extends Control

## SettingsDialog.gd - Game Settings Modal
## Manages audio toggle, progress reset, and modal animations.

signal closed()

@onready var modal_panel: Panel = $CenterContainer/ModalPanel
@onready var title_label: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/TitleLabel")
@onready var sound_label: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/SoundRow/Label")
@onready var sound_toggle_btn: Button = $CenterContainer/ModalPanel/VBox/SoundRow/SoundToggleBtn
@onready var haptic_label: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/HapticRow/Label")
@onready var haptic_toggle_btn: Button = get_node_or_null("CenterContainer/ModalPanel/VBox/HapticRow/HapticToggleBtn")
@onready var music_label: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/MusicRow/Label")
@onready var music_toggle_btn: Button = get_node_or_null("CenterContainer/ModalPanel/VBox/MusicRow/MusicToggleBtn")
@onready var pet_label: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/PetRow/Label")
@onready var pet_toggle_btn: Button = get_node_or_null("CenterContainer/ModalPanel/VBox/PetRow/PetToggleBtn")
@onready var lang_label: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/LangRow/Label")
@onready var lang_toggle_btn: Button = get_node_or_null("CenterContainer/ModalPanel/VBox/LangRow/LangToggleBtn")
@onready var cb_label: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/ColorblindRow/Label")
@onready var cb_toggle_btn: Button = get_node_or_null("CenterContainer/ModalPanel/VBox/ColorblindRow/ColorblindToggleBtn")
@onready var privacy_btn: Button = get_node_or_null("CenterContainer/ModalPanel/VBox/PrivacyBtn")
@onready var privacy_label: Label = get_node_or_null("CenterContainer/ModalPanel/VBox/PrivacyLabel")
@onready var reset_btn: Button = $CenterContainer/ModalPanel/VBox/ResetBtn
@onready var close_btn: Button = $CenterContainer/ModalPanel/VBox/CloseBtn
@onready var confirm_label: Label = $CenterContainer/ModalPanel/VBox/ConfirmLabel

var confirm_pending: bool = false

func _ready() -> void:
	visible = false
	sound_toggle_btn.pressed.connect(_on_sound_toggle_pressed)
	if haptic_toggle_btn:
		haptic_toggle_btn.pressed.connect(_on_haptic_toggle_pressed)
	if music_toggle_btn:
		music_toggle_btn.pressed.connect(_on_music_toggle_pressed)
	if pet_toggle_btn:
		pet_toggle_btn.pressed.connect(_on_pet_toggle_pressed)
	if lang_toggle_btn:
		lang_toggle_btn.pressed.connect(_on_lang_toggle_pressed)
	if cb_toggle_btn:
		cb_toggle_btn.pressed.connect(_on_cb_toggle_pressed)
	if privacy_btn:
		privacy_btn.pressed.connect(_on_privacy_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)
	close_btn.pressed.connect(hide_dialog)
	_apply_translations()
	_update_sound_ui()
	_update_haptic_ui()
	_update_music_ui()
	_update_pet_ui()
	_update_lang_ui()
	_update_cb_ui()

func open_dialog() -> void:
	visible = true
	confirm_pending = false
	if confirm_label:
		confirm_label.visible = false
	if privacy_label:
		privacy_label.visible = false
	_apply_translations()
	_update_sound_ui()
	_update_haptic_ui()
	_update_music_ui()
	_update_pet_ui()
	_update_lang_ui()
	_update_cb_ui()
	
	modal_panel.pivot_offset = modal_panel.size * 0.5
	modal_panel.scale = Vector2(0.8, 0.8)
	var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(modal_panel, "scale", Vector2.ONE, 0.25)
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()

func hide_dialog() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	visible = false
	closed.emit()

func _update_sound_ui() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.is_muted:
		sound_toggle_btn.text = "OFF 🔇"
		sound_toggle_btn.modulate = Color(0.7, 0.7, 0.7, 1)
	else:
		sound_toggle_btn.text = "ON 🔊"
		sound_toggle_btn.modulate = Color(0.2, 0.9, 0.5, 1)

func _on_sound_toggle_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.toggle_mute()
		_update_sound_ui()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.save_progress()

func _update_haptic_ui() -> void:
	if not haptic_toggle_btn:
		return
	var sm = get_node_or_null("/root/SoundManager")
	if sm and not sm.is_haptics_enabled:
		haptic_toggle_btn.text = "OFF 📳"
		haptic_toggle_btn.modulate = Color(0.7, 0.7, 0.7, 1)
	else:
		haptic_toggle_btn.text = "ON 📳"
		haptic_toggle_btn.modulate = Color(0.2, 0.9, 0.5, 1)

func _on_haptic_toggle_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.toggle_haptics()
		_update_haptic_ui()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.save_progress()

func _update_pet_ui() -> void:
	if not pet_toggle_btn:
		return
	var gm = get_node_or_null("/root/GameManager")
	if gm and not gm.pet_rescue_enabled:
		pet_toggle_btn.text = "CLASSIC ➔"
		pet_toggle_btn.modulate = Color(0.75, 0.85, 1.0, 1)
	else:
		pet_toggle_btn.text = "PETS 🐶"
		pet_toggle_btn.modulate = Color(0.2, 0.9, 0.7, 1)

func _on_pet_toggle_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.pet_rescue_enabled = not gm.pet_rescue_enabled
		gm.save_progress()
	_update_pet_ui()

func _on_privacy_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	if privacy_label:
		privacy_label.visible = not privacy_label.visible

func _update_music_ui() -> void:
	if not music_toggle_btn:
		return
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.is_music_muted:
		music_toggle_btn.text = "OFF 🔇"
		music_toggle_btn.modulate = Color(0.7, 0.7, 0.7, 1)
	else:
		music_toggle_btn.text = "ON 🎵"
		music_toggle_btn.modulate = Color(0.2, 0.9, 0.5, 1)

func _on_music_toggle_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
		sm.toggle_music()
		_update_music_ui()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.save_progress()

func _update_lang_ui() -> void:
	if not lang_toggle_btn:
		return
	var gm = get_node_or_null("/root/GameManager")
	var code = gm.language_code.to_upper() if gm else "EN"
	lang_toggle_btn.text = "🌐 " + code

func _on_lang_toggle_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.cycle_language()
		_apply_translations()
		_update_lang_ui()

func _apply_translations() -> void:
	if title_label: title_label.text = tr("MSG_SETTINGS")
	if sound_label: sound_label.text = tr("LBL_SOUND")
	if haptic_label: haptic_label.text = tr("LBL_HAPTIC")
	if music_label: music_label.text = tr("LBL_MUSIC")
	if pet_label: pet_label.text = tr("LBL_THEME")
	if lang_label: lang_label.text = tr("LBL_LANG")
	if cb_label: cb_label.text = tr("LBL_COLORBLIND")
	if privacy_btn: privacy_btn.text = tr("BTN_PRIVACY")
	if not confirm_pending: reset_btn.text = tr("BTN_RESET_PROGRESS")
	close_btn.text = tr("BTN_DONE")

func _update_cb_ui() -> void:
	if not cb_toggle_btn:
		return
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.colorblind_mode:
		cb_toggle_btn.text = "ON 👁️"
		cb_toggle_btn.modulate = Color(0.2, 0.9, 0.5, 1)
	else:
		cb_toggle_btn.text = "OFF"
		cb_toggle_btn.modulate = Color(0.7, 0.7, 0.7, 1)

func _on_cb_toggle_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.colorblind_mode = not gm.colorblind_mode
		gm.save_progress()
		if gm.has_signal("accessibility_updated"):
			gm.accessibility_updated.emit()
	_update_cb_ui()

func _on_reset_pressed() -> void:
	if not confirm_pending:
		confirm_pending = true
		reset_btn.text = "Tap Again to Confirm Reset!"
		if confirm_label:
			confirm_label.visible = true
			confirm_label.text = "Are you sure? All stars & progress will reset!"
	else:
		confirm_pending = false
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			gm.reset_progress()
		if confirm_label:
			confirm_label.text = "Progress Reset to Level 1!"
		reset_btn.text = "Progress Reset Completed"
		await get_tree().create_timer(1.0).timeout
		hide_dialog()
