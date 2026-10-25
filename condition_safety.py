import re

# Patterns are matched case-insensitively against each Precautions sentence.
# "minor" is deliberately excluded from the child patterns -- the dataset
# uses it constantly for "minor skin conditions"/"minor burns", unrelated to
# children, so including it would misfire on nearly every herb.
CONDITION_KEYWORDS = {
    "pregnant": [r"pregnan\w*"],
    "breastfeeding": [r"breastfeed\w*", r"breast-feed\w*", r"lactat\w*"],
    "child": [r"\bchild(?:ren)?\b", r"\binfant\w*\b"],
}

AVOID_PHRASES = (
    "avoid", "not recommended", "should not", "contraindicat",
    "not advised", "unsafe", "not be used", "not safe", "keep away",
    "out of reach", "not suitable for",
)


def get_condition_warnings(precautions_text, conditions):
    """For each selected condition this herb's Precautions text actually
    mentions, return the matching sentence verbatim (never a generated
    claim) plus a severity: "avoid" when the sentence itself uses
    avoid/contraindication language, otherwise "caution" (e.g. a generic
    "consult a doctor" deferral)."""
    if not isinstance(precautions_text, str) or not conditions:
        return []

    sentences = [s.strip() for s in re.split(r"(?<=[.;])\s+", precautions_text.strip()) if s.strip()]

    warnings = []
    for condition in conditions:
        patterns = CONDITION_KEYWORDS.get(condition)
        if not patterns:
            continue
        match = next(
            (s for s in sentences if any(re.search(p, s, re.IGNORECASE) for p in patterns)),
            None,
        )
        if match is None:
            continue
        severity = "avoid" if any(p in match.lower() for p in AVOID_PHRASES) else "caution"
        warnings.append({
            "condition": condition,
            "severity": severity,
            "note": match.rstrip(".;") + ".",
        })
    return warnings
