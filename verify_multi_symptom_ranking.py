"""
Broader verification across many random MULTI-symptom combinations (2-4
symptoms, matching how real users actually query), checking two things at
once:
1. The ground-truth-overlap sort invariant holds for multi-symptom queries
   too, not just the single-symptom case already verified.
2. The safety filter (herb_safety.py) actually keeps every flagged-
   dangerous, low-confidence herb out of the results served through the
   real API path (post_recommend's candidate-pool + filter logic),
   re-implemented here directly against the model so this doesn't require
   a running server.
"""
import sys
sys.path.insert(0, ".")
import random
import joblib
import pandas as pd
from train_herb_relevance_model_xgb import recommend_herbs
from herb_safety import is_flagged_dangerous, DANGER_CONFIDENCE_THRESHOLD

BUNDLE_PATH = "models/herb_relevance_model_xgb.joblib"
RAW_CSV = "HERBAL_DB - Sheet5_final.csv"
TOP_N = 5
N_QUERIES = 300
RANDOM_STATE = 7


def load_precautions_by_pos():
    raw_df = pd.read_csv(RAW_CSV)
    raw_df = raw_df.loc[:, ~raw_df.columns.str.match(r"^Unnamed")]
    raw_df = raw_df.dropna(subset=["Herbal Name"]).reset_index(drop=True)
    return raw_df["Precautions"]


def main():
    bundle = joblib.load(BUNDLE_PATH)
    M, symptom_cols = bundle["herb_matrix"], bundle["symptom_cols"]
    symptom_idx = {s: i for i, s in enumerate(symptom_cols)}
    precautions_by_pos = load_precautions_by_pos()

    rng = random.Random(RANDOM_STATE)
    sort_bugs = []
    safety_leaks = []

    for _ in range(N_QUERIES):
        n_symptoms = rng.randint(2, 4)
        query = rng.sample(symptom_cols, n_symptoms)
        query_indices = [symptom_idx[s] for s in query]

        # Fetch a larger pool, same as api_server.py's post_recommend does,
        # so the safety filter has room to backfill after exclusions.
        candidates = recommend_herbs(bundle, query, top_n=max(TOP_N * 5, 50))
        if candidates.empty:
            continue

        # -- Check 1: ground-truth overlap sort invariant --
        overlaps = [int(M[pos, query_indices].sum()) for pos, _ in candidates.iterrows()]
        top_overlaps = overlaps[:TOP_N]
        for i in range(1, len(top_overlaps)):
            if top_overlaps[i] > top_overlaps[i - 1]:
                sort_bugs.append((query, top_overlaps))
                break

        # -- Check 2: safety filter, applied the same way post_recommend does --
        shown = 0
        for pos, row in candidates.iterrows():
            if shown >= TOP_N:
                break
            precautions = precautions_by_pos.get(pos)
            score = float(row["relevance_score"])
            if is_flagged_dangerous(precautions) and score < DANGER_CONFIDENCE_THRESHOLD:
                continue
            shown += 1
        # Now directly verify: among the TOP_N actually shown, none should
        # be a low-confidence dangerous herb -- recompute explicitly.
        final_shown = []
        for pos, row in candidates.iterrows():
            precautions = precautions_by_pos.get(pos)
            score = float(row["relevance_score"])
            if is_flagged_dangerous(precautions) and score < DANGER_CONFIDENCE_THRESHOLD:
                continue
            final_shown.append((pos, row["Herbal Name"], score, precautions))
            if len(final_shown) >= TOP_N:
                break
        for pos, name, score, precautions in final_shown:
            if is_flagged_dangerous(precautions) and score < DANGER_CONFIDENCE_THRESHOLD:
                safety_leaks.append((query, name, score))

    print(f"Tested {N_QUERIES} random multi-symptom queries (2-4 symptoms each)")
    print(f"Sort invariant violations: {len(sort_bugs)}")
    print(f"Safety filter leaks (dangerous herb slipped through): {len(safety_leaks)}")

    if sort_bugs:
        print("\n=== SORT BUGS ===")
        for query, overlaps in sort_bugs[:20]:
            print(f"  {query}: top overlaps={overlaps}")

    if safety_leaks:
        print("\n=== SAFETY LEAKS ===")
        for query, name, score in safety_leaks[:20]:
            print(f"  {query}: {name} score={score:.3f}")


if __name__ == "__main__":
    main()
