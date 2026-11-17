extends SceneTree

func _init() -> void:
	run()

func run() -> void:
	print("\n==============================================")
	print(">>> VERIFYING DAILY CHALLENGE & 3 BOOSTERS <<<")
	print("==============================================")
	
	var main_scene = load("res://scenes/Main.tscn")
	var main_inst = main_scene.instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame
	
	var gm = root.get_node_or_null("GameManager")
	if not gm:
		gm = load("res://scripts/game_manager.gd").new()
		root.add_child(gm)
		gm.load_levels_from_disk()
	
	var sm = root.get_node_or_null("SoundManager")
	if not sm:
		sm = load("res://scripts/sound_manager.gd").new()
		root.add_child(sm)
		
	var board = main_inst.game_board
	assert(board != null, "GameBoard must exist in Main.tscn")
	
	# ----------------------------------------------------
	# 1. Verify Daily Challenge Medium-Hard Auto-Generation
	# ----------------------------------------------------
	print("\n--- 1. Testing Daily Challenge Auto-Generation (14–28 Moves) ---")
	var test_dates = ["2026-11-13", "2026-11-14", "2026-12-01", "2026-12-25", "2027-01-01"]
	for d in test_dates:
		var p = gm.get_daily_puzzle_data(d)
		var opt = int(p.get("optimal_moves", 0))
		print("  Date %s -> Optimal Moves: %d | Title: %s" % [d, opt, p.get("title")])
		assert(p.get("is_daily") == true, "Must be flagged is_daily")
		assert(opt >= 14 and opt <= 28, "Daily puzzle must be Medium-Hard (14–28 moves), got %d" % opt)
		assert(p.get("bounty_coins") == 100, "Bounty should be 100 coins")
	print("✓ All tested dates generated certified Medium-Hard daily puzzles!")

	# ----------------------------------------------------
	# 2. Verify Booster Economics & Inventory
	# ----------------------------------------------------
	print("\n--- 2. Testing Booster Inventory & Economics ---")
	gm.booster_sledgehammers = 1
	gm.booster_shrinks = 1
	gm.booster_cranes = 1
	gm.total_coins = 0
	
	assert(gm.can_afford_booster("sledgehammer") == true, "Should afford sledgehammer with inventory")
	var consumed = gm.consume_booster("sledgehammer")
	assert(consumed == true and gm.booster_sledgehammers == 0, "Should consume inventory sledgehammer")
	assert(gm.can_afford_booster("sledgehammer") == false, "Cannot afford sledgehammer with 0 count and 0 coins")
	
	# Test coin purchase
	gm.total_coins = 150
	assert(gm.can_afford_booster("sledgehammer") == true, "Can afford with 150 coins")
	consumed = gm.consume_booster("sledgehammer")
	assert(consumed == true and gm.total_coins == 50, "Should deduct 100 coins (150 -> 50)")
	
	# Test adding booster
	gm.add_booster("sledgehammer", 3)
	assert(gm.get_booster_count("sledgehammer") == 3, "Inventory should be 3")
	print("✓ Booster economics, coin pricing, and inventory verified!")

	# ----------------------------------------------------
	# 3. Verify Sound Synthesizers for Boosters
	# ----------------------------------------------------
	print("\n--- 3. Testing Booster Audio Synthesizers ---")
	sm.is_muted = false
	sm.play_booster_smash()
	sm.play_booster_shrink()
	sm.play_booster_crane_lift()
	sm.play_booster_crane_drop()
	print("✓ Booster sound synthesizers generated & played cleanly!")

	# ----------------------------------------------------
	# 4. Verify Interactive Board Boosters (Smash, Shrink, Crane)
	# ----------------------------------------------------
	print("\n--- 4. Testing Board Booster Interactions ---")
	gm.start_level(0)
	await process_frame
	await process_frame
	assert(board.blocks.size() == 5, "Level 1 should have 5 blocks")
	
	# Test Sledgehammer on target block (should be rejected)
	board.set_booster_mode("sledgehammer")
	var target_b = board.target_block_node
	var action_res = { "success": false, "msg": "" }
	board.booster_action_completed.connect(func(type, success, msg):
		action_res["success"] = success
		action_res["msg"] = msg
	)
	
	board.handle_booster_interaction(target_b)
	assert(action_res["success"] == false, "Cannot smash target block")
	assert(board.blocks.has(target_b), "Target block must not be deleted")
	
	# Test Sledgehammer on obstacle block (should succeed)
	var obs_b = null
	for b in board.blocks:
		if not b.is_target:
			obs_b = b
			break
	assert(obs_b != null, "Must find an obstacle block")
	var obs_id = obs_b.block_id
	var obs_x = obs_b.grid_x
	var obs_y = obs_b.grid_y
	
	board.set_booster_mode("sledgehammer")
	board.handle_booster_interaction(obs_b)
	assert(action_res["success"] == true, "Smash must succeed on obstacle block")
	assert(not board.blocks.has(obs_b), "Obstacle block must be removed from board.blocks")
	assert(board.grid[obs_y][obs_x] == null, "Grid cell must be freed")
	print("✓ Sledgehammer (Smash) verified!")
	
	# Test Shrink Ray on 2-cell block
	gm.start_level(0)
	await process_frame
	await process_frame
	var block_to_shrink = null
	for b in board.blocks:
		if not b.is_target and b.length >= 2:
			block_to_shrink = b
			break
	assert(block_to_shrink != null, "Found block to shrink")
	var orig_len = block_to_shrink.length
	board.set_booster_mode("shrink")
	board.handle_booster_interaction(block_to_shrink)
	assert(action_res["success"] == true, "Shrink must succeed")
	assert(block_to_shrink.length == orig_len - 1, "Length must be reduced by 1")
	print("✓ Shrink Ray verified!")
	
	# Test Crane Picker (Lift & Relocate)
	gm.start_level(0)
	await process_frame
	await process_frame
	var block_to_crane = null
	for b in board.blocks:
		if not b.is_target:
			block_to_crane = b
			break
	board.set_booster_mode("crane")
	board.handle_booster_interaction(block_to_crane)
	assert(board.crane_selected_block == block_to_crane, "Block must be selected for crane lift")
	
	# Drop into occupied cell (should fail)
	board._attempt_crane_drop(board.target_block_node.grid_x, board.target_block_node.grid_y)
	assert(action_res["success"] == false, "Cannot drop into occupied space")
	
	# Drop into empty cell (0, 0)
	board._attempt_crane_drop(0, 0)
	assert(action_res["success"] == true, "Crane drop must succeed into empty space")
	assert(block_to_crane.grid_x == 0 and block_to_crane.grid_y == 0, "Block must move to (0, 0)")
	assert(board.grid[0][0] == block_to_crane, "Grid must reflect crane drop")
	print("✓ Crane Picker verified!")
	
	# ----------------------------------------------------
	# 5. Verify Main.tscn BoosterBar UI Nodes & Level 5 Gating
	# ----------------------------------------------------
	print("\n--- 5. Testing BoosterBar Level 5 Gating & Guide Dialog ---")
	var smash_btn = main_inst.get_node_or_null("SafeMargin/MainLayout/BoosterBar/SmashButton")
	var shrink_btn = main_inst.get_node_or_null("SafeMargin/MainLayout/BoosterBar/ShrinkButton")
	var crane_btn = main_inst.get_node_or_null("SafeMargin/MainLayout/BoosterBar/CraneButton")
	var help_btn = main_inst.get_node_or_null("SafeMargin/MainLayout/BoosterBar/BoosterHelpButton")
	var booster_bar = main_inst.get_node_or_null("SafeMargin/MainLayout/BoosterBar")
	var guide_dialog = main_inst.get_node_or_null("BoosterGuideDialog")
	
	assert(smash_btn != null, "SmashButton must exist in Main.tscn")
	assert(shrink_btn != null, "ShrinkButton must exist in Main.tscn")
	assert(crane_btn != null, "CraneButton must exist in Main.tscn")
	assert(help_btn != null, "BoosterHelpButton must exist in Main.tscn")
	assert(guide_dialog != null, "BoosterGuideDialog must exist in Main.tscn")
	
	# Test Level 1 gating: Booster bar is hidden for beginners (Levels 1-4)
	gm.boosters_unlocked = false
	gm.highest_unlocked_level = 1
	gm.start_level(0)
	await process_frame
	await process_frame
	assert(booster_bar.visible == false, "BoosterBar must be hidden on Level 1-4 for beginners")
	
	# Test Level 5 unlock starter pack grant (strictly 3x of each!)
	gm.unlock_boosters_starter_pack()
	assert(gm.boosters_unlocked == true, "Boosters must be marked unlocked")
	assert(gm.booster_sledgehammers == 3, "Starter pack must grant strictly 3x Sledgehammers")
	assert(gm.booster_shrinks == 3, "Starter pack must grant strictly 3x Shrink Rays")
	assert(gm.booster_cranes == 3, "Starter pack must grant strictly 3x Crane Pickers")
	
	# Test Booster bar visible when unlocked (or on Level 5+)
	gm.start_level(0)
	await process_frame
	await process_frame
	assert(booster_bar.visible == true, "BoosterBar must be visible once unlocked")
	
	# Test Guide Dialog open & close
	guide_dialog.show_dialog(true)
	assert(guide_dialog.visible == true, "Guide dialog should open")
	guide_dialog._on_claim_pressed()
	await process_frame
	print("✓ BoosterBar Level 5 gating, 3x starter pack, and Guide dialog verified!")

	# ----------------------------------------------------
	# 6. Verify Exit Path Glow & Audio Cue
	# ----------------------------------------------------
	print("\n--- 6. Testing Exit Path Clear Detection ---")
	gm.start_level(0) # Level 1
	await process_frame
	await process_frame
	# Level 1 initially has blocks in way of exit
	assert(board.is_exit_path_clear == false, "Initial Level 1 path should not be clear")
	var exit_signal = { "fired": false }
	board.exit_path_cleared.connect(func(): exit_signal["fired"] = true)
	# Slide obstacles out of row 2
	for b in board.blocks:
		if b.block_id == "v1": # Move v1 down from row 2
			b.grid_y = 3
		elif b.block_id == "v2": # Move v2 down from row 2
			b.grid_y = 3
	board._rebuild_grid_occupancy()
	assert(board.is_exit_path_clear == true, "Path to exit must be clear when row 2 is unobstructed")
	assert(exit_signal["fired"] == true, "exit_path_cleared signal must fire on unobstructed path")
	print("✓ Exit Path Glow detection & signal verified!")

	# ----------------------------------------------------
	# 7. Verify Booster Undo & Inventory Refund Safeguard
	# ----------------------------------------------------
	print("\n--- 7. Testing Booster Undo & Refund Safeguard ---")
	gm.start_level(0)
	await process_frame
	await process_frame
	var pre_smash_count = gm.get_booster_count("sledgehammer")
	var target_obs = null
	for b in board.blocks:
		if not b.is_target:
			target_obs = b
			break
	var smashed_id = target_obs.block_id
	board.set_booster_mode("sledgehammer")
	board.handle_booster_interaction(target_obs)
	assert(board.find_block_by_id(smashed_id) == null, "Block should be smashed")
	
	# Now UNDO the sledgehammer booster!
	var undo_success = board.undo_last_move()
	assert(undo_success == true, "Undo booster should succeed")
	var restored_block = board.find_block_by_id(smashed_id)
	assert(restored_block != null, "Smashed block must be restored after Undo")
	assert(gm.get_booster_count("sledgehammer") == pre_smash_count, "Booster inventory must be refunded on Undo")
	print("✓ Sledgehammer Undo & 100% refund verified!")

	# ----------------------------------------------------
	# 8. Verify LevelSelect World Stats & Progress Bar
	# ----------------------------------------------------
	print("\n--- 8. Testing LevelSelect World Stats & Progress Bar ---")
	var ls_scene = load("res://scenes/LevelSelect.tscn")
	var ls_inst = ls_scene.instantiate()
	root.add_child(ls_inst)
	await process_frame
	assert(ls_inst.world_progress_bar != null, "LevelSelect must have world_progress_bar")
	assert(ls_inst.world_stats_label != null, "LevelSelect must have world_stats_label")
	# Switch to World 2
	ls_inst._switch_world(2, false)
	assert("WORLD 2" in ls_inst.world_title.text, "Title must update to World 2")
	assert("Stars:" in ls_inst.world_stats_label.text or "⭐" in ls_inst.world_stats_label.text, "Stats card must show stars")
	ls_inst.queue_free()
	print("✓ LevelSelect World Progress & Stats card verified!")

	# ----------------------------------------------------
	# 9. Verify Independent Haptics Setting & Persistence
	# ----------------------------------------------------
	print("\n--- 9. Testing Independent Haptics Toggle & Persistence ---")
	sm.set_haptics_enabled(true)
	assert(sm.is_haptics_enabled == true, "Haptics should be enabled")
	sm.toggle_haptics()
	assert(sm.is_haptics_enabled == false, "Haptics should be disabled after toggle")
	# Verify SettingsDialog controls
	var set_scene = load("res://scenes/SettingsDialog.tscn")
	var set_inst = set_scene.instantiate()
	root.add_child(set_inst)
	set_inst.open_dialog()
	assert(set_inst.haptic_toggle_btn != null, "SettingsDialog must have HapticToggleBtn")
	assert("OFF" in set_inst.haptic_toggle_btn.text, "Haptic button text should reflect OFF state")
	set_inst._on_haptic_toggle_pressed()
	assert(sm.is_haptics_enabled == true, "Haptic toggle button should re-enable haptics")
	assert("ON" in set_inst.haptic_toggle_btn.text, "Haptic button text should reflect ON state")
	set_inst.queue_free()
	print("✓ Independent Haptics setting & SettingsDialog UI verified!")

	# ----------------------------------------------------
	# 10. Verify GPGS Cloud Save & Leaderboard Scaffolding
	# ----------------------------------------------------
	print("\n--- 10. Testing GPGS Cloud Save & Leaderboard Scaffolding ---")
	var mm = root.get_node_or_null("MonetizationManager")
	if not mm:
		mm = load("res://scripts/monetization_manager.gd").new()
		root.add_child(mm)
	assert(mm.is_gpgs_available() == true, "GPGS must be available in debug/production")
	var gpgs_state = { "auth": false, "cloud_synced": false, "lb_score": 0 }
	mm.gpgs_sign_in(func(ok): gpgs_state["auth"] = ok)
	assert(gpgs_state["auth"] == true and mm.is_gpgs_authenticated == true, "GPGS sign in should complete")
	mm.sync_cloud_save({"coins": 500}, func(ok): gpgs_state["cloud_synced"] = ok)
	assert(gpgs_state["cloud_synced"] == true, "Cloud save sync should succeed")
	mm.gpgs_leaderboard_submitted.connect(func(s, ok): gpgs_state["lb_score"] = s)
	mm.submit_blitz_score(1500)
	assert(gpgs_state["lb_score"] == 1500, "Blitz leaderboard submission should succeed")
	print("✓ GPGS Cloud Save & Leaderboards verified!")

	# Clean reset to Level 1
	gm.reset_progress()

	print("\n==============================================")
	print(">>> ALL 10 BOOSTERS, DAILY & UX CHECKS PASSED 100%! <<<")
	print("==============================================\n")
	quit(0)
