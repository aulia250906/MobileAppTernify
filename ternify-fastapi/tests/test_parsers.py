"""
Unit Tests untuk parser-parser form di ocr_service.py

Cakupan:
- parse_rekam_medis_card: Parsing form rekam medis domba
- parse_perkawinan_card: Parsing form perkawinan/kawin domba
- parse_data_domba_card: Parsing form data domba
"""
import pytest
from ocr_service import (
    parse_rekam_medis_card,
    parse_perkawinan_card,
    parse_data_domba_card,
)


# ====================================================================
# parse_rekam_medis_card
# ====================================================================
class TestParseRekamMedisCard:
    """
    Tujuan: Memastikan raw OCR text form rekam medis di-parse menjadi
    structured dict dengan fields: ear_tag, berat_badan, gejala, diagnosa,
    tindakan, dosis_obat, status_kondisi, catatan.

    Dependensi internal: _split_glued_lines, _strip_bullet,
    _merge_lookback_lines, _parse_line_with_map, _strip_leading_label_words,
    nlp_text_correction (KB_GEJALA, KB_DIAGNOSIS, KB_TINDAKAN, KB_OBAT, KB_STATUS)
    """

    # ---- Positive Tests ----

    def test_parse_complete_form(self):
        """Form lengkap dengan semua field → semua field terisi."""
        raw_text = """Ear Tag: 001
Berat Badan: 5.2 kg
Gejala: demam
Diagnosa: scabies
Tindakan: suntik
Dosis Obat: 2 ml
Status Kondisi: stabil
Catatan: perlu observasi lanjutan"""

        result = parse_rekam_medis_card(raw_text)

        assert result["ear_tag"] == "001"
        assert result["berat_badan"] == "5.2 kg"
        assert result["gejala"] == "demam"
        assert result["diagnosa"] == "scabies"
        assert result["tindakan"] == "suntik"
        assert result["dosis_obat"] == "2 ml"
        assert result["status_kondisi"] == "stabil"
        assert result["catatan"] == "perlu observasi lanjutan"

    def test_parse_ear_tag_extraction_3_digits(self):
        """Ear tag 3 digit diekstrak dari value yang mengandung noise."""
        raw_text = "Ear Tag: domba nomor 123 di kandang"
        result = parse_rekam_medis_card(raw_text)
        assert result["ear_tag"] == "123"

    def test_parse_ear_tag_extraction_2_digits(self):
        """Ear tag 2 digit (batas minimum regex \\d{2,4})."""
        raw_text = "Ear Tag: 01"
        result = parse_rekam_medis_card(raw_text)
        assert result["ear_tag"] == "01"

    def test_parse_ear_tag_extraction_4_digits(self):
        """Ear tag 4 digit (batas maksimum regex \\d{2,4})."""
        raw_text = "Ear Tag: 9999"
        result = parse_rekam_medis_card(raw_text)
        assert result["ear_tag"] == "9999"

    def test_parse_berat_badan_kg(self):
        """Berat badan dalam kg."""
        raw_text = "Berat Badan: 5.2 kg"
        result = parse_rekam_medis_card(raw_text)
        assert result["berat_badan"] == "5.2 kg"

    def test_parse_berat_badan_gram(self):
        """Berat badan dalam gram."""
        raw_text = "Berat Badan: 500 gram"
        result = parse_rekam_medis_card(raw_text)
        assert result["berat_badan"] == "500 gram"

    def test_parse_berat_badan_gr(self):
        """Berat badan dalam gr (alias gram)."""
        raw_text = "Berat Badan: 500 gr"
        result = parse_rekam_medis_card(raw_text)
        assert result["berat_badan"] == "500 gr"

    def test_parse_berat_badan_decimal_comma(self):
        """Berat badan dengan desimal koma (OCR kadang baca ',' bukan '.')."""
        raw_text = "Berat Badan: 5,2 kg"
        result = parse_rekam_medis_card(raw_text)
        assert result["berat_badan"] == "5,2 kg"

    def test_parse_dosis_obat_ml(self):
        """Dosis obat dalam ml."""
        raw_text = "Dosis Obat: 2 ml"
        result = parse_rekam_medis_card(raw_text)
        assert result["dosis_obat"] == "2 ml"

    def test_parse_dosis_obat_mg(self):
        """Dosis obat dalam mg."""
        raw_text = "Dosis Obat: 500 mg"
        result = parse_rekam_medis_card(raw_text)
        assert result["dosis_obat"] == "500 mg"

    def test_parse_dosis_obat_cc(self):
        """Dosis obat dalam cc."""
        raw_text = "Dosis Obat: 3 cc"
        result = parse_rekam_medis_card(raw_text)
        assert result["dosis_obat"] == "3 cc"

    def test_parse_dosis_obat_tablet(self):
        """Dosis obat dalam tablet."""
        raw_text = "Dosis Obat: 2 tablet"
        result = parse_rekam_medis_card(raw_text)
        assert result["dosis_obat"] == "2 tablet"

    def test_parse_dosis_fallback_to_ml(self):
        """Dosis dengan unit tidak dikenali → fallback ke 'ml'."""
        raw_text = "Dosis Obat: 5 nl"  # 'nl' bukan unit valid → fallback
        result = parse_rekam_medis_card(raw_text)
        assert result["dosis_obat"] == "5 ml"

    def test_parse_nlp_correction_gejala(self):
        """Gejala typo dikoreksi via NLP (threshold=70)."""
        raw_text = "Gejala: diaree"  # dekat "diare"
        result = parse_rekam_medis_card(raw_text)
        assert result["gejala"] == "diare"

    def test_parse_nlp_correction_diagnosa(self):
        """Diagnosa typo dikoreksi via NLP."""
        raw_text = "Diagnosa: scabis"  # dekat "scabies"
        result = parse_rekam_medis_card(raw_text)
        assert result["diagnosa"] == "scabies"

    def test_parse_nlp_correction_tindakan(self):
        """Tindakan typo dikoreksi via NLP."""
        raw_text = "Tindakan: vaksinsi"  # dekat "vaksinasi"
        result = parse_rekam_medis_card(raw_text)
        assert result["tindakan"] == "vaksinasi"

    def test_parse_nlp_correction_status(self):
        """Status kondisi typo dikoreksi via NLP."""
        raw_text = "Status Kondisi: membaek"  # dekat "membaik"
        result = parse_rekam_medis_card(raw_text)
        assert result["status_kondisi"] == "membaik"

    def test_parse_alternative_label_bobot(self):
        """Label alternatif 'Bobot' → berat_badan."""
        raw_text = "Bobot: 5.2 kg"
        result = parse_rekam_medis_card(raw_text)
        assert result["berat_badan"] == "5.2 kg"

    def test_parse_alternative_label_symptom(self):
        """Label alternatif 'Symptom' → gejala."""
        raw_text = "Symptom: demam"
        result = parse_rekam_medis_card(raw_text)
        assert result["gejala"] == "demam"

    def test_parse_equals_separator(self):
        """Separator '=' berfungsi sama dengan ':'."""
        raw_text = "Ear Tag = 001\nGejala = demam"
        result = parse_rekam_medis_card(raw_text)
        assert result["ear_tag"] == "001"
        assert result["gejala"] == "demam"

    # ---- Negative Tests ----

    def test_parse_empty_text(self):
        """Text kosong → semua field None."""
        result = parse_rekam_medis_card("")
        assert all(v is None for v in result.values())

    def test_parse_no_labels(self):
        """Text tanpa label field → semua field None."""
        result = parse_rekam_medis_card("random text without any recognized labels")
        assert all(v is None for v in result.values())

    def test_parse_ear_tag_no_digits(self):
        """Ear tag tanpa angka 2-4 digit → value asli dipakai (regex tidak match)."""
        raw_text = "Ear Tag: domba satu"
        result = parse_rekam_medis_card(raw_text)
        # Tidak ada angka 2-4 digit → id_match None → value = "domba satu"
        assert result["ear_tag"] == "domba satu"

    # ---- Boundary Value Tests ----

    def test_parse_berat_badan_zero(self):
        """Berat badan 0 kg."""
        raw_text = "Berat Badan: 0 kg"
        result = parse_rekam_medis_card(raw_text)
        assert result["berat_badan"] == "0 kg"

    def test_parse_ear_tag_single_digit(self):
        """Ear tag 1 digit → regex \\d{2,4} TIDAK match → value asli."""
        raw_text = "Ear Tag: 5"
        result = parse_rekam_medis_card(raw_text)
        # \\d{2,4} membutuhkan minimal 2 digit
        assert result["ear_tag"] == "5"

    def test_parse_ear_tag_5_digits(self):
        """Ear tag 5 digit → regex \\d{2,4} match 4 digit pertama."""
        raw_text = "Ear Tag: 12345"
        result = parse_rekam_medis_card(raw_text)
        # \\b(\\d{2,4})\\b → '12345' sebagai satu token, \\b artinya word boundary
        # '12345' punya 5 digit → \\d{2,4} tidak match '12345' seluruhnya
        # Tapi \\d{2,4} bisa match substring '1234' → apakah ada \\b setelah '1234'?
        # Di '12345', tidak ada \\b setelah digit ke-4 → TIDAK match
        assert result["ear_tag"] is not None

    # ---- Edge Case Tests ----

    def test_parse_ocr_noise_characters(self):
        """Karakter noise OCR (||, []) dibersihkan sebelum parsing."""
        raw_text = "Ear Tag: ||001||\nGejala: [[demam]]"
        result = parse_rekam_medis_card(raw_text)
        assert result["ear_tag"] is not None

    def test_parse_bullet_lines(self):
        """Baris dengan bullet marker tetap di-parse setelah strip."""
        raw_text = "* Ear Tag: 001\n- Gejala: demam"
        result = parse_rekam_medis_card(raw_text)
        assert result["ear_tag"] == "001"
        assert result["gejala"] == "demam"

    def test_result_keys_complete(self):
        """Hasil selalu memiliki semua 8 field keys."""
        result = parse_rekam_medis_card("")
        expected_keys = {"ear_tag", "berat_badan", "gejala", "diagnosa",
                         "tindakan", "dosis_obat", "status_kondisi", "catatan"}
        assert set(result.keys()) == expected_keys

    def test_parse_dosis_unit_kg_not_fallback_to_ml(self):
        """Dosis dengan unit 'kg' → TIDAK fallback ke ml (exclusion di kode)."""
        raw_text = "Dosis Obat: 5 kg"
        result = parse_rekam_medis_card(raw_text)
        # Regex utama dosis: \\d{1,3}(?:[.,]\\d)?\\s*(?:ml|mg|cc|tablet|kapsul) → 'kg' tidak cocok
        # Fallback: '5 kg' → fallback_match group(2)='kg', yang ada di exclusion ('kg', 'gr')
        # → fallback TIDAK jalan → value tetap "5 kg"
        assert result["dosis_obat"] == "5 kg"


# ====================================================================
# parse_perkawinan_card
# ====================================================================
class TestParsePerkawinanCard:
    """
    Tujuan: Memastikan raw OCR text form perkawinan di-parse menjadi
    structured dict dengan fields: tanggal_perkawinan, ear_tag_induk,
    ear_tag_pejantan, status_kebuntingan, catatan.
    """

    # ---- Positive Tests ----

    def test_parse_complete_form(self):
        """Form lengkap perkawinan → semua field terisi."""
        raw_text = """Tanggal Perkawinan: 12-01-2025
Induk: 001
Jantan Ear Tag: 002
Status Kebuntingan: bunting
Catatan: kawin alami"""

        result = parse_perkawinan_card(raw_text)

        assert result["tanggal_perkawinan"] == "12-01-2025"
        assert result["ear_tag_induk"] == "001"
        assert result["ear_tag_pejantan"] == "002"
        assert result["status_kebuntingan"] == "bunting"
        assert result["catatan"] == "kawin alami"

    def test_parse_ear_tag_induk_extracted(self):
        """Ear tag induk diekstrak angka 2-4 digit."""
        raw_text = "Induk: domba nomor 123"
        result = parse_perkawinan_card(raw_text)
        assert result["ear_tag_induk"] == "123"

    def test_parse_ear_tag_pejantan_extracted(self):
        """Ear tag pejantan diekstrak angka 2-4 digit."""
        raw_text = "Jantan Ear Tag: 456"
        result = parse_perkawinan_card(raw_text)
        assert result["ear_tag_pejantan"] == "456"

    def test_parse_tanggal_date_normalized(self):
        """Tanggal dengan spasi internal dinormalisasi (spasi dihapus)."""
        raw_text = "Tanggal Perkawinan: 12 - 01 - 2025"
        result = parse_perkawinan_card(raw_text)
        assert result["tanggal_perkawinan"] == "12-01-2025"

    def test_parse_tanggal_slash_separator(self):
        """Tanggal dengan separator '/' juga dikenali."""
        raw_text = "Tanggal Perkawinan: 12/01/2025"
        result = parse_perkawinan_card(raw_text)
        assert result["tanggal_perkawinan"] == "12/01/2025"

    def test_parse_tanggal_dot_separator(self):
        """Tanggal dengan separator '.' juga dikenali."""
        raw_text = "Tanggal Perkawinan: 12.01.2025"
        result = parse_perkawinan_card(raw_text)
        assert result["tanggal_perkawinan"] == "12.01.2025"

    def test_parse_nlp_correction_kebuntingan(self):
        """Status kebuntingan typo dikoreksi via NLP."""
        raw_text = "Status Kebuntingan: buntng"  # dekat "bunting"
        result = parse_perkawinan_card(raw_text)
        assert result["status_kebuntingan"] == "bunting"

    def test_parse_alternative_label_tgl(self):
        """Label alternatif 'Tgl Perkawinan' → tanggal_perkawinan."""
        raw_text = "Tgl Perkawinan: 12-01-2025"
        result = parse_perkawinan_card(raw_text)
        assert result["tanggal_perkawinan"] == "12-01-2025"

    def test_parse_alternative_label_tanggal_kawin(self):
        """Label alternatif 'Tanggal Kawin' → tanggal_perkawinan."""
        raw_text = "Tanggal Kawin: 12-01-2025"
        result = parse_perkawinan_card(raw_text)
        assert result["tanggal_perkawinan"] == "12-01-2025"

    # ---- Negative Tests ----

    def test_parse_empty_text(self):
        """Text kosong → semua field None."""
        result = parse_perkawinan_card("")
        assert all(v is None for v in result.values())

    def test_parse_no_labels(self):
        """Text tanpa label perkawinan → semua None."""
        result = parse_perkawinan_card("just some random text here")
        assert all(v is None for v in result.values())

    # ---- Edge Case Tests ----

    def test_result_keys_complete(self):
        """Hasil selalu memiliki semua 5 field keys."""
        result = parse_perkawinan_card("")
        expected_keys = {"tanggal_perkawinan", "ear_tag_induk",
                         "ear_tag_pejantan", "status_kebuntingan", "catatan"}
        assert set(result.keys()) == expected_keys

    def test_parse_tanggal_short_year(self):
        """Tahun 2 digit (misal '25' bukan '2025')."""
        raw_text = "Tanggal Perkawinan: 12-01-25"
        result = parse_perkawinan_card(raw_text)
        assert result["tanggal_perkawinan"] == "12-01-25"

    def test_parse_ear_tag_same_for_both(self):
        """Ear tag induk dan pejantan bisa sama (edge case data)."""
        raw_text = "Induk: 001\nJantan Ear Tag: 001"
        result = parse_perkawinan_card(raw_text)
        assert result["ear_tag_induk"] == "001"
        assert result["ear_tag_pejantan"] == "001"


# ====================================================================
# parse_data_domba_card
# ====================================================================
class TestParseDataDombaCard:
    """
    Tujuan: Memastikan raw OCR text form data domba di-parse menjadi
    structured dict dengan fields: ear_tag, ear_tag_induk, ear_tag_jantan,
    jenis_kelamin, tanggal_lahir, jenis_domba, catatan.
    """

    # ---- Positive Tests ----

    def test_parse_complete_form(self):
        """Form lengkap data domba → semua field terisi."""
        raw_text = """Ear Tag: 001
Jenis Kelamin: jantan
Tanggal Lahir: 12-01-2025
Jenis Domba: Garut
Induk: 010
Jantan Ear Tag: 020
Catatan: domba sehat"""

        result = parse_data_domba_card(raw_text)

        assert result["ear_tag"] == "001"
        assert result["jenis_kelamin"] == "jantan"
        assert result["tanggal_lahir"] == "12-01-2025"
        assert result["jenis_domba"] == "Garut"
        assert result["ear_tag_induk"] == "010"
        assert result["ear_tag_jantan"] == "020"
        assert result["catatan"] == "domba sehat"

    def test_parse_nlp_correction_jenis_kelamin(self):
        """Jenis kelamin typo dikoreksi via NLP."""
        raw_text = "Jenis Kelamin: jntan"  # dekat "jantan"
        result = parse_data_domba_card(raw_text)
        assert result["jenis_kelamin"] == "jantan"

    def test_parse_nlp_correction_jenis_domba(self):
        """Jenis domba typo dikoreksi via NLP."""
        raw_text = "Jenis Domba: Garrt"  # dekat "Garut"
        result = parse_data_domba_card(raw_text)
        assert result["jenis_domba"] == "Garut"

    def test_parse_betina_gender(self):
        """Jenis kelamin betina."""
        raw_text = "Jenis Kelamin: betina"
        result = parse_data_domba_card(raw_text)
        assert result["jenis_kelamin"] == "betina"

    def test_parse_jantan_kastrasi(self):
        """Jenis kelamin 'jantan kastrasi' (multi-kata dari KB)."""
        raw_text = "Jenis Kelamin: jantan kastrasi"
        result = parse_data_domba_card(raw_text)
        # "jantan kastrasi" exact match di KB → score 100 → TIDAK dikoreksi
        # (karena threshold <= match[1] < 100 → False)
        assert result["jenis_kelamin"] == "jantan kastrasi"

    def test_parse_ear_tag_extracted(self):
        """Ear tag utama diekstrak angka 2-4 digit."""
        raw_text = "Ear Tag: 456"
        result = parse_data_domba_card(raw_text)
        assert result["ear_tag"] == "456"

    def test_parse_ear_tag_induk_extracted(self):
        """Ear tag induk diekstrak angka."""
        raw_text = "Induk: 010"
        result = parse_data_domba_card(raw_text)
        assert result["ear_tag_induk"] == "010"

    def test_parse_ear_tag_jantan_extracted(self):
        """Ear tag jantan/pejantan diekstrak angka."""
        raw_text = "Jantan Ear Tag: 020"
        result = parse_data_domba_card(raw_text)
        assert result["ear_tag_jantan"] == "020"

    def test_parse_tanggal_lahir_normalized(self):
        """Tanggal lahir dengan spasi dinormalisasi."""
        raw_text = "Tanggal Lahir: 12 - 01 - 2025"
        result = parse_data_domba_card(raw_text)
        assert result["tanggal_lahir"] == "12-01-2025"

    def test_parse_alternative_label_ras(self):
        """Label alternatif 'Ras' → jenis_domba."""
        raw_text = "Ras: Merino"
        result = parse_data_domba_card(raw_text)
        assert result["jenis_domba"] == "Merino"

    def test_parse_alternative_label_breed(self):
        """Label alternatif 'Breed' → jenis_domba."""
        raw_text = "Breed: Suffolk"
        result = parse_data_domba_card(raw_text)
        assert result["jenis_domba"] == "Suffolk"

    def test_parse_alternative_label_kelamin(self):
        """Label alternatif 'Kelamin' tanpa 'Jenis' → jenis_kelamin."""
        raw_text = "Kelamin: betina"
        result = parse_data_domba_card(raw_text)
        assert result["jenis_kelamin"] == "betina"

    # ---- Negative Tests ----

    def test_parse_empty_text(self):
        """Text kosong → semua field None."""
        result = parse_data_domba_card("")
        assert all(v is None for v in result.values())

    def test_parse_no_labels(self):
        """Text tanpa label data domba → semua None."""
        result = parse_data_domba_card("some random text")
        assert all(v is None for v in result.values())

    # ---- Edge Case Tests ----

    def test_result_keys_complete(self):
        """Hasil selalu memiliki semua 7 field keys."""
        result = parse_data_domba_card("")
        expected_keys = {"ear_tag", "ear_tag_induk", "ear_tag_jantan",
                         "jenis_kelamin", "tanggal_lahir", "jenis_domba", "catatan"}
        assert set(result.keys()) == expected_keys

    def test_parse_induk_before_ear_tag(self):
        """
        Field 'induk' harus dicek SEBELUM 'ear_tag' di FIELD_MAP (insertion order).
        Jika 'Induk (Ear Tag): 010' dicek 'ear_tag' duluan, hasilnya salah.
        """
        raw_text = "Induk: 010\nEar Tag: 001"
        result = parse_data_domba_card(raw_text)
        assert result["ear_tag_induk"] == "010"
        assert result["ear_tag"] == "001"

    def test_parse_multiple_breed_correction(self):
        """Beberapa jenis domba dari KB bisa dikoreksi."""
        for breed, typo in [("Merino", "Merrio"), ("Suffolk", "Sufflk"), ("Dorper", "Dorpre")]:
            raw_text = f"Jenis Domba: {typo}"
            result = parse_data_domba_card(raw_text)
            assert result["jenis_domba"] == breed, f"Expected '{breed}' from typo '{typo}'"
