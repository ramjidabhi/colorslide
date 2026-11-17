import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_feature_graphic(out_path="build/playstore_feature_graphic_1024x500.png"):
    width, height = 1024, 500
    img = Image.new("RGB", (width, height), (13, 16, 28))
    draw = ImageDraw.Draw(img)

    # 1. Gradient Background
    for y in range(height):
        ratio = y / height
        r = int(12 + 14 * ratio)
        g = int(15 + 16 * ratio)
        b = int(26 + 28 * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))

    # 2. Subtle Background Grid Pattern
    grid_size = 40
    for x in range(0, width, grid_size):
        draw.line([(x, 0), (x, height)], fill=(25, 33, 56, 120), width=1)
    for y in range(0, height, grid_size):
        draw.line([(0, y), (width, y)], fill=(25, 33, 56, 120), width=1)

    # Glow effects in background (behind title and behind board)
    glow_overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_overlay)
    
    # Red hero glow on right
    glow_draw.ellipse([540, 80, 960, 420], fill=(255, 46, 86, 50))
    # Cyan accent glow on left
    glow_draw.ellipse([80, 60, 480, 360], fill=(0, 242, 254, 30))
    # Golden glow at exit gate
    glow_draw.ellipse([880, 150, 1020, 310], fill=(255, 215, 0, 40))
    glow_overlay = glow_overlay.filter(ImageFilter.GaussianBlur(50))
    img.paste(glow_overlay, (0, 0), glow_overlay)
    draw = ImageDraw.Draw(img)

    # Load Fonts
    font_path = "assets/fonts/Nunito-Bold.ttf"
    title_font_big = ImageFont.truetype(font_path, 46)
    title_font_sub = ImageFont.truetype(font_path, 40)
    tagline_font = ImageFont.truetype(font_path, 18)
    badge_font = ImageFont.truetype(font_path, 16)
    block_font = ImageFont.truetype(font_path, 22)
    arrow_font = ImageFont.truetype(font_path, 28)

    # 3. Left Side: Game Branding & Badges
    # Draw title drop shadow
    draw.text((72, 68), "UNBLOCK PUZZLE", font=title_font_big, fill=(5, 7, 12))
    draw.text((70, 66), "UNBLOCK PUZZLE", font=title_font_big, fill=(255, 255, 255))

    # SLIDE ESCAPE in gradient / accent red
    draw.text((72, 122), "SLIDE ESCAPE", font=title_font_sub, fill=(5, 7, 12))
    draw.text((70, 120), "SLIDE ESCAPE", font=title_font_sub, fill=(255, 68, 88))

    # Tagline
    draw.text((70, 180), "THE ULTIMATE TACTILE BRAIN WORKOUT", font=tagline_font, fill=(0, 220, 240))

    # Feature Badges
    badges = [
        ("★  200 Handcrafted Levels", (255, 193, 7)),
        ("❄  Frost Caverns & Laser Gates", (64, 196, 255)),
        ("⚡  60s Blitz & Daily Challenges", (255, 110, 64)),
        ("✈  100% Offline — No WiFi Needed", (76, 217, 100))
    ]

    by = 225
    for text, col in badges:
        pill_w = 340
        pill_h = 36
        draw.rounded_rectangle([70, by, 70 + pill_w, by + pill_h], radius=18, fill=(20, 26, 45), outline=(38, 48, 78), width=1)
        draw.text((86, by + 8), text, font=badge_font, fill=col)
        by += 48

    # 4. Right Side: 6x6 Stylized Puzzle Board
    bx, by = 540, 70
    bw, bh = 420, 360
    cell_s = bw // 6 # 70px per cell
    
    # Board container with shadow
    draw.rounded_rectangle([bx + 4, by + 6, bx + bw + 4, by + bh + 6], radius=16, fill=(5, 7, 12))
    draw.rounded_rectangle([bx, by, bx + bw, by + bh], radius=16, fill=(22, 27, 44), outline=(45, 55, 85), width=2)

    # Grid cell lines
    for c in range(1, 6):
        draw.line([(bx + c * cell_s, by), (bx + c * cell_s, by + bh)], fill=(32, 39, 62), width=1)
        draw.line([(bx, by + c * cell_s), (bx + bw, by + c * cell_s)], fill=(32, 39, 62), width=1)

    # Exit Gate at row 2 (y=2) on the right edge
    exit_y1 = by + 2 * cell_s + 4
    exit_y2 = by + 3 * cell_s - 4
    draw.rectangle([bx + bw - 4, exit_y1, bx + bw + 14, exit_y2], fill=(255, 215, 0))
    draw.text((bx + bw + 20, exit_y1 + 15), "EXIT ▶", font=badge_font, fill=(255, 215, 0))

    # Helper function to draw rounded 3D block
    def draw_block(grid_x, grid_y, len_cells, is_vert, base_color, top_highlight, label=""):
        gap = 4
        x1 = bx + grid_x * cell_s + gap
        y1 = by + grid_y * cell_s + gap
        if is_vert:
            x2 = x1 + cell_s - 2 * gap
            y2 = y1 + len_cells * cell_s - 2 * gap
        else:
            x2 = x1 + len_cells * cell_s - 2 * gap
            y2 = y1 + cell_s - 2 * gap

        # Bottom shadow
        draw.rounded_rectangle([x1, y1 + 3, x2, y2 + 3], radius=10, fill=(8, 10, 16))
        # Main body
        draw.rounded_rectangle([x1, y1, x2, y2], radius=10, fill=base_color)
        # Top bevel highlight
        draw.rounded_rectangle([x1 + 2, y1 + 2, x2 - 2, y1 + 6], radius=4, fill=top_highlight)

        # Draw arrows or label
        if label:
            cx = (x1 + x2) // 2
            cy = (y1 + y2) // 2 - 10
            draw.text((cx - 8, cy), label, font=arrow_font, fill=(255, 255, 255))

    # Draw Obstacle blocks
    draw_block(2, 0, 2, True, (0, 180, 216), (128, 237, 255))
    draw_block(0, 0, 2, False, (114, 9, 183), (181, 23, 158))
    draw_block(3, 1, 3, True, (247, 127, 0), (252, 191, 73))
    draw_block(1, 4, 3, False, (16, 172, 132), (85, 239, 196))
    draw_block(0, 3, 2, True, (30, 144, 255), (135, 206, 250))
    draw_block(4, 4, 2, True, (100, 200, 255), (200, 240, 255), "❄")

    # HERO RED BLOCK with Cute Pet Face at (0, 2), length 2 pointing towards exit!
    hero_x1 = bx + 0 * cell_s + 4
    hero_y1 = by + 2 * cell_s + 4
    hero_x2 = hero_x1 + 2 * cell_s - 8
    hero_y2 = hero_y1 + cell_s - 8

    # Shadow & Base
    draw.rounded_rectangle([hero_x1, hero_y1 + 4, hero_x2, hero_y2 + 4], radius=12, fill=(10, 12, 18))
    draw.rounded_rectangle([hero_x1, hero_y1, hero_x2, hero_y2], radius=12, fill=(235, 45, 75))
    draw.rounded_rectangle([hero_x1 + 2, hero_y1 + 2, hero_x2 - 2, hero_y1 + 7], radius=4, fill=(255, 140, 160))

    # Cute Pet Ears & Face (like in user screenshot)
    face_cx = hero_x1 + 42
    face_cy = hero_y1 + 31
    # Ears
    draw.ellipse([face_cx - 20, face_cy - 18, face_cx - 8, face_cy - 6], fill=(180, 25, 50))
    draw.ellipse([face_cx + 8, face_cy - 18, face_cx + 20, face_cy - 6], fill=(180, 25, 50))
    # Eyes
    draw.ellipse([face_cx - 10, face_cy - 5, face_cx - 4, face_cy + 1], fill=(25, 10, 15))
    draw.ellipse([face_cx + 4, face_cy - 5, face_cx + 10, face_cy + 1], fill=(25, 10, 15))
    # Snout & Nose
    draw.ellipse([face_cx - 6, face_cy + 3, face_cx + 6, face_cy + 11], fill=(255, 200, 200))
    draw.ellipse([face_cx - 2, face_cy + 5, face_cx + 2, face_cy + 8], fill=(25, 10, 15))

    # Exit Arrow on right half of hero block
    arrow_cx = hero_x1 + 100
    draw.text((arrow_cx, hero_y1 + 12), "▶▶", font=arrow_font, fill=(255, 255, 255))
    
    # Path dots from Red block to exit
    for dot_x in [bx + 2 * cell_s + 35, bx + 3 * cell_s + 35, bx + 4 * cell_s + 35, bx + 5 * cell_s + 35]:
        draw.ellipse([dot_x - 5, by + 2 * cell_s + 30, dot_x + 5, by + 2 * cell_s + 40], fill=(255, 215, 0, 200))

    final_img = img.convert("RGB")
    final_img.save(out_path, quality=95)
    print("Updated Feature Graphic with Pet Hero:", out_path)

create_feature_graphic()
