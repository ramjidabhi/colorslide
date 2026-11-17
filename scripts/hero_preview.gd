extends Control

## HeroPreview.gd - Animated Mini-Board Preview on Main Menu
## Visually demonstrates the core slide-to-escape loop in 2 seconds.

var anim_time: float = 0.0
const LOOP_DUR: float = 3.6

func _ready() -> void:
	custom_minimum_size = Vector2(360, 170)

func _process(delta: float) -> void:
	anim_time = fmod(anim_time + delta, LOOP_DUR)
	queue_redraw()

func _ease_in_out(t: float) -> float:
	t = clamp(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _draw() -> void:
	var w = size.x
	var h = size.y
	var board_w = 280.0
	var board_h = 156.0
	var ox = (w - board_w) * 0.5
	var oy = (h - board_h) * 0.5
	var cell = 46.0

	# Mini board container
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#121622")
	sb.border_color = Color("#2D374E")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(18)
	draw_style_box(sb, Rect2(ox, oy, board_w, board_h))

	# Subtle 6x3 cells
	for r in range(3):
		for c in range(6):
			var cr = Rect2(ox + 4 + c * cell, oy + 9 + r * cell, cell - 4, cell - 4)
			draw_rect(cr, Color("#191E2D"), true)

	# Glowing exit gate on right middle row
	var exit_y = oy + 9 + cell
	var pulse = 0.65 + 0.35 * sin(anim_time * 5.0)
	draw_line(Vector2(ox + board_w - 2, exit_y + 4), Vector2(ox + board_w - 2, exit_y + cell - 8), Color(1.0, 0.3, 0.35, pulse), 6.0, true)

	# Phase 1 (0.0 - 1.1s): Cyan vertical blocker slides down from row 0 to row 1
	var p1 = _ease_in_out(anim_time / 0.85)
	if anim_time > 3.1:
		p1 = 1.0 - _ease_in_out((anim_time - 3.1) / 0.5)
	var cyan_y = lerp(0.0, 1.0, p1)
	_draw_mini_block(Rect2(ox + 4 + 3 * cell, oy + 9 + cyan_y * cell, cell - 4, cell * 2 - 4), Color("#00D2D3"), false)

	# Phase 2 (0.8 - 2.6s): Red hero block slides right to exit!
	var p2 = 0.0
	if anim_time > 0.85 and anim_time <= 2.3:
		p2 = _ease_in_out((anim_time - 0.85) / 1.0)
	elif anim_time > 2.3 and anim_time <= 3.1:
		p2 = 1.0
	elif anim_time > 3.1:
		p2 = 1.0 - _ease_in_out((anim_time - 3.1) / 0.5)
	var red_x = lerp(0.4, 4.0, p2)
	_draw_mini_block(Rect2(ox + 4 + red_x * cell, oy + 9 + cell, cell * 2 - 4, cell - 4), Color("#FF4757"), true)

	# Static accent block at bottom-left for puzzle depth
	_draw_mini_block(Rect2(ox + 4, oy + 9 + 2 * cell, cell * 2 - 4, cell - 4), Color("#FFA502"), false)

func _draw_mini_block(r: Rect2, col: Color, is_hero: bool) -> void:
	var s = StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(10)
	s.set_border_width_all(2)
	s.border_color = Color(1, 0.9, 0.8, 0.75) if is_hero else Color(1, 1, 1, 0.25)
	draw_style_box(s, r)
	if is_hero:
		var c = r.position + r.size * 0.5
		var pts = PackedVector2Array([c + Vector2(-4, -8), c + Vector2(6, 0), c + Vector2(-4, 8)])
		draw_polyline(pts, Color.WHITE, 3.0, true)
