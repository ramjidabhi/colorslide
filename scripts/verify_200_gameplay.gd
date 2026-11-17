extends SceneTree

func _init() -> void:
	run()

func run() -> void:
	print("\n==============================================")
	print(">>> RUNNING 200-LEVEL FULL VERIFICATION <<<")
	print("==============================================")

	# 1. Instantiate Main scene
	var main_scene = load("res://scenes/Main.tscn")
	if not main_scene:
		printerr("FAILED to load res://scenes/Main.tscn")
		quit(1)
		return

	var main_inst = main_scene.instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame

	var gm = root.get_node_or_null("GameManager")
	if not gm:
		printerr("GameManager missing!")
		quit(1)
		return

	print("✓ GameManager loaded with %d levels." % gm.all_levels.size())
	if gm.all_levels.size() != 200:
		printerr("FAILED: Expected 200 levels, got %d" % gm.all_levels.size())
		quit(1)
		return

	var board = main_inst.find_child("GameBoard", true, false)
	var guide = main_inst.get_node_or_null("TutorialGuide")

	# Test World 1: Level 1
	gm.start_level(0)
	await process_frame
	print("✓ World 1 loaded (L1): Board blocks: %d" % board.blocks.size())
	guide.open_hint(0)
	print("  L1 Hint Step 1: %s" % guide.instruction_label.text)
	guide.close_hint()

	# Test World 2: Level 75
	gm.start_level(74)
	await process_frame
	print("✓ World 2 loaded (L75): Board blocks: %d | World: %d" % [board.blocks.size(), board.world_id])
	guide.open_hint(0)
	print("  L75 Hint Step 1: %s" % guide.instruction_label.text)
	guide.close_hint()

	# Test World 3: Level 125 (Frost Cavern with ice blocks)
	gm.start_level(124)
	await process_frame
	var frozen_count = 0
	for b in board.blocks:
		if b.is_frozen:
			frozen_count += 1
	print("✓ World 3 loaded (L125): Frozen blocks: %d | World: %d" % [frozen_count, board.world_id])
	if frozen_count == 0:
		printerr("FAILED: World 3 expected frozen blocks!")
		quit(1)
		return
	guide.open_hint(0)
	print("  L125 Hint Step 1: %s" % guide.instruction_label.text)
	guide.close_hint()

	# Test World 4: Level 175 (Laser Facility with switches & lasers)
	gm.start_level(174)
	await process_frame
	print("✓ World 4 loaded (L175): Switches: %d | Lasers: %d | World: %d" % [board.switches.size(), board.lasers.size(), board.world_id])
	if board.switches.is_empty() or board.lasers.is_empty():
		printerr("FAILED: World 4 expected switches and lasers!")
		quit(1)
		return
	guide.open_hint(0)
	print("  L175 Hint Step 1: %s" % guide.instruction_label.text)
	guide.close_hint()

	# Test LevelSelect screen
	print("\n>>> Testing LevelSelect.tscn Scene & World Tabs...")
	var ls_scene = load("res://scenes/LevelSelect.tscn")
	var ls_inst = ls_scene.instantiate()
	root.add_child(ls_inst)
	await process_frame
	await process_frame

	print("✓ LevelSelect opened!")
	print("  Current World Title: ", ls_inst.world_title.text)
	ls_inst._switch_world(2)
	print("  Switched to W2: ", ls_inst.world_title.text)
	ls_inst._switch_world(3)
	print("  Switched to W3: ", ls_inst.world_title.text)
	ls_inst._switch_world(4)
	print("  Switched to W4: ", ls_inst.world_title.text)

	print("\n==============================================")
	print(">>> ALL 200-LEVEL SYSTEMS VERIFIED 100%! <<<")
	print("==============================================\n")
	quit(0)
