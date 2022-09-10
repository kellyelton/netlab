extends Control

const NeuronProperties = preload("./NeuronProperties.tscn")

onready var neurons := $VBoxContainer/HBoxContainer/MarginContainer/NeuronContainer
onready var props := $VBoxContainer/HBoxContainer/PanelContainer/MarginContainer

func _ready():
	load_auto_save()

func _on_SelectToolButton_toggled(button_pressed):
	save_auto_save()

func _on_AddNeuronToolButton_toggled(button_pressed):
	get_tree().reload_current_scene()

func _notification(what):
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		save_auto_save()

func _on_NeuronContainer_selected_changed(selected):
	for c in props.get_children():
		props.remove_child(c)
		
	if selected == null: return
	
	if selected is NeuronNode:
		var t = NeuronProperties.instance()
		#var t = NeuronProperties.new()
		t.neuron = selected
		props.add_child(t)

func load_auto_save():
	var file = File.new()
	if not file.file_exists("autosave.nmodel"): return
		
	file.open("autosave.nmodel", File.READ)
	var state = file.get_var(true)
	file.close()
	
	var neuron_nodes = {}
	for n in state["neurons"]:
		var rn = NeuronNode.new()
		rn.offset = n.offset
		rn.type = n.type
		rn.save_id = n.save_id
		neuron_nodes[rn.save_id] = rn
		neurons.add_child(rn)
	
	for n in state["neurons"]:
		var neuron_node = neuron_nodes[n.save_id]
		for i in n.inputs:
			var input_node = neuron_nodes[i]
			neuron_node.inputs.append(input_node)
		for o in n.outputs:
			var output_node = neuron_nodes[o]
			neuron_node.outputs.append(output_node)

func save_auto_save() -> void:
	var state = {}
	state["neurons"] = []
	for child in neurons.get_children():
		var n = {}
		n["save_id"] = child.save_id
		n["type"] = child.type
		n["offset"] = child.rect_position
		var inputs = []
		for i in child.inputs:
			inputs.append(i.save_id)
		n["inputs"] = inputs
		var outputs = []
		for o in child.outputs:
			outputs.append(o.save_id)
		n["outputs"] = outputs
		state["neurons"].append(n)
	var file = File.new()
	file.open("autosave.nmodel", File.WRITE_READ)
	file.store_var(state, true)
	file.close()
