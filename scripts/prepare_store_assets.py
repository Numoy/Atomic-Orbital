#!/usr/bin/env python3
"""Package current Flutter store exports as opaque RGB PNGs, without resizing."""

import argparse
import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--directory", default="store-assets/2026-10-22")
parser.add_argument("--localized", action="store_true")
args = parser.parse_args()
OUTPUT = ROOT / args.directory
EXPECTED = {
    "google-play-phone": (1080, 1920),
    "google-play-tablet": (1920, 1080),
    "app-store-iphone-medium": (1179, 2556),
    "app-store-iphone-large": (1320, 2868),
    "app-store-ipad-13": (2732, 2048),
}
SCENES = ["01-normal", "02-hardcore", "03-progress" if args.localized else "03-normal-later", "04-menu", "05-results"]
TARGETS = {f"{locale}/{target}": dimensions for locale in ["en", "de"] for target, dimensions in EXPECTED.items()} if args.localized else EXPECTED


def opaque(source: Path, destination: Path, size: tuple[int, int]) -> dict:
    with Image.open(source) as original:
        assert original.size == size, (source, original.size, size)
        rgba = original.convert("RGBA")
        assert rgba.getchannel("A").getextrema() == (255, 255), source
        rgb = rgba.convert("RGB")
        destination.parent.mkdir(parents=True, exist_ok=True)
        rgb.save(destination, optimize=True)
        with Image.open(destination) as saved:
            assert saved.mode == "RGB" and saved.size == size
            assert saved.tobytes() == rgb.tobytes(), destination
    return {
        "file": str(destination.relative_to(OUTPUT)),
        "width": size[0],
        "height": size[1],
        "mode": "RGB",
        "bytes": destination.stat().st_size,
        "sha256": hashlib.sha256(destination.read_bytes()).hexdigest(),
    }


def main() -> None:
    manifest = []
    for target, dimensions in TARGETS.items():
        for scene in SCENES:
            manifest.append(opaque(
                OUTPUT / f"raw/{target}/{scene}.png",
                OUTPUT / f"screenshots/{target}/{scene}.png",
                dimensions,
            ))
    manifest.append(opaque(
        OUTPUT / "raw/feature-1024x500.png",
        OUTPUT / "graphics/feature-1024x500.png", (1024, 500),
    ))

    # Preserve the original launcher artwork and its original blue background.
    source = ROOT / "app/src/main/res/launcher_web.png"
    with Image.open(source) as original:
        assert original.size == (512, 512)
        icon = Image.new("RGBA", original.size, (43, 121, 193, 255))
        icon.alpha_composite(original.convert("RGBA"))
        icon_path = OUTPUT / "raw/icon-512x512.png"
        icon.save(icon_path)
    manifest.append(opaque(icon_path, OUTPUT / "graphics/icon-512x512.png", (512, 512)))

    (OUTPUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    # A review sheet only: upload the full-size PNGs, never this montage.
    sheet = Image.new("RGB", (1500, len(TARGETS) * 370), (20, 26, 36))
    draw = ImageDraw.Draw(sheet)
    for row, target in enumerate(TARGETS):
        for column, scene in enumerate(SCENES):
            with Image.open(OUTPUT / f"screenshots/{target}/{scene}.png") as image:
                image.thumbnail((282, 330), Image.Resampling.LANCZOS)
                sheet.paste(image, (column * 300 + (300 - image.width) // 2, row * 370 + 28))
            draw.text((column * 300 + 8, row * 370 + 8), f"{target}: {scene}", fill="white")
    sheet.save(OUTPUT / "review-contact-sheet.jpg", quality=90)
    shutil.rmtree(OUTPUT / "raw")
    print(f"Validated {len(manifest)} opaque RGB store images in {OUTPUT}")


if __name__ == "__main__":
    main()
