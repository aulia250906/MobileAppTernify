
import re

def test_match(patterns, texts):
    for text in texts:
        matched = False
        for pattern in patterns:
            if re.search(pattern, text, re.IGNORECASE):
                print(f"[OK] {text} matched {pattern}")
                matched = True
                break
        if not matched:
            print(f"[FAIL] {text} did not match anything")

print("Rekam Medis:")
patterns_rm = [
    r"ear|tag|domba|id",
    r"berat|bobot",
    r"gejala|keluhan|symptom",
    r"diagnosa|diagnosis",
    r"tindakan|treatment|penanganan",
    r"dosis|obat",
    r"status|kondisi",
    r"catatan|note",
]
test_match(patterns_rm, ["Eer Taq", "Beret badan", "Stotus Kandisi", "Tindakcn", "Dos1s", "Status Kandisi"])

print("\nData Domba:")
patterns_dd = [
    r"induk|1nduk|lnduk",
    r"jantan|pejantan|jntan",
    r"ear|tag|id",
    r"kelamin|kelamn|jenis.?k",
    r"lahir|lhr|tanggal.?l|tgl.?l",
    r"domba|ras|breed|jenis.?d",
]
test_match(patterns_dd, ["lnduk (Eer Tag)", "Jentqn (Ear Tag)", "Jenis KeIamin", "Tonggal Lahlr", "Jenls Dombe"])

