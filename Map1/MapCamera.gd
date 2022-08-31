extends Camera2D


# Lower cap for the `_zoom_level`.
export var min_zoom := 0.05
# Upper cap for the `_zoom_level`.
export var max_zoom := 1.0
# Controls how much we increase or decrease the `_zoom_level` on every turn of the scroll wheel.
export var zoom_factor := 0.03
# Duration of the zoom's tween animation.
export var zoom_duration := 0.05

export var pan_cam_mode := false

# The camera's target zoom level.
var _zoom_level := 1.0 setget _set_zoom_level

var window_size = null
var last_mouse_pos = null

# We store a reference to the scene's tween node.
onready var tween: Tween = $Tween

func _ready():
	window_size = get_viewport_rect().size
	get_tree().get_root().connect("size_changed", self, "window_size_changed")

func _process(delta):
	if not self.pan_cam_mode: return
	if last_mouse_pos == null: return
	
	var mouse_pos = get_viewport().get_mouse_position()
	
	var mouse_delta = last_mouse_pos - mouse_pos
	
	self.position += mouse_delta
	
	last_mouse_pos = mouse_pos

func window_size_changed():
	return
	var old_size = self.window_size
	var new_size = get_viewport_rect().size	
	
	var delta = new_size / old_size
	
	if delta == Vector2.ONE: return

	var delta_float = (delta.x + delta.y) / 2

	var old_zoom = _zoom_level
	
	var new_zoom = old_zoom / delta_float
	
	_set_zoom_level(new_zoom)
	
	self.window_size = new_size

	print("Resizing from ", old_size, " to ", new_size, " . Change of " , delta, " Setting zoom from ", old_zoom, " to ", new_zoom)
	print("Size change delta: ", delta_float)
	print("Old zoom: ", old_zoom)
	print("New zoom: ", new_zoom)

func _set_zoom_level(value: float) -> void:
	# We limit the value between `min_zoom` and `max_zoom`
	_zoom_level = clamp(value, min_zoom, max_zoom)
	# Then, we ask the tween node to animate the camera's `zoom` property from its current value
	# to the target zoom level.
	tween.interpolate_property(
		self,
		"zoom",
		zoom,
		Vector2(_zoom_level, _zoom_level),
		zoom_duration,
		tween.TRANS_SINE,
		# Easing out means we start fast and slow down as we reach the target value.
		tween.EASE_OUT
	)
	tween.start()

func _unhandled_input(event):
	if event.is_action_pressed("zoom_in"):
		# Inside a given class, we need to either write `self._zoom_level = ...` or explicitly
		# call the setter function to use it.
		_set_zoom_level(_zoom_level - zoom_factor)
	if event.is_action_pressed("zoom_out"):
		_set_zoom_level(_zoom_level + zoom_factor)
	if event.is_action_pressed("toggle_pan_cam_mode"):
		self.pan_cam_mode = true
		self.last_mouse_pos = get_viewport().get_mouse_position()
		print("toggle cam pan on")
	if event.is_action_released("toggle_pan_cam_mode"):
		self.pan_cam_mode = false
		self.last_mouse_pos = null
		print("toggle cam pan off")
