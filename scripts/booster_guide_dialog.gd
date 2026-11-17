extends Control

## BoosterGuideDialog.gd
## Introduces the 3 special power-ups (Sledgehammer, Shrink Ray, Crane Picker)
## when the player reaches/clears Level 5, rewarding them with 3 of each!

signal guide_closed()

@onready var modal_panel: Panel = $CenterContainer/ModalPanel
@onready var title_label: Label = $CenterContainer/ModalPanel/VBox/TitleLabel
@onready var sub_label: Label = $CenterContainer/ModalPanel/VBox/SubLabel
@onready var claim_btn: Button = $CenterContainer/ModalPanel/VBox/ClaimButton

var is_first_time_reward: bool = false

func _ready() -> void:
	visible = false
	if claim_btn:
		claim_btn.pressed.connect(_on_claim_pressed)

func show_dialog(first_time: bool = false) -> void:
	is_first_time_reward = first_time
	visible = true
	z_index = 220
	
	if first_time:
		title_label.text = "🎉 BOOSTERS UNLOCKED!"
		sub_label.text = "Congratulations on clearing Level 5!\nHere is your Starter Pack (3x of Each Free):"
		claim_btn.text = "CLAIM 3x BOOSTERS & PLAY ▶"
	else:
		title_label.text = "💡 POWER-UPS GUIDE"
		sub_label.text = "Use special features when stuck on difficult puzzles:"
		claim_btn.text = "GOT IT! RETURN TO GAME 👍"
		
	modal_panel.pivot_offset = modal_panel.size * 0.5
	modal_panel.scale = Vector2(0.8, 0.8)
	var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(modal_panel, "scale", Vector2.ONE, 0.26)
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		if first_time:
			sm.play_win()
		else:
			sm.play_tap()

func _on_claim_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
		
	var gm = get_node_or_null("/root/GameManager")
	if is_first_time_reward and gm:
		gm.unlock_boosters_starter_pack()
		
	var t = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(modal_panel, "scale", Vector2(0.8, 0.8), 0.18)
	await t.finished
	visible = false
	guide_closed.emit()
