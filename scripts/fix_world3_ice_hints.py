import json
import sys

# Configure UTF-8 encoding
sys.stdout.reconfigure(encoding='utf-8')

LEVELS_PATH = "levels/levels.json"

COLOR_NAMES = {
    "#FF4757": "Red Block",
    "#FF6B6B": "Coral Block",
    "#FFA502": "Gold Block",
    "#FF9F43": "Amber Block",
    "#2ED573": "Green Block",
    "#10AC84": "Emerald Block",
    "#1DD1A1": "Mint Block",
    "#00D2D3": "Cyan Block",
    "#01A3A4": "Teal Block",
    "#54A0FF": "Blue Block",
    "#2E86DE": "Cobalt Block",
    "#5F27CD": "Violet Block",
    "#341F97": "Indigo Block",
    "#9B59B6": "Purple Block",
    "#E056FD": "Magenta Block",
    "#F368E0": "Hot Pink Block",
    "#747D8C": "Grey Block"
}

with open(LEVELS_PATH, "r", encoding="utf-8") as f:
    levels = json.load(f)

updated_count = 0

for lvl in levels:
    if lvl.get("world_id") != 3:
        continue

    blocks_dict = {b["id"]: dict(b) for b in lvl["blocks"]}
    frozen_ids = {b["id"] for b in lvl["blocks"] if b.get("is_frozen", False)}
    thawed_ids = set()

    solution = lvl.get("solution_steps", [])
    total_steps = len(solution)
    new_hint_steps = []

    for idx, step in enumerate(solution):
        b_id = step["block_id"]
        if b_id not in blocks_dict:
            continue

        b = blocks_dict[b_id]
        is_target = b.get("is_target", False)
        color = b.get("color", "#FFFFFF")
        c_name = "Red Block" if is_target else COLOR_NAMES.get(color, "Block")

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

        # Check thaw across all swept cells (from_cell through to_cell)
        min_x = min(from_x, to_x)
        max_x = max(from_x, to_x) + (b["length"] if direction == "horizontal" else 1)
        min_y = min(from_y, to_y)
        max_y = max(from_y, to_y) + (b["length"] if direction == "vertical" else 1)

        thawed_target = None
        for f_id in list(frozen_ids):
            if f_id != b_id and f_id not in thawed_ids:
                fb = blocks_dict[f_id]
                is_adj = False
                for fx in range(fb["x"], fb["x"] + (fb["length"] if fb.get("direction") == "horizontal" else 1)):
                    for fy in range(fb["y"], fb["y"] + (fb["length"] if fb.get("direction") == "vertical" else 1)):
                        for sx in range(min_x, max_x):
                            for sy in range(min_y, max_y):
                                if abs(sx - fx) + abs(sy - fy) == 1:
                                    is_adj = True
                                    break
                            if is_adj:
                                break
                        if is_adj:
                            break
                if is_adj:
                    thawed_ids.add(f_id)
                    thawed_target = COLOR_NAMES.get(fb.get("color"), "Block")
                    break

        if is_target and target_dir == "right" and to_x >= 4:
            instruction = f"Step {step_num}/{total_steps}: Clear! Slide Red Block 👉 into exit!"
        elif thawed_target:
            instruction = f"Step {step_num}/{total_steps}: Slide {c_name} {arrow} to melt {thawed_target} ice! ❄️"
        else:
            instruction = f"Step {step_num}/{total_steps}: Slide {c_name} {arrow} {target_dir} {dist_str}"

        new_hint_steps.append({
            "step": step_num,
            "total_steps": total_steps,
            "block_id": b_id,
            "is_target": is_target,
            "color": color,
            "color_name": c_name,
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

    lvl["hint_steps"] = new_hint_steps
    updated_count += 1

with open(LEVELS_PATH, "w", encoding="utf-8") as f:
    json.dump(levels, f, indent=2, ensure_ascii=False)

print(f"Successfully updated hints for {updated_count} World 3 levels!")
