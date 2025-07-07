import random
import string

NUM_CODES = 100
PREFIX = "SMOOTH"
DESCRIPTION = "Réduction 10%"
DISCOUNT_PERCENT = 10
MAX_USES = 1

all_suffixes = [a + b for a in string.ascii_uppercase + string.digits for b in string.ascii_uppercase + string.digits]
random.shuffle(all_suffixes)

codes = set()
for suffix in all_suffixes:
    if len(codes) >= NUM_CODES:
        break
    code = f"{PREFIX}{suffix}"
    codes.add(code)

print("INSERT INTO promo_codes (code, description, is_active, max_uses, discount_percent) VALUES")
for i, code in enumerate(codes):
    end = "," if i < NUM_CODES - 1 else ";"
    print(f"  ('{code}', '{DESCRIPTION}', true, {MAX_USES}, {DISCOUNT_PERCENT}){end}") 