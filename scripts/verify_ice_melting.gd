extends SceneTree

func _init() -> void:
	run()

func run() -> void:
	print("--- BEGIN ICE MELTING VERIFICATION ---")
	
	var main_scene = load("res://scenes/Main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	
	var gm = root.get_node_or_null("GameManager")
	assert(gm != null, "GameManager not found")
	
	var lvl_147_idx = -1
	for idx in range(gm.all_levels.size()):
		if gm.all_levels[idx].get("level_id") == 147:
			lvl_147_idx = idx
			break
			
	assert(lvl_147_idx != -1, "Level 147 not found in levels.json")
	gm.start_level(lvl_147_idx)
	await process_frame
	
	var board = main.game_board
	assert(board != null, "GameBoard not found")
	
	var block_e = null
	var block_a = null
	for b in board.blocks:
		if b.block_id == "e":
			block_e = b
		elif b.block_id == "a":
			block_a = b
			
	assert(block_e != null, "Block e not found")
	assert(block_a != null, "Block a not found")
	
	print("Block e is_frozen initially: ", block_e.is_frozen)
	assert(block_e.is_frozen == true, "Block e should start frozen in ice")
	
	# Test sliding block 'a' from (0, 2) to (1, 2)
	print("Moving block a from (0, 2) to (1, 2)...")
	var from_c = Vector2i(block_a.grid_x, block_a.grid_y)
	block_a.grid_x = 1
	block_a.grid_y = 2
	board._on_block_moved(block_a, from_c, Vector2i(1, 2))
	
	print("Block e is_frozen after adjacent slide: ", block_e.is_frozen)
	assert(block_e.is_frozen == false, "Block e should be unfrozen after adjacent block slides!")
	
	# Test moving thawed block e up to (0, 0)
	print("Moving thawed block e up from (0, 3) to (0, 0)...")
	var e_from = Vector2i(block_e.grid_x, block_e.grid_y)
	block_e.grid_x = 0
	block_e.grid_y = 0
	board._on_block_moved(block_e, e_from, Vector2i(0, 0))
	assert(block_e.grid_y == 0, "Block e should now be at row 0!")
	
	print("--- ALL ICE MELTING TESTS PASSED! ---")
	quit(0)
