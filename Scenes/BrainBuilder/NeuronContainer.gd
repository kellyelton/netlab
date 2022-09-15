extends Container

class_name NeuronContainer

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
var selecting : NeuronNode = null
var selected = null

var mouse_mode := MM_DEFAULT setget set_mouse_mode

var is_left_mouse_button_down := false

var moving := false
var movement_time := 0
var movement_duration := 300
var movements_from := []
var movements_to := []
var movement_positions := []
var movement_next_batch_start := 0
var movement_waiting_for_next_batch := false
var neuron_type := NeuronNode.TYPE_INPUT
var neuron_type_color := NeuronNode.InputColor

func _process(delta):
	if Input.is_action_just_pressed("bb_next_neuron_type"):
		next_neuron_type()
	if Input.is_action_just_pressed("bb_deselect"):
		select(null)
	if Input.is_action_just_pressed("bb_delete"):
		delete_selected()

	process_movements(delta)

	update()

func next_neuron_type():
	if neuron_type == NeuronNode.TYPE_INPUT:
		neuron_type = NeuronNode.TYPE_HIDDEN
		neuron_type_color = NeuronNode.HiddenColor
	elif neuron_type == NeuronNode.TYPE_HIDDEN:
		neuron_type = NeuronNode.TYPE_OUTPUT
		neuron_type_color = NeuronNode.OutputColor
	elif neuron_type == NeuronNode.TYPE_OUTPUT:
		neuron_type = NeuronNode.TYPE_INPUT
		neuron_type_color = NeuronNode.InputColor
	else:
		print_debug("Neuron type " + str(neuron_type) +" unexpected")

func process_movements(delta: float) -> void:
	if selected == null:
		moving = false
	return

func process_movements_1(delta: float) -> void:
	var now = OS.get_ticks_msec()
	if selected == null:
		moving = false
		if movement_positions.size() > 0:
			movements_from.clear()
			movements_to.clear()
			movement_positions.clear()
		return
	
	if not moving:
		movements_from.clear()
		movements_to.clear()
		movement_positions.clear()
		if selected.outputs.size() > 0:
			moving = true
			movement_time = now
			for out in selected.outputs:
				movements_from.append(selected)
				movements_to.append(out)
			for i in range(movements_from.size()):
				var from : NeuronNode = movements_from[i]
				var to : NeuronNode = movements_to[i]
				movement_positions.append(from.rect_position)
	
	if not moving: return
	
	var max_dist := 0.0
	for i in range(movements_from.size()):
		var from = movements_from[i].rect_position
		var to = movements_to[i].rect_position
		var pos: Vector2 = movement_positions[i]
		var dist = movement_positions[i].distance_to(to)
		movement_positions[i] = pos.move_toward(to, delta * movement_duration * (dist / 40))
		dist = movement_positions[i].distance_to(to)
		if dist > max_dist:
			max_dist = dist

	if max_dist <= 50:
		# next batch
		if not movement_waiting_for_next_batch:
			movement_waiting_for_next_batch = true
			movement_next_batch_start = now + 400
		elif movement_next_batch_start < now:
			movement_waiting_for_next_batch = false
			movement_next_batch_start = 0
			var next_batch := []
			next_batch.append_array(movements_to)
			
			movement_time = now
			movements_from.clear()
			movements_to.clear()
			movement_positions.clear()
			
			for next in next_batch:
				for out in next.outputs:
					movements_from.append(next)
					movements_to.append(out)

			if movements_from.size() == 0:
				moving = false
			else:
				for i in range(movements_from.size()):
					var from : NeuronNode = movements_from[i]
					var to : NeuronNode = movements_to[i]
					movement_positions.append(from.get_relative_snap_point(to.offset))

func set_mouse_mode(new_mouse_mode):
	if mouse_mode == new_mouse_mode: return
	
	mouse_mode = new_mouse_mode
	
	if mouse_mode == MM_DEFAULT:
		print("mm=default")
	elif mouse_mode == MM_CREATE_CONNECTION:
		print("mm=create connection")
	elif mouse_mode == MM_CREATING_CONNECTION:
		print("mm=creating connection")
	elif mouse_mode == MM_CREATE_NEURON:
		print("mm=create neuron")
	elif mouse_mode == MM_CREATING_NEURON:
		print("mm=creating neuron")
	elif mouse_mode == MM_SELECTING_NEURON:
		print("mm=selecting neuron")
	else:
		print("mm=" + str(mouse_mode))
	
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
			selecting = closest_to_mouse
			closest_to_mouse.is_mouse_down = true
			select(closest_to_mouse)
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
		if not is_left_mouse_button_down:
			selecting.is_mouse_down = false
			selecting = null
			new_mode = MM_DEFAULT
		else:
			selecting.rect_position = mouse_pos
			selecting.offset = mouse_pos
			selecting.update()
	else:
		print_debug("Mouse mode not implemented: " + str(mouse_mode))
		new_mode = MM_DEFAULT
	
	set_mouse_mode(new_mode)

	update()

func _draw():
	var mouse_pos = get_local_mouse_position()
	
	for c in get_children():
		var node = c
		for out in node.outputs:
			draw_output_line(node, out)

	draw_movement()
	
	draw_mouse_mode(mouse_pos)

func draw_movement():
	var selected_nodes := []
	var nodes := []
	
	if selected:
		selected_nodes.append(selected)
		nodes.append(selected)
	else:
		for c in get_children():
			var node = c
			if node.type == NeuronNode.TYPE_INPUT:
				selected_nodes.append(node)
				nodes.append(node)
	
	while nodes.size() > 0:
		var next_nodes = []
		for node in nodes:
			for out in node.outputs:
				if out in selected_nodes: continue
				selected_nodes.append(out)
				if not out in nodes:
					next_nodes.append(out)
		nodes = next_nodes
	
	if selected_nodes.size() < 2: return

	for node in selected_nodes:
		for out in node.outputs:
			var c : Color = node.get_main_color()
			c.a = 0.1
			draw_line(node.rect_position, out.rect_position, c, 6, true)
			
			var now = OS.get_ticks_msec()

			for i in range(4):
				var ribbit = ((now + (500 * i)) % 1000) / 1000.0
				var amt = node.rect_position.distance_to(out.rect_position) * ribbit
				var pos = node.rect_position.move_toward(out.rect_position, amt)
				#var rad = ((node.radius / 4) * ribbit) + 5
				var rad = 5
				var opac = 1#(ribbit)
				
				c = c.linear_interpolate(out.get_main_color(), ribbit / 4)

				c.a = 0.1
				draw_circle(pos, rad * 2, c)
				c.a = 1	
				draw_circle(pos, rad, c)

func draw_movement_1():
	for i in range(movement_positions.size()):
		var from = movements_from[i]
		var to = movements_to[i]
		var pos = movement_positions[i]
		
		draw_line(from.rect_position, to.rect_position, Color(1, 0.2, 0.2, 0.2), 10, true)
		draw_circle(pos, 30, Color(1, 0.2, 0.2, 0.2))

func draw_output_line(from: NeuronNode, to: NeuronNode):
	var start_point = from.get_relative_snap_point(to.rect_position)
	var end_point = to.get_relative_snap_point(from.rect_position)
	
	if from == selecting:
		var c1 = from.get_main_color()
		c1.a = 0.3
		draw_line(start_point, end_point, c1, 25, true)
		draw_line(start_point, end_point, Color.white, 8, true)
		draw_line(start_point, end_point, Color(1, 1, 1, 0.8), 4, true)
	elif from == selected:
		draw_line(start_point, end_point, Color(0.9, 0.9, 0.9, 1), 4, true)
	else:
		var c = from.get_main_color()
		c.a = 0.2
		draw_line(start_point, end_point, c, 2, true)
	draw_circle(end_point, 4, Color(0.6, 0.6, 1))

func draw_mouse_mode(mouse_pos):
	if mouse_mode == MM_DEFAULT:
		pass
	elif mouse_mode == MM_CREATE_NEURON:
		var c = neuron_type_color
		c.a = 0.2
		draw_circle(mouse_pos, 20, c)
	elif mouse_mode == MM_CREATING_NEURON:
		draw_circle(mouse_pos, 15, neuron_type_color)
	elif mouse_mode == MM_CREATE_CONNECTION:
		var c = closest_to_mouse.get_main_color()
		c.a = 0.2
		var end = mouse_pos.move_toward(closest_to_mouse.snap_point, 20)
		draw_line(closest_to_mouse.snap_point, end, c, 4, true)
		var c2 = neuron_type_color
		c2.a = 0.2
		draw_circle(mouse_pos, 20, c2)
	elif mouse_mode == MM_CREATING_CONNECTION:
		if closest_to_mouse != null:
			var p1 = connection_start_node.get_relative_snap_point(closest_to_mouse.rect_position)
			var p2 = closest_to_mouse.get_relative_snap_point(connection_start_node.rect_position)
			draw_line(p1, p2, connection_start_node.get_main_color(), 5, true)
			draw_circle(p2, 6, closest_to_mouse.get_main_color())
		else:
			draw_line(connection_start_node.snap_point, mouse_pos, connection_start_node.get_main_color(), 5, true)
			draw_circle(mouse_pos, 20, neuron_type_color)
	elif mouse_mode == MM_SELECTING_NEURON:
		var r = selecting.radius
		var c1 = selecting.get_main_color()
		c1.a = 0.3
		var c2 = Color.white
		draw_circle(selecting.rect_position, r + 10, c1)
		draw_circle(selecting.rect_position, r, c2)
	else:
		print_debug("Mouse mode not implemented: " + str(mouse_mode))

func create_neuron(pos: Vector2) -> NeuronNode:
	var neuron = NeuronNode.new()
	neuron.offset.x = pos.x
	neuron.offset.y = pos.y
	neuron.type = neuron_type
	add_child(neuron, true)
	return neuron

func update_closest_neuron() -> NeuronNode:
	var closest :NeuronNode = null
	var closest_distance = self.connection_hint_distance
	var mouse_pos = get_local_mouse_position()
	for c in get_children():
		c._container_mouse_move(mouse_pos)
		c.draw_snap_point = false
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
	
	moving = false
	
	if selected == null:
		print("Diselected")
	else:
		selected.is_selected = true
		print("Selected " + str(selected))
	
	emit_signal("selected_changed", selected)

func delete_selected() -> void:
	if not selected: return
	
	var deleted = selected
	
	select(null)
	
	remove_child(deleted)
	
	for c in get_children():
		if deleted in c.inputs:
			c.inputs.erase(deleted)
		if deleted in c.outputs:
			c.outputs.erase(deleted)
	
	deleted.queue_free()
