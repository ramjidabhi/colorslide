extends Control

## Block.gd - Interactive Draggable Block
## Handles tactile touch dragging, clamped continuous movement,
## procedural visual styling with rounded corners, and bouncy tween snapping.

signal drag_started(block: Control)
signal drag_ended(block: Control)
signal moved(block: Control, from_cell: Vector2i, to_cell: Vector2i)

@export var block_id: String = ""
@export var grid_x: int = 0
@export var grid_y: int = 0
@export var length: int = 2
@export var direction: String = "horizontal"  # "horizontal" or "vertical"
@export var block_color: Color = Color("#FF4757")
@export var is_target: bool = false
@export var is_frozen: bool = false

const CELL_SIZE: float = 140.0
const PADDING: float = 6.0
const CORNER_RADIUS: float = 24.0

var is_dragging: bool = false
var active_touch_index: int = -1
var drag_start_mouse: Vector2 = Vector2.ZERO
var drag_start_pos: Vector2 = Vector2.ZERO
var min_drag_coord: float = 0.0
var max_drag_coord: float = 0.0
var _hit_min_bound: bool = false
var _hit_max_bound: bool = false

var active_tween: Tween
var bg_style: StyleBoxFlat

func _ready() -> void:
	custom_minimum_size = get_block_size()
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_PASS
	_init_style()
	update_visual_position(false)
	queue_redraw()
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("skin_changed"):
		gm.skin_changed.connect(func(_new_skin): _init_style(); queue_redraw())
	if gm and gm.has_signal("accessibility_updated"):
		gm.accessibility_updated.connect(func(): queue_redraw())

func _init_style() -> void:
	bg_style = StyleBoxFlat.new()
	var current_skin = "classic"
	var gm = get_node_or_null("/root/GameManager")
	if gm and "equipped_skin" in gm:
		current_skin = gm.equipped_skin

	if is_frozen:
		bg_style.bg_color = block_color.lerp(Color("#48DBFB"), 0.55)
		bg_style.border_color = Color("#48DBFB")
		bg_style.border_width_left = 4
		bg_style.border_width_top = 4
		bg_style.border_width_right = 4
		bg_style.border_width_bottom = 4
	elif current_skin == "neon":
		bg_style.bg_color = block_color.darkened(0.2)
		bg_style.border_color = Color("#00D2D3") if not is_target else Color("#FF007F")
		bg_style.border_width_left = 4
		bg_style.border_width_top = 4
		bg_style.border_width_right = 4
		bg_style.border_width_bottom = 4
		bg_style.shadow_color = Color(0.0, 0.8, 1.0, 0.4)
		bg_style.shadow_size = 14
	elif current_skin == "woodcraft":
		bg_style.bg_color = block_color.lerp(Color("#8B4513"), 0.45)
		bg_style.border_color = Color("#D2B48C")
		bg_style.border_width_left = 4
		bg_style.border_width_top = 4
		bg_style.border_width_right = 4
		bg_style.border_width_bottom = 4
		bg_style.shadow_color = Color(0.2, 0.1, 0.05, 0.6)
		bg_style.shadow_size = 10
	elif current_skin == "gemstone":
		bg_style.bg_color = block_color.lerp(Color("#4A0072"), 0.25)
		bg_style.border_color = Color("#E0AAFF")
		bg_style.border_width_left = 3
		bg_style.border_width_top = 3
		bg_style.border_width_right = 3
		bg_style.border_width_bottom = 3
		bg_style.shadow_color = Color(0.6, 0.2, 0.9, 0.35)
		bg_style.shadow_size = 12
	elif current_skin == "gold":
		bg_style.bg_color = block_color.lerp(Color("#DAA520"), 0.4)
		bg_style.border_color = Color("#FFD700")
		bg_style.border_width_left = 4
		bg_style.border_width_top = 4
		bg_style.border_width_right = 4
		bg_style.border_width_bottom = 4
		bg_style.shadow_color = Color(1.0, 0.84, 0.0, 0.45)
		bg_style.shadow_size = 14
	else:
		bg_style.bg_color = block_color
		bg_style.border_width_left = 3
		bg_style.border_width_top = 3
		bg_style.border_width_right = 3
		bg_style.border_width_bottom = 3
		if is_target:
			bg_style.border_color = Color(1.0, 0.9, 0.7, 0.75)
		else:
			bg_style.border_color = Color(1.0, 1.0, 1.0, 0.22)
			
	bg_style.set_corner_radius_all(int(CORNER_RADIUS))
	bg_style.shadow_offset = Vector2(0, 6)
	bg_style.anti_aliasing = true

func setup(b_data: Dictionary) -> void:
	block_id = b_data.get("id", "b")
	grid_x = b_data.get("x", 0)
	grid_y = b_data.get("y", 0)
	length = b_data.get("length", 2)
	direction = b_data.get("direction", "horizontal")
	block_color = Color(b_data.get("color", "#FF4757"))
	is_target = b_data.get("is_target", false)
	is_frozen = b_data.get("is_frozen", false)
	
	_init_style()
	custom_minimum_size = get_block_size()
	size = custom_minimum_size
	update_visual_position(false)
	queue_redraw()

func get_block_size() -> Vector2:
	if direction == "horizontal":
		return Vector2(length * CELL_SIZE - PADDING * 2, CELL_SIZE - PADDING * 2)
	else:
		return Vector2(CELL_SIZE - PADDING * 2, length * CELL_SIZE - PADDING * 2)

func update_visual_position(animate: bool = true) -> void:
	var target_pos = Vector2(
		grid_x * CELL_SIZE + PADDING,
		grid_y * CELL_SIZE + PADDING
	)
	
	if not animate:
		position = target_pos
		return
		
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	active_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "position", target_pos, 0.22)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and active_touch_index == -1:
				_start_drag()
			elif not event.pressed and is_dragging and active_touch_index == -1:
				_end_drag()
				
	elif event is InputEventScreenTouch:
		if event.pressed:
			if not is_dragging and active_touch_index == -1:
				active_touch_index = event.index
				_start_drag()
		elif is_dragging and event.index == active_touch_index:
			active_touch_index = -1
			_end_drag()
			
	elif event is InputEventScreenDrag:
		if is_dragging and event.index == active_touch_index:
			_process_drag()
	elif event is InputEventMouseMotion:
		if is_dragging and active_touch_index == -1:
			_process_drag()

func _start_drag() -> void:
	if is_dragging:
		return
	if is_frozen:
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_tap()
			sm.trigger_haptic(40)
		# Wiggle feedback to show it's locked in ice
		var tw = create_tween()
		var orig = position
		var off = 8.0 if direction == "horizontal" else 0.0
		var off_y = 8.0 if direction == "vertical" else 0.0
		tw.tween_property(self, "position", orig + Vector2(off, off_y), 0.04)
		tw.tween_property(self, "position", orig - Vector2(off, off_y), 0.04)
		tw.tween_property(self, "position", orig, 0.04)
		_show_frozen_toast()
		return
		
	is_dragging = true
	_hit_min_bound = false
	_hit_max_bound = false
	drag_start_mouse = get_global_mouse_position()
	drag_start_pos = position
	z_index = 5  # Elevate during active drag
	drag_started.emit(self)
	
	pivot_offset = size * 0.5
	var pop_t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_t.tween_property(self, "scale", Vector2(1.04, 1.04), 0.1)
	queue_redraw()
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_tap()

func unfreeze() -> void:
	if not is_frozen:
		return
	is_frozen = false
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_slide(1.5)
	
	_init_style()
	var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale = Vector2(1.15, 1.15)
	t.tween_property(self, "scale", Vector2.ONE, 0.25)
	queue_redraw()

func refreeze() -> void:
	if is_frozen:
		return
	is_frozen = true
	_init_style()
	queue_redraw()

func _show_frozen_toast() -> void:
	var existing = get_tree().root.find_child("FrozenToast", true, false)
	if existing:
		return
		
	var toast = PanelContainer.new()
	toast.name = "FrozenToast"
	toast.top_level = true
	toast.z_index = 120
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.16, 0.26, 0.96)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.35, 0.85, 1.0, 0.95)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	toast.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	toast.add_child(margin)
	
	var lbl = Label.new()
	lbl.text = "❄️ LOCKED IN ICE! Slide adjacent block to melt!"
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.96, 1.0, 1.0))
	margin.add_child(lbl)
	
	get_tree().root.add_child(toast)
	var center = global_position + Vector2(size.x * 0.5, -20.0)
	toast.global_position = center - Vector2(240, 30)
	
	var t = create_tween().set_parallel(true)
	t.tween_property(toast, "global_position:y", toast.global_position.y - 35.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.chain().tween_property(toast, "modulate:a", 0.0, 0.4)
	t.chain().tween_callback(toast.queue_free)

func _process_drag() -> void:
	var current_mouse = get_global_mouse_position()
	var mouse_delta = current_mouse - drag_start_mouse
	
	if direction == "horizontal":
		var raw_x = drag_start_pos.x + mouse_delta.x
		var new_x = clamp(raw_x, min_drag_coord, max_drag_coord)
		_check_boundary_bump(raw_x, new_x)
		position.x = new_x
		
		# Auto-escape: if target block is dragged into the right exit slot
		if is_target and is_equal_approx(new_x, max_drag_coord) and max_drag_coord >= (6 - length) * CELL_SIZE + PADDING - 2.0:
			_end_drag()
			return
	else:
		var raw_y = drag_start_pos.y + mouse_delta.y
		var new_y = clamp(raw_y, min_drag_coord, max_drag_coord)
		_check_boundary_bump(raw_y, new_y)
		position.y = new_y

func _check_boundary_bump(raw_coord: float, clamped_coord: float) -> void:
	var gm = get_node_or_null("/root/GameManager")
	var sm = get_node_or_null("/root/SoundManager")
	var allow_shake = not (gm and gm.reduced_motion)
	if raw_coord < min_drag_coord - 8.0:
		if not _hit_min_bound:
			_hit_min_bound = true
			if sm: sm.play_bump()
			if allow_shake:
				_micro_shake(Vector2(-3.0, 0.0) if direction == "horizontal" else Vector2(0.0, -3.0))
	elif raw_coord > min_drag_coord + 10.0:
		_hit_min_bound = false

	if raw_coord > max_drag_coord + 8.0:
		if not _hit_max_bound:
			_hit_max_bound = true
			if sm: sm.play_bump()
			if allow_shake:
				_micro_shake(Vector2(3.0, 0.0) if direction == "horizontal" else Vector2(0.0, 3.0))
	elif raw_coord < max_drag_coord - 10.0:
		_hit_max_bound = false

func _micro_shake(offset: Vector2) -> void:
	var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", position + offset, 0.03)
	tw.tween_property(self, "position", position, 0.05)

func _end_drag() -> void:
	if not is_dragging:
		return
	is_dragging = false
	active_touch_index = -1
	z_index = 0  # Reset to 0 so modals and popups always render on top!
	
	var drop_t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	drop_t.tween_property(self, "scale", Vector2.ONE, 0.12)
	queue_redraw()
	
	drag_ended.emit(self)

func snap_to_nearest_cell() -> bool:
	var old_x = grid_x
	var old_y = grid_y
	
	if direction == "horizontal":
		var snapped_x = int(round((position.x - PADDING) / CELL_SIZE))
		grid_x = snapped_x
	else:
		var snapped_y = int(round((position.y - PADDING) / CELL_SIZE))
		grid_y = snapped_y
		
	var has_moved = (grid_x != old_x or grid_y != old_y)
	if has_moved:
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_slide(1.0 + randf() * 0.1)
		moved.emit(self, Vector2i(old_x, old_y), Vector2i(grid_x, grid_y))
		
	update_visual_position(true)
	return has_moved

# ----------------- TACTILE PROCEDURAL DRAWING -----------------

func _draw() -> void:
	var r = Rect2(Vector2.ZERO, size)
	
	# 1. Elevated soft 3D drop shadow when lifted / dragged
	if is_dragging:
		var shadow_rect = Rect2(Vector2(0, 8), size)
		draw_rect(shadow_rect, Color(0, 0, 0, 0.4), true)
	
	# 2. Main Block Body
	if bg_style:
		draw_style_box(bg_style, r)
	else:
		draw_rect(r, block_color, true)

	# 2b. Procedural Skin Surface Details
	_draw_skin_detail(r)
		
	# 3. 3D Specular Highlight bevel on top edge
	draw_line(Vector2(14, 4), Vector2(size.x - 14, 4), Color(1.0, 1.0, 1.0, 0.35), 2.5)
	
	# Center tactile grip / direction indicators
	var center = size * 0.5
	if is_frozen:
		_draw_frost_crystals(center)
	elif is_target:
		var gm = get_node_or_null("/root/GameManager")
		if gm == null or gm.pet_rescue_enabled:
			_draw_pet_character(center)
		else:
			_draw_escape_arrow(center)
	else:
		# Draw clean minimalist grip dots/pill for obstacles
		_draw_grip_indicators(center)

	# 4. Colorblind accessibility symbol badge in corner
	var gm_cb = get_node_or_null("/root/GameManager")
	if gm_cb and "colorblind_mode" in gm_cb and gm_cb.colorblind_mode and not is_target:
		_draw_colorblind_badge()

func _draw_skin_detail(r: Rect2) -> void:
	var gm = get_node_or_null("/root/GameManager")
	var skin = gm.equipped_skin if (gm and "equipped_skin" in gm) else "classic"
	if skin == "woodcraft":
		var grain_col = Color(0.22, 0.1, 0.04, 0.32)
		for offset in [0.28, 0.5, 0.72]:
			if direction == "horizontal":
				var y = r.size.y * offset
				draw_line(Vector2(14, y), Vector2(r.size.x - 14, y), grain_col, 2.5, true)
			else:
				var x = r.size.x * offset
				draw_line(Vector2(x, 14), Vector2(x, r.size.y - 14), grain_col, 2.5, true)
	elif skin == "gemstone":
		var facet = PackedVector2Array([
			Vector2(16, 10),
			Vector2(r.size.x * 0.55, 10),
			Vector2(r.size.x * 0.32, r.size.y - 10),
			Vector2(16, r.size.y - 10)
		])
		draw_colored_polygon(facet, Color(1.0, 1.0, 1.0, 0.12))
	elif skin == "neon":
		var inner_r = Rect2(Vector2(10, 10), r.size - Vector2(20, 20))
		var neon_col = Color(1.0, 0.25, 0.65, 0.55) if is_target else Color(0.0, 0.9, 1.0, 0.45)
		draw_rect(inner_r, neon_col, false, 2.0)
	elif skin == "gold":
		var sheen = PackedVector2Array([
			Vector2(r.size.x * 0.22, 6),
			Vector2(r.size.x * 0.42, 6),
			Vector2(r.size.x * 0.26, r.size.y - 6),
			Vector2(r.size.x * 0.08, r.size.y - 6)
		])
		draw_colored_polygon(sheen, Color(1.0, 0.97, 0.75, 0.24))

func _draw_colorblind_badge() -> void:
	var pos = Vector2(22, 22)
	var badge_col = Color(1.0, 1.0, 1.0, 0.85)
	var shape_idx = abs(block_id.hash()) % 4
	if shape_idx == 0:
		draw_circle(pos, 7.0, badge_col)
	elif shape_idx == 1:
		draw_rect(Rect2(pos - Vector2(6, 6), Vector2(12, 12)), badge_col, true)
	elif shape_idx == 2:
		var tri = PackedVector2Array([pos + Vector2(0, -7), pos + Vector2(7, 6), pos + Vector2(-7, 6)])
		draw_colored_polygon(tri, badge_col)
	else:
		var dia = PackedVector2Array([pos + Vector2(0, -8), pos + Vector2(8, 0), pos + Vector2(0, 8), pos + Vector2(-8, 0)])
		draw_colored_polygon(dia, badge_col)

func _draw_frost_crystals(center: Vector2) -> void:
	# Central 6-point snowflake
	var ice_color = Color(0.92, 0.98, 1.0, 0.95)
	var cyan_accent = Color(0.28, 0.86, 0.98, 0.85)
	
	for ang in [0.0, PI / 3.0, 2.0 * PI / 3.0]:
		var dir_v = Vector2(cos(ang), sin(ang)) * 22.0
		draw_line(center - dir_v, center + dir_v, ice_color, 4.0, true)
		var tip1 = center + dir_v * 0.7
		var tip2 = center - dir_v * 0.7
		var perp = Vector2(-dir_v.y, dir_v.x) * 0.4
		draw_line(tip1, tip1 + perp, cyan_accent, 3.0, true)
		draw_line(tip1, tip1 - perp, cyan_accent, 3.0, true)
		draw_line(tip2, tip2 + perp, cyan_accent, 3.0, true)
		draw_line(tip2, tip2 - perp, cyan_accent, 3.0, true)

func _draw_escape_arrow(center: Vector2) -> void:
	# Subtle chevron pointing right towards exit
	var arrow_color = Color(1, 1, 1, 0.9)
	var pts = PackedVector2Array([
		center + Vector2(-12, -18),
		center + Vector2(6, 0),
		center + Vector2(-12, 18)
	])
	draw_polyline(pts, arrow_color, 6.0, true)
	
	var pts2 = PackedVector2Array([
		center + Vector2(6, -18),
		center + Vector2(24, 0),
		center + Vector2(6, 18)
	])
	draw_polyline(pts2, arrow_color, 6.0, true)

func _draw_pet_character(center: Vector2) -> void:
	var gm = get_node_or_null("/root/GameManager")
	var w_id = 1
	if gm and not gm.is_daily_mode:
		var l_data = gm.get_current_level_data()
		w_id = int(l_data.get("world_id", 1))

	var look_dir = Vector2(3.0, 0.0) # Eagerly looking right toward the exit!
	if is_dragging:
		look_dir = Vector2(4.0, 0.0)

	if w_id == 2:
		# World 2: Cyber Sports Car 🏎️
		var strip_col = Color(1, 1, 1, 0.85)
		draw_line(Vector2(PADDING + 10, center.y - 12), Vector2(size.x - PADDING - 20, center.y - 12), strip_col, 4.0)
		draw_line(Vector2(PADDING + 10, center.y + 12), Vector2(size.x - PADDING - 20, center.y + 12), strip_col, 4.0)
		# Windshield
		var w_rect = Rect2(center.x - 30, center.y - 20, 40, 40)
		draw_rect(w_rect, Color(0.1, 0.15, 0.25, 0.9), true)
		# Twin glowing LED headlights on right front
		draw_circle(Vector2(size.x - PADDING - 14, center.y - 16), 7.0, Color("#FFF099"))
		draw_circle(Vector2(size.x - PADDING - 14, center.y + 16), 7.0, Color("#FFF099"))
	elif w_id == 3:
		# World 3: Arctic Baby Penguin 🐧
		# White belly oval
		var belly_rect = Rect2(center.x - 45, center.y - 26, 60, 52)
		draw_rect(belly_rect, Color(0.96, 0.98, 1.0, 0.95), true)
		# Eyes
		draw_circle(center + Vector2(-12, -8), 8.0, Color.WHITE)
		draw_circle(center + Vector2(-12, -8) + look_dir, 4.5, Color("#151820"))
		draw_circle(center + Vector2(16, -8), 8.0, Color.WHITE)
		draw_circle(center + Vector2(16, -8) + look_dir, 4.5, Color("#151820"))
		# Orange beak
		var beak = PackedVector2Array([
			center + Vector2(2, -2),
			center + Vector2(16, 2),
			center + Vector2(2, 6)
		])
		draw_colored_polygon(beak, Color("#FFA502"))
		# Exit arrow
		_draw_mini_exit_chevron(center + Vector2(size.x * 0.35, 0))
	elif w_id == 4:
		# World 4: Sci-Fi Recon Drone 🛸
		draw_circle(center, 22.0, Color(0.08, 0.12, 0.18, 0.95))
		draw_arc(center, 22.0, 0, TAU, 24, Color("#00D2D3"), 3.0)
		draw_circle(center, 12.0, Color("#FF4757"))
		draw_circle(center + look_dir, 5.0, Color.WHITE)
		_draw_mini_exit_chevron(center + Vector2(size.x * 0.35, 0))
	else:
		# World 1: Lost Puppy 🐶
		# Left & right floppy ears
		draw_circle(center + Vector2(-46, -18), 16.0, Color("#B33939"))
		draw_circle(center + Vector2(36, -18), 16.0, Color("#B33939"))
		# Expressive large round eyes
		draw_circle(center + Vector2(-22, -6), 11.0, Color.WHITE)
		draw_circle(center + Vector2(-22, -6) + look_dir, 6.0, Color("#151820"))
		draw_circle(center + Vector2(-22, -6) + look_dir + Vector2(-2, -2), 2.5, Color.WHITE)
		
		draw_circle(center + Vector2(18, -6), 11.0, Color.WHITE)
		draw_circle(center + Vector2(18, -6) + look_dir, 6.0, Color("#151820"))
		draw_circle(center + Vector2(18, -6) + look_dir + Vector2(-2, -2), 2.5, Color.WHITE)
		
		# Black button nose
		draw_circle(center + Vector2(-2, 10), 6.5, Color("#151820"))
		# Happy puppy smile line
		draw_arc(center + Vector2(-2, 12), 8.0, 0.1 * PI, 0.9 * PI, 12, Color("#151820"), 3.0)
		# Exit arrow on right flank
		_draw_mini_exit_chevron(center + Vector2(size.x * 0.36, 0))

func _draw_mini_exit_chevron(pos: Vector2) -> void:
	var col = Color(1.0, 1.0, 1.0, 0.85)
	var pts = PackedVector2Array([
		pos + Vector2(-6, -12),
		pos + Vector2(6, 0),
		pos + Vector2(-6, 12)
	])
	draw_polyline(pts, col, 4.0, true)

func _draw_grip_indicators(center: Vector2) -> void:
	var shadow_color = Color(0, 0, 0, 0.32)
	var light_color = Color(1, 1, 1, 0.45)
	
	if length >= 3:
		# Heavy 3-Cell Truck: Draw distinct cargo ribs & cab highlight
		if direction == "horizontal":
			for offset in [-48.0, -24.0, 0.0, 24.0, 48.0]:
				draw_line(center + Vector2(offset, -22), center + Vector2(offset, 22), shadow_color, 7.0, true)
				draw_line(center + Vector2(offset - 1, -22), center + Vector2(offset - 1, 22), light_color, 4.0, true)
		else:
			for offset in [-48.0, -24.0, 0.0, 24.0, 48.0]:
				draw_line(center + Vector2(-22, offset), center + Vector2(22, offset), shadow_color, 7.0, true)
				draw_line(center + Vector2(-22, offset - 1), center + Vector2(22, offset - 1), light_color, 4.0, true)
	else:
		# 2-Cell Car: Clean modern tactile grip slots
		if direction == "horizontal":
			for offset in [-18.0, 0.0, 18.0]:
				draw_line(center + Vector2(offset, -16), center + Vector2(offset, 16), shadow_color, 6.0, true)
				draw_line(center + Vector2(offset - 1, -16), center + Vector2(offset - 1, 16), light_color, 4.0, true)
		else:
			for offset in [-18.0, 0.0, 18.0]:
				draw_line(center + Vector2(-16, offset), center + Vector2(16, offset), shadow_color, 6.0, true)
				draw_line(center + Vector2(-16, offset - 1), center + Vector2(16, offset - 1), light_color, 4.0, true)
