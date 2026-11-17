extends Node

## GameManager Autoload
## Manages global game state, level progression, move counting,
## persistent saves, Daily Challenge & Streak Engine, Milestone Star Chests,
## and the Cosmetics Customization Shop.

signal level_loaded(level_data: Dictionary)
signal moves_updated(current_moves: int)
signal level_completed(level_id: int, stars: int, moves: int, coins_earned: int, earned_crown: bool, opt_moves: int)
signal progress_saved()
signal daily_completed(streak: int, coins: int, is_new: bool)
signal chest_ready(milestone_level: int)
signal skin_changed(new_skin_id: String)
signal piggy_updated(current: int, max_val: int)
signal wheel_spun(reward_name: String)
signal hints_updated(new_count: int)
signal language_changed(new_locale: String)

const SAVE_PATH = "user://colorslide_save.json"
const BACKUP_SAVE_PATH = "user://colorslide_save.bak"
const TEMP_SAVE_PATH = "user://colorslide_save.tmp"
const CURRENT_SAVE_VERSION: int = 3
const LEVELS_PATH = "res://levels/levels.json"
const HINT_COIN_COST: int = 100
const PLAY_STORE_PACKAGE_ID: String = "com.colorslide.unblockescape"
const SUPPORTED_LOCALES: Array = ["en", "es", "de", "fr", "ja", "pt", "ko", "id"]

var all_levels: Array = []
var current_level_index: int = 0
var current_moves: int = 0
var total_coins: int = 30
var hints_count: int = 3
var hint_unlocked_for_current: bool = false
var highest_unlocked_level: int = 1
var stars_earned: Dictionary = {}  # "level_1": 3, etc.
var master_crowns: Dictionary = {}  # "1": true (beaten at or under optimal_moves)
var booster_free_crowns: Dictionary = {} # "1": true (beaten at or under par with 0 boosters used)
var best_level_moves: Dictionary = {} # "1": 12, etc. (personal best records)
var total_moves_made: int = 0
var total_playtime_seconds: int = 0
var _playtime_accum: float = 0.0
var boosters_used_in_current_level: bool = false
var is_level_active: bool = false
var has_rated_prompted: bool = false
var language_code: String = "en"

# Daily Challenge & Streaks
var last_daily_date: String = ""
var daily_streak: int = 0
var best_daily_streak: int = 0
var completed_dailies: Array = []
var is_daily_mode: bool = false
var current_daily_puzzle: Dictionary = {}

# Milestone Star Chests
var opened_chests: Array = []

# Cosmetics Customization
var unlocked_skins: Array = ["classic"]
var equipped_skin: String = "classic"

# Interactive Piggy Bank (Coin Vault - Paced Progression)
var piggy_coins: int = 0
const PIGGY_MAX: int = 200
const PIGGY_RATE: int = 3

# Daily Piggy & Wheel
var last_wheel_spin_time: int = 0
var last_piggy_boost_time: int = 0

# In-Game Boosters (Special Features)
var boosters_unlocked: bool = false
var booster_sledgehammers: int = 0
var booster_shrinks: int = 0
var booster_cranes: int = 0
const BOOSTER_COSTS = {
	"sledgehammer": 100,
	"shrink": 75,
	"crane": 90   # Dropped from 120→90: Crane can relocate any block (including to free the hero path)
}
signal boosters_updated()
signal boosters_unlocked_celebration()

# Rush Hour Blitz High Score
var blitz_high_score: int = 0
var _last_cloud_sync_attempt: int = 0
const CLOUD_SYNC_DEBOUNCE_SEC: int = 60

# Pet Rescue Expressive Mode & Accessibility
var pet_rescue_enabled: bool = true
var colorblind_mode: bool = false
var reduced_motion: bool = false
signal accessibility_updated()

const SKIN_DEFS = {
	"classic": { "name": "Classic Vibrant", "cost": 0, "desc": "Clean, colorful modern finish." },
	"neon": { "name": "Cyber Neon", "cost": 300, "desc": "Glowing electric cyan & magenta cyber lines." },
	"woodcraft": { "name": "Artisan Woodcraft", "cost": 500, "desc": "Rich mahogany woodgrain and carved bevels." },
	"gemstone": { "name": "Obsidian Gem", "cost": 800, "desc": "Lustrous crystal jewel glass and reflections." },
	"gold": { "name": "Royal Gold", "cost": 1200, "desc": "24k radiant gold edges & royal star insignia." }
}

func _ready() -> void:
	_detect_initial_locale()
	load_levels_from_disk()
	load_progress()
	TranslationServer.set_locale(language_code)

func _process(delta: float) -> void:
	if is_level_active:
		_playtime_accum += delta
		if _playtime_accum >= 1.0:
			var whole_sec = int(_playtime_accum)
			total_playtime_seconds += whole_sec
			_playtime_accum -= float(whole_sec)

func _detect_initial_locale() -> void:
	var sys_loc = OS.get_locale_language().to_lower()
	if SUPPORTED_LOCALES.has(sys_loc):
		language_code = sys_loc
	else:
		language_code = "en"

func set_language(code: String) -> void:
	if not SUPPORTED_LOCALES.has(code):
		code = "en"
	language_code = code
	TranslationServer.set_locale(language_code)
	save_progress()
	language_changed.emit(language_code)

func cycle_language() -> String:
	var idx = SUPPORTED_LOCALES.find(language_code)
	var next_code = SUPPORTED_LOCALES[(idx + 1) % SUPPORTED_LOCALES.size()]
	set_language(next_code)
	return next_code

func apply_safe_area(margin: MarginContainer, base_top: int = 64, base_bottom: int = 50, base_side: int = 36) -> void:
	if not margin or not is_inside_tree():
		return
	var win_size = DisplayServer.window_get_size()
	var safe = DisplayServer.get_display_safe_area()
	if win_size.x <= 0 or win_size.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return
	var vp_size = margin.get_viewport_rect().size
	var scale_y = vp_size.y / float(win_size.y)
	var scale_x = vp_size.x / float(win_size.x)
	var top_inset = int(ceil(float(safe.position.y) * scale_y))
	var bottom_inset = int(ceil(float(win_size.y - (safe.position.y + safe.size.y)) * scale_y))
	var left_inset = int(ceil(float(safe.position.x) * scale_x))
	var right_inset = int(ceil(float(win_size.x - (safe.position.x + safe.size.x)) * scale_x))
	margin.add_theme_constant_override("margin_top", maxi(base_top, top_inset + 20))
	margin.add_theme_constant_override("margin_bottom", maxi(base_bottom, bottom_inset + 20))
	margin.add_theme_constant_override("margin_left", maxi(base_side, left_inset + 16))
	margin.add_theme_constant_override("margin_right", maxi(base_side, right_inset + 16))

func load_levels_from_disk() -> void:
	if not FileAccess.file_exists(LEVELS_PATH):
		push_error("Levels file does not exist at " + LEVELS_PATH)
		return
	var file = FileAccess.open(LEVELS_PATH, FileAccess.READ)
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_str)
	if error == OK and json.data is Array:
		all_levels = json.data
	else:
		push_error("Failed to parse levels.json!")

func get_current_level_data() -> Dictionary:
	if is_daily_mode:
		return current_daily_puzzle
	if current_level_index >= 0 and current_level_index < all_levels.size():
		return all_levels[current_level_index]
	return {}

func start_level(level_index: int) -> void:
	is_daily_mode = false
	if all_levels.is_empty():
		load_levels_from_disk()
	if all_levels.is_empty():
		return
	if level_index < 0 or level_index >= all_levels.size():
		level_index = 0
	current_level_index = level_index
	current_moves = 0
	boosters_used_in_current_level = false
	hint_unlocked_for_current = false
	is_level_active = true
	
	var l_data = all_levels[current_level_index]
	var l_id = int(l_data.get("level_id", current_level_index + 1))
	if l_id >= 5 and not boosters_unlocked:
		unlock_boosters_starter_pack()
		boosters_unlocked_celebration.emit()
	var mm = get_node_or_null("/root/MonetizationManager") if is_inside_tree() else null
	if mm:
		mm.log_event("level_start", {"level_id": l_data.get("level_id", current_level_index + 1)})
	moves_updated.emit(current_moves)
	level_loaded.emit(l_data)

func restart_current_level() -> void:
	if is_daily_mode:
		start_daily_challenge()
	else:
		start_level(current_level_index)

func next_level() -> void:
	if is_daily_mode:
		go_to_menu()
		return
	var next_idx = current_level_index + 1
	if next_idx >= all_levels.size():
		next_idx = 0
	start_level(next_idx)

func prev_level() -> void:
	if is_daily_mode:
		return
	var prev_idx = current_level_index - 1
	if prev_idx < 0:
		prev_idx = all_levels.size() - 1
	start_level(prev_idx)

func play_level(level_index: int) -> void:
	is_daily_mode = false
	current_level_index = clamp(level_index, 0, all_levels.size() - 1)
	if get_tree().current_scene and get_tree().current_scene.scene_file_path == "res://scenes/Main.tscn":
		start_level(current_level_index)
	else:
		get_tree().change_scene_to_file("res://scenes/Main.tscn")

func go_to_menu() -> void:
	is_level_active = false
	is_daily_mode = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func go_to_level_select() -> void:
	is_level_active = false
	is_daily_mode = false
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func get_stars_for_level(level_id: int) -> int:
	var key = "level_" + str(level_id)
	return stars_earned.get(key, 0)

func reset_progress() -> void:
	stars_earned.clear()
	master_crowns.clear()
	booster_free_crowns.clear()
	highest_unlocked_level = 1
	total_coins = 30
	hints_count = 3
	hint_unlocked_for_current = false
	current_level_index = 0
	opened_chests.clear()
	boosters_unlocked = false
	booster_sledgehammers = 0
	booster_shrinks = 0
	booster_cranes = 0
	piggy_coins = 0
	save_progress()
	hints_updated.emit(hints_count)
	boosters_updated.emit()

func add_hints(amount: int) -> void:
	hints_count += amount
	save_progress()
	hints_updated.emit(hints_count)

func use_or_buy_hint() -> String:
	var l_data = get_current_level_data()
	var l_id = int(l_data.get("level_id", 1))
	if (not is_daily_mode and l_id == 1) or hint_unlocked_for_current:
		hint_unlocked_for_current = true
		return "free"
	if hints_count > 0:
		hints_count -= 1
		hint_unlocked_for_current = true
		save_progress()
		hints_updated.emit(hints_count)
		return "hint"
	if total_coins >= HINT_COIN_COST:
		total_coins -= HINT_COIN_COST
		hint_unlocked_for_current = true
		save_progress()
		return "coins"
	return "insufficient"

func _calculate_stars(moves: int, opt_moves: int) -> int:
	if moves <= opt_moves + 3:
		return 3
	var two_star_limit = maxi(opt_moves + 8, int(ceil(float(opt_moves) * 1.5)))
	if moves <= two_star_limit:
		return 2
	return 1

func register_move() -> void:
	if not is_level_active:
		return
	current_moves += 1
	total_moves_made += 1
	moves_updated.emit(current_moves)

func complete_level() -> void:
	if not is_level_active:
		return
	is_level_active = false
	
	if is_daily_mode:
		_complete_daily()
		return
		
	var l_data = get_current_level_data()
	var l_id = int(l_data.get("level_id", 1))
	var opt_moves = int(l_data.get("optimal_moves", 20))
	var earned_crown = (current_moves <= opt_moves)
	if earned_crown:
		master_crowns[str(l_id)] = true
		if not boosters_used_in_current_level:
			booster_free_crowns[str(l_id)] = true
		
	# Personal best moves tracking
	var key_num = str(l_id)
	var prev_best = int(best_level_moves.get(key_num, 999999))
	if current_moves < prev_best:
		best_level_moves[key_num] = current_moves
		
	var stars = _calculate_stars(current_moves, opt_moves)
	
	# Tiered Coins Reward (Paced & Balanced Economy):
	# First-time completion awards full milestone reward:
	# - 3★ or Par Crown: 15 coins
	# - 2★: 10 coins
	# - 1★: 5 coins
	# - Pure Par Bonus (no boosters): +5 coins
	# - Early Levels (1–5 tutorial boost): +5 coins
	# Replaying already completed level awards a modest practice reward (2 coins)
	var key = "level_" + str(l_id)
	var is_first_clear = not stars_earned.has(key)
	
	var coins_reward = 0
	if is_first_clear:
		var base_coins = 10
		if earned_crown or stars == 3:
			base_coins = 15
		elif stars == 1:
			base_coins = 5
		else:
			base_coins = 10

		var early_boost = 5 if l_id <= 5 else 0
		var pure_boost = 5 if (earned_crown and not boosters_used_in_current_level) else 0
		coins_reward = base_coins + early_boost + pure_boost
	else:
		coins_reward = 2 if (earned_crown or stars == 3) else 1

	total_coins += coins_reward
	
	# Piggy bank vault deposit (+25 coins)
	piggy_coins = mini(PIGGY_MAX, piggy_coins + PIGGY_RATE)
	piggy_updated.emit(piggy_coins, PIGGY_MAX)
	
	# Save best stars record (never downgrade on replay)
	stars_earned[key] = maxi(int(stars_earned.get(key, 0)), stars)
		
	# Unlock next level one-by-one
	if l_id + 1 > highest_unlocked_level:
		highest_unlocked_level = mini(all_levels.size() if not all_levels.is_empty() else 200, l_id + 1)
		
	save_progress()
	level_completed.emit(l_id, stars, current_moves, coins_reward, earned_crown, opt_moves)

	var mm = get_node_or_null("/root/MonetizationManager") if is_inside_tree() else null
	if mm:
		mm.log_event("level_complete", {"level_id": l_id, "stars": stars, "moves": current_moves, "crown": earned_crown})
		mm.maybe_show_interstitial(l_id)
	
	# Check milestone star chest (every 10 levels: L10, L20, L30... L200)
	if l_id % 10 == 0 and not opened_chests.has(l_id):
		chest_ready.emit(l_id)
		
	# Check booster unlock celebration (Level 5+)
	if l_id >= 5 and not boosters_unlocked:
		unlock_boosters_starter_pack()
		boosters_unlocked_celebration.emit()

# ----------------- DAILY CHALLENGE & STREAK ENGINE -----------------

func get_today_date_str() -> String:
	var dt = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]

func get_yesterday_date_str() -> String:
	var now_unix = int(Time.get_unix_time_from_system())
	return Time.get_date_string_from_unix_time(now_unix - 86400)

func is_daily_completed_today() -> bool:
	return completed_dailies.has(get_today_date_str())

func get_unlocked_max_world() -> int:
	if highest_unlocked_level > 150:
		return 4
	elif highest_unlocked_level > 100:
		return 3
	elif highest_unlocked_level > 50:
		return 2
	else:
		return 1

func get_daily_puzzle_data(date_str: String = "") -> Dictionary:
	if date_str == "":
		date_str = get_today_date_str()
	if all_levels.is_empty():
		load_levels_from_disk()
	
	# Progressive Daily Pool based on player's highest unlocked world:
	# - World 1 only (Levels 1-50): Levels 1-50 (14-20 moves)
	# - Worlds 1-2 (Levels 51-100): Levels 1-100 (14-25 moves)
	# - Worlds 1-3 (Levels 101-150): Levels 1-150 (14-28 moves)
	# - Worlds 1-4 (Levels 151-200): All 200 levels (14-28 moves)
	var max_world = get_unlocked_max_world()
	
	var med_hard_pool: Array = []
	for lvl in all_levels:
		var w_id = int(lvl.get("world_id", 1))
		var opt = int(lvl.get("optimal_moves", 0))
		if w_id <= max_world:
			if opt >= 14 and opt <= 28:
				med_hard_pool.append(lvl)
				
	if med_hard_pool.is_empty():
		for lvl in all_levels:
			if int(lvl.get("world_id", 1)) <= max_world:
				med_hard_pool.append(lvl)
	if med_hard_pool.is_empty():
		med_hard_pool = all_levels
		
	var h = abs(date_str.hash())
	var idx = h % med_hard_pool.size()
	var p = med_hard_pool[idx].duplicate(true)
	
	p["is_daily"] = true
	p["date_str"] = date_str
	p["title"] = "Daily Mind Forge • " + date_str
	
	var world_tag = "World 1"
	match max_world:
		1: world_tag = "World 1"
		2: world_tag = "Worlds 1–2"
		3: world_tag = "Worlds 1–3"
		4: world_tag = "All 4 Worlds"
		
	p["world_name"] = "🔥 Daily Mind Forge (%s)" % world_tag
	p["difficulty"] = "Medium-Hard"
	p["bounty_coins"] = 100
	return p

# ----------------- IN-GAME BOOSTERS (SPECIAL FEATURES) -----------------

func get_booster_count(booster_type: String) -> int:
	match booster_type:
		"sledgehammer": return booster_sledgehammers
		"shrink": return booster_shrinks
		"crane": return booster_cranes
	return 0

func get_booster_cost(booster_type: String) -> int:
	return BOOSTER_COSTS.get(booster_type, 100)

func can_afford_booster(booster_type: String) -> bool:
	if get_booster_count(booster_type) > 0:
		return true
	return total_coins >= get_booster_cost(booster_type)

func consume_booster(booster_type: String) -> bool:
	boosters_used_in_current_level = true
	if get_booster_count(booster_type) > 0:
		match booster_type:
			"sledgehammer": booster_sledgehammers -= 1
			"shrink": booster_shrinks -= 1
			"crane": booster_cranes -= 1
		boosters_updated.emit()
		save_progress()
		return true
	var cost = get_booster_cost(booster_type)
	if total_coins >= cost:
		total_coins -= cost
		boosters_updated.emit()
		save_progress()
		return true
	return false

func add_booster(booster_type: String, count: int = 1) -> void:
	match booster_type:
		"sledgehammer": booster_sledgehammers += count
		"shrink": booster_shrinks += count
		"crane": booster_cranes += count
	boosters_updated.emit()
	save_progress()

func unlock_boosters_starter_pack() -> void:
	boosters_unlocked = true
	# Provide strictly 3 of each booster (Smash: 3, Shrink: 3, Crane: 3)
	booster_sledgehammers = 3
	booster_shrinks = 3
	booster_cranes = 3
	boosters_updated.emit()
	save_progress()

func start_daily_challenge() -> void:
	is_daily_mode = true
	current_daily_puzzle = get_daily_puzzle_data()
	current_moves = 0
	hint_unlocked_for_current = false
	is_level_active = true
	
	if get_tree().current_scene and get_tree().current_scene.scene_file_path == "res://scenes/Main.tscn":
		moves_updated.emit(current_moves)
		level_loaded.emit(current_daily_puzzle)
	else:
		get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _complete_daily() -> void:
	var today_str = get_today_date_str()
	var yesterday_str = get_yesterday_date_str()
	var is_first_time_today = not completed_dailies.has(today_str)
	var coins_reward = 30
	
	if is_first_time_today:
		completed_dailies.append(today_str)
		if last_daily_date == yesterday_str:
			daily_streak += 1
		elif last_daily_date == today_str:
			pass
		else:
			daily_streak = 1
			
		if daily_streak > best_daily_streak:
			best_daily_streak = daily_streak
			
		last_daily_date = today_str
		
		# Streak bonus rewards
		if daily_streak == 3:
			coins_reward += 25
		elif daily_streak >= 7:
			coins_reward += 50
			if not unlocked_skins.has("gold"):
				unlocked_skins.append("gold")
				
		total_coins += coins_reward
	else:
		coins_reward = 5 # replay practice
		total_coins += coins_reward
		
	var opt_moves = int(current_daily_puzzle.get("optimal_moves", 20))
	var earned_crown = (current_moves <= opt_moves)
	save_progress()
	daily_completed.emit(daily_streak, coins_reward, is_first_time_today)
	level_completed.emit(999, _calculate_stars(current_moves, opt_moves), current_moves, coins_reward, earned_crown, opt_moves)

# ----------------- MILESTONE CHESTS -----------------

func claim_milestone_chest(milestone_level: int) -> Dictionary:
	if not opened_chests.has(milestone_level):
		opened_chests.append(milestone_level)
		var bonus_coins = 35
		var bonus_hints = 1
		total_coins += bonus_coins
		hints_count += bonus_hints
		save_progress()
		hints_updated.emit(hints_count)
		return { "coins": bonus_coins, "hints": bonus_hints, "level": milestone_level }
	return {}

# ----------------- COSMETICS & SKINS -----------------

func unlock_skin(skin_id: String) -> bool:
	if unlocked_skins.has(skin_id):
		return true
	if not SKIN_DEFS.has(skin_id):
		return false
	var cost = SKIN_DEFS[skin_id].get("cost", 0)
	if total_coins >= cost:
		total_coins -= cost
		unlocked_skins.append(skin_id)
		equipped_skin = skin_id
		save_progress()
		skin_changed.emit(skin_id)
		return true
	return false

func equip_skin(skin_id: String) -> void:
	if unlocked_skins.has(skin_id) and SKIN_DEFS.has(skin_id):
		equipped_skin = skin_id
		save_progress()
		skin_changed.emit(skin_id)

# ----------------- PIGGY BANK & LUCKY WHEEL -----------------

func smash_piggy_bank() -> int:
	var claimed = piggy_coins
	if claimed > 0:
		total_coins += claimed
		piggy_coins = 0
		save_progress()
		piggy_updated.emit(piggy_coins, PIGGY_MAX)
		var sm = get_node_or_null("/root/SoundManager") if is_inside_tree() else null
		if sm:
			sm.play_win()
	return claimed

func add_piggy_coins(amount: int) -> int:
	piggy_coins = mini(PIGGY_MAX, piggy_coins + amount)
	save_progress()
	piggy_updated.emit(piggy_coins, PIGGY_MAX)
	return piggy_coins

func can_claim_piggy_boost() -> bool:
	var now = int(Time.get_unix_time_from_system())
	return (now - last_piggy_boost_time) >= 86400

func record_piggy_boost() -> int:
	last_piggy_boost_time = int(Time.get_unix_time_from_system())
	return add_piggy_coins(50)

func record_blitz_score(score: int) -> bool:
	var is_new = (score > blitz_high_score)
	if is_new:
		blitz_high_score = score
	var earned = int(score / 5.0)
	if earned > 0:
		total_coins += earned
	save_progress()
	var mm = get_node_or_null("/root/MonetizationManager") if is_inside_tree() else null
	if mm and mm.has_method("submit_blitz_score"):
		mm.submit_blitz_score(score)
	return is_new

func can_spin_wheel() -> bool:
	var now = int(Time.get_unix_time_from_system())
	return (now - last_wheel_spin_time) >= 86400  # 24 hours

func get_seconds_until_next_spin() -> int:
	var now = int(Time.get_unix_time_from_system())
	var diff = 86400 - (now - last_wheel_spin_time)
	return maxi(0, diff)

func record_wheel_spin() -> void:
	last_wheel_spin_time = int(Time.get_unix_time_from_system())
	save_progress()

func claim_wheel_reward(reward_type: String, amount: int) -> void:
	if reward_type == "coins":
		total_coins += amount
	elif reward_type == "hints":
		hints_count += amount
		hints_updated.emit(hints_count)
	elif reward_type == "skin":
		if not unlocked_skins.has("gemstone"):
			unlocked_skins.append("gemstone")
		elif not unlocked_skins.has("gold"):
			unlocked_skins.append("gold")
		else:
			total_coins += 500
	save_progress()
	wheel_spun.emit("%s +%d" % [reward_type, amount])

# ----------------- PERSISTENCE (ATOMIC SAVE & BACKUP RECOVERY) -----------------

func save_progress() -> void:
	var sm = get_node_or_null("/root/SoundManager") if is_inside_tree() else null
	var mm = get_node_or_null("/root/MonetizationManager") if is_inside_tree() else null
	var is_sound_muted = sm.is_muted if sm else false
	var is_music_muted = sm.is_music_muted if sm else false
	var is_haptics_enabled = sm.is_haptics_enabled if sm else true
	var is_ads_removed = mm.ads_removed if mm else false
	var save_dict = {
		"save_version": CURRENT_SAVE_VERSION,
		"coins": total_coins,
		"hints_count": hints_count,
		"highest_unlocked": highest_unlocked_level,
		"stars": stars_earned,
		"master_crowns": master_crowns,
		"booster_free_crowns": booster_free_crowns,
		"best_level_moves": best_level_moves,
		"total_moves_made": total_moves_made,
		"total_playtime_seconds": total_playtime_seconds,
		"sound_muted": is_sound_muted,
		"music_muted": is_music_muted,
		"haptics_enabled": is_haptics_enabled,
		"ads_removed": is_ads_removed,
		"language_code": language_code,
		"last_daily_date": last_daily_date,
		"daily_streak": daily_streak,
		"best_daily_streak": best_daily_streak,
		"completed_dailies": completed_dailies,
		"opened_chests": opened_chests,
		"unlocked_skins": unlocked_skins,
		"equipped_skin": equipped_skin,
		"piggy_coins": piggy_coins,
		"boosters_unlocked": boosters_unlocked,
		"booster_sledgehammers": booster_sledgehammers,
		"booster_shrinks": booster_shrinks,
		"booster_cranes": booster_cranes,
		"last_wheel_spin_time": last_wheel_spin_time,
		"last_piggy_boost_time": last_piggy_boost_time,
		"blitz_high_score": blitz_high_score,
		"pet_rescue_enabled": pet_rescue_enabled,
		"colorblind_mode": colorblind_mode,
		"reduced_motion": reduced_motion,
		"has_rated_prompted": has_rated_prompted
	}
	
	var json_data = JSON.stringify(save_dict, "\t")
	
	# Atomic write: Write to .tmp first to prevent half-written files on crash
	var tmp_file = FileAccess.open(TEMP_SAVE_PATH, FileAccess.WRITE)
	if tmp_file:
		tmp_file.store_string(json_data)
		tmp_file.flush()
		tmp_file.close()
		
		# If primary save exists and is valid, backup to .bak
		if FileAccess.file_exists(SAVE_PATH):
			var cur_read = FileAccess.open(SAVE_PATH, FileAccess.READ)
			if cur_read:
				var bak_content = cur_read.get_as_text()
				cur_read.close()
				if not bak_content.strip_edges().is_empty():
					var bak_file = FileAccess.open(BACKUP_SAVE_PATH, FileAccess.WRITE)
					if bak_file:
						bak_file.store_string(bak_content)
						bak_file.flush()
						bak_file.close()
		
		# Now write atomically to main save
		var main_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if main_file:
			main_file.store_string(json_data)
			main_file.flush()
			main_file.close()
			
		DirAccess.remove_absolute(TEMP_SAVE_PATH)
		progress_saved.emit()
		
	if mm and mm.has_method("sync_cloud_save") and mm.is_gpgs_authenticated:
		var now_sync = int(Time.get_unix_time_from_system())
		if now_sync - _last_cloud_sync_attempt >= CLOUD_SYNC_DEBOUNCE_SEC:
			_last_cloud_sync_attempt = now_sync
			mm.sync_cloud_save(save_dict)

func load_progress() -> void:
	var path_to_load = SAVE_PATH
	if not FileAccess.file_exists(path_to_load):
		if FileAccess.file_exists(BACKUP_SAVE_PATH):
			path_to_load = BACKUP_SAVE_PATH
		else:
			return
			
	var file = FileAccess.open(path_to_load, FileAccess.READ)
	if not file:
		return
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(content)
	if err != OK or not (json.data is Dictionary):
		# Primary was corrupt, attempt recovery from .bak
		if path_to_load != BACKUP_SAVE_PATH and FileAccess.file_exists(BACKUP_SAVE_PATH):
			var bak_file = FileAccess.open(BACKUP_SAVE_PATH, FileAccess.READ)
			if bak_file:
				var bak_content = bak_file.get_as_text()
				bak_file.close()
				if json.parse(bak_content) == OK and json.data is Dictionary:
					content = bak_content
				else:
					return
		else:
			return
			
	if json.data is Dictionary:
		var d = json.data
		total_coins = int(d.get("coins", 30))
		hints_count = int(d.get("hints_count", 3))
		highest_unlocked_level = int(d.get("highest_unlocked", 1))
		stars_earned = d.get("stars", {})
		master_crowns = d.get("master_crowns", {})
		booster_free_crowns = d.get("booster_free_crowns", {})
		best_level_moves = d.get("best_level_moves", {})
		total_moves_made = int(d.get("total_moves_made", 0))
		total_playtime_seconds = int(d.get("total_playtime_seconds", 0))
		var sm = get_node_or_null("/root/SoundManager") if is_inside_tree() else null
		if sm:
			if d.has("sound_muted"):
				sm.is_muted = d.get("sound_muted", false)
			if d.has("music_muted") and sm.has_method("set_music_muted"):
				sm.set_music_muted(d.get("music_muted", false))
			if d.has("haptics_enabled") and sm.has_method("set_haptics_enabled"):
				sm.set_haptics_enabled(d.get("haptics_enabled", true))
		var mm = get_node_or_null("/root/MonetizationManager") if is_inside_tree() else null
		if mm and d.has("ads_removed"):
			mm.ads_removed = d.get("ads_removed", false)
		if d.has("language_code"):
			var saved_loc = str(d.get("language_code", "en"))
			if SUPPORTED_LOCALES.has(saved_loc):
				language_code = saved_loc
				TranslationServer.set_locale(language_code)
		last_daily_date = d.get("last_daily_date", "")
		daily_streak = int(d.get("daily_streak", 0))
		best_daily_streak = int(d.get("best_daily_streak", 0))
		completed_dailies = d.get("completed_dailies", [])
		opened_chests = d.get("opened_chests", [])
		unlocked_skins = d.get("unlocked_skins", ["classic"])
		equipped_skin = d.get("equipped_skin", "classic")
		piggy_coins = int(d.get("piggy_coins", 0))
		boosters_unlocked = bool(d.get("boosters_unlocked", highest_unlocked_level >= 5))
		booster_sledgehammers = int(d.get("booster_sledgehammers", 0))
		booster_shrinks = int(d.get("booster_shrinks", 0))
		booster_cranes = int(d.get("booster_cranes", 0))
		last_wheel_spin_time = int(d.get("last_wheel_spin_time", 0))
		last_piggy_boost_time = int(d.get("last_piggy_boost_time", 0))
		blitz_high_score = int(d.get("blitz_high_score", 0))
		pet_rescue_enabled = d.get("pet_rescue_enabled", true)
		colorblind_mode = d.get("colorblind_mode", false)
		reduced_motion = d.get("reduced_motion", false)
		has_rated_prompted = d.get("has_rated_prompted", false)

func get_personal_best_moves(level_id: int) -> int:
	return int(best_level_moves.get(str(level_id), 0))

func get_total_stars() -> int:
	var total = 0
	for k in stars_earned.keys():
		total += int(stars_earned[k])
	return total

func get_total_crowns() -> int:
	return master_crowns.size()

func get_total_booster_free_crowns() -> int:
	return booster_free_crowns.size()

func get_completed_levels_count() -> int:
	var count = 0
	for k in stars_earned.keys():
		if int(stars_earned[k]) > 0:
			count += 1
	return count

func get_completion_percentage() -> float:
	var total_lvls = all_levels.size() if not all_levels.is_empty() else 200
	return (float(get_completed_levels_count()) / float(total_lvls)) * 100.0
