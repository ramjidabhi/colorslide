extends SceneTree

func _init() -> void:
	print("--- BEGIN RETENTION & DAU TEST ---")
	
	# 1. Test GameManager Loading
	var gm_script = load("res://scripts/game_manager.gd")
	var gm = Node.new()
	gm.name = "GameManager"
	gm.set_script(gm_script)
	root.add_child(gm)
	gm._ready()
	
	# 2. Test Daily Challenge Logic
	var today = gm.get_today_date_str()
	print("Today Date:", today)
	assert(today.length() == 10, "Date string format invalid")
	
	var daily_p = gm.get_daily_puzzle_data(today)
	print("Daily Puzzle Title:", daily_p.get("title"))
	assert(daily_p.get("is_daily") == true, "Daily flag missing")
	assert(daily_p.has("blocks"), "Daily puzzle missing blocks")
	
	# Test Streak progression
	gm.completed_dailies.clear()
	gm.daily_streak = 2
	gm.last_daily_date = gm.get_yesterday_date_str()
	gm.is_daily_mode = true
	gm.is_level_active = true
	gm.complete_level()
	print("New Daily Streak:", gm.daily_streak)
	assert(gm.daily_streak == 3, "Streak should advance to 3")
	assert(gm.is_daily_completed_today() == true, "Should be marked completed today")
	
	# 3. Test Milestone Chest
	var chest_res = gm.claim_milestone_chest(10)
	print("Chest 10 Claimed:", chest_res)
	assert(chest_res.get("coins") == 150, "Milestone chest should give 150 coins")
	assert(gm.opened_chests.has(10), "Chest 10 should be in opened_chests")
	
	# 4. Test Cosmetics & Skins
	gm.total_coins = 1000
	gm.unlocked_skins = ["classic"]
	gm.equipped_skin = "classic"
	var unlocked_neon = gm.unlock_skin("neon")
	print("Unlocked Neon Skin:", unlocked_neon)
	assert(unlocked_neon == true, "Should unlock neon skin")
	assert(gm.equipped_skin == "neon", "Neon should be equipped")
	
	# 5. Test Scene Loading
	var main_scene = load("res://scenes/Main.tscn")
	assert(main_scene != null, "Main.tscn failed to load")
	
	var menu_scene = load("res://scenes/MainMenu.tscn")
	assert(menu_scene != null, "MainMenu.tscn failed to load")
	
	var daily_scene = load("res://scenes/DailyChallengeDialog.tscn")
	assert(daily_scene != null, "DailyChallengeDialog.tscn failed to load")
	
	var chest_scene = load("res://scenes/StarChestDialog.tscn")
	assert(chest_scene != null, "StarChestDialog.tscn failed to load")
	
	var shop_scene = load("res://scenes/ShopDialog.tscn")
	assert(shop_scene != null, "ShopDialog.tscn failed to load")
	
	print("--- ALL RETENTION & DAU TESTS PASSED! ---")
	quit(0)
