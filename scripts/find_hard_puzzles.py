import json
import random
import time
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

def solve_puzzle(blocks: List[Block], max_depth: int = 40) -> Optional[List[Dict]]:
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

    while queue:
        curr_key, path = queue.popleft()
        if len(path) > max_depth:
            continue

        for i, b in enumerate(blocks):
            b.x = curr_key[2 * i]
            b.y = curr_key[2 * i + 1]

        if blocks[target_idx].x == win_x:
            return path

        for i, b in enumerate(blocks):
            current_coord = b.x if b.direction == 'horizontal' else b.y

            # Backward
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

            # Forward
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

def try_create_random_board(num_blocks: int) -> Optional[List[Block]]:
    grid = [[False] * BOARD_SIZE for _ in range(BOARD_SIZE)]
    blocks = []

    # Place Red Target Block at row 2, x=0 or 1
    red_x = random.choice([0, 1])
    red_block = Block("red", red_x, 2, 2, "horizontal", "#FF4757", is_target=True)
    blocks.append(red_block)
    for c in range(red_x, red_x + 2):
        grid[2][c] = True

    # Attempt to place other blocks
    attempts = 0
    while len(blocks) < num_blocks and attempts < 100:
        attempts += 1
        direction = random.choice(["horizontal", "vertical"])
        length = random.choice([2, 2, 2, 3])  # 75% cars, 25% trucks

        if direction == "horizontal":
            x = random.randint(0, BOARD_SIZE - length)
            y = random.randint(0, BOARD_SIZE - 1)
            # Avoid placing in row 2 exit corridor right in front of red if length allows
            if y == 2 and x >= red_x + 2:
                continue
            # Check overlap
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

    return blocks if len(blocks) >= num_blocks else None

def search_hard_levels(target_brackets: List[Tuple[int, int, str, str]]):
    """
    Finds levels for target move brackets: [(min_m, max_m, difficulty, title), ...]
    """
    found_levels = []
    print(f"Searching for {len(target_brackets)} challenging puzzle levels...")

    start_time = time.time()
    iterations = 0

    for idx, (min_m, max_m, diff, title) in enumerate(target_brackets):
        bracket_found = False
        print(f"\nSearching Level {idx+1}: Target {min_m}-{max_m} moves [{diff}] '{title}'...")

        # Search loop
        while not bracket_found and (time.time() - start_time < 35):
            iterations += 1
            num_blocks = random.randint(7, 11)
            board = try_create_random_board(num_blocks)
            if not board:
                continue

            orig_pos = [(b.x, b.y) for b in board]
            path = solve_puzzle(board, max_depth=max_m + 5)
            if path is not None:
                moves = len(path)
                if min_m <= moves <= max_m:
                    print(f" -> FOUND! Level {idx+1}: {moves} optimal moves with {len(board)} blocks!")
                    bracket_found = True

                    # Restore
                    for i, b in enumerate(board):
                        b.x = orig_pos[i][0]
                        b.y = orig_pos[i][1]

                    star3 = moves + 2
                    star2 = star3 + 4

                    lvl_obj = {
                        "level_id": idx + 1,
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
                    }
                    found_levels.append(lvl_obj)

    print(f"\nDone! Found {len(found_levels)} verified challenging puzzles in {iterations} iterations.")
    out_file = r"d:\ColorSlide\levels\levels.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(found_levels, f, indent=2)
    print(f"Saved to {out_file}!")

if __name__ == "__main__":
    TARGETS = [
        # Easy (Warmup)
        (5, 7, "Easy", "Morning Commute"),
        (6, 8, "Easy", "Crossroads"),
        (7, 9, "Easy", "Traffic Lane"),
        # Medium (Real Thinking)
        (9, 11, "Medium", "Side Street Shuffle"),
        (10, 12, "Medium", "The Intersection"),
        (11, 13, "Medium", "Grid Lock"),
        (12, 14, "Medium", "Double Parked"),
        # Hard (Deep Planning)
        (13, 15, "Hard", "Downtown Rush"),
        (14, 16, "Hard", "The Detour"),
        (15, 17, "Hard", "Highway Blockade"),
        (16, 18, "Hard", "Tight Squeeze"),
        (17, 19, "Hard", "Metropolis"),
        # Expert & Master (Serious Brain Teasers)
        (18, 20, "Expert", "City Center Jam"),
        (19, 22, "Expert", "Mastermind"),
        (20, 24, "Master", "The Grand Puzzle")
    ]
    search_hard_levels(TARGETS)
