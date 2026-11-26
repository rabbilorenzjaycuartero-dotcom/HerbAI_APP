"""
Server-side Usage Reports for the admin screen (panel revision).

The app used to download every chat log to the phone and count there, which
stops being correct (and usable) once there are thousands of users. Here the
server reads Firestore once per period (cached briefly), computes the
summary, and serves the user list and activity log in pages of 25 with
search and filters. It also builds the full-data Excel export.

Pure functions only (no Flask/Firestore imports), so they are easy to test;
api_server.py loads the documents and calls these.
"""
import io
import re
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone

PH_TZ = timezone(timedelta(hours=8))  # report dates in Philippine time
RANGES = {"7d": 7, "30d": 30, "all": None}
AGE_GROUPS = ["17 and below", "18-24", "25-34", "35-44", "45-59", "60 and above", "Not specified"]
PAGE_SIZE = 25

STOPWORDS = {
    # English
    "i", "im", "i'm", "ive", "a", "an", "the", "and", "or", "my", "is", "am", "are", "was", "me", "of", "to",
    "in", "on", "for", "with", "it", "also", "so", "very", "really", "feel", "feeling", "been", "have", "has",
    "had", "since", "what", "how", "can", "do", "does", "please", "some", "that", "this", "there", "be", "but",
    "just", "today", "now", "lately", "little", "bit", "any", "herb", "herbs", "good", "help", "need", "want",
    # Bisaya
    "naa", "ko", "koy", "kog", "ako", "akong", "ang", "sa", "ug", "og", "nga", "man", "kaayo", "karon", "unsa",
    "unsaon", "pa", "na", "lang", "ra", "kay", "mao", "kini", "ni", "ana", "gyud", "jud", "wala", "dili", "nako",
    "nimo", "pod", "pud", "sad", "usab", "unta", "diay", "bitaw", "si", "ka", "mo", "ta", "ba", "tungod", "kung",
    "para", "maayo", "tambal", "gibati", "akoa", "nag", "naay", "kahibalo",
    # Tagalog
    "may", "ng", "at", "mga", "ay", "po", "din", "rin", "ito", "yung", "kasi", "akin", "ano", "nang", "pero",
    "lagi", "sobra", "masyado", "ngayon", "yun", "gamot", "mabuti",
}


def range_start(range_key, now=None):
    days = RANGES.get(range_key, 30)
    if days is None:
        return None
    return (now or datetime.now(timezone.utc)) - timedelta(days=days)


def age_group(age):
    if not isinstance(age, (int, float)):
        return "Not specified"
    if age <= 17:
        return "17 and below"
    if age <= 24:
        return "18-24"
    if age <= 34:
        return "25-34"
    if age <= 44:
        return "35-44"
    if age <= 59:
        return "45-59"
    return "60 and above"


def designation_label(designation, other=None):
    if not designation:
        return "Not specified"
    if designation == "Others" and other:
        return f"Others ({other})"
    return designation


def designation_group(label):
    return "Others" if str(label).startswith("Others") else (label or "Not specified")


def _top(counter, n):
    return [{"label": k, "count": v} for k, v in counter.most_common(n)]


def _words(text):
    for w in re.split(r"[^a-zA-ZÀ-ÿñÑ'\-]+", (text or "").lower()):
        w = w.strip("'-")
        if len(w) >= 3 and w not in STOPWORDS:
            yield w


def normalize_user(uid, data):
    created = data.get("createdAt")
    return {
        "uid": uid,
        "name": data.get("name") or "",
        "email": data.get("email") or "",
        "age": data.get("age"),
        "ageGroup": age_group(data.get("age")),
        "designation": designation_label(data.get("designation"), data.get("designationOther")),
        "createdAt": created.isoformat() if hasattr(created, "isoformat") else None,
        "_created": created,
    }


def normalize_log(log_id, data):
    created = data.get("createdAt")
    return {
        "id": log_id,
        "source": data.get("source") or "chatbot",
        "uid": data.get("uid") or "",
        "userName": data.get("userName") or "",
        "age": data.get("age"),
        "ageGroup": age_group(data.get("age")),
        "designation": data.get("designation") or "Not specified",
        "message": data.get("message") or "",
        "detectedSymptoms": list(data.get("detectedSymptoms") or []),
        "conditions": list(data.get("conditions") or []),
        "recommendedHerbs": list(data.get("recommendedHerbs") or []),
        "replySource": data.get("replySource"),
        "createdAt": created.isoformat() if hasattr(created, "isoformat") else None,
        "_created": created,
    }


def _daily_trend(logs, range_key, now):
    """Chats and checklist searches per day (7d/30d) or per month (all)."""
    buckets = defaultdict(lambda: {"chatbot": 0, "checklist": 0})
    for log in logs:
        created = log["_created"]
        if not hasattr(created, "astimezone"):
            continue
        local = created.astimezone(PH_TZ)
        key = local.strftime("%Y-%m") if range_key == "all" else local.strftime("%Y-%m-%d")
        if log["source"] == "checklist":
            buckets[key]["checklist"] += 1
        elif log["message"]:
            buckets[key]["chatbot"] += 1
    local_now = now.astimezone(PH_TZ)
    if range_key == "all":
        keys, cursor = [], local_now.replace(day=1)
        for _ in range(12):
            keys.append(cursor.strftime("%Y-%m"))
            cursor = (cursor - timedelta(days=1)).replace(day=1)
        keys.reverse()
    else:
        days = RANGES[range_key]
        keys = [(local_now - timedelta(days=i)).strftime("%Y-%m-%d") for i in range(days - 1, -1, -1)]
    return [{"label": k, **buckets[k]} for k in keys]


def build_summary(users, logs, range_key, now=None):
    now = now or datetime.now(timezone.utc)
    chat_messages = [l for l in logs if l["source"] != "checklist" and l["message"]]
    checklist = [l for l in logs if l["source"] == "checklist"]

    concerns = Counter(s for l in logs for s in l["detectedSymptoms"])
    by_designation, by_age = defaultdict(Counter), defaultdict(Counter)
    for l in logs:
        for s in l["detectedSymptoms"]:
            by_designation[designation_group(l["designation"])][s] += 1
            by_age[l["ageGroup"]][s] += 1

    age_counts = Counter(u["ageGroup"] for u in users)
    return {
        "range": range_key,
        "generatedAt": now.isoformat(),
        "totals": {
            "registeredUsers": len(users),
            "activeUsers": len({l["uid"] for l in logs if l["uid"]}),
            "chatMessages": len(chat_messages),
            "checklistSearches": len(checklist),
            "concernsLogged": sum(concerns.values()),
        },
        "trend": _daily_trend(logs, range_key, now),
        "usersByDesignation": _top(Counter(designation_group(u["designation"]) for u in users), 20),
        "usersByAgeGroup": [{"label": g, "count": age_counts[g]} for g in AGE_GROUPS if age_counts[g]],
        "topConcerns": _top(concerns, 10),
        "concernsByDesignation": [
            {"group": g, "top": _top(c, 3)} for g, c in sorted(by_designation.items()) if c
        ],
        "concernsByAgeGroup": [
            {"group": g, "top": _top(by_age[g], 3)} for g in AGE_GROUPS if by_age.get(g)
        ],
        "topWords": _top(Counter(w for l in chat_messages for w in _words(l["message"])), 15),
        "topHerbs": _top(Counter(h for l in logs for h in l["recommendedHerbs"]), 10),
    }


def _public(item):
    return {k: v for k, v in item.items() if not k.startswith("_")}


def page(items, offset, limit=PAGE_SIZE):
    offset = max(0, int(offset or 0))
    limit = max(1, min(100, int(limit or PAGE_SIZE)))
    chunk = items[offset:offset + limit]
    nxt = offset + limit if offset + limit < len(items) else None
    return {"items": [_public(i) for i in chunk], "total": len(items), "nextOffset": nxt}


def filter_users(users, query="", designation="", age_group_filter=""):
    q = (query or "").strip().lower()
    out = []
    for u in users:
        if q and q not in u["name"].lower() and q not in u["email"].lower():
            continue
        if designation and designation_group(u["designation"]) != designation:
            continue
        if age_group_filter and u["ageGroup"] != age_group_filter:
            continue
        out.append(u)
    return out


def filter_logs(logs, query="", source="", designation="", symptom=""):
    q = (query or "").strip().lower()
    out = []
    for l in logs:
        if source and l["source"] != source:
            continue
        if designation and designation_group(l["designation"]) != designation:
            continue
        if symptom and symptom not in l["detectedSymptoms"]:
            continue
        if q and q not in l["message"].lower() and q not in l["userName"].lower() \
                and not any(q in s for s in l["detectedSymptoms"]):
            continue
        out.append(l)
    return out


def build_xlsx(summary, users, logs):
    """Summary, Users, Chatbot Logs and Checklist Logs sheets."""
    from openpyxl import Workbook
    from openpyxl.styles import Alignment, Font, PatternFill
    from openpyxl.utils import get_column_letter

    green = PatternFill("solid", fgColor="2E7D32")
    white_bold = Font(bold=True, color="FFFFFF")

    def sheet(ws, headers, rows, widths):
        ws.append(headers)
        for cell in ws[1]:
            cell.fill, cell.font = green, white_bold
            cell.alignment = Alignment(vertical="center")
        for row in rows:
            ws.append(row)
        for i, w in enumerate(widths, start=1):
            ws.column_dimensions[get_column_letter(i)].width = w
        ws.freeze_panes = "A2"
        ws.auto_filter.ref = ws.dimensions

    def local(iso):
        if not iso:
            return ""
        return datetime.fromisoformat(iso).astimezone(PH_TZ).strftime("%Y-%m-%d %H:%M")

    wb = Workbook()
    ws = wb.active
    ws.title = "Summary"
    t = summary["totals"]
    rows = [
        ["HerbAI Usage Report", ""],
        ["Period", {"7d": "Last 7 days", "30d": "Last 30 days", "all": "All time"}[summary["range"]]],
        ["Generated (PH time)", local(summary["generatedAt"])],
        ["", ""],
        ["Registered users (all time)", t["registeredUsers"]],
        ["Active users in period", t["activeUsers"]],
        ["Chatbot messages in period", t["chatMessages"]],
        ["Checklist searches in period", t["checklistSearches"]],
        ["", ""],
        ["Top symptom concerns", "Count"],
        *[[r["label"], r["count"]] for r in summary["topConcerns"]],
        ["", ""],
        ["Users by designation", "Count"],
        *[[r["label"], r["count"]] for r in summary["usersByDesignation"]],
        ["", ""],
        ["Users by age group", "Count"],
        *[[r["label"], r["count"]] for r in summary["usersByAgeGroup"]],
        ["", ""],
        ["Most recommended herbs", "Count"],
        *[[r["label"], r["count"]] for r in summary["topHerbs"]],
    ]
    for r in rows:
        ws.append(r)
    ws["A1"].font = Font(bold=True, size=14, color="2E7D32")
    for row in ws.iter_rows():
        if row[1].value == "Count":
            row[0].font = row[1].font = Font(bold=True)
    ws.column_dimensions["A"].width = 40
    ws.column_dimensions["B"].width = 22

    sheet(wb.create_sheet("Users"), ["Name", "Email", "Age", "Age group", "Designation", "Registered"],
          [[u["name"], u["email"], u["age"], u["ageGroup"], u["designation"], local(u["createdAt"])] for u in users],
          [28, 32, 8, 14, 26, 18])
    chat = [l for l in logs if l["source"] != "checklist"]
    sheet(wb.create_sheet("Chatbot Logs"),
          ["Date (PH)", "User", "Age", "Designation", "Typed message", "Detected symptoms", "Conditions",
           "Recommended herbs"],
          [[local(l["createdAt"]), l["userName"], l["age"], l["designation"], l["message"],
            ", ".join(l["detectedSymptoms"]), ", ".join(l["conditions"]), ", ".join(l["recommendedHerbs"])]
           for l in chat],
          [18, 24, 8, 22, 50, 32, 18, 50])
    checklist = [l for l in logs if l["source"] == "checklist"]
    sheet(wb.create_sheet("Checklist Logs"),
          ["Date (PH)", "User", "Age", "Designation", "Selected symptoms", "Conditions", "Recommended herbs"],
          [[local(l["createdAt"]), l["userName"], l["age"], l["designation"], ", ".join(l["detectedSymptoms"]),
            ", ".join(l["conditions"]), ", ".join(l["recommendedHerbs"])] for l in checklist],
          [18, 24, 8, 22, 40, 18, 50])

    buf = io.BytesIO()
    wb.save(buf)
    return buf.getvalue()
