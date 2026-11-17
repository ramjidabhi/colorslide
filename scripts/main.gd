extends Control

## Main.gd - Modern Mobile Puzzle Controller
## Coordinates responsive top bar, live undo mechanics, world theming,
## moves tracking, Daily Challenge headers, Milestone Chests, and Shop.

@onready var world_badge: Label = $SafeMargin/MainLayout/TopBar/HeaderCard/Margin/VBox/WorldBadge
@onready var level_num_label: Label = $SafeMargin/MainLayout/TopBar/HeaderCard/Margin/VBox/LevelNumberLabel
@onready var level_sub_label: Label = $SafeMargin/MainLayout/TopBar/HeaderCard/Margin/VBox/LevelSubLabel
@onready var coins_label: Label = $SafeMargin/MainLayout/TopBar/CoinsBox/CoinsLabel
@onready var piggy_btn: Button = get_node_or_null("SafeMargin/MainLayout/TopBar/PiggyButton")
@onready var wheel_btn: Button = get_node_or_null("SafeMargin/MainLayout/TopBar/WheelButton")
@onready var shop_btn: Button = get_node_or_null("SafeMargin/MainLayout/TopBar/ShopButton")
@onready var home_btn: Button = $SafeMargin/MainLayout/TopBar/HomeButton

@onready var status_label: Label = $SafeMargin/MainLayout/StatusPill/Margin/StatusLabel

@onready var restart_btn: Button = $SafeMargin/MainLayout/ActionDock/RestartButton
@onready var undo_btn: Button = $SafeMargin/MainLayout/ActionDock/UndoButton
@onready var hint_btn: Button = $SafeMargin/MainLayout/ActionDock/HintButton
@onready var sound_btn: Button = get_node_or_null("SafeMargin/MainLayout/ActionDock/SoundButton")
@onready var next_btn: Button = get_node_or_null("SafeMargin/MainLayout/ActionDock/NextButton")

@onready var smash_btn: Button = get_node_or_null("SafeMargin/MainLayout/BoosterBar/SmashButton")
@onready var shrink_btn: Button = get_node_or_null("SafeMargin/MainLayout/BoosterBar/ShrinkButton")
@onready var crane_btn: Button = get_node_or_null("SafeMargin/MainLayout/BoosterBar/CraneButton")
@onready var booster_bar: Control = get_node_or_null("SafeMargin/MainLayout/BoosterBar")
@onready var booster_help_btn: Button = get_node_or_null("SafeMargin/MainLayout/BoosterBar/BoosterHelpButton")

@onready var game_board: Control = $SafeMargin/MainLayout/BoardCenter/BoardContainer/GameBoard
@onready var win_dialog: Control = $WinDialog
@onready var tutorial_guide: Control = $TutorialGuide
@onready var star_chest_dialog: Control = $StarChestDialog
@onready var shop_dialog: Control = $ShopDialog
@onready var lucky_wheel_dialog: Control = $LuckyWheelDialog
@onready var piggy_bank_dialog: Control = $PiggyBankDialog
@onready var booster_guide_dialog: Control = get_node_or_null("BoosterGuideDialog")

const WORLD_HEADERS = {
	1: { "badge": "🧩 WORLD 1 • BEGINNER ESCAPE", "color": Color("#00D2D3") },
	2: { "badge": "🚦 WORLD 2 • STRATEGIC TRAFFIC", "color": Color("#FF9F43") },
	3: { "badge": "❄️ WORLD 3 • FROST CAVERN", "color": Color("#48DBFB") },
	4: { "badge": "⚡ WORLD 4 • LASER FACILITY", "color": Color("#FF5252") }
}

func _ready() -> void:
	if home_btn:
		home_btn.pressed.connect(_on_home_pressed)
	if shop_btn:
		shop_btn.pressed.connect(_on_shop_pressed)
	if piggy_btn:
		piggy_btn.pressed.connect(_on_piggy_pressed)
	if wheel_btn:
		wheel_btn.pressed.connect(_on_wheel_pressed)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)
	if undo_btn:
		undo_btn.pressed.connect(_on_undo_pressed)
	if hint_btn:
		hint_btn.pressed.connect(_on_hint_pressed)
	if sound_btn:
		sound_btn.pressed.connect(_on_sound_toggle_pressed)
	if next_btn:
		next_btn.pressed.connect(_on_next_pressed)
	if smash_btn:
		smash_btn.pressed.connect(_on_smash_pressed)
	if shrink_btn:
		shrink_btn.pressed.connect(_on_shrink_pressed)
	if crane_btn:
		crane_btn.pressed.connect(_on_crane_pressed)
	if booster_help_btn:
		booster_help_btn.pressed.connect(func():
			if booster_guide_dialog:
				booster_guide_dialog.show_dialog(false)
		)
	
	if game_board:
		if game_board.has_signal("undo_state_changed"):
			game_board.undo_state_changed.connect(_on_undo_state_changed)
		if game_board.has_signal("booster_action_completed"):
			game_board.booster_action_completed.connect(_on_booster_action_completed)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.apply_safe_area(get_node_or_null("SafeMargin"), 64, 50, 36)
		gm.level_loaded.connect(_on_level_loaded)
		gm.moves_updated.connect(_on_moves_updated)
		gm.progress_saved.connect(_update_coins_display)
		gm.level_completed.connect(_on_level_completed_check_rate)
		if gm.has_signal("hints_updated"):
			gm.hints_updated.connect(func(_c): _update_hint_button_label())
		if gm.has_signal("chest_ready"):
			gm.chest_ready.connect(_on_chest_ready)
		if gm.has_signal("boosters_updated"):
			gm.boosters_updated.connect(_update_booster_buttons)
		if gm.has_signal("boosters_unlocked_celebration"):
			gm.boosters_unlocked_celebration.connect(_on_boosters_unlocked_celebration)
			
		_update_coins_display()
		_update_sound_icon()
		_update_hint_button_label()
		_update_booster_buttons()
		if undo_btn: undo_btn.text = tr("BTN_UNDO")
		if restart_btn: restart_btn.text = tr("BTN_RESET")
		
		# Load initial level or active daily challenge
		if gm.is_daily_mode:
			gm.start_daily_challenge()
		else:
			gm.start_level(gm.current_level_index)

func _on_level_loaded(l_data: Dictionary) -> void:
	var is_daily = l_data.get("is_daily", false)
	var gm = get_node_or_null("/root/GameManager")
	
	if is_daily:
		world_badge.text = "🔥 DAILY CHALLENGE"
		world_badge.add_theme_color_override("font_color", Color("#FFA502"))
		var streak = gm.daily_streak if gm else 0
		level_num_label.text = "STREAK: %d DAYS" % streak
		level_sub_label.text = "DAILY MIND FORGE"
		_apply_world_background(0)
	else:
		var l_id = int(l_data.get("level_id", 1))
		var w_id = int(l_data.get("world_id", 1))
		var title = str(l_data.get("title", "Puzzle"))
		
		var wh = WORLD_HEADERS.get(w_id, WORLD_HEADERS[1])
		world_badge.text = wh["badge"]
		world_badge.add_theme_color_override("font_color", wh["color"])
		
		level_num_label.text = "LEVEL " + str(l_id)
		level_sub_label.text = title.to_upper()
		_apply_world_background(w_id)
		
	var l_id_num = int(l_data.get("level_id", 1))
	var opt_moves = int(l_data.get("optimal_moves", 0))
	var best_moves = gm.get_personal_best_moves(l_id_num) if gm else 0
	var best_str = str(best_moves) if best_moves > 0 else "—"
	if not is_daily and l_id_num == 5:
		status_label.text = "🚀 Boosters Unlocked! Tap 🔨, ✂️, 🧲 to use • Tap ❓ for Guide"
	elif not is_daily and l_id_num == 6:
		status_label.text = "💡 Tough puzzle? Tap 🔨 Smash or ✂️ Shrink below • Tap ❓ for Guide"
	elif opt_moves > 0 and not is_daily:
		status_label.text = "🟢 PAR: %d  |  MOVES: 0  |  BEST: %s" % [opt_moves, best_str]
	else:
		status_label.text = "Moves: 0  |  Best: %s • %s" % [best_str, tr("MSG_INSTRUCTION")]
	_update_coins_display()
	_update_hint_button_label()
	_update_booster_buttons()
	_update_undo_visual(false)
	
	# Boosters unlock on Level 5 (levels 1-4 keep a clean beginner screen)
	var can_show_boosters = is_daily or (gm and (gm.highest_unlocked_level >= 5 or gm.boosters_unlocked or l_id_num >= 5))
	if booster_bar:
		booster_bar.visible = can_show_boosters
	# On Level 5 first reveal: animate a brief glow arrow pointing at the booster bar
	if not is_daily and l_id_num == 5 and gm and gm.highest_unlocked_level <= 5:
		_flash_booster_bar_attention()

func _apply_world_background(w_id: int) -> void:
	var bg = get_node_or_null("Background") as Panel
	if not bg:
		return
	var target_col = Color(0.06, 0.07, 0.11, 1)
	match w_id:
		0: target_col = Color(0.10, 0.08, 0.05, 1) # Daily Warm Amber
		2: target_col = Color(0.04, 0.06, 0.12, 1) # Cyberpunk Midnight
		3: target_col = Color(0.04, 0.09, 0.14, 1) # Frost Cavern
		4: target_col = Color(0.10, 0.05, 0.08, 1) # Laser Defense
		_: target_col = Color(0.06, 0.07, 0.11, 1) # World 1 Slate
	var sb = StyleBoxFlat.new()
	sb.bg_color = target_col
	bg.add_theme_stylebox_override("panel", sb)

func _on_moves_updated(moves: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	var l_data = gm.get_current_level_data() if gm else {}
	var l_id = int(l_data.get("level_id", 1))
	var opt = int(l_data.get("optimal_moves", 0))
	var best = gm.get_personal_best_moves(l_id) if gm else 0
	var best_str = str(best) if best > 0 else "—"
	if opt > 0 and not l_data.get("is_daily", false):
		var par_color = "🟢" if moves <= opt else ("🟡" if moves <= opt + 4 else "🔴")
		status_label.text = "%s PAR: %d  |  MOVES: %d  |  BEST: %s" % [par_color, opt, moves, best_str]
	else:
		status_label.text = "Moves: %d  |  Best: %s • %s" % [moves, best_str, tr("MSG_INSTRUCTION")]
	# Show booster guide after player's FIRST move on L5 (not on level entry)
	if _pending_booster_guide and moves == 1:
		_pending_booster_guide = false
		await get_tree().create_timer(0.4).timeout
		if is_inside_tree() and booster_guide_dialog:
			booster_guide_dialog.show_dialog(true)

func _on_undo_state_changed(has_undo: bool) -> void:
	_update_undo_visual(has_undo)

func _update_undo_visual(has_undo: bool) -> void:
	undo_btn.modulate = Color(1, 1, 1, 1.0) if has_undo else Color(0.5, 0.55, 0.65, 0.45)

func _on_undo_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	if game_board and game_board.has_method("undo_last_move"):
		var did_undo = game_board.undo_last_move()
		if did_undo:
			var gm = get_node_or_null("/root/GameManager")
			if gm:
				gm.current_moves = max(0, gm.current_moves - 1)
				_on_moves_updated(gm.current_moves)
			if tutorial_guide and tutorial_guide.visible:
				tutorial_guide.open_hint()

func _update_coins_display() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		coins_label.text = "🪙 " + str(gm.total_coins)
		_update_hint_button_label()

func _update_hint_button_label() -> void:
	if not hint_btn:
		return
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	var l_data = gm.get_current_level_data()
	var l_id = int(l_data.get("level_id", 1))
	var hint_base = tr("BTN_HINT")
	if (not gm.is_daily_mode and l_id == 1) or gm.hint_unlocked_for_current:
		hint_btn.text = hint_base
	elif gm.hints_count > 0:
		hint_btn.text = "%s (%d)" % [hint_base, gm.hints_count]
	else:
		hint_btn.text = "%s (%d 🪙)" % [hint_base, gm.HINT_COIN_COST]

func _update_sound_icon() -> void:
	if not sound_btn:
		return
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.is_muted:
		sound_btn.text = "🔇"
	else:
		sound_btn.text = "🔊"

func _on_sound_toggle_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.toggle_mute()
		_update_sound_icon()
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			gm.save_progress()

func _on_home_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.go_to_level_select()

func _on_shop_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	if shop_dialog:
		shop_dialog.show_dialog()

func _on_piggy_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	if piggy_bank_dialog:
		piggy_bank_dialog.show_dialog()

func _on_wheel_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	if lucky_wheel_dialog:
		lucky_wheel_dialog.show_dialog()

func _on_chest_ready(milestone_level: int) -> void:
	if star_chest_dialog:
		star_chest_dialog.open_milestone_chest(milestone_level)

func _on_next_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.next_level()

func _on_restart_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.restart_current_level()

func _on_hint_pressed() -> void:
	if not tutorial_guide:
		return
	if tutorial_guide.visible:
		tutorial_guide.close_hint()
		return
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		var res = gm.use_or_buy_hint()
		if res == "insufficient":
			var mm = get_node_or_null("/root/MonetizationManager")
			if mm and mm.is_rewarded_ad_available():
				_offer_rewarded_hints()
				return
			var sm = get_node_or_null("/root/SoundManager")
			if sm:
				sm.play_bump()
			_show_hint_insufficient_toast()
			return
		_update_coins_display()
		_update_hint_button_label()
	if tutorial_guide.has_method("open_hint"):
		tutorial_guide.open_hint()

func _offer_rewarded_hints() -> void:
	var mm = get_node_or_null("/root/MonetizationManager")
	var gm = get_node_or_null("/root/GameManager")
	var sm = get_node_or_null("/root/SoundManager")
	if not mm or not gm:
		return
	
	_show_rewarded_ad_modal(
		"💡 Free Hint (+1)",
		"Out of hints and coins?\nWatch a quick video ad to get 1 Free Hint!",
		"🎬 WATCH AD (+1 HINT)",
		func():
			var success = mm.request_rewarded_ad("free_hint_rewarded", func():
				gm.add_hints(1)
				gm.use_or_buy_hint()
				_update_coins_display()
				_update_hint_button_label()
				if sm: sm.play_win()
				status_label.text = "🎉 +1 Free Hint Added! Walkthrough active."
				if tutorial_guide and tutorial_guide.has_method("open_hint"):
					tutorial_guide.open_hint()
			)
			if not success:
				status_label.text = "⏳ Ad loading or no internet. Please check connection."
	)

func _offer_rewarded_booster(booster_type: String, booster_name: String, icon: String) -> void:
	var mm = get_node_or_null("/root/MonetizationManager")
	var gm = get_node_or_null("/root/GameManager")
	var sm = get_node_or_null("/root/SoundManager")
	if not mm or not gm:
		return
		
	_show_rewarded_ad_modal(
		"%s Free %s" % [icon, booster_name],
		"Need a %s to clear this board?\nWatch a short video ad to claim +1 Free %s right now!" % [booster_name, booster_name],
		"🎬 WATCH AD (+1 FREE)",
		func():
			var success = mm.request_rewarded_ad("booster_" + booster_type, func():
				gm.add_booster(booster_type, 1)
				_update_booster_buttons()
				_update_coins_display()
				if sm: sm.play_star(1.3)
				status_label.text = "🎉 +1 Free %s Received! Ready to use." % booster_name
				if game_board:
					game_board.set_booster_mode(booster_type)
					_update_booster_buttons()
			)
			if not success:
				status_label.text = "⏳ Ad loading or no internet. Please check connection."
	)

func _show_rewarded_ad_modal(title_text: String, desc_text: String, action_btn_text: String, on_watch: Callable) -> void:
	var existing = find_child("RewardedAdPrompt", true, false)
	if existing:
		existing.queue_free()
	var backdrop = ColorRect.new()
	backdrop.name = "RewardedAdPrompt"
	backdrop.z_index = 260
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.04, 0.05, 0.08, 0.82)
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var overlay = PanelContainer.new()
	overlay.custom_minimum_size = Vector2(740, 0)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.13, 0.20, 0.98)
	sb.border_color = Color("#00D2D3")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(24)
	overlay.add_theme_stylebox_override("panel", sb)
	center.add_child(overlay)
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 32)
	m.add_theme_constant_override("margin_right", 32)
	m.add_theme_constant_override("margin_top", 28)
	m.add_theme_constant_override("margin_bottom", 28)
	overlay.add_child(m)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	m.add_child(vb)
	var t_lbl = Label.new()
	t_lbl.text = title_text
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_lbl.add_theme_font_size_override("font_size", 34)
	vb.add_child(t_lbl)
	var d_lbl = Label.new()
	d_lbl.text = desc_text
	d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_lbl.add_theme_font_size_override("font_size", 24)
	d_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98, 1))
	vb.add_child(d_lbl)
	var hb = HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 18)
	vb.add_child(hb)
	var cancel_btn = Button.new()
	cancel_btn.text = "✖ Cancel"
	cancel_btn.custom_minimum_size = Vector2(180, 76)
	cancel_btn.add_theme_font_size_override("font_size", 24)
	var c_sb = StyleBoxFlat.new()
	c_sb.bg_color = Color(0.2, 0.24, 0.34, 1)
	c_sb.set_corner_radius_all(18)
	cancel_btn.add_theme_stylebox_override("normal", c_sb)
	cancel_btn.pressed.connect(backdrop.queue_free)
	hb.add_child(cancel_btn)
	var watch_btn = Button.new()
	watch_btn.text = action_btn_text
	watch_btn.custom_minimum_size = Vector2(340, 76)
	watch_btn.add_theme_font_size_override("font_size", 24)
	var w_sb = StyleBoxFlat.new()
	w_sb.bg_color = Color(0.08, 0.76, 0.55, 1)
	w_sb.set_corner_radius_all(18)
	watch_btn.add_theme_stylebox_override("normal", w_sb)
	watch_btn.pressed.connect(func():
		backdrop.queue_free()
		if on_watch.is_valid():
			on_watch.call()
	)
	hb.add_child(watch_btn)
	add_child(backdrop)

func _show_hint_insufficient_toast() -> void:
	var existing = get_tree().root.find_child("HintToast", true, false)
	if existing:
		existing.queue_free()
	var toast = PanelContainer.new()
	toast.name = "HintToast"
	toast.top_level = true
	toast.z_index = 220
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.12, 0.18, 0.96)
	sb.border_color = Color("#FFA502")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	toast.add_theme_stylebox_override("panel", sb)
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 18)
	m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	toast.add_child(m)
	var lbl = Label.new()
	lbl.text = "💡 Need 50 🪙 or Spin Wheel for Hints!"
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.6, 1))
	m.add_child(lbl)
	get_tree().root.add_child(toast)
	toast.global_position = Vector2(get_viewport_rect().size.x * 0.5 - 230, get_viewport_rect().size.y - 240)
	var t = create_tween().set_parallel(true)
	t.tween_property(toast, "global_position:y", toast.global_position.y - 30.0, 1.3)
	t.chain().tween_property(toast, "modulate:a", 0.0, 0.35)
	t.chain().tween_callback(toast.queue_free)

func _on_level_completed_check_rate(l_id: int, _s: int, _m: int, _c: int, _crown: bool, _opt: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and l_id == 5 and not gm.has_rated_prompted:
		gm.has_rated_prompted = true
		gm.save_progress()
		await get_tree().create_timer(1.4).timeout
		if is_inside_tree():
			_show_rate_prompt()

func _show_rate_prompt() -> void:
	var backdrop = ColorRect.new()
	backdrop.name = "RatePrompt"
	backdrop.z_index = 250
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.04, 0.05, 0.08, 0.78)
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var overlay = PanelContainer.new()
	overlay.custom_minimum_size = Vector2(720, 0)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.14, 0.22, 0.98)
	sb.border_color = Color("#FFD700")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(24)
	overlay.add_theme_stylebox_override("panel", sb)
	center.add_child(overlay)
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_bottom", 24)
	overlay.add_child(m)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	m.add_child(vb)
	var t_lbl = Label.new()
	t_lbl.text = "⭐ Enjoying Slide Escape?"
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_lbl.add_theme_font_size_override("font_size", 32)
	vb.add_child(t_lbl)
	var d_lbl = Label.new()
	d_lbl.text = "A quick 5-star review helps other puzzle fans discover us!"
	d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_lbl.add_theme_font_size_override("font_size", 24)
	d_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95, 1))
	vb.add_child(d_lbl)
	var hb = HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 18)
	vb.add_child(hb)
	var later_btn = Button.new()
	later_btn.text = "Later"
	later_btn.custom_minimum_size = Vector2(180, 72)
	later_btn.add_theme_font_size_override("font_size", 26)
	var later_sb = StyleBoxFlat.new()
	later_sb.bg_color = Color(0.2, 0.24, 0.34, 1)
	later_sb.set_corner_radius_all(18)
	later_btn.add_theme_stylebox_override("normal", later_sb)
	later_btn.pressed.connect(backdrop.queue_free)
	hb.add_child(later_btn)
	var rate_btn = Button.new()
	rate_btn.text = "⭐ Rate 5★"
	rate_btn.custom_minimum_size = Vector2(220, 72)
	rate_btn.add_theme_font_size_override("font_size", 26)
	var rate_sb = StyleBoxFlat.new()
	rate_sb.bg_color = Color(0.08, 0.72, 0.56, 1)
	rate_sb.set_corner_radius_all(18)
	rate_btn.add_theme_stylebox_override("normal", rate_sb)
	rate_btn.pressed.connect(func():
		var sm = get_node_or_null("/root/SoundManager")
		if sm: sm.play_star(1.2)
		var mm = get_node_or_null("/root/MonetizationManager")
		var gm = get_node_or_null("/root/GameManager")
		if mm and gm:
			mm.request_in_app_review(gm.PLAY_STORE_PACKAGE_ID)
		backdrop.queue_free()
	)
	hb.add_child(rate_btn)
	add_child(backdrop)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if tutorial_guide and tutorial_guide.visible:
			tutorial_guide.close_hint()
		elif shop_dialog and shop_dialog.visible:
			shop_dialog.hide_dialog()
		elif lucky_wheel_dialog and lucky_wheel_dialog.visible:
			lucky_wheel_dialog.hide_dialog()
		elif piggy_bank_dialog and piggy_bank_dialog.visible:
			piggy_bank_dialog.hide_dialog()
		elif win_dialog and win_dialog.visible:
			_on_home_pressed()
		elif booster_guide_dialog and booster_guide_dialog.visible:
			booster_guide_dialog.visible = false
		else:
			_on_home_pressed()

func _on_boosters_unlocked_celebration() -> void:
	# Delay guide until after first move on L5 — less intrusive & more memorable
	# We set a flag and let _on_moves_updated trigger it on move #1
	_pending_booster_guide = true

var _pending_booster_guide: bool = false

# ----------------- IN-GAME BOOSTERS (SPECIAL FEATURES) -----------------

func _on_smash_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var sm = get_node_or_null("/root/SoundManager")
	if not gm or not game_board:
		return
	
	if game_board.active_booster_mode == "sledgehammer":
		game_board.cancel_booster_mode()
		_update_booster_buttons()
		_on_moves_updated(gm.current_moves)
		if sm: sm.play_tap()
		return
		
	if not gm.can_afford_booster("sledgehammer"):
		if sm: sm.play_bump()
		_offer_rewarded_booster("sledgehammer", "Sledgehammer", "🔨")
		return
		
	if sm: sm.play_tap()
	game_board.set_booster_mode("sledgehammer")
	_update_booster_buttons()
	status_label.text = "🔨 STEP 1/2: Tap any obstacle block on board to SMASH it!"

func _on_shrink_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var sm = get_node_or_null("/root/SoundManager")
	if not gm or not game_board:
		return
	
	if game_board.active_booster_mode == "shrink":
		game_board.cancel_booster_mode()
		_update_booster_buttons()
		_on_moves_updated(gm.current_moves)
		if sm: sm.play_tap()
		return
		
	if not gm.can_afford_booster("shrink"):
		if sm: sm.play_bump()
		_offer_rewarded_booster("shrink", "Shrink Ray", "✂️")
		return
		
	if sm: sm.play_tap()
	game_board.set_booster_mode("shrink")
	_update_booster_buttons()
	status_label.text = "✂️ STEP 1/2: Tap any 2 or 3-cell obstacle to SHRINK it!"

func _on_crane_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var sm = get_node_or_null("/root/SoundManager")
	if not gm or not game_board:
		return
	
	if game_board.active_booster_mode == "crane":
		game_board.cancel_booster_mode()
		_update_booster_buttons()
		_on_moves_updated(gm.current_moves)
		if sm: sm.play_tap()
		return
		
	if not gm.can_afford_booster("crane"):
		if sm: sm.play_bump()
		_offer_rewarded_booster("crane", "Crane Picker", "🧲")
		return
		
	if sm: sm.play_tap()
	game_board.set_booster_mode("crane")
	_update_booster_buttons()
	status_label.text = "🧲 STEP 1/2: Tap any trapped block to LIFT it!"

func _on_booster_action_completed(type: String, success: bool, message: String) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if success and gm:
		gm.consume_booster(type)
	if type == "crane" and not success and game_board and game_board.crane_selected_block != null:
		status_label.text = "🧲 STEP 2/2: Now tap any EMPTY space on board to DROP it!"
	else:
		status_label.text = message
	_update_booster_buttons()
	_update_coins_display()

func _update_booster_buttons() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	
	if smash_btn:
		var c = gm.get_booster_count("sledgehammer")
		smash_btn.tooltip_text = "🔨 Sledgehammer: Smash & eliminate 1 obstacle block (%d 🪙 or 🎬 Free)" % gm.get_booster_cost("sledgehammer")
		if game_board and game_board.active_booster_mode == "sledgehammer":
			smash_btn.text = "🔨 CANCEL"
		elif c > 0:
			smash_btn.text = "🔨 SMASH (x%d)" % c
		elif gm.total_coins < gm.get_booster_cost("sledgehammer"):
			smash_btn.text = "🔨 🎬 +1 FREE"
		else:
			smash_btn.text = "🔨 %d 🪙" % gm.get_booster_cost("sledgehammer")
			
	if shrink_btn:
		var c = gm.get_booster_count("shrink")
		shrink_btn.tooltip_text = "✂️ Shrink Ray: Shorten 2/3-cell obstacle by 1 cell (%d 🪙 or 🎬 Free)" % gm.get_booster_cost("shrink")
		if game_board and game_board.active_booster_mode == "shrink":
			shrink_btn.text = "✂️ CANCEL"
		elif c > 0:
			shrink_btn.text = "✂️ SHRINK (x%d)" % c
		elif gm.total_coins < gm.get_booster_cost("shrink"):
			shrink_btn.text = "✂️ 🎬 +1 FREE"
		else:
			shrink_btn.text = "✂️ %d 🪙" % gm.get_booster_cost("shrink")
			
	if crane_btn:
		var c = gm.get_booster_count("crane")
		crane_btn.tooltip_text = "🧲 Crane Picker: Pick up and relocate trapped block (%d 🪙 or 🎬 Free)" % gm.get_booster_cost("crane")
		if game_board and game_board.active_booster_mode == "crane":
			crane_btn.text = "🧲 CANCEL"
		elif c > 0:
			crane_btn.text = "🧲 CRANE (x%d)" % c
		elif gm.total_coins < gm.get_booster_cost("crane"):
			crane_btn.text = "🧲 🎬 +1 FREE"
		else:
			crane_btn.text = "🧲 %d 🪙" % gm.get_booster_cost("crane")

	if booster_help_btn:
		var is_intro = gm.highest_unlocked_level == 5 or gm.highest_unlocked_level == 6 or gm.current_level_index == 4 or gm.current_level_index == 5
		booster_help_btn.text = "❓ GUIDE" if is_intro else "❓"
		booster_help_btn.custom_minimum_size = Vector2(130, 74) if is_intro else Vector2(74, 74)

func _flash_booster_bar_attention() -> void:
	if not booster_bar:
		return
	var orig_mod = booster_bar.modulate
	var tw = create_tween().set_loops(3)
	tw.tween_property(booster_bar, "modulate", Color(1.3, 1.3, 1.0, 1.0), 0.25)
	tw.tween_property(booster_bar, "modulate", orig_mod, 0.25)
