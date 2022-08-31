extends KinematicBody2D

export (int) var min_speed = 2
export (int) var max_speed = 12
export (int) var start_speed = 10
export (int) var min_start_energy = 100
export (int) var max_start_energy = 3000
export (int) var energy_loss_per_second = 10
export (bool) var is_meat = false

onready var is_dead = false
onready var is_alive = true
onready var speed = rand_range(min_speed, max_speed)
onready var direction = Vector2(rand_range(-1, 1), rand_range(-1, 1))

var scale_adjust = Vector2(1, 1)

var time_died = null
var time_cleanup = null
var hit_velocity = null

var energy: int = 0
var _last_start_energy: int = 0

func _ready():
	self.energy = rand_range(self.min_start_energy, self.max_start_energy)
	self._last_start_energy = energy
	
	var adj_energy = self.energy - self.min_start_energy
	var adj_max = self.max_start_energy - self.min_start_energy
	
	var adj = adj_energy / float(adj_max)
	
	var adj2 = (adj * 2.5) + 0.5

	self.scale_adjust = Vector2(adj2, adj2)
	var sprite = $"CollisionShape2D/AnimatedSprite"
	sprite.frame = randi() * sprite.frames.get_frame_count("default")
	
	if self.is_meat:
		self.modulate = Color("ae7d5f")
	
	$EachSecondTimer.start()

func _process(delta):
	if self.is_dead: return
	
	$CollisionShape2D.scale = self.scale_adjust * self.get_energy_percent()

func get_energy_percent() -> float:
	return self.energy / float(self._last_start_energy)

func _take_energy_die(amount_requested: int, die_reason: String) -> int:
	assert(amount_requested > 0, "amount_requested must be greater than 0")
	
	if self.is_dead: return 0
	
	var original_energy = self.energy
	
	if original_energy <= 0: return 0
	
	self.energy = max(0, original_energy - amount_requested)
	
	var taken_energy = original_energy - self.energy
	
	var died = self.energy == 0 && taken_energy > 0

	if died: _die(die_reason)
	
	return taken_energy

func _physics_process(delta):
	if hit_velocity != null:
		self.direction = hit_velocity.normalized()
		hit_velocity = null
		return
	
	if self.speed <= 0: return

	var vel = self.speed * delta * self.direction
	
	var collision = move_and_collide(vel)
	
	if collision:
		direction = direction.bounce(collision.normal)

func hit(byWho, velocity):
	hit_velocity = velocity

func bite(who: Node, size: int, where: Vector2 = Vector2(0,0)) -> int:
	if self.is_dead: return 0
	
	var bite = $BiteParticles.duplicate()
	#TODO: Make particles happen where the collision happens
	get_parent().get_parent().add_temp_particles(bite, 5000, position)
	
	if is_meat:
		size = size / 2
	
	return self._take_energy_die(size, "Bitten by " + str(who))

func eaten(byWho):
	if self.is_dead: return
	
	#var bite = $BiteParticles.duplicate()
	#add_child(bite)
	#bite.emitting = true
	
	self._take_energy_die(self.energy, "Eaten by " + str(byWho))

func _die(reason: String) -> void:
	if self.is_dead: return
	
	self.is_dead = true
	self.is_alive = false
	self.time_died = OS.get_ticks_msec()
	self.time_cleanup = self.time_died + (1000 * 5)
	$EachSecondTimer.stop()

	$Particles2D.emitting = false
	$CollisionShape2D.disabled = true
	
	print(self, " died: ", reason)

	var tween = $Tween

	tween.interpolate_property(
		self,
		"speed",
		self.speed,
		0,
		0.6,
		tween.TRANS_SINE,
		tween.EASE_OUT
	)
	tween.interpolate_property(
		$CollisionShape2D,
		"scale",
		$CollisionShape2D.scale,
		Vector2.ZERO,
		0.6,
		tween.TRANS_SINE,
		tween.EASE_OUT
	)
	tween.start()


func _on_BlubBot_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_LEFT \
	and event.is_pressed():
		self.bite(self, 500)
		self.speed = rand_range(min_speed, max_speed)
		self.direction = Vector2(rand_range(-1, 1), rand_range(-1, 1))


func _on_EachSecondTimer_timeout():
	if self.is_dead: return
	
	if is_meat:
		self._take_energy_die(energy_loss_per_second * 20, "time")
	else:
		self._take_energy_die(energy_loss_per_second, "time")
