"""Check prepared store metadata against the published field limits."""
import json
from pathlib import Path

copy = json.loads(Path(__file__).with_name('listings.json').read_text())
limits = {
    'google_play': {'name': 30, 'short_description': 80,
                    'full_description': 4000, 'release_notes': 500},
    'app_store': {'name': 30, 'subtitle': 30, 'promotional_text': 170,
                  'description': 4000, 'keywords': 100, 'whats_new': 4000},
}
for store, fields in limits.items():
    for locale, listing in copy[store].items():
        for field, limit in fields.items():
            text = listing[field]
            size = len(text.encode('utf-8')) if field == 'keywords' else len(text)
            assert text.strip() and size <= limit, (store, locale, field, size, limit)
print('All 20 localized store fields fit their limits.')
