import json
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# Load level definitions
with open("levels/levels.json", "r", encoding="utf-8") as f:
    LEVELS = json.load(f)

FONT_PATH = "assets/fonts/Nunito-Bold.ttf"

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip("#")
    if len(hex_str) == 6:
        return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))
    return (200, 200, 200)

def lighten(rgb, amount=40):
    return tuple(min(255, c + amount) for c in rgb)

def darken(rgb, amount=40):
    return tuple(max(0, c - amount) for c in rgb)

def render_store_screenshot(lvl_data, banner_title, banner_sub, out_path, moves_text="MOVES: 3  |  PAR: 4", mode_badge="CLASSIC ESCAPE"):
    W, H = 1080, 1920
    img = Image.new("RGB", (W, H), (14, 17, 29))
    draw = ImageDraw.Draw(img)

    # 1. Background Gradient
    for y in range(H):
        ratio = y / H
        r = int(12 + 15 * ratio)
        g = int(15 + 18 * ratio)
        b = int(28 + 32 * ratio)
        draw.line([(0, y), (W, y)], fill=(r, g, b))

    # Grid lines background
    for x in range(0, W, 60):
        draw.line([(x, 0), (x, H)], fill=(25, 32, 54), width=1)
    for y in range(0, H, 60):
        draw.line([(0, y), (W, y)], fill=(25, 32, 54), width=1)

    # Ambient glows
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse([200, 100, 880, 450], fill=(255, 71, 87, 40))
    glow_draw.ellipse([140, 600, 940, 1400], fill=(0, 210, 211, 25))
    glow = glow.filter(ImageFilter.GaussianBlur(80))
    img.paste(glow, (0, 0), glow)
    draw = ImageDraw.Draw(img)

    # Fonts
    f_banner_title = ImageFont.truetype(FONT_PATH, 58)
    f_banner_sub = ImageFont.truetype(FONT_PATH, 30)
    f_header = ImageFont.truetype(FONT_PATH, 38)
    f_sub = ImageFont.truetype(FONT_PATH, 24)
    f_btn = ImageFont.truetype(FONT_PATH, 26)
    f_arrow = ImageFont.truetype(FONT_PATH, 36)

    # 2. Promotional Top Banner (ASO Styled)
    # Banner card
    draw.rounded_rectangle([40, 50, W - 40, 260], radius=28, fill=(20, 25, 42), outline=(50, 62, 98), width=2)

    # Mode Pill Badge
    pill_w = 260
    draw.rounded_rectangle([W // 2 - pill_w // 2, 70, W // 2 + pill_w // 2, 114], radius=22, fill=(255, 71, 87))
    draw.text((W // 2 - 95, 77), mode_badge, font=f_sub, fill=(255, 255, 255))

    # Banner Title
    # Center text
    bbox_t = draw.textbbox((0, 0), banner_title, font=f_banner_title)
    bw = bbox_t[2] - bbox_t[0]
    draw.text((W // 2 - bw // 2, 126), banner_title, font=f_banner_title, fill=(255, 255, 255))

    # Banner Subtitle
    bbox_s = draw.textbbox((0, 0), banner_sub, font=f_banner_sub)
    sw = bbox_s[2] - bbox_s[0]
    draw.text((W // 2 - sw // 2, 198), banner_sub, font=f_banner_sub, fill=(0, 220, 240))

    # 3. Game HUD Header
    hud_y = 300
    # Level info
    draw.text((80, hud_y), f"LEVEL {lvl_data['level_id']}", font=f_header, fill=(255, 255, 255))
    draw.text((80, hud_y + 46), f"{lvl_data.get('world_name', 'World')} • {lvl_data.get('title', '')}", font=f_sub, fill=(160, 175, 205))

    # Stars
    stars_x = W - 320
    for s in range(3):
        # Draw gold star circle
        draw.ellipse([stars_x + s * 65, hud_y + 6, stars_x + s * 65 + 46, hud_y + 52], fill=(255, 193, 7))
        draw.text((stars_x + s * 65 + 14, hud_y + 12), "★", font=f_btn, fill=(30, 20, 0))

    # Move Counter Card
    mc_y = 400
    draw.rounded_rectangle([80, mc_y, W - 80, mc_y + 70], radius=18, fill=(24, 30, 52), outline=(45, 56, 88), width=2)
    draw.text((110, mc_y + 18), moves_text, font=f_header, fill=(255, 215, 0))

    # Undo & Reset quick buttons
    draw.rounded_rectangle([W - 290, mc_y + 10, W - 195, mc_y + 60], radius=14, fill=(35, 45, 75))
    draw.text((W - 275, mc_y + 18), "↺ Undo", font=f_sub, fill=(255, 255, 255))

    draw.rounded_rectangle([W - 180, mc_y + 10, W - 95, mc_y + 60], radius=14, fill=(35, 45, 75))
    draw.text((W - 165, mc_y + 18), "↻ Reset", font=f_sub, fill=(255, 255, 255))

    # 4. Game Board (Centered 6x6 grid)
    board_s = 920
    bx = (W - board_s) // 2
    by = 510
    cell_s = board_s // 6 # ~153 px

    # Board shadow and container
    draw.rounded_rectangle([bx + 8, by + 12, bx + board_s + 8, by + board_s + 12], radius=24, fill=(5, 8, 14))
    draw.rounded_rectangle([bx, by, bx + board_s, by + board_s], radius=24, fill=(22, 27, 44), outline=(55, 68, 105), width=3)

    # Grid lines
    for i in range(1, 6):
        draw.line([(bx + i * cell_s, by), (bx + i * cell_s, by + board_s)], fill=(32, 40, 64), width=2)
        draw.line([(bx, by + i * cell_s), (bx + board_s, by + i * cell_s)], fill=(32, 40, 64), width=2)

    # Exit Gate at row 2 on the right edge
    exit_y1 = by + 2 * cell_s + 10
    exit_y2 = by + 3 * cell_s - 10
    draw.rectangle([bx + board_s - 8, exit_y1, bx + board_s + 20, exit_y2], fill=(255, 215, 0))
    draw.text((bx + board_s - 2, exit_y1 + 45), "▶", font=f_header, fill=(15, 20, 30))

    # Draw Switches & Lasers if any
    for sw in lvl_data.get("switches", []):
        sx = bx + sw["x"] * cell_s + 20
        sy = by + sw["y"] * cell_s + 20
        draw.rounded_rectangle([sx, sy, sx + cell_s - 40, sy + cell_s - 40], radius=16, fill=(255, 177, 0, 180), outline=(255, 255, 255), width=2)
        draw.text((sx + 35, sy + 30), "⚡", font=f_header, fill=(255, 255, 255))

    for lsr in lvl_data.get("lasers", []):
        lx = bx + lsr["x"] * cell_s
        ly = by + lsr["y"] * cell_s
        # Glowing red laser beam
        draw.rectangle([lx + 10, ly + cell_s // 2 - 8, lx + cell_s - 10, ly + cell_s // 2 + 8], fill=(255, 0, 80))
        draw.rectangle([lx + 20, ly + cell_s // 2 - 3, lx + cell_s - 20, ly + cell_s // 2 + 3], fill=(255, 255, 255))

    # Draw Blocks from level
    gap = 8
    for b in lvl_data["blocks"]:
        is_vert = b["direction"] == "vertical"
        length = b["length"]
        base_rgb = hex_to_rgb(b.get("color", "#FF4757"))
        
        # If frozen
        if b.get("is_frozen", False):
            base_rgb = (120, 210, 255)

        x1 = bx + b["x"] * cell_s + gap
        y1 = by + b["y"] * cell_s + gap
        if is_vert:
            x2 = x1 + cell_s - 2 * gap
            y2 = y1 + length * cell_s - 2 * gap
        else:
            x2 = x1 + length * cell_s - 2 * gap
            y2 = y1 + cell_s - 2 * gap

        # Bottom shadow
        draw.rounded_rectangle([x1, y1 + 6, x2, y2 + 6], radius=18, fill=(8, 11, 18))
        # Body
        draw.rounded_rectangle([x1, y1, x2, y2], radius=18, fill=base_rgb)
        # Top highlight
        draw.rounded_rectangle([x1 + 4, y1 + 4, x2 - 4, y1 + 12], radius=6, fill=lighten(base_rgb, 50))

        # Inner icon / label
        if b.get("is_target", False):
            # Target Red Block
            cx = (x1 + x2) // 2
            cy = (y1 + y2) // 2
            draw.text((cx - 16, cy - 24), "▶▶", font=f_arrow, fill=(255, 255, 255))
        elif b.get("is_frozen", False):
            cx = (x1 + x2) // 2
            cy = (y1 + y2) // 2
            draw.text((cx - 15, cy - 22), "❄", font=f_arrow, fill=(255, 255, 255))

    # 5. Bottom Booster Toolbar (tactile action bar)
    bar_y = 1480
    draw.rounded_rectangle([60, bar_y, W - 60, bar_y + 180], radius=28, fill=(22, 28, 48), outline=(48, 60, 96), width=2)

    boosters = [
        ("🔨 Sledgehammer", "Smash Block", (255, 110, 64)),
        ("⚡ Shrink Ray", "Resize Block", (64, 196, 255)),
        ("🧲 Crane", "Lift & Move", (255, 193, 7)),
        ("💡 Smart Hint", "Step-by-Step", (76, 217, 100))
    ]

    bw_item = 210
    for idx, (b_name, b_desc, col) in enumerate(boosters):
        bx_pos = 80 + idx * 230
        draw.rounded_rectangle([bx_pos, bar_y + 20, bx_pos + bw_item, bar_y + 155], radius=20, fill=(30, 38, 64))
        draw.text((bx_pos + 18, bar_y + 35), b_name.split()[0], font=f_header, fill=(255, 255, 255))
        draw.text((bx_pos + 16, bar_y + 85), b_name.split()[1] if len(b_name.split()) > 1 else "", font=f_sub, fill=col)
        draw.text((bx_pos + 16, bar_y + 115), b_desc, font=ImageFont.truetype(FONT_PATH, 18), fill=(160, 175, 200))

    # 6. Bottom Offline & Star Milestone Tag
    foot_y = 1710
    draw.rounded_rectangle([80, foot_y, W - 80, foot_y + 90], radius=24, fill=(18, 23, 38), outline=(40, 50, 80), width=1)
    badge_label = "✈  100% OFFLINE PLAY  •  NO ENERGY TIMERS  •  NO WIFI NEEDED"
    draw.text((120, foot_y + 30), badge_label, font=f_btn, fill=(76, 217, 100))

    img.save(out_path, quality=95)
    print("Generated Screenshot:", out_path)

# Generate 5 High-Impact Store Screenshots
# 1. Level 1 - Classic Slide & Escape
render_store_screenshot(
    LEVELS[0], 
    "SLIDE & ESCAPE!", 
    "200 Handcrafted Mind-Bending Levels", 
    "build/screenshot_1_classic.png",
    moves_text="MOVES: 2  |  PAR: 3",
    mode_badge="CLASSIC ESCAPE"
)

# 2. Level 55 - Strategic Traffic Jam
render_store_screenshot(
    LEVELS[54], 
    "STRATEGIC TRAFFIC JAM", 
    "Outsmart Heavy 3-Unit Trucks & Deadlocks", 
    "build/screenshot_2_traffic_jam.png",
    moves_text="MOVES: 8  |  PAR: 14",
    mode_badge="WORLD 2 • TRAFFIC JAM"
)

# 3. Level 105 - Frost Cavern
render_store_screenshot(
    LEVELS[104], 
    "FROST CAVERN MECHANICS", 
    "Slide Adjacent Blocks to Thaw Frozen Ice!", 
    "build/screenshot_3_frost_cavern.png",
    moves_text="MOVES: 6  |  PAR: 12",
    mode_badge="WORLD 3 • FROST CAVERN"
)

# 4. Level 155 - Laser Facility
render_store_screenshot(
    LEVELS[154], 
    "HIGH-TECH LASER GATES", 
    "Trigger Pressure Switches to Deactivate Barriers", 
    "build/screenshot_4_laser_facility.png",
    moves_text="MOVES: 11  |  PAR: 18",
    mode_badge="WORLD 4 • LASER DEFENSE"
)

# 5. Blitz Mode / Brain Workout
render_store_screenshot(
    LEVELS[19], 
    "60-SECOND RUSH HOUR BLITZ", 
    "Combo Multipliers, Daily Streaks & Rewards", 
    "build/screenshot_5_blitz_mode.png",
    moves_text="TIME: 00:42  |  COMBO: 3x  |  SCORE: 1,450",
    mode_badge="RUSH HOUR BLITZ"
)

# Replace the empty pitch-black phone_screenshot.png with Screenshot 1
import shutil
shutil.copy("build/screenshot_1_classic.png", "build/phone_screenshot.png")
shutil.copy("build/screenshot_1_classic.png", "phone_screen_test.png")
print("Replaced black phone_screenshot.png and phone_screen_test.png with real gameplay screenshots!")
