extends Node

## SoundManager - Procedural ASMR Sound Effects for Color Escape
## Generates clean tactile audio syntheses & material sound packs
## (Classic, Woodcraft, Gemstone, Cyber Neon, Royal Gold),
## plus coin rattles and lucky wheel peg tickers.

var is_muted: bool = false
var is_music_muted: bool = false
var is_haptics_enabled: bool = true
var audio_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
const POOL_SIZE = 8
const SAMPLE_RATE: int = 44100
const PADDING_SAMPLES: int = 32

var slide_stream: AudioStreamWAV
var slide_wood_stream: AudioStreamWAV
var slide_gem_stream: AudioStreamWAV
var slide_neon_stream: AudioStreamWAV
var slide_gold_stream: AudioStreamWAV

var bump_stream: AudioStreamWAV
var star_stream: AudioStreamWAV
var win_stream: AudioStreamWAV
var tap_stream: AudioStreamWAV
var coin_rattle_stream: AudioStreamWAV
var peg_tick_stream: AudioStreamWAV
var music_stream: AudioStreamWAV
var booster_smash_stream: AudioStreamWAV
var booster_shrink_stream: AudioStreamWAV
var booster_crane_lift_stream: AudioStreamWAV
var booster_crane_drop_stream: AudioStreamWAV

func _ready() -> void:
	# Create pool of AudioStreamPlayers for polyphonic sound
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		audio_players.append(player)

	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = -18.0
	add_child(music_player)
	
	_generate_sound_streams()
	get_tree().create_timer(0.4).timeout.connect(_update_music_state)

func _generate_sound_streams() -> void:
	slide_stream = _create_pop_tone(440.0, 0.08, 0.7)
	slide_wood_stream = _create_wood_tone(240.0, 0.09, 0.8)
	slide_gem_stream = _create_gem_tone(1150.0, 0.14, 0.7)
	slide_neon_stream = _create_neon_tone(580.0, 0.08, 0.75)
	slide_gold_stream = _create_gold_tone(880.0, 0.16, 0.8)

	bump_stream = _create_thud_tone(150.0, 0.06, 0.5)
	tap_stream = _create_click_tone(800.0, 0.04, 0.6)
	star_stream = _create_chime_tone(880.0, 0.25, 0.8)
	win_stream = _create_fanfare_tone()
	coin_rattle_stream = _create_coin_rattle_tone()
	peg_tick_stream = _create_peg_tick_tone()
	music_stream = _create_ambient_music_loop()
	booster_smash_stream = _create_smash_tone()
	booster_shrink_stream = _create_shrink_tone()
	booster_crane_lift_stream = _create_crane_lift_tone()
	booster_crane_drop_stream = _create_crane_drop_tone()
	if music_player and music_stream:
		music_player.stream = music_stream

func trigger_haptic(duration_ms: int = 20) -> void:
	if not is_haptics_enabled:
		return
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		Input.vibrate_handheld(duration_ms)

func play_slide(pitch_multiplier: float = 1.0) -> void:
	if is_muted:
		return
	var stream_to_play = slide_stream
	var gm = get_node_or_null("/root/GameManager")
	if gm and "equipped_skin" in gm:
		match gm.equipped_skin:
			"woodcraft": stream_to_play = slide_wood_stream
			"gemstone": stream_to_play = slide_gem_stream
			"neon": stream_to_play = slide_neon_stream
			"gold": stream_to_play = slide_gold_stream
			_: stream_to_play = slide_stream
			
	_play_stream(stream_to_play, pitch_multiplier)
	trigger_haptic(10)

func play_bump() -> void:
	if is_muted:
		return
	_play_stream(bump_stream, 1.0)
	trigger_haptic(25)

func play_tap() -> void:
	if is_muted:
		return
	_play_stream(tap_stream, 1.0)
	trigger_haptic(15)

func play_star(pitch_multiplier: float = 1.0) -> void:
	if is_muted:
		return
	_play_stream(star_stream, pitch_multiplier)
	trigger_haptic(30)

func play_win() -> void:
	if is_muted:
		return
	_play_stream(win_stream, 1.0)
	trigger_haptic(80)

func play_coin_rattle() -> void:
	if is_muted:
		return
	_play_stream(coin_rattle_stream, randf_range(0.95, 1.05))
	trigger_haptic(20)

func play_peg_tick() -> void:
	if is_muted:
		return
	_play_stream(peg_tick_stream, randf_range(0.98, 1.02))
	trigger_haptic(8)

func play_booster_smash() -> void:
	if is_muted:
		return
	_play_stream(booster_smash_stream, randf_range(0.95, 1.05))
	trigger_haptic(45)

func play_booster_shrink() -> void:
	if is_muted:
		return
	_play_stream(booster_shrink_stream, 1.0)
	trigger_haptic(25)

func play_booster_crane_lift() -> void:
	if is_muted:
		return
	_play_stream(booster_crane_lift_stream, 1.0)
	trigger_haptic(15)

func play_booster_crane_drop() -> void:
	if is_muted:
		return
	_play_stream(booster_crane_drop_stream, 1.0)
	trigger_haptic(35)

func toggle_mute() -> bool:
	is_muted = not is_muted
	return is_muted

func toggle_haptics() -> bool:
	is_haptics_enabled = not is_haptics_enabled
	if is_haptics_enabled:
		trigger_haptic(30)
	return is_haptics_enabled

func set_haptics_enabled(enabled: bool) -> void:
	is_haptics_enabled = enabled

func toggle_music() -> bool:
	is_music_muted = not is_music_muted
	_update_music_state()
	return is_music_muted

func set_music_muted(muted: bool) -> void:
	is_music_muted = muted
	_update_music_state()

func _update_music_state() -> void:
	if not is_inside_tree() or not music_player or not music_stream:
		return
	if is_music_muted:
		if music_player.playing:
			music_player.stop()
	else:
		if not music_player.playing:
			music_player.stream = music_stream
			music_player.play()

func _play_stream(stream: AudioStream, pitch: float = 1.0) -> void:
	if stream == null:
		return
	for player in audio_players:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = pitch
			player.play()
			return
	audio_players[0].stream = stream
	audio_players[0].pitch_scale = pitch
	audio_players[0].play()

# ----------------- PROCEDURAL SOUND SYNTHESIZERS -----------------

func _create_pop_tone(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = exp(-t * 35.0)
		var current_freq = freq * (1.0 + 0.8 * (1.0 - t / duration))
		var val = sin(2.0 * PI * current_freq * t) * envelope * amp
		var sample_16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)
		
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = bytes
	return s

func _create_wood_tone(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = exp(-t * 60.0)
		var val = (sin(2.0 * PI * freq * t) * 0.75 + sin(2.0 * PI * (freq * 2.1) * t) * 0.25) * envelope * amp
		var sample_16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = bytes
	return s

func _create_gem_tone(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = exp(-t * 14.0)
		var val = (sin(2.0 * PI * freq * t) * 0.6 + sin(2.0 * PI * (freq * 2.76) * t) * 0.3 + sin(2.0 * PI * (freq * 4.2) * t) * 0.1) * envelope * amp
		var sample_16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = bytes
	return s

func _create_neon_tone(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = exp(-t * 28.0)
		# Square/saw hybrid with low pass harmonic
		var phase = fmod(t * freq, 1.0)
		var saw = (phase * 2.0 - 1.0) * 0.4
		var sine = sin(2.0 * PI * freq * t) * 0.6
		var val = (saw + sine) * envelope * amp
		var sample_16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = bytes
	return s

func _create_gold_tone(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = exp(-t * 12.0)
		# Warm brass harmonic chime
		var val = (sin(2.0 * PI * freq * t) * 0.5 + sin(2.0 * PI * (freq * 1.5) * t) * 0.3 + sin(2.0 * PI * (freq * 2.0) * t) * 0.2) * envelope * amp
		var sample_16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = bytes
	return s

func _create_thud_tone(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = exp(-t * 40.0)
		var val = sin(2.0 * PI * freq * t) * envelope * amp
		var sample_16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)
		
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = bytes
	return s

func _create_click_tone(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = exp(-t * 80.0)
		var val = sin(2.0 * PI * freq * t) * envelope * amp
		var sample_16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)
		
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = bytes
	return s

func _create_chime_tone(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = exp(-t * 10.0)
		var val = (sin(2.0 * PI * freq * t) + 0.5 * sin(2.0 * PI * freq * 2.0 * t)) * envelope * (amp * 0.6)
		var sample_16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)
		
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = bytes
	return s

func _create_fanfare_tone() -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var duration = 0.55
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)
	
	var notes = [523.25, 659.25, 783.99, 1046.50]
	var note_dur = duration / float(notes.size())
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var note_idx = int(t / note_dur)
		note_idx = clamp(note_idx, 0, notes.size() - 1)
		var freq = notes[note_idx]
		var local_t = fmod(t, note_dur)
		var env = exp(-local_t * 6.0)
		var val = sin(2.0 * PI * freq * t) * env * 0.7
		var sample_16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)
		
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = bytes
	return s

func _create_coin_rattle_tone() -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var duration = 0.22
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var v1 = sin(2.0 * PI * 1480.0 * t) * exp(-max(0.0, t) * 45.0)
		var v2 = sin(2.0 * PI * 1850.0 * t) * exp(-max(0.0, t - 0.07) * 45.0) if t >= 0.07 else 0.0
		var v3 = sin(2.0 * PI * 2220.0 * t) * exp(-max(0.0, t - 0.14) * 45.0) if t >= 0.14 else 0.0
		var total_v = (v1 * 0.45 + v2 * 0.5 + v3 * 0.55) * 0.75
		var sample_16 = int(clamp(total_v * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)
		
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = bytes
	return s

func _create_peg_tick_tone() -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var duration = 0.03
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 90.0)
		var freq = 1600.0 * (1.0 - t / duration * 0.6)
		var val = sin(2.0 * PI * freq * t) * env * 0.65
		var sample_16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)
		
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = bytes
	return s

func _create_ambient_music_loop() -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var duration = 8.0
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)

	var chords = [
		[261.63, 329.63, 392.00, 493.88],
		[220.00, 261.63, 329.63, 392.00],
		[174.61, 220.00, 261.63, 329.63],
		[196.00, 246.94, 293.66, 329.63]
	]
	var chord_dur = 2.0

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var c_idx = mini(int(t / chord_dur), chords.size() - 1)
		var local_t = fmod(t, chord_dur)
		var env = sin(PI * (local_t / chord_dur))
		env = env * env * 0.35

		var chord = chords[c_idx]
		var val = 0.0
		for f in chord:
			val += sin(2.0 * PI * f * t) * 0.25
		val *= env
		var sample_16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)

	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = num_samples
	s.data = bytes
	return s

func _create_smash_tone() -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var duration = 0.22
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 22.0)
		var bass = sin(2.0 * PI * (120.0 - 60.0 * (t / duration)) * t) * 0.6
		var noise = (randf() * 2.0 - 1.0) * 0.4
		var val = (bass + noise) * env * 0.9
		var sample_16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = bytes
	return s

func _create_shrink_tone() -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var duration = 0.16
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 18.0)
		var freq = 1200.0 * (1.0 - (t / duration) * 0.7)
		var val = sin(2.0 * PI * freq * t) * env * 0.8
		var sample_16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = bytes
	return s

func _create_crane_lift_tone() -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var duration = 0.15
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = sin(PI * (t / duration))
		var freq = 320.0 + 330.0 * (t / duration)
		var val = sin(2.0 * PI * freq * t) * env * 0.7
		var sample_16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = bytes
	return s

func _create_crane_drop_tone() -> AudioStreamWAV:
	var sample_rate = SAMPLE_RATE
	var duration = 0.12
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize((num_samples + PADDING_SAMPLES) * 2)
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 35.0)
		var val = sin(2.0 * PI * 180.0 * t) * env * 0.85
		var sample_16 = int(clamp(val * 32767.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_16)
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = bytes
	return s
