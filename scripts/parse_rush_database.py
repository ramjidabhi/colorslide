"""
Extracts progressive difficulty puzzles from the authentic Rush database.
Parses 36-char strings, computes solutions, and slices states to create
a flawless 20-level difficulty curve (from 5 moves up to 40 moves).
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
    """Converts 36-char string into list of Block objects."""
    grid = [[s[r * 6 + c] for c in range(6)] for r in range(6)]
    visited = set()
    blocks = []
    color_idx = 0

    for r in range(6):
        for c in range(6):
            ch = grid[r][c]
            if ch == 'o' or ch == 'x' or (r, c) in visited:
                continue

            # Check horizontal
            h_len = 1
            while c + h_len < 6 and grid[r][c + h_len] == ch:
                h_len += 1

            # Check vertical
            v_len = 1
            while r + v_len < 6 and grid[r + v_len][c] == ch:
                v_len += 1

            is_target = (ch == 'A')
            if is_target:
                color = "#FF4757"
            else:
                color = PALETTE[color_idx % len(PALETTE)]
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
    """Returns (path_of_moves, path_of_state_keys)."""
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

def generate_progressive_curriculum():
    db_path = r"d:\ColorSlide\scripts\rush1000.txt"
    pure_boards = []
    with open(db_path, "r", encoding="utf-8") as f:
        for line in f:
            parts = line.split()
            if len(parts) >= 2 and 'x' not in parts[1]:
                pure_boards.append((int(parts[0]), parts[1]))

    print(f"Loaded {len(pure_boards)} pure boards from database.")

    # We need 20 levels with target move depths:
    # 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 22, 24, 26, 30, 34, 38
    target_moves = [5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 22, 24, 26, 30, 34, 38]
    titles = [
        ("The Morning Jam", "Easy"),
        ("Clear Corridor", "Easy"),
        ("Crossroads Alley", "Easy"),
        ("Side Shift", "Medium"),
        ("Gridlock Boulevard", "Medium"),
        ("The Gatekeeper", "Medium"),
        ("Overpass Rush", "Medium"),
        ("The Square Maze", "Medium"),
        ("Tight Squeeze", "Hard"),
        ("Downtown Grid", "Hard"),
        ("Highway Shift", "Hard"),
        ("The Choke Point", "Hard"),
        ("Metropolis Maze", "Hard"),
        ("Triple Lock", "Expert"),
        ("Red Light District", "Expert"),
        ("The Iron Gate", "Expert"),
        ("Master Mind", "Expert"),
        ("The Grand Trap", "Master"),
        ("Rush Hour Legend", "Master"),
        ("The Ultimate Escape", "Master")
    ]

    # Select boards and solve
    verified_levels = []
    found_targets = set()

    for original_moves, board_str in pure_boards:
        blocks = parse_36_string(board_str)
        path, states = solve_with_states(blocks)
        if not path:
            continue

        total_steps = len(path)
        # Slicing: At state index k, the remaining moves to win is (total_steps - k)
        for k in range(total_steps):
            remaining = total_steps - k
            for t_idx, target_m in enumerate(target_moves):
                if t_idx in found_targets:
                    continue
                if remaining == target_m:
                    # Found exact match!
                    state_key = states[k]
                    # Set block positions to this state
                    level_blocks = []
                    for b_i, b in enumerate(blocks):
                        bx = state_key[2 * b_i]
                        by = state_key[2 * b_i + 1]
                        level_blocks.append(Block(b.id, bx, by, b.length, b.direction, b.color, b.is_target))

                    title, diff = titles[t_idx]
                    star3 = remaining + 2
                    star2 = star3 + 4

                    verified_levels.append({
                        "order": t_idx,
                        "level_id": t_idx + 1,
                        "title": title,
                        "difficulty": diff,
                        "board_size": BOARD_SIZE,
                        "optimal_moves": remaining,
                        "star_thresholds": {
                            "3_stars": star3,
                            "2_stars": star2
                        },
                        "solution_steps": path[k:],
                        "blocks": [
                            {
                                "id": b.id,
                                "x": b.x,
                                "y": b.y,
                                "length": b.length,
                                "direction": b.direction,
                                "color": b.color,
                                "is_target": b.is_target
                            }
                            for b in level_blocks
                        ]
                    })
                    found_targets.add(t_idx)
                    print(f" -> Matched Level {t_idx+1}: {remaining} moves [{diff}] '{title}'")

        if len(found_targets) == len(target_moves):
            break

    # Sort levels by level_id
    verified_levels.sort(key=lambda x: x["order"])
    for l in verified_levels:
        del l["order"]

    out_file = r"d:\ColorSlide\levels\levels.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(verified_levels, f, indent=2)

    print(f"\nSUCCESS! Generated all {len(verified_levels)} progressive levels (5 to 38 moves) to {out_file}!")

if __name__ == "__main__":
    generate_progressive_curriculum()
