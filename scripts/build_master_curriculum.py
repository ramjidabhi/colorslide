"""
Master Curriculum Generator for Color Escape: Slide Block Jam.
Implements the Mobile Retention Psychology Sawtooth Curve:
- Levels 1-10: Learn mechanics, instant competence, quick wins (2 to 5 moves)
- Levels 11-30: Some thinking required (6 to 9 moves)
- Levels 31-50: Planning required (10 to 14 moves)
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
    init_key = state_to_key(blocks)
    queue = deque()
    queue.append((init_key, [], [init_key]))
    visited = {init_key}

    target_idx = None
    for idx, b in enumerate(blocks):
        if b.is_target:
            target_idx = idx
            break

    win_x = BOARD_SIZE - blocks[target_idx].length

    while queue:
        curr_key, path, states = queue.popleft()

        for i, b in enumerate(blocks):
            b.x = curr_key[2 * i]
            b.y = curr_key[2 * i + 1]

        if blocks[target_idx].x == win_x:
            return path, states

        for i, b in enumerate(blocks):
            coord = b.x if b.direction == 'horizontal' else b.y

            # Backward
            for step in range(1, BOARD_SIZE):
                cand = coord - step
                if is_valid_pos(blocks, i, cand):
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
                if is_valid_pos(blocks, i, cand):
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

def get_onboarding_levels() -> List[Dict]:
    """
    Carefully designed onboarding levels 1 to 10 (2 to 5 moves).
    100% win rate, teaches mechanics, instant dopamine!
    """
    onboarding_defs = [
        # Level 1: Instant Win (2 moves: Slide cyan block down, slide red out!)
        {
            "id": 1,
            "title": "Slide & Escape",
            "difficulty": "Easy",
            "blocks": [
                Block("red", 2, 2, 2, "horizontal", "#FF4757", is_target=True),
                Block("v1", 4, 1, 2, "vertical", "#00D2D3"),
            ]
        },
        # Level 2: Slide Up (2 moves: Slide amber block up, slide red out!)
        {
            "id": 2,
            "title": "Clear Upwards",
            "difficulty": "Easy",
            "blocks": [
                Block("red", 1, 2, 2, "horizontal", "#FF4757", is_target=True),
                Block("v1", 3, 2, 2, "vertical", "#FF9F43"),
            ]
        },
        # Level 3: Two Blockers (3 moves: Clear purple, clear cyan, red escapes!)
        {
            "id": 3,
            "title": "Double Gate",
            "difficulty": "Easy",
            "blocks": [
                Block("red", 0, 2, 2, "horizontal", "#FF4757", is_target=True),
                Block("v1", 2, 1, 2, "vertical", "#00D2D3"),
                Block("v2", 3, 2, 2, "vertical", "#5F27CD"),
            ]
        },
        # Level 4: The Palate Cleanser Breather (3 moves: Gentle horizontal move)
        {
            "id": 4,
            "title": "Smooth Flow",
            "difficulty": "Easy",
            "blocks": [
                Block("red", 1, 2, 2, "horizontal", "#FF4757", is_target=True),
                Block("h1", 1, 0, 2, "horizontal", "#10AC84"),
                Block("v1", 3, 0, 3, "vertical", "#00D2D3"),
            ]
        },
        # Level 5: Mini Milestone (4 moves: First coordination)
        {
            "id": 5,
            "title": "First Shuffle",
            "difficulty": "Easy",
            "blocks": [
                Block("red", 0, 2, 2, "horizontal", "#FF4757", is_target=True),
                Block("v1", 2, 0, 2, "vertical", "#00D2D3"),
                Block("v2", 3, 1, 3, "vertical", "#5F27CD"),
                Block("h1", 3, 0, 2, "horizontal", "#FF9F43"),
            ]
        },
        # Level 6: Breather Level (3 moves: Fast rewarding win after Level 5!)
        {
            "id": 6,
            "title": "Breeze Way",
            "difficulty": "Easy",
            "blocks": [
                Block("red", 1, 2, 2, "horizontal", "#FF4757", is_target=True),
                Block("v1", 3, 1, 2, "vertical", "#00D2D3"),
                Block("h1", 0, 4, 3, "horizontal", "#FF9F43"),
            ]
        },
        # Level 7: The Crossway (4 moves)
        {
            "id": 7,
            "title": "The Crossway",
            "difficulty": "Easy",
            "blocks": [
                Block("red", 0, 2, 2, "horizontal", "#FF4757", is_target=True),
                Block("v1", 2, 1, 3, "vertical", "#00D2D3"),
                Block("h1", 2, 0, 2, "horizontal", "#FF9F43"),
                Block("h2", 0, 4, 2, "horizontal", "#10AC84"),
            ]
        },
        # Level 8: Corner Clean (4 moves)
        {
            "id": 8,
            "title": "Corner Clean",
            "difficulty": "Easy",
            "blocks": [
                Block("red", 1, 2, 2, "horizontal", "#FF4757", is_target=True),
                Block("v1", 3, 0, 2, "vertical", "#00D2D3"),
                Block("v2", 4, 2, 2, "vertical", "#5F27CD"),
                Block("h1", 0, 0, 2, "horizontal", "#FF9F43"),
            ]
        },
        # Level 9: The Gateway (5 moves: Final warm-up before Level 10)
        {
            "id": 9,
            "title": "The Gateway",
            "difficulty": "Easy",
            "blocks": [
                Block("red", 0, 2, 2, "horizontal", "#FF4757", is_target=True),
                Block("v1", 2, 0, 3, "vertical", "#00D2D3"),
                Block("v2", 3, 2, 2, "vertical", "#5F27CD"),
                Block("h1", 3, 1, 2, "horizontal", "#FF9F43"),
                Block("h2", 0, 3, 2, "horizontal", "#10AC84"),
            ]
        },
        # Level 10: Section 1 Mini-Boss (5 moves: Satisfying conclusion to onboarding!)
        {
            "id": 10,
            "title": "Mini-Boss: First Master",
            "difficulty": "Easy",
            "blocks": [
                Block("red", 0, 2, 2, "horizontal", "#FF4757", is_target=True),
                Block("v1", 2, 0, 2, "vertical", "#00D2D3"),
                Block("v2", 2, 3, 2, "vertical", "#5F27CD"),
                Block("v3", 3, 1, 3, "vertical", "#10AC84"),
                Block("h1", 3, 0, 2, "horizontal", "#FF9F43"),
                Block("h2", 3, 4, 2, "horizontal", "#01A3A4"),
            ]
        }
    ]

    verified = []
    for l_def in onboarding_defs:
        blocks = l_def["blocks"]
        path, _ = solve_with_states(blocks)
        moves = len(path)
        star3 = moves + 1 if moves <= 3 else moves + 2
        star2 = star3 + 3

        verified.append({
            "level_id": l_def["id"],
            "title": l_def["title"],
            "difficulty": l_def["difficulty"],
            "board_size": BOARD_SIZE,
            "optimal_moves": moves,
            "star_thresholds": { "3_stars": star3, "2_stars": star2 },
            "solution_steps": path,
            "blocks": [
                {
                    "id": b.id, "x": b.x, "y": b.y, "length": b.length,
                    "direction": b.direction, "color": b.color, "is_target": b.is_target
                }
                for b in blocks
            ]
        })

    return verified

def build_full_50_levels():
    # 1. Get Levels 1 to 10 (Onboarding)
    levels = get_onboarding_levels()
    print("Levels 1 to 10 (Onboarding 2-5 moves) verified.")
    for l in levels:
        print(f"  Level {l['level_id']:2d}: {l['optimal_moves']} moves - {l['title']}")

    # 2. Extract Levels 11 to 30 (6 to 9 moves with Sawtooth wave)
    # 3. Extract Levels 31 to 50 (10 to 14 moves with Sawtooth wave)
    db_path = r"d:\ColorSlide\scripts\rush1000.txt"
    pure_boards = []
    with open(db_path, "r", encoding="utf-8") as f:
        for line in f:
            parts = line.split()
            if len(parts) >= 2 and 'x' not in parts[1]:
                pure_boards.append((int(parts[0]), parts[1]))

    # Target Sawtooth move counts for Levels 11 to 50:
    # Notice the breathers: e.g. 6 -> 7 -> 6 -> 8 -> 7 -> 9...
    target_pattern = [
        # 11 - 20 (6 to 8 moves)
        6, 6, 7, 6, 7, 8, 7, 8, 8, 9,
        # 21 - 30 (7 to 9 moves)
        7, 8, 8, 9, 8, 9, 9, 8, 9, 10,
        # 31 - 40 (10 to 12 moves)
        10, 10, 11, 10, 11, 12, 11, 12, 12, 13,
        # 41 - 50 (11 to 14 moves)
        11, 12, 12, 13, 12, 13, 14, 13, 14, 15
    ]

    titles_2 = [
        # 11-20
        ("Alley Shift", "Medium"), ("Clear Path", "Medium"), ("Cross Traffic", "Medium"),
        ("Breather Lane", "Medium"), ("Corridor Switch", "Medium"), ("The Gate", "Medium"),
        ("Palate Cleanser", "Medium"), ("Downtown Shuffle", "Medium"), ("City Grid", "Medium"),
        ("Milestone 20", "Medium"),
        # 21-30
        ("Gentle Breeze", "Medium"), ("Double Shift", "Medium"), ("Central Avenue", "Medium"),
        ("The Loop", "Medium"), ("Easy Glide", "Medium"), ("Blockade Run", "Medium"),
        ("The Turnabout", "Medium"), ("Free Flow", "Medium"), ("Intersection", "Medium"),
        ("Section Boss 30", "Medium"),
        # 31-40
        ("Planning Entry", "Hard"), ("The Maze", "Hard"), ("Overpass Jam", "Hard"),
        ("Breather Rest", "Hard"), ("Tight Squeeze", "Hard"), ("The Gridlock", "Hard"),
        ("River Crossing", "Hard"), ("Double Park", "Hard"), ("Metropolis", "Hard"),
        ("Midpoint Challenge 40", "Hard"),
        # 41-50
        ("Calm Waters", "Hard"), ("Dependency Row", "Hard"), ("The Vault Entry", "Hard"),
        ("City Express", "Hard"), ("Rest Stop", "Hard"), ("The Iron Corridor", "Hard"),
        ("Grand Junction", "Hard"), ("Smooth Glide", "Hard"), ("The Labyrinth", "Hard"),
        ("Master Boss 50", "Hard")
    ]

    needed = len(target_pattern)
    matched_idx = set()

    for original_moves, board_str in pure_boards:
        blocks = parse_36_string(board_str)
        path, states = solve_with_states(blocks)
        if not path:
            continue

        total_steps = len(path)
        for k in range(total_steps):
            rem = total_steps - k
            for p_i in range(needed):
                if p_i in matched_idx:
                    continue
                if rem == target_pattern[p_i]:
                    matched_idx.add(p_i)
                    state_key = states[k]
                    level_blocks = []
                    for b_i, b in enumerate(blocks):
                        bx = state_key[2 * b_i]
                        by = state_key[2 * b_i + 1]
                        level_blocks.append(Block(b.id, bx, by, b.length, b.direction, b.color, b.is_target))

                    lvl_id = 11 + p_i
                    title, diff = titles_2[p_i]
                    star3 = rem + 2
                    star2 = star3 + 4

                    levels.append({
                        "order": lvl_id,
                        "level_id": lvl_id,
                        "title": title,
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
                    print(f" -> Level {lvl_id:2d}: {rem} moves [{diff}] '{title}'")

        if len(matched_idx) == needed:
            break

    # Sort
    levels.sort(key=lambda x: x["level_id"])
    for l in levels:
        if "order" in l:
            del l["order"]

    out_file = r"d:\ColorSlide\levels\levels.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(levels, f, indent=2)

    print(f"\nSUCCESS! Created {len(levels)} levels in {out_file} with psychological Sawtooth curve!")

if __name__ == "__main__":
    build_full_50_levels()
