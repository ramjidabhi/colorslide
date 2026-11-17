import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

FONT_PATH = "assets/fonts/Nunito-Bold.ttf"

items = [
    {
        "src": "/home/ram/.gemini/antigravity/brain/22713f5e-55a4-4e1b-a201-0acf0b02c3ab/.user_uploaded/media_1794916905724_4449ce7d.jpg",
        "tag": "LEVEL 21 • WORLD 1",
        "title": "SLIDE & ESCAPE!",
        "subtitle": "Clear the Path for the Cute Hero Block",
        "badge_color": (255, 71, 87),
        "title_color": (255, 255, 255),
        "sub_color": (0, 220, 240),
        "out": "build/playstore_screenshot_1_gameplay.png"
    },
    {
        "src": "/home/ram/.gemini/antigravity/brain/22713f5e-55a4-4e1b-a201-0acf0b02c3ab/.user_uploaded/media_1794916905727_427b3191.jpg",
        "tag": "4 DYNAMIC WORLDS",
        "title": "200 PUZZLE LEVELS",
        "subtitle": "Beginner, Traffic Jam, Frost & Lasers",
        "badge_color": (0, 210, 211),
        "title_color": (255, 255, 255),
        "sub_color": (255, 215, 0),
        "out": "build/playstore_screenshot_2_worlds.png"
    },
    {
        "src": "/home/ram/.gemini/antigravity/brain/22713f5e-55a4-4e1b-a201-0acf0b02c3ab/.user_uploaded/media_1794916905719_ed80ea32.jpg",
        "tag": "FREE DAILY SPINS",
        "title": "LUCKY WHEEL REWARDS",
        "subtitle": "Win Free Coins, Power-Ups & Skins",
        "badge_color": (255, 159, 67),
        "title_color": (255, 255, 255),
        "sub_color": (255, 220, 100),
        "out": "build/playstore_screenshot_3_lucky_wheel.png"
    },
    {
        "src": "/home/ram/.gemini/antigravity/brain/22713f5e-55a4-4e1b-a201-0acf0b02c3ab/.user_uploaded/media_1794916905723_4d3e7b39.jpg",
        "tag": "PLAYER JOURNEY",
        "title": "TRACK YOUR MASTERY",
        "subtitle": "Collect 600 Stars & 200 Par Master Crowns",
        "badge_color": (165, 94, 234),
        "title_color": (255, 255, 255),
        "sub_color": (0, 240, 255),
        "out": "build/playstore_screenshot_4_stats.png"
    },
    {
        "src": "/home/ram/.gemini/antigravity/brain/22713f5e-55a4-4e1b-a201-0acf0b02c3ab/.user_uploaded/media_1794916905721_8be47363.jpg",
        "tag": "GAME MODES",
        "title": "DAILY CHALLENGE & BLITZ",
        "subtitle": "100% Offline • No Wi-Fi Required",
        "badge_color": (46, 213, 115),
        "title_color": (255, 255, 255),
        "sub_color": (120, 255, 170),
        "out": "build/playstore_screenshot_5_modes.png"
    }
]

W, H = 1080, 1920
f_tag = ImageFont.truetype(FONT_PATH, 24)
f_title = ImageFont.truetype(FONT_PATH, 56)
f_sub = ImageFont.truetype(FONT_PATH, 30)
f_foot = ImageFont.truetype(FONT_PATH, 24)

for item in items:
    # 1. Base canvas
    canvas = Image.new("RGB", (W, H), (14, 17, 28))
    draw = ImageDraw.Draw(canvas)

    # Vertical gradient
    for y in range(H):
        ratio = y / H
        r = int(12 + 14 * ratio)
        g = int(15 + 16 * ratio)
        b = int(26 + 30 * ratio)
        draw.line([(0, y), (W, y)], fill=(r, g, b))

    # Grid lines pattern
    for x in range(0, W, 60):
        draw.line([(x, 0), (x, H)], fill=(24, 30, 50), width=1)
    for y in range(0, H, 60):
        draw.line([(0, y), (W, y)], fill=(24, 30, 50), width=1)

    # Glow beneath banner
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse([150, 40, W - 150, 320], fill=(*item["badge_color"], 50))
    glow = glow.filter(ImageFilter.GaussianBlur(60))
    canvas.paste(glow, (0, 0), glow)
    draw = ImageDraw.Draw(canvas)

    # 2. Top Header Banner Card
    draw.rounded_rectangle([40, 40, W - 40, 250], radius=24, fill=(20, 25, 42), outline=(45, 56, 92), width=2)

    # Tag Badge
    bbox_tag = draw.textbbox((0, 0), item["tag"], font=f_tag)
    tw = bbox_tag[2] - bbox_tag[0]
    badge_pad = 20
    draw.rounded_rectangle([W // 2 - tw // 2 - badge_pad, 58, W // 2 + tw // 2 + badge_pad, 98], radius=20, fill=item["badge_color"])
    draw.text((W // 2 - tw // 2, 64), item["tag"], font=f_tag, fill=(255, 255, 255))

    # Main Title
    bbox_title = draw.textbbox((0, 0), item["title"], font=f_title)
    tiw = bbox_title[2] - bbox_title[0]
    draw.text((W // 2 - tiw // 2, 114), item["title"], font=f_title, fill=item["title_color"])

    # Subtitle
    bbox_sub = draw.textbbox((0, 0), item["subtitle"], font=f_sub)
    sw = bbox_sub[2] - bbox_sub[0]
    draw.text((W // 2 - sw // 2, 186), item["subtitle"], font=f_sub, fill=item["sub_color"])

    # 3. Embed User Screenshot in Phone Mockup Frame
    # Raw screenshot is 460 x 1024
    user_img = Image.open(item["src"]).convert("RGBA")
    
    # We want it to occupy from y = 280 to y = 1840 (height = 1560)
    # Target height ~ 1520px -> target width = 1520 * (460/1024) = 682 px
    screen_h = 1520
    screen_w = int(screen_h * (user_img.width / user_img.height)) # ~682
    user_resized = user_img.resize((screen_w, screen_h), Image.Resampling.LANCZOS)

    # Rounded corners for screenshot
    mask = Image.new("L", (screen_w, screen_h), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, screen_w, screen_h], radius=32, fill=255)

    pos_x = (W - screen_w) // 2
    pos_y = 280

    # Phone bezel shadow
    draw.rounded_rectangle([pos_x - 12 + 6, pos_y - 12 + 10, pos_x + screen_w + 12 + 6, pos_y + screen_h + 12 + 10], radius=42, fill=(5, 7, 12))
    # Phone bezel outer frame
    draw.rounded_rectangle([pos_x - 12, pos_y - 12, pos_x + screen_w + 12, pos_y + screen_h + 12], radius=42, fill=(30, 36, 58), outline=(60, 72, 110), width=3)
    # Inner border
    draw.rounded_rectangle([pos_x - 3, pos_y - 3, pos_x + screen_w + 3, pos_y + screen_h + 3], radius=34, fill=(10, 12, 20))

    # Paste screenshot
    canvas.paste(user_resized, (pos_x, pos_y), mask)

    # Save final Play Store screenshot
    canvas.save(item["out"], quality=95)
    print("Created:", item["out"], canvas.size)

# Also update build/phone_screenshot.png with Screenshot 1
import shutil
shutil.copy("build/playstore_screenshot_1_gameplay.png", "build/phone_screenshot.png")
print("Updated build/phone_screenshot.png with the new gameplay screenshot.")
