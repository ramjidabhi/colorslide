extends SceneTree

func _init() -> void:
	run()

func run() -> void:
	print("\n==============================================")
	print(">>> RUNNING UI REDESIGN & INTERACTION VERIFICATION <<<")
	print("==============================================")

	var main_scene = load("res://scenes/Main.tscn")
	if not main_scene:
		printerr("FAILED to load Main.tscn")
		quit(1)
		return

	var main_inst = main_scene.instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame

	var gm = root.get_node_or_null("GameManager")
	var board = main_inst.find_child("GameBoard", true, false)

	# 1. Test Level 200 Formatting (World Boss)
	gm.start_level(199) # Level 200
	await process_frame
	print("✓ Level 200 Loaded:")
	print("  Badge: ", main_inst.world_badge.text)
	print("  Level: ", main_inst.level_num_label.text)
	print("  Sub:   ", main_inst.level_sub_label.text)
	print("  Coins: ", main_inst.coins_label.text)
	print("  Status:", main_inst.status_label.text)

	if ".0" in main_inst.world_badge.text or ".0" in main_inst.level_num_label.text:
		printerr("FAILED: Found ugly .0 float in header text!")
		quit(1)
		return

	# 2. Test Level 1 & Interactive Undo
	gm.start_level(0) # Level 1
	await process_frame
	print("\n✓ Level 1 Loaded:")
	print("  Badge: ", main_inst.world_badge.text)
	print("  Level: ", main_inst.level_num_label.text)

	# Simulate moving block v1
	var v1_block = null
	for b in board.blocks:
		if b.block_id == "v1":
			v1_block = b
			break

	if not v1_block:
		printerr("FAILED: Could not find block v1 on Level 1!")
		quit(1)
		return

	var orig_pos = Vector2i(v1_block.grid_x, v1_block.grid_y)
	print("  v1 original position: ", orig_pos)
	
	# Simulate move down by 2 cells
	v1_block.grid_y += 2
	board._on_block_moved(v1_block, orig_pos, Vector2i(v1_block.grid_x, v1_block.grid_y))
	print("  v1 moved to: (%d, %d)" % [v1_block.grid_x, v1_block.grid_y])
	print("  Move count in HUD: ", main_inst.status_label.text)

	# Verify undo stack has 1 move
	print("  Board move_history size: %d" % board.move_history.size())
	if board.move_history.size() != 1:
		printerr("FAILED: Expected move_history size 1!")
		quit(1)
		return

	# Test Undo
	print("\n>>> Testing Undo action...")
	main_inst._on_undo_pressed()
	await process_frame
	print("  v1 position after undo: (%d, %d)" % [v1_block.grid_x, v1_block.grid_y])
	print("  HUD after undo: ", main_inst.status_label.text)

	if v1_block.grid_x != orig_pos.x or v1_block.grid_y != orig_pos.y:
		printerr("FAILED: Undo did not restore block to original coordinates!")
		quit(1)
		return

	print("✓ Interactive Undo successfully restored block to original cell!")

	# 3. Test Hint toggle
	print("\n>>> Testing Hint toggle...")
	main_inst._on_hint_pressed()
	await process_frame
	print("  Hint overlay visible: ", main_inst.tutorial_guide.visible)
	main_inst._on_hint_pressed()
	await process_frame
	print("  Hint overlay closed: ", not main_inst.tutorial_guide.visible)

	print("\n==============================================")
	print(">>> ALL UI REDESIGN & INTERACTION CHECKS PASSED! <<<")
	print("==============================================\n")
	quit(0)
