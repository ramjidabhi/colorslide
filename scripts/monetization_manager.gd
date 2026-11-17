extends Node

## MonetizationManager Autoload
## Production-ready wrapper for AdMob / Mediation, Google Play Billing (IAP),
## Google Play In-App Review, and Firebase Analytics.
## Automatically binds native Android singletons when packaged with plugins,
## and degrades gracefully when running offline or in desktop builds.

signal rewarded_ad_completed(placement: String)
signal remove_ads_purchased()
signal gpgs_sign_in_completed(success: bool)
signal gpgs_cloud_save_synced(success: bool)
signal gpgs_leaderboard_submitted(score: int, success: bool)

const ADMOB_APP_ID: String = "ca-app-pub-6827648916951660~3848367705"
const REWARDED_AD_UNIT_ID: String = "ca-app-pub-6827648916951660/1711113358"
const BANNER_AD_UNIT_ID: String = ""
const INTERSTITIAL_AD_UNIT_ID: String = ""

## Google Official Sample Test Ad IDs (Guaranteed 100% fill rate for testing before live ad unit propagation)
const TEST_REWARDED_AD_UNIT_ID: String = "ca-app-pub-3940256099942544/5224354917"
const TEST_APP_ID: String = "ca-app-pub-3940256099942544~3347511713"

var use_test_ads: bool = false # Set false for final Play Store production release

func get_active_rewarded_ad_id() -> String:
	return TEST_REWARDED_AD_UNIT_ID if use_test_ads else REWARDED_AD_UNIT_ID

var ads_removed: bool = false
var last_interstitial_time: int = 0
const INTERSTITIAL_COOLDOWN_SEC: int = 90
const MIN_LEVEL_FOR_INTERSTITIAL: int = 6

var _admob_singleton: Object = null
var _billing_singleton: Object = null
var _review_singleton: Object = null
var _analytics_singleton: Object = null
var _gpgs_singleton: Object = null

var _pending_reward_callback: Callable = Callable()
var _pending_reward_placement: String = ""
var _reward_granted: bool = false

var is_gpgs_authenticated: bool = false
var last_cloud_sync_time: int = 0
var session_events: Array = []

func _ready() -> void:
	_bind_native_plugins()
	_init_admob()
	log_event("app_open", {"platform": OS.get_name()})

func _bind_native_plugins() -> void:
	if Engine.has_singleton("PoingAdMob"):
		_admob_singleton = Engine.get_singleton("PoingAdMob")
	elif Engine.has_singleton("AdMob"):
		_admob_singleton = Engine.get_singleton("AdMob")

	if Engine.has_singleton("GodotGooglePlayBilling"):
		_billing_singleton = Engine.get_singleton("GodotGooglePlayBilling")

	if Engine.has_singleton("GodotPlayInAppReview"):
		_review_singleton = Engine.get_singleton("GodotPlayInAppReview")

	if Engine.has_singleton("FirebaseAnalytics"):
		_analytics_singleton = Engine.get_singleton("FirebaseAnalytics")

	if Engine.has_singleton("GodotPlayGames"):
		_gpgs_singleton = Engine.get_singleton("GodotPlayGames")
	elif Engine.has_singleton("PlayGamesServices"):
		_gpgs_singleton = Engine.get_singleton("PlayGamesServices")
	elif Engine.has_singleton("PGSSnapshot"):
		_gpgs_singleton = Engine.get_singleton("PGSSnapshot")

func _init_admob() -> void:
	if _admob_singleton:
		if _admob_singleton.has_method("init"):
			_admob_singleton.init()
		
		# Connect native AdMob signals if present
		if _admob_singleton.has_signal("rewarded_ad_user_earned_reward"):
			if not _admob_singleton.is_connected("rewarded_ad_user_earned_reward", _on_rewarded_ad_user_earned_reward):
				_admob_singleton.connect("rewarded_ad_user_earned_reward", _on_rewarded_ad_user_earned_reward)
		if _admob_singleton.has_signal("rewarded_ad_closed"):
			if not _admob_singleton.is_connected("rewarded_ad_closed", _on_rewarded_ad_closed):
				_admob_singleton.connect("rewarded_ad_closed", _on_rewarded_ad_closed)
		if _admob_singleton.has_signal("rewarded_ad_failed_to_load"):
			if not _admob_singleton.is_connected("rewarded_ad_failed_to_load", _on_rewarded_ad_failed_to_load):
				_admob_singleton.connect("rewarded_ad_failed_to_load", _on_rewarded_ad_failed_to_load)
		if _admob_singleton.has_signal("rewarded_ad_loaded"):
			if not _admob_singleton.is_connected("rewarded_ad_loaded", _on_rewarded_ad_loaded):
				_admob_singleton.connect("rewarded_ad_loaded", _on_rewarded_ad_loaded)

		preload_rewarded_ad()

func is_internet_available() -> bool:
	if _admob_singleton and _admob_singleton.has_method("is_internet_available"):
		return _admob_singleton.is_internet_available()
	return true

func is_rewarded_ad_available() -> bool:
	if _admob_singleton:
		if _admob_singleton.has_method("is_rewarded_ad_loaded"):
			return _admob_singleton.is_rewarded_ad_loaded()
		if _admob_singleton.has_method("isRewardedVideoLoaded"):
			return _admob_singleton.isRewardedVideoLoaded()
		return false
	# Desktop/editor simulation fallback
	return true

func preload_rewarded_ad() -> void:
	if _admob_singleton:
		var ad_id = get_active_rewarded_ad_id()
		if _admob_singleton.has_method("load_rewarded_ad"):
			_admob_singleton.load_rewarded_ad(ad_id)
		elif _admob_singleton.has_method("loadRewardedVideo"):
			_admob_singleton.loadRewardedVideo(ad_id)

func request_rewarded_ad(placement: String, on_reward: Callable) -> bool:
	log_event("rewarded_ad_request", {"placement": placement})
	if _admob_singleton:
		var ad_loaded = is_rewarded_ad_available()
		if ad_loaded:
			_pending_reward_callback = on_reward
			_pending_reward_placement = placement
			_reward_granted = false
			if _admob_singleton.has_method("show_rewarded_ad"):
				_admob_singleton.show_rewarded_ad()
				return true
			elif _admob_singleton.has_method("showRewardedVideo"):
				_admob_singleton.showRewardedVideo()
				return true
		else:
			# Not loaded yet; request load
			preload_rewarded_ad()
			return false

	# Offline / Desktop / Debug fallback: simulate immediate completion & grant reward
	if on_reward.is_valid():
		on_reward.call()
	rewarded_ad_completed.emit(placement)
	log_event("rewarded_ad_completed", {"placement": placement, "source": "simulated"})
	return true

func _on_rewarded_ad_user_earned_reward(type: String, amount: int) -> void:
	_reward_granted = true
	log_event("rewarded_ad_user_earned_reward", {"placement": _pending_reward_placement, "type": type, "amount": amount})
	if _pending_reward_callback.is_valid():
		_pending_reward_callback.call()
		_pending_reward_callback = Callable()
	rewarded_ad_completed.emit(_pending_reward_placement)

func _on_rewarded_ad_closed() -> void:
	log_event("rewarded_ad_closed", {"placement": _pending_reward_placement, "granted": _reward_granted})
	_pending_reward_placement = ""
	_pending_reward_callback = Callable()
	preload_rewarded_ad()

func _on_rewarded_ad_loaded() -> void:
	log_event("rewarded_ad_loaded", {})

func _on_rewarded_ad_failed_to_load(error_code: int) -> void:
	log_event("rewarded_ad_failed_to_load", {"code": error_code})

func maybe_show_interstitial(level_id: int) -> void:
	if ads_removed or level_id < MIN_LEVEL_FOR_INTERSTITIAL:
		return
	var now = int(Time.get_unix_time_from_system())
	if now - last_interstitial_time < INTERSTITIAL_COOLDOWN_SEC:
		return
	if _admob_singleton and _admob_singleton.has_method("show_interstitial"):
		_admob_singleton.show_interstitial()
		last_interstitial_time = now
		log_event("interstitial_shown", {"level_id": level_id})

func is_billing_available() -> bool:
	return _billing_singleton != null

func purchase_remove_ads(on_success: Callable) -> bool:
	log_event("iap_initiate", {"sku": "remove_ads"})
	if _billing_singleton and _billing_singleton.has_method("purchase"):
		_billing_singleton.purchase("remove_ads")
		return true
	# Debug/test purchase simulation when Billing plugin is not attached
	if OS.is_debug_build():
		ads_removed = true
		if on_success.is_valid():
			on_success.call()
		remove_ads_purchased.emit()
		log_event("iap_success", {"sku": "remove_ads", "source": "debug_sim"})
		return true
	return false

func request_in_app_review(package_id: String) -> void:
	log_event("rate_prompt_accepted", {"package": package_id})
	if _review_singleton and _review_singleton.has_method("request_review"):
		_review_singleton.request_review()
		return
	if OS.get_name() == "Android":
		var err = OS.shell_open("market://details?id=" + package_id)
		if err != OK:
			OS.shell_open("https://play.google.com/store/apps/details?id=" + package_id)
	else:
		OS.shell_open("https://play.google.com/store/apps/details?id=" + package_id)

func log_event(event_name: String, params: Dictionary = {}) -> void:
	var entry = {
		"name": event_name,
		"params": params,
		"ts": int(Time.get_unix_time_from_system())
	}
	session_events.append(entry)
	if session_events.size() > 200:
		session_events.pop_front()
	if _analytics_singleton and _analytics_singleton.has_method("log_event"):
		_analytics_singleton.log_event(event_name, params)

# ----------------- GOOGLE PLAY GAMES SERVICES (GPGS) -----------------

func is_gpgs_available() -> bool:
	return _gpgs_singleton != null or OS.is_debug_build()

func gpgs_sign_in(on_complete: Callable = Callable()) -> void:
	log_event("gpgs_sign_in_requested")
	if _gpgs_singleton:
		if _gpgs_singleton.has_method("sign_in"):
			_gpgs_singleton.sign_in()
		elif _gpgs_singleton.has_method("signIn"):
			_gpgs_singleton.signIn()
		is_gpgs_authenticated = true
	else:
		is_gpgs_authenticated = false  # No GPGS plugin present — do NOT mark as authenticated
	
	if on_complete.is_valid():
		on_complete.call(is_gpgs_authenticated)
	gpgs_sign_in_completed.emit(is_gpgs_authenticated)
	log_event("gpgs_sign_in_finished", {"authenticated": is_gpgs_authenticated})

func sync_cloud_save(save_dict: Dictionary, on_complete: Callable = Callable()) -> void:
	log_event("cloud_save_sync_start")
	var success = false
	if _gpgs_singleton:
		var json_str = JSON.stringify(save_dict)
		if _gpgs_singleton.has_method("save_snapshot"):
			_gpgs_singleton.save_snapshot("colorslide_cloud_save", json_str, "ColorSlide AutoSave")
			success = true
		elif _gpgs_singleton.has_method("saveSnapshot"):
			_gpgs_singleton.saveSnapshot("colorslide_cloud_save", json_str, "ColorSlide AutoSave")
			success = true
	else:
		success = true

	if success:
		last_cloud_sync_time = int(Time.get_unix_time_from_system())
	if on_complete.is_valid():
		on_complete.call(success)
	gpgs_cloud_save_synced.emit(success)
	log_event("cloud_save_sync_done", {"success": success})

func submit_blitz_score(score: int, leaderboard_id: String = "leaderboard_blitz_rush_hour") -> void:
	log_event("blitz_score_submitted", {"score": score})
	var success = false
	if _gpgs_singleton:
		if _gpgs_singleton.has_method("submit_score"):
			_gpgs_singleton.submit_score(leaderboard_id, score)
			success = true
		elif _gpgs_singleton.has_method("submitScore"):
			_gpgs_singleton.submitScore(leaderboard_id, score)
			success = true
	else:
		success = true
	gpgs_leaderboard_submitted.emit(score, success)

func show_leaderboard(leaderboard_id: String = "leaderboard_blitz_rush_hour") -> void:
	log_event("show_leaderboard", {"id": leaderboard_id})
	if _gpgs_singleton:
		if _gpgs_singleton.has_method("show_leaderboard"):
			_gpgs_singleton.show_leaderboard(leaderboard_id)
		elif _gpgs_singleton.has_method("showLeaderBoard"):
			_gpgs_singleton.showLeaderBoard(leaderboard_id)

func show_achievements() -> void:
	log_event("show_achievements")
	if _gpgs_singleton:
		if _gpgs_singleton.has_method("show_achievements"):
			_gpgs_singleton.show_achievements()
		elif _gpgs_singleton.has_method("showAchievements"):
			_gpgs_singleton.showAchievements()

func unlock_achievement(achievement_id: String) -> void:
	log_event("unlock_achievement", {"id": achievement_id})
	if _gpgs_singleton:
		if _gpgs_singleton.has_method("unlock_achievement"):
			_gpgs_singleton.unlock_achievement(achievement_id)
		elif _gpgs_singleton.has_method("unlockAchievement"):
			_gpgs_singleton.unlockAchievement(achievement_id)
