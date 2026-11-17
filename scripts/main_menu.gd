extends Control

## MainMenu.gd - Premium Title / Home Screen Controller
## Displays game title, Daily Challenge button with live streak counter,
## play/continue button, 200-level select, cosmetics shop, and settings.

@onready var daily_btn: Button = $SafeMargin/MainLayout/ButtonsVBox/DailyButton
@onready var play_btn: Button = $SafeMargin/MainLayout/ButtonsVBox/PlayButton
@onready var levels_btn: Button = $SafeMargin/MainLayout/ButtonsVBox/LevelsButton
@onready var blitz_btn: Button = get_node_or_null("SafeMargin/MainLayout/ButtonsVBox/BlitzButton")
@onready var shop_btn: Button = $SafeMargin/MainLayout/TopBar/ShopButton
@onready var piggy_btn: Button = $SafeMargin/MainLayout/TopBar/PiggyButton
@onready var wheel_btn: Button = $SafeMargin/MainLayout/TopBar/WheelButton
@onready var stats_btn: Button = get_node_or_null("SafeMargin/MainLayout/TopBar/StatsButton")
@onready var settings_btn: Button = $SafeMargin/MainLayout/TopBar/SettingsButton
@onready var coins_label: Label = $SafeMargin/MainLayout/TopBar/CoinsBox/CoinsLabel
@onready var progress_badge: Label = $SafeMargin/MainLayout/HeroCenter/VBox/ProgressBadge
@onready var hero_card: PanelContainer = $SafeMargin/MainLayout/HeroCenter/VBox/HeroCard
@onready var sub_title: Label = get_node_or_null("SafeMargin/MainLayout/HeroCenter/VBox/TitleBox/SubTitle")
@onready var tagline_label: Label = get_node_or_null("SafeMargin/MainLayout/HeroCenter/VBox/HeroCard/Center/ArtVBox/Tagline")

@onready var settings_dialog: Control = $SettingsDialog
@onready var daily_dialog: Control = $DailyChallengeDialog
@onready var shop_dialog: Control = $ShopDialog
@onready var wheel_dialog: Control = $LuckyWheelDialog
@onready var piggy_dialog: Control = $PiggyBankDialog
@onready var blitz_dialog: Control = get_node_or_null("BlitzModeDialog")
@onready var stats_dialog: Control = get_node_or_null("PlayerStatsDialog")

var float_tween: Tween

func _ready() -> void:
	if daily_btn:
		daily_btn.pressed.connect(_on_daily_pressed)
	play_btn.pressed.connect(_on_play_pressed)
	levels_btn.pressed.connect(_on_levels_pressed)
	if blitz_btn:
		blitz_btn.pressed.connect(_on_blitz_pressed)
	if shop_btn:
		shop_btn.pressed.connect(_on_shop_pressed)
	if piggy_btn:
		piggy_btn.pressed.connect(_on_piggy_pressed)
	if wheel_btn:
		wheel_btn.pressed.connect(_on_wheel_pressed)
	if stats_btn:
		stats_btn.pressed.connect(_on_stats_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.apply_safe_area(get_node_or_null("SafeMargin"), 70, 50, 48)
		gm.progress_saved.connect(_update_ui)
		gm.skin_changed.connect(func(_s): _update_ui())
		if gm.has_signal("language_changed"):
			gm.language_changed.connect(func(_loc): _update_ui())
		if gm.has_signal("piggy_updated"):
			gm.piggy_updated.connect(func(_c, _m): _update_ui())
	
	_update_ui()
	_start_hero_floating_animation()

func _update_ui() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		coins_label.text = "🪙 " + str(gm.total_coins)
		if piggy_btn:
			piggy_btn.text = "🐷 %d" % gm.piggy_coins
		if wheel_btn:
			if gm.can_spin_wheel():
				wheel_btn.text = "🎡 FREE!"
			else:
				wheel_btn.text = "🎡 SPIN"
		if sub_title:
			sub_title.text = tr("MSG_SUBTITLE")
		if tagline_label:
			tagline_label.text = tr("MSG_TAGLINE")
		if levels_btn:
			levels_btn.text = tr("BTN_LEVEL_SELECT")
		var footer_lbl = get_node_or_null("SafeMargin/MainLayout/FooterLabel")
		if footer_lbl:
			footer_lbl.text = tr("MSG_FOOTER")
		var unlocked = gm.highest_unlocked_level
		progress_badge.text = tr("MSG_PROGRESS_BADGE") % unlocked
		if unlocked > 1:
			play_btn.text = "%s (LEVEL %d) →" % [tr("BTN_CONTINUE"), unlocked]
		else:
			play_btn.text = tr("BTN_PLAY")
			
		if daily_btn:
			if gm.is_daily_completed_today():
				daily_btn.text = tr("BTN_DAILY_REPLAY")
			elif gm.daily_streak > 0:
				daily_btn.text = "🔥 DAILY PUZZLE (STREAK: %d) →" % gm.daily_streak
			else:
				daily_btn.text = tr("BTN_DAILY")
				
		if blitz_btn:
			if gm.blitz_high_score > 0:
				blitz_btn.text = "⚡ RUSH HOUR BLITZ (BEST: %d) →" % gm.blitz_high_score
			else:
				blitz_btn.text = tr("BTN_BLITZ")

func _start_hero_floating_animation() -> void:
	if not hero_card:
		return
	if float_tween and float_tween.is_valid():
		float_tween.kill()
		
	hero_card.pivot_offset = hero_card.size * 0.5
	float_tween = create_tween().set_loops()
	float_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(hero_card, "position:y", hero_card.position.y - 12.0, 1.8)
	float_tween.tween_property(hero_card, "position:y", hero_card.position.y + 12.0, 1.8)

func _on_daily_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	if daily_dialog:
		daily_dialog.show_dialog()

func _on_shop_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	if shop_dialog:
		shop_dialog.show_dialog()

func _on_play_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		var target_idx = clamp(gm.highest_unlocked_level - 1, 0, gm.all_levels.size() - 1)
		gm.play_level(target_idx)

func _on_levels_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.go_to_level_select()

func _on_settings_pressed() -> void:
	if settings_dialog:
		settings_dialog.open_dialog()

func _on_stats_pressed() -> void:
	if stats_dialog:
		stats_dialog.show_dialog()

func _on_piggy_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	if piggy_dialog:
		piggy_dialog.show_dialog()

func _on_wheel_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	if wheel_dialog:
		wheel_dialog.show_dialog()

func _on_blitz_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	if blitz_dialog:
		blitz_dialog.show_dialog()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if blitz_dialog and blitz_dialog.visible:
			blitz_dialog.hide_dialog()
		elif wheel_dialog and wheel_dialog.visible:
			wheel_dialog.hide_dialog()
		elif piggy_dialog and piggy_dialog.visible:
			piggy_dialog.hide_dialog()
		elif shop_dialog and shop_dialog.visible:
			shop_dialog.hide_dialog()
		elif daily_dialog and daily_dialog.visible:
			daily_dialog.hide_dialog()
		elif settings_dialog and settings_dialog.visible:
			settings_dialog.hide_dialog()
		else:
			get_tree().quit()

