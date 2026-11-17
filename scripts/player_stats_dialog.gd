extends Control

## PlayerStatsDialog.gd
## Displays lifetime player journey, completion progress, crowns, and mastery metrics.

signal closed()

@onready var levels_val: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/ContentScroll/CardsVBox/LevelsCard/Value")
@onready var stars_val: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/ContentScroll/CardsVBox/StarsCard/Value")
@onready var crowns_val: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/ContentScroll/CardsVBox/CrownsCard/Value")
@onready var pure_val: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/ContentScroll/CardsVBox/PureCrownsCard/Value")
@onready var moves_val: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/ContentScroll/CardsVBox/MovesCard/Value")
@onready var time_val: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/ContentScroll/CardsVBox/PlaytimeCard/Value")
@onready var streak_val: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/ContentScroll/CardsVBox/StreakCard/Value")
@onready var blitz_val: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/ContentScroll/CardsVBox/BlitzCard/Value")
@onready var close_btn: Button = get_node_or_null("CenterContainer/ModalPanel/VBox/CloseButton")
@onready var modal_panel: Panel = get_node_or_null("CenterContainer/ModalPanel")

func _ready() -> void:
	visible = false
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)

func show_dialog() -> void:
	refresh_stats()
	visible = true
	modulate = Color(1, 1, 1, 0)
	if modal_panel:
		modal_panel.scale = Vector2(0.9, 0.9)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	if modal_panel:
		tw.tween_property(modal_panel, "scale", Vector2.ONE, 0.25)
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()

func refresh_stats() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
		
	var completed = gm.get_completed_levels_count()
	var total_lvls = gm.all_levels.size() if not gm.all_levels.is_empty() else 200
	var pct = gm.get_completion_percentage()
	if levels_val:
		levels_val.text = "%d / %d (%.1f%%)" % [completed, total_lvls, pct]
		
	if stars_val:
		stars_val.text = "⭐ %d / %d" % [gm.get_total_stars(), total_lvls * 3]
		
	if crowns_val:
		crowns_val.text = "👑 %d / %d" % [gm.get_total_crowns(), total_lvls]
		
	if pure_val:
		pure_val.text = "🛡️ %d (No Boosters)" % gm.get_total_booster_free_crowns()
		
	if moves_val:
		moves_val.text = "👣 %s moves" % _format_number(gm.total_moves_made)
		
	if time_val:
		var total_sec = gm.total_playtime_seconds
		var hrs = int(total_sec / 3600.0)
		var mins = int((total_sec % 3600) / 60.0)
		time_val.text = "⏱️ %dh %02dm" % [hrs, mins]
		
	if streak_val:
		streak_val.text = "🔥 %d Days (Best: %d)" % [gm.daily_streak, gm.best_daily_streak]
		
	if blitz_val:
		blitz_val.text = "⚡ %d pts" % gm.blitz_high_score

func _format_number(val: int) -> String:
	if val < 1000:
		return str(val)
	var s = str(val)
	var res = ""
	var cnt = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			res = "," + res
	return res

func _on_close_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	if modal_panel:
		tw.tween_property(modal_panel, "scale", Vector2(0.9, 0.9), 0.15)
	await tw.finished
	visible = false
	closed.emit()
