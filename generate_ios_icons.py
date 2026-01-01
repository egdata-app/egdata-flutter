#!/usr/bin/env python3
"""
Generate iOS icons with correct filenames from the gradient icon.
"""

import os
from PIL import Image

# Map of expected iOS filenames to their pixel sizes
IOS_ICON_SIZES = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-57x57@1x.png": 57,
    "Icon-App-57x57@2x.png": 114,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-50x50@1x.png": 50,
    "Icon-App-50x50@2x.png": 100,
    "Icon-App-72x72@1x.png": 72,
    "Icon-App-72x72@2x.png": 144,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

def resize_icon(source_path, output_dir):
    """Resize the 1024px icon to all required iOS sizes."""
    # Load the 1024x1024 source icon
    source = Image.open(source_path)

    if source.size != (1024, 1024):
        print(f"Warning: Source image is {source.size}, expected 1024x1024")

    for filename, size in IOS_ICON_SIZES.items():
        # Resize the icon
        resized = source.resize((size, size), Image.Resampling.LANCZOS)

        # Save with the correct filename
        output_path = os.path.join(output_dir, filename)
        resized.save(output_path)
        print(f"Created {filename} ({size}x{size})")

def main():
    source_icon = "generated_icons/ios/Icon-1024.png"
    output_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"

    if not os.path.exists(source_icon):
        print(f"Error: Source icon not found: {source_icon}")
        return

    if not os.path.exists(output_dir):
        print(f"Error: Output directory not found: {output_dir}")
        return

    print(f"Generating iOS icons from {source_icon}...")
    resize_icon(source_icon, output_dir)
    print(f"\nAll iOS icons generated in {output_dir}")

if __name__ == "__main__":
    main()
