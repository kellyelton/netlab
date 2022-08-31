extends Node2D

const blue_overlay_border_color = Color(0.2, 0.2, 0.8, 0.8)
const blue_overlay_color = Color(0.2, 0.2, 1, 0.2)

const red_overlay_border_color = Color(0.8, 0.2, 0.2, 0.8)
const red_overlay_color = Color(2, 0.2, 0.2, 0.1)

const green_overlay_border_color = Color(0.2, 0.8, 0.2, 0.8)
const green_overlay_color = Color(0.2, 2, 0.2, 0.1)

export var selected: bool setget set_selected, get_selected

func _process(delta):
	$Area2D/CollisionShape2D.disabled = get_selected()
	
	update()

func _draw():
	if not get_selected(): return
	
	var collision_shape = $"Area2D/CollisionShape2D"
	
	var shape :RectangleShape2D = collision_shape.shape
	
	var rect = Rect2(Vector2(-(shape.extents.x / 2), -(shape.extents.y / 2)), shape.extents)

	var rect2 = rect.grow(0.8)

	draw_rect(rect, green_overlay_color, true)
	draw_rect(rect2, green_overlay_border_color, false, 1, true)

func set_selected(param1) -> void:
	if not get_tree(): return
	var is_selected = self.get_selected()
	if is_selected == param1: return
	
	var previous_selection = get_tree().current_scene.selection
	
	if param1:
		get_tree().current_scene.selection = self.get_parent()
		if self.get_parent().has_method("_on_selected"):
			self.get_parent()._on_selected()
	else:
		get_tree().current_scene.selection = null

	if not previous_selection == null:
		previous_selection.update()

func get_selected() -> bool:
	if not get_tree(): return false
	var global_selection = get_tree().current_scene.selection
	var is_globally_selected = global_selection == self.get_parent()
	return is_globally_selected

func _on_Area2D_input_event(viewport, event, shape_idx):
	if not event is InputEventMouseButton: return
	if not event.is_pressed(): return
	
	if event.button_index == BUTTON_LEFT:
		set_selected(true)
