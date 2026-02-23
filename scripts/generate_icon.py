#!/usr/bin/env python3
"""Generate pulse5ctl app icon as .icns."""

import math
import os
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw


def draw_icon(size: int) -> Image.Image:
    """Draw a hifispeaker icon at the given size (matches SF Symbol hifispeaker.fill)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    s = size / 512.0

    # Background: dark rounded rectangle
    bg_color = (30, 30, 50, 255)
    margin = int(12 * s)
    bg_radius = int(100 * s)
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=bg_radius,
        fill=bg_color,
    )
    border_color = (60, 60, 90, 255)
    border_w = max(1, int(3 * s))
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=bg_radius,
        outline=border_color,
        width=border_w,
    )

    cx = size / 2
    cy = size / 2
    white = (240, 240, 255, 255)
    dark = (20, 20, 40, 255)

    # Hi-fi speaker body — tall rounded rectangle, centered
    body_w = int(160 * s)
    body_h = int(280 * s)
    body_r = int(30 * s)
    body_x1 = cx - body_w // 2
    body_y1 = cy - body_h // 2
    body_x2 = cx + body_w // 2
    body_y2 = cy + body_h // 2
    draw.rounded_rectangle(
        [body_x1, body_y1, body_x2, body_y2],
        radius=body_r,
        fill=white,
    )

    # Large woofer — circle in the lower portion
    woofer_r = int(52 * s)
    woofer_cy = cy + int(50 * s)
    draw.ellipse(
        [cx - woofer_r, woofer_cy - woofer_r, cx + woofer_r, woofer_cy + woofer_r],
        fill=dark,
    )
    # Woofer inner ring
    inner_r = int(28 * s)
    draw.ellipse(
        [cx - inner_r, woofer_cy - inner_r, cx + inner_r, woofer_cy + inner_r],
        fill=(50, 50, 70, 255),
    )
    # Woofer dust cap
    cap_r = int(12 * s)
    draw.ellipse(
        [cx - cap_r, woofer_cy - cap_r, cx + cap_r, woofer_cy + cap_r],
        fill=dark,
    )

    # Tweeter — smaller circle in the upper portion
    tweeter_r = int(28 * s)
    tweeter_cy = cy - int(65 * s)
    draw.ellipse(
        [cx - tweeter_r, tweeter_cy - tweeter_r, cx + tweeter_r, tweeter_cy + tweeter_r],
        fill=dark,
    )
    # Tweeter dome
    dome_r = int(12 * s)
    draw.ellipse(
        [cx - dome_r, tweeter_cy - dome_r, cx + dome_r, tweeter_cy + dome_r],
        fill=(50, 50, 70, 255),
    )

    return img


def main():
    project_root = Path(__file__).resolve().parent.parent
    iconset_dir = project_root / "Sources" / "app" / "macos" / "AppIcon.iconset"
    iconset_dir.mkdir(parents=True, exist_ok=True)

    # Required sizes for macOS .icns
    sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }

    # Draw at 1024 and scale down for quality
    master = draw_icon(1024)

    for filename, px in sizes.items():
        resized = master.resize((px, px), Image.LANCZOS)
        resized.save(iconset_dir / filename)
        print(f"  {filename} ({px}x{px})")

    # Convert iconset → icns
    icns_path = project_root / "Sources" / "app" / "macos" / "AppIcon.icns"
    subprocess.run(
        ["iconutil", "-c", "icns", str(iconset_dir), "-o", str(icns_path)],
        check=True,
    )
    print(f"\nCreated {icns_path}")

    # Clean up iconset directory
    for f in iconset_dir.iterdir():
        f.unlink()
    iconset_dir.rmdir()
    print("Cleaned up iconset directory")


if __name__ == "__main__":
    main()
