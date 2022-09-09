extends Container

class_name NeuronContainer

const NeuronNode = preload("./NeuronNode.tscn")

const MM_DEFAULT := 0
const MM_CREATE_NEURON := 1
const MM_CREATING_NEURON := 2
const MM_CREATE_CONNECTION := 3
const MM_CREATING_CONNECTION := 4
const MM_SELECTING_NEURON := 5

signal mouse_mode_changed(mouse_mode)
signal selected_changed(selected)

export var connection_hint_distance := 100

var closest_to_mouse :NeuronNode = null
var connection_start_node : NeuronNode = null
var selected = null

var mouse_mode := MM_DEFAULT setget set_mouse_mode

var is_left_mouse_button_down := false

func set_mouse_mode(new_mouse_mode):
	if mouse_mode == new_mouse_mode: return
	
	mouse_mode = new_mouse_mode
	
	emit_signal("mouse_mode_changed", mouse_mode)

func _notification(what):
	if not what == NOTIFICATION_SORT_CHILDREN: return
	
	for child in get_children():
		if not "offset" in child: continue
		var size = child.rect_size
		var pos = child.offset
		var rec = Rect2(pos, size)
		fit_child_in_rect(child, rec)

func _on_NeuronContainer_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			is_left_mouse_button_down = event.is_pressed()
			update_mouse_mode()
	elif event is InputEventMouseMotion:
		update_mouse_mode()

func update_mouse_mode() -> void:
	var mouse_pos = get_local_mouse_position()
	
	update_closest_neuron()
	var new_mode := mouse_mode
	if mouse_mode == MM_DEFAULT:
		if closest_to_mouse == null:
			new_mode = MM_CREATE_NEURON
		elif closest_to_mouse.mouse_distance >= (closest_to_mouse.radius + 10):
			if get_child_count() >= 2:
				new_mode = MM_CREATE_CONNECTION
		elif is_left_mouse_button_down:
			new_mode = MM_SELECTING_NEURON
			closest_to_mouse.is_mouse_down = true
	elif mouse_mode == MM_CREATE_NEURON:
		if closest_to_mouse != null:
			new_mode = MM_DEFAULT
		elif is_left_mouse_button_down:
			new_mode = MM_CREATING_NEURON
	elif mouse_mode == MM_CREATING_NEURON:
		if not is_left_mouse_button_down:
			if closest_to_mouse == null:
				var n = create_neuron(mouse_pos)
				select(n)
			new_mode = MM_DEFAULT
	elif mouse_mode == MM_CREATE_CONNECTION:
		if closest_to_mouse == null:
			new_mode = MM_DEFAULT
		elif closest_to_mouse.mouse_distance < (closest_to_mouse.radius + 10):
			new_mode = MM_DEFAULT
		elif is_left_mouse_button_down:
			new_mode = MM_CREATING_CONNECTION
			connection_start_node = closest_to_mouse
			update_closest_neuron()
	elif mouse_mode == MM_CREATING_CONNECTION:
		if not is_left_mouse_button_down:
			if closest_to_mouse == null:
				if connection_start_node.mouse_distance > connection_hint_distance:
					closest_to_mouse = create_neuron(mouse_pos)
					select(closest_to_mouse)
			if closest_to_mouse != null:
				connect_neurons(connection_start_node, closest_to_mouse)
			new_mode = MM_DEFAULT
			connection_start_node = null
			update_closest_neuron()
	elif mouse_mode == MM_SELECTING_NEURON:
		if closest_to_mouse == null:
			new_mode = MM_DEFAULT
		elif not is_left_mouse_button_down:
			select(closest_to_mouse)
			new_mode = MM_DEFAULT
	else:
		print_debug("Mouse mode not implemented: " + str(mouse_mode))
		new_mode = MM_DEFAULT
	
	set_mouse_mode(new_mode)

	update()

func _draw():
	var mouse_pos = get_local_mouse_position()
	
	for c in get_children():
		var node: NeuronNode = c
		for out in node.outputs:
			draw_output_line(node, out)
	
	draw_mouse_mode(mouse_pos)

func draw_output_line(from: NeuronNode, to: NeuronNode):
	var start_point = from.get_relative_snap_point(to.rect_position)
	var end_point = to.get_relative_snap_point(from.rect_position)
	
	draw_line(start_point, end_point, Color(0.6, 0.6, 0.6, 0.6), 2, true)
	draw_circle(end_point, 4, Color(0.6, 0.6, 1))

func draw_mouse_mode(mouse_pos):
	if mouse_mode == MM_DEFAULT:
		pass
	elif mouse_mode == MM_CREATE_NEURON:
		draw_circle(mouse_pos, 10, Color(0.6, 1, 0.6, 0.5))
	elif mouse_mode == MM_CREATING_NEURON:
		draw_circle(mouse_pos, 10, Color(0.6, 1, 0.6, 0.8))
	elif mouse_mode == MM_CREATE_CONNECTION:
		draw_line(closest_to_mouse.snap_point, mouse_pos, Color(1, 1, 1, 0.2), 2, true)
	elif mouse_mode == MM_CREATING_CONNECTION:
		if closest_to_mouse != null:
			var p1 = connection_start_node.get_relative_snap_point(closest_to_mouse.rect_position)
			var p2 = closest_to_mouse.get_relative_snap_point(connection_start_node.rect_position)
			draw_line(p1, p2, Color(0.6, 0.6, 1, 0.5), 5, true)
			draw_circle(p2, 6, Color(0.6, 0.6, 1))
		else:
			draw_line(connection_start_node.snap_point, mouse_pos, Color(0.6, 0.6, 1, 0.5), 5, true)
			draw_circle(mouse_pos, 10, Color(0.2, 0.2, 0.6, 0.9))
	elif mouse_mode == MM_SELECTING_NEURON:
		var r = closest_to_mouse.radius
		draw_circle(closest_to_mouse.rect_position, r, Color(0.2, 0.6, 0.2, 0.5))
	else:
		print_debug("Mouse mode not implemented: " + str(mouse_mode))

func create_neuron(pos: Vector2) -> NeuronNode:
	var neuron = NeuronNode.instance()
	neuron.offset.x = pos.x
	neuron.offset.y = pos.y
	add_child(neuron, true)
	return neuron

func update_closest_neuron() -> NeuronNode:
	var closest :NeuronNode = null
	var closest_distance = self.connection_hint_distance
	var mouse_pos = get_local_mouse_position()
	for c in get_children():
		c._container_mouse_move(mouse_pos)
		c.draw_snap_point = false
		c.is_mouse_down = false
		if c == connection_start_node:
			continue
		if c.mouse_distance < closest_distance:
			closest = c
			closest_distance = c.mouse_distance
	closest_to_mouse = closest
	return closest_to_mouse

func connect_neurons(neuron_from: NeuronNode, neuron_to: NeuronNode) -> void:
	if not neuron_to in neuron_from.outputs:
		neuron_from.outputs.append(neuron_to)
	if not neuron_from in neuron_to.inputs:
		neuron_to.inputs.append(neuron_from)

func select(what) -> void:
	if selected == what: return
	if not selected == null:
		selected.is_selected = false
	
	selected = what
	
	if not selected == null:
		selected.is_selected = true
		
	emit_signal("selected_changed", selected)
