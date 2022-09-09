extends Control

const NeuronProperties = preload("./NeuronProperties.tscn")

onready var neurons := $VBoxContainer/HBoxContainer/MarginContainer/NeuronContainer
onready var props := $VBoxContainer/HBoxContainer/PanelContainer/MarginContainer

func _ready():
	pass
	#neurons.mouse_mode = NeuronContainer.MM_SELECT

func _on_SelectToolButton_toggled(button_pressed):
	pass

func _on_AddNeuronToolButton_toggled(button_pressed):
	pass


func _on_NeuronContainer_selected_changed(selected):
	for c in props.get_children():
		props.remove_child(c)
		
	if selected == null: return
	
	if selected is NeuronNode:
		var t = NeuronProperties.instance()
		#var t = NeuronProperties.new()
		t.neuron = selected
		props.add_child(t)
