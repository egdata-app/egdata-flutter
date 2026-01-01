#!/usr/bin/env python3
"""
Generate mobile app icons from logo and gradient background.
Creates app icons, notification icons, and splash screens for Android and iOS.
"""

import os
import sys
from io import BytesIO
from PIL import Image, ImageDraw
import requests

# URLs
LOGO_URL = "https://cdn.egdata.app/logo_simple_white_clean.png"
GRADIENT_URL = "https://cdn.egdata.app/placeholder-1080.webp"

# Output directories
ANDROID_DIR = "android/app/src/main/res"
IOS_DIR = "ios/Runner/Assets.xcassets"
OUTPUT_DIR = "generated_icons"


def download_image(url):
    """Download image from URL and return PIL Image."""
    print(f"Downloading {url}...")
    response = requests.get(url)
    response.raise_for_status()
    return Image.open(BytesIO(response.content)).convert("RGBA")


def analyze_gradient(gradient_image):
    """Extract gradient colors from the image."""
    # Sample colors from top and bottom of the gradient
    width, height = gradient_image.size

    # Sample from center column at different heights
    center_x = width // 2
    top_color = gradient_image.getpixel((center_x, height // 4))
    bottom_color = gradient_image.getpixel((center_x, height * 3 // 4))

    print(f"Gradient colors: top={top_color[:3]}, bottom={bottom_color[:3]}")
    return top_color[:3], bottom_color[:3]


def create_gradient_background(size, top_color, bottom_color):
    """Create a vertical gradient background."""
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    width, height = size
    for y in range(height):
        # Interpolate between top and bottom colors
        ratio = y / height
        r = int(top_color[0] * (1 - ratio) + bottom_color[0] * ratio)
        g = int(top_color[1] * (1 - ratio) + bottom_color[1] * ratio)
        b = int(top_color[2] * (1 - ratio) + bottom_color[2] * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))

    return image


def create_app_icon(logo, top_color, bottom_color, size, padding_percent=30):
    """Create an app icon with gradient background and centered logo."""
    # Create gradient background
    background = create_gradient_background((size, size), top_color, bottom_color)

    # Calculate logo size with padding
    padding = int(size * padding_percent / 100)
    logo_size = size - (2 * padding)

    # Resize logo maintaining aspect ratio
    logo_resized = logo.copy()
    logo_resized.thumbnail((logo_size, logo_size), Image.Resampling.LANCZOS)

    # Center logo on background
    logo_x = (size - logo_resized.width) // 2
    logo_y = (size - logo_resized.height) // 2

    # Composite logo onto background
    background.paste(logo_resized, (logo_x, logo_y), logo_resized)

    return background


def create_notification_icon(logo, size):
    """Create a notification icon (white silhouette on transparent)."""
    # For notification icons, we want just the white logo on transparent
    icon = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # Resize logo maintaining aspect ratio
    logo_resized = logo.copy()
    padding = int(size * 0.1)  # 10% padding
    logo_resized.thumbnail((size - 2 * padding, size - 2 * padding), Image.Resampling.LANCZOS)

    # Center logo
    logo_x = (size - logo_resized.width) // 2
    logo_y = (size - logo_resized.height) // 2

    icon.paste(logo_resized, (logo_x, logo_y), logo_resized)

    return icon


def create_splash_screen(logo, top_color, bottom_color, size):
    """Create a splash screen with gradient background and centered logo."""
    width, height = size
    background = create_gradient_background(size, top_color, bottom_color)

    # Make logo larger for splash screen (50% of screen height)
    logo_height = int(height * 0.5)
    logo_resized = logo.copy()
    logo_resized.thumbnail((width, logo_height), Image.Resampling.LANCZOS)

    # Center logo
    logo_x = (width - logo_resized.width) // 2
    logo_y = (height - logo_resized.height) // 2

    background.paste(logo_resized, (logo_x, logo_y), logo_resized)

    return background


def generate_android_icons(logo, top_color, bottom_color, output_dir):
    """Generate Android launcher and notification icons."""
    print("\nGenerating Android icons...")

    # Launcher icons (mipmap)
    launcher_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }

    for folder, size in launcher_sizes.items():
        icon = create_app_icon(logo, top_color, bottom_color, size)
        icon_dir = os.path.join(output_dir, "android", folder)
        os.makedirs(icon_dir, exist_ok=True)
        icon.save(os.path.join(icon_dir, "ic_launcher.png"))
        print(f"  Created {folder}/ic_launcher.png ({size}x{size})")

    # Notification icons (drawable)
    notification_sizes = {
        "drawable-mdpi": 24,
        "drawable-hdpi": 36,
        "drawable-xhdpi": 48,
        "drawable-xxhdpi": 72,
        "drawable-xxxhdpi": 96,
    }

    for folder, size in notification_sizes.items():
        icon = create_notification_icon(logo, size)
        icon_dir = os.path.join(output_dir, "android", folder)
        os.makedirs(icon_dir, exist_ok=True)
        icon.save(os.path.join(icon_dir, "ic_notification.png"))
        print(f"  Created {folder}/ic_notification.png ({size}x{size})")

    # Adaptive icon layers for all densities
    # Android adaptive icons need 108dp x 108dp with safe zone in center 72dp
    # The outer 18dp on each side can be masked/cropped
    adaptive_sizes = {
        "mipmap-mdpi": 108,
        "mipmap-hdpi": 162,
        "mipmap-xhdpi": 216,
        "mipmap-xxhdpi": 324,
        "mipmap-xxxhdpi": 432,
    }

    for folder, size in adaptive_sizes.items():
        adaptive_dir = os.path.join(output_dir, "android", folder)
        os.makedirs(adaptive_dir, exist_ok=True)

        # Background layer - just gradient
        background = create_gradient_background((size, size), top_color, bottom_color)
        background.save(os.path.join(adaptive_dir, "ic_launcher_background.png"))

        # Foreground layer - logo with safe zone padding
        # Use 50% padding to ensure logo fits in the 66% safe zone (72dp of 108dp)
        foreground = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        logo_padding = int(size * 0.25)  # 25% padding on each side = 50% total
        logo_size = size - (2 * logo_padding)

        logo_resized = logo.copy()
        logo_resized.thumbnail((logo_size, logo_size), Image.Resampling.LANCZOS)

        logo_x = (size - logo_resized.width) // 2
        logo_y = (size - logo_resized.height) // 2
        foreground.paste(logo_resized, (logo_x, logo_y), logo_resized)

        foreground.save(os.path.join(adaptive_dir, "ic_launcher_foreground.png"))

    print(f"  Created adaptive icon layers for all densities")


def generate_ios_icons(logo, top_color, bottom_color, output_dir):
    """Generate iOS app icons."""
    print("\nGenerating iOS icons...")

    # iOS app icon sizes (in points, we generate @1x, @2x, @3x)
    # For simplicity, we'll generate the commonly used sizes
    ios_sizes = {
        "Icon-20@2x.png": 40,
        "Icon-20@3x.png": 60,
        "Icon-29@2x.png": 58,
        "Icon-29@3x.png": 87,
        "Icon-40@2x.png": 80,
        "Icon-40@3x.png": 120,
        "Icon-60@2x.png": 120,
        "Icon-60@3x.png": 180,
        "Icon-76.png": 76,
        "Icon-76@2x.png": 152,
        "Icon-83.5@2x.png": 167,
        "Icon-1024.png": 1024,  # App Store
    }

    ios_dir = os.path.join(output_dir, "ios")
    os.makedirs(ios_dir, exist_ok=True)

    for filename, size in ios_sizes.items():
        icon = create_app_icon(logo, top_color, bottom_color, size)
        icon.save(os.path.join(ios_dir, filename))
        print(f"  Created {filename} ({size}x{size})")


def generate_splash_screens(logo, top_color, bottom_color, output_dir):
    """Generate splash screens for common mobile resolutions."""
    print("\nGenerating splash screens...")

    splash_sizes = {
        "splash-mdpi.png": (480, 800),
        "splash-hdpi.png": (720, 1280),
        "splash-xhdpi.png": (1080, 1920),
        "splash-xxhdpi.png": (1440, 2560),
        "splash-xxxhdpi.png": (1920, 3840),
        "splash-ios-1x.png": (750, 1334),  # iPhone 8
        "splash-ios-2x.png": (1125, 2436),  # iPhone X
        "splash-ios-3x.png": (1242, 2688),  # iPhone XS Max
    }

    splash_dir = os.path.join(output_dir, "splash")
    os.makedirs(splash_dir, exist_ok=True)

    for filename, size in splash_sizes.items():
        splash = create_splash_screen(logo, top_color, bottom_color, size)
        splash.save(os.path.join(splash_dir, filename))
        print(f"  Created {filename} ({size[0]}x{size[1]})")


def main():
    """Main function to generate all icons."""
    print("EGData Mobile Icon Generator")
    print("=" * 50)

    try:
        # Download images
        logo = download_image(LOGO_URL)
        gradient = download_image(GRADIENT_URL)

        # Analyze gradient
        top_color, bottom_color = analyze_gradient(gradient)

        # Create output directory
        output_dir = OUTPUT_DIR
        os.makedirs(output_dir, exist_ok=True)

        # Generate all icon types
        generate_android_icons(logo, top_color, bottom_color, output_dir)
        generate_ios_icons(logo, top_color, bottom_color, output_dir)
        generate_splash_screens(logo, top_color, bottom_color, output_dir)

        print("\n" + "=" * 50)
        print(f"All icons generated successfully in: {output_dir}")
        print("\nNext steps:")
        print("1. Review generated icons in the 'generated_icons' directory")
        print("2. Copy Android icons to android/app/src/main/res/")
        print("3. Copy iOS icons to ios/Runner/Assets.xcassets/AppIcon.appiconset/")
        print("4. Configure splash screens in your Flutter project")

    except Exception as e:
        print(f"\nError: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
