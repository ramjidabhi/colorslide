extends Control

## LuckyWheelDialog.gd - Daily Lucky Fortune Wheel
## Drives morning DAU and retention with an interactive carnival wheel.
## Features ASMR peg clicks, pointer bounce, LED rim lights, and extra spins.

signal reward_claimed(reward_dict: Dictionary)

@onready var modal_panel: Panel = $CenterContainer/ModalPanel
@onready var wheel_disc: Control = $CenterContainer/ModalPanel/Margin/VBox/WheelCenter/WheelDisc
@onready var spin_btn: Button = $CenterContainer/ModalPanel/Margin/VBox/SpinButton
@onready var extra_spin_btn: Button = $CenterContainer/ModalPanel/Margin/VBox/ExtraSpinButton
@onready var timer_label: Label = $CenterContainer/ModalPanel/Margin/VBox/TimerBadge/Margin/TimerLabel
@onready var result_label: Label = $CenterContainer/ModalPanel/Margin/VBox/ResultLabel
@onready var close_btn: Button = $CenterContainer/ModalPanel/Margin/VBox/CloseButton

const SECTORS = [
	{ "name": "+15 Coins", "type": "coins", "amount": 15, "color": Color("#FFA502") },
	{ "name": "+1 Hint", "type": "hints", "amount": 1, "color": Color("#00D2D3") },
	{ "name": "+25 Coins", "type": "coins", "amount": 25, "color": Color("#2ED573") },
	{ "name": "Rare Skin!", "type": "skin", "amount": 1, "color": Color("#9B59B6") },
	{ "name": "+35 Coins", "type": "coins", "amount": 35, "color": Color("#E67E22") },
	{ "name": "+2 Hints", "type": "hints", "amount": 2, "color": Color("#1DD1A1") },
	{ "name": "👑 75 JACKPOT", "type": "coins", "amount": 75, "color": Color("#FFD700") },
	{ "name": "+20 Coins", "type": "coins", "amount": 20, "color": Color("#54A0FF") }
]

var is_spinning: bool = false
var wheel_rotation_deg: float = 0.0
var pointer_flick_deg: float = 0.0
var last_sector_tick: int = -1
var spin_tween: Tween

func _ready() -> void:
	visible = false
	if close_btn:
		close_btn.pressed.connect(hide_dialog)
	if spin_btn:
		spin_btn.pressed.connect(_on_spin_pressed)
	if extra_spin_btn:
		extra_spin_btn.pressed.connect(_on_extra_spin_pressed)
	if wheel_disc:
		wheel_disc.draw.connect(_on_wheel_draw)

func show_dialog() -> void:
	refresh_ui()
	visible = true
	z_index = 180
	result_label.text = "Spin the wheel for your daily reward!"
	modal_panel.pivot_offset = modal_panel.size * 0.5
	modal_panel.scale = Vector2(0.8, 0.8)
	var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(modal_panel, "scale", Vector2.ONE, 0.28)
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()

func hide_dialog() -> void:
	if spin_tween and spin_tween.is_valid():
		spin_tween.kill()
	var t = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(modal_panel, "scale", Vector2(0.8, 0.8), 0.18)
	await t.finished
	visible = false

func refresh_ui() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	var title_lbl = get_node_or_null("CenterContainer/ModalPanel/Margin/VBox/TitleLabel")
	if title_lbl: title_lbl.text = tr("MSG_WHEEL_TITLE")
	if close_btn: close_btn.text = tr("BTN_BACK_GAME")
		
	var can_free_spin = gm.can_spin_wheel()
	if can_free_spin:
		timer_label.text = "✨ Free Daily Spin Ready!"
		timer_label.add_theme_color_override("font_color", Color("#2ED573"))
		spin_btn.text = tr("BTN_WHEEL_SPIN")
		spin_btn.disabled = false
		spin_btn.modulate = Color(1, 1, 1, 1)
	else:
		var secs = gm.get_seconds_until_next_spin()
		var hrs = secs / 3600
		var mins = (secs % 3600) / 60
		timer_label.text = "Next Free Spin in: %02dh %02dm" % [hrs, mins]
		timer_label.add_theme_color_override("font_color", Color("#A4B0BE"))
		spin_btn.text = "✓ FREE SPIN CLAIMED TODAY"
		spin_btn.disabled = true
		spin_btn.modulate = Color(0.65, 0.7, 0.8, 0.65)
		
	# Extra Spin Button
	if extra_spin_btn:
		if gm.total_coins >= 100:
			extra_spin_btn.text = "✨ EXTRA SPIN (100 🪙)"
			extra_spin_btn.disabled = false
			extra_spin_btn.modulate = Color(1, 1, 1, 1)
		else:
			extra_spin_btn.text = "✨ NEED 100 🪙 FOR EXTRA SPIN"
			extra_spin_btn.disabled = true
			extra_spin_btn.modulate = Color(0.6, 0.65, 0.75, 0.6)

func _on_spin_pressed() -> void:
	if is_spinning:
		return
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.record_wheel_spin()
	_execute_spin()

func _on_extra_spin_pressed() -> void:
	if is_spinning:
		return
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.total_coins >= 100:
		gm.total_coins -= 100
		gm.save_progress()
		_execute_spin()

func _execute_spin() -> void:
	is_spinning = true
	spin_btn.disabled = true
	if extra_spin_btn:
		extra_spin_btn.disabled = true
	result_label.text = "Spinning... Good luck! 🍀"
	
	var chosen_idx = randi() % SECTORS.size()
	var sector_angle = 360.0 / float(SECTORS.size())
	var target_sector_angle = (chosen_idx * sector_angle) + (sector_angle * 0.5)
	var total_rotations = (4 + randi() % 3) * 360.0
	var final_rotation = total_rotations + (360.0 - target_sector_angle) + 90.0
	
	if spin_tween and spin_tween.is_valid():
		spin_tween.kill()
		
	spin_tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	var start_deg = wheel_rotation_deg
	last_sector_tick = int(start_deg / sector_angle)
	
	spin_tween.tween_method(func(val: float):
		wheel_rotation_deg = val
		var cur_sector = int(val / sector_angle)
		if cur_sector != last_sector_tick:
			last_sector_tick = cur_sector
			var sm = get_node_or_null("/root/SoundManager")
			if sm:
				sm.play_peg_tick()
			pointer_flick_deg = -18.0
			var pt = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			pt.tween_property(self, "pointer_flick_deg", 0.0, 0.12)
			
		if wheel_disc:
			wheel_disc.queue_redraw()
	, start_deg, start_deg + final_rotation, 4.0)
	
	await spin_tween.finished
	is_spinning = false
	
	# Reward
	var rew = SECTORS[chosen_idx]
	result_label.text = "🎉 YOU WON: %s!" % rew["name"]
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_win()
		sm.trigger_haptic(80)
		
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.claim_wheel_reward(rew["type"], rew["amount"])
		
	reward_claimed.emit(rew)
	refresh_ui()

# ----------------- TACTILE PROCEDURAL DRAWINGS -----------------

func _on_wheel_draw() -> void:
	if not wheel_disc:
		return
	var radius = 175.0
	var center = wheel_disc.size * 0.5
	var num_sectors = SECTORS.size()
	var arc_rad = TAU / float(num_sectors)
	var rot_rad = deg_to_rad(wheel_rotation_deg)
	
	# 1. Draw 8 Colored Wheel Wedges
	for i in range(num_sectors):
		var start_a = rot_rad + i * arc_rad
		var end_a = start_a + arc_rad
		var col = SECTORS[i]["color"]
		
		var pts = PackedVector2Array([center])
		for step in range(13):
			var a = start_a + (end_a - start_a) * (float(step) / 12.0)
			pts.append(center + Vector2(cos(a), sin(a)) * radius)
		wheel_disc.draw_colored_polygon(pts, col)
		
		# Divider spoke
		wheel_disc.draw_line(center, center + Vector2(cos(start_a), sin(start_a)) * radius, Color(0.1, 0.1, 0.15, 0.5), 2.5)
		
		# Reward badge with clear unit symbol
		var mid_a = start_a + arc_rad * 0.5
		var icon_pos = center + Vector2(cos(mid_a), sin(mid_a)) * (radius * 0.65)
		var sec = SECTORS[i]
		var txt = str(sec["amount"])
		if sec["type"] == "hints":
			txt = "%d💡" % sec["amount"]
		elif sec["type"] == "skin":
			txt = "🎨"
		elif int(sec["amount"]) >= 1000:
			txt = "1K👑"
		var fnt = wheel_disc.get_theme_default_font()
		wheel_disc.draw_circle(icon_pos, 24.0, Color(0.08, 0.1, 0.16, 0.78))
		wheel_disc.draw_string(fnt, icon_pos + Vector2(-30, 6), txt, HORIZONTAL_ALIGNMENT_CENTER, 60, 16, Color.WHITE)

	# 2. Glowing Golden Rim with 16 Carnival Bulbs
	wheel_disc.draw_arc(center, radius, 0, TAU, 48, Color("#FFD700"), 7.0)
	for b in range(16):
		var b_ang = rot_rad + (TAU / 16.0) * b
		var b_pos = center + Vector2(cos(b_ang), sin(b_ang)) * (radius - 3.0)
		var bulb_col = Color("#FFF9E6") if b % 2 == 0 else Color("#FFA502")
		wheel_disc.draw_circle(b_pos, 4.0, bulb_col)

	# 3. Central Medallion
	wheel_disc.draw_circle(center, 32.0, Color("#151824"))
	wheel_disc.draw_arc(center, 32.0, 0, TAU, 32, Color("#FFD700"), 3.5)
	wheel_disc.draw_circle(center, 14.0, Color("#FFD700"))
	
	# 4. Physical Pointer Needle (Stationary at top with flick angle)
	var ptr_tip = center + Vector2(0, -radius + 18)
	var ptr_rot = deg_to_rad(pointer_flick_deg)
	var p1 = ptr_tip + Vector2(-14, -28).rotated(ptr_rot)
	var p2 = ptr_tip + Vector2(14, -28).rotated(ptr_rot)
	var ptr_poly = PackedVector2Array([p1, p2, ptr_tip])
	wheel_disc.draw_colored_polygon(ptr_poly, Color("#FF4757"))
	wheel_disc.draw_polyline(PackedVector2Array([p1, p2, ptr_tip, p1]), Color("#FFD700"), 2.5)
