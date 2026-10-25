"""
Flask API wrapping the trained herb-relevance model for the ai_herbal_app
Flutter app. Replaces the app's hardcoded mock_data.dart with real,
trained-model-backed data.

Endpoints:
    GET  /symptoms       -> full symptom vocabulary the model understands
    POST /recommend      -> {"symptoms": [...], "topN": 10} -> ranked herbs
    GET  /plants         -> all herbs, for browse/search screens
    GET  /images/<file>  -> serves photos extracted by extract_images.py
    GET  /check-email    -> {"exists": bool} via Firebase Admin, for the
                            Register screen's real-time "already registered"
                            hint (see firebase-service-account.json below)
    POST /send-verification-code -> emails a 6-digit code (Gmail SMTP, see
                            GMAIL_SENDER_EMAIL/GMAIL_APP_PASSWORD in .env) and
                            stores it in Firestore; requires a Firebase ID
                            token in `Authorization: Bearer <token>`
    POST /verify-email-code -> {"code": "123456"} -> on match, flips the
                            caller's emailVerified via Firebase Admin and
                            deletes the stored code; same Bearer token auth
    POST /login-lockout/status         -> {"email": ...} -> {"locked": bool,
                            "remainingSeconds": int}; escalating brute-force
                            lockout bookkeeping for the Login screen (no
                            auth -- the caller isn't signed in yet). See
                            LOGIN_LOCKOUT_SCHEDULE_NOTE for the schedule.
    POST /login-lockout/record-failure -> same shape as /status; call after
                            a failed Firebase sign-in to advance the counter
    POST /login-lockout/record-success -> {"email": ...} -> clears the
                            counter; call after a successful sign-in

/recommend excludes herbs flagged dangerous in their Precautions text unless
the model's relevance score clears a high confidence bar -- see
herb_safety.py (shared with try_symptom_extractor.py so the same rule
applies wherever recommendations are generated) for the full rationale:
found necessary after a real case where a rare single-symptom query
("toothache", only 20 tagged herbs) ranked a poisonous, actually-unrelated
herb #1 ahead of the genuinely correct, well-labeled matches.

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
import random
import re
import smtplib
from datetime import datetime, timedelta, timezone
from email.mime.text import MIMEText

import firebase_admin
import joblib
import pandas as pd
from dotenv import load_dotenv
from firebase_admin import auth as firebase_auth
from firebase_admin import credentials as firebase_credentials
from firebase_admin import firestore as firebase_firestore
from flask import Flask, Response, jsonify, request
from flask_cors import CORS
from supabase import create_client

from train_herb_relevance_model_xgb import recommend_herbs
from train_symptom_extractor import extract_symptoms_from_text
from symptom_spelling import build_symptom_words, spelling_suggestions
from condition_safety import get_condition_warnings
from herb_safety import is_flagged_dangerous, DANGER_CONFIDENCE_THRESHOLD

load_dotenv()

MODEL_PATH = "models/herb_relevance_model_xgb.joblib"
EXTRACTOR_PATH = "models/symptom_extractor.joblib"
MAX_SYMPTOM_TEXT_LENGTH = 500
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
supabase_bucket = None
_available_images = set()
try:
    supabase_client = create_client(
        os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    )
    supabase_bucket = supabase_client.storage.from_(os.environ["SUPABASE_BUCKET"])
    _available_images = set(_list_all_bucket_files(supabase_bucket))
    print(f"{len(_available_images)} image(s) available in Supabase Storage.")
except Exception as error:
    # Herb photos are a nice-to-have (_image_url already falls back to ""
    # for any herb without one, which the Flutter app renders as a plain
    # icon) -- they shouldn't be a hard dependency for the whole API. With
    # supabase_bucket left None and _available_images empty, every route
    # below still works, just without photos, instead of the process
    # dying before a single Flask route is registered.
    supabase_bucket = None
    _available_images = set()
    print(f"WARNING: Supabase Storage unavailable ({error!r}); continuing without herb photos.")

print("Connecting to Firebase Admin SDK...")
_firebase_admin_ready = False
firestore_db = None
try:
    service_account_path = os.environ.get(
        "FIREBASE_SERVICE_ACCOUNT_PATH", "firebase-service-account.json"
    )
    cred = firebase_credentials.Certificate(service_account_path)
    firebase_admin.initialize_app(cred)
    _firebase_admin_ready = True
    firestore_db = firebase_firestore.client()
    print("Firebase Admin SDK ready; /check-email and email-code verification can run for real.")
except Exception as error:
    # Both the "email already registered" check and the email-code
    # verification flow are nice-to-haves, not hard dependencies -- same
    # fail-soft approach as the Supabase photos connection above. Until the
    # service account key is dropped in, those routes just report
    # unavailable instead of crashing the whole API before a single route
    # registers.
    print(f"WARNING: Firebase Admin SDK unavailable ({error!r}); /check-email, /send-verification-code and /verify-email-code will all report unavailable.")


def _verify_request_token():
    """Decodes the caller's Firebase ID token from the Authorization header,
    so /send-verification-code and /verify-email-code always act on the
    actual signed-in account rather than trusting a client-supplied
    uid/email -- otherwise anyone could request or burn through codes for
    an email address that isn't theirs. Returns None if missing/invalid.
    """
    header = request.headers.get("Authorization", "")
    if not header.startswith("Bearer "):
        return None
    try:
        # clock_skew_seconds tolerates small drift between this container's
        # clock and the clock Google's servers stamped the token's "issued
        # at" with -- observed in testing to otherwise reject a
        # freshly-issued, perfectly valid token as "used too early" by a
        # couple of seconds.
        return firebase_auth.verify_id_token(header[len("Bearer "):], clock_skew_seconds=10)
    except Exception:
        return None


VERIFICATION_CODE_TTL_SECONDS = 600
VERIFICATION_CODE_RESEND_COOLDOWN_SECONDS = 30
MAX_VERIFICATION_ATTEMPTS = 5


LOGIN_LOCKOUT_SCHEDULE_NOTE = (
    "Every 3rd consecutive failed attempt locks the account: 15s at attempt "
    "3, 30s at attempt 6, 60s at attempt 9 and every multiple of 3 after "
    "that. The counter only resets on a successful login, not when a lock "
    "expires -- e.g. attempts 4 and 5 (after the 15s lock clears) are free "
    "until attempt 6 locks again."
)


def _lockout_duration_seconds(attempt_count):
    if attempt_count < 3 or attempt_count % 3 != 0:
        return 0
    if attempt_count == 3:
        return 15
    if attempt_count == 6:
        return 30
    return 60


def _send_verification_code_email(to_email, code):
    sender = os.environ["GMAIL_SENDER_EMAIL"]
    app_password = os.environ["GMAIL_APP_PASSWORD"]
    message = MIMEText(
        f"Your HERBAI verification code is: {code}\n\nThis code expires in 10 minutes."
    )
    message["Subject"] = "Your HERBAI verification code"
    message["From"] = sender
    message["To"] = to_email
    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
        server.login(sender, app_password)
        server.sendmail(sender, [to_email], message.as_string())

print("Loading model bundle...")
bundle = joblib.load(MODEL_PATH)
symptom_cols = bundle["symptom_cols"]
extractor_bundle = joblib.load(EXTRACTOR_PATH)
symptom_words = build_symptom_words(extractor_bundle["symptom_cols"])

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
for col in ["Symptoms", "Preparation", "Precautions", "Botany", "Source URL"]:
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


def _herb_to_json(pos, rec, relevance_score=None, conditions=None):
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
        "sourceUrl": rec.get("Source URL") if isinstance(rec.get("Source URL"), str) else "",
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
        "conditionWarnings": get_condition_warnings(rec.get("Precautions"), conditions),
    }
    if relevance_score is not None:
        result["relevanceScore"] = relevance_score
    return result


@app.route("/images/<path:filename>", methods=["GET"])
def get_image(filename):
    if supabase_bucket is None or filename not in _available_images:
        return "Not found", 404
    data = supabase_bucket.download(filename)
    content_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"
    return Response(data, mimetype=content_type)


@app.route("/login-lockout/status", methods=["POST"])
def post_login_lockout_status():
    email = str((request.get_json(force=True) or {}).get("email", "")).strip().lower()
    if not email:
        return jsonify({"error": "email required"}), 400
    if firestore_db is None:
        return jsonify({"locked": False, "remainingSeconds": 0})

    doc = firestore_db.collection("login_lockouts").document(email).get()
    if not doc.exists:
        return jsonify({"locked": False, "remainingSeconds": 0})

    locked_until = doc.to_dict().get("lockedUntil")
    now = datetime.now(timezone.utc)
    if locked_until and now < locked_until:
        return jsonify({"locked": True, "remainingSeconds": int((locked_until - now).total_seconds()) + 1})
    return jsonify({"locked": False, "remainingSeconds": 0})


@app.route("/login-lockout/record-failure", methods=["POST"])
def post_login_lockout_record_failure():
    email = str((request.get_json(force=True) or {}).get("email", "")).strip().lower()
    if not email:
        return jsonify({"error": "email required"}), 400
    if firestore_db is None:
        return jsonify({"locked": False, "remainingSeconds": 0})

    doc_ref = firestore_db.collection("login_lockouts").document(email)
    doc = doc_ref.get()
    attempts = (doc.to_dict().get("failedAttempts", 0) if doc.exists else 0) + 1

    lock_seconds = _lockout_duration_seconds(attempts)
    now = datetime.now(timezone.utc)
    locked_until = now + timedelta(seconds=lock_seconds) if lock_seconds else None
    doc_ref.set({"failedAttempts": attempts, "lockedUntil": locked_until})

    if lock_seconds:
        return jsonify({"locked": True, "remainingSeconds": lock_seconds})
    return jsonify({"locked": False, "remainingSeconds": 0})


@app.route("/login-lockout/record-success", methods=["POST"])
def post_login_lockout_record_success():
    email = str((request.get_json(force=True) or {}).get("email", "")).strip().lower()
    if email and firestore_db is not None:
        firestore_db.collection("login_lockouts").document(email).delete()
    return jsonify({"ok": True})


@app.route("/check-email", methods=["GET"])
def get_check_email():
    email = (request.args.get("email") or "").strip()
    if not re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", email):
        return jsonify({"error": "invalid email"}), 400

    if not _firebase_admin_ready:
        return jsonify({"exists": False, "unknown": True})

    try:
        firebase_auth.get_user_by_email(email)
        return jsonify({"exists": True})
    except firebase_auth.UserNotFoundError:
        return jsonify({"exists": False})
    except Exception as error:
        # Fail open: a transient Admin SDK/network error should never block
        # registration over a check that's only ever a convenience hint.
        print(f"WARNING: /check-email lookup failed for an address ({error!r}).")
        return jsonify({"exists": False, "unknown": True})


@app.route("/send-verification-code", methods=["POST"])
def post_send_verification_code():
    if not _firebase_admin_ready or firestore_db is None:
        return jsonify({"error": "verification service unavailable"}), 503
    claims = _verify_request_token()
    if claims is None:
        return jsonify({"error": "unauthorized"}), 401

    uid = claims["uid"]
    email = claims.get("email")
    if not email:
        return jsonify({"error": "no email on this account"}), 400

    doc_ref = firestore_db.collection("email_verification_codes").document(uid)
    now = datetime.now(timezone.utc)
    existing = doc_ref.get()
    if existing.exists:
        last_sent = existing.to_dict().get("lastSentAt")
        if last_sent and (now - last_sent).total_seconds() < VERIFICATION_CODE_RESEND_COOLDOWN_SECONDS:
            return jsonify({"error": "please wait before requesting another code"}), 429

    code = f"{random.randint(0, 999999):06d}"
    doc_ref.set({
        "code": code,
        "email": email,
        "expiresAt": now + timedelta(seconds=VERIFICATION_CODE_TTL_SECONDS),
        "lastSentAt": now,
        "attempts": 0,
    })

    try:
        _send_verification_code_email(email, code)
    except Exception as error:
        print(f"WARNING: failed to send verification code email ({error!r}).")
        return jsonify({"error": "failed to send email"}), 502

    return jsonify({"sent": True})


@app.route("/verify-email-code", methods=["POST"])
def post_verify_email_code():
    if not _firebase_admin_ready or firestore_db is None:
        return jsonify({"verified": False, "reason": "verification service unavailable"}), 503
    claims = _verify_request_token()
    if claims is None:
        return jsonify({"verified": False, "reason": "unauthorized"}), 401

    uid = claims["uid"]
    submitted_code = str((request.get_json(force=True) or {}).get("code", "")).strip()

    doc_ref = firestore_db.collection("email_verification_codes").document(uid)
    snapshot = doc_ref.get()
    if not snapshot.exists:
        return jsonify({"verified": False, "reason": "No code requested yet. Tap resend."}), 400

    data = snapshot.to_dict()
    now = datetime.now(timezone.utc)
    if now > data["expiresAt"]:
        doc_ref.delete()
        return jsonify({"verified": False, "reason": "That code expired. Tap resend for a new one."}), 400

    if data.get("attempts", 0) >= MAX_VERIFICATION_ATTEMPTS:
        doc_ref.delete()
        return jsonify({"verified": False, "reason": "Too many attempts. Tap resend for a new code."}), 429

    if submitted_code != data["code"]:
        doc_ref.update({"attempts": firebase_firestore.Increment(1)})
        return jsonify({"verified": False, "reason": "Incorrect code. Please try again."}), 400

    firebase_auth.update_user(uid, email_verified=True)
    doc_ref.delete()
    return jsonify({"verified": True})


@app.route("/symptoms", methods=["GET"])
def get_symptoms():
    return jsonify([{"id": s, "name": s.title()} for s in symptom_cols])


@app.route("/plants", methods=["GET"])
def get_plants():
    return jsonify([_herb_to_json(pos, rec) for pos, rec in meta_by_pos.items()])


@app.route("/extract_symptoms", methods=["POST"])
def post_extract_symptoms():
    data = request.get_json(force=True) or {}
    text = str(data.get("text", "")).strip()
    if len(text) > MAX_SYMPTOM_TEXT_LENGTH:
        return jsonify({"error": f"text must be {MAX_SYMPTOM_TEXT_LENGTH} characters or fewer"}), 400
    if not text:
        return jsonify({"symptoms": [], "spellingSuggestions": []})

    return jsonify({
        "symptoms": extract_symptoms_from_text(extractor_bundle, text),
        "spellingSuggestions": [
            {"typed": wrong, "suggestion": right}
            for wrong, right in spelling_suggestions(text, symptom_words)
        ],
    })


@app.route("/recommend", methods=["POST"])
def post_recommend():
    data = request.get_json(force=True) or {}
    symptoms = data.get("symptoms", [])
    top_n = int(data.get("topN", 10))
    conditions = data.get("conditions", [])

    # Fetch a larger candidate pool than requested so filtering out
    # low-confidence dangerous herbs below can still leave top_n results,
    # instead of truncating first and losing the chance to backfill.
    result_df = recommend_herbs(bundle, symptoms, top_n=max(top_n * 5, 50))
    if result_df.empty:
        return jsonify([])

    out = []
    for pos, row in result_df.iterrows():
        rec = meta_by_pos.get(pos)
        if rec is None:
            continue
        score = float(row["relevance_score"])
        if is_flagged_dangerous(rec.get("Precautions")) and score < DANGER_CONFIDENCE_THRESHOLD:
            continue
        out.append(_herb_to_json(pos, rec, relevance_score=score, conditions=conditions))
        if len(out) >= top_n:
            break
    return jsonify(out)


if __name__ == "__main__":
    # Local dev only -- when deployed, gunicorn imports `app` directly and
    # never runs this block, so debug=True here never reaches production.
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)), debug=True, use_reloader=False)
