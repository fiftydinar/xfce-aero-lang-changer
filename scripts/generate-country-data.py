#!/usr/bin/env python3
"""Regenerate data/country_names.json from CLDR territory data.

Sources (in priority order, later overrides earlier):
  1. Existing data/country_names.json baseline (preserves languages not in CLDR)
  2. CLDR JSON release (unicode-org/cldr-json) territory names
  3. Manual overrides (highest priority, fixes CLDR fallbacks like Tatar→Russian)

New CLDR languages are automatically added alongside existing ones.

Usage:
  # From repo root:
  python3 scripts/generate-country-data.py
"""

import json
import os
import re
import shutil
import sys
import tempfile
import urllib.request
import zipfile

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(REPO_ROOT, "data")
OUTPUT = os.path.join(DATA_DIR, "country_names.json")

# GitHub API / download helpers
GH_API = "https://api.github.com/repos/unicode-org/cldr-json/releases/latest"
GH_DL = "https://github.com/unicode-org/cldr-json/releases/download"

# Inherit GITHUB_TOKEN from the environment (set by GitHub Actions)
# to avoid unauthenticated rate limits (60/hr vs 5000/hr).
_GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN") or ""


def _github_request(url: str, *, data: bytes | None = None, timeout: int = 30) -> urllib.request.Request:
    """Create an HTTP request with optional GitHub token auth."""
    headers = {"User-Agent": "xfce-aero-lang-changer"}
    if _GITHUB_TOKEN:
        headers["Authorization"] = f"Bearer {_GITHUB_TOKEN}"
    return urllib.request.Request(url, data=data, headers=headers)

# Manual overrides for CLDR fallback cases. Highest priority.
MANUAL_OVERRIDES: dict[str, dict[str, str]] = {
    "crh": {"RU": "Русие Федерациясы", "UA": "Ukraina"},
    "kv": {"RU": "Россия"},
    "mhr": {"RU": "Россий"},
    "niu": {"NU": "Niuē", "NZ": "Niu Silani"},
    "quz": {"PE": "Piruw"},
    "shs": {"CA": "Kanata"},
    # tt/RU: CLDR falls back to Russian "Россия", system locale has correct Tatar "Русия"
    "tt": {"RU": "Русия"},
}

# CLDR locale code to our @modifier suffix mapping.
# CLDR uses BCP47-style tags; we use lang@modifier convention.
SCRIPT_VARIANT_MAP: dict[str, str] = {
    "sr-Latn": "sr@latin",
    "sr-Cyrl": "sr",
    "uz-Cyrl": "uz@cyrillic",
    "uz-Latn": "uz",
    "az-Cyrl": "az@cyrillic",
    "az-Latn": "az",
    "bs-Cyrl": "bs@cyrillic",
    "bs-Latn": "bs",
    "ms-Arab": "ms@arabic",
    "ms-Latn": "ms",
    "kk-Arab": "kk@arabic",
    "kk-Cyrl": "kk",
    "ky-Arab": "ky@arabic",
    "ky-Cyrl": "ky",
    "tg-Cyrl": "tg",
    "tg-Persn": "tg@persian",
    "tt-Cyrl": "tt",
    "tt-Latn": "tt@iqtelif",
    "sah-Cyrl": "sah",
    "sah-Latn": "sah@latin",
    "tk-Cyrl": "tk@cyrillic",
    "tk-Latn": "tk",
    "ug-Arab": "ug",
    "ug-Cyrl": "ug@cyrillic",
    "ug-Latn": "ug@latin",
}

# Locales to exclude when parsing CLDR data.
SKIP_LOCALES = {"root", "und", "zxx"}


def log(msg: str) -> None:
    print(f"  [{os.path.basename(sys.argv[0])}] {msg}", flush=True)


def fetch_latest_cldr_version() -> str:
    """Determine latest CLDR release tag from GitHub API."""
    log("Fetching latest CLDR version from GitHub API...")
    try:
        req = _github_request(GH_API, timeout=30)
        req.add_header("Accept", "application/json")
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode())
            tag = data["tag_name"]
            log(f"Latest CLDR version: {tag}")
            return tag
    except Exception as e:
        log(f"Warning: could not fetch latest version ({e}), falling back to 48.2.0")
        return "48.2.0"


def download_cldr_zip(version: str, dest: str) -> str:
    """Download and extract CLDR JSON full zip. Returns the path to extracted dir."""
    zip_name = f"cldr-{version}-json-full.zip"
    url = f"{GH_DL}/{version}/{zip_name}"
    zip_path = os.path.join(dest, zip_name)
    extract_dir = os.path.join(dest, f"cldr-{version}")

    if os.path.exists(extract_dir):
        log(f"Already extracted: {extract_dir}")
        return extract_dir

    log(f"Downloading {url}...")
    try:
        req = _github_request(url, timeout=120)
        with urllib.request.urlopen(req, timeout=120) as resp:
            with open(zip_path, "wb") as f:
                f.write(resp.read())
    except Exception as e:
        log(f"Error downloading: {e}")
        sys.exit(1)

    log(f"Extracting {zip_path}...")
    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(extract_dir)

    # Find cldr-localenames-full first (has the territory data we need)
    entries = os.listdir(extract_dir)
    if "cldr-localenames-full" in entries:
        return os.path.join(extract_dir, "cldr-localenames-full")
    # Fallback: any cldr-* dir that has main/
    for entry in entries:
        if entry.startswith("cldr-") and os.path.isdir(os.path.join(extract_dir, entry, "main")):
            return os.path.join(extract_dir, entry)

    return extract_dir


def parse_cldr_territories(base_dir: str) -> dict[str, dict[str, str]]:
    """Parse CLDR territory data from extracted JSON files.

    base_dir should be the extracted cldr-localenames-full directory
    (or a parent containing a 'main/' subdir).

    Returns a dict mapping our lang codes (e.g. "sr", "sr@latin") to
    {territory_code: localized_name}.
    """
    result: dict[str, dict[str, str]] = {}
    main_dir = os.path.join(base_dir, "main")
    if not os.path.isdir(main_dir):
        for root, dirs, files in os.walk(base_dir):
            if "territories.json" in files and root.endswith("/main"):
                main_dir = root
                break
        else:
            log(f"Error: could not find main/ directory with territories.json in {base_dir}")
            sys.exit(1)

    for locale_id in sorted(os.listdir(main_dir)):
        locale_dir = os.path.join(main_dir, locale_id)
        if not os.path.isdir(locale_dir):
            continue
        if locale_id in SKIP_LOCALES:
            continue

        territories_file = os.path.join(locale_dir, "territories.json")
        if not os.path.isfile(territories_file):
            continue

        try:
            with open(territories_file, encoding="utf-8") as f:
                data = json.load(f)
        except (json.JSONDecodeError, UnicodeDecodeError):
            continue

        # Navigate: main -> {localeId} -> localeDisplayNames -> territories
        main_block = data.get("main", {})
        # The locale key in CLDR may differ from the directory name
        # (e.g. dir "af" has key "af" inside, but some variant locales
        # might have normalized keys). Try the exact locale_id first,
        # then fall back to the first key in main_block.
        loc_block = main_block.get(locale_id)
        if loc_block is None:
            # Fallback: use the first (and typically only) key
            for k in main_block:
                loc_block = main_block[k]
                break
            if loc_block is None:
                continue
        ldn = loc_block.get("localeDisplayNames", {})
        territories = ldn.get("territories", {})
        if not territories:
            continue

        # Map CLDR locale code to our @modifier convention
        lang_code = map_locale_code(locale_id)
        if lang_code is None:
            continue

        # Keep all territory codes, including alt-variant and alt-short variants
        filtered: dict[str, str] = {}
        for code, name in territories.items():
            if isinstance(name, str):
                filtered[code] = name

        if filtered:
            if lang_code in result:
                result[lang_code].update(filtered)
            else:
                result[lang_code] = filtered

    return result


def map_locale_code(locale_id: str) -> str | None:
    """Map a CLDR BCP47 locale ID to our lang@modifier convention."""
    # Check explicit script variants first
    if locale_id in SCRIPT_VARIANT_MAP:
        return SCRIPT_VARIANT_MAP[locale_id]

    # Handle ca-ES-VALENCIA -> ca@valencia
    if re.match(r"^[a-z]{2,3}-[A-Z]{2}-VALENCIA$", locale_id):
        base = locale_id.split("-")[0]
        return f"{base}@valencia"

    # Generic pattern: lang[-Region] (without script component)
    m = re.match(r"^([a-z]{2,3})(?:-[A-Z]{2})?$", locale_id)
    if m:
        return m.group(1)

    # If locale has a script variant not in SCRIPT_VARIANT_MAP, add it as @script
    m = re.match(r"^([a-z]{2,3})-([A-Z][a-z]{3})(?:-[A-Z]{2})?$", locale_id)
    if m:
        base = m.group(1)
        script = m.group(2).lower()
        return f"{base}@{script}"

    return None


def main() -> None:
    os.makedirs(DATA_DIR, exist_ok=True)

    # 1. Load existing data as the baseline, so we preserve languages not in CLDR
    existing: dict[str, dict[str, str]] = {}
    if os.path.isfile(OUTPUT):
        with open(OUTPUT, encoding="utf-8") as f:
            existing = json.load(f)
        log(f"Loaded existing data: {len(existing)} languages")

    with tempfile.TemporaryDirectory(prefix="cldr-") as tmpdir:
        # 2. Fetch CLDR data
        version = fetch_latest_cldr_version()
        cldr_dir = download_cldr_zip(version, tmpdir)

        # 3. Parse CLDR territory data
        log("Parsing CLDR territory data...")
        cldr = parse_cldr_territories(cldr_dir)
        log(f"  CLDR data: {len(cldr)} languages")

        # 4. Build result: start with existing data, then overlay CLDR updates.
        #    For languages already in the file, replace all entries with CLDR data.
        #    Existing languages NOT in CLDR (e.g. tt@iqtelif not in CLDR 48) keep
        #    their original entries. New CLDR languages are added automatically.
        data = dict(existing)

        cldr_updated = 0
        cldr_added = 0
        for lang, territories in sorted(cldr.items()):
            if lang in data:
                if data[lang] != territories:
                    cldr_updated += 1
                data[lang] = territories
            else:
                data[lang] = territories
                cldr_added += 1

        if cldr_updated:
            log(f"  CLDR updates applied to: {cldr_updated} languages")
        if cldr_added:
            log(f"  New CLDR languages added: {cldr_added}")

    # 5. Apply manual overrides (highest priority).
    #    These fix cases where CLDR falls back to a parent language
    #    (e.g. Tatar → Russian).
    for lang, territories in MANUAL_OVERRIDES.items():
        if lang in data:
            data[lang].update(territories)
        else:
            data[lang] = territories
        log(f"  Manual override applied to: {lang}")

    # 6. Write output preserving existing key order so diffs show real changes.
    output_data: dict[str, dict[str, str]] = {}
    for lang in existing:
        if lang in data:
            # Preserve original territory code order for existing languages;
            # append new codes (from CLDR/manual) after existing ones.
            merged = {}
            for code in existing[lang]:
                if code in data[lang]:
                    merged[code] = data[lang][code]
            for code, name in data[lang].items():
                if code not in merged:
                    merged[code] = name
            output_data[lang] = merged
    # Append any new languages not in the existing file
    for lang in data:
        if lang not in output_data:
            output_data[lang] = dict(sorted(data[lang].items()))

    log(f"Writing {OUTPUT} ({len(output_data)} languages)...")
    with open(OUTPUT, "w", encoding="utf-8") as f:
        json.dump(output_data, f, ensure_ascii=False, indent=1)
        f.write("\n")

    log("Done!")


if __name__ == "__main__":
    main()
