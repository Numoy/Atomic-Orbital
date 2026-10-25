# Atomic Orbital data deletion page — 23 October 2026

Published URL for Google Play's optional data-deletion field:

https://marvinmaerz.com/atomic-orbital/delete-data/

The deletion page, privacy policy and support page all returned HTTPS 200 at **2026-10-23 18:03 UTC**. Each full article and its links matched the local production build. Privacy and support now link to the deletion page from their Atomic Orbital navigation.

Website repository: `Numoy/marvinmaerz`, branch `main`.

Signed commit: **7b9f61da1bfca5afe1e9563acdab9372e56341a6** — `Add Atomic Orbital data deletion instructions`.

Only these files are in the commit:

- `src/pages/atomic-orbital/delete-data.astro` (new)
- `src/pages/atomic-orbital/privacy.astro` (one navigation link)
- `src/pages/atomic-orbital/support.astro` (one navigation link)

The existing SSH/1Password signing configuration remained enabled. The commit contains an SSH signature. Push to the existing origin/main succeeded and triggered the existing Netlify production deployment. Main and origin/main are synchronized. The pre-existing untracked `.playwright-mcp/` directory was preserved; no other website files changed.

The page instructs users to clear local records and queued uploads first, including other device copies, before deleting Atomic Orbital's Google Play Games data. It explains irreversible local progress loss, possible backup restoration/re-upload, the difference between disconnecting and deleting, the absence of a developer-operated game account/backend, Google's separate Play History controls and provider-controlled retention. It also distinguishes iPhone/iPad local data and offloading from app deletion. Privacy questions use the existing public contact, with no passwords or authentication codes requested.

Google's current [individual-game deletion guidance](https://support.google.com/googleplay/answer/9130646?hl=en) was checked on 23 October 2026. It now documents the web Play Games profile and Play Store profile-settings routes. The page uses those current paths and links to the source rather than relying on the older standalone Play Games app path. Google-held retention is linked to [Google's retention policy](https://policies.google.com/technologies/retention?hl=en), with no app-invented deletion deadline.

Validation:

- `npm run build` passed with the existing Astro/Netlify setup.
- Headless installed Google Chrome rendered the production static build at widths 320, 390 and 1440 pixels; no horizontal/article overflow or page script errors were detected. The 390-pixel screenshot was visually reviewed.
- Privacy/support deletion links were checked at 320 pixels without overflow.
- Live HTTPS responses, full article/link comparisons, source/response hashes and response headers are in [verification.json](evidence/website-delete-data-2026-10-23/verification.json). Local checks and screenshots are in the same evidence directory.

This deployment changed documentation only. It did not delete any user's data, exercise the destructive platform controls, mutate store forms or change app/gameplay code.
