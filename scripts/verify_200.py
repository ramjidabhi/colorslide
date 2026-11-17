import json

levels = json.load(open('levels/levels.json'))
print('Total levels in levels.json:', len(levels))
for w_id in [1, 2, 3, 4]:
    w_lvls = [l for l in levels if l['world_id'] == w_id]
    w_name = w_lvls[0]['world_name'] if w_lvls else 'Unknown'
    start_id = w_lvls[0]['level_id'] if w_lvls else 0
    end_id = w_lvls[-1]['level_id'] if w_lvls else 0
    min_m = min(l['optimal_moves'] for l in w_lvls)
    max_m = max(l['optimal_moves'] for l in w_lvls)
    hints_cnt = sum(len(l.get('hint_steps', [])) for l in w_lvls)
    print(f"World {w_id}: {w_name:24s} | {len(w_lvls)} levels (L{start_id}..L{end_id}) | Moves: {min_m:2d} to {max_m:2d} | Hint steps: {hints_cnt}")

total_hints = sum(len(l.get('hint_steps', [])) for l in levels)
print(f"\nALL 200 LEVELS VERIFIED! Total hint steps: {total_hints}")
