"""
Systematically verify recommend_herbs() for EVERY symptom in the
vocabulary: for a single-symptom query, any herb genuinely tagged with
that symptom must outrank any herb that isn't (ground-truth overlap sorts
first). This checks that invariant holds everywhere, not just the
"toothache" case that surfaced the bug, and separately reports symptoms
where fewer than top_n herbs are tagged at all (a real data-scarcity
limit, not a bug -- there's nothing to promote if genuinely tagged herbs
don't exist).
"""
import sys
sys.path.insert(0, ".")
import joblib
import pandas as pd
from train_herb_relevance_model_xgb import recommend_herbs

BUNDLE_PATH = "models/herb_relevance_model_xgb.joblib"
TOP_N = 5


def main():
    bundle = joblib.load(BUNDLE_PATH)
    M, symptom_cols = bundle["herb_matrix"], bundle["symptom_cols"]
    meta = bundle["herb_meta"]
    symptom_idx = {s: i for i, s in enumerate(symptom_cols)}

    sort_bugs = []
    scarce_symptoms = []
    full_house = 0

    for s in symptom_cols:
        j = symptom_idx[s]
        total_tagged = int(M[:, j].sum())

        top = recommend_herbs(bundle, [s], top_n=TOP_N)
        tagged_flags = []
        for pos, _ in top.iterrows():
            tagged_flags.append(bool(M[pos, j] == 1))

        # Invariant: once a False (untagged) appears, no True should follow.
        seen_untagged = False
        for flag in tagged_flags:
            if not flag:
                seen_untagged = True
            elif seen_untagged:
                sort_bugs.append((s, tagged_flags, total_tagged))
                break

        n_tagged_in_top = sum(tagged_flags)
        if total_tagged < TOP_N:
            scarce_symptoms.append((s, total_tagged, n_tagged_in_top))
        elif n_tagged_in_top == TOP_N:
            full_house += 1

    print(f"Checked {len(symptom_cols)} symptoms, top_n={TOP_N}")
    print(f"Full house (all {TOP_N} top results genuinely tagged): {full_house}")
    print(f"Scarce (fewer than {TOP_N} herbs tagged at all -- expected gaps): {len(scarce_symptoms)}")
    print(f"SORT BUGS (tagged herb ranked below an untagged one -- real bugs): {len(sort_bugs)}")

    if sort_bugs:
        print("\n=== SORT BUGS (investigate) ===")
        for s, flags, total in sort_bugs:
            print(f"  {s!r}: flags={flags} total_tagged={total}")

    if scarce_symptoms:
        print(f"\n=== Scarce symptoms (data limit, not a bug) ===")
        for s, total, in_top in scarce_symptoms:
            print(f"  {s!r:35s} total_tagged={total}  tagged_in_top{TOP_N}={in_top}")


if __name__ == "__main__":
    main()
