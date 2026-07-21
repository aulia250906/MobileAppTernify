
from ocr_service import parse_rekam_medis_card, parse_data_domba_card, parse_perkawinan_card

print("=== Test 1: Rekam Medis without colon ===")
raw_text = "Ear Tag 022\nBerat badan 3 kg\nStatus Kondisl Susah makan\nTindakan pemberian obat\nDosis 5 ml"
res = parse_rekam_medis_card(raw_text)
print(res)

print("\n=== Test 2: Data Domba without colon ===")
raw_text = "Ear Tag 001\nJenis Kelamin Betina\nTanggal Lahir 20 - 05 - 2026\nJenis Domba Domba Garut\nInduk (Ear Tag) 021\nJantan (Ear Tag) 031"
res = parse_data_domba_card(raw_text)
print(res)

