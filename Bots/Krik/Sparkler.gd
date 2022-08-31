extends KinematicBody2D

export (int) var speed = 80

var destination = null
var destination_obj = null

onready var start_time = OS.get_ticks_msec()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	var ohsofast = self.speed * delta
	if self.destination != null:
		var direction = self.destination - self.position
		direction = direction.normalized()
		
		var velocity = direction * speed * delta
		
		var collision = move_and_collide(velocity)
		
		if collision:
			if collision.collider == destination_obj:
				self.get_parent().remove_child(self)
				self.queue_free()
