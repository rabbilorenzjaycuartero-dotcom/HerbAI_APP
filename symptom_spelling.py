import difflib
import re


def build_symptom_words(symptom_cols):
    words = set()
    for s in symptom_cols:
        words.update(re.findall(r"[a-z]+", s.lower()))
    return words


def spelling_suggestions(text, symptom_words):
    suggestions = []
    for word in sorted(set(re.findall(r"[a-z]+", text.lower()))):
        if len(word) < 4 or word in symptom_words:
            continue
        close = difflib.get_close_matches(word, symptom_words, n=1, cutoff=0.8)
        if close:
            suggestions.append((word, close[0]))
    return suggestions
