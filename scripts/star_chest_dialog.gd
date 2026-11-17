extends Control

## StarChestDialog.gd - Milestone Star Chests
## Rewards players every 10 levels (L10, L20, L30...) with bonus coins & hints.
## Drastically boosts per-session retention and creates irresistible short-term goals.

signal chest_claimed(milestone_level: int)

@onready var modal_panel: Panel = $CenterContainer/ModalPanel
@onready var title_label: Label = $CenterContainer/ModalPanel/VBox/TitleLabel
@onready var sub_label: Label = $CenterContainer/ModalPanel/VBox/SubLabel
@onready var chest_icon: Label = $CenterContainer/ModalPanel/VBox/ChestIcon
@onready var reward_label: Label = $CenterContainer/ModalPanel/VBox/RewardBox/RewardLabel
@onready var claim_btn: Button = $CenterContainer/ModalPanel/VBox/ClaimButton

var current_milestone: int = 10
var is_opened: bool = false
var pulse_tween: Tween

func _ready() -> void:
	visible = false
	if claim_btn:
		claim_btn.pressed.connect(_on_claim_pressed)
		
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("chest_ready"):
		gm.chest_ready.connect(open_milestone_chest)

func open_milestone_chest(milestone_level: int) -> void:
	current_milestone = milestone_level
	is_opened = false
	visible = true
	z_index = 210  # Highest priority above all win dialogs
	
	title_label.text = tr("MSG_CHEST_TITLE")
	sub_label.text = "LEVEL %d MASTERED!" % milestone_level
	chest_icon.text = "🎁"
	reward_label.text = "Tap to open your mystery chest!"
	claim_btn.text = tr("BTN_CHEST_OPEN")
	
	# Start pulsing chest
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	chest_icon.scale = Vector2.ONE
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(chest_icon, "scale", Vector2(1.2, 1.2), 0.45).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(chest_icon, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)
	
	modal_panel.pivot_offset = modal_panel.size * 0.5
	modal_panel.scale = Vector2(0.7, 0.7)
	var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(modal_panel, "scale", Vector2.ONE, 0.3)
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_star()

func _on_claim_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if not is_opened:
		# First click: Open Chest
		is_opened = true
		if pulse_tween and pulse_tween.is_valid():
			pulse_tween.kill()
			
		chest_icon.text = "✨ 💎 🪙 ✨"
		chest_icon.scale = Vector2(1.4, 1.4)
		var pop_t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop_t.tween_property(chest_icon, "scale", Vector2.ONE, 0.25)
		
		reward_label.text = "+150 COINS  •  +2 HINTS!"
		claim_btn.text = tr("BTN_CHEST_COLLECT")
		
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			gm.claim_milestone_chest(current_milestone)
			
		if sm:
			sm.play_win()
	else:
		# Second click: Close
		if sm:
			sm.play_tap()
		visible = false
		chest_claimed.emit(current_milestone)
