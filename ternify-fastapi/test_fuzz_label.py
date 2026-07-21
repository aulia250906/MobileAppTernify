
from rapidfuzz import process, fuzz

def test_labels():
    field_key_map = {
        "ear tag": "ear_tag",
        "jenis kelamin": "jenis_kelamin",
        "tanggal lahir": "tanggal_lahir",
        "jenis domba": "jenis_domba",
        "induk (ear tag)": "ear_tag_induk",
        "jantan (ear tag)": "ear_tag_jantan"
    }
    
    test_cases = [
        "Eer Taq", "Ear Toq", "Id Domba",
        "Jenis KeIamin", "Jems Kclamn",
        "Tonggal Lahlr", "Tgl Lh1r",
        "Jenls Dombe", "Jns Dmba",
        "lnduk (Eer Tag)", "lnduk",
        "Jentqn (Ear Tag)", "Jntn"
    ]
    
    for raw in test_cases:
        match = process.extractOne(raw.lower(), list(field_key_map.keys()), scorer=fuzz.ratio)
        if match and match[1] >= 60:
            print(f"[MATCH] {raw} -> {field_key_map[match[0]]} (score: {match[1]:.1f})")
        else:
            print(f"[FAIL] {raw} -> best was {match} (score too low)")

test_labels()

