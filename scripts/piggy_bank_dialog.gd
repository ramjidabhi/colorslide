extends Control

## PiggyBankDialog.gd - Interactive Mascot Piggy Bank (Coin Vault)
## #1 converting casual puzzle retention & monetization mechanic.
## Features tactile piggy tapping with ASMR coin rattle, daily coin boost,
## golden milestone progress meter, and explosive smash animations.

signal piggy_smashed(coins_claimed: int)

@onready var modal_panel: Panel = $CenterContainer/ModalPanel
@onready var speech_label: Label = $CenterContainer/ModalPanel/Margin/VBox/SpeechBubble/Margin/SpeechLabel
@onready var piggy_btn: Button = $CenterContainer/ModalPanel/Margin/VBox/PiggyCenter/PiggyBtn
@onready var piggy_mascot: Control = $CenterContainer/ModalPanel/Margin/VBox/PiggyCenter/PiggyBtn/PiggyMascot
@onready var coins_status_label: Label = $CenterContainer/ModalPanel/Margin/VBox/StatusBox/CoinsStatusLabel
@onready var progress_container: Control = $CenterContainer/ModalPanel/Margin/VBox/ProgressContainer
@onready var smash_btn: Button = $CenterContainer/ModalPanel/Margin/VBox/SmashButton
@onready var boost_btn: Button = $CenterContainer/ModalPanel/Margin/VBox/BoostButton
@onready var close_btn: Button = $CenterContainer/ModalPanel/Margin/VBox/CloseButton

var bob_tween: Tween
var jiggle_tween: Tween
var quote_index: int = 0
const PIGGY_QUOTES = [
	"✨ Oink! Tap me to shake coins!",
	"🪙 Clink clink! I'm getting heavier!",
	"⭐ Solve puzzles to feed me coins!",
	"🎉 Almost full! Smash me when ready!",
	"🐷 Yummy stars! Feed me more!",
	"💎 Ka-ching! Keep the streak going!"
]

func _ready() -> void:
	visible = false
	if close_btn:
		close_btn.pressed.connect(hide_dialog)
	if smash_btn:
		smash_btn.pressed.connect(_on_smash_pressed)
	if boost_btn:
		boost_btn.pressed.connect(_on_boost_pressed)
	if piggy_btn:
		piggy_btn.pressed.connect(_on_piggy_tapped)
	if piggy_mascot:
		piggy_mascot.draw.connect(_on_piggy_draw)
	if progress_container:
		progress_container.draw.connect(_on_progress_draw)
		
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("piggy_updated"):
		gm.piggy_updated.connect(func(_c, _m): refresh_ui())

func show_dialog() -> void:
	refresh_ui()
	visible = true
	z_index = 175
	modal_panel.pivot_offset = modal_panel.size * 0.5
	modal_panel.scale = Vector2(0.8, 0.8)
	var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(modal_panel, "scale", Vector2.ONE, 0.28)
	
	_start_piggy_idle()
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()

func hide_dialog() -> void:
	if bob_tween and bob_tween.is_valid():
		bob_tween.kill()
	if jiggle_tween and jiggle_tween.is_valid():
		jiggle_tween.kill()
	var t = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(modal_panel, "scale", Vector2(0.8, 0.8), 0.18)
	await t.finished
	visible = false

func _start_piggy_idle() -> void:
	if bob_tween and bob_tween.is_valid():
		bob_tween.kill()
	if not piggy_btn:
		return
	piggy_btn.pivot_offset = piggy_btn.size * 0.5
	piggy_btn.scale = Vector2.ONE
	bob_tween = create_tween().set_loops()
	bob_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob_tween.tween_property(piggy_btn, "scale", Vector2(1.06, 0.96), 0.8)
	bob_tween.tween_property(piggy_btn, "scale", Vector2(0.96, 1.05), 0.8)

func _on_piggy_tapped() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_coin_rattle()
		sm.trigger_haptic(25)
		
	# Bouncy squash and stretch animation
	if jiggle_tween and jiggle_tween.is_valid():
		jiggle_tween.kill()
	piggy_btn.pivot_offset = piggy_btn.size * 0.5
	jiggle_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	piggy_btn.scale = Vector2(1.22, 0.82)
	jiggle_tween.tween_property(piggy_btn, "scale", Vector2(0.92, 1.15), 0.15)
	jiggle_tween.tween_property(piggy_btn, "scale", Vector2(1.05, 0.95), 0.15)
	jiggle_tween.tween_property(piggy_btn, "scale", Vector2.ONE, 0.2)
	
	# Spawn floating sparkle coins
	_spawn_tap_sparkles()
	
	# Cycle speech quote
	quote_index = (quote_index + 1) % PIGGY_QUOTES.size()
	speech_label.text = PIGGY_QUOTES[quote_index]
	
	if piggy_mascot:
		piggy_mascot.queue_redraw()

func _spawn_tap_sparkles() -> void:
	var center = piggy_btn.global_position + piggy_btn.size * 0.5
	for i in range(3):
		var spark = Label.new()
		spark.text = "🪙" if i == 0 else "✨"
		spark.add_theme_font_size_override("font_size", 28)
		spark.top_level = true
		spark.global_position = center + Vector2(randf_range(-30, 30), randf_range(-20, 20))
		add_child(spark)
		
		var t = create_tween().set_parallel(true)
		var dest = spark.global_position + Vector2(randf_range(-40, 40), - randf_range(60, 100))
		t.tween_property(spark, "global_position", dest, 0.6).set_ease(Tween.EASE_OUT)
		t.tween_property(spark, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
		t.chain().tween_callback(spark.queue_free)

func _on_boost_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
		
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_star()
		sm.trigger_haptic(40)
		
	gm.record_piggy_boost()
	speech_label.text = "🎉 +50 Free Coins Deposited! Yum!"
	
	# Spawn flying coins to the pig
	var start_pos = boost_btn.global_position + boost_btn.size * 0.5
	var end_pos = piggy_btn.global_position + piggy_btn.size * 0.5
	for i in range(5):
		var coin = Label.new()
		coin.text = "🪙"
		coin.add_theme_font_size_override("font_size", 32)
		coin.top_level = true
		coin.global_position = start_pos
		add_child(coin)
		
		var t = create_tween()
		t.tween_interval(i * 0.08)
		t.tween_property(coin, "global_position", end_pos, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		t.tween_callback(func():
			if sm:
				sm.play_tap()
			_on_piggy_tapped()
			coin.queue_free()
		)
	
	refresh_ui()

func refresh_ui() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	var title_lbl = get_node_or_null("CenterContainer/ModalPanel/Margin/VBox/TitleLabel")
	if title_lbl: title_lbl.text = tr("MSG_PIGGY_TITLE")
	var desc_lbl = get_node_or_null("CenterContainer/ModalPanel/Margin/VBox/DescLabel")
	if desc_lbl: desc_lbl.text = tr("MSG_PIGGY_DESC")
	if close_btn: close_btn.text = tr("BTN_BACK_GAME")
		
	var cur = gm.piggy_coins
	var max_val = gm.PIGGY_MAX
	var pct = int((float(cur) / float(max_val)) * 100.0)
	coins_status_label.text = "🪙 %d / %d COINS STORED (%d%%)" % [cur, max_val, pct]
	
	# Smash Button State
	if cur >= max_val:
		smash_btn.text = "🔨 SMASH FULL VAULT! (+%d COINS)" % cur
		smash_btn.disabled = false
		smash_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif cur > 0:
		smash_btn.text = "🔨 SMASH & CLAIM (+%d COINS)" % cur
		smash_btn.disabled = false
		smash_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		smash_btn.text = "🧩 PLAY PUZZLES TO FILL (+25/Win)"
		smash_btn.disabled = false # Keep active so player can tap to jump to level
		smash_btn.modulate = Color(0.85, 0.9, 1.0, 0.9)
		
	# Boost Button State
	if gm.can_claim_piggy_boost():
		boost_btn.text = "🎁 FREE DAILY BOOST (+50 🪙)"
		boost_btn.disabled = false
		boost_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		boost_btn.text = "✓ DAILY BOOST CLAIMED (READY TOMORROW)"
		boost_btn.disabled = true
		boost_btn.modulate = Color(0.65, 0.7, 0.8, 0.7)
		
	if piggy_mascot:
		piggy_mascot.queue_redraw()
	if progress_container:
		progress_container.queue_redraw()

func _on_smash_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
		
	if gm.piggy_coins <= 0:
		# If empty, let this button take the user to the current puzzle!
		hide_dialog()
		return
		
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_win()
		sm.trigger_haptic(100)
		
	# Screen shake
	var orig_pos = modal_panel.position
	var st = create_tween().set_trans(Tween.TRANS_SINE)
	for i in range(6):
		var offset = Vector2(randf_range(-14, 14), randf_range(-14, 14))
		st.tween_property(modal_panel, "position", orig_pos + offset, 0.04)
	st.tween_property(modal_panel, "position", orig_pos, 0.05)
	
	# Flying explosion of 14 golden coins
	var center = piggy_btn.global_position + piggy_btn.size * 0.5
	for i in range(14):
		var c = Label.new()
		c.text = "🪙"
		c.add_theme_font_size_override("font_size", 36)
		c.top_level = true
		c.global_position = center
		add_child(c)
		
		var ang = (TAU / 14.0) * i + randf_range(-0.15, 0.15)
		var dist = randf_range(160, 260)
		var dest = center + Vector2(cos(ang), sin(ang)) * dist
		
		var t = create_tween().set_parallel(true)
		t.tween_property(c, "global_position", dest, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(c, "scale", Vector2(1.3, 1.3), 0.3)
		t.chain().tween_property(c, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
		t.chain().tween_callback(c.queue_free)
		
	var claimed = gm.smash_piggy_bank()
	speech_label.text = "🎉 SMASHED! +%d COINS TRANSFERRED!" % claimed
	coins_status_label.text = "🪙 VAULT EMPTIED • SOLVE PUZZLES TO REFILL"
	smash_btn.text = "VAULT EMPTIED ✓"
	smash_btn.disabled = true
	
	piggy_smashed.emit(claimed)
	refresh_ui()

# ----------------- TACTILE PROCEDURAL DRAWINGS -----------------

func _on_piggy_draw() -> void:
	if not piggy_mascot:
		return
	var center = piggy_mascot.size * 0.5 + Vector2(0, 10)
	var gm = get_node_or_null("/root/GameManager")
	var coins = gm.piggy_coins if gm else 0
	
	# 1. Left & Right Ears
	var ear_col = Color("#FF5277")
	var ear_inner = Color("#FF2A55")
	var l_ear = PackedVector2Array([
		center + Vector2(-55, -45),
		center + Vector2(-75, -88),
		center + Vector2(-28, -65)
	])
	piggy_mascot.draw_colored_polygon(l_ear, ear_col)
	var l_inner = PackedVector2Array([
		center + Vector2(-52, -48),
		center + Vector2(-68, -80),
		center + Vector2(-34, -64)
	])
	piggy_mascot.draw_colored_polygon(l_inner, ear_inner)
	
	var r_ear = PackedVector2Array([
		center + Vector2(55, -45),
		center + Vector2(75, -88),
		center + Vector2(28, -65)
	])
	piggy_mascot.draw_colored_polygon(r_ear, ear_col)
	var r_inner = PackedVector2Array([
		center + Vector2(52, -48),
		center + Vector2(68, -80),
		center + Vector2(34, -64)
	])
	piggy_mascot.draw_colored_polygon(r_inner, ear_inner)
	
	# 2. Main Piggy Ceramic Body
	piggy_mascot.draw_circle(center, 74.0, Color("#FF6584"))
	# 3D Highlight sheen on top-left
	piggy_mascot.draw_circle(center + Vector2(-18, -18), 44.0, Color(1.0, 0.55, 0.68, 0.35))
	
	# 3. Golden Coin Slot on top
	var slot_rect = Rect2(center.x - 26, center.y - 74, 52, 10)
	piggy_mascot.draw_rect(slot_rect, Color("#3A1522"), true)
	piggy_mascot.draw_rect(slot_rect, Color("#FFD700"), false, 2.5)
	
	# Golden coin peeking out if coins > 0
	if coins > 0:
		var coin_center = center + Vector2(0, -78)
		piggy_mascot.draw_circle(coin_center, 15.0, Color("#FFA502"))
		piggy_mascot.draw_arc(coin_center, 15.0, 0, TAU, 16, Color("#FFD700"), 2.0)
		piggy_mascot.draw_circle(coin_center, 6.0, Color("#FFD700"))
		
	# 4. Cute Snout
	var snout_center = center + Vector2(0, 14)
	var snout_rect = Rect2(snout_center.x - 30, snout_center.y - 20, 60, 40)
	piggy_mascot.draw_style_box(_get_snout_style(), snout_rect)
	# Nostrils
	piggy_mascot.draw_circle(snout_center + Vector2(-10, 0), 5.0, Color("#C02048"))
	piggy_mascot.draw_circle(snout_center + Vector2(10, 0), 5.0, Color("#C02048"))
	
	# 5. Sparkling Cartoon Eyes
	var l_eye = center + Vector2(-28, -14)
	var r_eye = center + Vector2(28, -14)
	piggy_mascot.draw_circle(l_eye, 9.0, Color("#1C1524"))
	piggy_mascot.draw_circle(l_eye + Vector2(-2, -2), 3.2, Color.WHITE)
	piggy_mascot.draw_circle(r_eye, 9.0, Color("#1C1524"))
	piggy_mascot.draw_circle(r_eye + Vector2(-2, -2), 3.2, Color.WHITE)
	
	# 6. Blushing Rosy Cheeks
	piggy_mascot.draw_circle(center + Vector2(-48, 6), 13.0, Color(1.0, 0.35, 0.5, 0.45))
	piggy_mascot.draw_circle(center + Vector2(48, 6), 13.0, Color(1.0, 0.35, 0.5, 0.45))

func _get_snout_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color("#FF8DA1")
	s.border_color = Color("#FF4757")
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left = 18
	s.corner_radius_top_right = 18
	s.corner_radius_bottom_right = 18
	s.corner_radius_bottom_left = 18
	return s

func _on_progress_draw() -> void:
	if not progress_container:
		return
	var rect = Rect2(Vector2.ZERO, progress_container.size)
	var gm = get_node_or_null("/root/GameManager")
	var cur = gm.piggy_coins if gm else 0
	var max_val = gm.PIGGY_MAX if gm else 1000
	var fill_ratio = clamp(float(cur) / float(max_val), 0.0, 1.0)
	
	# Track background
	var track_style = StyleBoxFlat.new()
	track_style.bg_color = Color(0.12, 0.1, 0.16, 0.95)
	track_style.border_color = Color(0.28, 0.22, 0.35, 0.8)
	track_style.border_width_left = 2
	track_style.border_width_top = 2
	track_style.border_width_right = 2
	track_style.border_width_bottom = 2
	track_style.corner_radius_top_left = 16
	track_style.corner_radius_top_right = 16
	track_style.corner_radius_bottom_right = 16
	track_style.corner_radius_bottom_left = 16
	progress_container.draw_style_box(track_style, rect)
	
	# Fill bar with golden sheen
	if fill_ratio > 0.01:
		var fill_w = max(32.0, rect.size.x * fill_ratio)
		var fill_rect = Rect2(rect.position, Vector2(fill_w, rect.size.y))
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color("#FFA502")
		fill_style.border_color = Color("#FFD700")
		fill_style.border_width_top = 2
		fill_style.border_width_bottom = 2
		fill_style.border_width_left = 2
		fill_style.border_width_right = 2
		fill_style.corner_radius_top_left = 16
		fill_style.corner_radius_top_right = 16 if fill_ratio >= 0.98 else 6
		fill_style.corner_radius_bottom_right = 16 if fill_ratio >= 0.98 else 6
		fill_style.corner_radius_bottom_left = 16
		progress_container.draw_style_box(fill_style, fill_rect)
		
		# Top glossy highlight line
		progress_container.draw_line(
			Vector2(12, 6),
			Vector2(fill_w - 12, 6),
			Color(1.0, 1.0, 1.0, 0.45),
			3.0
		)
		
	# Milestone notches at 25%, 50%, 75%
	for notch in [0.25, 0.5, 0.75]:
		var nx = rect.size.x * notch
		var col = Color("#FFD700") if fill_ratio >= notch else Color(0.4, 0.45, 0.55, 0.6)
		progress_container.draw_line(Vector2(nx, 4), Vector2(nx, rect.size.y - 4), col, 2.5)
