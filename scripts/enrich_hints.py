"""
Enrich all 50 levels in levels/levels.json with rich, step-by-step hint data.
Every level gets a verified, human-readable hint_steps sequence with:
- step & total_steps
- block_id, is_target, color, color_name
- direction, target_dir, arrow
- delta, distance, from_pos, to_pos
- formatted instruction
"""

import json

COLOR_NAMES = {
    "#FF4757": "Red Block",
    "#00D2D3": "Cyan Block",
    "#FF9F43": "Amber Block",
    "#5F27CD": "Purple Block",
    "#10AC84": "Emerald Block",
    "#01A3A4": "Teal Block",
    "#E056FD": "Magenta Block",
    "#FF6B6B": "Coral Block",
    "#F368E0": "Hot Pink Block",
    "#54A0FF": "Blue Block",
    "#48DBFB": "Sky Blue Block",
    "#1DD1A1": "Mint Block",
    "#F8A5C2": "Pink Block",
    "#574B90": "Indigo Block",
    "#3DC1D3": "Aqua Block",
    "#E77F67": "Peach Block",
    "#A29BFE": "Lavender Block",
}

def enrich_levels():
    levels_path = r"d:\ColorSlide\levels\levels.json"
    with open(levels_path, "r", encoding="utf-8") as f:
        levels = json.load(f)

    print(f"Loaded {len(levels)} levels from {levels_path}")

    for lvl in levels:
        l_id = lvl["level_id"]
        title = lvl["title"]
        blocks_dict = {b["id"]: dict(b) for b in lvl["blocks"]}
        solution = lvl.get("solution_steps", [])
        total_steps = len(solution)

        hint_steps = []
        for idx, step in enumerate(solution):
            b_id = step["block_id"]
            if b_id not in blocks_dict:
                print(f"WARNING: Level {l_id} block {b_id} not found in blocks!")
                continue

            b = blocks_dict[b_id]
            is_target = b.get("is_target", False)
            color = b.get("color", "#FFFFFF")
            color_name = "Red Block" if is_target else COLOR_NAMES.get(color, "Block")

            direction = step["direction"]
            delta = step["delta"]
            dist = abs(delta)
            dist_str = "1 space" if dist == 1 else f"{dist} spaces"

            from_x = b["x"]
            from_y = b["y"]

            if direction == "horizontal":
                target_dir = "right" if delta > 0 else "left"
                arrow = "👉" if delta > 0 else "👈"
                to_x = from_x + delta
                to_y = from_y
                b["x"] = to_x
            else:
                target_dir = "down" if delta > 0 else "up"
                arrow = "👇" if delta > 0 else "👆"
                to_x = from_x
                to_y = from_y + delta
                b["y"] = to_y

            step_num = idx + 1
            if is_target and target_dir == "right" and to_x >= 4:
                instruction = f"Step {step_num}/{total_steps}: Clear! Slide Red Block 👉 into exit!"
            else:
                instruction = f"Step {step_num}/{total_steps}: Slide {color_name} {arrow} {target_dir} {dist_str}"

            hint_steps.append({
                "step": step_num,
                "total_steps": total_steps,
                "block_id": b_id,
                "is_target": is_target,
                "color": color,
                "color_name": color_name,
                "direction": direction,
                "target_dir": target_dir,
                "arrow": arrow,
                "delta": delta,
                "distance": dist,
                "from_x": from_x,
                "from_y": from_y,
                "to_x": to_x,
                "to_y": to_y,
                "instruction": instruction
            })

        lvl["hint_steps"] = hint_steps
        if l_id == 1:
            lvl["tutorial_steps"] = hint_steps

    with open(levels_path, "w", encoding="utf-8") as f:
        json.dump(levels, f, indent=2)

    print(f"Successfully enriched all {len(levels)} levels with step-by-step hint_steps!")

if __name__ == "__main__":
    enrich_levels()
