"""
Shared safety filter for herb recommendations -- used by both api_server.py
(the live app) and try_symptom_extractor.py (the standalone CLI tester), so
a fix applied in one place can't silently miss the other.

Found necessary after a real case: querying "toothache" (only 20 herbs
tagged with it) ranked "Jerusalem Cherry" -- poisonous per its own
Precautions text, and its only ACTUAL tagged symptom is "minor skin
conditions", unrelated to toothache -- #1 at score 0.627, ahead of the
genuinely correct "Toothache Plant"/"Toothache Tree" (~0.30, buried at rank
42/115). Root cause: Jerusalem Cherry has only 1 tagged symptom (19 herbs
in the dataset are this sparse), so masking that lone symptom for scoring
leaves an entirely empty profile -- the model is essentially guessing, and
can guess confidently wrong. The same herb also scored 0.895 for an
unrelated headache/anxiety/insomnia query, so the confidence bar needs to
sit above the range these sparse-profile herbs can spuriously reach.
"""
DANGER_KEYWORDS = ("toxic", "poison", "lethal", "fatal", "deadly", "carcinogenic")
DANGER_CONFIDENCE_THRESHOLD = 0.95


def is_flagged_dangerous(precautions_text):
    if not isinstance(precautions_text, str):
        return False
    text = precautions_text.lower()
    return any(keyword in text for keyword in DANGER_KEYWORDS)


def filter_dangerous(rows, get_precautions, get_score, top_n):
    """rows: iterable of candidate items (already sorted best-first).
    get_precautions(item)/get_score(item): accessors for that item's
    Precautions text and relevance score. Returns up to top_n items with
    low-confidence dangerous ones dropped, order preserved."""
    out = []
    for item in rows:
        if is_flagged_dangerous(get_precautions(item)) and get_score(item) < DANGER_CONFIDENCE_THRESHOLD:
            continue
        out.append(item)
        if len(out) >= top_n:
            break
    return out
