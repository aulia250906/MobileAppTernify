import cv2
import os
import re
import json
import joblib
import numpy as np
import pandas as pd
import pytesseract
from PIL import Image, ImageEnhance
from rapidfuzz import process, fuzz


# Path Windows dihapus karena Colab menggunakan Linux. Pytesseract akan otomatis menemukannya.

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

# Status kondisi domba (kondisi umum, bukan diagnosa medis spesifik)
KB_STATUS = ["sehat", "lemas", "kritis", "membaik", "stabil",
             "perlu observasi", "mati", "sembuh",
             "susah makan", "nafsu makan turun", "nafsu makan rendah"]

KB_KELAMIN = ["jantan", "betina", "jantan kastrasi"]

KB_KEBUNTINGAN = ["bunting", "tidak bunting", "belum diketahui", "melahirkan",
                  "keguguran", "bunting 1 bulan", "bunting 2 bulan",
                  "bunting 3 bulan", "bunting 4 bulan", "bunting 5 bulan"]

ALL_KB = (KB_RAS + KB_GEJALA + KB_DIAGNOSIS + KB_TINDAKAN + KB_OBAT + KB_STATUS + KB_KELAMIN + KB_KEBUNTINGAN)

# ==================================================================
# MODEL REGISTRY — Penyimpanan Model & Konfigurasi via Joblib
# ==================================================================
class ModelRegistry:
    """Registry untuk menyimpan dan memuat konfigurasi model OCR via Joblib."""
    _instance = None
    _DEFAULT_CONFIG = {
        "tesseract": {
            "oem": 3,
            "psm_primary": 11,
            "psm_fallback": 6,
            "lang": "ind",
            "confidence_threshold": 50,
            "min_words_threshold": 5,
        },
        "preprocessing": {
            "min_width": 1500,
            "blur_kernel_size": 5,
            "adaptive_block_size": 35,
            "adaptive_c": 15,
            "morph_h_len": 40,
            "morph_v_len": 40,
            "morph_iterations": 2,
            "contrast_factor": 1.5,
            "sharpness_factor": 2.0,
        },
        "nlp": {
            "default_threshold": 78,
            "strict_threshold": 70,
        },
        "version": "1.0.0",
    }

    def __init__(self, config_path="models/default_config.joblib"):
        self.config_path = config_path
        self.config = self._load_or_create()

    def _load_or_create(self):
        """Muat konfigurasi dari file joblib, atau gunakan default jika belum ada."""
        if os.path.exists(self.config_path):
            try:
                loaded = joblib.load(self.config_path)
                if isinstance(loaded, dict):
                    return loaded
            except Exception:
                pass
        # Deep copy default via json untuk menghindari mutasi
        return json.loads(json.dumps(self._DEFAULT_CONFIG))

    def get_config(self, section=None):
        """Ambil konfigurasi aktif. Jika section diberikan, kembalikan sub-dict."""
        if section:
            return self.config.get(section, {})
        return self.config

    def save(self):
        """Simpan konfigurasi ke file .joblib dan .json (human-readable)."""
        try:
            config_dir = os.path.dirname(self.config_path)
            if config_dir:
                os.makedirs(config_dir, exist_ok=True)
            joblib.dump(self.config, self.config_path)
            # Simpan juga versi JSON yang bisa dibaca manusia
            json_path = self.config_path.replace(".joblib", ".json")
            with open(json_path, "w", encoding="utf-8") as f:
                json.dump(self.config, f, indent=2, ensure_ascii=False)
        except Exception:
            pass  # Gagal simpan tidak menghentikan proses OCR

    def update_config(self, section, key, value):
        """Update satu nilai konfigurasi dan simpan."""
        if section in self.config:
            self.config[section][key] = value
            self.save()


def get_registry(config_path="models/default_config.joblib"):
    """Singleton loader untuk ModelRegistry."""
    if ModelRegistry._instance is None:
        ModelRegistry._instance = ModelRegistry(config_path)
        ModelRegistry._instance.save()
    return ModelRegistry._instance

# ==================================================================
# DATA LAYER - PREPROCESSING
# ==================================================================
def _deskew_image(cv_image):
    """Deteksi dan koreksi kemiringan gambar menggunakan Pillow + Tesseract OSD.

    Penting untuk foto dari kamera HP yang sering miring. Menggunakan
    pytesseract.image_to_osd untuk mendeteksi sudut rotasi, lalu memutar
    gambar dengan Pillow agar lurus.
    """
    try:
        pil_img = Image.fromarray(cv_image[:, :, ::-1])  # BGR → RGB tanpa cv2
        osd = pytesseract.image_to_osd(cv_image, output_type=pytesseract.Output.DICT)
        angle = int(osd.get("rotate", 0))
        if angle != 0:
            pil_img = pil_img.rotate(-angle, expand=True, fillcolor=(255, 255, 255))
            return np.array(pil_img)[:, :, ::-1]  # RGB → BGR
    except Exception:
        pass  # Jika OSD gagal, lewati deskew
    return cv_image


def _enhance_image(cv_image, contrast_factor=1.5, sharpness_factor=2.0):
    """Tingkatkan kontras dan ketajaman gambar menggunakan Pillow.

    Foto dari HP sering memiliki kontras rendah atau blur ringan.
    Enhancement ini meningkatkan keterbacaan teks sebelum masuk ke
    tahap thresholding OpenCV.
    """
    try:
        pil_img = Image.fromarray(cv_image[:, :, ::-1])  # BGR → RGB
        pil_img = ImageEnhance.Contrast(pil_img).enhance(contrast_factor)
        pil_img = ImageEnhance.Sharpness(pil_img).enhance(sharpness_factor)
        return np.array(pil_img)[:, :, ::-1]  # RGB → BGR
    except Exception:
        return cv_image


def preprocess_image(image_path):
    """Pipeline preprocessing gambar: Pillow enhancement → OpenCV cleanup → confidence."""
    registry = get_registry()
    prep_config = registry.get_config("preprocessing")
    tess_config = registry.get_config("tesseract")

    original = cv2.imread(image_path)
    if original is None:
        raise ValueError(f"Gambar tidak ditemukan: {image_path}")

    # --- Tahap 1: Pillow Enhancement (Deskew & Contrast/Sharpness) ---
    enhanced = _deskew_image(original)
    enhanced = _enhance_image(
        enhanced,
        contrast_factor=prep_config.get("contrast_factor", 1.5),
        sharpness_factor=prep_config.get("sharpness_factor", 2.0),
    )

    # --- Tahap 2: OpenCV Preprocessing (Grayscale, Thresholding, Noise Removal) ---
    gray = cv2.cvtColor(enhanced, cv2.COLOR_BGR2GRAY)
    min_w = prep_config.get("min_width", 1500)
    h, w = gray.shape
    if w < min_w:
        scale = min_w / w
        gray = cv2.resize(gray, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)

    blur_k = prep_config.get("blur_kernel_size", 5)
    blurred = cv2.GaussianBlur(gray, (blur_k, blur_k), 0)
    block_size = prep_config.get("adaptive_block_size", 35)
    c_val = prep_config.get("adaptive_c", 15)
    thresh = cv2.adaptiveThreshold(
        blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, block_size, c_val
    )

    morph_h = prep_config.get("morph_h_len", 40)
    morph_v = prep_config.get("morph_v_len", 40)
    morph_iter = prep_config.get("morph_iterations", 2)
    h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (morph_h, 1))
    v_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, morph_v))
    h_lines  = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, h_kernel, iterations=morph_iter)
    v_lines  = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, v_kernel, iterations=morph_iter)
    table_lines = cv2.add(h_lines, v_lines)

    dilate_k = np.ones((3, 3), np.uint8)
    table_lines = cv2.dilate(table_lines, dilate_k, iterations=1)

    thresh_clean = cv2.subtract(thresh, table_lines)
    final_img = 255 - thresh_clean

    erode_k = np.ones((2, 2), np.uint8)
    final_img = cv2.erode(final_img, erode_k, iterations=1)

    oem = tess_config.get("oem", 3)
    lang = tess_config.get("lang", "ind")
    tess_data = pytesseract.image_to_data(
        final_img, lang=lang, config=f"--oem {oem} --psm 6", output_type=pytesseract.Output.DICT
    )
    confs = [int(c) for c in tess_data["conf"] if str(c).isdigit() and int(c) > 0]
    confidence = round(sum(confs) / len(confs), 1) if confs else 0

    return final_img, confidence

# ==================================================================
# OCR ENGINE & NLP
# ==================================================================
def _extract_lines_from_tess_data(data):
    """Ekstrak baris teks terstruktur dari output pytesseract.image_to_data.

    Mengelompokkan kata-kata berdasarkan koordinat Y (baris visual), lalu
    mengurutkan per baris berdasarkan koordinat X (posisi horizontal).
    Kata dengan confidence ≤ 10 dibuang.
    """
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


def run_ocr_engine(image):
    """OCR Engine dengan smart fallback strategy.

    Menjalankan Tesseract dengan PSM primary (default: 11 — sparse text).
    Jika hasilnya terlalu sedikit kata (< min_words_threshold), mencoba
    PSM fallback (default: 6 — uniform block) dan mengambil hasil terbaik.
    Strategi ini menjaga response time cepat untuk mobile tanpa mengorbankan
    akurasi pada gambar yang sulit.
    """
    registry = get_registry()
    tess_config = registry.get_config("tesseract")
    oem = tess_config.get("oem", 3)
    lang = tess_config.get("lang", "ind")
    psm_primary = tess_config.get("psm_primary", 11)
    psm_fallback = tess_config.get("psm_fallback", 6)
    min_words = tess_config.get("min_words_threshold", 5)

    # Primary pass
    primary_cfg = f"--oem {oem} --psm {psm_primary} -l {lang}"
    data = pytesseract.image_to_data(
        image, config=primary_cfg, output_type=pytesseract.Output.DICT
    )
    best_text = _extract_lines_from_tess_data(data)

    # Smart fallback: hanya jika hasil primary terlalu sedikit
    if len(best_text.split()) < min_words and psm_fallback:
        try:
            fallback_cfg = f"--oem {oem} --psm {psm_fallback} -l {lang}"
            fb_data = pytesseract.image_to_data(
                image, config=fallback_cfg, output_type=pytesseract.Output.DICT
            )
            fb_text = _extract_lines_from_tess_data(fb_data)
            if len(fb_text.split()) > len(best_text.split()):
                best_text = fb_text
        except Exception:
            pass

    return best_text


def nlp_text_correction(word, kb_list, threshold=78):
    """Koreksi teks OCR via fuzzy matching terhadap Knowledge Base.

    Menggunakan dua strategi pencocokan:
    1. fuzz.ratio (primary) — pencocokan karakter langsung, baik untuk typo
    2. fuzz.token_sort_ratio (fallback) — menangani urutan kata terbalik,
       mis. OCR membaca "makan nafsu" padahal seharusnya "nafsu makan"
    """
    if not word or len(word) <= 2 or word in ["-", "--", "~"]: return word
    kb_lower = [k.lower() for k in kb_list]

    # Primary: fuzz.ratio (pencocokan karakter langsung)
    match = process.extractOne(word.lower(), kb_lower, scorer=fuzz.ratio)
    if match and threshold <= match[1] < 100:
        idx = kb_lower.index(match[0])
        return kb_list[idx]

    # Fallback: token_sort_ratio (menangani kata yang urutannya terbalik)
    match_tsr = process.extractOne(word.lower(), kb_lower, scorer=fuzz.token_sort_ratio)
    if match_tsr and match_tsr[1] >= threshold:
        idx = kb_lower.index(match_tsr[0])
        # Hanya koreksi jika hasilnya berbeda dari input
        if kb_list[idx].lower() != word.lower():
            return kb_list[idx]

    return word

# ==================================================================
# PARSERS
# ==================================================================
def _strip_bullet(line):
    """Hilangkan penanda bullet (*, -, •, dll) di awal baris sebelum parsing label:value."""
    return re.sub(r"^[\*\-\u2022\u25CF\u25AA\u25E6•·▪●]+\s*", "", line).strip()

def _split_glued_lines(raw_text):
    """
    Pisahkan baris yang nempel akibat OCR gagal mendeteksi newline,
    contoh: '...Jantan (Ear Tag): 031Ear Tag: 001...' (dua field/record
    tergabung dalam satu baris tanpa pemisah). Disisipkan newline sebelum
    label field baru yang dikenali (Ear Tag, Jenis Kelamin, dst) jika ia
    muncul tepat menempel setelah suatu nilai (huruf/angka langsung diikuti
    huruf kapital label, tanpa spasi).
    """
    known_labels = (
        r"Ear\s*Tag|Jenis\s*Kelamin|Tanggal\s*Lahir|Jenis\s*Domba|"
        r"Induk|Jantan|Pejantan|Tanggal\s*perkawinan|Status\s*Kebuntingan|"
        r"Berat\s*badan|Status\s*Kondisi|Tindakan|Dosis|Gejala|Diagnosa|Catatan"
    )
    pattern = re.compile(r"(?<=[a-zA-Z0-9])(" + known_labels + r")\s*:", flags=re.IGNORECASE)
    return pattern.sub(r"\n\1:", raw_text)

# Kata-kata yang HANYA muncul sebagai bagian dari nama label field (bukan isi value).
# Dipakai untuk mendeteksi baris "label murni" — baris yang cuma berisi nama field
# tanpa value (kasus OCR yang membaca value di baris sebelumnya, label di baris
# berikutnya, mis. layout kolom yang urutan bacanya terbalik/acak).
_LABEL_ONLY_WORDS = {
    "ear", "tag", "jenis", "kelamin", "tanggal", "lahir", "domba", "induk",
    "jantan", "pejantan", "perkawinan", "status", "kebuntingan", "berat",
    "badan", "kondisi", "tindakan", "dosis", "obat", "gejala", "diagnosa",
    "diagnosis", "catatan", "no", "id", "bobot", "ras", "breed", "tgl",
    "keterangan", "note", "treatment", "penanganan",
}

def _is_label_only_line(line):
    """
    True jika sebuah baris kemungkinan besar HANYA berisi nama label field
    (tanpa value asli), misalnya 'Status Kondisi' atau 'Tindakan'. Dideteksi
    dengan mengecek apakah SEMUA kata di baris itu adalah kata label yang
    dikenal (lihat _LABEL_ONLY_WORDS), dan tidak ada angka di baris tsb.
    """
    words = [w.lower().strip(".,:;()[]{}") for w in line.split()]
    words = [w for w in words if w]
    if not words: return False
    if any(re.search(r"\d", w) for w in words): return False
    return all(w in _LABEL_ONLY_WORDS for w in words)

_LOOKBACK_MARKER = "\u0000LB\u0000"  # penanda internal: baris ini hasil gabungan _merge_lookback_lines

def _merge_lookback_lines(lines, field_map):
    """
    Menangani layout OCR di mana VALUE muncul di satu baris dan LABEL field-nya
    baru muncul di baris BERIKUTNYA (urutan baca terbalik), contoh nyata:
        'Susah makan'        <- value, tanpa label apapun
        'Status Kondisi'     <- label murni, tanpa value
        'pemberi obat'       <- value (terpotong OCR dari 'pemberian obat')
        'Tindakan an'        <- label field + sisa potongan kata yang nyasar

    Aturan: jika sebuah baris TIDAK cocok dengan field manapun ("yatim"), dan
    baris BERIKUTNYA cocok dengan suatu field, gabungkan baris yatim itu sebagai
    bagian depan dari value field berikutnya:
        'Tindakan an'  +  prev 'pemberi obat'  ->  'Tindakan: pemberi obat an'
    Baris yang sudah punya pemisah ':' / '=' (format label:value normal) TIDAK
    pernah dianggap yatim, supaya format dokumen standar tidak terganggu.
    Baris hasil gabungan diberi penanda _LOOKBACK_MARKER supaya tahap berikutnya
    tahu baris ini perlu dibersihkan dari sisa kata label yang menempel.
    """
    field_keys_only = {k: v for k, v in field_map.items()}
    merged = []
    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]

        if ":" in line or "=" in line:
            merged.append(line)
            i += 1
            continue

        current_field_key, _ = _parse_line_with_map(line, field_keys_only)

        if current_field_key is None and i + 1 < n:
            next_line = lines[i + 1]
            if ":" not in next_line and "=" not in next_line:
                next_field_key, _ = _parse_line_with_map(next_line, field_keys_only)
                if next_field_key is not None:
                    # baris ini "yatim" (tak match field apapun) dan baris berikutnya
                    # punya field -> gabungkan jadi satu baris: [baris_field_berikutnya] [baris_yatim]
                    merged.append(f"{next_line} {line}{_LOOKBACK_MARKER}")
                    i += 2
                    continue

        merged.append(line)
        i += 1

    return merged

def _strip_leading_label_words(value, is_lookback_merged):
    """
    Buang kata-kata label generik (lihat _LABEL_ONLY_WORDS) yang nyangkut di
    AWAL value, misalnya 'Kondisi Susah makan' -> 'Susah makan' (kata 'Kondisi'
    adalah sisa label). Juga membuang token tunggal pendek (<=2 huruf) yang
    tidak bermakna sebagai kata utuh, misalnya potongan OCR 'an' dari 'pemberian'.

    HANYA dijalankan jika is_lookback_merged True (baris ini hasil gabungan
    _merge_lookback_lines) — supaya value field NORMAL yang kebetulan diawali
    kata generik (mis. jenis_domba = "Domba Garut") tidak ikut terpotong.
    """
    if not is_lookback_merged:
        return value
    words = value.split()
    while words and (words[0].lower().strip(".,:;()[]{}") in _LABEL_ONLY_WORDS):
        words.pop(0)
    while words and len(words[0]) <= 2 and words[0].isalpha():
        words.pop(0)
    cleaned = " ".join(words).strip()
    return cleaned if cleaned else value

def _parse_line_with_map(line, field_map):
    # Pola dicek sesuai URUTAN field_map (insertion order). Field yang lebih spesifik
    # (mis. "induk", "jantan") harus didefinisikan SEBELUM pola umum (mis. "ear.?tag")
    # di dalam FIELD_MAP masing-masing parser, supaya label gabungan seperti
    # "Induk (Ear Tag)" tidak salah tertangkap oleh pola umum "ear_tag".
    sep = re.split(r"\s*[:=]\s*", line, maxsplit=1)
    if len(sep) == 2 and sep[0].strip() and sep[1].strip():
        raw_label, value = sep[0].strip(), sep[1].strip()
        for pattern, key in field_map.items():
            if re.search(pattern, raw_label, re.IGNORECASE): return key, value

    words = line.split()
    for length in (1, 2, 3, 4):
        if len(words) <= length: continue
        candidate_label = " ".join(words[:length])
        candidate_value = " ".join(words[length:])
        for pattern, key in field_map.items():
            if re.search(pattern, candidate_label, re.IGNORECASE): return key, candidate_value
    return None, None

# Parser Rekam Medis
def parse_rekam_medis_card(raw_text):
    FIELD_MAP = {
        r"ear|tag|e[a-z]r|t[a-z]g|domba|id": "ear_tag",
        r"berat|bobot|b[a-z]rat|b[a-z]bot": "berat_badan",
        r"gejala|symptom|keluhan|g[a-z]jala": "gejala",
        r"diagnosa|diagnosis|diagnos|d[a-z]agnos": "diagnosa",
        r"tindakan|treatment|penanganan|t[a-z]ndak": "tindakan",
        r"dosis|obat|d[a-z]sis": "dosis_obat",
        r"status|kondisi|st[a-z]tus|k[a-z]ndisi": "status_kondisi",
        r"catatan|note|keterangan": "catatan",
    }
    KB_MAP = {"gejala": KB_GEJALA, "diagnosa": KB_DIAGNOSIS, "tindakan": KB_TINDAKAN,
              "dosis_obat": KB_OBAT, "status_kondisi": KB_STATUS}
    record = {k: None for k in FIELD_MAP.values()}
    raw_text = _split_glued_lines(raw_text)
    raw_lines = [_strip_bullet(l.strip()) for l in raw_text.split("\n") if l.strip()]
    raw_lines = _merge_lookback_lines(raw_lines, FIELD_MAP)

    for raw_line in raw_lines:
        is_lookback = _LOOKBACK_MARKER in raw_line
        raw_line = raw_line.replace(_LOOKBACK_MARKER, "")
        line = re.sub(r"[|\[\]\(\){]{2,}", " ", raw_line).strip()
        field_key, value = _parse_line_with_map(line, FIELD_MAP)
        if not field_key or not value: continue

        # Buang sisa kolom tabel OCR yang nyangkut di depan value (mis. "77   susah makan"),
        # tapi HANYA jika token awal itu kode/angka, bukan kata biasa (mis. "susah makan").
        value = re.sub(r"^[\d\W]{1,6}\s{2,}", "", value).strip()
        # Buang sisa kata label / token nyasar yang nempel di depan value akibat
        # penggabungan baris lookback (mis. layout OCR value-mendahului-label).
        value = _strip_leading_label_words(value, is_lookback)
        if field_key in KB_MAP:
            value = nlp_text_correction(value, KB_MAP[field_key], threshold=70)

        if field_key == "ear_tag":
            id_match = re.search(r"\b(\d{2,4})\b", value)
            value = id_match.group(1) if id_match else value
        if field_key == "berat_badan":
            berat_match = re.search(r"(\d{1,3}(?:[.,]\d+)?)\s*(kg|gram|gr|g)\b", value.lower())
            if berat_match:
                value = f"{berat_match.group(1)} {berat_match.group(2)}"
        if field_key == "dosis_obat":
            dosis_match = re.search(r"(\d{1,3}(?:[.,]\d)?\s*(?:ml|mg|cc|tablet|kapsul))", value.lower())
            if dosis_match:
                value = dosis_match.group(1)
            else:
                # Fallback: OCR kadang salah baca satuan singkat (mis. "ml" -> "w" / "nl" / "ni").
                # Jika ada angka dengan token satuan pendek (1-3 huruf) yang TIDAK dikenali,
                # anggap itu varian rusak dari "ml" (satuan dosis cair paling umum pada form ini).
                fallback_match = re.search(r"(\d{1,3}(?:[.,]\d)?)\s*([a-zA-Z]{1,3})\b", value)
                if fallback_match and fallback_match.group(2).lower() not in ("kg", "gr"):
                    value = f"{fallback_match.group(1)} ml"

        record[field_key] = value
    return record

# Parser Perkawinan
def parse_perkawinan_card(raw_text):
    FIELD_MAP = {
        r"tanggal|kawin|perkawinan|t[a-z]nggal|tgl|k[a-z]win": "tanggal_perkawinan",
        r"induk|i[a-z]duk|1nduk|lnduk": "ear_tag_induk",
        r"pejantan|jantan|j[a-z]ntan|p[a-z]jantan": "ear_tag_pejantan",
        r"bunting|kebuntingan|status|b[a-z]nting|st[a-z]tus": "status_kebuntingan",
        r"catatan|note|keterangan": "catatan"
    }
    KB_MAP = {"status_kebuntingan": KB_KEBUNTINGAN}
    record = {k: None for k in FIELD_MAP.values()}
    raw_text = _split_glued_lines(raw_text)
    raw_lines = [_strip_bullet(l.strip()) for l in raw_text.split("\n") if l.strip()]
    raw_lines = _merge_lookback_lines(raw_lines, FIELD_MAP)

    for raw_line in raw_lines:
        is_lookback = _LOOKBACK_MARKER in raw_line
        raw_line = raw_line.replace(_LOOKBACK_MARKER, "")
        line = re.sub(r"[|\[\]\(\)]{2,}", " ", raw_line).strip()
        field_key, value = _parse_line_with_map(line, FIELD_MAP)
        if not field_key or not value: continue

        value = _strip_leading_label_words(value, is_lookback)
        if field_key in KB_MAP: value = nlp_text_correction(value, KB_MAP[field_key], threshold=70)
        if field_key in ("ear_tag_induk", "ear_tag_pejantan"):
            id_match = re.search(r"\b(\d{2,4})\b", value)
            value = id_match.group(1) if id_match else value
        if field_key == "tanggal_perkawinan":
            tgl = re.search(r"(\d{1,2}\s*[-/.]\s*\d{1,2}\s*[-/.]\s*\d{2,4})", value)
            if tgl: value = re.sub(r"\s+", "", tgl.group(1))
        record[field_key] = value
    return record

# Parser Data Domba
def parse_data_domba_card(raw_text):
    FIELD_MAP = {
        r"induk|i[a-z]duk|1nduk|lnduk": "ear_tag_induk",
        r"pejantan|jantan|j[a-z]ntan|p[a-z]jantan": "ear_tag_jantan",
        r"ear|tag|e[a-z]r|t[a-z]g|id": "ear_tag",
        r"kelamin|jenis[a-z]?k|k[a-z]lamin": "jenis_kelamin",
        r"lahir|l[a-z]hir|tanggal|t[a-z]nggal|tgl": "tanggal_lahir",
        r"domba|ras|breed|d[a-z]mba": "jenis_domba",
        r"catatan|note|keterangan": "catatan"
    }
    KB_MAP = {"jenis_kelamin": KB_KELAMIN, "jenis_domba": KB_RAS}
    record = {k: None for k in FIELD_MAP.values()}
    raw_text = _split_glued_lines(raw_text)
    raw_lines = [_strip_bullet(l.strip()) for l in raw_text.split("\n") if l.strip()]
    raw_lines = _merge_lookback_lines(raw_lines, FIELD_MAP)

    for raw_line in raw_lines:
        is_lookback = _LOOKBACK_MARKER in raw_line
        raw_line = raw_line.replace(_LOOKBACK_MARKER, "")
        line = re.sub(r"[|\[\]\(\)]{2,}", " ", raw_line).strip()
        field_key, value = _parse_line_with_map(line, FIELD_MAP)
        if not field_key or not value: continue

        value = _strip_leading_label_words(value, is_lookback)
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
# DATA VALIDATION — Cleaning Teks Mentah via Pandas
# ==================================================================
def _normalize_unicode_chars(value):
    """Normalisasi karakter unicode yang sering muncul dari hasil OCR."""
    if not isinstance(value, str):
        return value
    replacements = {
        '\u2013': '-', '\u2014': '-',   # en-dash, em-dash → hyphen
        '\u2018': "'", '\u2019': "'",   # smart single quotes
        '\u201c': '"', '\u201d': '"',   # smart double quotes
        '\u2026': '...',                # ellipsis
        '\u00a0': ' ',                  # non-breaking space
    }
    for old, new in replacements.items():
        value = value.replace(old, new)
    return value


def validate_ocr_dataframe(record, form_type):
    """Cleaning dan validasi data hasil OCR menggunakan Pandas DataFrame.

    Sesuai alur sistem: 'Data Validation (Cleaning Teks Mentah via Pandas)'

    Tahapan:
    1. Konversi record dict → Pandas DataFrame
    2. Strip whitespace & normalisasi karakter unicode
    3. Hapus nilai noise-only (hanya simbol/spasi)
    4. Validasi format spesifik per field (ear_tag, tanggal, berat)
    5. Konversi kembali ke dict yang bersih
    """
    if not record:
        return record

    df = pd.DataFrame([record])

    # --- Tahap 1: Cleaning umum semua kolom ---
    for col in df.columns:
        # Strip whitespace
        df[col] = df[col].apply(lambda x: x.strip() if isinstance(x, str) else x)
        # Normalisasi karakter unicode
        df[col] = df[col].apply(_normalize_unicode_chars)
        # Hapus nilai noise-only (hanya simbol/dash/spasi)
        df[col] = df[col].apply(
            lambda x: None if isinstance(x, str) and re.match(r'^[\s\-~_.,:;|/\\*]+$', x) else x
        )
        # Kosongkan string empty
        df[col] = df[col].apply(lambda x: None if isinstance(x, str) and not x.strip() else x)

    # --- Tahap 2: Validasi format spesifik ---
    # Ear tag: harus berisi digit
    ear_tag_cols = [c for c in df.columns if 'ear_tag' in c]
    for col in ear_tag_cols:
        val = df.at[0, col]
        if isinstance(val, str):
            digits = re.sub(r'[^\d]', '', val)
            df.at[0, col] = digits if digits else None

    # Tanggal: normalisasi separator, hapus spasi berlebih
    date_cols = [c for c in df.columns if 'tanggal' in c]
    for col in date_cols:
        val = df.at[0, col]
        if isinstance(val, str):
            normalized = re.sub(r'\s+', '', val)
            df.at[0, col] = normalized if re.search(r'\d', normalized) else None

    # Berat badan: harus ada angka
    if 'berat_badan' in df.columns:
        val = df.at[0, 'berat_badan']
        if isinstance(val, str) and not re.search(r'\d', val):
            df.at[0, 'berat_badan'] = None

    # --- Tahap 3: Konversi kembali ke dict ---
    cleaned = {}
    for col in df.columns:
        val = df.at[0, col]
        if isinstance(val, str) and val:
            cleaned[col] = val
        else:
            cleaned[col] = None
    return cleaned

# ==================================================================
# ROUTER & PIPELINE
# ==================================================================
def detect_form_type(text):
    t = re.sub(r"\s+", " ", text.upper())

    if "DOKUMEN PERKAWINAN" in t or "PERKAWINAN" in t:
        return "PERKAWINAN"
    if "DOKUMEN DOMBA" in t or ("JENIS KELAMIN" in t and "TANGGAL LAHIR" in t):
        return "DATA_DOMBA"
    if "DOKUMEN REKAM MEDIS" in t or "REKAM MEDIS" in t:
        return "REKAM_MEDIS"

    # Sinyal tambahan tanpa judul dokumen eksplisit
    if "INDUK" in t and "PEJANTAN" in t and ("KEBUNTINGAN" in t or "BUNTING" in t):
        return "PERKAWINAN"
    if "GEJALA" in t or "DIAGNOSA" in t or "DIAGNOSIS" in t:
        return "REKAM_MEDIS"
    if ("BERAT BADAN" in t or "BOBOT" in t) and ("STATUS KONDISI" in t or "TINDAKAN" in t or "DOSIS" in t):
        return "REKAM_MEDIS"
    if "JENIS DOMBA" in t and "TANGGAL LAHIR" in t:
        return "DATA_DOMBA"

    return "UNKNOWN"

def process_form_image(image_path):
    """Pipeline utama OCR: preprocessing → engine → parsing → validasi.

    Mengintegrasikan semua layer:
    - Model Registry: konfigurasi dari Joblib
    - Image Pre-processing: Pillow + OpenCV
    - OCR Engine: Tesseract dengan smart fallback
    - NLP Text Correction: fuzzy matching
    - Data Validation: cleaning via Pandas
    - JSON serialization: validasi output
    """
    registry = get_registry()
    tess_config = registry.get_config("tesseract")
    min_confidence = tess_config.get("confidence_threshold", 50)

    img, confidence = preprocess_image(image_path)

    if confidence < min_confidence:
        return {"success": False, "message": f"Confidence terlalu rendah ({confidence}%)", "data": None}

    raw_text = run_ocr_engine(img)
    form_type = detect_form_type(raw_text)

    if form_type == "UNKNOWN":
        return {"success": False, "message": "Jenis form tidak dikenali", "data": None}

    if form_type == "REKAM_MEDIS": record = parse_rekam_medis_card(raw_text)
    elif form_type == "PERKAWINAN": record = parse_perkawinan_card(raw_text)
    elif form_type == "DATA_DOMBA": record = parse_data_domba_card(raw_text)

    # Data Validation: Cleaning teks mentah via Pandas
    record = validate_ocr_dataframe(record, form_type)

    result = {
        "success": True,
        "message": "OCR Berhasil",
        "form_type": form_type,
        "confidence": confidence,
        "extracted_text": raw_text,
        "details": record,
        "data": record
    }

    # Pastikan output JSON-serializable (menggunakan json module)
    try:
        json.dumps(result, ensure_ascii=False)
    except (TypeError, ValueError):
        for key in ("details", "data"):
            if key in result and result[key]:
                result[key] = {k: str(v) if v is not None else None
                               for k, v in result[key].items()}

    return result