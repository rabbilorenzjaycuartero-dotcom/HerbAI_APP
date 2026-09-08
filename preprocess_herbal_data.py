"""
Preprocessing pipeline: Herbal DB -> multi-hot symptom features for Random Forest
Target: Herbal Name (Herbal_Name_encoded column, label-encoded)

Steps:
1. Load raw CSV, drop empty column, drop fully-blank trailing row
2. Parse the free-text "Symptoms" column into a list of discrete symptom phrases per row
3. Normalize phrases (strip leading verbs/gerunds, drop leftover clause fragments,
   merge plural/singular duplicates)
4. Keep only symptoms occurring in >=2 rows (MIN_FREQ) as feature columns
   -> symptoms seen only once can't teach the model a repeatable pattern
5. Multi-hot encode: 1 column per symptom, 1 if present in that row's Symptoms text, else 0
6. Label-encode Herbal Name -> Herbal_Name_encoded (target for RF)
7. Extract Genus (first token of Scientific Name, cleaned of "Not clearly identified"
   -> "unknown") as an extra feature: congeneric herbs tend to share symptom profiles
"""
import re
from collections import Counter

import pandas as pd
from sklearn.preprocessing import LabelEncoder

INPUT_CSV = "HERBAL_DB - Sheet5_final.csv"
OUTPUT_CSV = "herbal_preprocessed_1.csv"
MIN_FREQ = 2  # minimum times a symptom must appear to become a feature column

VERB_PREFIXES = [
    "help relieve", "help treat", "help support", "help with", "help reduce",
    "relieve", "reduce", "support", "promote", "treat", "manage", "ease",
    "improve", "boost", "prevent", "control", "soothe", "heal", "combat",
    "alleviate", "strengthen", "stimulate", "enhance", "maintain",
    "relieving", "reducing", "supporting", "promoting", "treating", "managing",
    "easing", "improving", "boosting", "preventing", "controlling", "soothing",
    "healing", "combating", "alleviating", "strengthening", "stimulating",
    "enhancing", "maintaining",
]
VERB_PATTERN = re.compile(r"^(?:" + "|".join(VERB_PREFIXES) + r")\s+", flags=re.IGNORECASE)

JUNK_MARKERS = [
    "although", "due to", "well documented", "not considered", "in folk medicine",
    "well established", "culturally established", "not well", "limited traditional",
    "highly restricted", "safety has not", "is not", "where its",
]


def extract_symptoms(text):
    """Parse a free-text Symptoms cell into a list of clean symptom phrases."""
    if pd.isna(text):
        return []
    t = text.strip()
    t = re.sub(r"^Raditionally", "Traditionally", t, flags=re.IGNORECASE)  # fix typo in source data

    first_sentence = re.split(r"\.\s", t)[0]

    m = re.search(r"used\s+(?:\w+\s+){0,2}?(?:for|to)\s+(.*)", first_sentence, flags=re.IGNORECASE)
    if not m:
        m = re.search(r"used in .*?\s(?:for|to)\s+(.*)", first_sentence, flags=re.IGNORECASE)
    core = m.group(1) if m else first_sentence

    core = core.strip().rstrip(".")
    core = re.sub(r"\(.*?\)", "", core)
    core = re.sub(r"\bin some cultures\b", "", core, flags=re.IGNORECASE)
    core = re.sub(r"\bin traditional medicine\b", "", core, flags=re.IGNORECASE)
    core = re.sub(r"\bwhere its traditional use is culturally established\b", "", core, flags=re.IGNORECASE)

    parts = re.split(r",|\band\b", core)
    cleaned = []
    for p in parts:
        p = re.sub(r"\s+", " ", p.strip().lower()).strip(" .;")
        if not p:
            continue
        prev = None
        while prev != p:  # strip stacked verb prefixes, e.g. "help relieve x"
            prev = p
            p = VERB_PATTERN.sub("", p).strip()
        if not p or len(p) <= 1:
            continue
        if any(marker in p for marker in JUNK_MARKERS):
            continue
        cleaned.append(p)
    return cleaned


def consolidate_plurals(terms_counter):
    """Map plural/singular variants (e.g. 'headache'/'headaches') to one canonical term."""
    terms = list(terms_counter.keys())
    mapping = {}
    for t in terms:
        if t.endswith("s") and t[:-1] in terms_counter:
            singular, plural = t[:-1], t
            keep = singular if terms_counter[singular] >= terms_counter[plural] else plural
            mapping[singular] = keep
            mapping[plural] = keep
    for t in terms:
        mapping.setdefault(t, t)
    return mapping


def extract_genus(scientific_name):
    """First token of Scientific Name, or 'unknown' for unidentified entries."""
    if pd.isna(scientific_name):
        return "unknown"
    genus = str(scientific_name).strip().split()[0]
    if genus.lower() in {"not", "unknown", "n/a", "na", "none", "unidentified"}:
        return "unknown"
    return genus


def main():
    df = pd.read_csv(INPUT_CSV)
    df = df.loc[:, ~df.columns.str.match(r"^Unnamed")]  # drop any empty/unnamed columns, if present
    df = df.dropna(subset=["Herbal Name"]).reset_index(drop=True)

    df["Genus"] = df["Scientific Name"].apply(extract_genus)

    df["symptom_list"] = df["Symptoms"].apply(extract_symptoms)

    all_terms = Counter(s for lst in df["symptom_list"] for s in lst)
    cmap = consolidate_plurals(all_terms)
    df["symptom_list"] = df["symptom_list"].apply(lambda lst: sorted(set(cmap[s] for s in lst)))

    all_symptoms = [s for lst in df["symptom_list"] for s in lst]
    counts = Counter(all_symptoms)
    vocab = sorted([s for s, c in counts.items() if c >= MIN_FREQ])

    feat_df = pd.DataFrame(0, index=df.index, columns=vocab, dtype=int)
    for i, lst in enumerate(df["symptom_list"]):
        for s in lst:
            if s in vocab:
                feat_df.at[i, s] = 1

    final = pd.concat(
        [df[["ID", "Herbal Name", "Scientific Name", "Genus"]].reset_index(drop=True), feat_df],
        axis=1,
    )

    le = LabelEncoder()
    final["Herbal_Name_encoded"] = le.fit_transform(final["Herbal Name"])

    final.to_csv(OUTPUT_CSV, index=False)

    print(f"Rows: {final.shape[0]}, Feature columns: {len(vocab)}")
    print(f"Saved to {OUTPUT_CSV}")

    vc = final["Herbal Name"].value_counts()
    print(f"Classes with 1 sample: {(vc == 1).sum()} / {final['Herbal Name'].nunique()} total classes")


if __name__ == "__main__":
    main()