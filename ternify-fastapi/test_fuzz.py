
from rapidfuzz import process, fuzz
kb = ["susah makan", "sehat", "lemas", "kritis"]
print(process.extractOne("Kondisl Susah makan", kb, scorer=fuzz.ratio))
print(process.extractOne("Kondisl Susah makan", kb, scorer=fuzz.token_sort_ratio))

