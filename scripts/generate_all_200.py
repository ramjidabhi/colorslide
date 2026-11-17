"""
Complete 200-Level Roadmap Generator for Color Escape: Slide Block Jam.
Builds all 4 Worlds (50 levels each):
- World 1: Beginner Escape (Levels 1–50) [Classic Sliding & Foundations]
- World 2: Strategic Traffic Jam (Levels 51–100) [3-Cell Trucks, Deadlocks & Pullbacks]
- World 3: Frost Cavern (Levels 101–150) [Ice Locks & Thaw Mechanics]
- World 4: Laser Facility (Levels 151–200) [Floor Switches & Laser Barriers]
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

class Block:
    def __init__(self, block_id: str, x: int, y: int, length: int, direction: str, color: str, is_target: bool = False, is_frozen: bool = False):
        self.id = block_id
        self.x = x
        self.y = y
        self.length = length
        self.direction = direction
        self.color = color
        self.is_target = is_target
        self.is_frozen = is_frozen

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
    work_blocks = [Block(b.id, b.x, b.y, b.length, b.direction, b.color, b.is_target, b.is_frozen) for b in blocks]
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

def generate_hint_steps_for_level(lvl: dict) -> list:
    blocks_dict = {b["id"]: dict(b) for b in lvl["blocks"]}
    solution = lvl.get("solution_steps", [])
    total_steps = len(solution)
    hint_steps = []

    # Map of frozen block ids
    frozen_ids = {b["id"] for b in lvl["blocks"] if b.get("is_frozen", False)}
    thawed_ids = set()

    # Switches and lasers
    switches = lvl.get("switches", [])
    switch_positions = {(s["x"], s["y"]): s for s in switches}

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

        # Check special contextual instructions
        # 1. Switch trigger
        landed_on_switch = False
        for i in range(b.get("length", 2)):
            cx = to_x + (i if direction == "horizontal" else 0)
            cy = to_y + (i if direction == "vertical" else 0)
            if (cx, cy) in switch_positions:
                landed_on_switch = True
                break

        # 2. Ice thaw check
        thawed_target = None
        for f_id in frozen_ids:
            if f_id not in thawed_ids:
                fb = blocks_dict[f_id]
                # Check adjacency
                is_adj = False
                for i in range(b.get("length", 2)):
                    bx = to_x + (i if direction == "horizontal" else 0)
                    by = to_y + (i if direction == "vertical" else 0)
                    for j in range(fb.get("length", 2)):
                        fx = fb["x"] + (j if fb.get("direction") == "horizontal" else 0)
                        fy = fb["y"] + (j if fb.get("direction") == "vertical" else 0)
                        if abs(bx - fx) + abs(by - fy) == 1:
                            is_adj = True
                            break
                    if is_adj:
                        break
                if is_adj:
                    thawed_ids.add(f_id)
                    thawed_target = COLOR_NAMES.get(fb.get("color"), "Block")
                    break

        if is_target and target_dir == "right" and to_x >= 4:
            instruction = f"Step {step_num}/{total_steps}: Clear! Slide Red Block 👉 into exit!"
        elif landed_on_switch:
            instruction = f"Step {step_num}/{total_steps}: Slide {c_name} onto Switch ⚡ to deactivate laser!"
        elif thawed_target:
            instruction = f"Step {step_num}/{total_steps}: Slide {c_name} {arrow} to melt {thawed_target} ice! ❄️"
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

    return hint_steps

def build_all_200_levels():
    print("==================================================")
    print(">>> BUILDING COLOR ESCAPE: COMPLETE 200 LEVELS <<<")
    print("==================================================")

    # 1. Load existing World 1 (Levels 1 to 50)
    with open(r"d:\ColorSlide\levels\levels.json", "r", encoding="utf-8") as f:
        existing_w1 = json.load(f)[:50]

    all_levels = list(existing_w1)
    print(f"Loaded {len(all_levels)} levels for World 1: Beginner Escape.")

    # Load authentic rush boards
    db_path = r"d:\ColorSlide\scripts\rush1000.txt"
    with open(db_path, "r", encoding="utf-8") as f:
        pure_boards = [l.strip().split()[1] for l in f if len(l.strip().split()) >= 2 and 'x' not in l.strip().split()[1]]

    # ------------------ WORLD 2: Strategic Traffic Jam (Levels 51–100) ------------------
    print("\n>>> Building World 2: Strategic Traffic Jam (Levels 51–100)...")
    w2_brackets = [
        # 51-60: Tight Parking (15-17 moves)
        (51, 60, "Normal+", "Tight Parking", [15, 15, 16, 16, 16, 17, 17, 17, 17, 17],
         ["Tight Lot", "Cargo Weave", "Parking Grid", "Express Turn", "Twin Haul", "Double Cross", "Delivery Shift", "Alley Exit", "Freight Jam", "Milestone 60"]),
        # 61-70: The Two-Lane Weave (17-19 moves)
        (61, 70, "Medium", "The Two-Lane Weave", [17, 18, 18, 18, 18, 19, 19, 19, 19, 19],
         ["Twin Lanes", "Side Bypass", "Transit Lock", "Divided Way", "The Concourse", "Cross Street", "Dual Shifter", "Outer Loop", "Traffic Pivot", "Milestone 70"]),
        # 71-80: Counter-Intuitive Shifts (19-21 moves)
        (71, 80, "Medium+", "Counter-Intuitive Shifts", [19, 20, 20, 20, 20, 21, 21, 21, 21, 21],
         ["Backtrack Pass", "Reverse Gear", "The Detour", "Sacrifice Slot", "Pocket Shift", "Turning Bay", "Rear Maneuver", "Deadlock Retreat", "Counter Play", "Milestone 80"]),
        # 81-90: Highway Gridlock (21-23 moves)
        (81, 90, "Hard", "Highway Gridlock", [21, 22, 22, 22, 22, 23, 23, 23, 23, 23],
         ["Rush Hour", "Beltway Jam", "Expressway Standstill", "Interstate Lock", "Rotary Standoff", "Bumper to Bumper", "Central Gridlock", "Flyover Weave", "Overpass Jam", "Milestone 90"]),
        # 91-100: Grandmaster Prep & Level 100 Boss (23-25 moves)
        (91, 100, "Boss", "Strategic Boss Jam", [23, 24, 24, 24, 24, 24, 25, 25, 25, 25],
         ["Grandmaster I", "Grandmaster II", "Precision Pivot", "Clockwork Shuffle", "The Iron Maze", "Hourglass Shift", "Titan Weave", "The Master Lock", "Apex Standoff", "World Boss: Grand Central Jam"])
    ]

    target_w2 = []
    for s_l, e_l, diff, sub_cat, moves_l, titles_l in w2_brackets:
        for idx in range(len(moves_l)):
            target_w2.append((s_l + idx, diff, sub_cat, moves_l[idx], titles_l[idx]))

    matched_w2 = set()
    for b_idx, b_str in enumerate(pure_boards):
        blocks = parse_36_string(b_str)
        path, states = solve_with_states(blocks)
        if not path:
            continue

        tot = len(path)
        for k in range(tot):
            rem = tot - k
            for t_i, (l_num, diff, sub_cat, m_target, t_name) in enumerate(target_w2):
                if t_i in matched_w2:
                    continue
                if rem == m_target:
                    matched_w2.add(t_i)
                    state_key = states[k]
                    level_blocks = []
                    for b_i, b in enumerate(blocks):
                        bx = state_key[2 * b_i]
                        by = state_key[2 * b_i + 1]
                        level_blocks.append(Block(b.id, bx, by, b.length, b.direction, b.color, b.is_target))

                    lvl_dict = {
                        "level_id": l_num,
                        "world_id": 2,
                        "world_name": "Strategic Traffic Jam",
                        "sub_category": sub_cat,
                        "title": t_name,
                        "difficulty": diff,
                        "board_size": BOARD_SIZE,
                        "optimal_moves": rem,
                        "solution_steps": path[k:],
                        "blocks": [
                            {
                                "id": b.id, "x": b.x, "y": b.y, "length": b.length,
                                "direction": b.direction, "color": b.color, "is_target": b.is_target,
                                "is_frozen": False
                            }
                            for b in level_blocks
                        ]
                    }
                    lvl_dict["hint_steps"] = generate_hint_steps_for_level(lvl_dict)
                    all_levels.append(lvl_dict)
                    print(f"  Level {l_num:3d} [World 2]: {rem} moves [{diff}] '{t_name}'")

        if len(matched_w2) == len(target_w2):
            break

    # ------------------ WORLD 3: Frost Cavern (Levels 101–150) ------------------
    print("\n>>> Building World 3: Frost Cavern (Levels 101–150)...")
    w3_brackets = [
        # 101-110: Frost Introduction (18-20 moves, 1 ice block)
        (101, 110, "Medium-Hard", "Frost Introduction", [18, 18, 18, 19, 19, 19, 20, 20, 20, 20],
         ["First Frost", "Icy Corridor", "Frozen Lock", "Glacial Path", "Crystal Drift", "Cold Shoulder", "Arctic Threshold", "Frost Shifter", "Winter Gate", "Milestone 110"]),
        # 111-120: Thaw Sequences (20-22 moves)
        (111, 120, "Hard", "Thaw Sequences", [20, 20, 21, 21, 21, 21, 22, 22, 22, 22],
         ["Warm Touch", "Thaw Sequence", "Icebreaker", "Thermal Pivot", "Defrosting Lane", "Melting Point", "Steam Channel", "Spring Thaw", "Heat Wave", "Milestone 120"]),
        # 121-130: Twin Freeze (22-24 moves, 2 ice blocks)
        (121, 130, "Hard+", "Twin Freeze", [22, 22, 23, 23, 23, 23, 24, 24, 24, 24],
         ["Twin Glaciers", "Double Frost", "Sub-Zero Standoff", "Frozen Twin", "Bipolar Ice", "Polar Jam", "Deep Permafrost", "Frostbite Chamber", "Zero Kelvin", "Milestone 130"]),
        # 131-140: Frozen Corridors (24-26 moves)
        (131, 140, "Very Hard", "Frozen Corridors", [24, 24, 25, 25, 25, 25, 26, 26, 26, 26],
         ["The Blizzard", "Avalanche Pass", "Whiteout Weave", "Frost Wall", "Sleet Alley", "Crystalline Vault", "Ice Cavern Core", "Glacier Rift", "Frostbite Ridge", "Milestone 140"]),
        # 141-150: Expert Frost & Level 150 Boss (26-28 moves)
        (141, 150, "Boss", "Frost Master & Cryo Vault", [26, 26, 27, 27, 27, 27, 28, 28, 28, 28],
         ["Cryogenic Lab", "Absolute Zero", "Borealis Drift", "Frost Giant", "The Chill Factor", "Ice Core Alpha", "Glacial Abyss", "Cryo Matrix", "Polar Summit", "World Boss: The Cryo Vault"])
    ]

    target_w3 = []
    for s_l, e_l, diff, sub_cat, moves_l, titles_l in w3_brackets:
        for idx in range(len(moves_l)):
            target_w3.append((s_l + idx, diff, sub_cat, moves_l[idx], titles_l[idx]))

    matched_w3 = set()
    for b_idx in range(len(pure_boards) - 1, -1, -1):
        b_str = pure_boards[b_idx]
        blocks = parse_36_string(b_str)
        path, states = solve_with_states(blocks)
        if not path:
            continue

        tot = len(path)
        for k in range(tot):
            rem = tot - k
            for t_i, (l_num, diff, sub_cat, m_target, t_name) in enumerate(target_w3):
                if t_i in matched_w3:
                    continue
                if rem == m_target:
                    matched_w3.add(t_i)
                    state_key = states[k]
                    level_blocks = []
                    for b_i, b in enumerate(blocks):
                        bx = state_key[2 * b_i]
                        by = state_key[2 * b_i + 1]
                        level_blocks.append(Block(b.id, bx, by, b.length, b.direction, b.color, b.is_target))

                    # Freeze 1 or 2 blocks that move later in the sequence
                    num_frozen = 1 if l_num <= 120 else (2 if l_num < 150 else 3)
                    rem_path = path[k:]
                    moved_block_order = []
                    for s in rem_path:
                        if s["block_id"] != "a" and s["block_id"] not in moved_block_order:
                            moved_block_order.append(s["block_id"])

                    # Pick frozen blocks from later half of moves
                    frozen_candidates = set(moved_block_order[len(moved_block_order)//2 : len(moved_block_order)//2 + num_frozen])

                    block_dicts = []
                    for b in level_blocks:
                        is_fr = (b.id in frozen_candidates) and not b.is_target
                        block_dicts.append({
                            "id": b.id, "x": b.x, "y": b.y, "length": b.length,
                            "direction": b.direction, "color": b.color, "is_target": b.is_target,
                            "is_frozen": is_fr
                        })

                    lvl_dict = {
                        "level_id": l_num,
                        "world_id": 3,
                        "world_name": "Frost Cavern",
                        "sub_category": sub_cat,
                        "title": t_name,
                        "difficulty": diff,
                        "board_size": BOARD_SIZE,
                        "optimal_moves": rem,
                        "solution_steps": rem_path,
                        "blocks": block_dicts
                    }
                    lvl_dict["hint_steps"] = generate_hint_steps_for_level(lvl_dict)
                    all_levels.append(lvl_dict)
                    print(f"  Level {l_num:3d} [World 3]: {rem} moves [{diff}] '{t_name}' (Frozen: {len(frozen_candidates)})")

        if len(matched_w3) == len(target_w3):
            break

    # ------------------ WORLD 4: Laser Facility (Levels 151–200) ------------------
    print("\n>>> Building World 4: Laser Facility (Levels 151–200)...")
    w4_brackets = [
        # 151-160: Switch Onboarding (22-24 moves, single switch)
        (151, 160, "Hard", "Switch Onboarding", [22, 22, 23, 23, 23, 23, 24, 24, 24, 24],
         ["Laser Lane", "Pressure Plate", "High Voltage", "Power Terminal", "Relay Switch", "Circuit Gate", "Laser Corridor", "Capacitor Loop", "Red Line", "Milestone 160"]),
        # 161-170: Holding the Gate (24-27 moves)
        (161, 170, "Very Hard", "Holding the Gate", [24, 25, 25, 25, 26, 26, 26, 27, 27, 27],
         ["Gatekeeper", "Holding Pattern", "Laser Barrier", "Terminal Shift", "Switch Anchor", "Power Conduit", "Grid Interlock", "Laser Mesh", "Hazard Trench", "Milestone 170"]),
        # 171-180: Advanced Terminals (27-29 moves)
        (171, 180, "Very Hard+", "Advanced Terminals", [27, 27, 28, 28, 28, 28, 29, 29, 29, 29],
         ["Dual Circuit", "Flux Capacitor", "Overload Gate", "Cyber Relay", "Neon Fence", "Photon Barrier", "Electrode Pass", "Terminal Maze", "Power Station", "Milestone 180"]),
        # 181-190: High-Tech Deadlocks (29-31 moves)
        (181, 190, "Extreme", "High-Tech Deadlocks", [29, 30, 30, 30, 30, 31, 31, 31, 31, 31],
         ["Matrix Grid", "Laser Labyrinth", "Quantum Lock", "Fusion Core", "Superconductor", "Laser Standoff", "Plasma Barrier", "Defense Grid", "Shield Relay", "Milestone 190"]),
        # 191-200: Master Lasers & Level 200 Boss (31-34 moves)
        (191, 200, "Boss", "Facility Master & Omega Lockdown", [31, 32, 32, 32, 33, 33, 33, 34, 34, 34],
         ["Reactor Core", "Sub-Atomic Weave", "Laser Lockdown", "Circuit Breaker", "Cyber Citadel", "Omega Relay", "Laser Singularity", "The Core Threshold", "Final Security Gate", "World Boss: Omega Lockdown"])
    ]

    target_w4 = []
    for s_l, e_l, diff, sub_cat, moves_l, titles_l in w4_brackets:
        for idx in range(len(moves_l)):
            target_w4.append((s_l + idx, diff, sub_cat, moves_l[idx], titles_l[idx]))

    matched_w4 = set()
    for b_idx in range(50, len(pure_boards)):
        b_str = pure_boards[b_idx]
        blocks = parse_36_string(b_str)
        path, states = solve_with_states(blocks)
        if not path:
            continue

        tot = len(path)
        for k in range(tot):
            rem = tot - k
            for t_i, (l_num, diff, sub_cat, m_target, t_name) in enumerate(target_w4):
                if t_i in matched_w4:
                    continue
                if rem == m_target:
                    matched_w4.add(t_i)
                    state_key = states[k]
                    level_blocks = []
                    for b_i, b in enumerate(blocks):
                        bx = state_key[2 * b_i]
                        by = state_key[2 * b_i + 1]
                        level_blocks.append(Block(b.id, bx, by, b.length, b.direction, b.color, b.is_target))

                    rem_path = path[k:]
                    # Place a switch at a key resting position of an intermediate block
                    switch_pos = {"x": 1, "y": 4}
                    if len(rem_path) >= 3:
                        # Find an intermediate move's landing cell
                        mid_step = rem_path[len(rem_path) // 2]
                        mid_b = None
                        for b in level_blocks:
                            if b.id == mid_step["block_id"]:
                                mid_b = b
                                break
                        if mid_b:
                            if mid_step["direction"] == "horizontal":
                                switch_pos = {"x": mid_step["to"], "y": mid_b.y}
                            else:
                                switch_pos = {"x": mid_b.x, "y": mid_step["to"]}

                    switches = [{"id": "sw1", "x": switch_pos["x"], "y": switch_pos["y"], "laser_id": "laser1"}]
                    lasers = [{"id": "laser1", "x": 4, "y": 2, "switch_id": "sw1"}]

                    lvl_dict = {
                        "level_id": l_num,
                        "world_id": 4,
                        "world_name": "Laser Facility",
                        "sub_category": sub_cat,
                        "title": t_name,
                        "difficulty": diff,
                        "board_size": BOARD_SIZE,
                        "optimal_moves": rem,
                        "switches": switches,
                        "lasers": lasers,
                        "solution_steps": rem_path,
                        "blocks": [
                            {
                                "id": b.id, "x": b.x, "y": b.y, "length": b.length,
                                "direction": b.direction, "color": b.color, "is_target": b.is_target,
                                "is_frozen": False
                            }
                            for b in level_blocks
                        ]
                    }
                    lvl_dict["hint_steps"] = generate_hint_steps_for_level(lvl_dict)
                    all_levels.append(lvl_dict)
                    print(f"  Level {l_num:3d} [World 4]: {rem} moves [{diff}] '{t_name}' (Switch: {switch_pos})")

        if len(matched_w4) == len(target_w4):
            break

    # Sort all 200 levels
    all_levels.sort(key=lambda x: x["level_id"])

    out_file = r"d:\ColorSlide\levels\levels.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(all_levels, f, indent=2)

    print(f"\n==================================================")
    print(f"SUCCESS: ALL {len(all_levels)} LEVELS GENERATED AND ENRICHED!")
    print(f"  World 1 (1–50)   : Beginner Escape")
    print(f"  World 2 (51–100)  : Strategic Traffic Jam")
    print(f"  World 3 (101–150) : Frost Cavern (Ice Locks)")
    print(f"  World 4 (151–200) : Laser Facility (Switches & Laser Barriers)")
    print(f"Saved to: {out_file}")
    print(f"==================================================")

if __name__ == "__main__":
    build_all_200_levels()
