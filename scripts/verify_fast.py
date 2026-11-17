import sys
from collections import deque
import json

BOARD_SIZE = 6

def solve(blocks):
    # blocks: list of (id, x, y, len, dir, is_target)
    # dir: 'h' or 'v'
    init_key = tuple((b[1], b[2]) for b in blocks)
    queue = deque([(init_key, [])])
    visited = {init_key}
    
    target_idx = [i for i, b in enumerate(blocks) if b[5]][0]
    win_x = BOARD_SIZE - blocks[target_idx][3]
    
    while queue:
        curr_key, path = queue.popleft()
        
        # reconstruct
        curr_pos = list(curr_key)
        if curr_pos[target_idx][0] == win_x:
            return path
            
        # occupancy
        occ = {}
        for idx, (bx, by) in enumerate(curr_pos):
            b_len = blocks[idx][3]
            b_dir = blocks[idx][4]
            for step in range(b_len):
                cx = bx + (step if b_dir == 'h' else 0)
                cy = by + (step if b_dir == 'v' else 0)
                occ[(cx, cy)] = idx
                
        # moves
        for idx, (bx, by) in enumerate(curr_pos):
            b_len = blocks[idx][3]
            b_dir = blocks[idx][4]
            
            # backward
            coord = bx if b_dir == 'h' else by
            for step in range(1, BOARD_SIZE):
                cand = coord - step
                if cand < 0:
                    break
                # check collision for the new cell
                check_cell = (cand, by) if b_dir == 'h' else (bx, cand)
                if check_cell in occ:
                    break
                # valid
                new_key_list = list(curr_key)
                new_key_list[idx] = (cand, by) if b_dir == 'h' else (bx, cand)
                new_key = tuple(new_key_list)
                if new_key not in visited:
                    visited.add(new_key)
                    queue.append((new_key, path + [(blocks[idx][0], -step)]))
                    
            # forward
            for step in range(1, BOARD_SIZE):
                cand = coord + step
                if cand + b_len > BOARD_SIZE:
                    break
                # check collision for the new front cell
                front_cand = cand + b_len - 1
                check_cell = (front_cand, by) if b_dir == 'h' else (bx, front_cand)
                if check_cell in occ:
                    break
                new_key_list = list(curr_key)
                new_key_list[idx] = (cand, by) if b_dir == 'h' else (bx, cand)
                new_key = tuple(new_key_list)
                if new_key not in visited:
                    visited.add(new_key)
                    queue.append((new_key, path + [(blocks[idx][0], step)]))
                    
    return None

# Test classic boards
boards = [
    # Level 1: 4 moves
    ("Level 1", [
        ("red", 0, 2, 2, 'h', True),
        ("v1", 2, 0, 2, 'v', False),
        ("v2", 3, 1, 3, 'v', False),
        ("h1", 3, 0, 2, 'h', False),
    ]),
    # Level 2: 6 moves
    ("Level 2", [
        ("red", 0, 2, 2, 'h', True),
        ("v1", 2, 0, 3, 'v', False),
        ("v2", 3, 2, 3, 'v', False),
        ("h1", 3, 1, 2, 'h', False),
        ("h2", 0, 3, 2, 'h', False),
        ("v3", 4, 0, 2, 'v', False),
    ]),
    # Level 3: 8 moves
    ("Level 3", [
        ("red", 0, 2, 2, 'h', True),
        ("v1", 2, 0, 3, 'v', False),
        ("h1", 3, 0, 2, 'h', False),
        ("v2", 3, 1, 3, 'v', False),
        ("v3", 4, 1, 3, 'v', False),
        ("h2", 2, 4, 2, 'h', False),
        ("h3", 0, 5, 3, 'h', False),
    ]),
    # Level 4: 10 moves
    ("Level 4", [
        ("red", 0, 2, 2, 'h', True),
        ("v1", 2, 1, 3, 'v', False),
        ("h1", 1, 0, 2, 'h', False),
        ("v2", 3, 0, 3, 'v', False),
        ("v3", 4, 2, 2, 'v', False),
        ("h2", 2, 4, 2, 'h', False),
        ("h3", 0, 5, 3, 'h', False),
        ("v4", 5, 0, 3, 'v', False),
    ]),
    # Level 5: 11 moves
    ("Level 5", [
        ("red", 1, 2, 2, 'h', True),
        ("v1", 0, 0, 3, 'v', False),
        ("h1", 1, 0, 2, 'h', False),
        ("v2", 3, 0, 2, 'v', False),
        ("v3", 3, 2, 2, 'v', False),
        ("v4", 4, 1, 3, 'v', False),
        ("h2", 2, 4, 3, 'h', False),
        ("h3", 1, 5, 3, 'h', False),
        ("v5", 5, 3, 3, 'v', False),
    ]),
    # Level 6: 12 moves
    ("Level 6", [
        ("red", 0, 2, 2, 'h', True),
        ("v1", 2, 0, 2, 'v', False),
        ("v2", 2, 3, 3, 'v', False),
        ("v3", 3, 1, 3, 'v', False),
        ("h1", 3, 0, 2, 'h', False),
        ("h2", 3, 4, 2, 'h', False),
        ("v4", 4, 2, 3, 'v', False),
        ("h3", 0, 0, 2, 'h', False),
        ("h4", 0, 4, 2, 'h', False),
    ]),
    # Level 7: 14 moves
    ("Level 7", [
        ("red", 1, 2, 2, 'h', True),
        ("v1", 0, 1, 3, 'v', False),
        ("h1", 1, 1, 2, 'h', False),
        ("v2", 3, 0, 3, 'v', False),
        ("v3", 4, 2, 3, 'v', False),
        ("h2", 2, 3, 2, 'h', False),
        ("h3", 1, 4, 3, 'h', False),
        ("v4", 5, 0, 2, 'v', False),
        ("v5", 5, 3, 3, 'v', False),
        ("h4", 2, 5, 3, 'h', False),
    ]),
    # Level 8: 15 moves
    ("Level 8", [
        ("red", 0, 2, 2, 'h', True),
        ("v1", 2, 0, 3, 'v', False),
        ("h1", 0, 0, 2, 'h', False),
        ("v2", 3, 1, 3, 'v', False),
        ("h2", 3, 0, 2, 'h', False),
        ("v3", 4, 2, 3, 'v', False),
        ("h3", 0, 3, 2, 'h', False),
        ("h4", 0, 4, 3, 'h', False),
        ("h5", 2, 5, 3, 'h', False),
        ("v4", 5, 0, 2, 'v', False),
        ("v5", 5, 3, 3, 'v', False),
    ]),
    # Level 9: 16 moves (Original Rush Hour Card 16)
    ("Level 9", [
        ("red", 1, 2, 2, 'h', True),
        ("v1", 0, 0, 2, 'v', False),
        ("h1", 1, 0, 2, 'h', False),
        ("v2", 3, 0, 3, 'v', False),
        ("h2", 1, 1, 2, 'h', False),
        ("v3", 4, 1, 2, 'v', False),
        ("v4", 4, 3, 2, 'v', False),
        ("h3", 1, 3, 3, 'h', False),
        ("h4", 1, 4, 2, 'h', False),
        ("v5", 0, 4, 2, 'v', False),
        ("h5", 2, 5, 3, 'h', False),
        ("v6", 5, 1, 3, 'v', False),
    ]),
    # Level 10: 18 moves (Original Rush Hour Card 20)
    ("Level 10", [
        ("red", 0, 2, 2, 'h', True),
        ("v1", 2, 0, 2, 'v', False),
        ("v2", 2, 2, 2, 'v', False), # wait, row 2 is red
    ])
]

for name, b in boards[:-1]:
    res = solve(b)
    if res:
        print(f"{name}: SOLVED in {len(res)} moves!")
    else:
        print(f"{name}: NO SOLUTION")
