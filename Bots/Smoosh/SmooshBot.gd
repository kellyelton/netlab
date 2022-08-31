extends KinematicBody2D

export (int) var speed = 1200
export (float) var rotation_speed = 20
export (int) var max_energy = 14000 
export (float) var min_speed_percent = 0.1
export (int) var min_time_between_bites_ms = 300
export (String) var bot_type = "SmooshBot"
export (bool) var show_debug_lines = false

onready var start_time = OS.get_ticks_msec()
onready var fov_size = get_node("rays").get_child_count()
onready var controller = preload("./SmooshController.gd").new(self)

const LEFT = 0
const RIGHT = 1
const NONE = 0.5
const FORWARD = 1
const BACKWARD = 0

var turn = NONE
var direction = NONE
var age = 0
var fov = []
var fov_distances = []
var lastBaby = 0
var baby_count = 0
var parent_bot = null
var perfect_clone = false
var energy = max_energy
var total_energy_gained = 0
var score = 0
var isAlive = true
var start_position = null
var last_position = null
var total_distance = 0
var velocity = Vector2()
var speed_percent = 1
var despawn_time = 0
var debug_lines = []
var is_touching_food = false
var touching = []
var request_bite = false
var time_last_bite = 0
var ui_layer: CanvasLayer = null
var generation: int = 0

func _ready():
	if parent_bot != null:
		self.controller.neural_network = parent_bot.controller.neural_network.duplicate()
		if not self.perfect_clone:
			self.controller.neural_network.mutate()
			print("bot mutated from " + str(parent_bot.get_instance_id()))
	last_position = position
	start_position = position
	#TODO: Maybe these guys could have a tractor beam, or siphon energy from other things (pink debug ray)
	self.generation = self.get_generation_count()

func _physics_process(delta):
	if not self.isAlive: return
	
	var rotate = 0
	
	if turn == LEFT:
		rotate = -1
	elif turn == RIGHT:
		rotate = 1
		
	if rotate != 0:
		rotate = rotate * rotation_speed * delta

	var dir = Vector2()
	if direction == FORWARD:
		dir.x = 1
	elif direction == BACKWARD:
		dir.x =  0.25

	rotation += rotate
	
	velocity = lerp(velocity, (dir * (speed * max(min_speed_percent, speed_percent))), 0.2) * delta
	
	velocity = velocity.rotated(rotation)

	self.touching.clear()
	self.is_touching_food = false
	var collision = move_and_collide(velocity)
	if collision:
		velocity = velocity.bounce(collision.normal)
		var collider = collision.get_collider()
		self.touching.append(collider)
		if collider.is_class("TileMap"):
			energy = max(0, energy - (500 * delta))
		elif collider.is_in_group("food"):
			self.is_touching_food = true
			collider.hit(self, velocity)
		elif collider.is_in_group("bot"):
			energy = max(0, energy - (500 * delta))
		elif collider.has_method("_on_bot_hit"):
			collider._on_bot_hit(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not self.isAlive: return
	
	self.age = (OS.get_ticks_msec() - start_time) / 1000
	self.total_distance += position.distance_to(self.last_position)
	self.last_position = position
	self.fov.clear()
	self.fov_distances.clear()
	if show_debug_lines:
		self.debug_lines.clear()
	var rays = self.get_node("rays")
	for ray in rays.get_children():
		if ray.is_colliding():
			var obj = ray.get_collider()
			
			var collision_point = ray.get_collision_point()
			var collision_point_local = to_local(collision_point)

			if show_debug_lines:
				self.debug_lines.append([Vector2(0, 0), collision_point_local])

			var distance = global_position.distance_to(collision_point)
			self.fov_distances.append(distance)
			if obj.is_class("TileMap"):
				self.fov.append(-100)
			elif obj.is_in_group("bot"):
				self.fov.append(20)
			elif obj.is_in_group("food"):
				self.fov.append(50)
			elif obj.is_in_group("map_danger"):
				self.fov.append(100)
			else:
				self.fov.append(0)
				self.fov_distances.append(-1)
		else:
			self.fov.append(0)
			self.fov_distances.append(-1)
	
	self.controller._process(delta)

	if self.request_bite && self.is_touching_food:
		if OS.get_ticks_msec() >= (self.time_last_bite + min_time_between_bites_ms):
			for node in self.touching:
				if node.is_in_group("food"):
					self.time_last_bite = OS.get_ticks_msec()
					
					var energy_gain = node.bite(self, 250)
					
					self.total_energy_gained += energy_gain
					
					self.energy = min(self.max_energy, energy_gain + self.energy)
					break
	
	var move_energy = 0
	
	if self.turn != 0:
		move_energy += (self.age / 4) * delta
	if self.direction != 0:
		var speed_per = max(min_speed_percent, self.speed_percent)
		move_energy += (self.age / 4) * speed_per * delta

	self.energy = max(0, self.energy - move_energy)
		
	self.energy = max(0, self.energy - (self.age * delta))
	
	$AnimatedSprite.speed_scale = max(min_speed_percent, self.speed_percent)
	
	self.score = calculate_score()
	
	if self.energy == 0:
		die("ran out of energy")
		
	update()

var lcolor = Color(0.8, 0.2, 0.8, 0.4)
var lcolor2 = Color(0.9, 0.3, 0.9, 0.4)

func _draw():
	if not show_debug_lines: return
	
	for debug_line in self.debug_lines:
		var from = debug_line[0]
		var to = debug_line[1]
		draw_line(from, to, self.lcolor, 1)
		
		var rect = Rect2(to, Vector2(0.6, 0.6))
		draw_circle(to, 0.6, lcolor2)

func make_baby():
	return
	if OS.get_ticks_msec() >= (1000 * 5) + lastBaby:
		if self.energy < 20:
			self.die("died from reproduction")
			return

		self.baby_count += 1

		self.energy = max(0, self.energy - 20)

		var newBot = load("./SmooshBot.tscn").instance()
		newBot.parent_bot = self
		newBot.position = Vector2(position.x - 16, position.y - 16)
		lastBaby = OS.get_ticks_msec()
		newBot.lastBaby = lastBaby
		get_parent().add_child(newBot)
		print("new bb born")

		if self.energy == 0:
			self.die("died in child birth")

func bitten(who):
	if not isAlive: return 0
	var energy_to_give = 800
	if energy < 800:
		energy_to_give = 800 - energy
	
	energy -= energy_to_give
	
	if energy <= 0:
		die("bitten by: " + str(who))
		
	return energy_to_give

func die(reason):
	if isAlive == false:
		return

	isAlive = false
	despawn_time = OS.get_ticks_msec() + (1000 * 4)
	
	self.modulate = Color.dimgray
	
	self.score = calculate_score()
	
	print("bot died at age " + str(age) + " (" + str(score) + "): " + reason)
	
	var newFood = load("res://Bots/Blub/BlubBot.tscn").instance()
	newFood.position = position
	newFood.energy = 100
	newFood.is_meat = true
	self.get_parent().add_child(newFood)
	
	self.energy = 0

func get_generation_count() -> int:
	var parent_count = 0
	var cur_parent = self.parent_bot
	while cur_parent != null:
		parent_count += 1
		cur_parent = cur_parent.parent_bot
		
	return parent_count

func calculate_score() -> float:
	var age_bonus = (age / (60.0 * 5.0)) * 1000.0
	
	var total_energy_gained_bonus = self.total_energy_gained * 4
	
	var total_distance_bonus = 0 # total distance
	var distance_from_spawn_bonus = 0 # position.distance_to(start_position)
	
	var total_baby_bonus = 0
	# If died in childbirth, reduce bonus
	
	var score\
		= age_bonus\
		+ total_distance_bonus\
		+ distance_from_spawn_bonus\
		+ total_baby_bonus\
		+ total_energy_gained_bonus
	
	return score

func _on_SmooshBot_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_RIGHT \
	and event.is_pressed():
		die("User killed")

func follow_cam():
	$FollowCam.current = true

func _on_selected():
	var details = load("res://Components/BotDetails/BotDetails.tscn").instance()
	details.bot = self
	
	ui_layer.add_child(details)
	details.popup_centered()
