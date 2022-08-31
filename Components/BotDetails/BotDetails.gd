extends WindowDialog

var bot: Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	var list = $"VBoxContainer/ItemList"
	
	list.add_item("type:")
	list.add_item(bot.bot_type)
	list.add_item("age:")
	list.add_item(str(bot.age))
	list.add_item("generation:")
	list.add_item(str(bot.generation))
	list.add_item("energy:")
	var str_energy = "%10.3f" % bot.energy
	list.add_item(str_energy)
	list.add_item("max energy:")
	list.add_item(str(bot.max_energy))
	list.add_item("velocity:")
	var str_velocity = "(" + ("%4.2f" % bot.velocity.x) + ", " + ("%4.2f" % bot.velocity.y) + ")"
	list.add_item(str_velocity)
	list.add_item("speed %:")
	var str_speed = ("%3.2f" % (bot.speed_percent * 100))
	list.add_item(str_speed)
	list.add_item("distance:")
	list.add_item(str(bot.total_distance))
	list.add_item("baby count:")
	list.add_item(str(bot.baby_count))
	list.add_item("Total Energy +:")
	list.add_item(str(bot.total_energy_gained))
	list.add_item("score:")
	list.add_item(str(bot.score))
	
	self.window_title = bot.bot_type
	
	$VBoxContainer/CheckShowDebugLines.pressed = bot.show_debug_lines

func _process(delta):
	if not self.visible: return

	var list = $"VBoxContainer/ItemList"
	
	list.set_item_text(3, str(bot.age))
	
	list.set_item_text(5, str(bot.generation))
	
	var str_energy = "%6.3f" % bot.energy
	list.set_item_text(7, str_energy)
	
	var str_velocity = "(" + ("%4.2f" % bot.velocity.x) + ", " + ("%4.2f" % bot.velocity.y) + ")"
	list.set_item_text(11, str_velocity)
	
	var str_speed = str(int(bot.speed_percent * 100))
	list.set_item_text(13, str_speed)
	
	list.set_item_text(15, str(bot.total_distance))
	
	list.set_item_text(17, str(bot.baby_count))
	
	list.set_item_text(19, str(bot.total_energy_gained))
	
	list.set_item_text(21, str(bot.score))

func _on_CheckCamFollow_toggled(button_pressed):
	if button_pressed:
		bot.follow_cam()
	else:
		get_tree().current_scene.follow_cam()

func _on_BotDetails_modal_closed():
	#bot.get_tree().current_scene.follow_cam()
	pass

func _on_BotDetails_popup_hide():
	get_tree().current_scene.selection = null
	get_tree().current_scene.follow_cam()
	get_parent().remove_child(self)
	self.bot = null
	queue_free()

func _on_CheckShowDebugLines_toggled(button_pressed):
	if not "show_debug_lines" in bot:
		if button_pressed:
			$VBoxContainer/CheckShowDebugLines.toggle_mode = false
		return

	bot.show_debug_lines = button_pressed
