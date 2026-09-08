"""
Herb recommender via binary relevance reframing (Option B).

WHY THIS APPROACH:
The original goal -- Random Forest predicting a specific Herbal Name directly
from symptoms -- doesn't work as a classification problem: 1,084 of 1,103
herbs have only 1 example each, so there's no way to learn or test a
generalizable pattern per herb (see earlier exploration for details, and
"explode" attempt which also failed due to symptom-collision: symptoms like
"inflammation" appear in ~980 different herbs, so a single symptom carries
almost no distinguishing signal).

This script reframes the problem as BINARY RELEVANCE instead:
    Given a herb's OTHER known symptoms + a candidate symptom,
    does this candidate symptom apply to this herb? (yes/no)

This turns 1,103 classes into a 2-class problem with ~13,000 balanced
examples, which supports a real train/test split and genuine evaluation.
To recommend herbs for a set of query symptoms, we score every herb against
every query symptom (with that symptom masked out of its profile, to avoid
trivially "cheating" from that symptom's presence) and average the scores.

FEATURES (v2):
    - masked symptom multi-hot profile (196 dims) -- the herb's other symptoms
    - one-hot of the candidate/query symptom (196 dims) -- replaces the old
      raw symptom index, which had no meaningful ordering for a tree to split on
    - genus frequency -- how many herbs share this herb's plant genus;
      congeneric plants tend to share traditional-use/symptom profiles
    - symptom co-occurrence (PMI) score -- how strongly the candidate symptom
      is associated, dataset-wide, with the herb's other present symptoms

Evaluation uses 5-fold stratified cross-validation (mean +/- std) rather than
a single train/test split, since a single split's accuracy can vary with
which examples happen to land in the test fold.
"""
import numpy as np
import pandas as pd
import joblib
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import StratifiedKFold, RandomizedSearchCV
from sklearn.metrics import accuracy_score, roc_auc_score
import warnings
warnings.filterwarnings("ignore")

DATA_CSV = "herbal_preprocessed_1.csv"
MODEL_OUT = "models/herb_relevance_model.joblib"
RANDOM_STATE = 42


def compute_genus_freq(df):
    """How many herbs (including itself) share each herb's plant genus."""
    counts = df["Genus"].value_counts()
    return df["Genus"].map(counts).to_numpy(dtype=float)


def compute_pmi_matrix(M):
    """Symptom-symptom pointwise mutual information, dataset-wide.

    PMI(j, k) = log( P(j, k) / (P(j) * P(k)) ), estimated from co-occurrence
    counts across all herbs. Positive values mean the two symptoms co-occur
    more than chance; used to score how well a candidate symptom "fits" a
    herb's other known symptoms.
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


def cross_validate(X, y, param_overrides=None, n_splits=5):
    skf = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=RANDOM_STATE)
    accs, aucs = [], []
    params = {"n_estimators": 200, **(param_overrides or {})}
    for train_idx, test_idx in skf.split(X, y):
        clf = RandomForestClassifier(random_state=RANDOM_STATE, n_jobs=2, **params)
        clf.fit(X[train_idx], y[train_idx])
        pred = clf.predict(X[test_idx])
        proba = clf.predict_proba(X[test_idx])[:, 1]
        accs.append(accuracy_score(y[test_idx], pred))
        aucs.append(roc_auc_score(y[test_idx], proba))
    return np.array(accs), np.array(aucs)


def tune_hyperparams(X, y):
    """Modest randomized search over RF hyperparameters."""
    param_dist = {
        "n_estimators": [200, 300, 400],
        "max_depth": [None, 12, 20, 30],
        "min_samples_leaf": [1, 2, 4],
        "max_features": ["sqrt", "log2", 0.5],
    }
    search = RandomizedSearchCV(
        RandomForestClassifier(random_state=RANDOM_STATE, n_jobs=2),
        param_distributions=param_dist,
        n_iter=10,
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
    clf = RandomForestClassifier(random_state=RANDOM_STATE, n_jobs=2, **best_params)
    clf.fit(X, y)

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
    """Rank herbs for a list of query symptom strings (must match symptom_cols)."""
    clf, symptom_cols = bundle["model"], bundle["symptom_cols"]
    M, meta = bundle["herb_matrix"], bundle["herb_meta"]
    genus_freq, pmi = bundle["genus_freq"], bundle["pmi"]
    symptom_to_idx = {s: i for i, s in enumerate(symptom_cols)}
    n_herbs, n_symptoms = M.shape

    valid_q = [s for s in query_symptoms if s in symptom_to_idx]
    unknown = [s for s in query_symptoms if s not in symptom_to_idx]
    if unknown:
        print(f"(ignored, not in vocabulary: {unknown})")
    if not valid_q:
        return pd.DataFrame()

    scores = np.zeros(n_herbs)
    for q in valid_q:
        j = symptom_to_idx[q]
        feats = M.copy()
        feats[:, j] = 0
        n_present = np.maximum(feats.sum(axis=1), 1)
        co_scores = (feats @ pmi[j]) / n_present
        onehot = np.zeros((n_herbs, n_symptoms))
        onehot[:, j] = 1
        X = np.column_stack([feats, onehot, genus_freq, co_scores])
        scores += clf.predict_proba(X)[:, 1]
    scores /= len(valid_q)

    result = meta.copy()
    result["relevance_score"] = scores
    return result.sort_values("relevance_score", ascending=False).head(top_n)


if __name__ == "__main__":
    main()
