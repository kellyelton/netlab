extends GridContainer

class_name NeuronNode

const TYPE_INPUT := 0
const TYPE_OUTPUT := 1
const TYPE_HIDDEN := 2

var offset := Vector2()

var draw_snap_point := false

var type := TYPE_INPUT
var radius := 24.0
var mouse_pos := Vector2()
var mouse_angle := 0.0
var mouse_distance := 0.0
var is_mouse_over := false
var snap_point := Vector2()
var local_snap_point := Vector2()
var outputs := []
var inputs := []
var is_selected := false
var is_mouse_down := false

func get_relative_snap_point(relative_to: Vector2):
	var angle := relative_to.angle_to_point(rect_position)
	var px := cos(angle) * (radius + 0)
	var py := sin(angle) * (radius + 0)
	var local_point = Vector2(px, py)
	var point = self.rect_position + local_point
	return point

func _container_mouse_move(pos: Vector2):
	mouse_pos = pos
	mouse_angle = mouse_pos.angle_to_point(self.rect_position)
	mouse_distance = mouse_pos.distance_to(self.rect_position)
	is_mouse_over = mouse_distance <= radius + 10
	
	var px = cos(mouse_angle) * radius
	var py = sin(mouse_angle) * radius
	local_snap_point = Vector2(px, py)
	snap_point = self.rect_position + local_snap_point
	
	update()

var InputColor := Color(0.2, 0.6, 0.6, 0.9)
var InputMouseOverColor := Color(0.4, 0.8, 0.8, 0.9)
var InputMouseDownColor := Color(0.2, 0.6, 0.6, 0.6)
var InputSelectedColor := Color(0.6, 1, 1, 0.8)
var InputSelectedMouseOverColor := Color(0.8, 1, 1, 0.9)
var InputSelectedMouseDownColor := Color(0.4, 1, 1, 0.7)

var OutputColor := Color(0.6, 0.4, 0.2, 0.9)
var OutputMouseOverColor := Color(0.6, 0.5, 0.3, 0.9)
var OutputMouseDownColor := Color(0.6, 0.4, 0.2, 0.6)
var OutputSelectedColor := Color(1, 0.8, 0.6, 0.8)
var OutputSelectedMouseOverColor := Color(1, 1, 0.8, 0.9)
var OutputSelectedMouseDownColor := Color(0.8, 0.6, 0.4, 0.7)

var HiddenColor := Color(0.2, 0.2, 0.8, 0.9)
var HiddenMouseOverColor := Color(0.3, 0.3, 0.8, 0.9)
var HiddenMouseDownColor := Color(0.3, 0.3, 0.9, 1)
var HiddenSelectedColor := Color(0.6, 0.6, 0.95, 0.8)
var HiddenSelectedMouseOverColor := Color(0.85, 0.85, 0.99, 0.9)
var HiddenSelectedMouseDownColor := Color(0.4, 0.4, 0.95, 0.7)

func _draw():
	if type == TYPE_INPUT:
		if is_selected:
			if is_mouse_down:
				draw_circle(Vector2.ZERO, radius + 2, InputSelectedMouseDownColor)
			elif is_mouse_over:
				draw_circle(Vector2.ZERO, radius + 8, InputSelectedMouseOverColor)
			else:
				draw_circle(Vector2.ZERO, radius + 4, InputSelectedColor)
		else:
			if is_mouse_down:
				draw_circle(Vector2.ZERO, radius - 3, InputMouseDownColor)
			elif is_mouse_over:
				draw_circle(Vector2.ZERO, radius + 8, InputMouseOverColor)
			else:
				draw_circle(Vector2.ZERO, radius, InputColor)
	elif type == TYPE_OUTPUT:
		if is_selected:
			if is_mouse_down:
				draw_circle(Vector2.ZERO, radius + 2, OutputSelectedMouseDownColor)
			elif is_mouse_over:
				draw_circle(Vector2.ZERO, radius + 8, OutputSelectedMouseOverColor)
			else:
				draw_circle(Vector2.ZERO, radius + 4, OutputSelectedColor)
		else:
			if is_mouse_down:
				draw_circle(Vector2.ZERO, radius - 3, OutputMouseDownColor)
			elif is_mouse_over:
				draw_circle(Vector2.ZERO, radius + 8, OutputMouseOverColor)
			else:
				draw_circle(Vector2.ZERO, radius, OutputColor)
	elif type == TYPE_HIDDEN:
		if is_selected:
			if is_mouse_down:
				draw_circle(Vector2.ZERO, radius + 2, HiddenSelectedMouseDownColor)
			elif is_mouse_over:
				draw_circle(Vector2.ZERO, radius + 8, HiddenSelectedMouseOverColor)
			else:
				draw_circle(Vector2.ZERO, radius + 4, HiddenSelectedColor)
		else:
			if is_mouse_down:
				draw_circle(Vector2.ZERO, radius - 3, HiddenMouseDownColor)
			elif is_mouse_over:
				draw_circle(Vector2.ZERO, radius + 8, HiddenMouseOverColor)
			else:
				draw_circle(Vector2.ZERO, radius, HiddenColor)
	
	if draw_snap_point:
		draw_circle(local_snap_point, 1.5, Color.white)
