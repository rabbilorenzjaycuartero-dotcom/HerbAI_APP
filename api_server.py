"""
Flask API wrapping the trained herb-relevance model for the ai_herbal_app
Flutter app. Replaces the app's hardcoded mock_data.dart with real,
trained-model-backed data.

Endpoints:
    GET  /symptoms       -> full symptom vocabulary the model understands
    POST /recommend      -> {"symptoms": [...], "topN": 10} -> ranked herbs
    GET  /plants         -> all herbs, for browse/search screens
    GET  /images/<file>  -> serves photos extracted by extract_images.py

Every herb JSON object matches the Flutter `Plant` model's fields exactly.
Fields not present in the gathered data (rating, reviewCount, categories,
availability, isDohRecognized, isEasyToPrepare) get the same neutral
default for every herb. The four safetyInfo booleans are returned as null
(unverified) rather than a fabricated true/false, since a flat false would
render as a false "not safe" claim in the app's UI. imageUrl points at a
real extracted photo where extract_images.py found one (~38% of herbs),
and is "" otherwise. Photos themselves live in Supabase Storage (private
bucket, see .env) rather than on local disk -- this server fetches them
with the service_role key (which bypasses bucket access rules) and streams
them back through our own /images/<file> route, so the client's imageUrl
shape never changes and no Flutter code needed to change for this move.
"""
import mimetypes
import os
import re

import joblib
import pandas as pd
from dotenv import load_dotenv
from flask import Flask, Response, jsonify, request
from flask_cors import CORS
from supabase import create_client

from train_herb_relevance_model_xgb import recommend_herbs

load_dotenv()

MODEL_PATH = "models/herb_relevance_model_xgb.joblib"
RAW_CSV = "HERBAL_DB - Sheet5_final.csv"
PREPROCESSED_CSV = "herbal_preprocessed_1.csv"

app = Flask(__name__)
CORS(app)

def _list_all_bucket_files(bucket, page_size=1000):
    """bucket.list() caps out well below our ~1,578 files per call (observed
    hard server-side ceiling around 1000-1500 regardless of requested
    limit), so page through with offset until a short page signals the end.
    """
    names, offset = [], 0
    while True:
        page = bucket.list(options={"limit": page_size, "offset": offset})
        names.extend(entry["name"] for entry in page)
        if len(page) < page_size:
            return names
        offset += page_size


print("Connecting to Supabase Storage...")
supabase_client = create_client(
    os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"]
)
supabase_bucket = supabase_client.storage.from_(os.environ["SUPABASE_BUCKET"])
_available_images = set(_list_all_bucket_files(supabase_bucket))
print(f"{len(_available_images)} image(s) available in Supabase Storage.")

print("Loading model bundle...")
bundle = joblib.load(MODEL_PATH)
symptom_cols = bundle["symptom_cols"]

raw_df = pd.read_csv(RAW_CSV)
raw_df = raw_df.loc[:, ~raw_df.columns.str.match(r"^Unnamed")]
raw_df = raw_df.dropna(subset=["Herbal Name"]).reset_index(drop=True)

preprocessed_df = pd.read_csv(PREPROCESSED_CSV)

# NOTE: the source CSV's "ID" column is NOT unique (e.g. ID 1340 is both
# "Spiderflower / Seru Walai" and "Spreading Chisocheton / Patens") -- 86 of
# 1,461 rows share a duplicate ID with another, distinct herb. Joining on
# "ID" (or keying a dict by it) would fan out/collide different herbs
# together. herbal_preprocessed_1.csv and the raw CSV (after the same
# dropna-on-"Herbal Name" filter preprocess_herbal_data.py applies) are
# exactly row-aligned by position, so the raw text columns are attached
# positionally instead, and herbs are keyed by that stable row position
# (the same position used internally by the trained model/herb_matrix),
# exposed to the app as the herb "id".
assert len(raw_df) == len(preprocessed_df), "raw/preprocessed CSV row-count mismatch"
meta_df = preprocessed_df.copy()
for col in ["Symptoms", "Preparation", "Precautions", "Botany"]:
    meta_df[col] = raw_df[col].values
meta_by_pos = meta_df.to_dict("index")
print(f"Loaded {len(meta_by_pos)} herbs, {len(symptom_cols)} symptoms.")


def _split_sentences(text):
    """Split free text on '.'/';' boundaries into a clean list of strings."""
    if not isinstance(text, str) or not text.strip():
        return []
    parts = re.split(r"[.;]\s*", text.strip())
    return [p.strip() for p in parts if p.strip()]


def _image_url(pos):
    """URL for this herb's extracted photo (see extract_images.py), or ''
    if none was extracted for it (~62% of herbs, per the source xlsx)."""
    for ext in (".jpg", ".gif"):
        filename = f"{pos}{ext}"
        if filename in _available_images:
            # request.host_url reflects whatever host the client actually
            # used to reach this server, so it resolves correctly for the
            # Android emulator, a LAN IP, or a USB adb-reverse tunnel
            # without any extra config.
            return f"{request.host_url}images/{filename}"
    return ""


def _herb_to_json(pos, rec, relevance_score=None):
    symptoms_helped = [c for c in symptom_cols if rec.get(c) == 1]
    result = {
        "id": str(pos),
        "name": rec["Herbal Name"],
        "scientificName": rec.get("Scientific Name") or "",
        "description": rec.get("Symptoms") if isinstance(rec.get("Symptoms"), str) else "",
        "medicinalUses": [s.title() for s in symptoms_helped],
        "symptomsHelped": [s.title() for s in symptoms_helped],
        "preparationMethods": _split_sentences(rec.get("Preparation")),
        "safetyWarnings": _split_sentences(rec.get("Precautions")),
        "ethnobotanicalInfo": rec.get("Botany") if isinstance(rec.get("Botany"), str) else "",
        "categories": [],
        "rating": 0.0,
        "reviewCount": 0,
        "imageUrl": _image_url(pos),
        "availability": "common",
        "isDohRecognized": False,
        "isEasyToPrepare": True,
        "safetyInfo": {
            "safeForAdults": None,
            "safeForChildren": None,
            "safeForElderly": None,
            "safeForPregnant": None,
        },
    }
    if relevance_score is not None:
        result["relevanceScore"] = relevance_score
    return result


@app.route("/images/<path:filename>", methods=["GET"])
def get_image(filename):
    if filename not in _available_images:
        return "Not found", 404
    data = supabase_bucket.download(filename)
    content_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"
    return Response(data, mimetype=content_type)


@app.route("/symptoms", methods=["GET"])
def get_symptoms():
    return jsonify([{"id": s, "name": s.title()} for s in symptom_cols])


@app.route("/plants", methods=["GET"])
def get_plants():
    return jsonify([_herb_to_json(pos, rec) for pos, rec in meta_by_pos.items()])


@app.route("/recommend", methods=["POST"])
def post_recommend():
    data = request.get_json(force=True) or {}
    symptoms = data.get("symptoms", [])
    top_n = int(data.get("topN", 10))

    result_df = recommend_herbs(bundle, symptoms, top_n=top_n)
    if result_df.empty:
        return jsonify([])

    out = []
    for pos, row in result_df.iterrows():
        rec = meta_by_pos.get(pos)
        if rec is None:
            continue
        out.append(_herb_to_json(pos, rec, relevance_score=float(row["relevance_score"])))
    return jsonify(out)


if __name__ == "__main__":
    # Local dev only -- when deployed, gunicorn imports `app` directly and
    # never runs this block, so debug=True here never reaches production.
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)), debug=True, use_reloader=False)
