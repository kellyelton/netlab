extends GridContainer
class_name NeuronProperties

var neuron: NeuronNode = null

onready var si = $SelectType

func _ready():
	si.items.clear()
	si.add_item("Input", NeuronNode.TYPE_INPUT)
	si.add_item("Output", NeuronNode.TYPE_OUTPUT)
	si.add_item("Hidden", NeuronNode.TYPE_HIDDEN)
	
	si.select(neuron.type)

func _on_SelectType_item_selected(index):
	neuron.type = index
