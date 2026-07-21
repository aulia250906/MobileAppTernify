"""
Unit Tests untuk pipeline-level functions di ocr_service.py

Cakupan:
- preprocess_image: Image preprocessing (mock cv2 + pytesseract)
- process_form_image: Pipeline orchestrator (mock internal functions)
- ModelRegistry: Penyimpanan konfigurasi via Joblib
- validate_ocr_dataframe: Data validation via Pandas
"""
import os
import json
import pytest
from unittest.mock import patch, MagicMock
import numpy as np

from ocr_service import (
    preprocess_image, process_form_image,
    ModelRegistry, get_registry,
    validate_ocr_dataframe, _normalize_unicode_chars,
)


# ====================================================================
# preprocess_image
# ====================================================================
class TestPreprocessImage:
    """
    Tujuan: Memastikan pipeline preprocessing gambar berjalan benar:
    1. Load gambar → ValueError jika tidak ditemukan
    2. Konversi ke grayscale
    3. Upscale jika width < 1500px
    4. Blur, threshold, morphology, cleanup
    5. Hitung confidence dari pytesseract.image_to_data
    6. Return (final_image, confidence)

    Mock: cv2.imread, cv2.cvtColor, cv2.resize, cv2.GaussianBlur,
          cv2.adaptiveThreshold, cv2 morphology ops, pytesseract.image_to_data
    """

    @patch("ocr_service.pytesseract")
    @patch("ocr_service.cv2")
    def test_valid_image_returns_tuple(self, mock_cv2, mock_tess):
        """Gambar valid → return (ndarray, float confidence)."""
        # Arrange
        mock_img = np.zeros((100, 200, 3), dtype=np.uint8)  # 200px width < 1500
        mock_cv2.imread.return_value = mock_img
        mock_cv2.cvtColor.return_value = np.zeros((100, 200), dtype=np.uint8)
        mock_cv2.resize.return_value = np.zeros((750, 1500), dtype=np.uint8)
        mock_cv2.GaussianBlur.return_value = np.zeros((750, 1500), dtype=np.uint8)
        mock_cv2.adaptiveThreshold.return_value = np.zeros((750, 1500), dtype=np.uint8)
        mock_cv2.getStructuringElement.return_value = np.ones((1, 40), dtype=np.uint8)
        mock_cv2.morphologyEx.return_value = np.zeros((750, 1500), dtype=np.uint8)
        mock_cv2.add.return_value = np.zeros((750, 1500), dtype=np.uint8)
        mock_cv2.dilate.return_value = np.zeros((750, 1500), dtype=np.uint8)
        mock_cv2.subtract.return_value = np.zeros((750, 1500), dtype=np.uint8)
        mock_cv2.erode.return_value = np.zeros((750, 1500), dtype=np.uint8)

        # Constants untuk cv2
        mock_cv2.COLOR_BGR2GRAY = 6
        mock_cv2.INTER_CUBIC = 2
        mock_cv2.ADAPTIVE_THRESH_GAUSSIAN_C = 1
        mock_cv2.THRESH_BINARY_INV = 1
        mock_cv2.MORPH_RECT = 0
        mock_cv2.MORPH_OPEN = 2

        # Tesseract confidence data
        mock_tess.image_to_data.return_value = {
            "conf": [85, 90, 78, -1, 0, 92],
            "text": ["word1", "word2", "word3", "", "", "word4"],
            "top": [10, 10, 30, 0, 0, 30],
            "left": [10, 50, 10, 0, 0, 50],
        }
        mock_tess.Output.DICT = "dict"

        # Act
        result_img, confidence = preprocess_image("test_image.jpg")

        # Assert
        assert isinstance(confidence, float)
        assert confidence > 0
        mock_cv2.imread.assert_called_once_with("test_image.jpg")

    @patch("ocr_service.cv2")
    def test_image_not_found_raises_error(self, mock_cv2):
        """Gambar tidak ditemukan → ValueError."""
        # Arrange
        mock_cv2.imread.return_value = None

        # Act & Assert
        with pytest.raises(ValueError, match="Gambar tidak ditemukan"):
            preprocess_image("nonexistent.jpg")

    @patch("ocr_service.pytesseract")
    @patch("ocr_service.cv2")
    def test_image_width_above_1500_no_resize(self, mock_cv2, mock_tess):
        """Gambar dengan width >= 1500px TIDAK di-resize."""
        # Arrange
        mock_img = np.zeros((100, 2000, 3), dtype=np.uint8)  # width 2000 >= 1500
        mock_cv2.imread.return_value = mock_img
        gray = np.zeros((100, 2000), dtype=np.uint8)
        mock_cv2.cvtColor.return_value = gray
        mock_cv2.GaussianBlur.return_value = gray
        mock_cv2.adaptiveThreshold.return_value = gray
        mock_cv2.getStructuringElement.return_value = np.ones((1, 40), dtype=np.uint8)
        mock_cv2.morphologyEx.return_value = gray
        mock_cv2.add.return_value = gray
        mock_cv2.dilate.return_value = gray
        mock_cv2.subtract.return_value = gray
        mock_cv2.erode.return_value = gray

        mock_cv2.COLOR_BGR2GRAY = 6
        mock_cv2.ADAPTIVE_THRESH_GAUSSIAN_C = 1
        mock_cv2.THRESH_BINARY_INV = 1
        mock_cv2.MORPH_RECT = 0
        mock_cv2.MORPH_OPEN = 2

        mock_tess.image_to_data.return_value = {"conf": [85], "text": ["w"], "top": [0], "left": [0]}
        mock_tess.Output.DICT = "dict"

        # Act
        preprocess_image("wide_image.jpg")

        # Assert — cv2.resize should NOT be called
        mock_cv2.resize.assert_not_called()

    @patch("ocr_service.pytesseract")
    @patch("ocr_service.cv2")
    def test_confidence_zero_when_no_valid_conf(self, mock_cv2, mock_tess):
        """Tidak ada confidence valid (semua -1 atau 0) → confidence = 0."""
        # Arrange
        mock_img = np.zeros((100, 2000, 3), dtype=np.uint8)
        mock_cv2.imread.return_value = mock_img
        gray = np.zeros((100, 2000), dtype=np.uint8)
        mock_cv2.cvtColor.return_value = gray
        mock_cv2.GaussianBlur.return_value = gray
        mock_cv2.adaptiveThreshold.return_value = gray
        mock_cv2.getStructuringElement.return_value = np.ones((1, 40), dtype=np.uint8)
        mock_cv2.morphologyEx.return_value = gray
        mock_cv2.add.return_value = gray
        mock_cv2.dilate.return_value = gray
        mock_cv2.subtract.return_value = gray
        mock_cv2.erode.return_value = gray

        mock_cv2.COLOR_BGR2GRAY = 6
        mock_cv2.ADAPTIVE_THRESH_GAUSSIAN_C = 1
        mock_cv2.THRESH_BINARY_INV = 1
        mock_cv2.MORPH_RECT = 0
        mock_cv2.MORPH_OPEN = 2

        mock_tess.image_to_data.return_value = {"conf": [-1, 0, -1]}
        mock_tess.Output.DICT = "dict"

        # Act
        _, confidence = preprocess_image("low_quality.jpg")

        # Assert
        assert confidence == 0

    @patch("ocr_service.pytesseract")
    @patch("ocr_service.cv2")
    def test_confidence_calculation_correct(self, mock_cv2, mock_tess):
        """Confidence dihitung sebagai rata-rata dari conf > 0."""
        # Arrange
        mock_img = np.zeros((100, 2000, 3), dtype=np.uint8)
        mock_cv2.imread.return_value = mock_img
        gray = np.zeros((100, 2000), dtype=np.uint8)
        mock_cv2.cvtColor.return_value = gray
        mock_cv2.GaussianBlur.return_value = gray
        mock_cv2.adaptiveThreshold.return_value = gray
        mock_cv2.getStructuringElement.return_value = np.ones((1, 40), dtype=np.uint8)
        mock_cv2.morphologyEx.return_value = gray
        mock_cv2.add.return_value = gray
        mock_cv2.dilate.return_value = gray
        mock_cv2.subtract.return_value = gray
        mock_cv2.erode.return_value = gray

        mock_cv2.COLOR_BGR2GRAY = 6
        mock_cv2.ADAPTIVE_THRESH_GAUSSIAN_C = 1
        mock_cv2.THRESH_BINARY_INV = 1
        mock_cv2.MORPH_RECT = 0
        mock_cv2.MORPH_OPEN = 2

        # confs yang valid: 80, 90 → avg = 85.0
        mock_tess.image_to_data.return_value = {"conf": [80, 90, -1, 0]}
        mock_tess.Output.DICT = "dict"

        # Act
        _, confidence = preprocess_image("test.jpg")

        # Assert
        assert confidence == 85.0


# ====================================================================
# process_form_image
# ====================================================================
class TestProcessFormImage:
    """
    Tujuan: Memastikan pipeline orchestrator bekerja benar:
    1. Memanggil preprocess_image → jika confidence < 50 → gagal
    2. Memanggil run_ocr_engine
    3. Memanggil detect_form_type → jika UNKNOWN → gagal
    4. Memanggil parser yang sesuai
    5. Return structured result

    Mock: preprocess_image, run_ocr_engine, detect_form_type,
          parse_rekam_medis_card, parse_perkawinan_card, parse_data_domba_card
    """

    @patch("ocr_service.parse_rekam_medis_card")
    @patch("ocr_service.detect_form_type")
    @patch("ocr_service.run_ocr_engine")
    @patch("ocr_service.preprocess_image")
    def test_successful_rekam_medis_pipeline(self, mock_preprocess, mock_ocr, mock_detect, mock_parse):
        """Pipeline sukses: confidence OK, form dikenali (REKAM_MEDIS)."""
        # Arrange
        mock_preprocess.return_value = (np.zeros((100, 100), dtype=np.uint8), 85.0)
        mock_ocr.return_value = "Rekam Medis\nEar Tag: 001\nGejala: demam"
        mock_detect.return_value = "REKAM_MEDIS"
        mock_parse.return_value = {"ear_tag": "001", "gejala": "demam"}

        # Act
        result = process_form_image("test.jpg")

        # Assert
        assert result["success"] is True
        assert result["message"] == "OCR Berhasil"
        assert result["form_type"] == "REKAM_MEDIS"
        assert result["confidence"] == 85.0
        assert result["data"] == {"ear_tag": "001", "gejala": "demam"}
        assert "extracted_text" in result
        assert "details" in result
        mock_preprocess.assert_called_once_with("test.jpg")
        mock_parse.assert_called_once()

    @patch("ocr_service.parse_perkawinan_card")
    @patch("ocr_service.detect_form_type")
    @patch("ocr_service.run_ocr_engine")
    @patch("ocr_service.preprocess_image")
    def test_successful_perkawinan_pipeline(self, mock_preprocess, mock_ocr, mock_detect, mock_parse):
        """Pipeline sukses: form PERKAWINAN → memanggil parse_perkawinan_card."""
        # Arrange
        mock_preprocess.return_value = (np.zeros((100, 100)), 75.0)
        mock_ocr.return_value = "Perkawinan\nInduk: 001"
        mock_detect.return_value = "PERKAWINAN"
        mock_parse.return_value = {"ear_tag_induk": "001"}

        # Act
        result = process_form_image("test.jpg")

        # Assert
        assert result["success"] is True
        assert result["form_type"] == "PERKAWINAN"
        mock_parse.assert_called_once()

    @patch("ocr_service.parse_data_domba_card")
    @patch("ocr_service.detect_form_type")
    @patch("ocr_service.run_ocr_engine")
    @patch("ocr_service.preprocess_image")
    def test_successful_data_domba_pipeline(self, mock_preprocess, mock_ocr, mock_detect, mock_parse):
        """Pipeline sukses: form DATA_DOMBA → memanggil parse_data_domba_card."""
        # Arrange
        mock_preprocess.return_value = (np.zeros((100, 100)), 90.0)
        mock_ocr.return_value = "Data Domba\nEar Tag: 001"
        mock_detect.return_value = "DATA_DOMBA"
        mock_parse.return_value = {"ear_tag": "001"}

        # Act
        result = process_form_image("test.jpg")

        # Assert
        assert result["success"] is True
        assert result["form_type"] == "DATA_DOMBA"
        mock_parse.assert_called_once()

    # ---- Negative Tests ----

    @patch("ocr_service.preprocess_image")
    def test_low_confidence_fails(self, mock_preprocess):
        """Confidence < 50 → success=False, pipeline berhenti."""
        # Arrange
        mock_preprocess.return_value = (np.zeros((100, 100)), 30.0)

        # Act
        result = process_form_image("blurry.jpg")

        # Assert
        assert result["success"] is False
        assert "30" in result["message"]  # pesan berisi angka confidence
        assert result["data"] is None

    @patch("ocr_service.detect_form_type")
    @patch("ocr_service.run_ocr_engine")
    @patch("ocr_service.preprocess_image")
    def test_unknown_form_type_fails(self, mock_preprocess, mock_ocr, mock_detect):
        """Form type UNKNOWN → success=False."""
        # Arrange
        mock_preprocess.return_value = (np.zeros((100, 100)), 80.0)
        mock_ocr.return_value = "Random unrecognized text"
        mock_detect.return_value = "UNKNOWN"

        # Act
        result = process_form_image("unknown.jpg")

        # Assert
        assert result["success"] is False
        assert "tidak dikenali" in result["message"]
        assert result["data"] is None

    # ---- Boundary Value Tests ----

    @patch("ocr_service.preprocess_image")
    def test_confidence_exactly_49_fails(self, mock_preprocess):
        """Confidence = 49 (tepat di bawah threshold 50) → gagal."""
        mock_preprocess.return_value = (np.zeros((100, 100)), 49.0)
        result = process_form_image("test.jpg")
        assert result["success"] is False

    @patch("ocr_service.parse_rekam_medis_card")
    @patch("ocr_service.detect_form_type")
    @patch("ocr_service.run_ocr_engine")
    @patch("ocr_service.preprocess_image")
    def test_confidence_exactly_50_passes(self, mock_preprocess, mock_ocr, mock_detect, mock_parse):
        """Confidence = 50 (tepat di batas threshold) → lolos (karena if confidence < 50)."""
        mock_preprocess.return_value = (np.zeros((100, 100)), 50.0)
        mock_ocr.return_value = "Rekam Medis"
        mock_detect.return_value = "REKAM_MEDIS"
        mock_parse.return_value = {}

        result = process_form_image("test.jpg")
        assert result["success"] is True

    @patch("ocr_service.preprocess_image")
    def test_confidence_zero_fails(self, mock_preprocess):
        """Confidence = 0 → gagal."""
        mock_preprocess.return_value = (np.zeros((100, 100)), 0)
        result = process_form_image("empty.jpg")
        assert result["success"] is False

    # ---- Edge Case Tests ----

    @patch("ocr_service.parse_rekam_medis_card")
    @patch("ocr_service.detect_form_type")
    @patch("ocr_service.run_ocr_engine")
    @patch("ocr_service.preprocess_image")
    def test_result_contains_all_required_keys(self, mock_preprocess, mock_ocr, mock_detect, mock_parse):
        """Hasil sukses harus mengandung semua key yang diperlukan."""
        mock_preprocess.return_value = (np.zeros((100, 100)), 80.0)
        mock_ocr.return_value = "text"
        mock_detect.return_value = "REKAM_MEDIS"
        mock_parse.return_value = {"ear_tag": "001"}

        result = process_form_image("test.jpg")

        required_keys = {"success", "message", "form_type", "confidence",
                         "extracted_text", "details", "data"}
        assert required_keys.issubset(set(result.keys()))

    @patch("ocr_service.preprocess_image")
    def test_failed_result_contains_required_keys(self, mock_preprocess):
        """Hasil gagal harus mengandung success, message, data."""
        mock_preprocess.return_value = (np.zeros((100, 100)), 20.0)

        result = process_form_image("test.jpg")

        assert "success" in result
        assert "message" in result
        assert "data" in result

    @patch("ocr_service.preprocess_image")
    def test_preprocess_exception_propagates(self, mock_preprocess):
        """Exception dari preprocess_image harus propagate ke caller."""
        mock_preprocess.side_effect = ValueError("Gambar tidak ditemukan: bad.jpg")

        with pytest.raises(ValueError, match="Gambar tidak ditemukan"):
            process_form_image("bad.jpg")

    @patch("ocr_service.parse_rekam_medis_card")
    @patch("ocr_service.detect_form_type")
    @patch("ocr_service.run_ocr_engine")
    @patch("ocr_service.preprocess_image")
    def test_confidence_100_passes(self, mock_preprocess, mock_ocr, mock_detect, mock_parse):
        """Confidence = 100 (maksimum) → sukses."""
        mock_preprocess.return_value = (np.zeros((100, 100)), 100.0)
        mock_ocr.return_value = "Rekam Medis"
        mock_detect.return_value = "REKAM_MEDIS"
        mock_parse.return_value = {}

        result = process_form_image("perfect.jpg")
        assert result["success"] is True
        assert result["confidence"] == 100.0


# ====================================================================
# ModelRegistry — Penyimpanan Model & Konfigurasi via Joblib
# ====================================================================
class TestModelRegistry:
    """
    Tujuan: Memastikan ModelRegistry menyimpan dan memuat konfigurasi
    model OCR via Joblib, dengan fallback ke default config.
    """

    def setup_method(self):
        """Reset singleton sebelum tiap test."""
        ModelRegistry._instance = None

    def teardown_method(self):
        """Bersihkan singleton setelah tiap test."""
        ModelRegistry._instance = None

    def test_default_config_has_all_sections(self):
        """Config default harus memiliki semua section yang dibutuhkan."""
        registry = ModelRegistry()
        config = registry.get_config()
        assert "tesseract" in config
        assert "preprocessing" in config
        assert "nlp" in config
        assert "version" in config

    def test_get_section_tesseract(self):
        """get_config('tesseract') mengembalikan sub-dict dengan key yang benar."""
        registry = ModelRegistry()
        tess = registry.get_config("tesseract")
        assert "oem" in tess
        assert "lang" in tess
        assert "psm_primary" in tess
        assert "psm_fallback" in tess
        assert tess["lang"] == "ind"

    def test_get_section_preprocessing(self):
        """get_config('preprocessing') mengembalikan params preprocessing."""
        registry = ModelRegistry()
        prep = registry.get_config("preprocessing")
        assert "min_width" in prep
        assert "contrast_factor" in prep
        assert "sharpness_factor" in prep
        assert prep["min_width"] == 1500

    def test_get_nonexistent_section(self):
        """Section yang tidak ada mengembalikan dict kosong."""
        registry = ModelRegistry()
        assert registry.get_config("nonexistent") == {}

    def test_get_full_config(self):
        """get_config() tanpa argumen mengembalikan seluruh config."""
        registry = ModelRegistry()
        config = registry.get_config()
        assert isinstance(config, dict)
        assert "version" in config

    def test_update_config(self, tmp_path):
        """update_config mengubah nilai dan mempersist."""
        config_path = str(tmp_path / "test_config.joblib")
        registry = ModelRegistry(config_path)
        registry.update_config("tesseract", "oem", 1)
        assert registry.get_config("tesseract")["oem"] == 1

    def test_save_and_load_round_trip(self, tmp_path):
        """Config yang disimpan bisa dimuat kembali dengan benar."""
        config_path = str(tmp_path / "test_config.joblib")
        registry1 = ModelRegistry(config_path)
        registry1.update_config("tesseract", "lang", "eng")
        registry1.save()

        registry2 = ModelRegistry(config_path)
        assert registry2.get_config("tesseract")["lang"] == "eng"

    def test_save_creates_json_alongside_joblib(self, tmp_path):
        """save() membuat file .json di samping .joblib untuk human-readability."""
        config_path = str(tmp_path / "test_config.joblib")
        registry = ModelRegistry(config_path)
        registry.save()

        json_path = str(tmp_path / "test_config.json")
        assert os.path.exists(json_path)
        with open(json_path, encoding="utf-8") as f:
            data = json.load(f)
        assert data["version"] == "1.0.0"

    def test_singleton_pattern(self):
        """get_registry() mengembalikan instance yang sama (singleton)."""
        ModelRegistry._instance = None
        r1 = get_registry()
        r2 = get_registry()
        assert r1 is r2
        ModelRegistry._instance = None

    def test_corrupt_file_falls_back_to_default(self, tmp_path):
        """File joblib yang korup → fallback ke default config."""
        config_path = str(tmp_path / "corrupt.joblib")
        with open(config_path, "w") as f:
            f.write("this is not a valid joblib file")
        registry = ModelRegistry(config_path)
        assert registry.get_config("tesseract")["oem"] == 3  # default value


# ====================================================================
# validate_ocr_dataframe — Data Validation via Pandas
# ====================================================================
class TestValidateOcrDataframe:
    """
    Tujuan: Memastikan validate_ocr_dataframe membersihkan dan
    memvalidasi data hasil OCR menggunakan Pandas DataFrame.
    """

    def test_clean_data_passthrough(self):
        """Data yang sudah bersih harus lewat tanpa perubahan."""
        record = {"ear_tag": "031", "berat_badan": "15 kg", "gejala": "diare"}
        result = validate_ocr_dataframe(record, "REKAM_MEDIS")
        assert result["ear_tag"] == "031"
        assert result["berat_badan"] == "15 kg"
        assert result["gejala"] == "diare"

    def test_strip_whitespace(self):
        """Whitespace di awal/akhir value harus dibuang."""
        record = {"ear_tag": "  031  ", "gejala": " diare "}
        result = validate_ocr_dataframe(record, "REKAM_MEDIS")
        assert result["ear_tag"] == "031"
        assert result["gejala"] == "diare"

    def test_remove_noise_values(self):
        """Nilai noise-only (hanya simbol) harus menjadi None."""
        record = {"ear_tag": "031", "catatan": "---", "gejala": "~"}
        result = validate_ocr_dataframe(record, "REKAM_MEDIS")
        assert result["ear_tag"] == "031"
        assert result["catatan"] is None
        assert result["gejala"] is None

    def test_none_values_preserved(self):
        """None tetap None, tidak berubah."""
        record = {"ear_tag": None, "berat_badan": None}
        result = validate_ocr_dataframe(record, "REKAM_MEDIS")
        assert result["ear_tag"] is None
        assert result["berat_badan"] is None

    def test_ear_tag_digits_only(self):
        """Ear tag yang mengandung huruf → ambil digit saja."""
        record = {"ear_tag": "ABC031DEF"}
        result = validate_ocr_dataframe(record, "DATA_DOMBA")
        assert result["ear_tag"] == "031"

    def test_ear_tag_no_digits(self):
        """Ear tag tanpa digit sama sekali → None."""
        record = {"ear_tag": "ABC"}
        result = validate_ocr_dataframe(record, "DATA_DOMBA")
        assert result["ear_tag"] is None

    def test_date_normalization(self):
        """Tanggal dengan spasi berlebih → spasi dihapus."""
        record = {"tanggal_lahir": "12 - 01 - 2025"}
        result = validate_ocr_dataframe(record, "DATA_DOMBA")
        assert result["tanggal_lahir"] == "12-01-2025"

    def test_berat_no_digits(self):
        """Berat badan tanpa angka → None."""
        record = {"berat_badan": "berat"}
        result = validate_ocr_dataframe(record, "REKAM_MEDIS")
        assert result["berat_badan"] is None

    def test_berat_with_digits_kept(self):
        """Berat badan dengan angka + satuan → dipertahankan."""
        record = {"berat_badan": "15 kg"}
        result = validate_ocr_dataframe(record, "REKAM_MEDIS")
        assert result["berat_badan"] == "15 kg"

    def test_unicode_normalization(self):
        """Karakter unicode (en-dash, smart quotes) → dinormalisasi."""
        record = {"catatan": "demam\u2013tinggi"}
        result = validate_ocr_dataframe(record, "REKAM_MEDIS")
        assert result["catatan"] == "demam-tinggi"

    def test_empty_record(self):
        """Record kosong → dikembalikan apa adanya."""
        assert validate_ocr_dataframe({}, "REKAM_MEDIS") == {}

    def test_none_record(self):
        """None → dikembalikan None."""
        assert validate_ocr_dataframe(None, "REKAM_MEDIS") is None

    def test_empty_string_becomes_none(self):
        """String kosong atau hanya spasi → None."""
        record = {"ear_tag": "", "gejala": "  "}
        result = validate_ocr_dataframe(record, "REKAM_MEDIS")
        assert result["ear_tag"] is None
        assert result["gejala"] is None

    def test_perkawinan_ear_tag_fields(self):
        """Validasi ear_tag pada form perkawinan (induk & pejantan)."""
        record = {"ear_tag_induk": "ABC042", "ear_tag_pejantan": "XY099"}
        result = validate_ocr_dataframe(record, "PERKAWINAN")
        assert result["ear_tag_induk"] == "042"
        assert result["ear_tag_pejantan"] == "099"

    def test_tanggal_perkawinan_normalization(self):
        """Tanggal perkawinan → spasi dihapus."""
        record = {"tanggal_perkawinan": "15 / 06 / 2025"}
        result = validate_ocr_dataframe(record, "PERKAWINAN")
        assert result["tanggal_perkawinan"] == "15/06/2025"


# ====================================================================
# _normalize_unicode_chars
# ====================================================================
class TestNormalizeUnicodeChars:
    """Tests untuk fungsi helper normalisasi karakter unicode."""

    def test_en_dash(self):
        assert _normalize_unicode_chars("a\u2013b") == "a-b"

    def test_em_dash(self):
        assert _normalize_unicode_chars("a\u2014b") == "a-b"

    def test_smart_quotes(self):
        assert _normalize_unicode_chars("\u2018hello\u2019") == "'hello'"
        assert _normalize_unicode_chars("\u201chello\u201d") == '"hello"'

    def test_ellipsis(self):
        assert _normalize_unicode_chars("wait\u2026") == "wait..."

    def test_nbsp(self):
        assert _normalize_unicode_chars("hello\u00a0world") == "hello world"

    def test_none_passthrough(self):
        assert _normalize_unicode_chars(None) is None

    def test_int_passthrough(self):
        assert _normalize_unicode_chars(123) == 123

    def test_no_unicode(self):
        assert _normalize_unicode_chars("hello world") == "hello world"
