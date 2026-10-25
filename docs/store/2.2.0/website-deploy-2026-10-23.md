# Atomic Orbital privacy/support deployment — 23 October 2026

The two reviewed pages are published on the existing Netlify production site:

- Privacy policy: https://marvinmaerz.com/atomic-orbital/privacy/
- Support: https://marvinmaerz.com/atomic-orbital/support/

Both returned HTTPS 200 at **2026-10-23 04:33 UTC**. The full article text matches the committed Astro source, and both pages contain their crosslinks and the existing public support email. Responses identify Netlify as the server. Saved response HTML, hashes, response headers and checks are in [verification.json](evidence/website-deploy-2026-10-23/verification.json).

Website repository: `Numoy/marvinmaerz`, branch `main`.

Commit: **972b09b5e339ec55051fed21db1d2ac5597162fb** — `Add Atomic Orbital privacy and support pages`.

The fetch confirmed local main matched origin before committing. The commit was created with the existing SSH/1Password signing configuration enabled; its commit object contains an SSH signature. Push to origin/main succeeded and triggered the already-configured production Git deployment. No signing setting was disabled or changed.

Only these files are in the commit:

- `src/pages/atomic-orbital/privacy.astro`
- `src/pages/atomic-orbital/support.astro`

The generic `src/pages/data-protection.astro` remained byte-identical. Pre-existing untracked `.playwright-mcp/` files were preserved. After pushing, local main and origin/main were synchronized, with no tracked changes remaining in the website checkout.

The prior portfolio build and desktop/mobile rendering checks passed before this deployment; no page content drift occurred before commit. This step did not publish stores, alter app/gameplay code, create credentials, or change unrelated website pages.
