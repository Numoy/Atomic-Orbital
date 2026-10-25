# Atomic Orbital 2.2.0 — prepared store material

- `listings.json`: reusable en-US/de-DE Google Play and App Store copy.
- `validate_copy.py`: checks all localized field limits (`python3 docs/store/2.2.0/validate_copy.py`).
- `content-privacy-audit.md`: source-based content/privacy declarations, evidence, current URL status and remaining decisions.
- `privacy-policy.en.md`, `support.en.md`: reviewed app-specific page text.
- `evidence/`: local desktop/mobile rendered-page checks and screenshots.

Actual website pages are prepared in `/Users/maerz/Projects/marvinmaerz/src/pages/atomic-orbital/privacy.astro` and `support.astro`. They reuse the current Layout, are statically prerendered, and crosslink. The generic policy and unrelated pages are unchanged. The portfolio build passes. Local preview: `http://127.0.0.1:4392/atomic-orbital/privacy/` and `/support/` while the task server runs.

Both app-specific pages are now published and verified HTTPS 200 on 2026-10-23: [Privacy](https://marvinmaerz.com/atomic-orbital/privacy/) and [Support](https://marvinmaerz.com/atomic-orbital/support/). Full article text matches the signed commit. See [deployment record](website-deploy-2026-10-23.md) for commit and response evidence. These verified URLs are ready for store metadata.

The existing Netlify production site serving `marvinmaerz.com` auto-publishes GitHub `Numoy/marvinmaerz` main. Signed commit `972b09b5e339ec55051fed21db1d2ac5597162fb` contains only the two app-specific pages and was pushed to main. The generic policy and unrelated files were preserved. No store submission or external message was performed by this website step.
