extends Control

## GameBoard.gd - 6x6 Puzzle Board Controller
## Manages block lifecycle, collision grid matrix, smooth drag bounds,
## multi-world visual themes, ice-melting mechanics, floor switches & laser barriers.

signal puzzle_won()
signal puzzle_solved_immediately()
signal undo_state_changed(has_undo: bool)
signal booster_action_completed(type: String, success: bool, message: String)
signal exit_path_cleared()

const BOARD_SIZE: int = 6
const CELL_SIZE: float = 140.0
const PADDING: float = 6.0
const CORNER_RADIUS: float = 28.0

const BLOCK_SCENE: PackedScene = preload("res://scenes/Block.tscn")

var blocks: Array[Control] = []
var grid: Array = []  # 6x6 2D matrix
var is_locked: bool = false
var blitz_mode: bool = false
var target_block_node: Control = null

var active_booster_mode: String = ""
var crane_selected_block: Control = null
var is_exit_path_clear: bool = false

var world_id: int = 1
var switches: Array = []
var lasers: Array = []
var move_history: Array = []
var _prev_laser_states: Dictionary = {}
var _exit_pulse_t: float = 0.0

@onready var blocks_container: Control = $BlocksContainer
@onready var exit_gate: Control = $ExitGate
@onready var win_particles: CPUParticles2D = $WinParticles

var board_style: StyleBoxFlat
var cell_style: StyleBoxFlat

func _ready() -> void:
	custom_minimum_size = Vector2(BOARD_SIZE * CELL_SIZE, BOARD_SIZE * CELL_SIZE)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_PASS
	_init_styles()
	_init_grid()
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.level_loaded.connect(load_level)
		if not gm.all_levels.is_empty():
			load_level(gm.get_current_level_data())

func _init_styles() -> void:
	board_style = StyleBoxFlat.new()
	board_style.bg_color = Color("#1A1E29")
	board_style.set_corner_radius_all(int(CORNER_RADIUS))
	board_style.border_width_left = 3
	board_style.border_width_top = 3
	board_style.border_width_right = 3
	board_style.border_width_bottom = 3
	board_style.border_color = Color("#2D3548")
	board_style.shadow_color = Color(0, 0, 0, 0.45)
	board_style.shadow_size = 20
	board_style.shadow_offset = Vector2(0, 10)
	board_style.anti_aliasing = true

	cell_style = StyleBoxFlat.new()
	cell_style.bg_color = Color("#131620")
	cell_style.set_corner_radius_all(18)
	cell_style.border_width_left = 2
	cell_style.border_width_top = 2
	cell_style.border_width_right = 2
	cell_style.border_width_bottom = 2
	cell_style.border_color = Color("#1F2433")
	cell_style.anti_aliasing = true

func _apply_world_theme(w_id: int) -> void:
	world_id = w_id
	if w_id == 2:
		# World 2: Cyberpunk Midnight
		board_style.bg_color = Color("#0A0E1A")
		board_style.border_color = Color("#00D2D3")
		cell_style.bg_color = Color("#0F172A")
		cell_style.border_color = Color(0.0, 0.82, 0.82, 0.35)
	elif w_id == 3:
		# World 3: Frost Cavern
		board_style.bg_color = Color("#0C1826")
		board_style.border_color = Color("#48DBFB")
		cell_style.bg_color = Color("#102238")
		cell_style.border_color = Color(0.28, 0.86, 0.98, 0.4)
	elif w_id == 4:
		# World 4: Laser Facility
		board_style.bg_color = Color("#14141E")
		board_style.border_color = Color("#FF4757")
		cell_style.bg_color = Color("#1C1C28")
		cell_style.border_color = Color(1.0, 0.28, 0.34, 0.4)
	else:
		# World 1: Beginner Escape
		board_style.bg_color = Color("#1A1E29")
		board_style.border_color = Color("#2D3548")
		cell_style.bg_color = Color("#131620")
		cell_style.border_color = Color("#1F2433")

func _init_grid() -> void:
	grid.clear()
	for y in range(BOARD_SIZE):
		var row: Array = []
		for x in range(BOARD_SIZE):
			row.append(null)
		grid.append(row)

func load_level(l_data: Dictionary) -> void:
	cancel_booster_mode()
	is_locked = false
	move_history.clear()
	undo_state_changed.emit(false)
	_clear_board()
	_init_grid()
	
	var w_id = l_data.get("world_id", 1)
	_apply_world_theme(w_id)
	
	switches = l_data.get("switches", [])
	lasers = l_data.get("lasers", [])
	_prev_laser_states.clear()
	
	var blocks_data = l_data.get("blocks", [])
	for b_info in blocks_data:
		var b_instance = BLOCK_SCENE.instantiate()
		blocks_container.add_child(b_instance)
		b_instance.setup(b_info)
		
		b_instance.drag_started.connect(_on_block_drag_started)
		b_instance.drag_ended.connect(_on_block_drag_ended)
		b_instance.moved.connect(_on_block_moved)
		
		blocks.append(b_instance)
		if b_instance.is_target:
			target_block_node = b_instance
			
	_rebuild_grid_occupancy()
	_snapshot_laser_states()
	queue_redraw()

func _process(delta: float) -> void:
	if not is_locked:
		_exit_pulse_t = fmod(_exit_pulse_t + delta * 3.5, TAU)
		queue_redraw()

func _snapshot_laser_states() -> void:
	_prev_laser_states.clear()
	for laser in lasers:
		var lid = str(laser.get("id", "laser"))
		_prev_laser_states[lid] = _is_laser_active(laser)

func _check_laser_state_feedback() -> void:
	if lasers.is_empty():
		return
	var sm = get_node_or_null("/root/SoundManager")
	for laser in lasers:
		var lid = str(laser.get("id", "laser"))
		var was_active = _prev_laser_states.get(lid, true)
		var now_active = _is_laser_active(laser)
		if was_active != now_active and sm:
			if not now_active:
				sm.play_slide(1.65)
			else:
				sm.play_bump()
		_prev_laser_states[lid] = now_active

func _clear_board() -> void:
	for b in blocks:
		if is_instance_valid(b):
			b.queue_free()
	blocks.clear()
	target_block_node = null

func _rebuild_grid_occupancy() -> void:
	_init_grid()
	for b in blocks:
		if is_instance_valid(b):
			for i in range(b.length):
				var cx = b.grid_x + (i if b.direction == "horizontal" else 0)
				var cy = b.grid_y + (i if b.direction == "vertical" else 0)
				if cx >= 0 and cx < BOARD_SIZE and cy >= 0 and cy < BOARD_SIZE:
					grid[cy][cx] = b
	_check_exit_path()

func _check_exit_path() -> void:
	if target_block_node == null or not is_instance_valid(target_block_node):
		is_exit_path_clear = false
		queue_redraw()
		return
	var clear = true
	var start_x = target_block_node.grid_x + target_block_node.length
	for x in range(start_x, BOARD_SIZE):
		if grid[2][x] != null and grid[2][x] != target_block_node:
			clear = false
			break
		for laser in lasers:
			if _is_laser_active(laser):
				if int(laser.get("x", 4)) == x and int(laser.get("y", 2)) == 2:
					clear = false
					break
		if not clear:
			break
	if clear != is_exit_path_clear:
		is_exit_path_clear = clear
		queue_redraw()
		if is_exit_path_clear and not is_locked:
			var sm = get_node_or_null("/root/SoundManager")
			if sm:
				sm.play_star(1.4)
				sm.trigger_haptic(15)
			exit_path_cleared.emit()

func _on_block_drag_started(b: Control) -> void:
	if is_locked:
		return
	if active_booster_mode != "":
		b.is_dragging = false
		b.active_touch_index = -1
		handle_booster_interaction(b)
		return
	_calculate_drag_bounds(b)

func set_booster_mode(mode: String) -> void:
	cancel_booster_mode()
	active_booster_mode = mode
	queue_redraw()

func cancel_booster_mode() -> void:
	if crane_selected_block != null and is_instance_valid(crane_selected_block):
		crane_selected_block.scale = Vector2.ONE
		crane_selected_block = null
	active_booster_mode = ""
	queue_redraw()

func handle_booster_interaction(b: Control) -> void:
	if not is_instance_valid(b):
		return
	var sm = get_node_or_null("/root/SoundManager")
	
	match active_booster_mode:
		"sledgehammer":
			if b.is_target:
				if sm: sm.play_bump()
				booster_action_completed.emit("sledgehammer", false, "Cannot smash the red escape block!")
				return
			# Successful Smash!
			b.is_dragging = false
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE
			blocks.erase(b)
			if sm: sm.play_booster_smash()
			
			var b_data = {
				"id": b.block_id,
				"x": b.grid_x,
				"y": b.grid_y,
				"length": b.length,
				"direction": b.direction,
				"color": b.block_color.to_html(),
				"is_target": b.is_target,
				"is_frozen": b.is_frozen
			}
			move_history.append({
				"is_booster": true,
				"booster_type": "sledgehammer",
				"block_dict": b_data
			})
			
			# Shatter animation
			var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.tween_property(b, "scale", Vector2(1.25, 1.25), 0.08)
			tw.tween_property(b, "scale", Vector2.ZERO, 0.16)
			tw.tween_callback(b.queue_free)
			
			_rebuild_grid_occupancy()
			_check_laser_state_feedback()
			active_booster_mode = ""
			booster_action_completed.emit("sledgehammer", true, "💥 Block Smashed!")
			undo_state_changed.emit(not move_history.is_empty())
			
		"shrink":
			if b.is_target:
				if sm: sm.play_bump()
				booster_action_completed.emit("shrink", false, "Cannot shrink the red escape block!")
				return
			if b.length <= 1:
				if sm: sm.play_bump()
				booster_action_completed.emit("shrink", false, "Block is already at minimum size (1 cell)!")
				return
			# Successful Shrink!
			b.is_dragging = false
			move_history.append({
				"is_booster": true,
				"booster_type": "shrink",
				"block": b
			})
			b.length -= 1
			b.custom_minimum_size = b.get_block_size()
			b.size = b.custom_minimum_size
			b.update_visual_position(false)
			b.queue_redraw()
			if sm: sm.play_booster_shrink()
			
			# Pulse squeeze animation
			var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(b, "scale", Vector2(1.15, 0.85), 0.08)
			tw.tween_property(b, "scale", Vector2.ONE, 0.14)
			
			_rebuild_grid_occupancy()
			_check_laser_state_feedback()
			active_booster_mode = ""
			booster_action_completed.emit("shrink", true, "✂️ Block Shrunk to %d Cells!" % b.length)
			undo_state_changed.emit(not move_history.is_empty())
			
		"crane":
			if crane_selected_block == null:
				if b.is_target:
					if sm: sm.play_bump()
					booster_action_completed.emit("crane", false, "Cannot relocate the red escape block!")
					return
				# Step 1: Select & Lift block
				crane_selected_block = b
				b.is_dragging = false
				if sm: sm.play_booster_crane_lift()
				var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(b, "scale", Vector2(1.08, 1.08), 0.15)
				booster_action_completed.emit("crane", false, "🧲 Tap an empty space on the board to drop!")
			elif crane_selected_block == b:
				# Tapped again -> deselect
				b.scale = Vector2.ONE
				crane_selected_block = null
				if sm: sm.play_tap()
				booster_action_completed.emit("crane", false, "Selection cancelled. Tap any block to lift.")

func _attempt_crane_drop(target_gx: int, target_gy: int) -> void:
	if crane_selected_block == null or not is_instance_valid(crane_selected_block):
		return
	var b = crane_selected_block
	var sm = get_node_or_null("/root/SoundManager")
	
	if target_gx < 0 or target_gx >= BOARD_SIZE or target_gy < 0 or target_gy >= BOARD_SIZE:
		return
		
	# Check if block fits at (target_gx, target_gy)
	var fits = true
	for i in range(b.length):
		var cx = target_gx + (i if b.direction == "horizontal" else 0)
		var cy = target_gy + (i if b.direction == "vertical" else 0)
		if cx < 0 or cx >= BOARD_SIZE or cy < 0 or cy >= BOARD_SIZE:
			fits = false
			break
		# Check laser blockage
		for laser in lasers:
			if _is_laser_active(laser, b):
				if int(laser.get("x", 4)) == cx and int(laser.get("y", 2)) == cy:
					fits = false
					break
		if not fits:
			break
		# Check grid occupancy (must be empty or occupied by b itself)
		if grid[cy][cx] != null and grid[cy][cx] != b:
			fits = false
			break
			
	if not fits:
		if sm: sm.play_bump()
		booster_action_completed.emit("crane", false, "❌ Space occupied or out of bounds! Tap an empty spot.")
		return
		
	# Successfully relocate block!
	move_history.append({
		"is_booster": true,
		"booster_type": "crane",
		"block": b,
		"from_x": b.grid_x,
		"from_y": b.grid_y
	})
	b.grid_x = target_gx
	b.grid_y = target_gy
	b.update_visual_position(true)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", Vector2.ONE, 0.15)
	
	if sm: sm.play_booster_crane_drop()
	_rebuild_grid_occupancy()
	_check_laser_state_feedback()
	
	crane_selected_block = null
	active_booster_mode = ""
	booster_action_completed.emit("crane", true, "🧲 Block Relocated Successfully!")
	undo_state_changed.emit(not move_history.is_empty())

func _gui_input(event: InputEvent) -> void:
	if active_booster_mode == "crane" and crane_selected_block != null:
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			var local_pos = event.position
			var gx = int(local_pos.x / CELL_SIZE)
			var gy = int(local_pos.y / CELL_SIZE)
			_attempt_crane_drop(gx, gy)

func _calculate_drag_bounds(b: Control) -> void:
	# Temporarily clear this block from grid
	for i in range(b.length):
		var cx = b.grid_x + (i if b.direction == "horizontal" else 0)
		var cy = b.grid_y + (i if b.direction == "vertical" else 0)
		grid[cy][cx] = null
		
	# Check for active lasers and mark their cells as impassable
	# Pass `b` as excluded because `b` may currently be moving off a switch
	for laser in lasers:
		if _is_laser_active(laser, b):
			var lx = laser.get("x", 4)
			var ly = laser.get("y", 2)
			if lx >= 0 and lx < BOARD_SIZE and ly >= 0 and ly < BOARD_SIZE:
				if grid[ly][lx] == null:
					grid[ly][lx] = self # Marker for laser obstacle

	if b.direction == "horizontal":
		# Scan Left
		var min_x = b.grid_x
		for x in range(b.grid_x - 1, -1, -1):
			if grid[b.grid_y][x] != null:
				break
			min_x = x
			
		# Scan Right
		var max_x = b.grid_x
		for x in range(b.grid_x + b.length, BOARD_SIZE):
			if grid[b.grid_y][x] != null:
				break
			max_x = x - b.length + 1
			
		b.min_drag_coord = min_x * CELL_SIZE + PADDING
		b.max_drag_coord = max_x * CELL_SIZE + PADDING
	else:
		# Scan Up
		var min_y = b.grid_y
		for y in range(b.grid_y - 1, -1, -1):
			if grid[y][b.grid_x] != null:
				break
			min_y = y
			
		# Scan Down
		var max_y = b.grid_y
		for y in range(b.grid_y + b.length, BOARD_SIZE):
			if grid[y][b.grid_x] != null:
				break
			max_y = y - b.length + 1
			
		b.min_drag_coord = min_y * CELL_SIZE + PADDING
		b.max_drag_coord = max_y * CELL_SIZE + PADDING
		
	# Rebuild clean grid
	_rebuild_grid_occupancy()

func _on_block_drag_ended(b: Control) -> void:
	b.snap_to_nearest_cell()
	if not is_locked and b.is_target and b.grid_x == (BOARD_SIZE - b.length):
		_trigger_escape_win_sequence(b)

func _on_block_moved(b: Control, from_cell: Vector2i, to_cell: Vector2i) -> void:
	_rebuild_grid_occupancy()
	var thawed = _check_ice_melting(b, from_cell, to_cell)
	_check_laser_state_feedback()
	move_history.append({"block": b, "from": from_cell, "to": to_cell, "thawed": thawed})
	undo_state_changed.emit(true)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.register_move()
	
	# Check Win: target reaches right exit (grid_x == 4 for length 2)
	if b.is_target and b.grid_x == (BOARD_SIZE - b.length):
		_trigger_escape_win_sequence(b)
		
	queue_redraw()

func undo_last_move() -> bool:
	if is_locked or move_history.is_empty():
		return false
	var record = move_history.pop_back()
	
	# Check if this was a Booster action (Area 4: Safeguard & Refund)
	if record.get("is_booster", false):
		var b_type = record.get("booster_type", "")
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("add_booster"):
			gm.add_booster(b_type, 1)
			
		match b_type:
			"sledgehammer":
				var b_dict = record.get("block_dict", {})
				if not b_dict.is_empty():
					var b_inst = BLOCK_SCENE.instantiate()
					blocks_container.add_child(b_inst)
					b_inst.setup(b_dict)
					b_inst.drag_started.connect(_on_block_drag_started)
					b_inst.drag_ended.connect(_on_block_drag_ended)
					b_inst.moved.connect(_on_block_moved)
					blocks.append(b_inst)
			"shrink":
				var b_shrunk = record.get("block")
				if is_instance_valid(b_shrunk):
					b_shrunk.length += 1
					b_shrunk.custom_minimum_size = b_shrunk.get_block_size()
					b_shrunk.size = b_shrunk.custom_minimum_size
					b_shrunk.update_visual_position(false)
					b_shrunk.queue_redraw()
			"crane":
				var b_crane = record.get("block")
				if is_instance_valid(b_crane):
					b_crane.grid_x = record.get("from_x", 0)
					b_crane.grid_y = record.get("from_y", 0)
					b_crane.update_visual_position(true)
					
		_rebuild_grid_occupancy()
		_check_laser_state_feedback()
		undo_state_changed.emit(not move_history.is_empty())
		queue_redraw()
		booster_action_completed.emit(b_type, false, "↶ Booster Undone & Refunded!")
		return true

	var b = record.get("block")
	if not is_instance_valid(b):
		undo_state_changed.emit(not move_history.is_empty())
		return false
		
	var from_c = record.get("from", Vector2i.ZERO)
	b.grid_x = from_c.x
	b.grid_y = from_c.y
	b.update_visual_position(true)
	_rebuild_grid_occupancy()
	
	# Restore any blocks that were thawed by the undone move
	var thawed = record.get("thawed", [])
	for tb in thawed:
		if is_instance_valid(tb) and tb.has_method("refreeze"):
			tb.refreeze()
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_slide(0.9)
		
	undo_state_changed.emit(not move_history.is_empty())
	queue_redraw()
	return true

func find_block_by_id(b_id: String) -> Control:
	for b in blocks:
		if is_instance_valid(b) and b.block_id == b_id:
			return b
	return null

func _check_ice_melting(moved_b: Control, from_cell: Vector2i, to_cell: Vector2i) -> Array:
	var thawed_blocks: Array = []
	var swept_cells: Array[Vector2i] = []
	var min_x = mini(from_cell.x, to_cell.x)
	var max_x = maxi(from_cell.x, to_cell.x) + (moved_b.length if moved_b.direction == "horizontal" else 1)
	var min_y = mini(from_cell.y, to_cell.y)
	var max_y = maxi(from_cell.y, to_cell.y) + (moved_b.length if moved_b.direction == "vertical" else 1)
	
	for x in range(min_x, max_x):
		for y in range(min_y, max_y):
			swept_cells.append(Vector2i(x, y))
		
	for b in blocks:
		if is_instance_valid(b) and b != moved_b and b.is_frozen:
			var is_adj = false
			for j in range(b.length):
				var fx = b.grid_x + (j if b.direction == "horizontal" else 0)
				var fy = b.grid_y + (j if b.direction == "vertical" else 0)
				for sc in swept_cells:
					if abs(sc.x - fx) + abs(sc.y - fy) == 1:
						is_adj = true
						break
				if is_adj:
					break
			if is_adj:
				b.unfreeze()
				thawed_blocks.append(b)
	return thawed_blocks

func _is_laser_active(laser: Dictionary, exclude_block: Control = null) -> bool:
	var sw_id = laser.get("switch_id", "")
	for sw in switches:
		if sw.get("id") == sw_id or sw_id == "":
			var sw_x = sw.get("x", -1)
			var sw_y = sw.get("y", -1)
			# Check if any block (excluding dragged block if specified) occupies the switch
			for b in blocks:
				if is_instance_valid(b) and b != exclude_block:
					for i in range(b.length):
						var bx = b.grid_x + (i if b.direction == "horizontal" else 0)
						var by = b.grid_y + (i if b.direction == "vertical" else 0)
						if bx == sw_x and by == sw_y:
							return false # Switch pressed! Laser deactivated!
	return true

func _trigger_escape_win_sequence(target_b: Control) -> void:
	is_locked = true
	puzzle_solved_immediately.emit()
	for b in blocks:
		if is_instance_valid(b):
			b.z_index = 0
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_win()
	
	# Trigger particle burst at exit gate
	if win_particles:
		win_particles.position = Vector2(BOARD_SIZE * CELL_SIZE, 2.5 * CELL_SIZE)
		win_particles.emitting = true
		
	# Slide target block smoothly through the exit out of the board
	var tween_dur = 0.2 if blitz_mode else 0.45
	var wait_dur = 0.22 if blitz_mode else 0.65
	var escape_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	var escape_pos = Vector2(BOARD_SIZE * CELL_SIZE + 240, target_b.position.y)
	escape_tween.tween_property(target_b, "position", escape_pos, tween_dur)
	
	# Open win dialog after short delay
	await get_tree().create_timer(wait_dur).timeout
	puzzle_won.emit()
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.is_level_active and not blitz_mode:
		gm.complete_level()

# ----------------- TACTILE PROCEDURAL BOARD DRAWING -----------------

func _draw() -> void:
	var total_w = BOARD_SIZE * CELL_SIZE
	var total_h = BOARD_SIZE * CELL_SIZE
	
	# 1. Main Board Inset Frame
	var board_rect = Rect2(Vector2.ZERO, Vector2(total_w, total_h))
	if board_style:
		draw_style_box(board_style, board_rect)
	else:
		draw_rect(board_rect, Color("#262C3A"), true)
	
	# 2. 36 Inset Cell Grooves + Subtle Exit Lane Guide on Row 2
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var cell_rect = Rect2(
				Vector2(x * CELL_SIZE + PADDING, y * CELL_SIZE + PADDING),
				Vector2(CELL_SIZE - PADDING * 2, CELL_SIZE - PADDING * 2)
			)
			if cell_style:
				draw_style_box(cell_style, cell_rect)
			else:
				draw_rect(cell_rect, Color("#1D222E"), true)
			if y == 2:
				var lane_alpha = 0.04 + 0.025 * float(x) / 5.0
				draw_rect(cell_rect.grow(-6), Color(1.0, 0.32, 0.38, lane_alpha), true)
				
	# 3. Floor Switches
	for sw in switches:
		var sx = sw.get("x", 0)
		var sy = sw.get("y", 0)
		var center = Vector2((sx + 0.5) * CELL_SIZE, (sy + 0.5) * CELL_SIZE)
		
		# Check if occupied
		var is_pressed = false
		for b in blocks:
			if is_instance_valid(b):
				for i in range(b.length):
					var bx = b.grid_x + (i if b.direction == "horizontal" else 0)
					var by = b.grid_y + (i if b.direction == "vertical" else 0)
					if bx == sx and by == sy:
						is_pressed = true
						break
				if is_pressed:
					break
					
		var pad_color = Color("#10AC84") if is_pressed else Color("#FF9F43")
		draw_circle(center, 38.0, pad_color * 0.35)
		draw_arc(center, 38.0, 0, TAU, 32, pad_color, 4.0, true)
		draw_circle(center, 18.0, pad_color)
		
	# 4. Laser Barriers
	for laser in lasers:
		if _is_laser_active(laser):
			var lx = laser.get("x", 4)
			var ly = laser.get("y", 2)
			var p1 = Vector2(lx * CELL_SIZE + 10, (ly + 0.5) * CELL_SIZE)
			var p2 = Vector2((lx + 1) * CELL_SIZE - 10, (ly + 0.5) * CELL_SIZE)
			var laser_col = Color(1.0, 0.2, 0.25, 0.95)
			# Glowing core & outer beam
			draw_line(p1, p2, laser_col * 0.4, 16.0, true)
			draw_line(p1, p2, laser_col, 5.0, true)
			draw_line(p1, p2, Color(1, 1, 1, 0.9), 2.0, true)
			
	# 5. Exit Gate Highlight on Right Edge of Row 2 (Area 1: Dynamic Path-Clear Pulse)
	var exit_y = 2 * CELL_SIZE + PADDING
	var exit_h = CELL_SIZE - PADDING * 2
	var exit_glow = Color("#00FFB2") if is_exit_path_clear else Color("#FF4757")
	
	# Glowing exit slot notch
	draw_line(Vector2(total_w - 4, exit_y), Vector2(total_w - 4, exit_y + exit_h), exit_glow, 15.0 if is_exit_path_clear else 12.0, true)
	
	# If path is clear, draw glowing green runner guide along row 2!
	if is_exit_path_clear and target_block_node != null and is_instance_valid(target_block_node):
		var lead_x = (target_block_node.grid_x + target_block_node.length) * CELL_SIZE
		var runner_alpha = 0.35 + 0.25 * (0.5 + 0.5 * sin(_exit_pulse_t * 2.0))
		draw_line(Vector2(lead_x, exit_y + exit_h * 0.5), Vector2(total_w, exit_y + exit_h * 0.5), Color(0.0, 1.0, 0.7, runner_alpha), 6.0, true)
	
	# Double chevron rightward exit indicators with dynamic pulse
	var pulse_alpha = (0.75 + 0.25 * sin(_exit_pulse_t * 2.0)) if is_exit_path_clear else (0.6 + 0.35 * (0.5 + 0.5 * sin(_exit_pulse_t)))
	var chevron_col = Color(1.0, 0.95, 0.3, pulse_alpha) if is_exit_path_clear else Color(1, 1, 1, pulse_alpha)
	var cy = exit_y + exit_h * 0.5
	var arrow_pts1 = PackedVector2Array([
		Vector2(total_w - 24, cy - 18),
		Vector2(total_w - 10, cy),
		Vector2(total_w - 24, cy + 18)
	])
	draw_polyline(arrow_pts1, chevron_col, 6.0 if is_exit_path_clear else 5.0, true)
	
	var arrow_pts2 = PackedVector2Array([
		Vector2(total_w - 8, cy - 18),
		Vector2(total_w + 6, cy),
		Vector2(total_w - 8, cy + 18)
	])
	draw_polyline(arrow_pts2, chevron_col, 6.0 if is_exit_path_clear else 5.0, true)

	# 6. Active Booster Target Highlighting & Interactive Board Guidance
	if active_booster_mode != "":
		var pulse_a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_exit_pulse_t * 4.0))
		match active_booster_mode:
			"sledgehammer":
				for b in blocks:
					if is_instance_valid(b) and not b.is_target:
						var bx = b.grid_x * CELL_SIZE + PADDING
						var by = b.grid_y * CELL_SIZE + PADDING
						var bw = (b.length * CELL_SIZE - PADDING * 2) if b.direction == "horizontal" else (CELL_SIZE - PADDING * 2)
						var bh = (CELL_SIZE - PADDING * 2) if b.direction == "horizontal" else (b.length * CELL_SIZE - PADDING * 2)
						var r = Rect2(bx, by, bw, bh)
						draw_rect(r, Color(1.0, 0.2, 0.3, pulse_a * 0.25), true)
						draw_rect(r, Color(1.0, 0.3, 0.45, pulse_a), false, 4.0)
			"shrink":
				for b in blocks:
					if is_instance_valid(b) and not b.is_target and b.length > 1:
						var bx = b.grid_x * CELL_SIZE + PADDING
						var by = b.grid_y * CELL_SIZE + PADDING
						var bw = (b.length * CELL_SIZE - PADDING * 2) if b.direction == "horizontal" else (CELL_SIZE - PADDING * 2)
						var bh = (CELL_SIZE - PADDING * 2) if b.direction == "horizontal" else (b.length * CELL_SIZE - PADDING * 2)
						var r = Rect2(bx, by, bw, bh)
						draw_rect(r, Color(0.1, 0.85, 0.95, pulse_a * 0.25), true)
						draw_rect(r, Color(0.1, 0.95, 1.0, pulse_a), false, 4.0)
			"crane":
				if crane_selected_block == null:
					for b in blocks:
						if is_instance_valid(b) and not b.is_target:
							var bx = b.grid_x * CELL_SIZE + PADDING
							var by = b.grid_y * CELL_SIZE + PADDING
							var bw = (b.length * CELL_SIZE - PADDING * 2) if b.direction == "horizontal" else (CELL_SIZE - PADDING * 2)
							var bh = (CELL_SIZE - PADDING * 2) if b.direction == "horizontal" else (b.length * CELL_SIZE - PADDING * 2)
							var r = Rect2(bx, by, bw, bh)
							draw_rect(r, Color(1.0, 0.82, 0.2, pulse_a * 0.25), true)
							draw_rect(r, Color(1.0, 0.85, 0.25, pulse_a), false, 4.0)
				else:
					# Lifted -> draw pulsing drop landing targets on all empty cells
					for gy in range(BOARD_SIZE):
						for gx in range(BOARD_SIZE):
							if grid[gy][gx] == null:
								var center = Vector2((gx + 0.5) * CELL_SIZE, (gy + 0.5) * CELL_SIZE)
								draw_circle(center, 20.0 * pulse_a, Color(0.1, 0.95, 0.6, 0.25))
								draw_arc(center, 26.0, 0, TAU, 24, Color(0.1, 0.95, 0.6, pulse_a), 3.0, true)
