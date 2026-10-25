# World and character artwork — 2026-10-24

The user clarified that world artwork and characters were the priority. This pass changes shared artwork without further shop or menu layout changes.

- Earth now uses recognizable continental silhouettes, replacing the rounded placeholder land shapes. A single cached Canvas path holds simplified coastlines projected onto the visible hemisphere. Ocean, land and clouds retain the same lighting.
- A visible alien pilot gives the UFO a character and focal point. Broad eyes remain visible at the phone-sized player radius; the hull's small decorative lights are simplified.
- The cow has a broader muzzle, shorter neck, sideways ears and staggered near/far legs. Its spots, belly and head form a stronger side silhouette.
- The submarine has a stern propeller and stabilizer, replacing the fish-like triangular tail.

The coastline is derived from [Natural Earth's land dataset](https://github.com/nvkelso/natural-earth-vector/blob/693f11422f4e08d2da4566b854dda53eb7c39fb3/geojson/ne_110m_land.geojson), which its [terms identify as public domain](https://www.naturalearthdata.com/about/terms-of-use/). The [source record](design/character-art-2026-10-24/earth-source.json) pins the revision, hash, projection and simplification parameters. The game contains eight projected polygons and 244 vertices; no runtime geography loading, projection or network request is introduced.

Classic rendering, wallet data/IDs/prices, ownership, physics, collision bounds, timing and competitive rules are unchanged. All artwork remains bounded by the existing radii, and the core remains opaque over emerging hazards.

## Verification

- All **252 tests pass**. New image checks cover Africa, South America and Atlantic placement plus two visible alien eyes at phone gameplay size. Existing tests cover entity bounds, opaque core, globe lighting, seeded simulation equality, Classic parity, HUD, wallets and shop interactions.
- `flutter analyze`, formatting and `git diff --check` pass.
- Nineteen menu/shop evidence tests and the three artwork-sheet exports pass. Actual source painters produce both enlarged and phone-sized parts for direct art review.
- Android comparison profile and iOS debug simulator builds pass. Neither build is installed or published during this pass; physical-phone readability and sustained frame pacing remain unverified.

Inspected current artwork:

- [Cow Abduction characters](evidence/character-art-2026-10-24/cow_abduction-characters.png) and [Deep Blue characters](evidence/character-art-2026-10-24/deep_blue-characters.png).
- [Cow shop](evidence/character-art-2026-10-24/shop-phone.png), [Deep Blue shop](evidence/character-art-2026-10-24/deep_blue-shop-phone.png), and [Cow gameplay](evidence/character-art-2026-10-24/cow_abduction-gameplay-phone.png).

UI captures use mock preferences and fixture positions/scores; they do not change a real wallet or submit scores. The source remains offline and synchronous; no raster assets, loading/retry screens or new dependencies are added.
