class_name VinController

const NeuralNetwork = preload("res://Scripts/NeuralNet.gd")

var neural_network: NeuralNetwork
var body = null
var feedback = 0

var move_activation = 0.2

func _init(parent:KinematicBody2D):
	self.body = parent
	var inputCount = 0
	inputCount += self.body.fov_size * 2
	inputCount += 1 # touching food
	inputCount += 1 # energy
	inputCount += 1 # feedback
	inputCount += 2 # velocity
	inputCount += 5 # random
	self.neural_network = NeuralNetwork.new(inputCount, 24, 8)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var tf = 0
	if self.body.is_touching_food: tf = 1
	var inputs = [
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
	
	var right = outputs[0]
	var down = outputs[1]
	var left = outputs[2]
	var up = outputs[3]
	
	if right < self.move_activation: right = 0
	if down < self.move_activation: down = 0
	if left < self.move_activation: left = 0
	if up < self.move_activation: up = 0
	
	var req_velocity = Vector2(\
		-left + right,\
		-up + down\
	)
	
	self.body.requested_velocity = req_velocity
			
	if outputs[4] < 0.2:
		self.body.make_baby()
		
	self.feedback = outputs[5]
	self.body.speed_percent = outputs[6]
	
	self.body.request_bite = outputs[7] > 0.8

	for o in outputs:
		if o < 0: print_debug(o)
