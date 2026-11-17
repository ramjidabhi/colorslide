extends Control

## DailyChallengeDialog.gd - Daily Puzzle & Streak Calendar
## Drives #1 mobile DAU habit: daily appointment mechanics,
## streak multipliers, 7-day milestone rewards, and calendar tracking.

signal start_daily_puzzle()

@onready var modal_panel: Panel = $CenterContainer/ModalPanel
@onready var date_label: Label = $CenterContainer/ModalPanel/VBox/DateLabel
@onready var streak_num_label: Label = $CenterContainer/ModalPanel/VBox/StreakBox/Margin/VBox/StreakNumLabel
@onready var streak_desc_label: Label = $CenterContainer/ModalPanel/VBox/StreakBox/Margin/VBox/StreakDescLabel
@onready var calendar_grid: HBoxContainer = $CenterContainer/ModalPanel/VBox/CalendarGrid
@onready var play_btn: Button = $CenterContainer/ModalPanel/VBox/PlayButton
@onready var close_btn: Button = $CenterContainer/ModalPanel/VBox/CloseButton

func _ready() -> void:
	visible = false
	if close_btn:
		close_btn.pressed.connect(hide_dialog)
	if play_btn:
		play_btn.pressed.connect(_on_play_pressed)
		
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("daily_completed"):
		gm.daily_completed.connect(func(_s, _c, _new): refresh_ui())

func show_dialog() -> void:
	refresh_ui()
	visible = true
	z_index = 150
	modal_panel.pivot_offset = modal_panel.size * 0.5
	modal_panel.scale = Vector2(0.8, 0.8)
	var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(modal_panel, "scale", Vector2.ONE, 0.28)
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()

func hide_dialog() -> void:
	var t = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(modal_panel, "scale", Vector2(0.8, 0.8), 0.18)
	await t.finished
	visible = false

func refresh_ui() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
		
	var today_str = gm.get_today_date_str()
	var dt = Time.get_date_dict_from_system()
	var month_names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var month_name = month_names[dt.month - 1]
	
	var max_w = gm.get_unlocked_max_world()
	var world_pool_str = "WORLD 1 POOL"
	match max_w:
		1: world_pool_str = "WORLD 1 POOL"
		2: world_pool_str = "WORLDS 1–2 POOL"
		3: world_pool_str = "WORLDS 1–3 POOL"
		4: world_pool_str = "ALL 4 WORLDS POOL"
		
	date_label.text = "TODAY: %s %d, %d • 🔥 %s" % [month_name.to_upper(), dt.day, dt.year, world_pool_str]
	
	var streak = gm.daily_streak
	streak_num_label.text = "🔥 %d DAY STREAK" % streak
	
	var world_hint = ""
	if max_w < 4:
		world_hint = "\n(Reach World %d to unlock more daily challenges!)" % (max_w + 1)
		
	if streak == 0:
		streak_desc_label.text = "Solve today's puzzle to ignite your flame!" + world_hint
	elif streak < 3:
		streak_desc_label.text = "%d more day(s) until +25 bonus coins!" % (3 - streak) + world_hint
	elif streak < 7:
		streak_desc_label.text = "%d more day(s) until Royal Gold Skin!" % (7 - streak) + world_hint
	else:
		streak_desc_label.text = "👑 Unstoppable! Grandmaster daily streak!" + world_hint
		
	# Refresh 7-Day calendar ribbon
	_populate_week_ribbon(gm, dt.weekday)
	
	var title_lbl = get_node_or_null("CenterContainer/ModalPanel/VBox/TitleLabel")
	if title_lbl: title_lbl.text = tr("MSG_DAILY_TITLE")
	if close_btn: close_btn.text = tr("BTN_BACK_HOME")

	# Update Play button state
	var is_done = gm.is_daily_completed_today()
	if is_done:
		play_btn.text = tr("BTN_DAILY_REPLAY")
		play_btn.modulate = Color(0.7, 0.85, 1.0, 1.0)
	else:
		play_btn.text = tr("BTN_DAILY_PLAY")
		play_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _populate_week_ribbon(gm: Node, today_weekday: int) -> void:
	for child in calendar_grid.get_children():
		child.queue_free()
		
	var day_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
	# Godot weekday: 1 = Monday, 7 = Sunday
	var now_unix = int(Time.get_unix_time_from_system())
	
	for i in range(7):
		var w_idx = i + 1
		var day_unix = now_unix - (today_weekday - w_idx) * 86400
		var day_date_str = Time.get_date_string_from_unix_time(day_unix)
		var was_completed = gm.completed_dailies.has(day_date_str)
		
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(100, 130)
		
		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(16)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 6)
		
		var name_lbl = Label.new()
		name_lbl.text = day_names[i]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 22)
		
		var icon_lbl = Label.new()
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 34)
		
		if w_idx < today_weekday:
			# Past day in week: check actual completion history
			if was_completed:
				style.bg_color = Color("#182A24")
				style.border_color = Color("#2ED573")
				name_lbl.add_theme_color_override("font_color", Color("#2ED573"))
				icon_lbl.text = "✓"
				icon_lbl.add_theme_color_override("font_color", Color("#2ED573"))
			else:
				style.bg_color = Color("#161822")
				style.border_color = Color("#2A2F40")
				name_lbl.add_theme_color_override("font_color", Color("#636E72"))
				icon_lbl.text = "—"
				icon_lbl.add_theme_color_override("font_color", Color("#636E72"))
		elif w_idx == today_weekday:
			# Today
			if gm.is_daily_completed_today():
				style.bg_color = Color("#182A24")
				style.border_color = Color("#2ED573")
				name_lbl.add_theme_color_override("font_color", Color("#2ED573"))
				icon_lbl.text = "✓"
				icon_lbl.add_theme_color_override("font_color", Color("#2ED573"))
			else:
				style.bg_color = Color("#2A2415")
				style.border_color = Color("#FFA502")
				name_lbl.add_theme_color_override("font_color", Color("#FFA502"))
				icon_lbl.text = "🔥"
		else:
			# Future day
			style.bg_color = Color("#141822")
			style.border_color = Color("#2D3548")
			name_lbl.add_theme_color_override("font_color", Color("#747D8C"))
			if w_idx == 7:
				icon_lbl.text = "👑"
				icon_lbl.add_theme_color_override("font_color", Color("#FFD700"))
			else:
				icon_lbl.text = "🔒"
				icon_lbl.add_theme_color_override("font_color", Color("#747D8C"))
				
		card.add_theme_stylebox_override("panel", style)
		vbox.add_child(name_lbl)
		vbox.add_child(icon_lbl)
		card.add_child(vbox)
		calendar_grid.add_child(card)

func _on_play_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	hide_dialog()
	start_daily_puzzle.emit()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.start_daily_challenge()
