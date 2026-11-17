"""
Reverse Play (Scramble) High-Depth Level Generator.
Guarantees 100% solvability and reaches deep 10 to 30 move optimal paths!
"""

import json
import random
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

    def get_cells(self, x: Optional[int] = None, y: Optional[int] = None) -> List[Tuple[int, int]]:
        bx = self.x if x is None else x
        by = self.y if y is None else y
        if self.direction == 'horizontal':
            return [(bx + i, by) for i in range(self.length)]
        else:
            return [(bx, by + i) for i in range(self.length)]

def state_to_key(blocks: List[Block]) -> Tuple[int, ...]:
    coords = []
    for b in blocks:
        coords.append(b.x)
        coords.append(b.y)
    return tuple(coords)

def is_valid_position(blocks: List[Block], moving_idx: int, new_coord: int) -> bool:
    b = blocks[moving_idx]
    if b.direction == 'horizontal':
        if new_coord < 0 or new_coord + b.length > BOARD_SIZE:
            return False
        test_cells = [(new_coord + i, b.y) for i in range(b.length)]
    else:
        if new_coord < 0 or new_coord + b.length > BOARD_SIZE:
            return False
        test_cells = [(b.x, new_coord + i) for i in range(b.length)]

    for idx, other in enumerate(blocks):
        if idx == moving_idx:
            continue
        other_cells = set(other.get_cells())
        for cell in test_cells:
            if cell in other_cells:
                return False
    return True

def solve_puzzle(blocks: List[Block], max_states: int = 150000) -> Optional[List[Dict]]:
    initial_key = state_to_key(blocks)
    queue = deque()
    queue.append((initial_key, []))
    visited = {initial_key}

    target_idx = None
    for idx, b in enumerate(blocks):
        if b.is_target:
            target_idx = idx
            break

    assert target_idx is not None
    win_x = BOARD_SIZE - blocks[target_idx].length

    while queue and len(visited) < max_states:
        curr_key, path = queue.popleft()

        for i, b in enumerate(blocks):
            b.x = curr_key[2 * i]
            b.y = curr_key[2 * i + 1]

        if blocks[target_idx].x == win_x:
            return path

        for i, b in enumerate(blocks):
            current_coord = b.x if b.direction == 'horizontal' else b.y

            # Slide Backward
            for step in range(1, BOARD_SIZE):
                cand = current_coord - step
                if is_valid_position(blocks, i, cand):
                    new_key_list = list(curr_key)
                    if b.direction == 'horizontal':
                        new_key_list[2 * i] = cand
                    else:
                        new_key_list[2 * i + 1] = cand
                    new_key = tuple(new_key_list)
                    if new_key not in visited:
                        visited.add(new_key)
                        move_info = {
                            "block_id": b.id,
                            "direction": b.direction,
                            "from": current_coord,
                            "to": cand,
                            "delta": -step
                        }
                        queue.append((new_key, path + [move_info]))
                else:
                    break

            # Slide Forward
            for step in range(1, BOARD_SIZE):
                cand = current_coord + step
                if is_valid_position(blocks, i, cand):
                    new_key_list = list(curr_key)
                    if b.direction == 'horizontal':
                        new_key_list[2 * i] = cand
                    else:
                        new_key_list[2 * i + 1] = cand
                    new_key = tuple(new_key_list)
                    if new_key not in visited:
                        visited.add(new_key)
                        move_info = {
                            "block_id": b.id,
                            "direction": b.direction,
                            "from": current_coord,
                            "to": cand,
                            "delta": step
                        }
                        queue.append((new_key, path + [move_info]))
                else:
                    break

    return None

def scramble_board(num_blocks=9, num_scramble_steps=60) -> Optional[List[Block]]:
    """Starts with red car at exit and scrambles blocks randomly."""
    grid = [[False] * BOARD_SIZE for _ in range(BOARD_SIZE)]
    blocks = []

    # Target car at winning position
    red = Block("red", 4, 2, 2, "horizontal", "#FF4757", is_target=True)
    blocks.append(red)
    grid[2][4] = True
    grid[2][5] = True

    # Fill 7 to 9 other blocks randomly
    attempts = 0
    while len(blocks) < num_blocks and attempts < 200:
        attempts += 1
        direction = random.choice(["horizontal", "vertical"])
        length = random.choice([2, 2, 3])

        if direction == "horizontal":
            x = random.randint(0, BOARD_SIZE - length)
            y = random.randint(0, BOARD_SIZE - 1)
            overlap = any(grid[y][x + i] for i in range(length))
            if not overlap:
                for i in range(length):
                    grid[y][x + i] = True
                color = PALETTE[len(blocks) % len(PALETTE)]
                blocks.append(Block(f"b{len(blocks)}", x, y, length, direction, color))
        else:
            x = random.randint(0, BOARD_SIZE - 1)
            y = random.randint(0, BOARD_SIZE - length)
            overlap = any(grid[y + i][x] for i in range(length))
            if not overlap:
                for i in range(length):
                    grid[y + i][x] = True
                color = PALETTE[len(blocks) % len(PALETTE)]
                blocks.append(Block(f"b{len(blocks)}", x, y, length, direction, color))

    # Perform random legal moves (scramble)
    for _ in range(num_scramble_steps):
        b_idx = random.randint(0, len(blocks) - 1)
        b = blocks[b_idx]
        delta = random.choice([-2, -1, 1, 2])
        coord = b.x if b.direction == "horizontal" else b.y
        new_c = coord + delta
        if is_valid_position(blocks, b_idx, new_c):
            if b.direction == "horizontal":
                b.x = new_c
            else:
                b.y = new_c

    # Ensure red block is not still at exit (must be x <= 2)
    if blocks[0].x > 2:
        return None

    return blocks

def generate_progressive_20_pack():
    titles = [
        ("The Morning Jam", "Easy"),
        ("Crossroads Alley", "Easy"),
        ("Double Parked", "Easy"),
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
        ("Triple Lock", "Hard"),
        ("Red Light District", "Expert"),
        ("The Iron Gate", "Expert"),
        ("Master Mind", "Expert"),
        ("The Grand Trap", "Expert"),
        ("Rush Hour Legend", "Master"),
        ("The Ultimate Escape", "Master")
    ]

    # Target optimal moves ranges for 20 levels
    target_moves = [
        (4, 6), (5, 7), (6, 8), (7, 9), (8, 10),
        (9, 11), (10, 12), (11, 13), (12, 14), (13, 15),
        (14, 16), (15, 17), (16, 18), (17, 19), (18, 20),
        (19, 21), (20, 22), (21, 24), (23, 26), (25, 30)
    ]

    verified = []
    print("Generating 20-level progressive difficulty pack (up to 25+ moves)...")

    for i in range(20):
        min_m, max_m = target_moves[i]
        title, diff = titles[i]
        print(f"\nBuilding Level {i+1} [{diff}] '{title}' (Target: {min_m}-{max_m} moves)...")

        found = False
        attempts = 0
        while not found and attempts < 1000:
            attempts += 1
            num_b = random.randint(8, 11)
            steps = random.randint(40, 120)
            board = scramble_board(num_b, steps)
            if not board:
                continue

            orig_pos = [(b.x, b.y) for b in board]
            path = solve_puzzle(board)
            if path:
                moves = len(path)
                if min_m <= moves <= max_m:
                    found = True
                    print(f" -> Level {i+1} SUCCEEDED! Exact {moves} optimal moves with {len(board)} blocks!")

                    # Restore positions
                    for b_i, b in enumerate(board):
                        b.x = orig_pos[b_i][0]
                        b.y = orig_pos[b_i][1]

                    star3 = moves + 2
                    star2 = star3 + 4

                    verified.append({
                        "level_id": i + 1,
                        "title": title,
                        "difficulty": diff,
                        "board_size": BOARD_SIZE,
                        "optimal_moves": moves,
                        "star_thresholds": {
                            "3_stars": star3,
                            "2_stars": star2
                        },
                        "solution_steps": path,
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
                            for b in board
                        ]
                    })
                elif moves > max_m and i >= 15:
                    # Keep extra hard ones for later
                    found = True
                    print(f" -> Level {i+1} SUCCEEDED (Bonus Hard)! {moves} optimal moves!")
                    for b_i, b in enumerate(board):
                        b.x = orig_pos[b_i][0]
                        b.y = orig_pos[b_i][1]

                    star3 = moves + 2
                    star2 = star3 + 4
                    verified.append({
                        "level_id": i + 1,
                        "title": title,
                        "difficulty": diff,
                        "board_size": BOARD_SIZE,
                        "optimal_moves": moves,
                        "star_thresholds": { "3_stars": star3, "2_stars": star2 },
                        "solution_steps": path,
                        "blocks": [{ "id": b.id, "x": b.x, "y": b.y, "length": b.length, "direction": b.direction, "color": b.color, "is_target": b.is_target } for b in board]
                    })

    out_file = r"d:\ColorSlide\levels\levels.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(verified, f, indent=2)
    print(f"\nSuccessfully saved {len(verified)} verified levels to {out_file}!")

if __name__ == "__main__":
    generate_progressive_20_pack()
