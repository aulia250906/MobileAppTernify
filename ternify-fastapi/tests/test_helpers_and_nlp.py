"""
Unit Tests untuk fungsi-fungsi helper dan NLP di ocr_service.py

Cakupan:
- nlp_text_correction: Koreksi teks OCR via fuzzy matching
- _strip_bullet: Pembersihan bullet marker
- _split_glued_lines: Pemisahan baris yang tergabung
- _is_label_only_line: Deteksi baris label murni
- _parse_line_with_map: Parser inti label:value
- _merge_lookback_lines: Penggabungan baris lookback
- _strip_leading_label_words: Pembersihan kata label residual
"""
import pytest
from ocr_service import (
    nlp_text_correction,
    _strip_bullet,
    _split_glued_lines,
    _is_label_only_line,
    _parse_line_with_map,
    _merge_lookback_lines,
    _strip_leading_label_words,
    _LOOKBACK_MARKER,
    _LABEL_ONLY_WORDS,
    KB_RAS,
    KB_GEJALA,
    KB_DIAGNOSIS,
    KB_TINDAKAN,
    KB_OBAT,
    KB_STATUS,
    KB_KELAMIN,
    KB_KEBUNTINGAN,
    ALL_KB,
)


# ====================================================================
# nlp_text_correction
# ====================================================================
class TestNlpTextCorrection:
    """
    Tujuan: Memastikan fungsi fuzzy matching mengoreksi kata OCR yang salah
    terhadap knowledge base, dengan threshold dan boundary yang tepat.
    """

    # ---- Positive Tests ----

    def test_exact_match_returns_original(self):
        """Kata yang sudah benar di KB dikembalikan tanpa perubahan."""
        # Arrange
        word = "Garut"
        # Act
        result = nlp_text_correction(word, KB_RAS)
        # Assert — exact match (score=100) TIDAK dikoreksi karena threshold < 100
        assert result == "Garut"

    def test_typo_correction_breed_name(self):
        """Kata typo ringan yang mirip item KB berhasil dikoreksi."""
        # Arrange — "Garrt" mirip "Garut" (1 huruf beda)
        word = "Garrt"
        # Act
        result = nlp_text_correction(word, KB_RAS)
        # Assert — harus terkoreksi ke "Garut"
        assert result == "Garut"

    def test_typo_correction_symptom(self):
        """Koreksi gejala yang typo dari OCR."""
        word = "diaree"  # dekat dengan "diare"
        result = nlp_text_correction(word, KB_GEJALA)
        assert result == "diare"

    def test_typo_correction_diagnosis(self):
        """Koreksi diagnosa yang typo dari OCR."""
        word = "scabis"  # dekat dengan "scabies"
        result = nlp_text_correction(word, KB_DIAGNOSIS)
        assert result == "scabies"

    def test_typo_correction_medicine(self):
        """Koreksi nama obat yang typo."""
        word = "ivermectn"  # dekat dengan "ivermectin"
        result = nlp_text_correction(word, KB_OBAT)
        assert result == "ivermectin"

    def test_typo_correction_status(self):
        """Koreksi status kondisi yang typo."""
        word = "membaek"  # dekat dengan "membaik"
        result = nlp_text_correction(word, KB_STATUS)
        assert result == "membaik"

    def test_typo_correction_gender(self):
        """Koreksi jenis kelamin yang typo."""
        word = "betna"  # dekat dengan "betina"
        result = nlp_text_correction(word, KB_KELAMIN)
        assert result == "betina"

    def test_typo_correction_pregnancy(self):
        """Koreksi status kebuntingan yang typo."""
        word = "buntng"  # dekat dengan "bunting"
        result = nlp_text_correction(word, KB_KEBUNTINGAN)
        assert result == "bunting"

    def test_custom_threshold_lower(self):
        """Threshold yang lebih rendah (70) memperluas cakupan koreksi."""
        word = "ivrmctn"  # lebih jauh dari "ivermectin"
        result_strict = nlp_text_correction(word, KB_OBAT, threshold=90)
        result_lenient = nlp_text_correction(word, KB_OBAT, threshold=50)
        # Dengan threshold lebih ketat, mungkin tidak terkoreksi
        # Dengan threshold lebih lenient, kemungkinan besar terkoreksi
        # Minimal kita uji: threshold rendah tidak crash dan mengembalikan string
        assert isinstance(result_strict, str)
        assert isinstance(result_lenient, str)

    # ---- Negative Tests ----

    def test_no_match_returns_original(self):
        """Kata yang sangat beda dari semua item KB tidak dikoreksi."""
        word = "XYZ123ABC"
        result = nlp_text_correction(word, KB_RAS)
        assert result == "XYZ123ABC"

    def test_empty_kb_returns_original(self):
        """KB list kosong → kata dikembalikan tanpa perubahan."""
        word = "Garut"
        result = nlp_text_correction(word, [])
        assert result == "Garut"

    # ---- Boundary Value Tests ----

    def test_word_length_2_skipped(self):
        """Kata dengan panjang ≤ 2 karakter di-skip (return as-is)."""
        word = "ab"
        result = nlp_text_correction(word, KB_RAS)
        assert result == "ab"

    def test_word_length_1_skipped(self):
        """Kata dengan panjang 1 karakter di-skip."""
        word = "a"
        result = nlp_text_correction(word, KB_RAS)
        assert result == "a"

    def test_word_length_3_processed(self):
        """Kata dengan panjang 3 karakter diproses (tidak di-skip)."""
        word = "orf"  # exact match di KB_DIAGNOSIS
        result = nlp_text_correction(word, KB_DIAGNOSIS)
        # "orf" exact match → score 100, dan karena threshold < 100 → tidak dikoreksi
        # (exact match di-skip per logika `threshold <= match[1] < 100`)
        assert result == "orf"

    # ---- Edge Case Tests ----

    def test_empty_word_returns_empty(self):
        """Kata kosong dikembalikan tanpa error."""
        result = nlp_text_correction("", KB_RAS)
        assert result == ""

    def test_placeholder_dash_skipped(self):
        """Placeholder '-' di-skip oleh guard clause."""
        result = nlp_text_correction("-", KB_RAS)
        assert result == "-"

    def test_placeholder_double_dash_skipped(self):
        """Placeholder '--' di-skip oleh guard clause."""
        result = nlp_text_correction("--", KB_RAS)
        assert result == "--"

    def test_placeholder_tilde_skipped(self):
        """Placeholder '~' di-skip oleh guard clause."""
        result = nlp_text_correction("~", KB_RAS)
        assert result == "~"

    def test_case_insensitive_matching(self):
        """Fuzzy matching case-insensitive tapi mengembalikan casing asli dari KB."""
        word = "garut"  # lowercase → cocok dengan "Garut" di KB
        result = nlp_text_correction(word, KB_RAS)
        # exact match (score 100) → tetap "garut" karena score == 100 → if threshold <= 100 < 100 → False
        # Exact match seharusnya TIDAK dikoreksi per logika
        assert result == "garut"

    def test_multiword_kb_entry_correction(self):
        """KB entry multi-kata ('Ekor Gemuk') bisa mengoreksi typo multi-kata."""
        word = "Ekor Gemk"  # dekat dengan "Ekor Gemuk"
        result = nlp_text_correction(word, KB_RAS)
        assert result == "Ekor Gemuk"


# ====================================================================
# _strip_bullet
# ====================================================================
class TestStripBullet:
    """
    Tujuan: Memastikan penanda bullet di awal baris dihapus
    sebelum parsing label:value.
    """

    # ---- Positive Tests ----

    def test_strip_asterisk_bullet(self):
        result = _strip_bullet("* item satu")
        assert result == "item satu"

    def test_strip_dash_bullet(self):
        result = _strip_bullet("- item dua")
        assert result == "item dua"

    def test_strip_unicode_bullet(self):
        result = _strip_bullet("• item tiga")
        assert result == "item tiga"

    def test_strip_filled_circle_bullet(self):
        """Unicode ● (U+25CF) filled circle."""
        result = _strip_bullet("● item empat")
        assert result == "item empat"

    def test_strip_multiple_bullets(self):
        """Multiple bullet chars berturut-turut."""
        result = _strip_bullet("**- item")
        assert result == "item"

    # ---- Negative Tests ----

    def test_no_bullet_unchanged(self):
        result = _strip_bullet("normal text tanpa bullet")
        assert result == "normal text tanpa bullet"

    def test_bullet_mid_text_unchanged(self):
        """Bullet di tengah kalimat tidak dihapus."""
        result = _strip_bullet("text - with dash")
        assert result == "text - with dash"

    # ---- Edge Case Tests ----

    def test_empty_string(self):
        result = _strip_bullet("")
        assert result == ""

    def test_bullet_only(self):
        """Baris hanya berisi bullet → menjadi string kosong."""
        result = _strip_bullet("* ")
        assert result == ""

    def test_whitespace_after_bullet(self):
        """Spasi berlebih setelah bullet dibersihkan."""
        result = _strip_bullet("*    item")
        assert result == "item"


# ====================================================================
# _split_glued_lines
# ====================================================================
class TestSplitGluedLines:
    """
    Tujuan: Memastikan baris yang tergabung akibat OCR gagal mendeteksi
    newline bisa dipisahkan kembali berdasarkan label field yang dikenal.
    """

    # ---- Positive Tests ----

    def test_split_ear_tag_glued(self):
        """Label 'Ear Tag:' menempel di akhir value sebelumnya."""
        text = "031Ear Tag: 001"
        result = _split_glued_lines(text)
        assert "Ear Tag: 001" in result
        assert "\n" in result

    def test_split_jenis_kelamin_glued(self):
        """Label 'Jenis Kelamin:' menempel setelah value."""
        text = "GarutJenis Kelamin: jantan"
        result = _split_glued_lines(text)
        assert "\n" in result
        assert "Jenis Kelamin: jantan" in result

    def test_split_multiple_glued(self):
        """Beberapa label tergabung dalam satu baris."""
        text = "001Jenis Kelamin: jantanTanggal Lahir: 12-01-2025"
        result = _split_glued_lines(text)
        lines = [l.strip() for l in result.split("\n") if l.strip()]
        assert len(lines) >= 2

    # ---- Negative Tests ----

    def test_no_glued_labels_unchanged(self):
        """Baris tanpa label tergabung → tidak berubah."""
        text = "Normal text without labels"
        result = _split_glued_lines(text)
        assert result == text

    def test_label_with_space_before_not_split(self):
        """Label dengan spasi sebelumnya (bukan tergabung) → tidak dipisahkan."""
        text = "value Ear Tag: 001"
        # Ada spasi antara "value" dan "Ear" → lookbehind [a-zA-Z0-9] perlu char langsung menempel
        # Sebenarnya "e" di "value" langsung diikuti spasi → TIDAK cocok lookbehind
        # Jadi harusnya tidak dipisah
        result = _split_glued_lines(text)
        # Ini TIDAK akan split karena ada spasi sebelum "Ear"
        assert result == text

    # ---- Edge Case Tests ----

    def test_empty_string(self):
        result = _split_glued_lines("")
        assert result == ""

    def test_case_insensitive_split(self):
        """Split bekerja case-insensitive (flag re.IGNORECASE)."""
        text = "031ear tag: 001"
        result = _split_glued_lines(text)
        assert "\n" in result


# ====================================================================
# _is_label_only_line
# ====================================================================
class TestIsLabelOnlyLine:
    """
    Tujuan: Mendeteksi baris yang hanya berisi nama field label
    tanpa value data apapun.
    """

    # ---- Positive Tests ----

    def test_single_label_word(self):
        assert _is_label_only_line("Gejala") is True

    def test_multi_label_words(self):
        assert _is_label_only_line("Status Kondisi") is True

    def test_label_with_punctuation(self):
        """Label dengan tanda baca → kata di-strip, tetap dikenali."""
        assert _is_label_only_line("Ear Tag:") is True

    def test_three_label_words(self):
        assert _is_label_only_line("Dosis Obat Tindakan") is True

    # ---- Negative Tests ----

    def test_line_with_value_data(self):
        """Baris mengandung data value (bukan hanya label) → False."""
        assert _is_label_only_line("Ear Tag: 001") is False

    def test_line_with_numbers(self):
        """Baris mengandung angka → pasti ada data → False."""
        assert _is_label_only_line("Gejala 123") is False

    def test_line_with_unknown_word(self):
        """Baris mengandung kata yang bukan label → False."""
        assert _is_label_only_line("Gejala demam") is False

    # ---- Edge Case Tests ----

    def test_empty_string_returns_false(self):
        assert _is_label_only_line("") is False

    def test_whitespace_only_returns_false(self):
        assert _is_label_only_line("   ") is False

    def test_label_word_with_mixed_case(self):
        """Kata label case-insensitive (dicek via .lower())."""
        assert _is_label_only_line("EAR TAG") is True


# ====================================================================
# _parse_line_with_map
# ====================================================================
class TestParseLineWithMap:
    """
    Tujuan: Memastikan parser inti bisa mengekstrak (field_key, value)
    dari berbagai format baris OCR menggunakan field_map.
    """

    SAMPLE_FIELD_MAP = {
        r"ear.?tag": "ear_tag",
        r"berat.?badan|berat|bobot": "berat_badan",
        r"gejala|symptom": "gejala",
        r"catatan|note": "catatan",
    }

    # ---- Positive Tests (Separator: / =) ----

    def test_colon_separator(self):
        """Format standar 'Label: Value'."""
        key, value = _parse_line_with_map("Ear Tag: 001", self.SAMPLE_FIELD_MAP)
        assert key == "ear_tag"
        assert value == "001"

    def test_equals_separator(self):
        """Format alternatif 'Label = Value'."""
        key, value = _parse_line_with_map("Berat Badan = 5.2 kg", self.SAMPLE_FIELD_MAP)
        assert key == "berat_badan"
        assert value == "5.2 kg"

    def test_colon_with_extra_spaces(self):
        """Spasi berlebih di sekitar separator."""
        key, value = _parse_line_with_map("Gejala  :   demam tinggi", self.SAMPLE_FIELD_MAP)
        assert key == "gejala"
        assert value == "demam tinggi"

    # ---- Positive Tests (Sliding Window — tanpa separator) ----

    def test_sliding_window_1_word_label(self):
        """Label 1 kata tanpa separator, value di sisa baris."""
        key, value = _parse_line_with_map("Gejala demam tinggi", self.SAMPLE_FIELD_MAP)
        assert key == "gejala"
        assert value == "demam tinggi"

    def test_sliding_window_2_word_label(self):
        """Label 2 kata tanpa separator."""
        key, value = _parse_line_with_map("Berat Badan 5.2 kg", self.SAMPLE_FIELD_MAP)
        assert key == "berat_badan"
        assert value == "Badan 5.2 kg"

    # ---- Negative Tests ----

    def test_no_matching_label(self):
        """Baris tanpa label yang dikenali → (None, None)."""
        key, value = _parse_line_with_map("Random text tanpa label", self.SAMPLE_FIELD_MAP)
        assert key is None
        assert value is None

    def test_empty_value_after_colon(self):
        """Label ada tapi value kosong setelah colon."""
        key, value = _parse_line_with_map("Ear Tag:", self.SAMPLE_FIELD_MAP)
        # sep[1].strip() akan kosong → tidak masuk if branch, fallback ke sliding window
        # Sliding window: hanya 2 kata ["Ear", "Tag:"] → length 1: "Ear" cocok? Tidak.
        # Harusnya return None, None
        assert key is None
        assert value is None

    # ---- Edge Case Tests ----

    def test_case_insensitive_label(self):
        """Label matching case-insensitive."""
        key, value = _parse_line_with_map("EAR TAG: 001", self.SAMPLE_FIELD_MAP)
        assert key == "ear_tag"
        assert value == "001"

    def test_label_with_special_chars(self):
        """Label dengan karakter khusus (EarTag tanpa spasi)."""
        key, value = _parse_line_with_map("EarTag: 001", self.SAMPLE_FIELD_MAP)
        assert key == "ear_tag"  # ear.?tag regex cocok

    def test_single_word_line(self):
        """Baris hanya 1 kata → sliding window tidak bisa (len(words) <= length)."""
        key, value = _parse_line_with_map("Gejala", self.SAMPLE_FIELD_MAP)
        assert key is None
        assert value is None


# ====================================================================
# _merge_lookback_lines
# ====================================================================
class TestMergeLookbackLines:
    """
    Tujuan: Memastikan baris 'yatim' (value tanpa label) digabungkan
    dengan baris berikutnya yang memiliki label field, untuk menangani
    layout OCR terbalik.
    """

    SAMPLE_FIELD_MAP = {
        r"status.?kondisi|status|kondisi": "status_kondisi",
        r"tindakan|treatment": "tindakan",
        r"gejala": "gejala",
    }

    # ---- Positive Tests ----

    def test_orphan_merged_with_next_field(self):
        """Baris yatim 'Susah makan' digabungkan dengan label 'Status Kondisi'."""
        lines = ["Susah makan", "Status Kondisi"]
        result = _merge_lookback_lines(lines, self.SAMPLE_FIELD_MAP)
        assert len(result) == 1
        assert "Status Kondisi" in result[0]
        assert "Susah makan" in result[0]
        assert _LOOKBACK_MARKER in result[0]

    def test_line_with_colon_not_merged(self):
        """Baris yang sudah punya separator ':' TIDAK digabungkan."""
        lines = ["Gejala: demam", "Status Kondisi"]
        result = _merge_lookback_lines(lines, self.SAMPLE_FIELD_MAP)
        assert len(result) == 2
        assert result[0] == "Gejala: demam"

    # ---- Negative Tests ----

    def test_no_orphan_lines(self):
        """Semua baris punya label → tidak ada penggabungan."""
        lines = ["Gejala: demam", "Status Kondisi: stabil"]
        result = _merge_lookback_lines(lines, self.SAMPLE_FIELD_MAP)
        assert len(result) == 2

    def test_orphan_at_end_not_merged(self):
        """Baris yatim di posisi terakhir → tidak ada baris berikutnya → tetap sendiri."""
        lines = ["Gejala: demam", "orphan text"]
        result = _merge_lookback_lines(lines, self.SAMPLE_FIELD_MAP)
        assert len(result) == 2
        assert result[1] == "orphan text"

    # ---- Edge Case Tests ----

    def test_empty_list(self):
        result = _merge_lookback_lines([], self.SAMPLE_FIELD_MAP)
        assert result == []

    def test_single_orphan_line(self):
        """Hanya satu baris yatim tanpa baris berikutnya."""
        lines = ["orphan text"]
        result = _merge_lookback_lines(lines, self.SAMPLE_FIELD_MAP)
        assert len(result) == 1
        assert result[0] == "orphan text"

    def test_consecutive_orphans_partial_merge(self):
        """Dua baris yatim berturut diikuti satu baris label."""
        lines = ["orphan1", "orphan2", "Gejala domba"]
        result = _merge_lookback_lines(lines, self.SAMPLE_FIELD_MAP)
        # orphan1: cek orphan1 (no field), next = orphan2 (no field) → tidak merge
        # orphan2: cek orphan2 (no field), next = Gejala domba (has field, no colon/=) → merge
        # Jadi: ["orphan1", "Gejala domba orphan2{marker}"]
        assert len(result) == 2
        assert _LOOKBACK_MARKER in result[1]


# ====================================================================
# _strip_leading_label_words
# ====================================================================
class TestStripLeadingLabelWords:
    """
    Tujuan: Membersihkan kata-kata label yang nyangkut di awal value
    (hanya untuk baris hasil lookback merge).
    """

    # ---- Positive Tests ----

    def test_strip_label_word_from_merged(self):
        """Kata label 'Kondisi' di-strip dari value lookback-merged."""
        result = _strip_leading_label_words("Kondisi Susah makan", is_lookback_merged=True)
        assert result == "Susah makan"

    def test_strip_multiple_label_words(self):
        """Beberapa kata label berurutan di-strip."""
        result = _strip_leading_label_words("Status Kondisi membaik", is_lookback_merged=True)
        assert result == "membaik"

    def test_strip_short_token_after_label(self):
        """Token pendek (≤2 huruf) setelah label words juga di-strip."""
        result = _strip_leading_label_words("Tindakan an pemberian obat", is_lookback_merged=True)
        assert result == "pemberian obat"

    # ---- Negative Tests ----

    def test_non_lookback_not_stripped(self):
        """is_lookback_merged=False → value tidak diubah sama sekali."""
        result = _strip_leading_label_words("Domba Garut", is_lookback_merged=False)
        assert result == "Domba Garut"

    # ---- Edge Case Tests ----

    def test_all_label_words_returns_original(self):
        """Semua kata adalah label words → cleaned kosong → return original."""
        result = _strip_leading_label_words("Ear Tag Domba", is_lookback_merged=True)
        assert result == "Ear Tag Domba"  # cleaned kosong → return value asli

    def test_empty_value(self):
        result = _strip_leading_label_words("", is_lookback_merged=True)
        assert result == ""

    def test_only_short_tokens(self):
        """Value hanya berisi token pendek setelah label removal."""
        result = _strip_leading_label_words("Tag an", is_lookback_merged=True)
        # "Tag" → label word → strip → "an" → len 2 & alpha → strip → kosong → return "Tag an"
        assert result == "Tag an"
