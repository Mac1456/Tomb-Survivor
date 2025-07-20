extends Node2D
class_name MultiplayerManager

# Map size configurations
enum MapSize {
	SMALL,   # 1-2 players
	MEDIUM,  # 3 players  
	LARGE    # 4 players
}

# Map size definitions
const MAP_SIZES = {
	MapSize.SMALL: Vector2(1000, 600),
	MapSize.MEDIUM: Vector2(1400, 900),
	MapSize.LARGE: Vector2(1800, 1200)
}

# Multiplayer state
var network_manager: NetworkManager = null
var player_instances: Dictionary = {}  # player_id -> player_node
var player_cameras: Dictionary = {}     # player_id -> camera_node
var main_viewport: SubViewport = null
var current_map_size: Vector2 = Vector2(1200, 800)
var is_multiplayer: bool = false

# Signals
signal all_players_spawned()

func initialize_multiplayer(net_manager: NetworkManager):
	network_manager = net_manager
	is_multiplayer = true
	print("Multiplayer manager initialized")

func get_map_size_for_player_count(player_count: int) -> Vector2:
	match player_count:
		1, 2:
			return MAP_SIZES[MapSize.SMALL]
		3:
			return MAP_SIZES[MapSize.MEDIUM]
		4, _:
			return MAP_SIZES[MapSize.LARGE]

func setup_multiplayer_arena(player_count: int) -> Vector2:
	current_map_size = get_map_size_for_player_count(player_count)
	print("Setting up arena for ", player_count, " players - Size: ", current_map_size)
	return current_map_size

@rpc("any_peer", "call_local", "reliable") 
func spawn_multiplayer_player(player_id: int, character_index: int, spawn_position: Vector2):
	print("🎮 SPAWNING: Player ", player_id, " with character ", character_index, " at ", spawn_position)
	
	# Create player instance
	var player_scene = load("res://scenes/Player.tscn")
	var player_instance = player_scene.instantiate()
	
	# Set character data
	var character_data = CharacterData.get_character(character_index)
	if character_data:
		player_instance.set_character_data(character_data)
	
	# Set multiplayer properties
	player_instance.name = "Player_" + str(player_id)
	player_instance.set_multiplayer_authority(player_id)
	player_instance.position = spawn_position
	
	# Add to scene
	get_parent().add_child(player_instance)
	player_instances[player_id] = player_instance
	
	# Setup camera for this player
	setup_player_camera(player_id, player_instance)
	
	print("Player spawned: ", player_id, " at ", spawn_position)

func setup_player_camera(player_id: int, player_node: Node2D):
	# Only create camera for local player
	if player_id == multiplayer.get_unique_id():
		var camera = Camera2D.new()
		camera.name = "PlayerCamera_" + str(player_id)
		
		# Camera configuration
		camera.zoom = Vector2(1.0, 1.0)  # Adjust zoom based on map size
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 8.0
		camera.enabled = true
		
		# Set camera bounds to current arena size
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(current_map_size.x)
		camera.limit_bottom = int(current_map_size.y)
		camera.limit_smoothed = true
		
		# Adjust zoom based on map size
		var zoom_factor = 1200.0 / current_map_size.x  # Base zoom on original size
		camera.zoom = Vector2(zoom_factor, zoom_factor)
		
		# Add camera to player
		player_node.add_child(camera)
		camera.make_current()
		
		player_cameras[player_id] = camera
		print("Camera setup for local player: ", player_id, " with zoom: ", camera.zoom)

func get_spawn_positions(player_count: int) -> Array[Vector2]:
	var spawn_positions: Array[Vector2] = []
	var margin = 100.0  # Distance from edges
	
	match player_count:
		1:
			spawn_positions.append(current_map_size / 2)  # Center
		2:
			spawn_positions.append(Vector2(margin, current_map_size.y / 2))  # Left
			spawn_positions.append(Vector2(current_map_size.x - margin, current_map_size.y / 2))  # Right
		3:
			spawn_positions.append(Vector2(margin, margin))  # Top-left
			spawn_positions.append(Vector2(current_map_size.x - margin, margin))  # Top-right
			spawn_positions.append(Vector2(current_map_size.x / 2, current_map_size.y - margin))  # Bottom-center
		4:
			spawn_positions.append(Vector2(margin, margin))  # Top-left
			spawn_positions.append(Vector2(current_map_size.x - margin, margin))  # Top-right
			spawn_positions.append(Vector2(margin, current_map_size.y - margin))  # Bottom-left
			spawn_positions.append(Vector2(current_map_size.x - margin, current_map_size.y - margin))  # Bottom-right
	
	return spawn_positions

func create_multiplayer_barriers() -> Array[Vector2]:
	# Create tactical barriers based on map size
	var barriers: Array[Vector2] = []
	var center = current_map_size / 2
	var quarter_x = current_map_size.x / 4
	var quarter_y = current_map_size.y / 4
	
	# Add barriers for tactical gameplay
	barriers.append(Vector2(center.x, quarter_y))      # Top center
	barriers.append(Vector2(center.x, center.y * 1.5)) # Bottom center
	barriers.append(Vector2(quarter_x, center.y))      # Left center
	barriers.append(Vector2(quarter_x * 3, center.y))  # Right center
	
	# Additional barriers for larger maps
	if current_map_size.x > 1200:
		barriers.append(Vector2(quarter_x, quarter_y))      # Top-left
		barriers.append(Vector2(quarter_x * 3, quarter_y))  # Top-right
		barriers.append(Vector2(quarter_x, quarter_y * 3))  # Bottom-left
		barriers.append(Vector2(quarter_x * 3, quarter_y * 3))  # Bottom-right
	
	return barriers

func get_player_instance(player_id: int) -> Node2D:
	return player_instances.get(player_id, null)

func get_local_player() -> Node2D:
	var local_id = multiplayer.get_unique_id()
	return get_player_instance(local_id)

func cleanup_multiplayer():
	# Clean up player instances and cameras
	for player_id in player_instances:
		if player_instances[player_id]:
			player_instances[player_id].queue_free()
	
	player_instances.clear()
	player_cameras.clear()
	print("Multiplayer cleaned up")

# Network synchronization
@rpc("any_peer", "call_local", "reliable")
func sync_player_position(player_id: int, pos: Vector2):
	if player_id in player_instances:
		var player = player_instances[player_id]
		if player and player_id != multiplayer.get_unique_id():
			player.position = pos

@rpc("any_peer", "call_local", "reliable")
func sync_player_animation(player_id: int, animation: String):
	if player_id in player_instances:
		var player = player_instances[player_id]
		if player and player_id != multiplayer.get_unique_id():
			if player.has_method("play_animation"):
				player.play_animation(animation)
