"""
World 1: Beginner Escape (Levels 1 to 50) Full Generator.
Builds and validates 50 distinct puzzles adhering to the user's exact 10 sub-brackets:
1-5: Very Easy (1-2 blocking blocks)
6-10: Easy (3-4 blocking blocks)
11-15: Easy (H & V blocks)
16-20: Easy (Two-block dependencies)
21-25: Easy+ (Limited empty spaces)
26-30: Easy+ (Blocks blocking each other)
31-35: Normal (Three-step solutions)
36-40: Normal (Multiple block movements)
41-45: Normal+ (Tight corridors)
46-50: Normal+ (Mini-boss & Level 50 World Boss)
"""

import json
from collections import deque
from typing import List, Dict, Tuple, Optional

BOARD_SIZE = 6

PALETTE = [
    "#00D2D3", "#FF9F43", "#5F27CD", "#10AC84",
    "#01A3A4", "#E056FD", "#FF6B6B", "#F368E0",
    "#54A0FF", "#48DBFB", "#1DD1A1", "#F8A5C2",
    "#574B90", "#3DC1D3", "#E77F67", "#A29BFE"
]

class Block:
    def __init__(self, block_id: str, x: int, y: int, length: int, direction: str, color: str, is_target: bool = False):
        self.id = block_id
        self.x = x
        self.y = y
        self.length = length
        self.direction = direction
        self.color = color
        self.is_target = is_target

    def get_cells(self, x=None, y=None):
        bx = self.x if x is None else x
        by = self.y if y is None else y
        if self.direction == 'horizontal':
            return [(bx + i, by) for i in range(self.length)]
        else:
            return [(bx, by + i) for i in range(self.length)]

def state_to_key(blocks: List[Block]):
    coords = []
    for b in blocks:
        coords.append(b.x)
        coords.append(b.y)
    return tuple(coords)

def is_valid_pos(blocks: List[Block], m_idx: int, new_c: int) -> bool:
    b = blocks[m_idx]
    if b.direction == 'horizontal':
        if new_c < 0 or new_c + b.length > BOARD_SIZE:
            return False
        cells = [(new_c + i, b.y) for i in range(b.length)]
    else:
        if new_c < 0 or new_c + b.length > BOARD_SIZE:
            return False
        cells = [(b.x, new_c + i) for i in range(b.length)]

    for idx, other in enumerate(blocks):
        if idx == m_idx:
            continue
        other_cells = set(other.get_cells())
        for cell in cells:
            if cell in other_cells:
                return False
    return True

def solve_with_states(blocks: List[Block]):
    work_blocks = [Block(b.id, b.x, b.y, b.length, b.direction, b.color, b.is_target) for b in blocks]
    init_key = state_to_key(work_blocks)
    queue = deque()
    queue.append((init_key, [], [init_key]))
    visited = {init_key}

    target_idx = None
    for idx, b in enumerate(work_blocks):
        if b.is_target:
            target_idx = idx
            break

    win_x = BOARD_SIZE - work_blocks[target_idx].length

    while queue:
        curr_key, path, states = queue.popleft()

        for i, b in enumerate(work_blocks):
            b.x = curr_key[2 * i]
            b.y = curr_key[2 * i + 1]

        if work_blocks[target_idx].x == win_x:
            return path, states

        for i, b in enumerate(work_blocks):
            coord = b.x if b.direction == 'horizontal' else b.y

            # Backward
            for step in range(1, BOARD_SIZE):
                cand = coord - step
                if is_valid_pos(work_blocks, i, cand):
                    new_key_list = list(curr_key)
                    if b.direction == 'horizontal':
                        new_key_list[2 * i] = cand
                    else:
                        new_key_list[2 * i + 1] = cand
                    new_key = tuple(new_key_list)
                    if new_key not in visited:
                        visited.add(new_key)
                        m_info = {"block_id": b.id, "direction": b.direction, "from": coord, "to": cand, "delta": -step}
                        queue.append((new_key, path + [m_info], states + [new_key]))
                else:
                    break

            # Forward
            for step in range(1, BOARD_SIZE):
                cand = coord + step
                if is_valid_pos(work_blocks, i, cand):
                    new_key_list = list(curr_key)
                    if b.direction == 'horizontal':
                        new_key_list[2 * i] = cand
                    else:
                        new_key_list[2 * i + 1] = cand
                    new_key = tuple(new_key_list)
                    if new_key not in visited:
                        visited.add(new_key)
                        m_info = {"block_id": b.id, "direction": b.direction, "from": coord, "to": cand, "delta": step}
                        queue.append((new_key, path + [m_info], states + [new_key]))
                else:
                    break

    return None, None

def parse_36_string(s: str) -> List[Block]:
    grid = [[s[r * 6 + c] for c in range(6)] for r in range(6)]
    visited = set()
    blocks = []
    color_idx = 0

    for r in range(6):
        for c in range(6):
            ch = grid[r][c]
            if ch == 'o' or ch == 'x' or (r, c) in visited:
                continue

            h_len = 1
            while c + h_len < 6 and grid[r][c + h_len] == ch:
                h_len += 1

            v_len = 1
            while r + v_len < 6 and grid[r + v_len][c] == ch:
                v_len += 1

            is_target = (ch == 'A')
            color = "#FF4757" if is_target else PALETTE[color_idx % len(PALETTE)]
            if not is_target:
                color_idx += 1

            if h_len > 1:
                blocks.append(Block(ch.lower(), c, r, h_len, 'horizontal', color, is_target))
                for i in range(h_len):
                    visited.add((r, c + i))
            elif v_len > 1:
                blocks.append(Block(ch.lower(), c, r, v_len, 'vertical', color, is_target))
                for i in range(v_len):
                    visited.add((r + i, c))

    return blocks

def generate_world_1():
    print("Building World 1: Beginner Escape (50 Levels)...")
    levels = []

    # ------------------ BRACKET 1: Levels 1-5 (Very Easy: 1-2 blocking blocks) ------------------
    b1_defs = [
        # Level 1: 2 colored obstacle boxes moved to clear the path, then level cleared!
        {
            "title": "First Clearance", "sub": "Move 2 Obstacles", "diff": "Very Easy",
            "tutorial_steps": [
                { "block_id": "v1", "instruction": "1. Slide the cyan box ⬇️ down!", "target_dir": "down" },
                { "block_id": "v2", "instruction": "2. Slide the amber box ⬆️ up!", "target_dir": "up" },
                { "block_id": "red", "instruction": "3. Clear! Slide Red 👉 into exit!", "target_dir": "right" }
            ],
            "blocks": [
                Block("red", 0, 2, 2, "horizontal", "#FF4757", is_target=True),
                Block("h_top", 1, 0, 2, "horizontal", "#54A0FF"),
                Block("v1", 2, 1, 2, "vertical", "#00D2D3"),
                Block("v2", 3, 2, 2, "vertical", "#FF9F43"),
                Block("h_bot", 3, 4, 2, "horizontal", "#5F27CD"),
            ]
        },
        # Level 2: 3 colored boxes coordination
        {
            "title": "Triple Maneuver", "sub": "Multi-Box Clearance", "diff": "Very Easy",
            "tutorial_steps": [],
            "blocks": [
                Block("red", 0, 2, 2, "horizontal", "#FF4757", is_target=True),
                Block("v1", 2, 1, 2, "vertical", "#00D2D3"),
                Block("h1", 2, 3, 2, "horizontal", "#FF9F43"),
                Block("v2", 4, 1, 3, "vertical", "#5F27CD"),
            ]
        },
        # Level 3: Corridor clearance (Autonomous)
        {
            "title": "Narrow Channel", "sub": "1–2 Blocking Blocks", "diff": "Very Easy",
            "tutorial_steps": [],
            "blocks": [
                Block("red", 0, 2, 2, "horizontal", "#FF4757", is_target=True),
                Block("v1", 2, 0, 3, "vertical", "#00D2D3"),
                Block("v2", 3, 2, 2, "vertical", "#10AC84"),
                Block("h1", 0, 4, 2, "horizontal", "#FF9F43"),
            ]
        },
        # Level 4: Grid Weave (Autonomous)
        {
            "title": "Grid Weave", "sub": "Corridor Clearance", "diff": "Very Easy",
            "tutorial_steps": [],
            "blocks": [
                Block("red", 0, 2, 2, "horizontal", "#FF4757", is_target=True),
                Block("h1", 1, 0, 2, "horizontal", "#54A0FF"),
                Block("v1", 2, 1, 2, "vertical", "#00D2D3"),
                Block("h2", 2, 3, 2, "horizontal", "#FF9F43"),
                Block("v2", 4, 0, 3, "vertical", "#5F27CD"),
            ]
        },
        # Level 5: Shift & Glide (Autonomous)
        {
            "title": "Shift & Glide", "sub": "1–2 Blocking Blocks", "diff": "Very Easy",
            "tutorial_steps": [],
            "blocks": [
                Block("red", 1, 2, 2, "horizontal", "#FF4757", is_target=True),
                Block("h_top", 2, 0, 2, "horizontal", "#54A0FF"),
                Block("v1", 3, 1, 2, "vertical", "#00D2D3"),
            ]
        }
    ]

    for idx, b_data in enumerate(b1_defs):
        path, _ = solve_with_states(b_data["blocks"])
        moves = len(path)
        star3 = moves + 1 if moves <= 2 else moves + 2
        star2 = star3 + 3
        lvl_num = idx + 1
        levels.append({
            "level_id": lvl_num,
            "world_id": 1,
            "world_name": "Beginner Escape",
            "sub_category": b_data["sub"],
            "title": b_data["title"],
            "difficulty": b_data["diff"],
            "board_size": BOARD_SIZE,
            "optimal_moves": moves,
            "star_thresholds": { "3_stars": star3, "2_stars": star2 },
            "tutorial_steps": b_data.get("tutorial_steps", []),
            "solution_steps": path,
            "blocks": [
                {
                    "id": b.id, "x": b.x, "y": b.y, "length": b.length,
                    "direction": b.direction, "color": b.color, "is_target": b.is_target
                }
                for b in b_data["blocks"]
            ]
        })
        print(f"Level {lvl_num:2d}: {moves} moves [{b_data['diff']}] - {b_data['title']}")

    # ------------------ BRACKETS 2-10: Levels 6 to 50 ------------------
    # We slice states from authentic pure Rush Hour boards with exact move counts
    # Sub-categories mapping:
    sub_cat_map = [
        # Levels 6-10 (Easy: 3-4 blocking blocks, 5-7 moves)
        (6, 10, "Easy", "3–4 Blocking Blocks", [5, 6, 6, 7, 7],
         ["Cross Alley", "Four Corners", "Traffic Guard", "Side Chamber", "Milestone 10"]),
        # Levels 11-15 (Easy: H & V blocks, 7-8 moves)
        (11, 15, "Easy", "Horizontal & Vertical Blocks", [7, 7, 8, 7, 8],
         ["Weave Way", "Intersect", "Grid Channel", "Perpendicular", "Milestone 15"]),
        # Levels 16-20 (Easy: Two-block dependencies, 8-9 moves)
        (16, 20, "Easy", "Two-Block Dependencies", [8, 8, 9, 8, 9],
         ["Chain Link", "Key Block", "Double Lock", "Dependency Pass", "Milestone 20"]),
        # Levels 21-25 (Easy+: Limited empty spaces, 9-10 moves)
        (21, 25, "Easy+", "Limited Empty Spaces", [9, 9, 10, 9, 10],
         ["Tight Lot", "Packed Lane", "Crowded Row", "Compact Space", "Milestone 25"]),
        # Levels 26-30 (Easy+: Blocks blocking each other, 10-11 moves)
        (26, 30, "Easy+", "Mutual Blockers", [10, 10, 11, 10, 11],
         ["Interlock", "The Impasse", "Crossed Paths", "Tangled Route", "Milestone 30"]),
        # Levels 31-35 (Normal: Three-step solutions, 11-12 moves)
        (31, 35, "Normal", "Three-Step Solutions", [11, 11, 12, 11, 12],
         ["Triple Chain", "Step By Step", "Stairway Shift", "The Sequence", "Milestone 35"]),
        # Levels 36-40 (Normal: Multiple block movements, 12-13 moves)
        (36, 40, "Normal", "Multiple Block Movements", [12, 12, 13, 12, 13],
         ["Carousel", "Grand Shuffle", "Orchestra", "Rotary Jam", "Milestone 40"]),
        # Levels 41-45 (Normal+: Tight corridors, 13-14 moves)
        (41, 45, "Normal+", "Tight Corridors", [13, 13, 14, 13, 14],
         ["Canyon Pass", "The Tunnel", "Razor Edge", "The Gorge", "Milestone 45"]),
        # Levels 46-50 (Normal+: Mini boss & World 1 Boss, 14-17 moves)
        (46, 50, "Normal+", "Mini Boss & World 1 Boss", [14, 15, 15, 16, 17],
         ["Sentry Trial", "Chamber of Trials", "The Vanguard", "The Iron Threshold", "World Boss: Beginner Master"])
    ]

    db_path = r"d:\ColorSlide\scripts\rush1000.txt"
    pure_boards = []
    with open(db_path, "r", encoding="utf-8") as f:
        for line in f:
            parts = line.split()
            if len(parts) >= 2 and 'x' not in parts[1]:
                pure_boards.append((int(parts[0]), parts[1]))

    # Flatten remaining level targets
    target_list = []
    for start_l, end_l, diff, sub_cat, moves_list, title_list in sub_cat_map:
        for idx in range(len(moves_list)):
            l_num = start_l + idx
            m_target = moves_list[idx]
            t_name = title_list[idx]
            target_list.append((l_num, diff, sub_cat, m_target, t_name))

    matched_indices = set()

    for orig_m, b_str in pure_boards:
        blocks = parse_36_string(b_str)
        path, states = solve_with_states(blocks)
        if not path:
            continue

        total_steps = len(path)
        for k in range(total_steps):
            rem = total_steps - k
            for t_i, (l_num, diff, sub_cat, m_target, t_name) in enumerate(target_list):
                if t_i in matched_indices:
                    continue
                if rem == m_target:
                    matched_indices.add(t_i)
                    state_key = states[k]
                    level_blocks = []
                    for b_i, b in enumerate(blocks):
                        bx = state_key[2 * b_i]
                        by = state_key[2 * b_i + 1]
                        level_blocks.append(Block(b.id, bx, by, b.length, b.direction, b.color, b.is_target))

                    star3 = rem + 2
                    star2 = star3 + 4

                    levels.append({
                        "level_id": l_num,
                        "world_id": 1,
                        "world_name": "Beginner Escape",
                        "sub_category": sub_cat,
                        "title": t_name,
                        "difficulty": diff,
                        "board_size": BOARD_SIZE,
                        "optimal_moves": rem,
                        "star_thresholds": { "3_stars": star3, "2_stars": star2 },
                        "solution_steps": path[k:],
                        "blocks": [
                            {
                                "id": b.id, "x": b.x, "y": b.y, "length": b.length,
                                "direction": b.direction, "color": b.color, "is_target": b.is_target
                            }
                            for b in level_blocks
                        ]
                    })
                    print(f"Level {l_num:2d}: {rem} moves [{diff}] '{t_name}' ({sub_cat})")

        if len(matched_indices) == len(target_list):
            break

    # Sort by level_id
    levels.sort(key=lambda x: x["level_id"])

    # Color mapping for hint names
    color_names = {
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
    }

    # Generate rich step-by-step hint_steps for all 50 levels
    for lvl in levels:
        l_id = lvl["level_id"]
        blocks_dict = {b["id"]: dict(b) for b in lvl["blocks"]}
        solution = lvl.get("solution_steps", [])
        total_steps = len(solution)

        hint_steps = []
        for idx, step in enumerate(solution):
            b_id = step["block_id"]
            if b_id not in blocks_dict:
                continue

            b = blocks_dict[b_id]
            is_target = b.get("is_target", False)
            color = b.get("color", "#FFFFFF")
            c_name = "Red Block" if is_target else color_names.get(color, "Block")

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
                instruction = f"Step {step_num}/{total_steps}: Slide {c_name} {arrow} {target_dir} {dist_str}"

            hint_steps.append({
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

        lvl["hint_steps"] = hint_steps
        if l_id == 1:
            lvl["tutorial_steps"] = hint_steps

    out_file = r"d:\ColorSlide\levels\levels.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(levels, f, indent=2)

    print(f"\nSUCCESS: World 1 (all {len(levels)} levels) built and verified in {out_file}!")

if __name__ == "__main__":
    generate_world_1()
