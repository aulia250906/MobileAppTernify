import cv2
import re
import json
import joblib
import numpy as np
import pytesseract
from rapidfuzz import process, fuzz

pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"


# ==================================================================
# KNOWLEDGE BASE — Kamus istilah untuk koreksi teks OCR
# ==================================================================
KB_RAS = ["Merino", "Suffolk", "Dorper", "Garut", "Texel", "Corriedale",
          "Awassi", "Barbados", "Ekor Gemuk", "Priangan", "Batur", "Sapudi",
          "Jonggol", "Lokal", "Domba Garut", "Domba Merino", "Domba Etawa", "Etawa"]

KB_GEJALA = ["nafsu makan rendah", "nafsu makan turun", "lemas", "diare",
             "demam", "batuk", "sesak napas", "gatal", "pincang", "kembung"]

KB_DIAGNOSIS = ["sehat", "orf", "scabies", "kudis", "cacingan", "pneumonia",
                "bloat", "kembung", "mastitis", "tetanus", "diare", "pink eye",
                "anemia", "malnutrisi", "PMK", "luka", "demam", "sakit perut"]

KB_TINDAKAN = ["pemberian obat", "suntik", "operasi", "isolasi", "vaksinasi",
               "perawatan luka", "pemberian vitamin", "drench"]

KB_OBAT = ["ivermectin", "albendazole", "oxytetracycline", "penicillin",
           "amoxicillin", "vitamin B", "kalsium", "probiotik", "betadine",
           "antibiotik", "antiparasit", "vaksin", "akarisida"]

KB_STATUS = ["sehat", "lemas", "kritis", "membaik", "stabil",
             "perlu observasi", "mati", "sembuh"]

KB_KELAMIN = ["jantan", "betina", "jantan kastrasi"]

KB_KEBUNTINGAN = ["bunting", "tidak bunting", "belum diketahui", "melahirkan",
                  "keguguran", "bunting 1 bulan", "bunting 2 bulan",
                  "bunting 3 bulan", "bunting 4 bulan", "bunting 5 bulan"]

ALL_KB = (KB_RAS + KB_GEJALA + KB_DIAGNOSIS + KB_TINDAKAN + KB_OBAT + KB_STATUS + KB_KELAMIN + KB_KEBUNTINGAN)

# ==================================================================
# DATA LAYER - PREPROCESSING
# ==================================================================
def preprocess_image(image_path):
    original = cv2.imread(image_path)
    if original is None:
        raise ValueError(f"Gambar tidak ditemukan: {image_path}")

    gray = cv2.cvtColor(original, cv2.COLOR_BGR2GRAY)
    h, w = gray.shape
    if w < 1500:
        scale = 1500 / w
        gray = cv2.resize(gray, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)

    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    thresh = cv2.adaptiveThreshold(
        blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 35, 15
    )

    h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (40, 1))
    v_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, 40))
    h_lines  = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, h_kernel, iterations=2)
    v_lines  = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, v_kernel, iterations=2)
    table_lines = cv2.add(h_lines, v_lines)

    dilate_k = np.ones((3, 3), np.uint8)
    table_lines = cv2.dilate(table_lines, dilate_k, iterations=1)

    thresh_clean = cv2.subtract(thresh, table_lines)
    final_img = 255 - thresh_clean

    erode_k = np.ones((2, 2), np.uint8)
    final_img = cv2.erode(final_img, erode_k, iterations=1)

    tess_data = pytesseract.image_to_data(
        final_img, lang="ind", config="--oem 3 --psm 6", output_type=pytesseract.Output.DICT
    )
    confs = [int(c) for c in tess_data["conf"] if str(c).isdigit() and int(c) > 0]
    confidence = round(sum(confs) / len(confs), 1) if confs else 0

    return final_img, confidence

# ==================================================================
# OCR ENGINE & NLP
# ==================================================================
def run_ocr_engine(image):
    data = pytesseract.image_to_data(
        image, config="--oem 3 --psm 11 -l ind", output_type=pytesseract.Output.DICT
    )
    lines_dict = {}
    for i in range(len(data["text"])):
        text = data["text"][i].strip()
        conf = int(data["conf"][i])
        if not text or conf <= 10: continue

        y, x = data["top"][i], data["left"][i]
        matched_y = next((ey for ey in lines_dict if abs(y - ey) < 20), None)
        if matched_y is None:
            lines_dict[y] = []
            matched_y = y
        lines_dict[matched_y].append((x, text))

    result_lines = []
    for y in sorted(lines_dict):
        words = sorted(lines_dict[y], key=lambda w: w[0])
        result_lines.append(" ".join(w[1] for w in words))

    return "\n".join(result_lines)

def nlp_text_correction(word, kb_list, threshold=78):
    if not word or len(word) <= 2 or word in ["-", "--", "~"]: return word
    match = process.extractOne(word.lower(), [k.lower() for k in kb_list], scorer=fuzz.ratio)
    if match and threshold <= match[1] < 100:
        idx = [k.lower() for k in kb_list].index(match[0])
        return kb_list[idx]
    return word

# ==================================================================
# PARSERS
# ==================================================================
def _parse_line_with_map(line, field_map):
    sep = re.split(r"\s*[:=]\s*", line, maxsplit=1)
    if len(sep) == 2 and sep[0].strip() and sep[1].strip():
        raw_label, value = sep[0].strip(), sep[1].strip()
        for pattern, key in field_map.items():
            if re.search(pattern, raw_label, re.IGNORECASE): return key, value
            
    words = line.split()
    for length in (1, 2, 3):
        if len(words) <= length: continue
        candidate_label = " ".join(words[:length])
        candidate_value = " ".join(words[length:])
        for pattern, key in field_map.items():
            if re.search(pattern, candidate_label, re.IGNORECASE): return key, candidate_value
    return None, None

# Parser Rekam Medis
def parse_rekam_medis_card(raw_text):
    FIELD_MAP = {
        r"domba|ear.?tag|no.?domba|id.?domba": "ear_tag",
        r"gejala|symptom|keluhan": "gejala",
        r"diagnosa|diagnosis|diagnos": "diagnosa",
        r"tindakan|treatment|penanganan": "tindakan",
        r"dosis.?obat|dosis|^obat$": "dosis_obat",
        r"status.?kondisi|status|kondisi": "status_kondisi",
        r"catatan|note|keterangan": "catatan",
    }
    KB_MAP = {"gejala": KB_GEJALA, "diagnosa": KB_DIAGNOSIS, "tindakan": KB_TINDAKAN, "dosis_obat": KB_OBAT, "status_kondisi": KB_STATUS}
    record = {k: None for k in FIELD_MAP.values()}
    
    for line in [l.strip() for l in raw_text.split("\n") if l.strip()]:
        line = re.sub(r"[|\[\]\(\){]{2,}", " ", line).strip()
        field_key, value = _parse_line_with_map(line, FIELD_MAP)
        if not field_key or not value: continue
        
        value = re.sub(r"^\S{1,6}\s{2,}", "", value).strip()
        if field_key in KB_MAP:
            value = nlp_text_correction(value, KB_MAP[field_key], threshold=70)
            
        if field_key == "ear_tag":
            id_match = re.search(r"\b(\d{2,4})\b", value)
            value = id_match.group(1) if id_match else value
        if field_key == "dosis_obat":
            dosis_match = re.search(r"(\d{1,3}(?:[.,]\d)?\s*(?:ml|mg|cc|tablet|kapsul))", value.lower())
            if dosis_match: value = dosis_match.group(1)
            
        record[field_key] = value
    return record

# Parser Perkawinan
def parse_perkawinan_card(raw_text):
    FIELD_MAP = {
        r"induk": "ear_tag_induk", r"pejantan|jantan.*ear|ear.*jantan": "ear_tag_pejantan",
        r"kebuntingan|bunting|status": "status_kebuntingan", r"catatan|note|keterangan": "catatan"
    }
    KB_MAP = {"status_kebuntingan": KB_KEBUNTINGAN}
    record = {k: None for k in FIELD_MAP.values()}

    for line in [l.strip() for l in raw_text.split("\n") if l.strip()]:
        line = re.sub(r"[|\[\]\(\)]{2,}", " ", line).strip()
        field_key, value = _parse_line_with_map(line, FIELD_MAP)
        if not field_key or not value: continue

        if field_key in KB_MAP: value = nlp_text_correction(value, KB_MAP[field_key], threshold=70)
        if field_key in ("ear_tag_induk", "ear_tag_pejantan"):
            id_match = re.search(r"\b(\d{2,4})\b", value)
            value = id_match.group(1) if id_match else value
        record[field_key] = value
    return record

# Parser Data Domba
def parse_data_domba_card(raw_text):
    FIELD_MAP = {
        r"ear.?tag(?!.*induk)(?!.*jantan)": "ear_tag", r"jenis.?kelamin|kelamin": "jenis_kelamin",
        r"tanggal.?lahir|lahir|tgl": "tanggal_lahir", r"jenis.?domba|ras|breed": "jenis_domba",
        r"induk": "ear_tag_induk", r"jantan.*ear|ear.*jantan|pejantan": "ear_tag_jantan", r"catatan|note|keterangan": "catatan"
    }
    KB_MAP = {"jenis_kelamin": KB_KELAMIN, "jenis_domba": KB_RAS}
    record = {k: None for k in FIELD_MAP.values()}

    for line in [l.strip() for l in raw_text.split("\n") if l.strip()]:
        line = re.sub(r"[|\[\]\(\)]{2,}", " ", line).strip()
        field_key, value = _parse_line_with_map(line, FIELD_MAP)
        if not field_key or not value: continue

        if field_key in KB_MAP: value = nlp_text_correction(value, KB_MAP[field_key], threshold=70)
        if field_key in ("ear_tag", "ear_tag_induk", "ear_tag_jantan"):
            id_match = re.search(r"\b(\d{2,4})\b", value)
            value = id_match.group(1) if id_match else value
        if field_key == "tanggal_lahir":
            tgl = re.search(r"(\d{1,2}\s*[-/.]\s*\d{1,2}\s*[-/.]\s*\d{2,4})", value)
            if tgl: value = re.sub(r"\s+", "", tgl.group(1))
        record[field_key] = value
    return record

# ==================================================================
# ROUTER & PIPELINE
# ==================================================================
def detect_form_type(text):
    t = text.upper()
    if "REKAM MEDIS" in t or "GEJALA" in t or "DIAGNOSA" in t: return "REKAM_MEDIS"
    if "PERKAWINAN" in t or ("INDUK" in t and "PEJANTAN" in t and "KEBUNTINGAN" in t): return "PERKAWINAN"
    if "DATA DOMBA" in t or ("JENIS KELAMIN" in t and "TANGGAL LAHIR" in t): return "DATA_DOMBA"
    return "UNKNOWN"

def process_form_image(image_path):
    img, confidence = preprocess_image(image_path)
    
    if confidence < 50:
        return {"success": False, "message": f"Confidence terlalu rendah ({confidence}%)", "data": None}

    raw_text = run_ocr_engine(img)
    form_type = detect_form_type(raw_text)

    if form_type == "UNKNOWN":
        return {"success": False, "message": "Jenis form tidak dikenali", "data": None}

    if form_type == "REKAM_MEDIS": record = parse_rekam_medis_card(raw_text)
    elif form_type == "PERKAWINAN": record = parse_perkawinan_card(raw_text)
    elif form_type == "DATA_DOMBA": record = parse_data_domba_card(raw_text)

    return {
        "success": True, 
        "message": "OCR Berhasil", 
        "form_type": form_type, 
        "confidence": confidence,
        "extracted_text": raw_text,
        "details": record,
        "data": record
    }