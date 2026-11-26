#!/usr/bin/env python3
"""Verify rendered PNG screenshots match expected dimensions and are non-blank."""

import argparse
import os
import struct
import sys

PNG_MAGIC = b"\x89PNG\r\n\x1a\n"


def extract_saved_paths(log_text: str) -> list[str]:
    """Parse 'Saved: <path>' or 'qml: Saved: <path>' lines from render logs."""
    saved: list[str] = []
    for raw_line in log_text.splitlines():
        line = raw_line.strip()
        if line.startswith("qml: Saved: "):
            saved.append(line[len("qml: Saved: "):].strip())
        elif line.startswith("Saved: "):
            saved.append(line[len("Saved: "):].strip())
    return saved


def verify_png(path: str, req_w: int, req_h: int, min_bytes: int) -> None:
    """Validate a single PNG file's existence, IHDR size, and minimum byte count."""
    if not os.path.isfile(path):
        raise SystemExit(f"Error: Rendered PNG not found on disk: {path}")

    size = os.path.getsize(path)
    with open(path, "rb") as handle:
        header = handle.read(24)

    if len(header) < 24 or header[:8] != PNG_MAGIC or header[12:16] != b"IHDR":
        raise SystemExit(f"Error: File is not a valid PNG: {path}")

    width, height = struct.unpack(">II", header[16:24])
    if width != req_w or height != req_h:
        raise SystemExit(
            f"Error: Unexpected dimensions in {path}: got {width}x{height}, expected {req_w}x{req_h}"
        )

    if size < min_bytes:
        raise SystemExit(
            f"Error: Rendered PNG looks blank/trivial ({size} bytes < {min_bytes}): {path}\n"
            "Hint: Ensure QT_QUICK_BACKEND=rhi and QSG_RHI_BACKEND=opengl are working on a GPU driver "
            "(without RHI, Qt offscreen falls back to software rendering and skips ShaderEffect)."
        )


def build_parser() -> argparse.ArgumentParser:
    """Construct CLI argument parser."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--width", type=int, required=True, help="Expected PNG width in pixels")
    parser.add_argument("--height", type=int, required=True, help="Expected PNG height in pixels")
    parser.add_argument(
        "--min-bytes",
        type=int,
        default=20000,
        help="Minimum PNG byte size to reject blank renders (default: 20000)",
    )
    parser.add_argument(
        "--log-file",
        default=None,
        help="Path to QML render log file, or '-' to read log lines from stdin",
    )
    parser.add_argument("files", nargs="*", help="Explicit PNG file paths to validate")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.files:
        paths = list(args.files)
    else:
        if args.log_file and args.log_file != "-":
            with open(args.log_file, "r", encoding="utf-8") as handle:
                log_text = handle.read()
        else:
            log_text = sys.stdin.read()
        paths = extract_saved_paths(log_text)
        if not paths:
            raise SystemExit(
                "Error: Renderer exited cleanly but no 'Saved: <path>' outputs were reported."
            )

    for path in paths:
        verify_png(path, args.width, args.height, args.min_bytes)

    print(f"Verified {len(paths)} non-blank {args.width}x{args.height} PNG render(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
