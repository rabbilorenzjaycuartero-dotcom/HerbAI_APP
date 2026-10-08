"""
Herb recommender via binary relevance reframing -- XGBoost version.

Same problem framing as train_herb_relevance_model_rf.py (Random Forest version):
    Given a herb's OTHER known symptoms + a candidate symptom,
    does this candidate symptom apply to this herb? (yes/no)

See train_herb_relevance_model_rf.py for the full rationale on why this
reframing was used instead of direct herb classification, and for the v2
feature set: masked symptom profile + one-hot candidate symptom + genus
frequency + symptom co-occurrence (PMI) score.

This script swaps the classifier for XGBoost, keeping identical data
prep/masking/feature logic so the two models are directly comparable.
"""
import numpy as np
import pandas as pd
import joblib
from xgboost import XGBClassifier
from sklearn.model_selection import StratifiedKFold, RandomizedSearchCV
from sklearn.metrics import accuracy_score, roc_auc_score
import warnings
warnings.filterwarnings("ignore")

DATA_CSV = "herbal_preprocessed_1.csv"
MODEL_OUT = "models/herb_relevance_model_xgb.joblib"
RANDOM_STATE = 42


def compute_genus_freq(df):
    """How many herbs (including itself) share each herb's plant genus."""
    counts = df["Genus"].value_counts()
    return df["Genus"].map(counts).to_numpy(dtype=float)


def compute_pmi_matrix(M):
    """Symptom-symptom pointwise mutual information, dataset-wide.

    PMI(j, k) = log( P(j, k) / (P(j) * P(k)) ), estimated from co-occurrence
    counts across all herbs. Used to score how well a candidate symptom
    "fits" a herb's other known symptoms.
    """
    n_herbs = M.shape[0]
    co = M.T @ M  # co[j, k] = # herbs with both symptom j and k present
    freq = np.diag(co).astype(float)
    freq_safe = np.where(freq == 0, 1, freq)
    co_smooth = co + 0.5  # avoid log(0) for symptom pairs that never co-occur
    pmi = np.log((co_smooth * n_herbs) / np.outer(freq_safe, freq_safe))
    np.fill_diagonal(pmi, 0.0)  # a symptom isn't "co-occurring" with itself
    return pmi


def build_examples(M, rng, genus_freq, pmi):
    """Build balanced (label, feature-vector) examples for every herb.

    Feature vector = [masked symptom profile | one-hot candidate symptom |
                       herb's genus frequency | candidate/profile PMI score]
    """
    n_herbs, n_symptoms = M.shape
    eye = np.eye(n_symptoms)
    feats_list, y_list = [], []

    for i in range(n_herbs):
        present = np.where(M[i] == 1)[0]
        absent = np.where(M[i] == 0)[0]
        if len(present) == 0:
            continue
        n_neg = min(len(present), len(absent))
        neg_j = rng.choice(absent, size=n_neg, replace=False)

        for j, label in list(zip(present, [1] * len(present))) + list(zip(neg_j, [0] * len(neg_j))):
            masked = M[i].copy()
            masked[j] = 0  # mask candidate symptom, prevent leakage
            n_present = masked.sum()
            co_score = float(pmi[j] @ masked) / n_present if n_present > 0 else 0.0
            x = np.concatenate([masked, eye[j], [genus_freq[i], co_score]])
            feats_list.append(x)
            y_list.append(label)

    return np.stack(feats_list), np.array(y_list)


def _score_all_herbs(clf, M, genus_freq, pmi, query_indices):
    """Score every herb against a list of query symptom column indices,
    using the same masked-averaging procedure recommend_herbs() serves to
    the app. Shared by recommend_herbs() (string-based, real queries) and
    query_level_eval() (index-based, realistic ranking eval)."""
    n_herbs, n_symptoms = M.shape
    scores = np.zeros(n_herbs)
    for j in query_indices:
        feats = M.copy()
        feats[:, j] = 0
        n_present = np.maximum(feats.sum(axis=1), 1)
        co_scores = (feats @ pmi[j]) / n_present
        onehot = np.zeros((n_herbs, n_symptoms))
        onehot[:, j] = 1
        X = np.column_stack([feats, onehot, genus_freq, co_scores])
        scores += clf.predict_proba(X)[:, 1]
    scores /= len(query_indices)
    return scores


def query_level_eval(clf, M, genus_freq, pmi, rng, n_queries=300, top_ks=(5, 10)):
    """Realistic ranking eval: for sampled herbs, hold out a random half of
    that herb's OWN symptoms as a synthetic query, score every herb with
    _score_all_herbs() (the exact procedure the app uses at serving time),
    and check whether the source herb resurfaces near the top.

    See train_herb_relevance_model_rf.py's query_level_eval for the full
    rationale: pairwise ROC-AUC on independent (herb, symptom) examples
    never tests whether the query-averaging step actually works.
    """
    n_herbs = M.shape[0]
    eligible = np.where(M.sum(axis=1) >= 2)[0]
    sample_size = min(n_queries, len(eligible))
    sampled = rng.choice(eligible, size=sample_size, replace=False)

    ranks = []
    for i in sampled:
        present = np.where(M[i] == 1)[0]
        n_query = max(1, len(present) // 2)
        query_idx = rng.choice(present, size=n_query, replace=False)
        scores = _score_all_herbs(clf, M, genus_freq, pmi, query_idx)
        rank = int((-scores).argsort().argsort()[i]) + 1  # 1-indexed
        ranks.append(rank)

    ranks = np.array(ranks)
    result = {"mrr": float(np.mean(1.0 / ranks))}
    for k in top_ks:
        result[f"recall@{k}"] = float(np.mean(ranks <= k))
    return result


def cross_validate(X, y, param_overrides=None, n_splits=5):
    skf = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=RANDOM_STATE)
    accs, aucs = [], []
    params = {
        "n_estimators": 300, "max_depth": 6, "learning_rate": 0.1,
        "subsample": 0.8, "colsample_bytree": 0.8,
        **(param_overrides or {}),
    }
    for train_idx, test_idx in skf.split(X, y):
        clf = XGBClassifier(
            eval_metric="logloss", random_state=RANDOM_STATE, n_jobs=2, **params
        )
        clf.fit(X[train_idx], y[train_idx])
        pred = clf.predict(X[test_idx])
        proba = clf.predict_proba(X[test_idx])[:, 1]
        accs.append(accuracy_score(y[test_idx], pred))
        aucs.append(roc_auc_score(y[test_idx], proba))
    return np.array(accs), np.array(aucs)


def tune_hyperparams(X, y):
    """Modest randomized search over XGBoost hyperparameters."""
    param_dist = {
        "n_estimators": [200, 300, 400, 500],
        "max_depth": [4, 6, 8, 10],
        "learning_rate": [0.03, 0.05, 0.1, 0.2],
        "subsample": [0.7, 0.8, 1.0],
        "colsample_bytree": [0.6, 0.8, 1.0],
        "min_child_weight": [1, 3, 5],
        "reg_alpha": [0, 0.1, 1.0],
        "reg_lambda": [1.0, 2.0, 5.0],
    }
    search = RandomizedSearchCV(
        XGBClassifier(eval_metric="logloss", random_state=RANDOM_STATE, n_jobs=2),
        param_distributions=param_dist,
        n_iter=15,
        cv=3,
        scoring="roc_auc",
        random_state=RANDOM_STATE,
        n_jobs=1,
    )
    search.fit(X, y)
    return search.best_params_


def main():
    rng = np.random.default_rng(RANDOM_STATE)
    df = pd.read_csv(DATA_CSV)
    meta_cols = ["ID", "Herbal Name", "Scientific Name", "Genus", "Herbal_Name_encoded"]
    symptom_cols = [c for c in df.columns if c not in meta_cols]
    M = df[symptom_cols].values
    print(f"{M.shape[0]} herbs x {M.shape[1]} symptoms")

    genus_freq = compute_genus_freq(df)
    pmi = compute_pmi_matrix(M)

    X, y = build_examples(M, rng, genus_freq, pmi)
    print(f"Examples: {len(y)} (positives: {y.sum()}, negatives: {(y == 0).sum()})")
    print(f"Feature dims: {X.shape[1]} (196 masked profile + 196 one-hot symptom + genus_freq + co-occurrence)")

    print("\nTuning hyperparameters (RandomizedSearchCV, 3-fold)...")
    best_params = tune_hyperparams(X, y)
    print(f"Best params: {best_params}")

    print("\nCross-validating (5-fold, stratified) with best params...")
    accs, aucs = cross_validate(X, y, param_overrides=best_params)
    print(f"CV accuracy: {accs.mean():.3f} +/- {accs.std():.3f}")
    print(f"CV ROC-AUC:  {aucs.mean():.3f} +/- {aucs.std():.3f}")

    print("\nFitting final model on all data...")
    clf = XGBClassifier(eval_metric="logloss", random_state=RANDOM_STATE, n_jobs=2, **best_params)
    clf.fit(X, y)

    print("\nRealistic query-level eval on the final model (does the right herb")
    print("resurface when queried with its own symptoms)...")
    query_metrics = query_level_eval(clf, M, genus_freq, pmi, rng, n_queries=300)
    print(
        f"Recall@5={query_metrics['recall@5']:.3f}  "
        f"Recall@10={query_metrics['recall@10']:.3f}  "
        f"MRR={query_metrics['mrr']:.3f}"
    )

    joblib.dump(
        {
            "model": clf,
            "symptom_cols": symptom_cols,
            "herb_matrix": M,
            "herb_meta": df[["ID", "Herbal Name", "Scientific Name"]],
            "genus_freq": genus_freq,
            "pmi": pmi,
        },
        MODEL_OUT,
    )
    print(f"\nSaved model + inference data to {MODEL_OUT}")


def recommend_herbs(bundle, query_symptoms, top_n=5):
    """Rank herbs for a list of query symptom strings (must match symptom_cols).
    Works identically to the Random Forest version -- XGBClassifier shares the
    same predict_proba interface."""
    clf, symptom_cols = bundle["model"], bundle["symptom_cols"]
    M, meta = bundle["herb_matrix"], bundle["herb_meta"]
    genus_freq, pmi = bundle["genus_freq"], bundle["pmi"]
    symptom_to_idx = {s: i for i, s in enumerate(symptom_cols)}

    valid_q = [s for s in query_symptoms if s in symptom_to_idx]
    unknown = [s for s in query_symptoms if s not in symptom_to_idx]
    if unknown:
        print(f"(ignored, not in vocabulary: {unknown})")
    if not valid_q:
        return pd.DataFrame()

    query_indices = [symptom_to_idx[q] for q in valid_q]
    scores = _score_all_herbs(clf, M, genus_freq, pmi, query_indices)

    # Ground-truth overlap: how many of the queried symptoms this herb is
    # ACTUALLY tagged with in the real data, not just model-inferred. Sorted
    # first, ahead of the model's relevance_score, because a real tag is
    # direct evidence while the model score is a statistical guess -- found
    # necessary after a real case where "toothache" (only 20 tagged herbs,
    # a single-symptom query with no other symptoms to average against)
    # surfaced 4 of 5 top results with NO actual toothache tag at all, while
    # genuinely-tagged herbs like "Toothache Plant"/"Toothache Tree" (named
    # for exactly this) were buried far down the list.
    ground_truth_overlap = M[:, query_indices].sum(axis=1)

    result = meta.copy()
    result["relevance_score"] = scores
    result["_ground_truth_overlap"] = ground_truth_overlap
    result = result.sort_values(
        by=["_ground_truth_overlap", "relevance_score"], ascending=[False, False]
    )
    return result.drop(columns="_ground_truth_overlap").head(top_n)


if __name__ == "__main__":
    main()
