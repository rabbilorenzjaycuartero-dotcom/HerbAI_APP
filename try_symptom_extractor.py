"""Interactive tester for the FULL free-text -> herb-recommendation pipeline.
Type a sentence describing your symptoms (English/Bisaya/Tagalog, any mix):
  1. Logistic Regression (symptom_extractor.joblib) extracts which known
     symptoms your text refers to.
  2. Those symptoms get fed into XGBoost (herb_relevance_model_xgb.joblib),
     the same ranking model the app actually serves, to recommend herbs --
     mirroring exactly what a real "type your symptoms" app feature would do.
  3. The same safety filter api_server.py applies (herb_safety.py) is applied
     here too, so this CLI tester can't show something the live app wouldn't.
Type 'quit' to exit.
"""
import joblib
import pandas as pd
from symptom_spelling import build_symptom_words, spelling_suggestions
from train_symptom_extractor import extract_symptoms_from_text
from train_herb_relevance_model_xgb import recommend_herbs
from herb_safety import filter_dangerous

EXTRACTOR_PATH = "models/symptom_extractor.joblib"
XGB_PATH = "models/herb_relevance_model_xgb.joblib"
RAW_CSV = "HERBAL_DB - Sheet5_final.csv"


def _load_precautions_by_pos():
    # Same positional-alignment trick api_server.py uses: this raw CSV, after
    # the same dropna-on-"Herbal Name" filter preprocess_herbal_data.py
    # applies, is row-aligned with herbal_preprocessed_1.csv (and therefore
    # with the bundle's herb_meta, whose index IS that row position).
    raw_df = pd.read_csv(RAW_CSV)
    raw_df = raw_df.loc[:, ~raw_df.columns.str.match(r"^Unnamed")]
    raw_df = raw_df.dropna(subset=["Herbal Name"]).reset_index(drop=True)
    return raw_df["Precautions"]


def main():
    print("Loading models...")
    extractor_bundle = joblib.load(EXTRACTOR_PATH)
    xgb_bundle = joblib.load(XGB_PATH)
    precautions_by_pos = _load_precautions_by_pos()
    symptom_words = build_symptom_words(extractor_bundle["symptom_cols"])
    print("Ready. Type your symptoms (or 'quit' to exit).\n")

    while True:
        text = input("> ").strip()
        if not text:
            continue
        if text.lower() in ("quit", "exit", "q"):
            break

        for wrong, right in spelling_suggestions(text, symptom_words):
            print(f"  spelling: '{wrong}' -> did you mean '{right}'? Please correct your spelling.")

        matched = extract_symptoms_from_text(extractor_bundle, text)
        if not matched:
            print("No matching symptom found. Try rephrasing or check spelling.")
            continue
        print(f"  matched symptoms: {matched}")

        candidates = recommend_herbs(xgb_bundle, matched, top_n=50)
        if candidates.empty:
            print("  (walay herb nga na-recommend)")
            continue

        rows = list(candidates.iterrows())  # [(pos, row), ...]
        top = filter_dangerous(
            rows,
            get_precautions=lambda item: precautions_by_pos.get(item[0]),
            get_score=lambda item: item[1]["relevance_score"],
            top_n=5,
        )
        print("  recommended herbs:")
        for _, row in top:
            print(f"    {row['Herbal Name']} (score={row['relevance_score']:.3f})")


if __name__ == "__main__":
    main()
