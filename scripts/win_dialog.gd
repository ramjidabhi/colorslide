extends Control

## WinDialog.gd - Celebratory Level Cleared Popup
## Sequentially animates 3 stars, displays moves vs optimal,
## and offers Next Level / Replay buttons.

signal next_level_pressed()
signal replay_pressed()

@onready var modal_panel: Panel = $CenterContainer/ModalPanel
@onready var title_label: Label = $CenterContainer/ModalPanel/VBoxContainer/TitleLabel
@onready var crown_badge: Label = $CenterContainer/ModalPanel/VBoxContainer/CrownBadge
@onready var stars_container: HBoxContainer = $CenterContainer/ModalPanel/VBoxContainer/StarsContainer
@onready var star1: Label = $CenterContainer/ModalPanel/VBoxContainer/StarsContainer/Star1
@onready var star2: Label = $CenterContainer/ModalPanel/VBoxContainer/StarsContainer/Star2
@onready var star3: Label = $CenterContainer/ModalPanel/VBoxContainer/StarsContainer/Star3
@onready var stats_label: Label = $CenterContainer/ModalPanel/VBoxContainer/StatsLabel
@onready var coins_label: Label = $CenterContainer/ModalPanel/VBoxContainer/CoinsCenter/CoinsBadge/CoinsLabel
@onready var next_button: Button = $CenterContainer/ModalPanel/VBoxContainer/NextButton
@onready var replay_button: Button = $CenterContainer/ModalPanel/VBoxContainer/SecondaryButtons/ReplayButton
@onready var levels_button: Button = $CenterContainer/ModalPanel/VBoxContainer/SecondaryButtons/LevelsButton

func _ready() -> void:
	visible = false
	next_button.pressed.connect(_on_next_pressed)
	replay_button.pressed.connect(_on_replay_pressed)
	if levels_button:
		levels_button.pressed.connect(_on_levels_pressed)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.level_completed.connect(show_win)

func show_win(l_id: int, stars: int, moves: int, coins: int, earned_crown: bool = false, opt_moves: int = 0) -> void:
	z_index = 200
	visible = true
	var is_daily = (l_id == 999)
	if is_daily:
		title_label.text = tr("MSG_DAILY_CLEARED")
	elif l_id == 50:
		title_label.text = "🏆 WORLD 1 MASTERED! 🏆"
	elif l_id == 100:
		title_label.text = "🏆 WORLD 2 MASTERED! 🏆"
	elif l_id == 150:
		title_label.text = "🏆 WORLD 3 MASTERED! 🏆"
	elif l_id == 200:
		title_label.text = "👑 GRANDMASTER! 👑"
	else:
		title_label.text = "LEVEL %d • %s" % [l_id, tr("MSG_WIN")]
	if next_button: next_button.text = tr("BTN_BACK_MENU") if is_daily else tr("BTN_NEXT")
	if replay_button: replay_button.text = tr("BTN_REPLAY")
	if levels_button: levels_button.text = tr("BTN_LEVELS")
		
	var gm = get_node_or_null("/root/GameManager")
	var is_pure = gm != null and gm.booster_free_crowns.has(str(l_id))
	if crown_badge:
		crown_badge.visible = earned_crown
		if earned_crown:
			if is_pure:
				crown_badge.text = "👑🛡️ PURE MASTER CROWN! NO BOOSTERS • %d MOVES" % moves
			else:
				crown_badge.text = "👑 MASTER CROWN! PERFECT %d MOVES (PAR: %d)" % [moves, opt_moves]
			if is_daily:
				var streak = gm.daily_streak if gm else 1
				stats_label.text = "🏆 OPTIMAL ROUTE MASTERED! • 🔥 %d DAY STREAK" % streak
			else:
				stats_label.text = "🏆 OPTIMAL ROUTE MASTERED! • 🐷 +25 in Piggy Bank"
			coins_label.text = "+%d Coins (120 👑 Optimal Master!)" % coins if not is_daily else "+%d Coins" % coins
		else:
			if is_daily:
				var streak = gm.daily_streak if gm else 1
				stats_label.text = "%d★ Rating • Moves: %d • 🔥 %d Day Streak" % [stars, moves, streak]
			elif opt_moves > 0:
				stats_label.text = "%d★ Rating • Moves: %d (Par: %d)" % [stars, moves, opt_moves]
			else:
				stats_label.text = "🎉 PUZZLE SOLVED! • 🐷 +25 in Piggy Bank"
			coins_label.text = "+" + str(coins) + " Coins"
	
	# Reset stars
	star1.modulate = Color(0.3, 0.3, 0.3, 0.5)
	star2.modulate = Color(0.3, 0.3, 0.3, 0.5)
	star3.modulate = Color(0.3, 0.3, 0.3, 0.5)
	
	# Scale animation from center
	modal_panel.pivot_offset = modal_panel.size * 0.5
	modal_panel.scale = Vector2(0.7, 0.7)
	var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(modal_panel, "scale", Vector2.ONE, 0.35)
	
	_spawn_confetti_burst()
	
	# Animate stars in sequence
	await get_tree().create_timer(0.3).timeout
	if stars >= 1:
		_animate_star(star1, 1.0)
	await get_tree().create_timer(0.25).timeout
	if stars >= 2:
		_animate_star(star2, 1.1)
	await get_tree().create_timer(0.25).timeout
	if stars >= 3:
		_animate_star(star3, 1.25)
	if earned_crown:
		await get_tree().create_timer(0.25).timeout
		var sm = get_node_or_null("/root/SoundManager")
		if sm and is_inside_tree():
			sm.play_star(1.5)

func _animate_star(star_node: Label, pitch: float) -> void:
	star_node.modulate = Color(1.0, 0.85, 0.1, 1.0)
	star_node.scale = Vector2(1.6, 1.6)
	var st = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	st.tween_property(star_node, "scale", Vector2.ONE, 0.25)
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_star(pitch)

func _spawn_confetti_burst() -> void:
	var colors = [
		Color("#FF4757"), Color("#2ED573"), Color("#1E90FF"),
		Color("#FFA502"), Color("#9B59B6"), Color("#FFD700"), Color("#00D2D3")
	]
	var center = modal_panel.global_position + modal_panel.size * 0.5
	for i in range(24):
		var p = ColorRect.new()
		p.custom_minimum_size = Vector2(randf_range(8, 14), randf_range(14, 22))
		p.color = colors[randi() % colors.size()]
		p.top_level = true
		p.pivot_offset = p.custom_minimum_size * 0.5
		p.rotation_degrees = randf_range(0, 360)
		var spawn_pos = center + Vector2(randf_range(-220, 220), randf_range(-120, 60))
		p.global_position = spawn_pos
		add_child(p)
		
		var t = create_tween().set_parallel(true)
		var dest = spawn_pos + Vector2(randf_range(-180, 180), randf_range(200, 480))
		t.tween_property(p, "global_position", dest, randf_range(0.9, 1.4)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(p, "rotation_degrees", p.rotation_degrees + randf_range(-360, 360), 1.2)
		t.tween_property(p, "modulate:a", 0.0, 1.3).set_ease(Tween.EASE_IN)
		t.chain().tween_callback(p.queue_free)

func _on_next_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	visible = false
	next_level_pressed.emit()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.next_level()

func _on_replay_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	visible = false
	replay_pressed.emit()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.restart_current_level()

func _on_levels_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	visible = false
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.go_to_level_select()
