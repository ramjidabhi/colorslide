extends Control

## BlitzModeDialog.gd - 60-Second Rush Hour Blitz Game Mode
## Fast-paced time-attack puzzle solving with countdown clock,
## combo multipliers, time bonuses (+5s per solve), and high score records.

signal blitz_ended(final_score: int)

@onready var modal_panel: Panel = $CenterContainer/ModalPanel
@onready var timer_label: Label = $CenterContainer/ModalPanel/Margin/VBox/TopBar/TimerPill/TimerLabel
@onready var score_label: Label = $CenterContainer/ModalPanel/Margin/VBox/TopBar/ScorePill/ScoreLabel
@onready var combo_label: Label = $CenterContainer/ModalPanel/Margin/VBox/TopBar/ComboPill/ComboLabel
@onready var close_btn: Button = $CenterContainer/ModalPanel/Margin/VBox/TopBar/CloseBtn
@onready var game_board: Control = $CenterContainer/ModalPanel/Margin/VBox/BoardCenter/BoardContainer/GameBoard
@onready var summary_overlay: PanelContainer = $CenterContainer/ModalPanel/Margin/VBox/SummaryOverlay
@onready var summary_title: Label = $CenterContainer/ModalPanel/Margin/VBox/SummaryOverlay/Margin/VBox/SummaryTitle
@onready var summary_stats: Label = $CenterContainer/ModalPanel/Margin/VBox/SummaryOverlay/Margin/VBox/SummaryStats
@onready var restart_blitz_btn: Button = $CenterContainer/ModalPanel/Margin/VBox/RestartBlitzBtn

var is_active: bool = false
var is_transitioning: bool = false
var time_left: float = 60.0
var score: int = 0
var combo: int = 1
var puzzles_cleared: int = 0
var blitz_levels: Array = []
var blitz_level_index: int = 0
var current_blitz_lvl: Dictionary = {}

func _ready() -> void:
	_ensure_nodes()
	visible = false
	if close_btn:
		close_btn.pressed.connect(hide_dialog)
	if restart_blitz_btn:
		restart_blitz_btn.pressed.connect(_on_restart_pressed)
	if game_board:
		game_board.blitz_mode = true
		if game_board.has_signal("puzzle_solved_immediately"):
			game_board.puzzle_solved_immediately.connect(func(): is_transitioning = true)
		if game_board.has_signal("puzzle_won"):
			game_board.puzzle_won.connect(_on_blitz_level_won)
		
	_collect_blitz_levels()

func _ensure_nodes() -> void:
	if not modal_panel:
		modal_panel = get_node_or_null("CenterContainer/ModalPanel")
	if not timer_label:
		timer_label = get_node_or_null("CenterContainer/ModalPanel/Margin/VBox/TopBar/TimerPill/TimerLabel")
	if not score_label:
		score_label = get_node_or_null("CenterContainer/ModalPanel/Margin/VBox/TopBar/ScorePill/ScoreLabel")
	if not combo_label:
		combo_label = get_node_or_null("CenterContainer/ModalPanel/Margin/VBox/TopBar/ComboPill/ComboLabel")
	if not close_btn:
		close_btn = get_node_or_null("CenterContainer/ModalPanel/Margin/VBox/TopBar/CloseBtn")
	if not game_board:
		game_board = get_node_or_null("CenterContainer/ModalPanel/Margin/VBox/BoardCenter/BoardContainer/GameBoard")
	if not summary_overlay:
		summary_overlay = get_node_or_null("CenterContainer/ModalPanel/Margin/VBox/SummaryOverlay")
	if not summary_title:
		summary_title = get_node_or_null("CenterContainer/ModalPanel/Margin/VBox/SummaryOverlay/Margin/VBox/SummaryTitle")
	if not summary_stats:
		summary_stats = get_node_or_null("CenterContainer/ModalPanel/Margin/VBox/SummaryOverlay/Margin/VBox/SummaryStats")
	if not restart_blitz_btn:
		restart_blitz_btn = get_node_or_null("CenterContainer/ModalPanel/Margin/VBox/RestartBlitzBtn")

func _get_gm() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/GameManager")

func _get_sm() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/SoundManager")

func _collect_blitz_levels() -> void:
	var gm = _get_gm()
	if not gm or gm.all_levels.is_empty():
		return
	blitz_levels.clear()
	# Collect quick, fast-action puzzles (optimal moves <= 10)
	for lvl in gm.all_levels:
		var opt = int(lvl.get("optimal_moves", 99))
		if opt <= 10 and opt >= 3:
			blitz_levels.append(lvl)
	if blitz_levels.is_empty():
		blitz_levels = gm.all_levels.slice(0, 20)

func show_dialog() -> void:
	_ensure_nodes()
	visible = true
	z_index = 190
	if modal_panel:
		modal_panel.pivot_offset = modal_panel.size * 0.5
		modal_panel.scale = Vector2(0.8, 0.8)
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(modal_panel, "scale", Vector2.ONE, 0.28)
	
	start_blitz()

func hide_dialog() -> void:
	is_active = false
	var t = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(modal_panel, "scale", Vector2(0.8, 0.8), 0.18)
	await t.finished
	visible = false

func start_blitz() -> void:
	_ensure_nodes()
	if blitz_levels.is_empty():
		_collect_blitz_levels()
		
	time_left = 60.0
	score = 0
	combo = 1
	puzzles_cleared = 0
	blitz_level_index = 0
	is_transitioning = false
	is_active = true
	
	var title_lbl = get_node_or_null("CenterContainer/ModalPanel/Margin/VBox/HeaderBox/ModeTitle")
	if title_lbl: title_lbl.text = tr("MSG_BLITZ_TITLE")
	var desc_lbl = get_node_or_null("CenterContainer/ModalPanel/Margin/VBox/HeaderBox/ModeDesc")
	if desc_lbl: desc_lbl.text = tr("MSG_BLITZ_DESC")
	if close_btn: close_btn.text = "✕"
	if summary_overlay:
		summary_overlay.visible = false
	if restart_blitz_btn:
		restart_blitz_btn.text = tr("BTN_BLITZ_RESET")
		restart_blitz_btn.disabled = false
	
	_update_ui()
	_load_next_blitz_puzzle()
	
	var sm = _get_sm()
	if sm:
		sm.play_star()

func _process(delta: float) -> void:
	if not is_active or is_transitioning:
		return
		
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_end_blitz()
		
	_update_ui()

func _update_ui() -> void:
	var secs = int(ceil(time_left))
	if timer_label:
		timer_label.text = "⏱️ %02ds" % secs
		if time_left <= 10.0:
			timer_label.add_theme_color_override("font_color", Color("#FF4757"))
		else:
			timer_label.add_theme_color_override("font_color", Color(1, 0.45, 0.2, 1))
	if score_label:
		score_label.text = "⭐ %d PTS" % score
	if combo_label:
		combo_label.text = "🔥 x%d" % combo

func _load_next_blitz_puzzle() -> void:
	if blitz_levels.is_empty() or not game_board:
		return
	current_blitz_lvl = blitz_levels[blitz_level_index % blitz_levels.size()]
	blitz_level_index += 1
	game_board.blitz_mode = true
	game_board.load_level(current_blitz_lvl)
	is_transitioning = false

func _on_blitz_level_won() -> void:
	if not is_active:
		return
		
	var points = 100 * combo
	score += points
	puzzles_cleared += 1
	combo = mini(5, combo + 1)
	time_left += 5.0 # +5s time bonus!
	
	var sm = _get_sm()
	if sm:
		sm.play_star()
		sm.trigger_haptic(40)
		
	_spawn_floating_text("+5s! +%d PTS!" % points)
	_load_next_blitz_puzzle()

func _spawn_floating_text(txt: String) -> void:
	var lbl = Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", Color("#2ED573"))
	lbl.top_level = true
	var center = game_board.global_position + game_board.size * 0.5
	lbl.global_position = center
	add_child(lbl)
	
	var t = create_tween().set_parallel(true)
	t.tween_property(lbl, "global_position:y", center.y - 80.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(lbl, "modulate:a", 0.0, 0.7).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(lbl.queue_free)

func _end_blitz() -> void:
	is_active = false
	var gm = _get_gm()
	var is_new_record = false
	var coins_earned = int(score / 5.0)
	if gm:
		is_new_record = gm.record_blitz_score(score)
		
	var sm = _get_sm()
	if sm:
		sm.play_win()
		sm.trigger_haptic(80)
		
	summary_title.text = "🏆 NEW HIGH SCORE!" if is_new_record else "⏰ TIME'S UP!"
	summary_stats.text = "Score: %d PTS • Cleared: %d • Coins: +%d 🪙" % [score, puzzles_cleared, coins_earned]
	summary_overlay.visible = true
	
	restart_blitz_btn.text = tr("BTN_BLITZ_AGAIN")
	restart_blitz_btn.disabled = false

func _on_restart_pressed() -> void:
	var sm = _get_sm()
	if sm:
		sm.play_tap()
	if is_active:
		if not is_transitioning and not current_blitz_lvl.is_empty() and game_board:
			game_board.load_level(current_blitz_lvl)
	else:
		start_blitz()
