"""
Generate casual (text, symptom) training phrases for train_symptom_extractor.py.

Kept as a SEPARATE dataset from HERBAL_DB - Sheet5_final.csv on purpose --
that file is one row per real herb, read directly by the herb-ranking
pipeline (preprocess_herbal_data.py, train_herb_relevance_model_xgb.py,
api_server.py). Mixing synthetic phrase rows into it would make fake
"herbs" show up in real recommendations. This script's output
(symptom_phrases_training.csv) is only ever read by train_symptom_extractor.py.

Produces ~10 phrases per symptom (4 English + 3 Bisaya + 3 Tagalog), using
native Bisaya/Tagalog terms where they genuinely exist, and natural
code-switching (the English/clinical term embedded in a Bisaya/Tagalog
sentence frame) for more technical/compound symptom phrases -- which is
itself how Filipinos commonly talk, not just a fallback.
"""
import csv
import pandas as pd

PREPROCESSED_CSV = "herbal_preprocessed_1.csv"
OUTPUT_CSV = "symptom_phrases_training.csv"

# English symptom key -> natural Bisaya phrase.
BISAYA_TERMS = {
    "fever": "hilanat", "cough": "ubo", "colds": "sip-on",
    "sore throat": "sakit sa tutunlan", "headache": "sakit sa ulo",
    "toothache": "sakit sa ngipon", "stomach pain": "sakit sa tiyan",
    "stomachache": "sakit sa tiyan", "stomach cramps": "kuyos sa tiyan",
    "stomach discomfort": "kaguol sa tiyan", "diarrhea": "kalibang",
    "body pain": "sakit sa lawas", "body aches": "sakit sa lawas",
    "muscle pain": "sakit sa kaunuran", "muscle aches": "sakit sa kaunuran",
    "muscle spasms": "kisi-kisi sa kaunuran", "joint pain": "sakit sa lutahan",
    "joint discomfort": "kaguol sa lutahan", "wounds": "samad",
    "minor wounds": "gamay nga samad", "cuts": "samad", "burns": "paso",
    "minor burns": "gamay nga paso", "itching": "katol",
    "skin irritation": "katol sa panit", "scalp irritation": "katol sa ulo",
    "skin conditions": "problema sa panit", "skin disorders": "problema sa panit",
    "skin diseases": "sakit sa panit", "skin infections": "impeksyon sa panit",
    "skin inflammation": "hubag sa panit", "skin ulcers": "hubag sa panit",
    "minor skin conditions": "gamay nga problema sa panit",
    "minor skin infections": "gamay nga impeksyon sa panit",
    "fatigue": "kakapoy", "weakness": "kaluya", "body weakness": "kaluya sa lawas",
    "nausea": "kaduwal", "insomnia": "dili makatulog", "anxiety": "kabalaka",
    "nervousness": "kahadlok", "restlessness": "dili mahimutang", "stress": "stress",
    "high blood pressure": "taas nga presyur", "hypertension": "taas nga presyur",
    "diabetes": "diabetes", "urinary problems": "problema sa pag-ihi",
    "urinary complaints": "reklamo sa pag-ihi", "urinary discomfort": "kaguol sa pag-ihi",
    "urinary disorders": "problema sa pag-ihi", "urinary issues": "problema sa pag-ihi",
    "urinary tract disorders": "problema sa dalan sa ihi",
    "urinary tract infections": "impeksyon sa dalan sa ihi",
    "urinary tract problems": "problema sa dalan sa ihi",
    "painful urination": "sakit mo-ihi", "constipation": "lisod molibang",
    "bloating": "paspas nga tiyan", "gas": "gas sa tiyan", "flatulence": "gas sa tiyan",
    "indigestion": "dili matunaw ang pagkaon", "digestion": "panagtunaw",
    "digestive discomfort": "kaguol sa tiyan", "digestive disorders": "problema sa panagtunaw",
    "digestive issues": "problema sa panagtunaw", "digestive problems": "problema sa panagtunaw",
    "digestive complaints": "reklamo sa panagtunaw",
    "minor digestive discomfort": "gamay nga kaguol sa tiyan",
    "minor digestive disorders": "gamay nga problema sa panagtunaw",
    "intestinal discomfort": "kaguol sa tinai", "intestinal problems": "problema sa tinai",
    "intestinal parasites": "bulate", "intestinal worms": "bulate",
    "swelling": "hubag", "bruises": "pasa", "bleeding": "pagdugo",
    "minor bleeding": "gamay nga pagdugo", "fractures": "bali sa bukog",
    "sprains": "balikog", "insect bites": "kagat sa insekto",
    "snake bites": "kagat sa halas", "allergies": "alerdyi",
    "asthma": "lisod ginhawa", "bronchitis": "hubag sa bronchial tube",
    "earache": "sakit sa dalunggan", "eye irritation": "katol sa mata",
    "mouth sores": "singaw", "mouth ulcers": "singaw", "dandruff": "abog sa buhok",
    "lice infestation": "kuto", "warts": "bulingit", "boils": "pigsa",
    "hemorrhoids": "almuranas", "jaundice": "paninilaw", "malaria": "malaria",
    "menstrual discomfort": "kaguol sa binulan", "menstrual disorders": "problema sa binulan",
    "nosebleeds": "gilanat ang ilong", "gout": "gout", "rheumatic pain": "sakit sa reyuma",
    "rheumatism": "reyuma", "arthritis": "arthritis", "kidney stones": "bato sa kidney",
    "kidney disorders": "problema sa kidney", "kidney problems": "problema sa kidney",
    "high cholesterol": "taas nga cholesterol", "epilepsy": "epilepsy",
    "scabies": "galiw", "ringworm": "buni", "eczema": "eczema",
    "fungal infections": "buni", "fungal skin infections": "buni sa panit",
    "leprosy": "aguros", "vitamin c deficiency": "kulang sa vitamin C",
    "edema": "hubag tungod sa tubig", "fluid retention": "pagtipon sa tubig sa lawas",
    "heat exhaustion": "kaluya tungod sa init", "dehydration": "kawala og tubig sa lawas",
    "dysentery": "kalibang og dugo", "ulcers": "ulcer", "stomach ulcers": "ulcer sa tiyan",
    "stomach disorders": "problema sa tiyan", "stomach problems": "problema sa tiyan",
    "liver disorders": "sakit sa atay", "respiratory problems": "lisod ginhawa",
    "respiratory congestion": "barado nga ginhawa", "respiratory discomfort": "kaguol sa ginhawa",
    "respiratory infections": "impeksyon sa baga", "respiratory conditions": "problema sa ginhawa",
    "phlegm": "plema", "congestion": "barado nga ilong", "nasal congestion": "barado nga ilong",
    "memory problems": "kalimot dayon", "nerve-related conditions": "problema sa nerbiyos",
    "nervous disorders": "problema sa nerbiyos", "infections": "impeksyon",
    "minor infections": "gamay nga impeksyon", "inflammation": "hubag",
    "minor inflammation": "gamay nga hubag", "loss of appetite": "walay gana mokaon",
    "poor appetite": "kulang og gana mokaon", "poor circulation": "huyang nga sirkulasyon sa dugo",
    "pain": "sakit", "mild pain": "gamay nga sakit", "minor pain": "gamay nga sakit",
    "bad breath": "baho sa baba", "acne": "acne", "anemia": "anemia",
    "parasitic infections": "impeksyon sa parasites", "bone or joint pain": "sakit sa bukog o lutahan",
    "body discomfort": "kaguol sa lawas",
}

# English symptom key -> natural Tagalog phrase.
TAGALOG_TERMS = {
    "fever": "lagnat", "cough": "ubo", "colds": "sipon",
    "sore throat": "masakit ang lalamunan", "headache": "sakit ng ulo",
    "toothache": "sakit ng ngipin", "stomach pain": "sakit ng tiyan",
    "stomachache": "sakit ng tiyan", "stomach cramps": "pulikat sa tiyan",
    "stomach discomfort": "di magandang pakiramdam sa tiyan", "diarrhea": "pagtatae",
    "body pain": "sakit ng katawan", "body aches": "sakit ng katawan",
    "muscle pain": "sakit ng kalamnan", "muscle aches": "sakit ng kalamnan",
    "muscle spasms": "pamimintig ng kalamnan", "joint pain": "sakit ng kasukasuan",
    "joint discomfort": "di magandang pakiramdam sa kasukasuan", "wounds": "sugat",
    "minor wounds": "maliit na sugat", "cuts": "hiwa", "burns": "paso",
    "minor burns": "maliit na paso", "itching": "kati",
    "skin irritation": "pangangati ng balat", "scalp irritation": "pangangati ng ulo",
    "skin conditions": "problema sa balat", "skin disorders": "problema sa balat",
    "skin diseases": "sakit sa balat", "skin infections": "impeksyon sa balat",
    "skin inflammation": "pamamaga ng balat", "skin ulcers": "sugat sa balat",
    "minor skin conditions": "maliit na problema sa balat",
    "minor skin infections": "maliit na impeksyon sa balat",
    "fatigue": "pagod", "weakness": "panghihina", "body weakness": "panghihina ng katawan",
    "nausea": "pagduduwal", "insomnia": "hindi makatulog", "anxiety": "pagkabalisa",
    "nervousness": "kaba", "restlessness": "di mapakali", "stress": "stress",
    "high blood pressure": "mataas na presyon", "hypertension": "mataas na presyon",
    "diabetes": "diabetes", "urinary problems": "problema sa pag-ihi",
    "urinary complaints": "reklamo sa pag-ihi",
    "urinary discomfort": "di magandang pakiramdam sa pag-ihi",
    "urinary disorders": "problema sa pag-ihi", "urinary issues": "problema sa pag-ihi",
    "urinary tract disorders": "problema sa daluyan ng ihi",
    "urinary tract infections": "impeksyon sa daluyan ng ihi",
    "urinary tract problems": "problema sa daluyan ng ihi",
    "painful urination": "masakit mag-ihi", "constipation": "hirap dumumi",
    "bloating": "namamagang tiyan", "gas": "kabag", "flatulence": "kabag",
    "indigestion": "hindi natutunawan", "digestion": "pagtunaw ng pagkain",
    "digestive discomfort": "di magandang pakiramdam sa tiyan",
    "digestive disorders": "problema sa pagtunaw", "digestive issues": "problema sa pagtunaw",
    "digestive problems": "problema sa pagtunaw", "digestive complaints": "reklamo sa pagtunaw",
    "minor digestive discomfort": "maliit na di magandang pakiramdam sa tiyan",
    "minor digestive disorders": "maliit na problema sa pagtunaw",
    "intestinal discomfort": "di magandang pakiramdam sa bituka",
    "intestinal problems": "problema sa bituka", "intestinal parasites": "bulate",
    "intestinal worms": "bulate", "swelling": "pamamaga", "bruises": "pasa",
    "bleeding": "pagdurugo", "minor bleeding": "maliit na pagdurugo",
    "fractures": "baling buto", "sprains": "pilay", "insect bites": "kagat ng insekto",
    "snake bites": "kagat ng ahas", "allergies": "alerhiya", "asthma": "hika",
    "bronchitis": "pamamaga ng daanan ng hangin", "earache": "sakit ng tainga",
    "eye irritation": "makati ang mata", "mouth sores": "singaw", "mouth ulcers": "singaw",
    "dandruff": "balakubak", "lice infestation": "kuto", "warts": "kulugo",
    "boils": "pigsa", "hemorrhoids": "almuranas", "jaundice": "paninilaw",
    "malaria": "malaria", "menstrual discomfort": "sakit sa regla",
    "menstrual disorders": "problema sa regla", "nosebleeds": "pagdurugo ng ilong",
    "gout": "gout", "rheumatic pain": "sakit ng reyuma", "rheumatism": "reyuma",
    "arthritis": "arthritis", "kidney stones": "bato sa bato",
    "kidney disorders": "problema sa bato", "kidney problems": "problema sa bato",
    "high cholesterol": "mataas na cholesterol", "epilepsy": "epilepsy",
    "scabies": "galis", "ringworm": "buni", "eczema": "eczema",
    "fungal infections": "buni", "fungal skin infections": "buni sa balat",
    "leprosy": "ketong", "vitamin c deficiency": "kulang sa vitamin C",
    "edema": "pamamaga dahil sa tubig", "fluid retention": "pag-ipon ng tubig sa katawan",
    "heat exhaustion": "pagkahilo dahil sa init", "dehydration": "nawalan ng tubig sa katawan",
    "dysentery": "pagtatae ng dugo", "ulcers": "ulcer", "stomach ulcers": "ulcer sa tiyan",
    "stomach disorders": "problema sa tiyan", "stomach problems": "problema sa tiyan",
    "liver disorders": "sakit sa atay", "respiratory problems": "hirap huminga",
    "respiratory congestion": "baradong paghinga",
    "respiratory discomfort": "di magandang pakiramdam sa paghinga",
    "respiratory infections": "impeksyon sa baga", "respiratory conditions": "problema sa paghinga",
    "phlegm": "plema", "congestion": "baradong ilong", "nasal congestion": "baradong ilong",
    "memory problems": "mahinang alaala", "nerve-related conditions": "problema sa nerbiyos",
    "nervous disorders": "problema sa nerbiyos", "infections": "impeksyon",
    "minor infections": "maliit na impeksyon", "inflammation": "pamamaga",
    "minor inflammation": "maliit na pamamaga", "loss of appetite": "walang ganang kumain",
    "poor appetite": "kulang sa ganang kumain",
    "poor circulation": "mahinang sirkulasyon ng dugo", "pain": "sakit",
    "mild pain": "bahagyang sakit", "minor pain": "bahagyang sakit",
    "bad breath": "mabahong hininga", "acne": "acne", "anemia": "anemia",
    "parasitic infections": "impeksyon ng parasite", "bone or joint pain": "sakit ng buto o kasukasuan",
    "body discomfort": "di magandang pakiramdam sa katawan",
}

# English symptom key -> natural casual phrasing. Only needed where the raw
# vocabulary word itself isn't how a person would casually say it (e.g.
# "insomnia" -> people say "can't sleep", not "insomnia"), or where TF-IDF's
# lack of stemming means a common morphological variant (e.g. "wound" vs the
# vocabulary's "wounds") would otherwise never appear in training data at
# all. Confirmed empirically: a sentence using none of these synonyms
# ("i can't sleep and i feel anxious") reduced to a single recognized word
# ("and") because "sleep"/"anxious" never appeared anywhere in training text.
ENGLISH_TERMS = {
    "insomnia": "can't sleep", "anxiety": "feeling anxious",
    "nervousness": "feeling nervous", "restlessness": "can't stay still",
    "painful urination": "hurts when i pee", "urinary problems": "trouble peeing",
    "urinary discomfort": "uncomfortable when i pee",
    "urinary complaints": "problems when i pee", "urinary issues": "trouble urinating",
    "nausea": "feel like vomiting", "wounds": "an open wound",
    "minor wounds": "a small wound", "itching": "itchy skin",
    "skin irritation": "irritated itchy skin", "scalp irritation": "itchy scalp",
    "toothache": "my tooth hurts", "earache": "my ear hurts",
    "sore throat": "my throat hurts", "stomach pain": "my stomach hurts",
    "stomachache": "stomach ache", "body pain": "my body hurts",
    "body aches": "body aches all over", "muscle pain": "sore muscles",
    "muscle aches": "aching muscles", "joint pain": "aching joints",
    "headache": "my head hurts", "constipation": "can't poop",
    "bloating": "feeling bloated", "fatigue": "feeling tired and worn out",
    "weakness": "feeling weak", "body weakness": "weak all over",
    "bad breath": "smelly breath", "dandruff": "flaky scalp",
    "warts": "a wart on my skin", "boils": "a boil",
    "hemorrhoids": "piles", "jaundice": "yellowish skin",
    "nosebleeds": "bloody nose", "loss of appetite": "not feeling hungry",
    "poor appetite": "no appetite", "memory problems": "very forgetful",
    "snake bites": "bitten by a snake", "insect bites": "a bug bite",
    "mouth sores": "sores in my mouth", "mouth ulcers": "sores in my mouth",
    "fractures": "a broken bone", "sprains": "a twisted ankle",
    "swelling": "swollen", "bruises": "a bruise", "cuts": "a cut",
    "burns": "a burn on my skin", "diarrhea": "loose stools",
    "indigestion": "upset stomach", "heat exhaustion": "feeling faint from the heat",
    "dehydration": "very thirsty and dried out",
}

ENGLISH_TEMPLATES = [
    "i have {s}", "i've been experiencing {s}", "i'm dealing with {s} lately",
    "i think i have {s}",
]
BISAYA_TEMPLATES = ["naa koy {s}", "gibati nako ang {s}", "aduna koy {s} karon"]
TAGALOG_TEMPLATES = ["may {s} ako", "nararamdaman ko ang {s}", "meron akong {s} ngayon"]


def main():
    df = pd.read_csv(PREPROCESSED_CSV)
    meta_cols = ["ID", "Herbal Name", "Scientific Name", "Genus", "Herbal_Name_encoded"]
    symptom_cols = [c for c in df.columns if c not in meta_cols]

    rows = []
    for s in symptom_cols:
        bisaya_term = BISAYA_TERMS.get(s, s)  # code-switch: fall back to the English term
        tagalog_term = TAGALOG_TERMS.get(s, s)
        casual_term = ENGLISH_TERMS.get(s, s)

        # Half the English templates use the raw vocabulary term (people do
        # sometimes say the clinical word), half use the casual phrasing --
        # both matter as training signal, not just one or the other.
        for tmpl in ENGLISH_TEMPLATES[:2]:
            rows.append((tmpl.format(s=s), s))
        for tmpl in ENGLISH_TEMPLATES[2:]:
            rows.append((tmpl.format(s=casual_term), s))
        for tmpl in BISAYA_TEMPLATES:
            rows.append((tmpl.format(s=bisaya_term), s))
        for tmpl in TAGALOG_TEMPLATES:
            rows.append((tmpl.format(s=tagalog_term), s))

    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["text", "symptom"])
        writer.writerows(rows)

    print(f"{len(symptom_cols)} symptoms, {len(rows)} phrases -> {OUTPUT_CSV}")
    missing_bisaya = [s for s in symptom_cols if s not in BISAYA_TERMS]
    missing_tagalog = [s for s in symptom_cols if s not in TAGALOG_TERMS]
    if missing_bisaya:
        print(f"Code-switched (no curated Bisaya term): {missing_bisaya}")
    if missing_tagalog:
        print(f"Code-switched (no curated Tagalog term): {missing_tagalog}")


if __name__ == "__main__":
    main()
