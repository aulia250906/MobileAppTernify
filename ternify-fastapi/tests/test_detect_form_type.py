"""
Unit Tests untuk detect_form_type di ocr_service.py

Cakupan:
- Deteksi form PERKAWINAN (keyword-based)
- Deteksi form DATA_DOMBA (keyword-based)
- Deteksi form REKAM_MEDIS (keyword-based)
- Deteksi UNKNOWN (tidak dikenali)
- Prioritas dan overlap antar keyword
"""
import pytest
from ocr_service import detect_form_type


class TestDetectFormType:
    """
    Tujuan: Memastikan raw OCR text diklasifikasikan ke jenis form yang benar
    berdasarkan keyword matching. Logika menggunakan if/elif chain sehingga
    urutan pengecekan menentukan prioritas.

    Prioritas (sesuai urutan kode):
    1. PERKAWINAN — "DOKUMEN PERKAWINAN" atau "PERKAWINAN"
    2. DATA_DOMBA — "DOKUMEN DOMBA" atau ("JENIS KELAMIN" + "TANGGAL LAHIR")
    3. REKAM_MEDIS — "DOKUMEN REKAM MEDIS" atau "REKAM MEDIS"
    4. Sinyal tambahan PERKAWINAN — "INDUK" + "PEJANTAN" + ("KEBUNTINGAN"/"BUNTING")
    5. Sinyal tambahan REKAM_MEDIS — "GEJALA" / "DIAGNOSA" / "DIAGNOSIS"
    6. Sinyal tambahan REKAM_MEDIS — ("BERAT BADAN"/"BOBOT") + ("STATUS KONDISI"/"TINDAKAN"/"DOSIS")
    7. Sinyal tambahan DATA_DOMBA — "JENIS DOMBA" + "TANGGAL LAHIR"
    8. UNKNOWN
    """

    # ---- Positive Tests: Keyword Utama ----

    def test_detect_perkawinan_explicit_title(self):
        """'DOKUMEN PERKAWINAN' di judul → PERKAWINAN."""
        text = "DOKUMEN PERKAWINAN\nTanggal: 12-01-2025\nInduk: 001"
        assert detect_form_type(text) == "PERKAWINAN"

    def test_detect_perkawinan_keyword_only(self):
        """Keyword 'PERKAWINAN' saja tanpa 'DOKUMEN' → PERKAWINAN."""
        text = "Form Perkawinan Domba\nEar Tag Induk: 001"
        assert detect_form_type(text) == "PERKAWINAN"

    def test_detect_data_domba_explicit_title(self):
        """'DOKUMEN DOMBA' di judul → DATA_DOMBA."""
        text = "DOKUMEN DOMBA\nEar Tag: 001\nJenis: Garut"
        assert detect_form_type(text) == "DATA_DOMBA"

    def test_detect_data_domba_combined_keywords(self):
        """'JENIS KELAMIN' + 'TANGGAL LAHIR' → DATA_DOMBA."""
        text = "Ear Tag: 001\nJenis Kelamin: Jantan\nTanggal Lahir: 12-01-2025"
        assert detect_form_type(text) == "DATA_DOMBA"

    def test_detect_rekam_medis_explicit_title(self):
        """'DOKUMEN REKAM MEDIS' di judul → REKAM_MEDIS."""
        text = "DOKUMEN REKAM MEDIS\nEar Tag: 001\nGejala: demam"
        assert detect_form_type(text) == "REKAM_MEDIS"

    def test_detect_rekam_medis_keyword_only(self):
        """Keyword 'REKAM MEDIS' tanpa 'DOKUMEN' → REKAM_MEDIS."""
        text = "Rekam Medis Pemeriksaan\nGejala: diare"
        assert detect_form_type(text) == "REKAM_MEDIS"

    # ---- Positive Tests: Sinyal Tambahan (Fallback) ----

    def test_detect_perkawinan_secondary_signals(self):
        """'INDUK' + 'PEJANTAN' + 'KEBUNTINGAN' → PERKAWINAN (sinyal tambahan)."""
        text = "Data Induk Betina: 001\nPejantan: 002\nStatus Kebuntingan: bunting"
        assert detect_form_type(text) == "PERKAWINAN"

    def test_detect_perkawinan_bunting_variant(self):
        """'INDUK' + 'PEJANTAN' + 'BUNTING' (tanpa 'KEBUNTINGAN') → PERKAWINAN."""
        text = "Induk: 001\nPejantan: 002\nBunting 2 bulan"
        assert detect_form_type(text) == "PERKAWINAN"

    def test_detect_rekam_medis_gejala_signal(self):
        """'GEJALA' saja → REKAM_MEDIS (sinyal tambahan)."""
        text = "Ear Tag: 001\nGejala: demam tinggi\nObat: paracetamol"
        assert detect_form_type(text) == "REKAM_MEDIS"

    def test_detect_rekam_medis_diagnosa_signal(self):
        """'DIAGNOSA' saja → REKAM_MEDIS (sinyal tambahan)."""
        text = "Ear Tag: 001\nDiagnosa: scabies"
        assert detect_form_type(text) == "REKAM_MEDIS"

    def test_detect_rekam_medis_diagnosis_signal(self):
        """'DIAGNOSIS' (ejaan alternatif) → REKAM_MEDIS (sinyal tambahan)."""
        text = "Ear Tag: 001\nDiagnosis: pneumonia"
        assert detect_form_type(text) == "REKAM_MEDIS"

    def test_detect_rekam_medis_berat_badan_plus_tindakan(self):
        """'BERAT BADAN' + 'TINDAKAN' → REKAM_MEDIS (sinyal tambahan)."""
        text = "Ear Tag: 001\nBerat Badan: 5 kg\nTindakan: suntik"
        assert detect_form_type(text) == "REKAM_MEDIS"

    def test_detect_rekam_medis_bobot_plus_dosis(self):
        """'BOBOT' + 'DOSIS' → REKAM_MEDIS (sinyal tambahan)."""
        text = "Ear Tag: 001\nBobot: 5 kg\nDosis: 2 ml"
        assert detect_form_type(text) == "REKAM_MEDIS"

    def test_detect_rekam_medis_berat_plus_status_kondisi(self):
        """'BERAT BADAN' + 'STATUS KONDISI' → REKAM_MEDIS."""
        text = "Ear Tag: 001\nBerat Badan: 5 kg\nStatus Kondisi: stabil"
        assert detect_form_type(text) == "REKAM_MEDIS"

    def test_detect_data_domba_jenis_domba_signal(self):
        """'JENIS DOMBA' + 'TANGGAL LAHIR' → DATA_DOMBA (sinyal tambahan)."""
        text = "Ear Tag: 001\nJenis Domba: Garut\nTanggal Lahir: 01-01-2025"
        assert detect_form_type(text) == "DATA_DOMBA"

    # ---- Negative Tests ----

    def test_unknown_no_keywords(self):
        """Text tanpa keyword form → UNKNOWN."""
        text = "Random text without any form keywords"
        assert detect_form_type(text) == "UNKNOWN"

    def test_unknown_empty_string(self):
        """Text kosong → UNKNOWN."""
        assert detect_form_type("") == "UNKNOWN"

    def test_unknown_only_ear_tag(self):
        """Hanya 'EAR TAG' tanpa sinyal form lain → UNKNOWN."""
        text = "Ear Tag: 001"
        assert detect_form_type(text) == "UNKNOWN"

    def test_unknown_partial_rekam_medis_signal(self):
        """'BERAT BADAN' saja (tanpa TINDAKAN/DOSIS/STATUS KONDISI) → UNKNOWN."""
        text = "Ear Tag: 001\nBerat Badan: 5 kg"
        assert detect_form_type(text) == "UNKNOWN"

    # ---- Edge Case Tests: Prioritas & Overlap ----

    def test_perkawinan_takes_priority_over_others(self):
        """Jika 'PERKAWINAN' ada, selalu menang meskipun ada keyword lain."""
        text = "PERKAWINAN\nGejala: demam\nJenis Kelamin: jantan\nTanggal Lahir: 01-01"
        assert detect_form_type(text) == "PERKAWINAN"

    def test_data_domba_priority_over_rekam_medis(self):
        """'JENIS KELAMIN' + 'TANGGAL LAHIR' → DATA_DOMBA, meskipun ada 'GEJALA'."""
        text = "Jenis Kelamin: jantan\nTanggal Lahir: 01-01-2025\nGejala: demam"
        # DATA_DOMBA dicek sebelum REKAM_MEDIS di sinyal utama
        assert detect_form_type(text) == "DATA_DOMBA"

    def test_case_insensitive_detection(self):
        """Deteksi case-insensitive (text di-uppercase internal)."""
        text = "dokumen perkawinan\ntanggal: 12-01-2025"
        assert detect_form_type(text) == "PERKAWINAN"

    def test_mixed_case_detection(self):
        """Mixed case tetap terdeteksi."""
        text = "rEkAm MeDiS\nGejala: demam"
        assert detect_form_type(text) == "REKAM_MEDIS"

    def test_multiline_whitespace_normalized(self):
        """Multiple spaces/newlines dinormalisasi sebelum matching."""
        text = "DOKUMEN   \n  PERKAWINAN  \n  data"
        # re.sub(r"\\s+", " ", text.upper()) → "DOKUMEN PERKAWINAN DATA"
        # Tapi pengecekan menggunakan `in` pada string → "DOKUMEN PERKAWINAN" in "DOKUMEN PERKAWINAN DATA"
        # Harusnya: tidak match karena normalisasi mengubah newline jadi spasi
        # "DOKUMEN PERKAWINAN" IS in "DOKUMEN PERKAWINAN DATA" → True
        assert detect_form_type(text) == "PERKAWINAN"

    # ---- Boundary Value Tests ----

    def test_only_keyword_perkawinan(self):
        """Hanya kata 'Perkawinan' tanpa context → PERKAWINAN."""
        assert detect_form_type("Perkawinan") == "PERKAWINAN"

    def test_jenis_kelamin_without_tanggal_lahir(self):
        """'JENIS KELAMIN' tanpa 'TANGGAL LAHIR' → bukan DATA_DOMBA."""
        text = "Jenis Kelamin: jantan\nEar Tag: 001"
        assert detect_form_type(text) != "DATA_DOMBA"

    def test_tanggal_lahir_without_jenis_kelamin(self):
        """'TANGGAL LAHIR' tanpa 'JENIS KELAMIN' → bukan DATA_DOMBA via primary signal."""
        text = "Tanggal Lahir: 01-01-2025\nEar Tag: 001"
        result = detect_form_type(text)
        assert result != "DATA_DOMBA" or result == "UNKNOWN"

    def test_induk_pejantan_without_bunting(self):
        """'INDUK' + 'PEJANTAN' tanpa 'KEBUNTINGAN'/'BUNTING' → TIDAK PERKAWINAN via secondary."""
        text = "Induk: 001\nPejantan: 002\nCatatan: sehat"
        result = detect_form_type(text)
        assert result != "PERKAWINAN"
