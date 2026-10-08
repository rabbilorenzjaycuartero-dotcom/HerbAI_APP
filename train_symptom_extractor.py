"""
Free-text symptom extractor -- Logistic Regression (One-vs-Rest).

Originally built with Random Forest to give RF a job separate from
herb-ranking (where XGBoost alone consistently wins -- see
train_herb_relevance_model_rf.py and the removed hybrid experiments). RF
turned out to be a poor structural fit for this specific task: a
multi-output RF stores a full per-class leaf-value table for all 150
symptom labels in every tree, which produced a 2.1GB model file that
failed to even load (MemoryError), and every attempt to shrink it (capping
tree depth, capping TF-IDF dimensionality) collapsed accuracy well below
its already-modest ~33% subset accuracy. Switched to Logistic Regression
instead: linear models are the standard, usually stronger choice for
sparse high-dimensional text (TF-IDF) classification, and store only a
coefficient vector per label -- a few hundred KB total instead of hundreds
of MB to GB.

This maps free text a user types ("i have a cough and sore throat") to
which of the known symptoms it refers to -- a multi-label text
classification task, not a ranking task.

TRAINING DATA, two sources combined:
1. HERBAL_DB - Sheet5_final.csv's "Symptoms" column (a free-text sentence
   per herb, e.g. "Traditionally used for fever, cough...") is already
   row-aligned with herbal_preprocessed_1.csv's multi-hot symptom columns
   (the same positional-alignment trick api_server.py relies on) -- so
   every herb is a ready-made (text -> symptom tags) training example.
2. symptom_phrases_training.csv (see generate_symptom_phrases.py) -- ~1,500
   hand-templated casual phrases (English/Bisaya/Tagalog) covering how a
   real person would actually type a symptom, since (1) alone is written in
   a single formal database-entry register and doesn't teach the model
   natural phrasing (confirmed empirically: a version trained on (1) alone
   got 23% held-out subset accuracy and defaulted to predicting
   "inflammation" for almost any casual sentence).

Kept as a separate CSV from HERBAL_DB - Sheet5_final.csv on purpose -- that
file is one row per real herb, read directly by the herb-ranking pipeline;
mixing in synthetic phrase rows there would make fake "herbs" appear in
real recommendations.

SANITY CHECK BELOW: the trained classifier is run against hand-written
casual sentences to check honestly whether it generalizes, rather than
assuming it does because held-out accuracy on same-style training data
looks fine.
"""
import numpy as np
import pandas as pd
import joblib
from sklearn.linear_model import LogisticRegression
from sklearn.multiclass import OneVsRestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, f1_score
import warnings
warnings.filterwarnings("ignore")

RAW_CSV = "HERBAL_DB - Sheet5_final.csv"
PREPROCESSED_CSV = "herbal_preprocessed_1.csv"
PHRASES_CSV = "symptom_phrases_training.csv"
MODEL_OUT = "models/symptom_extractor.joblib"
RANDOM_STATE = 42


def load_training_pairs():
    raw_df = pd.read_csv(RAW_CSV)
    raw_df = raw_df.loc[:, ~raw_df.columns.str.match(r"^Unnamed")]
    raw_df = raw_df.dropna(subset=["Herbal Name"]).reset_index(drop=True)

    preprocessed_df = pd.read_csv(PREPROCESSED_CSV)
    assert len(raw_df) == len(preprocessed_df), "raw/preprocessed CSV row-count mismatch"

    meta_cols = ["ID", "Herbal Name", "Scientific Name", "Genus", "Herbal_Name_encoded"]
    symptom_cols = [c for c in preprocessed_df.columns if c not in meta_cols]
    symptom_idx = {s: i for i, s in enumerate(symptom_cols)}

    herb_texts = raw_df["Symptoms"].fillna("").astype(str).tolist()
    herb_Y = preprocessed_df[symptom_cols].values.astype(int)

    # Casual-phrase examples: one symptom tag per row -> one-hot against the
    # same symptom_cols space, so both sources share one training matrix.
    phrases_df = pd.read_csv(PHRASES_CSV)
    phrase_texts = phrases_df["text"].tolist()
    phrase_Y = np.zeros((len(phrases_df), len(symptom_cols)), dtype=int)
    for row_i, symptom in enumerate(phrases_df["symptom"]):
        phrase_Y[row_i, symptom_idx[symptom]] = 1

    texts = herb_texts + phrase_texts
    Y = np.vstack([herb_Y, phrase_Y])
    return texts, Y, symptom_cols


def _build_classifier():
    return OneVsRestClassifier(
        LogisticRegression(max_iter=1000, class_weight="balanced", random_state=RANDOM_STATE),
        n_jobs=2,
    )


def main():
    texts, Y, symptom_cols = load_training_pairs()
    print(f"{len(texts)} (text, symptom_tags) training pairs, {len(symptom_cols)} symptoms")

    X_text_train, X_text_test, Y_train, Y_test = train_test_split(
        texts, Y, test_size=0.2, random_state=RANDOM_STATE
    )

    # No need to cap dimensionality the way the Random Forest attempt did --
    # a linear model's size scales as n_features x n_labels, trivially small
    # even at the full TF-IDF vocabulary.
    vectorizer = TfidfVectorizer(analyzer="char_wb", ngram_range=(3, 5), min_df=2)
    X_train = vectorizer.fit_transform(X_text_train)
    X_test = vectorizer.transform(X_text_test)
    print(f"TF-IDF vocabulary size: {len(vectorizer.vocabulary_)}")

    clf = _build_classifier()
    clf.fit(X_train, Y_train)

    Y_pred = clf.predict(X_test)
    subset_acc = accuracy_score(Y_test, Y_pred)  # exact match on all labels -- a strict bar
    micro_f1 = f1_score(Y_test, Y_pred, average="micro", zero_division=0)
    print(f"\nHeld-out subset accuracy (exact full-label match): {subset_acc:.3f}")
    print(f"Held-out micro-F1 (per-symptom-tag correctness):    {micro_f1:.3f}")

    # Refit on all data for the saved/serving model.
    X_all = vectorizer.fit_transform(texts)
    clf_final = _build_classifier()
    clf_final.fit(X_all, Y)

    joblib.dump(
        {"vectorizer": vectorizer, "model": clf_final, "symptom_cols": symptom_cols},
        MODEL_OUT,
    )
    print(f"\nSaved to {MODEL_OUT}")


def extract_symptoms_from_text(bundle, text, threshold=0.30, top_n=8):
    """Given free text, return the matched symptom strings from the
    known vocabulary, using each label's predict_proba."""
    vectorizer, clf, symptom_cols = bundle["vectorizer"], bundle["model"], bundle["symptom_cols"]
    X = vectorizer.transform([text])
    # OneVsRestClassifier.predict_proba returns a single (n_samples, n_labels)
    # array directly -- one probability per label, unlike a multi-output RF's
    # list of per-label (n_samples, 2) arrays.
    scores = clf.predict_proba(X)[0]

    ranked = np.argsort(-scores)
    matched = [symptom_cols[i] for i in ranked if scores[i] >= threshold][:top_n]
    return matched


if __name__ == "__main__":
    main()

    print("\n=== Casual-phrasing sanity check (NOT styled like training data) ===")
    bundle = joblib.load(MODEL_OUT)
    casual_sentences = [
        "i have a cough and sore throat",
        "my stomach hurts and i have diarrhea",
        "i can't sleep and i feel anxious",
        "i have a headache and fever",
        "my skin is itchy and irritated",
        "i have trouble urinating",
        "my tooth hurts so bad",
        "i have high blood pressure",
        "i feel nauseous and want to vomit",
        "i have a wound that won't heal",
        "naa koy ubo ug sakit akong tutunlan",
        "sakit akong tiyan ug nagkalibang ko",
        "dili ko makatulog, gikabalaka ko",
        "masakit ang ulo ko at may lagnat ako",
        "makati at namumula ang balat ko",
    ]
    for sentence in casual_sentences:
        matched = extract_symptoms_from_text(bundle, sentence)
        print(f"  {sentence!r:55s} -> {matched}")
