import numpy as np
import pandas as pd
import xgboost as xgb

def recommend_herbs_xgb(bundle, query_symptoms, top_n=5):
    """
    Rank herbs for a list of query symptoms using the XGBoost relevance model.
    Includes a tie-breaker (weakest_symptom_score) and a confidence indicator
    based on how much predictions still shift in the later boosting rounds --
    XGBoost doesn't have independent trees to vote like Random Forest, so we
    instead check prediction stability as more boosting rounds are added.
    A converged/confident prediction barely changes in the final rounds;
    one still swinging late is less certain.
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
    booster = clf.get_booster()
    n_trees = clf.n_estimators

    # check predictions at 70%, 85%, 100% of boosting rounds -> late-stage stability
    checkpoints = sorted(set([int(n_trees * 0.7), int(n_trees * 0.85), n_trees]))

    per_symptom_scores = []
    per_symptom_std = []

    for q in valid_q:
        j = symptom_to_idx[q]
        feats = M.copy()
        feats[:, j] = 0
        n_present = np.maximum(feats.sum(axis=1), 1)
        co_scores = (feats @ pmi[j]) / n_present
        onehot = np.zeros((n_herbs, n_symptoms))
        onehot[:, j] = 1
        X = np.column_stack([feats, onehot, genus_freq, co_scores])
        dmat = xgb.DMatrix(X)

        staged = np.stack(
            [booster.predict(dmat, iteration_range=(0, c)) for c in checkpoints],
            axis=0,
        )
        per_symptom_scores.append(staged[-1])          # final-round prediction
        per_symptom_std.append(staged.std(axis=0))      # late-stage instability

    scores_matrix = np.stack(per_symptom_scores, axis=1)
    std_matrix = np.stack(per_symptom_std, axis=1)

    mean_score = scores_matrix.mean(axis=1)
    min_score = scores_matrix.min(axis=1)
    avg_instability = std_matrix.mean(axis=1)

    result = meta.copy()
    result["relevance_score"] = mean_score
    result["weakest_symptom_score"] = min_score
    result["confidence"] = pd.cut(
        avg_instability, bins=[-1, 0.01, 0.03, 1.0], labels=["high", "medium", "low"]
    )

    result = result.sort_values(
        by=["relevance_score", "weakest_symptom_score"],
        ascending=[False, False],
    )
    return result.head(top_n)[["Herbal Name", "Scientific Name", "relevance_score",
                                 "weakest_symptom_score", "confidence"]]


if __name__ == "__main__":
    import joblib
    bundle = joblib.load('models/herb_relevance_model_xgb.joblib')

    print("="*70)
    print("XGBoost -- fever, cough, sore throat")
    print("="*70)
    print(recommend_herbs_xgb(bundle, ['fever', 'cough', 'sore throat'], top_n=5).to_string(index=False))

    print("\n" + "="*70)
    print("XGBoost -- headache, anxiety, insomnia")
    print("="*70)
    print(recommend_herbs_xgb(bundle, ['headache', 'anxiety', 'thinsomnia'], top_n=5).to_string(index=False))

    print("\n" + "="*70)
    print("XGBoost -- diarrhea, stomachache")
    print("="*70)
    print(recommend_herbs_xgb(bundle, ['diarrhea', 'stomachache'], top_n=5).to_string(index=False))
