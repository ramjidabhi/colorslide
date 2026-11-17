extends SceneTree

func _init() -> void:
	run()

func run() -> void:
	print("\n==========================================")
	print(">>> RUNNING VERIFICATION: ALL 50 LEVEL HINTS <<<")
	print("==========================================")

	# 1. Verify levels.json
	var file = FileAccess.open("res://levels/levels.json", FileAccess.READ)
	if not file:
		printerr("FAILED to open res://levels/levels.json")
		quit(1)
		return

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK or not (json.data is Array):
		printerr("FAILED to parse levels.json as Array!")
		quit(1)
		return

	var levels: Array = json.data
	print("✓ levels.json loaded successfully. Total levels: %d" % levels.size())
	if levels.size() != 50:
		printerr("FAILED: Expected 50 levels, got %d" % levels.size())
		quit(1)
		return

	# 2. Check hint_steps on all 50 levels
	var total_steps_verified = 0
	for lvl in levels:
		var l_id = lvl.get("level_id", 0)
		var title = lvl.get("title", "")
		var hint_steps = lvl.get("hint_steps", [])
		var opt_moves = lvl.get("optimal_moves", 0)

		if hint_steps.is_empty():
			printerr("FAILED: Level %d (%s) has no hint_steps!" % [l_id, title])
			quit(1)
			return

		if hint_steps.size() != opt_moves:
			printerr("FAILED: Level %d (%s) hint_steps count (%d) != optimal_moves (%d)" % [l_id, title, hint_steps.size(), opt_moves])
			quit(1)
			return

		for step in hint_steps:
			total_steps_verified += 1
			var bid = step.get("block_id", "")
			var instr = step.get("instruction", "")
			var cname = step.get("color_name", "")
			var tdir = step.get("target_dir", "")
			var arrow = step.get("arrow", "")

			if bid == "" or instr == "" or cname == "" or tdir == "" or arrow == "":
				printerr("FAILED: Level %d has incomplete step data: %s" % [l_id, str(step)])
				quit(1)
				return

	print("✓ All 50 levels validated! Total hint steps verified: %d" % total_steps_verified)
	print("  Sample Level 1:")
	for s in levels[0]["hint_steps"]:
		print("    - ", s["instruction"])

	print("  Sample Level 50:")
	var sample_50 = levels[49]["hint_steps"].slice(0, 3)
	for s in sample_50:
		print("    - ", s["instruction"])
	print("    ... (%d total steps)" % levels[49]["hint_steps"].size())

	# 3. Instantiate Main scene and test Hint Controller
	print("\n>>> Testing Main.tscn Scene & Hint Controller...")
	var main_scene = load("res://scenes/Main.tscn")
	if not main_scene:
		printerr("FAILED to load res://scenes/Main.tscn")
		quit(1)
		return

	var main_inst = main_scene.instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame

	var guide = main_inst.get_node_or_null("TutorialGuide")
	if not guide:
		printerr("FAILED: TutorialGuide node missing in Main.tscn")
		quit(1)
		return
	print("✓ Found TutorialGuide node in Main.tscn (z_index: %d)" % guide.z_index)

	# Test hint toggle on Level 1
	guide.open_hint(0)
	print("✓ TutorialGuide.open_hint(0) executed cleanly!")
	print("  Current step instruction: ", guide.instruction_label.text)
	print("  Current step badge: ", guide.step_label.text)

	# Test navigation buttons
	guide._on_next_pressed()
	print("✓ Next step pressed -> Instruction: ", guide.instruction_label.text)
	guide._on_prev_pressed()
	print("✓ Prev step pressed -> Instruction: ", guide.instruction_label.text)

	guide.close_hint()
	print("✓ TutorialGuide.close_hint() executed cleanly!")

	print("\n==========================================")
	print(">>> ALL HINT SYSTEM CHECKS PASSED 100%! <<<")
	print("==========================================\n")
	quit(0)
