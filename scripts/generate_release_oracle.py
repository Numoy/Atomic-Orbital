#!/usr/bin/env python3
"""Compile release 41's Java controllers and Play Games completion rules.

Usage: python3 scripts/generate_release_oracle.py 41.apk /path/to/jadx
Only Android/view dependencies are stubbed; controller/model code is unmodified.
"""

import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET


APK_SHA256 = "de2eab0ee467a81a4f3cdb7da1955cd5c3784630836c113861bf14ca859d9824"
ROOT = Path(__file__).resolve().parent.parent
PACKAGE = "de.numpy.orbital.orbital4"
SOURCE_FILES = [
    "constants/Constants.java",
    "gameobjects/GameObject.java",
    "gameobjects/player/Player.java",
    "gameobjects/player/PlayerController.java",
    "gameobjects/photon/PhotonModel.java",
    "gameobjects/photon/PhotonFactory.java",
    "gameobjects/photon/PhotonUtils.java",
    "gameobjects/photon/PhotonController.java",
    "gameobjects/photon/TrajectoryType.java",
    "orbit/Orbit.java",
    "orbit/OrbitController.java",
    "hitpoints/Hitpoints.java",
    "hitpoints/HitpointsController.java",
]

STUBS = {
    "android/util/Size.java": """package android.util;
public class Size {
  private final int width, height;
  public Size(int width, int height) { this.width = width; this.height = height; }
  public int getWidth() { return width; }
  public int getHeight() { return height; }
}""",
    "android/graphics/Canvas.java": "package android.graphics; public class Canvas {}",
    "android/content/Context.java": """package android.content;
public class Context {
  public android.content.res.Resources getResources() {
    return new android.content.res.Resources();
  }
}""",
    "android/content/res/Resources.java": """package android.content.res;
public class Resources { public int getColor(int color) { return color; } }""",
    "de/numpy/orbital/orbital4/R.java": """package de.numpy.orbital.orbital4;
public class R { public static class color { public static int red = 1, green = 2; } }""",
    "de/numpy/orbital/orbital4/mainmenu/MenuActivity.java": """package de.numpy.orbital.orbital4.mainmenu;
public class MenuActivity { public static boolean hardcore_mode; }""",
    "de/numpy/orbital/orbital4/userinput/UserInput.java": """package de.numpy.orbital.orbital4.userinput;
public class UserInput { public boolean touchDown; }""",
}


def games_fixture(work):
    source = work / "jadx/sources/de/numpy/orbital/orbital4/gameobjects/GameObjects.java"
    source_text = source.read_text()
    names = ["setHighscore", "checkGamesPlayed", "checkNormalGamesPlayed", "checkHardcoreGamesPlayed", "checkTotalPoints"]
    methods = []
    for name in names:
        start = re.search(r"    (public|private) void " + name + r"\(", source_text).start()
        opening = source_text.index("{", start)
        depth = 1
        end = opening + 1
        while depth:
            if source_text[end] == "{":
                depth += 1
            elif source_text[end] == "}":
                depth -= 1
            end += 1
        methods.append(source_text[start:end])
    method_text = "\n".join(methods)
    strings_path = work / "jadx/resources/res/values/strings.xml"
    strings = {item.attrib["name"]: item.text for item in ET.parse(strings_path).getroot().findall("string")}
    resources = (work / "jadx/sources/de/numpy/orbital/orbital4/R.java").read_text()
    resource_names = sorted(set(re.findall(r"R\.string\.(\w+)", method_text)))
    definitions, lookups = [], []
    for name in resource_names:
        value = re.search(r"public static final int " + name + r" = (0x[0-9a-f]+);", resources).group(1)
        definitions.append(f"static final int {name} = {value};")
        lookups.append(f"case {value}: return {json.dumps(strings[name])};")
    resource_code = (
        "static class R { static class string {" + "".join(definitions) + "}}\n"
        "static class ResourceStrings { String getString(int id) { switch(id) {" +
        "".join(lookups) + "default: throw new IllegalArgumentException(); }}}"
    )
    template = (ROOT / "scripts/release_oracle/ReleaseGamesOracle.java").read_text()
    generated = template.replace("// ORIGINAL_RESOURCE_IDS", resource_code).replace("// ORIGINAL_RULE_METHODS", method_text)
    java_file = work / "ReleaseGamesOracle.java"
    java_file.write_text(generated)
    subprocess.run(["javac", "-d", str(work / "classes"), str(java_file)], check=True)
    fixture = json.loads(subprocess.check_output(["java", "-cp", str(work / "classes"), "ReleaseGamesOracle"], text=True))
    fixture["provenance"] = {
        "apkSha256": APK_SHA256,
        "sourceSha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "stringsSha256": hashlib.sha256(strings_path.read_bytes()).hexdigest(),
        "scope": "Unmodified game-completion rule methods, signed-in logical request order; SDK/UI delivery is not executed.",
        "approvedCorrections": {
            "gamesPlayedLeaderboard": strings["games_played_leaderboard"],
            "gamesPlayedCount": "Submit the completed count; the original submitted the previous count to its preference-key string.",
        },
    }
    destination = ROOT / "test/oracle/release_41_play_games.json"
    destination.write_text(json.dumps(fixture, indent=2) + "\n")
    print(f"Generated {destination}")


def generate(apk, jadx):
    if hashlib.sha256(apk.read_bytes()).hexdigest() != APK_SHA256:
        raise ValueError("Expected the Google Play release 41 APK; SHA-256 differs")
    with tempfile.TemporaryDirectory(prefix="atomic-release-oracle-") as temporary:
        work = Path(temporary)
        # JADX may report errors in bundled Play Services; javac below checks
        # that every controller used by this oracle decompiled successfully.
        result = subprocess.run(
            [str(jadx), "--log-level", "error", "-d", str(work / "jadx"), str(apk)],
            capture_output=True, text=True,
        )
        sources = work / "src"
        package_path = Path(*PACKAGE.split("."))
        hashes = {}
        for relative in SOURCE_FILES:
            original = work / "jadx/sources" / package_path / relative
            if not original.is_file():
                raise RuntimeError(f"JADX did not produce {relative}: {result.stderr}")
            text = original.read_text()
            if "throw new UnsupportedOperationException" in text:
                raise RuntimeError(f"JADX could not recover {relative}")
            hashes[relative] = hashlib.sha256(original.read_bytes()).hexdigest()
            destination = sources / package_path / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(original, destination)
        for name, text in STUBS.items():
            path = sources / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text + "\n")
        for package, name, parameters in [
            ("gameobjects/player", "PlayerView", "android.util.Size size"),
            ("gameobjects/photon", "PhotonView", ""),
            ("orbit", "OrbitView", "android.util.Size size"),
            ("hitpoints", "HitpointsView", "Hitpoints hitpoints"),
        ]:
            path = sources / package_path / package / (name + ".java")
            path.write_text(
                f"package {PACKAGE}.{package.replace('/', '.')};\n"
                f"public class {name} {{\n"
                f"  public {name}({parameters}) {{}}\n"
                "  public void draw(android.graphics.Canvas canvas, Object... ignored) {}\n"
                "}\n"
            )
        shutil.copyfile(ROOT / "scripts/release_oracle/ReleaseOracle.java", sources / "ReleaseOracle.java")
        classes = work / "classes"
        classes.mkdir()
        subprocess.run(["javac", "-d", str(classes), *map(str, sorted(sources.rglob("*.java")))], check=True)
        output = subprocess.check_output(["java", "-ea", "-cp", str(classes), "ReleaseOracle"], text=True)
        fixture = json.loads(output)
        fixture["provenance"] = {
            "applicationId": PACKAGE,
            "versionName": "2.1.6",
            "versionCode": 41,
            "apkSha256": APK_SHA256,
            "jadxVersion": subprocess.check_output([str(jadx), "--version"], text=True).strip(),
            "sourceSha256": hashes,
            "scope": "Per-update controller states; no rendering, wall-clock pacing, audio or seeded wave positions.",
        }
        destination = ROOT / "test/oracle/release_41.json"
        destination.write_text(json.dumps(fixture, indent=2) + "\n")
        print(f"Generated {destination}")
        games_fixture(work)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    generate(Path(sys.argv[1]).resolve(strict=True), Path(sys.argv[2]).resolve(strict=True))
