extends Node2D

const blue_overlay_border_color = Color(0.2, 0.2, 0.8, 0.8)
const blue_overlay_color = Color(0.2, 0.2, 1, 0.2)

const red_overlay_border_color = Color(0.8, 0.2, 0.2, 0.8)
const red_overlay_color = Color(2, 0.2, 0.2, 0.1)

const green_overlay_border_color = Color(0.2, 0.8, 0.2, 0.8)
const green_overlay_color = Color(0.2, 2, 0.2, 0.1)

export (bool) var show_spawn_debug_layer = false
export (bool) var show_health_bars_layer = false

export (Font) var fonta

var last_redraw = 0

func _ready():
	var screen_count = OS.get_screen_count()
	
	if screen_count == 1: return
	
	var position = OS.get_screen_position(0)
	var size = OS.get_screen_size(0)
	
	OS.window_size = size
	OS.window_position = position
	OS.window_fullscreen = true

func _process(delta):
	if Input.is_action_just_pressed("toggle_spawn_debug_layer"):
		self.show_spawn_debug_layer = self.show_spawn_debug_layer == false

	if Input.is_action_just_pressed("toggle_health_bars"):
		self.show_health_bars_layer = self.show_health_bars_layer == false

	if OS.get_ticks_msec() >= (10) + last_redraw:
		update()

func _draw():
	#draw_tilemap_area()
	if show_spawn_debug_layer:
		draw_spawn_area()
		draw_historical_spawn_locations()
		draw_historical_food_spawn_locations()
	
	if self.show_health_bars_layer:
		draw_all_health_bars()

	last_redraw = OS.get_ticks_msec()

func draw_tilemap_area():
	var map = $"../TileMap"
	
	var mapTileRect = map.get_used_rect()
	
	var mapRect = Rect2(\
		map.map_to_world(mapTileRect.position),\
		map.map_to_world(mapTileRect.size)\
	)
	
	draw_rect(mapRect, blue_overlay_color, true)
	draw_rect(mapRect, blue_overlay_border_color, false, 2)

func draw_spawn_area():
	var map = get_parent()
	
	#var tiles = map.get_spawn_tiles()
	
	#for tile in tiles:
	#	draw_rect(tile, red_overlay_color, true)
	#	draw_rect(tile, red_overlay_border_color, false, 2)
	
	var mapRect = map.get_spawn_rect()
	
	draw_rect(mapRect, red_overlay_color, true)
	draw_rect(mapRect, red_overlay_border_color, false, 1)

func draw_all_health_bars():
	var map = $"../TileMap"
	
	var bots = map.get_tree().get_nodes_in_group("bot")
	
	for bot in bots:
		var top_left = Vector2(bot.position.x - 5, bot.position.y - 5)
		var full_rect = Rect2(top_left, Vector2(10, 1))
		var energy_percent = float(bot.energy) / bot.max_energy
		var ew = (full_rect.size.x - 2) * energy_percent
		var prect = Rect2(Vector2(top_left.x + 0.25, top_left.y + 0.25), Vector2(ew, 0.5))
		
		if bot.energy > 0.01:
			draw_rect(full_rect, red_overlay_color, true)
			draw_rect(full_rect, red_overlay_border_color, false, 1)
			draw_rect(prect, green_overlay_color, true)
			draw_rect(prect, green_overlay_border_color, false, 1)
		
		var str_energy = "%10.3f" % bot.energy
		#draw_string(fonta, top_left, str_energy + "/" + str(bot.max_energy), green_overlay_border_color)

func draw_historical_spawn_locations() -> void:
	var map = get_parent()
	
	for loc in map.spawn_locations:
		var rect = Rect2(loc, Vector2(1, 1))
		draw_rect(rect, green_overlay_border_color, true)

func draw_historical_food_spawn_locations() -> void:
	var map = get_parent()
	
	for loc in map.food_spawn_locations:
		var rect = Rect2(loc, Vector2(1, 1))
		draw_rect(rect, red_overlay_border_color, true)
