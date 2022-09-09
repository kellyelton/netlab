class_name Neuron

var inputs := []
var output := 0.0
var input_neurons := []
var output_neurons := []
var output_weights := []
var output_biases := []

func input(value: float) -> void:
	inputs.append(value)

func process() -> void:
	if inputs.size() == 0: return
	
	if output_neurons:
		for o in range(output_neurons.size()):
			var output_neuron: Neuron = output_neurons[o]
			var output := 0.0
			for i in range(inputs.size()):
				output += i * output_weights[o][i]
			output += output_biases[o]
			output = sigmoid(output)
			output_neuron.input(output)
	else:
		var output := 0.0
		for i in range(inputs.size()):
			output += i * output_weights[0][i]
		output += output_biases[0]
		output = sigmoid(output)
		self.output = output

func sigmoid(x):
	return 1 / (1 + exp(-x))

func dsigmoid(y):
	return y * (1 - y)

func duplicate():
	return get_script().new(self)
