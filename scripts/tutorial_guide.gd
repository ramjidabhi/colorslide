extends Control

## TutorialGuide.gd - Step-by-Step Interactive Tutorial & Universal Hint Engine
## Provides animated hands, glowing block highlights, step counters,
## and directions for all 50 levels of World 1.

@onready var banner: PanelContainer = $Banner
@onready var step_label: Label = $Banner/Margin/VBox/Header/Badge/BadgeMargin/StepLabel
@onready var prev_btn: Button = $Banner/Margin/VBox/Header/PrevBtn
@onready var next_btn: Button = $Banner/Margin/VBox/Header/NextBtn
@onready var close_btn: Button = $Banner/Margin/VBox/Header/CloseBtn
@onready var instruction_label: Label = $Banner/Margin/VBox/InstructionLabel
@onready var highlight_box: Panel = $HighlightBox
@onready var hand_cursor: Control = $HandCursor
@onready var hand_label: Label = $HandCursor/HandLabel

var current_steps: Array = []
var step_index: int = 0
var is_tutorial_mode: bool = false
var hand_tween: Tween
var highlight_tween: Tween
var active_target_block: Control = null
var reset_hint_btn: Button = null

func _ready() -> void:
	visible = false
	if prev_btn:
		prev_btn.pressed.connect(_on_prev_pressed)
	if next_btn:
		next_btn.pressed.connect(_on_next_pressed)
	if close_btn:
		close_btn.pressed.connect(close_hint)
	_create_reset_hint_button()

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.level_loaded.connect(_on_level_loaded)
		gm.level_completed.connect(_cleanup.unbind(6))

func _create_reset_hint_button() -> void:
	var header = get_node_or_null("Banner/Margin/VBox/Header")
	if not header:
		return
	reset_hint_btn = Button.new()
	reset_hint_btn.name = "ResetHintBtn"
	reset_hint_btn.text = "↺ RESET"
	reset_hint_btn.custom_minimum_size = Vector2(124, 46)
	reset_hint_btn.add_theme_font_size_override("font_size", 22)
	reset_hint_btn.visible = false
	reset_hint_btn.pressed.connect(_on_reset_and_hint_pressed)
	header.add_child(reset_hint_btn)
	if close_btn:
		header.move_child(reset_hint_btn, close_btn.get_index())

func _on_reset_and_hint_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		var was_unlocked = gm.hint_unlocked_for_current
		gm.restart_current_level()
		gm.hint_unlocked_for_current = was_unlocked
		await get_tree().process_frame
		open_hint(0)

func _on_level_loaded(l_data: Dictionary) -> void:
	_cleanup()
	var l_id = l_data.get("level_id", 1)
	
	# Load hint steps (fallback to tutorial_steps or solution_steps)
	current_steps = l_data.get("hint_steps", [])
	if current_steps.is_empty():
		current_steps = l_data.get("tutorial_steps", [])
	
	step_index = 0
	
	# Auto-start interactive tutorial for Level 1
	if l_id == 1 and not current_steps.is_empty():
		is_tutorial_mode = true
		await get_tree().process_frame
		await get_tree().create_timer(0.15).timeout
		open_hint(0)
	else:
		is_tutorial_mode = false

func toggle_hint() -> void:
	if visible:
		close_hint()
	else:
		open_hint()

func open_hint(force_step: int = -1) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		var l_data = gm.get_current_level_data()
		current_steps = l_data.get("hint_steps", [])
		if current_steps.is_empty():
			current_steps = l_data.get("tutorial_steps", [])

	if current_steps.is_empty():
		return

	var board = _get_board()
	if force_step >= 0:
		step_index = clamp(force_step, 0, current_steps.size() - 1)
	else:
		step_index = _detect_current_step()
		# If board diverged from precomputed optimal path, compute live BFS solution from current board!
		if board and not _is_step_executable(board, current_steps[step_index]):
			var live_steps = _compute_live_bfs_steps(board)
			if not live_steps.is_empty():
				current_steps = live_steps
				step_index = 0
			else:
				# Show helpful divergence notice instead of pointing at a blocked step
				visible = true
				step_label.text = "💡 HINT"
				instruction_label.text = "Path blocked! Tap ↺ RESET to return to clean start."
				if reset_hint_btn: reset_hint_btn.visible = true
				if prev_btn: prev_btn.disabled = true
				if next_btn: next_btn.disabled = true
				highlight_box.visible = false
				hand_cursor.visible = false
				return

	if reset_hint_btn: reset_hint_btn.visible = false
	visible = true
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	
	_show_current_step()

func close_hint() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	_cleanup()

func _detect_current_step() -> int:
	var board = _get_board()
	if not board or board.blocks.is_empty():
		return 0

	# Find the first step in sequence that hasn't reached its target coordinate
	for i in range(current_steps.size()):
		var step = current_steps[i]
		var bid = step.get("block_id", "")
		var target_x = step.get("to_x", -1)
		var target_y = step.get("to_y", -1)

		var found_block = null
		for b in board.blocks:
			if is_instance_valid(b) and b.block_id == bid:
				found_block = b
				break

		if found_block:
			if target_x >= 0 and target_y >= 0:
				if found_block.grid_x != target_x or found_block.grid_y != target_y:
					return i
			else:
				return i

	return 0

func _show_current_step() -> void:
	if step_index < 0 or step_index >= current_steps.size():
		_cleanup()
		return

	var step_info = current_steps[step_index]
	var total = current_steps.size()
	var current_num = step_index + 1

	if is_tutorial_mode:
		step_label.text = "🎓 TUTORIAL • STEP %d OF %d" % [current_num, total]
	else:
		step_label.text = "💡 HINT • STEP %d OF %d" % [current_num, total]

	instruction_label.text = step_info.get("instruction", "")

	if prev_btn:
		prev_btn.disabled = (step_index == 0)
	if next_btn:
		next_btn.disabled = (step_index >= total - 1)

	# Banner bounce-in
	banner.scale = Vector2(0.9, 0.9)
	var bt = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bt.tween_property(banner, "scale", Vector2.ONE, 0.22)

	_setup_visual_guide(step_info)

func _setup_visual_guide(step_info: Dictionary) -> void:
	_disconnect_active_block()

	var block_id = step_info.get("block_id", "red")
	var dir = step_info.get("target_dir", "right")
	var dist = step_info.get("distance", 1)

	var board = _get_board()
	if not board:
		return

	for b in board.blocks:
		if is_instance_valid(b) and b.block_id == block_id:
			active_target_block = b
			break

	if not active_target_block:
		return

	# Calculate context-aware dynamic move from block's CURRENT position
	var target_x = step_info.get("to_x", -1)
	var target_y = step_info.get("to_y", -1)
	
	if target_x >= 0 and target_y >= 0:
		var cur_x = active_target_block.grid_x
		var cur_y = active_target_block.grid_y
		var dx = target_x - cur_x
		var dy = target_y - cur_y
		
		if active_target_block.direction == "horizontal":
			if dx > 0:
				dir = "right"
				dist = dx
			elif dx < 0:
				dir = "left"
				dist = -dx
			elif dx == 0:
				# Block is already at target position! Advance to next step!
				step_index += 1
				if step_index < current_steps.size():
					_show_current_step()
					return
		else:
			if dy > 0:
				dir = "down"
				dist = dy
			elif dy < 0:
				dir = "up"
				dist = -dy
			elif dy == 0:
				# Block is already at target position! Advance to next step!
				step_index += 1
				if step_index < current_steps.size():
					_show_current_step()
					return
					
	# Dynamically update the instruction text to match the real required slide
	var arrow_sym = "👉"
	var dir_name = "RIGHT"
	if dir == "left":
		arrow_sym = "👈"
		dir_name = "LEFT"
	elif dir == "up":
		arrow_sym = "👆"
		dir_name = "UP"
	elif dir == "down":
		arrow_sym = "👇"
		dir_name = "DOWN"
		
	var b_name = str(step_info.get("color_name", ""))
	if active_target_block.is_target:
		b_name = "Red Target Block"
	elif b_name == "":
		b_name = active_target_block.block_id.capitalize() + " Block"
		
	var cell_word = "cell" if dist == 1 else "cells"
	if active_target_block.is_frozen:
		instruction_label.text = "❄️ %s is FROZEN! Slide an adjacent block next to it to melt ice!" % b_name
	else:
		instruction_label.text = "Slide %s %d %s %s %s" % [b_name, dist, cell_word, arrow_sym, dir_name]

	# Connect block events
	if not active_target_block.moved.is_connected(_on_target_block_moved):
		active_target_block.moved.connect(_on_target_block_moved)
	if not active_target_block.drag_started.is_connected(_on_drag_started):
		active_target_block.drag_started.connect(_on_drag_started)
	if not active_target_block.drag_ended.is_connected(_on_drag_ended):
		active_target_block.drag_ended.connect(_on_drag_ended)

	# 1. Position and pulse Highlight Box
	highlight_box.visible = true
	highlight_box.global_position = active_target_block.global_position
	highlight_box.size = active_target_block.size

	if highlight_tween and highlight_tween.is_valid():
		highlight_tween.kill()
	highlight_box.modulate.a = 0.5
	highlight_tween = create_tween().set_loops()
	highlight_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	highlight_tween.tween_property(highlight_box, "modulate:a", 1.0, 0.5)
	highlight_tween.tween_property(highlight_box, "modulate:a", 0.4, 0.5)

	# 2. Position and animate Hand Cursor
	var block_center = active_target_block.global_position + active_target_block.size * 0.5
	hand_cursor.global_position = block_center

	var offset_dist = clamp(dist * 80.0, 70.0, 140.0)
	var offset_vec = Vector2.ZERO

	if active_target_block.is_frozen:
		hand_label.text = "❄️"
		offset_vec = Vector2(0, -28.0)
	elif dir == "right":
		hand_label.text = "👉"
		offset_vec = Vector2(offset_dist, 0)
	elif dir == "down":
		hand_label.text = "👇"
		offset_vec = Vector2(0, offset_dist)
	elif dir == "up":
		hand_label.text = "👆"
		offset_vec = Vector2(0, -offset_dist)
	elif dir == "left":
		hand_label.text = "👈"
		offset_vec = Vector2(-offset_dist, 0)

	hand_cursor.visible = true
	if hand_tween and hand_tween.is_valid():
		hand_tween.kill()

	hand_tween = create_tween().set_loops()
	hand_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hand_tween.tween_property(hand_cursor, "global_position", block_center + offset_vec, 0.65)
	hand_tween.tween_property(hand_cursor, "global_position", block_center, 0.45)

func _on_drag_started(_b: Control) -> void:
	hand_cursor.visible = false
	highlight_box.visible = false

func _on_drag_ended(_b: Control) -> void:
	if visible and step_index < current_steps.size():
		if active_target_block and is_instance_valid(active_target_block):
			highlight_box.global_position = active_target_block.global_position
			highlight_box.size = active_target_block.size
			highlight_box.visible = true
			hand_cursor.global_position = active_target_block.global_position + active_target_block.size * 0.5
			hand_cursor.visible = true

func _on_target_block_moved(b: Control, _from: Vector2i, _to: Vector2i) -> void:
	if step_index >= current_steps.size():
		return

	var expected_step = current_steps[step_index]
	var expected_id = expected_step.get("block_id", "")
	var target_x = expected_step.get("to_x", -1)
	var target_y = expected_step.get("to_y", -1)

	if b.block_id == expected_id:
		# Check if destination or progress matched
		var reached = false
		if target_x >= 0 and target_y >= 0:
			reached = (b.grid_x == target_x and b.grid_y == target_y)
		else:
			reached = true

		if reached:
			var sm = get_node_or_null("/root/SoundManager")
			if sm:
				sm.play_slide(1.25)
			
			step_index += 1
			if step_index < current_steps.size():
				await get_tree().create_timer(0.2).timeout
				_show_current_step()
			else:
				# Completed all steps for this puzzle
				_cleanup()
		else:
			# Player overshot or moved in wrong direction: recalibrate hint from new position!
			await get_tree().create_timer(0.15).timeout
			_show_current_step()

func _on_prev_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	if step_index > 0:
		step_index -= 1
		_show_current_step()

func _on_next_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()
	if step_index < current_steps.size() - 1:
		step_index += 1
		_show_current_step()

func _disconnect_active_block() -> void:
	if active_target_block and is_instance_valid(active_target_block):
		if active_target_block.moved.is_connected(_on_target_block_moved):
			active_target_block.moved.disconnect(_on_target_block_moved)
		if active_target_block.drag_started.is_connected(_on_drag_started):
			active_target_block.drag_started.disconnect(_on_drag_started)
		if active_target_block.drag_ended.is_connected(_on_drag_ended):
			active_target_block.drag_ended.disconnect(_on_drag_ended)
	active_target_block = null

func _cleanup() -> void:
	visible = false
	_disconnect_active_block()
	if hand_tween and hand_tween.is_valid():
		hand_tween.kill()
	if highlight_tween and highlight_tween.is_valid():
		highlight_tween.kill()
	highlight_box.visible = false
	hand_cursor.visible = false

func _get_board() -> Control:
	return get_tree().root.find_child("GameBoard", true, false)

func _is_step_executable(board: Control, step: Dictionary) -> bool:
	var bid = step.get("block_id", "")
	var tx = int(step.get("to_x", -1))
	var ty = int(step.get("to_y", -1))
	if tx < 0 or ty < 0:
		return false
	var target_b = null
	for b in board.blocks:
		if is_instance_valid(b) and b.block_id == bid:
			target_b = b
			break
	if not target_b or target_b.is_frozen:
		return false
	board._calculate_drag_bounds(target_b)
	var dest_coord = (tx * board.CELL_SIZE + board.PADDING) if target_b.direction == "horizontal" else (ty * board.CELL_SIZE + board.PADDING)
	return dest_coord >= target_b.min_drag_coord - 0.5 and dest_coord <= target_b.max_drag_coord + 0.5

func _compute_live_bfs_steps(board: Control) -> Array:
	var n = board.blocks.size()
	if n == 0:
		return []
	var meta: Array = []
	var init_coords: PackedInt32Array = PackedInt32Array()
	var init_frozen: PackedByteArray = PackedByteArray()
	init_coords.resize(n)
	init_frozen.resize(n)
	var target_idx = -1

	for i in range(n):
		var b = board.blocks[i]
		if not is_instance_valid(b):
			return []
		var is_h = (b.direction == "horizontal")
		meta.append({
			"id": b.block_id,
			"is_h": is_h,
			"len": b.length,
			"fixed": b.grid_y if is_h else b.grid_x,
			"is_target": b.is_target
		})
		init_coords[i] = b.grid_x if is_h else b.grid_y
		init_frozen[i] = 1 if b.is_frozen else 0
		if b.is_target:
			target_idx = i
	if target_idx == -1:
		return []

	var switches: Array = board.switches
	var lasers: Array = board.lasers

	var make_key = func(coords: PackedInt32Array, frozen: PackedByteArray) -> String:
		return str(coords) + "|" + str(frozen)

	var init_key = make_key.call(init_coords, init_frozen)
	var visited: Dictionary = { init_key: true }
	var queue: Array = [{ "c": init_coords, "f": init_frozen, "parent": -1, "move": {} }]
	var head = 0
	var max_states = 10000

	while head < queue.size() and queue.size() < max_states:
		var node = queue[head]
		var coords: PackedInt32Array = node["c"]
		var frozen: PackedByteArray = node["f"]

		# Check win
		if coords[target_idx] == 6 - meta[target_idx]["len"]:
			var rev_steps: Array = []
			var cur = head
			while cur > 0:
				rev_steps.append(queue[cur]["move"])
				cur = queue[cur]["parent"]
			rev_steps.reverse()
			return rev_steps

		# Build occupancy grid (36 ints, -1 = empty)
		var occ: PackedInt32Array = PackedInt32Array()
		occ.resize(36)
		occ.fill(-1)
		for i in range(n):
			var m = meta[i]
			var pos = coords[i]
			if m["is_h"]:
				for k in range(m["len"]):
					occ[m["fixed"] * 6 + pos + k] = i
			else:
				for k in range(m["len"]):
					occ[(pos + k) * 6 + m["fixed"]] = i

		for i in range(n):
			if frozen[i] == 1:
				continue
			var m = meta[i]
			var cur_pos = coords[i]
			var fixed = m["fixed"]
			var blen = m["len"]

			# Determine active lasers while excluding moving block i
			var laser_blocked: PackedByteArray = PackedByteArray()
			laser_blocked.resize(36)
			for laser in lasers:
				var sw_id = laser.get("switch_id", "")
				var active = true
				for sw in switches:
					if sw.get("id") == sw_id or sw_id == "":
						var occ_id = occ[int(sw.get("y", 0)) * 6 + int(sw.get("x", 0))]
						if occ_id != -1 and occ_id != i:
							active = false
							break
				if active:
					var lx = int(laser.get("x", 4))
					var ly = int(laser.get("y", 2))
					if lx >= 0 and lx < 6 and ly >= 0 and ly < 6:
						laser_blocked[ly * 6 + lx] = 1

			# Try negative and positive slides
			for dir_sign in [-1, 1]:
				var step_pos = cur_pos + dir_sign
				while step_pos >= 0 and step_pos + blen <= 6:
					var check_cell = step_pos if dir_sign == -1 else (step_pos + blen - 1)
					var cell_idx = (fixed * 6 + check_cell) if m["is_h"] else (check_cell * 6 + fixed)
					if occ[cell_idx] != -1 or laser_blocked[cell_idx] == 1:
						break

					var next_c = coords.duplicate()
					next_c[i] = step_pos
					var next_f = frozen.duplicate()

					# Update ice melting if any frozen block exists
					var min_x = mini(cur_pos, step_pos) if m["is_h"] else fixed
					var max_x = (maxi(cur_pos, step_pos) + blen) if m["is_h"] else (fixed + 1)
					var min_y = fixed if m["is_h"] else mini(cur_pos, step_pos)
					var max_y = (fixed + 1) if m["is_h"] else (maxi(cur_pos, step_pos) + blen)
					for j in range(n):
						if next_f[j] == 1:
							var jm = meta[j]
							var jpos = next_c[j]
							var jfixed = jm["fixed"]
							var melted = false
							for k in range(jm["len"]):
								var fx = (jpos + k) if jm["is_h"] else jfixed
								var fy = jfixed if jm["is_h"] else (jpos + k)
								for sx in range(min_x, max_x):
									for sy in range(min_y, max_y):
										if abs(sx - fx) + abs(sy - fy) == 1:
											melted = true
											break
									if melted: break
								if melted: break
							if melted:
								next_f[j] = 0

					var nkey = make_key.call(next_c, next_f)
					if not visited.has(nkey):
						visited[nkey] = true
						var to_x = step_pos if m["is_h"] else fixed
						var to_y = fixed if m["is_h"] else step_pos
						var move_dict = {
							"block_id": m["id"],
							"is_target": m["is_target"],
							"to_x": to_x,
							"to_y": to_y,
							"target_dir": ("right" if dir_sign > 0 else "left") if m["is_h"] else ("down" if dir_sign > 0 else "up"),
							"distance": abs(step_pos - cur_pos)
						}
						queue.append({ "c": next_c, "f": next_f, "parent": head, "move": move_dict })

					step_pos += dir_sign
		head += 1

	return []
