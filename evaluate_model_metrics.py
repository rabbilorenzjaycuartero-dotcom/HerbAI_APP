"""
Reproduces every number in the paper's "AI Model Evaluation Output" table
(Appendix D) straight from the project's data and code, so the screenshot of
this script's terminal output is the evidence for that table.

Run:  python evaluate_model_metrics.py
"""
import re
import time
import warnings

import joblib
import numpy as np
import pandas as pd
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score
from sklearn.model_selection import StratifiedKFold, train_test_split
from xgboost import XGBClassifier

from condition_safety import CONDITION_KEYWORDS, get_condition_warnings
from herb_safety import DANGER_CONFIDENCE_THRESHOLD, filter_dangerous, is_flagged_dangerous
from train_herb_relevance_model_xgb import (
    RANDOM_STATE, _score_all_herbs, build_examples, compute_genus_freq, compute_pmi_matrix,
    recommend_herbs,
)

warnings.filterwarnings("ignore")

DATA_CSV = "herbal_preprocessed_1.csv"
RAW_CSV = "HERBAL_DB - Sheet5_final.csv"
MODEL_PATH = "models/herb_relevance_model_xgb.joblib"
TOP_N = 10


def line(label, value):
    print(f"  {label:<52} {value}")


def main():
    t0 = time.time()
    df = pd.read_csv(DATA_CSV)
    meta_cols = ["ID", "Herbal Name", "Scientific Name", "Genus", "Herbal_Name_encoded"]
    symptom_cols = [c for c in df.columns if c not in meta_cols]
    M = df[symptom_cols].values

    raw = pd.read_csv(RAW_CSV)
    raw = raw.loc[:, ~raw.columns.str.match(r"^Unnamed")]
    raw = raw.dropna(subset=["Herbal Name"]).reset_index(drop=True)
    assert len(raw) == len(df), "raw/preprocessed CSV row-count mismatch"
    precautions = raw["Precautions"].tolist()

    bundle = joblib.load(MODEL_PATH)
    clf_final = bundle["model"]
    params = {k: v for k, v in clf_final.get_params().items() if v is not None and k != "missing"}

    genus_freq = compute_genus_freq(df)
    pmi = compute_pmi_matrix(M)
    X, y = build_examples(M, np.random.default_rng(RANDOM_STATE), genus_freq, pmi)

    print("=" * 72)
    print(" HerbAI - AI MODEL EVALUATION OUTPUT")
    print("=" * 72)
    line("Herbs in dataset", f"{M.shape[0]:,}")
    line("Symptoms the model knows", f"{M.shape[1]:,}")
    line("Training examples (herb, symptom) pairs", f"{len(y):,}  (features per example: {X.shape[1]})")

    # 1) Single 80/20 stratified hold-out split
    X_tr, X_te, y_tr, y_te = train_test_split(
        X, y, test_size=0.2, stratify=y, random_state=RANDOM_STATE)
    clf = XGBClassifier(**params)
    clf.fit(X_tr, y_tr)
    pred = clf.predict(X_te)
    print("\n[1] XGBoost classifier - 80/20 hold-out test set "
          f"(train {len(y_tr):,} / test {len(y_te):,})")
    line("Accuracy on the test set", f"{accuracy_score(y_te, pred):.1%}")
    line("Precision", f"{precision_score(y_te, pred):.1%}")
    line("Recall", f"{recall_score(y_te, pred):.1%}")
    line("F1-score", f"{f1_score(y_te, pred):.1%}")

    # 2) 5-fold stratified cross-validation
    skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=RANDOM_STATE)
    accs = []
    for tr, te in skf.split(X, y):
        m = XGBClassifier(**params)
        m.fit(X[tr], y[tr])
        accs.append(accuracy_score(y[te], m.predict(X[te])))
    accs = np.array(accs)
    print("\n[2] 5-fold stratified cross-validation")
    line("Fold accuracies", "  ".join(f"{a:.1%}" for a in accs))
    line("5-fold cross-validation accuracy", f"{accs.mean():.1%} (+/-{accs.std():.1%})")

    # 3) Free-text symptom extraction (one unseen sentence per symptom)
    from train_symptom_extractor import extract_symptoms_from_text
    from generate_symptom_phrases import ENGLISH_TERMS
    from evaluate_all_symptoms import TEST_TEMPLATE
    ext = joblib.load("models/symptom_extractor.joblib")
    hits = sum(s in extract_symptoms_from_text(ext, TEST_TEMPLATE.format(s=ENGLISH_TERMS.get(s, s)))
               for s in symptom_cols)
    print("\n[3] Free-text symptom extraction (template not used in training)")
    line("Free-text symptom extraction", f"{hits} of {len(symptom_cols)} ({hits/len(symptom_cols):.1%})")

    # 4) Safety filter: every single-symptom query, top-10 before filtering
    flagged = np.array([is_flagged_dangerous(p) for p in precautions])
    in_top, dropped, kept = 0, 0, 0
    for s in symptom_cols:
        ranked = recommend_herbs(bundle, [s], top_n=TOP_N)  # same ranking the app serves
        for i, score in zip(ranked.index, ranked["relevance_score"]):
            if flagged[i]:
                in_top += 1
                if score < DANGER_CONFIDENCE_THRESHOLD:
                    dropped += 1
                else:
                    kept += 1
    print(f"\n[4] Safety filter - {len(symptom_cols)} single-symptom queries, top-{TOP_N} each")
    line("Herbs whose Precautions say toxic/poison/etc.", f"{flagged.sum():,}")
    line("Flagged herbs that reached a top-10 list", f"{in_top:,}")
    line(f"  removed (score < {DANGER_CONFIDENCE_THRESHOLD})", f"{dropped:,} ({dropped/max(in_top,1):.1%})")
    line(f"  kept (score >= {DANGER_CONFIDENCE_THRESHOLD}, model very confident)", f"{kept:,}")
    # Run the real filter the app uses on a 50-herb pool, then inspect what it shows.
    leaked = 0
    for s in symptom_cols:
        pool = recommend_herbs(bundle, [s], top_n=50)
        shown = filter_dangerous(list(zip(pool.index, pool["relevance_score"])),
                                 lambda r: precautions[r[0]], lambda r: r[1], TOP_N)
        leaked += sum(flagged[i] and sc < DANGER_CONFIDENCE_THRESHOLD for i, sc in shown)
    line("Low-confidence toxic herbs shown after filter", f"{leaked}")

    # 5) Condition warnings: every herb x condition its Precautions mention
    expected, shown = 0, 0
    per_cond = {}
    for p in precautions:
        if not isinstance(p, str):
            continue
        for cond, pats in CONDITION_KEYWORDS.items():
            if any(re.search(pt, p, re.IGNORECASE) for pt in pats):
                expected += 1
                per_cond[cond] = per_cond.get(cond, 0) + 1
                if any(w["condition"] == cond for w in get_condition_warnings(p, [cond])):
                    shown += 1
    print("\n[5] Condition warnings (pregnant / breastfeeding / child)")
    line("Herb-condition pairs mentioned in Precautions", f"{expected:,}  " +
         ", ".join(f"{k} {v}" for k, v in per_cond.items()))
    line("Condition warnings correctly displayed", f"{shown:,} of {expected:,} ({shown/max(expected,1):.0%})")

    # 6) Determinism: same input, same output
    rng = np.random.default_rng(7)
    same = True
    for _ in range(20):
        q = rng.choice(len(symptom_cols), size=rng.integers(1, 5), replace=False)
        a = _score_all_herbs(clf_final, M, genus_freq, pmi, q)
        b = _score_all_herbs(clf_final, M, genus_freq, pmi, q)
        same &= np.array_equal(a, b) and np.array_equal(np.argsort(-a), np.argsort(-b))
    print("\n[6] Consistency - 20 random queries, each run twice")
    line("Same input gave the same result on repeated runs", "Pass" if same else "Fail")

    print("\n" + "=" * 72)
    print(f" Finished in {time.time() - t0:.0f} s")
    print("=" * 72)


if __name__ == "__main__":
    main()
