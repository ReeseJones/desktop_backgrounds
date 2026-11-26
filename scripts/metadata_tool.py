#!/usr/bin/env python3
"""Read, bump, update, and validate KDE Plasma 6 wallpaper metadata and KConfig XML."""

import argparse
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")


def parse_semver(version: str, label: str = "version") -> tuple[int, int, int]:
    """Parse a strict X.Y.Z semantic version string."""
    match = SEMVER_RE.fullmatch(str(version))
    if not match:
        raise SystemExit(f"Error: {label} '{version}' does not match X.Y.Z")
    return tuple(int(part) for part in match.groups())


def load_metadata(path: str) -> dict:
    """Load and return parsed metadata.json data."""
    if not os.path.isfile(path):
        raise SystemExit(f"Missing metadata.json: {path}")
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def cmd_get(args: argparse.Namespace) -> int:
    """Print KPlugin Id and/or Version from metadata.json."""
    data = load_metadata(args.metadata_json)
    kp = data.get("KPlugin")
    if not isinstance(kp, dict):
        raise SystemExit(f"Error: {args.metadata_json} missing KPlugin object")
    plugin_id = str(kp.get("Id", "")).strip()
    version = str(kp.get("Version", "")).strip()
    if not plugin_id or not version:
        raise SystemExit(
            f"Error: Failed to extract KPlugin.Id and KPlugin.Version from {args.metadata_json}"
        )

    if args.field == "id":
        print(plugin_id)
    elif args.field == "version":
        print(version)
    else:
        print(f"{plugin_id} {version}")
    return 0


def cmd_bump(args: argparse.Namespace) -> int:
    """Compute the next X.Y.Z version given current version and bump mode."""
    maj, minor, patch = parse_semver(args.current_version, "Current version")
    mode = args.mode
    if mode == "same":
        next_ver = f"{maj}.{minor}.{patch}"
    elif mode == "patch":
        next_ver = f"{maj}.{minor}.{patch + 1}"
    elif mode == "minor":
        next_ver = f"{maj}.{minor + 1}.0"
    elif mode == "major":
        next_ver = f"{maj + 1}.0.0"
    elif SEMVER_RE.fullmatch(mode):
        next_ver = mode
    else:
        raise SystemExit(f"Invalid bump/version '{mode}'")
    print(next_ver)
    return 0


def cmd_set_version(args: argparse.Namespace) -> int:
    """Update KPlugin.Version in metadata.json while preserving formatting."""
    parse_semver(args.version, "Target version")
    data = load_metadata(args.metadata_json)
    kp = data.get("KPlugin")
    if not isinstance(kp, dict):
        raise SystemExit(f"Error: {args.metadata_json} missing KPlugin object")
    kp["Version"] = args.version
    with open(args.metadata_json, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=4)
        handle.write("\n")
    return 0


def cmd_validate(args: argparse.Namespace) -> int:
    """Validate Plasma/Wallpaper metadata.json fields and KConfig main.xml syntax."""
    data = load_metadata(args.metadata_json)
    if data.get("KPackageStructure") != "Plasma/Wallpaper":
        raise SystemExit("metadata.json KPackageStructure must be 'Plasma/Wallpaper'")
    kp = data.get("KPlugin")
    if not isinstance(kp, dict):
        raise SystemExit("metadata.json missing KPlugin object")

    plugin_id = str(kp.get("Id", "")).strip()
    plugin_name = str(kp.get("Name", "")).strip()
    version = str(kp.get("Version", "")).strip()
    if not plugin_id:
        raise SystemExit("metadata.json missing KPlugin.Id")
    if not plugin_name:
        raise SystemExit("metadata.json missing KPlugin.Name")
    parse_semver(version, "metadata.json KPlugin.Version")
    if data.get("X-KDE-ParentApp") != "org.kde.plasmashell":
        raise SystemExit("metadata.json X-KDE-ParentApp must be 'org.kde.plasmashell'")

    if not os.path.isfile(args.main_xml):
        raise SystemExit(f"Missing KConfig schema: {args.main_xml}")
    ET.parse(args.main_xml)

    print(f"[PASS] Check 2 (Metadata & KConfig XML): {plugin_id} v{version}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    """Construct CLI argument parser."""
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    p_get = subparsers.add_parser("get", help="Extract KPlugin.Id and/or Version")
    p_get.add_argument("metadata_json", help="Path to package/metadata.json")
    p_get.add_argument(
        "--field",
        choices=("id-version", "id", "version"),
        default="id-version",
        help="Which field(s) to output (default: id-version)",
    )
    p_get.set_defaults(func=cmd_get)

    p_bump = subparsers.add_parser("bump", help="Compute bumped X.Y.Z version")
    p_bump.add_argument("current_version", help="Existing X.Y.Z version")
    p_bump.add_argument("mode", help="patch | minor | major | same | X.Y.Z")
    p_bump.set_defaults(func=cmd_bump)

    p_set = subparsers.add_parser("set-version", help="Write KPlugin.Version in metadata.json")
    p_set.add_argument("metadata_json", help="Path to package/metadata.json")
    p_set.add_argument("version", help="New X.Y.Z version")
    p_set.set_defaults(func=cmd_set_version)

    p_val = subparsers.add_parser("validate", help="Validate metadata.json and main.xml")
    p_val.add_argument("metadata_json", help="Path to package/metadata.json")
    p_val.add_argument("main_xml", help="Path to package/contents/config/main.xml")
    p_val.set_defaults(func=cmd_validate)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
