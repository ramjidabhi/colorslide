extends Control

## LevelSelect.gd - Grid of 200 Levels across 4 Worlds
## Renders interactive level cards with 3-star ratings, lock states,
## world switching tabs, and back button navigation.

@onready var back_btn: Button = $SafeMargin/MainLayout/TopBar/BackButton
@onready var stars_total_label: Label = $SafeMargin/MainLayout/TopBar/StarsBox/StarsLabel
@onready var coins_label: Label = $SafeMargin/MainLayout/TopBar/CoinsBox/CoinsLabel
@onready var world_title: Label = $SafeMargin/MainLayout/HeaderBox/WorldTitle
@onready var sub_title: Label = $SafeMargin/MainLayout/HeaderBox/SubTitle
@onready var world_progress_bar: ProgressBar = get_node_or_null("SafeMargin/MainLayout/HeaderBox/WorldProgressBox/WorldProgressBar")
@onready var world_stats_label: Label = get_node_or_null("SafeMargin/MainLayout/HeaderBox/WorldProgressBox/WorldStatsLabel")
@onready var tab1: Button = $SafeMargin/MainLayout/WorldTabs/Tab1
@onready var tab2: Button = $SafeMargin/MainLayout/WorldTabs/Tab2
@onready var tab3: Button = $SafeMargin/MainLayout/WorldTabs/Tab3
@onready var tab4: Button = $SafeMargin/MainLayout/WorldTabs/Tab4
@onready var grid_container: GridContainer = $SafeMargin/MainLayout/Scroll/GridMargin/GridContainer

var current_world: int = 1

var card_style_unlocked: StyleBoxFlat
var card_style_locked: StyleBoxFlat
var card_style_current: StyleBoxFlat
var tab_style_active: StyleBoxFlat
var tab_style_inactive: StyleBoxFlat

const WORLD_INFO = {
	1: {
		"title": "WORLD 1: BEGINNER ESCAPE",
		"sub": "Levels 1–50 • Classic Sliding Foundations",
		"start_lvl": 1,
		"end_lvl": 50
	},
	2: {
		"title": "WORLD 2: STRATEGIC TRAFFIC JAM",
		"sub": "Levels 51–100 • 3-Cell Trucks & Deadlock Shifts",
		"start_lvl": 51,
		"end_lvl": 100
	},
	3: {
		"title": "WORLD 3: FROST CAVERN",
		"sub": "Levels 101–150 • Ice Locks & Thaw Mechanics ❄️",
		"start_lvl": 101,
		"end_lvl": 150
	},
	4: {
		"title": "WORLD 4: LASER FACILITY",
		"sub": "Levels 151–200 • Switches ⚡ & Laser Barriers",
		"start_lvl": 151,
		"end_lvl": 200
	}
}

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	tab1.pressed.connect(func(): _switch_world(1))
	tab2.pressed.connect(func(): _switch_world(2))
	tab3.pressed.connect(func(): _switch_world(3))
	tab4.pressed.connect(func(): _switch_world(4))
	
	_init_styles()
	
	# Detect which world player is currently on
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.apply_safe_area(get_node_or_null("SafeMargin"), 70, 40, 40)
		var current_lvl = clamp(gm.highest_unlocked_level, 1, 200)
		if current_lvl > 150:
			current_world = 4
		elif current_lvl > 100:
			current_world = 3
		elif current_lvl > 50:
			current_world = 2
		else:
			current_world = 1
			
	_update_world_tab_badges()
	if back_btn:
		back_btn.text = tr("BTN_BACK_MENU_LS")
	_switch_world(current_world, false)

func _update_world_tab_badges() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	var tabs = [tab1, tab2, tab3, tab4]
	for w in range(1, 5):
		var start_l = WORLD_INFO[w]["start_lvl"]
		var end_l = WORLD_INFO[w]["end_lvl"]
		var w_stars = 0
		for lid in range(start_l, end_l + 1):
			w_stars += gm.get_stars_for_level(lid)
		if tabs[w - 1]:
			tabs[w - 1].text = "W%d • %d★" % [w, w_stars]

func _init_styles() -> void:
	card_style_unlocked = StyleBoxFlat.new()
	card_style_unlocked.bg_color = Color("#1D2333")
	card_style_unlocked.set_corner_radius_all(18)
	card_style_unlocked.border_width_left = 2
	card_style_unlocked.border_width_top = 2
	card_style_unlocked.border_width_right = 2
	card_style_unlocked.border_width_bottom = 2
	card_style_unlocked.border_color = Color("#2D364D")
	card_style_unlocked.anti_aliasing = true

	card_style_current = StyleBoxFlat.new()
	card_style_current.bg_color = Color("#1E2D44")
	card_style_current.set_corner_radius_all(18)
	card_style_current.border_width_left = 3
	card_style_current.border_width_top = 3
	card_style_current.border_width_right = 3
	card_style_current.border_width_bottom = 3
	card_style_current.border_color = Color("#00D2D3")
	card_style_current.shadow_color = Color(0, 0.82, 0.82, 0.3)
	card_style_current.shadow_size = 10
	card_style_current.anti_aliasing = true

	card_style_locked = StyleBoxFlat.new()
	card_style_locked.bg_color = Color("#141722")
	card_style_locked.set_corner_radius_all(18)
	card_style_locked.anti_aliasing = true

	tab_style_active = StyleBoxFlat.new()
	tab_style_active.bg_color = Color(0.0, 0.75, 0.75, 1.0)
	tab_style_active.set_corner_radius_all(16)

	tab_style_inactive = StyleBoxFlat.new()
	tab_style_inactive.bg_color = Color(0.16, 0.20, 0.28, 1.0)
	tab_style_inactive.set_corner_radius_all(16)

func _switch_world(w_id: int, play_sfx: bool = true) -> void:
	if play_sfx:
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_tap()
		
	current_world = w_id
	var info = WORLD_INFO.get(w_id, WORLD_INFO[1])
	world_title.text = tr("WORLD_%d_TITLE" % w_id)
	sub_title.text = tr("WORLD_%d_SUB" % w_id)
	
	# Update tab buttons visual
	tab1.add_theme_stylebox_override("normal", tab_style_active if w_id == 1 else tab_style_inactive)
	tab2.add_theme_stylebox_override("normal", tab_style_active if w_id == 2 else tab_style_inactive)
	tab3.add_theme_stylebox_override("normal", tab_style_active if w_id == 3 else tab_style_inactive)
	tab4.add_theme_stylebox_override("normal", tab_style_active if w_id == 4 else tab_style_inactive)
	
	_update_world_stats(w_id)
	_populate_levels(info["start_lvl"], info["end_lvl"])

func _update_world_stats(w_id: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	var info = WORLD_INFO.get(w_id, WORLD_INFO[1])
	var start_l: int = info["start_lvl"]
	var end_l: int = info["end_lvl"]
	var total_levels: int = end_l - start_l + 1
	var max_stars: int = total_levels * 3
	
	var stars_count: int = 0
	var crowns_count: int = 0
	var cleared_count: int = 0
	for lid in range(start_l, end_l + 1):
		var s: int = gm.get_stars_for_level(lid)
		stars_count += s
		if s > 0 or lid < gm.highest_unlocked_level:
			cleared_count += 1
		if gm.master_crowns.has(str(lid)):
			crowns_count += 1
			
	if world_progress_bar:
		world_progress_bar.max_value = float(total_levels)
		world_progress_bar.value = float(cleared_count)
	if world_stats_label:
		var stars_txt = tr("LBL_STARS") if tr("LBL_STARS") != "LBL_STARS" else "Stars"
		var crowns_txt = tr("LBL_CROWNS") if tr("LBL_CROWNS") != "LBL_CROWNS" else "Crowns"
		var cleared_txt = tr("LBL_CLEARED") if tr("LBL_CLEARED") != "LBL_CLEARED" else "Cleared"
		world_stats_label.text = "⭐ %s: %d/%d • 👑 %s: %d/%d • 🔓 %s: %d/%d" % [
			stars_txt, stars_count, max_stars,
			crowns_txt, crowns_count, total_levels,
			cleared_txt, cleared_count, total_levels
		]

func _populate_levels(start_lvl: int, end_lvl: int) -> void:
	for child in grid_container.get_children():
		child.queue_free()
		
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
		
	coins_label.text = "🪙 " + str(gm.total_coins)
	
	var total_stars = 0
	for k in gm.stars_earned:
		total_stars += gm.stars_earned[k]
	stars_total_label.text = "⭐ " + str(total_stars) + " / 600"
	
	for lvl_id in range(start_lvl, end_lvl + 1):
		var is_unlocked = (lvl_id <= gm.highest_unlocked_level)
		var is_current = (lvl_id == gm.highest_unlocked_level)
		var stars = gm.get_stars_for_level(lvl_id)
		
		var card = Button.new()
		card.custom_minimum_size = Vector2(150, 154)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.theme_type_variation = "FlatButton"
		
		# Inner Layout
		var vbox = VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 6)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(vbox)
		
		var num_label = Label.new()
		num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var stars_label = Label.new()
		stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stars_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var has_crown = gm.master_crowns.has(str(lvl_id))
		if is_unlocked:
			card.add_theme_stylebox_override("normal", card_style_current if is_current else card_style_unlocked)
			if has_crown:
				num_label.text = "👑 " + str(lvl_id)
				num_label.add_theme_color_override("font_color", Color(1, 0.88, 0.25, 1))
				num_label.add_theme_font_size_override("font_size", 36)
			else:
				num_label.text = str(lvl_id)
				num_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
				num_label.add_theme_font_size_override("font_size", 42)
			
			var stars_str = ""
			for s in range(3):
				stars_str += "★" if s < stars else "☆"
			stars_label.text = stars_str
			stars_label.add_theme_font_size_override("font_size", 26)
			stars_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
		else:
			card.add_theme_stylebox_override("normal", card_style_locked)
			num_label.text = "🔒"
			num_label.add_theme_font_size_override("font_size", 36)
			num_label.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55, 0.7))
			
			stars_label.text = str(lvl_id)
			stars_label.add_theme_font_size_override("font_size", 22)
			stars_label.add_theme_color_override("font_color", Color(0.35, 0.4, 0.5, 0.7))
			
		vbox.add_child(num_label)
		vbox.add_child(stars_label)
		
		# Strictly enforce one-by-one level locking
		var target_index = lvl_id - 1
		if is_unlocked:
			var lvl_info = gm.all_levels[target_index] if target_index < gm.all_levels.size() else {}
			var opt_moves = int(lvl_info.get("optimal_moves", 10))
			var diff_str = "Easy" if opt_moves <= 8 else ("Medium" if opt_moves <= 16 else "Hard")
			card.tooltip_text = "Level %d • %s (Par: %d moves)" % [lvl_id, diff_str, opt_moves]
			card.pressed.connect(func(): _on_level_selected(target_index))
		else:
			card.pressed.connect(func(): _on_locked_level_tapped(card, lvl_id))
		grid_container.add_child(card)

	_scroll_to_current_level(start_lvl, end_lvl, gm.highest_unlocked_level)

func _scroll_to_current_level(start_lvl: int, end_lvl: int, unlocked_lvl: int) -> void:
	var scroll = get_node_or_null("SafeMargin/MainLayout/Scroll") as ScrollContainer
	if not scroll:
		return
	if unlocked_lvl < start_lvl or unlocked_lvl > end_lvl:
		scroll.scroll_vertical = 0
		return
	var rel_idx = unlocked_lvl - start_lvl
	var cols = maxi(1, grid_container.columns)
	var row = int(rel_idx / cols)
	await get_tree().process_frame
	if is_inside_tree() and scroll:
		scroll.scroll_vertical = maxi(0, (row - 1) * 180)

func _on_locked_level_tapped(card: Control, lvl_id: int) -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_bump()
	# Gentle horizontal wiggle on locked card
	var orig_x = card.position.x
	var tw = create_tween()
	tw.tween_property(card, "position:x", orig_x - 8.0, 0.04)
	tw.tween_property(card, "position:x", orig_x + 8.0, 0.04)
	tw.tween_property(card, "position:x", orig_x, 0.04)
	_show_locked_toast(lvl_id)

func _show_locked_toast(lvl_id: int) -> void:
	var existing = get_tree().root.find_child("LockedToast", true, false)
	if existing:
		existing.queue_free()
	var toast = PanelContainer.new()
	toast.name = "LockedToast"
	toast.top_level = true
	toast.z_index = 150
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.16, 0.24, 0.96)
	sb.border_color = Color("#FF6B6B")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	toast.add_theme_stylebox_override("panel", sb)
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	toast.add_child(m)
	var lbl = Label.new()
	lbl.text = "🔒 Complete Level %d to unlock!" % (lvl_id - 1)
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.9, 1))
	m.add_child(lbl)
	get_tree().root.add_child(toast)
	toast.global_position = Vector2(get_viewport_rect().size.x * 0.5 - 210, get_viewport_rect().size.y - 180)
	var t = create_tween().set_parallel(true)
	t.tween_property(toast, "global_position:y", toast.global_position.y - 30.0, 1.1)
	t.chain().tween_property(toast, "modulate:a", 0.0, 0.35)
	t.chain().tween_callback(toast.queue_free)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()

func _on_level_selected(idx: int) -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.play_level(idx)

func _on_back_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.go_to_menu()
