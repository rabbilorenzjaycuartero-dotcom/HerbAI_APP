"""
Systematically test the symptom extractor against EVERY symptom in the
vocabulary, not just a hand-picked list -- using a sentence template NOT
seen during training (generate_symptom_phrases.py never used this phrasing),
so this genuinely tests generalization rather than memorization.
"""
import joblib
import pandas as pd
from train_symptom_extractor import extract_symptoms_from_text
from generate_symptom_phrases import ENGLISH_TERMS

MODEL_PATH = "models/symptom_extractor.joblib"
PREPROCESSED_CSV = "herbal_preprocessed_1.csv"

# Deliberately different phrasing from any ENGLISH_TEMPLATES used in training.
TEST_TEMPLATE = "lately i've been suffering from {s}, it's been rough"


def main():
    df = pd.read_csv(PREPROCESSED_CSV)
    meta_cols = ["ID", "Herbal Name", "Scientific Name", "Genus", "Herbal_Name_encoded"]
    symptom_cols = [c for c in df.columns if c not in meta_cols]

    bundle = joblib.load(MODEL_PATH)

    hits, misses = [], []
    for s in symptom_cols:
        term = ENGLISH_TERMS.get(s, s)
        sentence = TEST_TEMPLATE.format(s=term)
        matched = extract_symptoms_from_text(bundle, sentence)
        if s in matched:
            hits.append((s, matched))
        else:
            misses.append((s, sentence, matched))

    print(f"Recall: {len(hits)}/{len(symptom_cols)} = {len(hits)/len(symptom_cols):.1%}\n")

    print(f"=== MISSES ({len(misses)}) ===")
    for s, sentence, matched in misses:
        print(f"  target={s!r:30s} sentence={sentence!r}")
        print(f"      got: {matched}")


if __name__ == "__main__":
    main()
