class_name SmooshController

const NeuralNetwork = preload("res://Scripts/NeuralNet.gd")

export (float) var turn_bias = 0.5
export (float) var move_bias = 0.5

const LEFT = 0
const RIGHT = 1
const NONE = 0.5
const FORWARD = 1
const BACKWARD = 0

var neural_network: NeuralNetwork
var body = null
var feedback = 0

func _init(parent:KinematicBody2D):
	self.body = parent
	var inputCount = 0
	inputCount += self.body.fov_size * 2
	inputCount += 2 # turn/direction
	inputCount += 1 # touching food
	inputCount += 1 # energy
	inputCount += 1 # feedback
	inputCount += 2 # velocity
	inputCount += 5 # random
	self.neural_network = NeuralNetwork.new(inputCount, 4, 8)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var tf = 0
	if self.body.is_touching_food: tf = 1
	
	var inputs = [self.body.turn,
				  self.body.direction,
				  tf,
				  self.body.energy,
				  feedback,
				  self.body.velocity.x,
				  self.body.velocity.y,
				  rand_range(0, 5),
				  rand_range(0, 5),
				  rand_range(0, 5),
				  rand_range(0, 5),
				  rand_range(0, 5)]
				
	for i in range(len(body.fov)):
		var fov = body.fov[i]
		var fov_distance = body.fov_distances[i]
		inputs.append(fov * 100)
		inputs.append(fov_distance * 10)

	var outputs = self.neural_network.predict(inputs)
	
	if outputs[0] > turn_bias && outputs[1] > turn_bias:
		self.body.turn = NONE
	elif outputs[0] > turn_bias:
		self.body.turn = LEFT
	elif outputs[1] > turn_bias:
		self.body.turn = RIGHT
	else:
		self.body.turn = NONE

	if outputs[2] > move_bias && outputs[3] > move_bias:
		self.body.direction = NONE
	elif outputs[2] > move_bias:
		self.body.direction = BACKWARD
	elif outputs[3] > move_bias:
		self.body.direction = FORWARD
	else:
		self.body.direction = NONE
		
	if outputs[4] < 0.2:
		self.body.make_baby()
		
	self.feedback = outputs[5]
	self.body.speed_percent = outputs[6]
	
	self.body.request_bite = outputs[7] > 0.8
