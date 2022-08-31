extends Node2D

var bot_count = 40
var all_high_score_bots = {}
var spawn_locations = []
var food_spawn_locations = []
var selection: Node2D = null
var particle_cleanup_times = {}

func _ready():
	randomize()
	$EverySecondTimer.start()
	$SpawnBlubTimer.start()

func _process(delta):
	var bots = get_bots()
	var foods = self.get_food()
	
	if Input.is_action_just_pressed("full_reload"):
		get_tree().reload_current_scene()
	elif Input.is_action_just_pressed("kill_all"):
		for bot in bots:
			bot.die("kill_all")
	
	for bot in bots:
		if bot.isAlive == false and bot.despawn_time <= OS.get_ticks_msec():
			remove_bot(bot)
	
	for food in foods:
		if food.is_dead:
			if OS.get_ticks_msec() >= food.time_cleanup:
				$TileMap.remove_child(food)
				food.queue_free()

func get_bots():
	var bots = []
	for child in $TileMap.get_children():
		if child.is_in_group("bot"):
			bots.append(child)
	
	return bots

func remove_bot(bot):
	var is_high_score = store_bot_if_high_score(bot)
	$TileMap.remove_child(bot)
	if not is_high_score:
		bot.queue_free()

func get_active_bot_count():
	return len(get_bots())

func get_food():
	var food = []
	for child in $TileMap.get_children():
		if child.is_in_group("food"):
			food.append(child)
	
	return food

func get_food_count():
	return len(get_food())

func store_bot_if_high_score(bot) -> bool:
	var botkey = bot.bot_type
	
	if not all_high_score_bots.has(botkey):
		all_high_score_bots[botkey] = []
	
	var high_score_bots = all_high_score_bots[botkey]
	
	var hsbot_count = len(high_score_bots)
	
	if hsbot_count == 0:
		high_score_bots.append(bot)
		print("NEW HIGH SCORE " + botkey + " " + str(bot.score))
		return true

	var added_bot
	for i in range(0, hsbot_count):
		var hsb = high_score_bots[i]
		
		if hsb.score > bot.score: continue
		
		high_score_bots.insert(i, bot)
		if i == 0: print("NEW HIGH SCORE " + botkey + " " + str(bot.score))
		
		added_bot = true
		break
	
	if added_bot:
		while len(high_score_bots) > 10:
			var oldbot = high_score_bots.pop_back()
			#oldbot.queue_free()
	
	return added_bot

func create_bot():
	var newBot = null
	var bt = randf()
	if bt < 0.33:
		newBot = load("res://Bots/Smoosh/SmooshBot.tscn").instance()
	elif bt < 0.66:
		newBot = load("res://Bots/Vin/VinBot.tscn").instance()
	else:
		newBot = load("res://Bots/Krik/KrikBot.tscn").instance()

	if randf() < 0.75:
		var parent = random_high_score_bot(newBot.bot_type)
		newBot.parent_bot = parent

	newBot.ui_layer = $UILayer
	newBot.position = get_bot_spawn_location()
	$TileMap.add_child(newBot)
	var parts = $SpawnParticles.duplicate()
	add_temp_particles(parts, 5000, newBot.position)
	if self.spawn_locations == null:
		self.spawn_locations = []
	self.spawn_locations.append(newBot.position)

func random_high_score_bot(botkey):
	if not all_high_score_bots.has(botkey):
		return null
	
	var high_score_bots = all_high_score_bots[botkey]
	
	var hsb_count = len(high_score_bots)
	
	if hsb_count == 0:
		return null
		
	var rnd = rand_range(0, hsb_count - 1)
	var idx = int(rnd)
	return high_score_bots[idx]

func create_food():
	var newFood = load("res://Bots/Blub/BlubBot.tscn").instance()
	newFood.position = get_food_spawn_location()
	$TileMap.add_child(newFood)
	if self.food_spawn_locations == null:
		self.food_spawn_locations = []
	self.food_spawn_locations.append(newFood.position)

func get_map_rect():
	var map = $TileMap
	
	var mapTileRect = map.get_used_rect()
	
	var mapRect = Rect2(\
		map.map_to_world(mapTileRect.position),\
		map.map_to_world(mapTileRect.size)\
	)
	
	return mapRect

func get_bot_spawn_location() -> Vector2:
	var locations = []
	for child in $TileMap/SpawnPositions.get_children():
		if child.is_in_group("spawn_bot"):
			locations.append(child.position)
	
	return locations[randi() % locations.size()]

func get_food_spawn_location() -> Vector2:
	var locations = []
	for child in $TileMap/SpawnPositions.get_children():
		if child.is_in_group("spawn_food"):
			locations.append(child.position)
	
	return locations[randi() % locations.size()]

func get_spawn_tiles():
	var map = $TileMap
	
	var spawn_tile_id = map.tile_set.find_tile_by_name("Map1.png 4")
	var spawn_tiles = map.get_used_cells_by_id(spawn_tile_id)
	
	var tiles = []
	for cell in spawn_tiles:
		var tile_location = map.map_to_world(cell)
		var rect = Rect2(tile_location, map.cell_size)
		
		tiles.append(rect)
	
	return tiles

func get_spawn_rect():
	var map = $TileMap
	
	var spawn_tile_id = map.tile_set.find_tile_by_name("Map1.png 4")
	var spawn_tiles = map.get_used_cells_by_id(spawn_tile_id)
	
	var left = (1 << 31)
	var top = (1 << 31)
	var right = -(1 << 31)
	var bottom = -(1 << 31)
	
	for cell in spawn_tiles:
		if cell.x < left:
			left = cell.x	
		if cell.x > right:
			right = cell.x

		if cell.y < top:
			top = cell.y
		if cell.y > bottom:
			bottom = cell.y

	var top_left = Vector2(left, top)
	
	var world_top_left = map.map_to_world(top_left)
	
	var width = right - left + 1
	var height = bottom - top + 1
	
	var size = Vector2(width, height) * map.cell_size
	
	var world_spawn_rect = Rect2(world_top_left, size)
	
	# Add padding
	world_spawn_rect = world_spawn_rect.grow(-5)
	
	return world_spawn_rect

func random_empty_location():
	var spawn_tile_id = $TileMap.tile_set.find_tile_by_name("Map1.png 4")
	var spawn_rect = self.get_spawn_rect()
	
	var width = spawn_rect.size.x - spawn_rect.position.x
	var height = spawn_rect.size.y - spawn_rect.position.y
	
	#var ranx = randf() * width
	#var rany = randf() * height

	#print("spawn_size(", width, ", ", height, ") = ", "(", ranx, ", ", rany, ")")
	
	while true:
		var ran_loc = Vector2(\
			(randf() * width) + spawn_rect.position.x,\
			(randf() * height) + spawn_rect.position.y\
		)
		
		var ran_map_loc = $TileMap.world_to_map(ran_loc)
		
		var cell = $TileMap.get_cell(ran_map_loc.x, ran_map_loc.y)
		
		if cell == spawn_tile_id:
			#print("random location: ", ran_loc, " - ", ran_map_loc, " -> ", cell)
			return ran_loc

func follow_cam():
	$MapCamera.current = true

func add_temp_particles(particles: Particles2D, cleanup_time: int, position: Vector2) -> void:
	particles.position = position
	particles.restart()
	
	$TileMap.add_child(particles)
	
	particle_cleanup_times[particles] = OS.get_ticks_msec() + cleanup_time

func _on_EverySecondTimer_timeout():
	var particles = []
	for child in $TileMap.get_children():
		if child.is_in_group("temp_particle"):
			var cleanup_time = particle_cleanup_times[child]
			if cleanup_time < OS.get_ticks_msec():
				$TileMap.remove_child(child)
				child.queue_free()
	
	var child_count = $TileMap.get_child_count()
	if child_count > 1000:
		print("!! Tilemap has ", child_count, " children")	

func _on_SpawnBlubTimer_timeout():
	var i = 0
	for food in self.get_food():
		i = i + 1
		if i >= 1: break
		food.queue_free()
		$TileMap.remove_child(food)
		
	create_food()
	create_bot()
	create_bot()
	create_bot()
	create_bot()
	create_bot()

func _unhandled_input(event):
	if not event is InputEventMouseButton: return
	if not event.is_pressed(): return
	
	var select = $UILayer/ViewportContainer/SpawnSelectionLayer.current_bot
	
	if select == null: return
	
	if event.button_index == BUTTON_LEFT:
		print("spawn")
		var path = select.filename
		
		var newBot = load(path).instance()
		
		var map = self
		
		var spawn_location = $TileMap.get_local_mouse_position()
		
		newBot.parent_bot = select.parent_bot
		newBot.perfect_clone = true
		newBot.ui_layer = $UILayer
		newBot.position = spawn_location
		$TileMap.add_child(newBot)
		var parts = $SpawnParticles.duplicate()
		$TileMap.add_child(parts)
		parts.position = newBot.position
		parts.emitting = true
	pass
