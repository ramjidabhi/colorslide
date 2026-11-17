extends SceneTree

func _init() -> void:
	run()

func run() -> void:
	print("\n--- TESTING PROGRESSIVE DAILY CHALLENGE WORLD UNLOCKS ---")
	var gm = load("res://scripts/game_manager.gd").new()
	root.add_child(gm)
	gm.load_levels_from_disk()

	# 1. Player in World 1 (Level 1 to 50)
	gm.highest_unlocked_level = 20
	assert(gm.get_unlocked_max_world() == 1, "Max world should be 1")
	var p1 = gm.get_daily_puzzle_data("2026-11-14")
	print("World 1 Player (L20): Picked Level %d in World %d (%s) -> %s" % [
		p1.get("level_id"), p1.get("world_id"), p1.get("world_name"), p1.get("title")
	])
	assert(p1.get("world_id") == 1, "Must pick ONLY from World 1 when player is in World 1")

	# 2. Player in World 2 (Level 51 to 100)
	gm.highest_unlocked_level = 75
	assert(gm.get_unlocked_max_world() == 2, "Max world should be 2")
	var p2 = gm.get_daily_puzzle_data("2026-11-14")
	print("World 2 Player (L75): Picked Level %d in World %d (%s) -> %s" % [
		p2.get("level_id"), p2.get("world_id"), p2.get("world_name"), p2.get("title")
	])
	assert(p2.get("world_id") <= 2, "Must pick ONLY from Worlds 1 & 2 when player is in World 2")

	# 3. Player in World 3 (Level 101 to 150)
	gm.highest_unlocked_level = 130
	assert(gm.get_unlocked_max_world() == 3, "Max world should be 3")
	var p3 = gm.get_daily_puzzle_data("2026-11-14")
	print("World 3 Player (L130): Picked Level %d in World %d (%s) -> %s" % [
		p3.get("level_id"), p3.get("world_id"), p3.get("world_name"), p3.get("title")
	])
	assert(p3.get("world_id") <= 3, "Must pick ONLY from Worlds 1, 2 & 3 when player is in World 3")

	# 4. Player in World 4 (Level 151 to 200)
	gm.highest_unlocked_level = 180
	assert(gm.get_unlocked_max_world() == 4, "Max world should be 4")
	var p4 = gm.get_daily_puzzle_data("2026-11-14")
	print("World 4 Player (L180): Picked Level %d in World %d (%s) -> %s" % [
		p4.get("level_id"), p4.get("world_id"), p4.get("world_name"), p4.get("title")
	])
	assert(p4.get("world_id") <= 4, "Can pick from all 4 Worlds when player is in World 4")

	print("\n🎉 ALL PROGRESSIVE DAILY CHALLENGE CHECKS PASSED 100%!")
	quit(0)
