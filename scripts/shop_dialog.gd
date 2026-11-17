extends Control

## ShopDialog.gd - Block Skins & Cosmetics Shop
## Drives coin economy, high retention, and player personalization.
## Allows players to spend coins earned from levels & daily challenges
## on stunning visual block skins.

signal skin_selected(skin_id: String)

@onready var modal_panel: Panel = $CenterContainer/ModalPanel
@onready var coins_label: Label = $CenterContainer/ModalPanel/VBox/TopBar/CoinsBox/CoinsLabel
@onready var skins_container: VBoxContainer = $CenterContainer/ModalPanel/VBox/Scroll/SkinsVBox
@onready var close_btn: Button = $CenterContainer/ModalPanel/VBox/CloseButton

func _ready() -> void:
	visible = false
	if close_btn:
		close_btn.pressed.connect(hide_dialog)
		
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.skin_changed.connect(func(_s): refresh_ui())
		gm.progress_saved.connect(refresh_ui)

func show_dialog() -> void:
	refresh_ui()
	visible = true
	z_index = 160
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
	var title_lbl = get_node_or_null("CenterContainer/ModalPanel/VBox/TopBar/TitleLabel")
	if title_lbl: title_lbl.text = tr("MSG_SHOP_TITLE")
	var sub_lbl = get_node_or_null("CenterContainer/ModalPanel/VBox/SubLabel")
	if sub_lbl: sub_lbl.text = tr("MSG_SHOP_SUB")
	if close_btn: close_btn.text = tr("BTN_BACK_GAME")
		
	coins_label.text = "🪙 %d" % gm.total_coins
	
	for child in skins_container.get_children():
		child.queue_free()
		
	var mm = get_node_or_null("/root/MonetizationManager")
	if mm:
		skins_container.add_child(_create_free_hints_card(mm, gm))
		skins_container.add_child(_create_free_coins_card(mm, gm))
		if mm.is_billing_available():
			skins_container.add_child(_create_remove_ads_card(mm))

	var skin_keys = ["classic", "neon", "woodcraft", "gemstone", "gold"]
	for s_id in skin_keys:
		if not gm.SKIN_DEFS.has(s_id):
			continue
		var s_data = gm.SKIN_DEFS[s_id]
		var card = _create_skin_card(gm, s_id, s_data)
		skins_container.add_child(card)

func _create_free_hints_card(mm: Node, gm: Node) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 108)
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(20)
	style.set_border_width_all(2)
	style.bg_color = Color("#17202A")
	style.border_color = Color("#00D2D3")
	card.add_theme_stylebox_override("panel", style)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)
	var icon_lbl = Label.new()
	icon_lbl.text = "💡"
	icon_lbl.add_theme_font_size_override("font_size", 40)
	hbox.add_child(icon_lbl)
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl = Label.new()
	name_lbl.text = "+1 Free Hint"
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(name_lbl)
	var desc_lbl = Label.new()
	desc_lbl.text = "Watch a quick video ad to claim 1 free hint!"
	desc_lbl.add_theme_font_size_override("font_size", 19)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.88, 0.9))
	info.add_child(desc_lbl)
	hbox.add_child(info)
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(190, 76)
	btn.add_theme_font_size_override("font_size", 22)
	btn.text = "🎬 WATCH (+1 💡)"
	btn.pressed.connect(func():
		var sm = get_node_or_null("/root/SoundManager")
		if sm: sm.play_tap()
		var success = mm.request_rewarded_ad("shop_free_hints", func():
			gm.add_hints(1)
			if sm: sm.play_win()
			refresh_ui()
		)
		if not success:
			desc_lbl.text = "⏳ Ad loading or no internet. Please check connection."
	)
	hbox.add_child(btn)
	return card

func _create_free_coins_card(mm: Node, gm: Node) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 108)
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(20)
	style.set_border_width_all(2)
	style.bg_color = Color("#17202A")
	style.border_color = Color("#F1C40F")
	card.add_theme_stylebox_override("panel", style)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)
	var icon_lbl = Label.new()
	icon_lbl.text = "🪙"
	icon_lbl.add_theme_font_size_override("font_size", 40)
	hbox.add_child(icon_lbl)
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl = Label.new()
	name_lbl.text = "+100 Free Coins"
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(name_lbl)
	var desc_lbl = Label.new()
	desc_lbl.text = "Watch a quick video ad to claim 100 free coins!"
	desc_lbl.add_theme_font_size_override("font_size", 19)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.88, 0.9))
	info.add_child(desc_lbl)
	hbox.add_child(info)
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(190, 76)
	btn.add_theme_font_size_override("font_size", 22)
	btn.text = "🎬 WATCH (+100)"
	btn.pressed.connect(func():
		var sm = get_node_or_null("/root/SoundManager")
		if sm: sm.play_tap()
		var success = mm.request_rewarded_ad("shop_free_coins", func():
			gm.add_coins(100)
			if sm: sm.play_win()
			refresh_ui()
		)
		if not success:
			desc_lbl.text = "⏳ Ad loading or no internet. Please check connection."
	)
	hbox.add_child(btn)
	return card

func _create_remove_ads_card(mm: Node) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 108)
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(20)
	style.set_border_width_all(2)
	style.bg_color = Color("#1B192B")
	style.border_color = Color("#2ED573") if mm.ads_removed else Color("#FF6B81")
	card.add_theme_stylebox_override("panel", style)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)
	var icon_lbl = Label.new()
	icon_lbl.text = "🛡️"
	icon_lbl.add_theme_font_size_override("font_size", 40)
	hbox.add_child(icon_lbl)
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl = Label.new()
	name_lbl.text = tr("IAP_REMOVE_ADS")
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(name_lbl)
	var desc_lbl = Label.new()
	desc_lbl.text = "Play forever without interstitial breaks."
	desc_lbl.add_theme_font_size_override("font_size", 19)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.88, 0.9))
	info.add_child(desc_lbl)
	hbox.add_child(info)
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(190, 76)
	btn.add_theme_font_size_override("font_size", 24)
	if mm.ads_removed:
		btn.text = "ACTIVE ✓"
		btn.disabled = true
	else:
		btn.text = "$2.99"
		btn.pressed.connect(func():
			mm.purchase_remove_ads(func():
				var gm = get_node_or_null("/root/GameManager")
				if gm: gm.save_progress()
				refresh_ui()
			)
		)
	hbox.add_child(btn)
	return card

func _create_skin_card(gm: Node, s_id: String, s_data: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 114)
	
	var is_equipped = (gm.equipped_skin == s_id)
	var is_unlocked = gm.unlocked_skins.has(s_id)
	var cost = s_data.get("cost", 0)
	
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(20)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	
	if is_equipped:
		style.bg_color = Color("#17242B")
		style.border_color = Color("#00D2D3")
	else:
		style.bg_color = Color("#151824")
		style.border_color = Color("#252E42")
		
	card.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)
	
	# Live Rendered Skin Block Swatch
	var swatch = _create_skin_swatch(s_id)
	hbox.add_child(swatch)
	
	# Info VBox
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	
	var name_lbl = Label.new()
	name_lbl.text = s_data.get("name", "")
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	info_vbox.add_child(name_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = s_data.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", 19)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85, 0.85))
	info_vbox.add_child(desc_lbl)
	hbox.add_child(info_vbox)
	
	# Action Button
	var act_btn = Button.new()
	act_btn.custom_minimum_size = Vector2(180, 76)
	act_btn.add_theme_font_size_override("font_size", 24)
	act_btn.clip_text = true
	
	var btn_style = StyleBoxFlat.new()
	btn_style.set_corner_radius_all(18)
	
	if is_equipped:
		act_btn.text = tr("BTN_EQUIPPED")
		btn_style.bg_color = Color("#00D2D3")
		act_btn.add_theme_color_override("font_color", Color("#0A1017"))
		act_btn.disabled = true
	elif is_unlocked:
		act_btn.text = tr("BTN_EQUIP")
		btn_style.bg_color = Color("#222E42")
		btn_style.border_width_left = 2
		btn_style.border_width_top = 2
		btn_style.border_width_right = 2
		btn_style.border_width_bottom = 2
		btn_style.border_color = Color("#3B5072")
		act_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		act_btn.pressed.connect(func():
			var sm = get_node_or_null("/root/SoundManager")
			if sm: sm.play_tap()
			gm.equip_skin(s_id)
		)
	else:
		act_btn.text = "🪙 %d" % cost
		if gm.total_coins >= cost:
			btn_style.bg_color = Color("#E67E22")
			act_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			act_btn.pressed.connect(func():
				var sm = get_node_or_null("/root/SoundManager")
				if sm: sm.play_star()
				gm.unlock_skin(s_id)
			)
		else:
			btn_style.bg_color = Color("#1E222D")
			act_btn.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65, 0.6))
			act_btn.disabled = true
			
	act_btn.add_theme_stylebox_override("normal", btn_style)
	act_btn.add_theme_stylebox_override("disabled", btn_style)
	hbox.add_child(act_btn)
	
	return card

func _create_skin_swatch(s_id: String) -> Control:
	var swatch = Control.new()
	swatch.custom_minimum_size = Vector2(76, 56)
	swatch.draw.connect(func():
		var r = Rect2(Vector2(2, 6), Vector2(72, 44))
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(12)
		sb.set_border_width_all(3)
		var base_col = Color("#FF4757")
		match s_id:
			"neon":
				sb.bg_color = base_col.darkened(0.2)
				sb.border_color = Color("#00D2D3")
			"woodcraft":
				sb.bg_color = base_col.lerp(Color("#8B4513"), 0.45)
				sb.border_color = Color("#D2B48C")
			"gemstone":
				sb.bg_color = base_col.lerp(Color("#4A0072"), 0.25)
				sb.border_color = Color("#E0AAFF")
			"gold":
				sb.bg_color = base_col.lerp(Color("#DAA520"), 0.4)
				sb.border_color = Color("#FFD700")
			_:
				sb.bg_color = base_col
				sb.border_color = Color(1.0, 0.9, 0.7, 0.75)
		swatch.draw_style_box(sb, r)
		swatch.draw_line(Vector2(10, 10), Vector2(66, 10), Color(1, 1, 1, 0.35), 2.0)
	)
	return swatch
