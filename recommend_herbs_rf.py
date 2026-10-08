import numpy as np
import pandas as pd

def recommend_herbs_v2(bundle, query_symptoms, top_n=5):
    """
    Rank herbs for a list of query symptoms, with tie-breaking and a
    confidence indicator based on how much the forest's individual trees
    agree with each other.
    """
    clf, symptom_cols = bundle["model"], bundle["symptom_cols"]
    M, meta = bundle["herb_matrix"], bundle["herb_meta"]
    genus_freq, pmi = bundle["genus_freq"], bundle["pmi"]
    symptom_to_idx = {s: i for i, s in enumerate(symptom_cols)}

    valid_q = [s for s in query_symptoms if s in symptom_to_idx]
    unknown = [s for s in query_symptoms if s not in symptom_to_idx]
    if unknown:
        print(f"(ignored, not in vocabulary: {unknown})")
    if not valid_q:
        return pd.DataFrame()

    n_herbs, n_symptoms = M.shape
    per_symptom_scores = []   # one array per query symptom
    per_symptom_std = []      # tree-disagreement per query symptom

    for q in valid_q:
        j = symptom_to_idx[q]
        feats = M.copy()
        feats[:, j] = 0
        n_present = np.maximum(feats.sum(axis=1), 1)
        co_scores = (feats @ pmi[j]) / n_present
        onehot = np.zeros((n_herbs, n_symptoms))
        onehot[:, j] = 1
        X = np.column_stack([feats, onehot, genus_freq, co_scores])

        # per-tree predictions -> mean (the usual predict_proba) + std (disagreement)
        tree_preds = np.stack([t.predict_proba(X)[:, 1] for t in clf.estimators_], axis=0)
        per_symptom_scores.append(tree_preds.mean(axis=0))
        per_symptom_std.append(tree_preds.std(axis=0))

    scores_matrix = np.stack(per_symptom_scores, axis=1)   # n_herbs x n_query_symptoms
    std_matrix = np.stack(per_symptom_std, axis=1)

    mean_score = scores_matrix.mean(axis=1)
    min_score = scores_matrix.min(axis=1)          # worst-supported symptom in the query
    avg_uncertainty = std_matrix.mean(axis=1)       # higher = trees disagree more = less confident

    result = meta.copy()
    result["relevance_score"] = mean_score
    result["weakest_symptom_score"] = min_score
    result["uncertainty"] = avg_uncertainty
    result["confidence"] = pd.cut(
        avg_uncertainty, bins=[-1, 0.15, 0.30, 1.0], labels=["high", "medium", "low"]
    )

    result = result.sort_values(
        by=["relevance_score", "weakest_symptom_score", "uncertainty"],
        ascending=[False, False, True],
    )
    return result.head(top_n)[["Herbal Name", "Scientific Name", "relevance_score",
                                 "weakest_symptom_score", "confidence"]]


if __name__ == "__main__":
    import joblib
    bundle = joblib.load('models/herb_relevance_model.joblib')

    print("="*70)
    print("fever, cough, sore throat")
    print("="*70)
    print(recommend_herbs_v2(bundle, ['fever', 'cough', 'sore throat'], top_n=5).to_string(index=False))

    print("\n" + "="*70)
    print("single symptom - diabetes")
    print("="*70)
    print(recommend_herbs_v2(bundle, ['diabetes'], top_n=5).to_string(index=False))

    print("\n" + "="*70)
    print("headache, anxiety, insomnia")
    print("="*70)
    print(recommend_herbs_v2(bundle, ['headache', 'anxiety', 'insomnia'], top_n=5).to_string(index=False))
