extends Viewport

export (int) var current_pointer_id = 1

var current_bot: Node = null

func _unhandled_key_input(event):
	var id: int = 1
	if event.scancode == KEY_1:
		id = 1
	elif event.scancode == KEY_2:
		id = 2
	elif event.scancode == KEY_3:
		id = 3
	elif event.scancode == KEY_4:
		id = 4
	elif event.scancode == KEY_5:
		id = 5
	elif event.scancode == KEY_6:
		id = 6
	elif event.scancode == KEY_7:
		id = 7
	elif event.scancode == KEY_8:
		id = 8
	elif event.scancode == KEY_9:
		id = 9
	elif event.scancode == KEY_0:
		id = 0
	else: return
	
	#if current_pointer_id == id: return
	
	current_pointer_id = id
	
	print("Updated pointer to " + str(current_pointer_id))

	if current_pointer_id == 1:
		remove_current_bot()
		get_parent().hide()
	else:
		get_parent().show()
		if current_pointer_id == 2:
			replace_current_bot("res://Bots/Krik/KrikBot.tscn")
		elif current_pointer_id == 3:
			replace_current_bot("res://Bots/Smoosh/SmooshBot.tscn")
		elif current_pointer_id == 4:
			replace_current_bot("res://Bots/Vin/VinBot.tscn")	

func remove_current_bot() -> void:
	if current_bot == null: return
	
	$TileMap.remove_child(current_bot)
	current_bot.queue_free()
	current_bot = null

func replace_current_bot(path: String) -> void:
	remove_current_bot()
	
	var newBot = load(path).instance()
	
	var map = get_parent().get_parent().get_parent()
	
	if newBot.bot_type in map.all_high_score_bots:
		newBot.parent_bot = map.all_high_score_bots[newBot.bot_type][0]
		newBot.perfect_clone = true
	
	newBot.scale = Vector2(1.5, 1.5)
	newBot.show_debug_lines = true
	newBot.perfect_clone = true

	$TileMap.add_child(newBot)
	
	#newBot.ui_layer = $UILayer
	newBot.position = $TileMap/SpawnLocation.position
	current_bot = newBot
