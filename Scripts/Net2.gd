class_name Net2

const Neuron = preload("./Neuron.gd")

var input_neurons := []
var output_neurons := []
var hidden_neurons := []

func _init(inputs: int, outputs: int, hiddens: int):
	for o in range(outputs):
		output_neurons.append(Neuron.new())

	for i in range(inputs):
		var neuron = Neuron.new()
		input_neurons.append(neuron)
		for o in output_neurons:
			neuron.add_output(o)
	
	for h in range(hiddens):
		var neuron = Neuron.new()
		hidden_neurons.append(neuron)
		

func predict(inputs: Array) -> Array:
	if not output_neurons: return []
	if not input_neurons: return []
	if not inputs: return []
	
	for i in range(0, input_neurons.size()):
		var input = 0
		if inputs.size() >= i:
			input = inputs[i]

		input_neurons[i].input(input)

	var outputs = []

	var layer = input_neurons
	var next_layer = []
	while layer != null:
		for i in range(0, layer.size()):
			var neuron = layer[i]
			
			neuron.process()
			
			for n in neuron.output_neurons:
				next_layer.append(n)

		if next_layer.size() == 0:
			for n in layer:
				outputs.append(n.output)
			layer = null
		else:
			layer = next_layer
			next_layer = []
	
	return outputs

func duplicate():
	return get_script().new(self)
