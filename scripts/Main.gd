extends Node2D

# Performance-optimized game setup
const ARENA_SIZE = Vector2(1600, 1000)  # Large arena supporting 1-4 players
const WALL_THICKNESS = 32
const MAX_ENTITIES = 50  # Performance cap

# Multiplayer support
# Simplified multiplayer - no complex manager needed
var multiplayer_players: Array = []
var network_manager: NetworkManager = null
var is_multiplayer_game: bool = false
var current_arena_size: Vector2 = ARENA_SIZE

# Game Mode System
enum GameMode {
	DEBUG,
	PLAYABLE
}

var current_game_mode: GameMode = GameMode.PLAYABLE  # Default to playable mode
var game_paused: bool = false
var game_over: bool = false

# Round System
var current_round: int = 1
var enemies_to_spawn_this_round: int = 0
var enemies_spawned_this_round: int = 0
var round_completed: bool = false
var round_timer: float = 0.0
var between_rounds: bool = false
var between_round_duration: float = 3.0
var spawn_timer: float = 0.0
var spawn_interval: float = 1.5  # Seconds between enemy spawns

# Enemy synchronization
var next_enemy_id: int = 1  # Global unique enemy ID for multiplayer sync

# Round UI System
var round_ui_canvas: CanvasLayer = null
var round_label: Label = null
var game_over_ui_canvas: CanvasLayer = null
var game_over_container: Control = null

# Combat constants
const MELEE_ATTACK_RANGE = 50.0
const MELEE_ATTACK_DAMAGE = 25.0

# Character-specific cooldown management
var character_cooldowns: Dictionary = {}

func get_character_cooldown(character_name: String, ability_type: String) -> float:
	var key = character_name + "_" + ability_type
	if character_cooldowns.has(key):
		return max(0.0, character_cooldowns[key])
	return 0.0

func set_character_cooldown(character_name: String, ability_type: String, cooldown_time: float):
	var key = character_name + "_" + ability_type
	character_cooldowns[key] = cooldown_time
	print("🕐 Set cooldown for ", character_name, " ", ability_type, ": ", cooldown_time, "s")

func _update_cooldowns(delta: float):
	# Reduce all active cooldowns
	for key in character_cooldowns.keys():
		if character_cooldowns[key] > 0:
			character_cooldowns[key] -= delta
			if character_cooldowns[key] <= 0:
				character_cooldowns[key] = 0.0

# Projectile type definitions
enum ProjectileType {
	ARROW,
	FIREBALL,
	HOMING_ARROW,  # Huntress special ability
	ARCANE_ORB,    # Wizard special ability
	DIVINE_ENERGY, # Knight special ability
	BLOOD_WAVE,    # Berserker special ability
	METEOR         # Ultimate abilities
}

# Projectile stats by type
const PROJECTILE_STATS = {
	ProjectileType.ARROW: {
		"speed": 600.0,
		"damage": 20.0,
		"sprite_path": "res://assets/arrow.svg",
		"size": Vector2(24, 8),
		"collision_radius": 4.0,
		"homing": false,
		"piercing": false,
		"explosion_radius": 0.0
	},
	ProjectileType.FIREBALL: {
		"speed": 300.0,
		"damage": 45.0,
		"sprite_path": "res://assets/fireball.svg",
		"size": Vector2(12, 12),
		"collision_radius": 6.0,
		"homing": false,
		"piercing": false,
		"explosion_radius": 0.0
	},
	ProjectileType.HOMING_ARROW: {
		"speed": 500.0,
		"damage": 85.0,
		"sprite_path": "res://assets/arrow.svg",
		"size": Vector2(28, 10),
		"collision_radius": 5.0,
		"homing": true,
		"piercing": true,
		"explosion_radius": 0.0,
		"homing_strength": 150.0,
		"pierce_count": 3
	},
	ProjectileType.ARCANE_ORB: {
		"speed": 250.0,
		"damage": 90.0,
		"sprite_path": "res://assets/fireball.svg",
		"size": Vector2(20, 20),
		"collision_radius": 10.0,
		"homing": false,
		"piercing": false,
		"explosion_radius": 60.0,
		"explosion_damage": 50.0
	},
	ProjectileType.DIVINE_ENERGY: {
		"speed": 0.0,
		"damage": 35.0,
		"sprite_path": "res://assets/fireball.svg",
		"size": Vector2(50, 50),
		"collision_radius": 80.0,
		"homing": false,
		"piercing": false,
		"explosion_radius": 0.0,
		"heal_amount": 40.0,
		"duration": 3.0
	},
	ProjectileType.BLOOD_WAVE: {
		"speed": 0.0,
		"damage": 60.0,
		"sprite_path": "res://assets/fireball.svg",
		"size": Vector2(40, 40),
		"collision_radius": 120.0,
		"homing": false,
		"piercing": false,
		"explosion_radius": 0.0,
		"duration": 2.0
	},
	ProjectileType.METEOR: {
		"speed": 800.0,
		"damage": 150.0,
		"sprite_path": "res://assets/fireball.svg",
		"size": Vector2(30, 30),
		"collision_radius": 15.0,
		"homing": false,
		"piercing": false,
		"explosion_radius": 100.0,
		"explosion_damage": 75.0
	}
}

# Player movement constants
const DODGE_ROLL_SPEED = 600.0
const DODGE_ROLL_DURATION = 0.3
const DODGE_ROLL_COOLDOWN = 1.0

# Core game objects
var player: Player
var camera: Camera2D
var arena_bounds: Array = []

# Selected character data (Step 3)
var selected_character: CharacterData.Character = null

# Combat system
var enemies: Array = []
var projectiles: Array = []
var pickups: Array = []
var enemies_container: Node2D
var projectiles_container: Node2D
var pickups_container: Node2D

# Enemy scaling system
var game_time: float = 0.0
var enemy_scale_factor: float = 1.0

# Enemy scene reference
var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")

# Background system
var background_sprite: Sprite2D

# Fixed background asset - cave background only
var background_asset: String = "res://assets/backgrounds/cave_background.png"

# Final background color choice
var background_color: Color = Color(0.15, 0.15, 0.15, 1.0)  # Brighter Black

# Final barrier layout
var barriers_container = null  # Reference to barriers container

# Boss system
var current_boss = null
var boss_health_bar: ProgressBar = null
var boss_health_bar_container: Control = null
var boss_name_label: Label = null
var boss_ui_canvas: CanvasLayer = null
var boss_is_active: bool = false

# HUD Cooldown System
var hud_canvas: CanvasLayer = null
var hud_container: Control = null
var cooldown_icons: Dictionary = {}
var cooldown_progress_bars: Dictionary = {}
var cooldown_labels: Dictionary = {}

# Performance tracking
var entity_count: int = 0
var frame_time_accumulator: float = 0.0

# Player scene reference
var player_scene: PackedScene = preload("res://scenes/Player.tscn")

func _ready():
	print("🎮 Main.gd ready - Node path: ", get_path())
	print("🎮 Parent node: ", get_parent().name if get_parent() else "No parent")
	
	# Add to main group for easy reference
	add_to_group("main")
	
	print("=== Tomb Survivor - Game Mode & Round System ===")
	print("Current Game Mode: ", GameMode.keys()[current_game_mode])
	
	# Set up input actions for the new system
	setup_input_actions()
	
	# Default character if none selected
	if not selected_character:
		selected_character = CharacterData.get_character(0)
	
	# Initialize the game system
	# NOTE: Game setup now handled by set_selected_character() based on multiplayer mode
	# Do not auto-setup here to avoid conflicts with multiplayer

func create_background():
	print("Creating final background system...")
	
	# Create background sprite
	background_sprite = Sprite2D.new()
	background_sprite.name = "Background"
	background_sprite.z_index = -10  # Behind everything
	
	# Load the cave background
	var texture = load(background_asset)
	if texture:
		background_sprite.texture = texture
		print("✨ Loaded cave background successfully")
	else:
		print("❌ Failed to load cave background")
		return
	
	# Position background at center of arena (use dynamic size for multiplayer)
	var arena_size = current_arena_size if is_multiplayer_game else ARENA_SIZE
	background_sprite.position = arena_size / 2
	
	# Scale background to cover arena dynamically
	var scale_factor = max(arena_size.x / 600.0, arena_size.y / 400.0)  # Base scale calculation
	background_sprite.scale = Vector2(scale_factor, scale_factor)
	
	# Apply final background color
	background_sprite.modulate = background_color
	print("🎨 Applied final background color: Brighter Black")
	
	add_child(background_sprite)
	print("Background system created with final cave background")



func setup_input_actions():
	# Define input actions for character controls
	if not InputMap.has_action("move_up"):
		InputMap.add_action("move_up")
		var event = InputEventKey.new()
		event.keycode = KEY_W
		InputMap.action_add_event("move_up", event)
	
	if not InputMap.has_action("move_down"):
		InputMap.add_action("move_down")
		var event = InputEventKey.new()
		event.keycode = KEY_S
		InputMap.action_add_event("move_down", event)
	
	if not InputMap.has_action("move_left"):
		InputMap.add_action("move_left")
		var event = InputEventKey.new()
		event.keycode = KEY_A
		InputMap.action_add_event("move_left", event)
	
	if not InputMap.has_action("move_right"):
		InputMap.add_action("move_right")
		var event = InputEventKey.new()
		event.keycode = KEY_D
		InputMap.action_add_event("move_right", event)
	
	if not InputMap.has_action("primary_attack"):
		InputMap.add_action("primary_attack")
		var event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("primary_attack", event)
	
	if not InputMap.has_action("special_ability"):
		InputMap.add_action("special_ability")
		var event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("special_ability", event)
	
	if not InputMap.has_action("ultimate_ability"):
		InputMap.add_action("ultimate_ability")
		var event = InputEventKey.new()
		event.keycode = KEY_R
		InputMap.action_add_event("ultimate_ability", event)
	
	if not InputMap.has_action("dodge_roll"):
		InputMap.add_action("dodge_roll")
		var event = InputEventKey.new()
		event.keycode = KEY_SPACE
		InputMap.action_add_event("dodge_roll", event)

func set_selected_character(character: CharacterData.Character):
	selected_character = character
	print("Game received selected character: ", character.name)
	print("🔍 DEBUG: is_multiplayer_game = ", is_multiplayer_game)
	print("🔍 DEBUG: player exists = ", player != null)
	if network_manager:
		print("🔍 DEBUG: network_manager.is_host = ", network_manager.is_host)
	
	# If game hasn't been set up yet, set it up now
	if not player:
		if is_multiplayer_game:
			if network_manager and network_manager.is_host:
				print("🏠 HOST: Setting up multiplayer game...")
				setup_multiplayer_game()
			else:
				print("👥 CLIENT: Setting up client multiplayer environment...")
				# Clients need their own environment setup but don't spawn enemies
				setup_multiplayer_client_game()
		else:
			print("🎮 SINGLE PLAYER: Setting up performance optimized game")
			setup_performance_optimized_game()
	else:
		# Update existing player with new character
		print("🔄 UPDATING: Existing player with new character")
		player.set_character_data(selected_character)

func set_multiplayer_mode(multiplayer: bool, net_manager):
	is_multiplayer_game = multiplayer
	print("🔧 SETTING MULTIPLAYER MODE: ", multiplayer)
	if multiplayer and net_manager:
		network_manager = net_manager
		print("🌐 Main scene set to multiplayer mode")
		print("🔍 DEBUG: network_manager.is_host = ", network_manager.is_host)
		
		# Clients wait for RPC setup (don't setup immediately)
		if not network_manager.is_host:
			print("👥 CLIENT: Will set up environment when RPC received...")
	else:
		print("🎮 Main scene set to single player mode")

func setup_multiplayer_client_environment():
	print("👥 CLIENT: Setting up multiplayer client environment...")
	
	# Set large arena size for multiplayer
	current_arena_size = ARENA_SIZE
	
	# Create game systems (clients render same arena as host)
	create_background()
	create_multiplayer_arena()
	create_combat_containers()
	create_boss_ui()
	create_hud_cooldown_system()
	
	print("👥 CLIENT: Environment ready - Arena size: ", current_arena_size)

func setup_multiplayer_client_game():
	print("�� CLIENT: Setting up peer-to-peer multiplayer client...")
	
	# Set large arena size for multiplayer  
	current_arena_size = ARENA_SIZE
	
	# Create rendering systems (clients render same as host)
	create_background()
	create_multiplayer_arena()
	create_combat_containers()
	create_boss_ui()
	create_hud_cooldown_system()
	
	# Create temporary camera (will be replaced when player spawns)
	create_camera()
	
	# Initialize shared session - will receive seed from host
	print("🤝 PEER: Client ready for peer-to-peer session")
	print("🤝 PEER: Arena size: ", current_arena_size)

func setup_multiplayer_game():
	print("🏠 HOST: Setting up peer-to-peer multiplayer game...")
	
	# Get player count (default to 2 for safety)
	var player_count = network_manager.get_player_count() if network_manager else 2
	print("🤝 PEER: Player count = ", player_count)
	
	# Set large arena size for multiplayer
	current_arena_size = ARENA_SIZE
	
	# Create game systems for multiplayer
	create_background()
	create_multiplayer_arena()
	create_combat_containers()
	create_boss_ui()
	create_hud_cooldown_system()
	
	print("🤝 PEER: Arena created - Size: ", current_arena_size)
	
	# Initialize shared session for deterministic gameplay
	initialize_shared_session()
	
	# Tell clients to set up their rendering, then spawn all players directly
	if network_manager and network_manager.is_host:
		print("🤝 PEER: Notifying other players to set up...")
		network_manager.join_multiplayer_game.rpc()
		
		# Give clients time to set up, then spawn everyone
		await get_tree().create_timer(1.0).timeout
		print("🤝 PEER: Spawning all players...")
		spawn_all_multiplayer_players()
		
		# Start game systems after spawning
		await get_tree().create_timer(0.5).timeout
		print("🤝 PEER: Starting shared game systems...")
		setup_round_system()
		setup_game_mode()
		print("🤝 PEER: Peer-to-peer session active!")

func create_multiplayer_arena():
	print("Creating multiplayer arena with size: ", current_arena_size)
	
	# Create arena container
	var arena_container = Node2D.new()
	arena_container.name = "MultiplayerArena"
	add_child(arena_container)
	
	# Create walls using dynamic arena size
	create_multiplayer_wall_boundaries(arena_container)
	create_multiplayer_tactical_barriers(arena_container)
	
	print("Multiplayer arena created with optimized collision system")

func create_multiplayer_wall_boundaries(parent: Node2D):
	var walls_container = Node2D.new()
	walls_container.name = "Walls"
	parent.add_child(walls_container)
	
	# Create boundary walls using current_arena_size
	var wall_positions = [
		{"pos": Vector2(0, 0), "size": Vector2(current_arena_size.x, WALL_THICKNESS)},  # Top
		{"pos": Vector2(0, current_arena_size.y - WALL_THICKNESS), "size": Vector2(current_arena_size.x, WALL_THICKNESS)},  # Bottom
		{"pos": Vector2(0, 0), "size": Vector2(WALL_THICKNESS, current_arena_size.y)},  # Left
		{"pos": Vector2(current_arena_size.x - WALL_THICKNESS, 0), "size": Vector2(WALL_THICKNESS, current_arena_size.y)}  # Right
	]
	
	for wall_data in wall_positions:
		create_optimized_wall(walls_container, wall_data.pos, wall_data.size)

func create_multiplayer_tactical_barriers(parent: Node2D):
	var barriers_container = Node2D.new()
	barriers_container.name = "Barriers"
	parent.add_child(barriers_container)
	
	# Create strategic barriers for large multiplayer arena
	var barrier_positions = [
		Vector2(current_arena_size.x * 0.25, current_arena_size.y * 0.25),  # Top-left quadrant
		Vector2(current_arena_size.x * 0.75, current_arena_size.y * 0.25),  # Top-right quadrant
		Vector2(current_arena_size.x * 0.25, current_arena_size.y * 0.75),  # Bottom-left quadrant
		Vector2(current_arena_size.x * 0.75, current_arena_size.y * 0.75),  # Bottom-right quadrant
		Vector2(current_arena_size.x * 0.5, current_arena_size.y * 0.5),   # Center statue
	]
	
	for pos in barrier_positions:
		if pos == Vector2(current_arena_size.x * 0.5, current_arena_size.y * 0.5):
			create_large_stone_statue(barriers_container, pos)  # Center is statue
		else:
			create_small_tombstone(barriers_container, pos)     # Corners are tombstones

# Simplified direct spawning for all players
func spawn_all_multiplayer_players():
	print("🏠 HOST: Spawning all players directly...")
	
	if not network_manager:
		print("Error: Network manager not initialized")
		return
	
	# Fixed spawn positions for up to 4 players 
	var spawn_positions = [
		Vector2(200, 300),   # Player 1: Left side
		Vector2(1400, 300),  # Player 2: Right side  
		Vector2(200, 700),   # Player 3: Bottom-left
		Vector2(1400, 700),  # Player 4: Bottom-right
	]
	
	var connected_players = network_manager.get_connected_players()
	var player_characters = network_manager.get_player_characters()
	
	var spawn_index = 0
	for player_id in connected_players.keys():
		if spawn_index < spawn_positions.size():
			var spawn_pos = spawn_positions[spawn_index]
			var character_index = player_characters.get(player_id, 0)
			
			# Create players directly on both host and client via simple RPC
			create_multiplayer_player.rpc(player_id, character_index, spawn_pos)
			spawn_index += 1
			
			print("🎮 Spawned player ", player_id, " at ", spawn_pos)

# Simple RPC to create a player on all clients
@rpc("any_peer", "call_local", "reliable") 
func create_multiplayer_player(player_id: int, character_index: int, spawn_pos: Vector2):
	print("🎮 Creating player ", player_id, " with character ", character_index, " at ", spawn_pos)
	
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
	player_instance.position = spawn_pos
	
	# Add to scene
	add_child(player_instance)
	multiplayer_players.append(player_instance)
	
	# Setup camera for local player only
	if player_id == multiplayer.get_unique_id():
		setup_multiplayer_camera(player_instance)
	
	print("✅ Player ", player_id, " created successfully at ", spawn_pos)

func setup_multiplayer_camera(player_node: Node2D):
	print("📷 Setting up camera for local player")
	
	# Remove existing camera if any
	var existing_cameras = get_tree().get_nodes_in_group("camera")
	for cam in existing_cameras:
		cam.queue_free()
	
	# Create new camera attached to player
	var camera = Camera2D.new()
	camera.name = "MultiplayerCamera" 
	camera.add_to_group("camera")
	camera.zoom = Vector2(1.0, 1.0)  # Good zoom for large arena
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(current_arena_size.x)
	camera.limit_bottom = int(current_arena_size.y)
	
	player_node.add_child(camera)
	print("📷 Camera attached to player - Arena bounds: ", current_arena_size)

func setup_performance_optimized_game():
	# Create all nodes programmatically for guaranteed compatibility
	create_background()
	create_arena()
	create_player()
	create_camera()
	create_combat_containers()
	create_boss_ui()
	create_hud_cooldown_system()
	
	print("Step 3 systems initialized successfully!")
	print("Selected character: ", selected_character.name)
	print("Controls: WASD to move, Left Click to attack, Right Click for special ability")
	print("Additional: Spacebar for dodge roll, R for ultimate ability")
	if current_game_mode == GameMode.DEBUG:
		print("Debug Mode: 1 - Spawn Sword Skeleton, 2 - Spawn Archer Skeleton, 4 - Spawn Stone Golem")
		print("Debug Mode: 3 - Spawn Blue Witch Boss, ` - Toggle Debug Mode")
	print("Performance: Entity limit =", MAX_ENTITIES)

func setup_round_system():
	print("Setting up round system...")
	
	# Initialize round variables
	current_round = 1
	enemies_to_spawn_this_round = calculate_enemies_for_round(current_round)
	enemies_spawned_this_round = 0
	round_completed = false
	between_rounds = false
	round_timer = 0.0
	spawn_timer = 0.0
	
	# Create round UI
	create_round_ui()
	create_game_over_ui()
	
	# Start first round if in playable mode
	if current_game_mode == GameMode.PLAYABLE:
		start_new_round()
	
	print("Round system initialized. Starting Round: ", current_round)

func setup_game_mode():
	print("Setting up game mode: ", GameMode.keys()[current_game_mode])
	
	match current_game_mode:
		GameMode.DEBUG:
			print("DEBUG MODE ACTIVE - Manual enemy spawning enabled")
			print("Press ` to toggle between Debug and Playable modes")
		GameMode.PLAYABLE:
			print("PLAYABLE MODE ACTIVE - Round-based progression enabled")
			print("Press ` to toggle to Debug mode")

func create_arena():
	print("Creating performance-optimized arena...")
	
	# Create arena container
	var arena_container = Node2D.new()
	arena_container.name = "Arena"
	add_child(arena_container)
	
	# Create walls efficiently using StaticBody2D (performance optimized)
	create_wall_boundaries(arena_container)
	create_tactical_barriers(arena_container)
	# Safe zones removed - no more safe corners for more dynamic gameplay
	
	print("Arena created with optimized collision system")

func create_wall_boundaries(parent: Node2D):
	var walls_container = Node2D.new()
	walls_container.name = "Walls"
	parent.add_child(walls_container)
	
	# Create boundary walls (StaticBody2D for performance)
	var wall_positions = [
		{"pos": Vector2(0, 0), "size": Vector2(ARENA_SIZE.x, WALL_THICKNESS)},  # Top
		{"pos": Vector2(0, ARENA_SIZE.y - WALL_THICKNESS), "size": Vector2(ARENA_SIZE.x, WALL_THICKNESS)},  # Bottom
		{"pos": Vector2(0, 0), "size": Vector2(WALL_THICKNESS, ARENA_SIZE.y)},  # Left
		{"pos": Vector2(ARENA_SIZE.x - WALL_THICKNESS, 0), "size": Vector2(WALL_THICKNESS, ARENA_SIZE.y)}  # Right
	]
	
	for wall_data in wall_positions:
		create_optimized_wall(walls_container, wall_data.pos, wall_data.size)

func create_optimized_wall(parent: Node2D, pos: Vector2, size: Vector2):
	var wall = StaticBody2D.new()
	
	# Optimized collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.position = size / 2
	
	# Simple visual representation (performance-friendly)
	var visual = ColorRect.new()
	visual.size = size
	visual.color = Color(0.3, 0.2, 0.1, 1.0)  # Crypt brown
	
	# Optimized collision layers
	wall.collision_layer = 2  # Wall layer
	wall.collision_mask = 0   # Walls don't detect anything
	
	wall.add_child(collision)
	wall.add_child(visual)
	wall.position = pos
	parent.add_child(wall)
	
	# Track for performance monitoring
	entity_count += 1

func create_tactical_barriers(parent: Node2D):
	barriers_container = Node2D.new()
	barriers_container.name = "Barriers"
	parent.add_child(barriers_container)
	
	# Final barrier layout: 4 corner tombstones + 1 center statue
	var corner_tombstone_positions = [
		Vector2(250, 150),   # Top-left
		Vector2(950, 150),   # Top-right
		Vector2(250, 650),   # Bottom-left
		Vector2(950, 650),   # Bottom-right
	]
	
	var center_statue_position = Vector2(600, 400)  # Center
	
	# Create corner tombstones (smaller)
	for pos in corner_tombstone_positions:
		create_small_tombstone(barriers_container, pos)
	
	# Create center statue (bigger)
	create_large_stone_statue(barriers_container, center_statue_position)

# Old create_optimized_barrier function removed

# Final barrier creation functions
func create_large_stone_statue(parent: Node2D, pos: Vector2):
	var barrier = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Large stone statue for center - detailed SVG asset
	var size = Vector2(120, 160)
	shape.size = size
	collision.position = Vector2(size.x / 2, size.y / 2)
	collision.shape = shape
	
	# Load detailed stone statue SVG
	var sprite = Sprite2D.new()
	var texture = load("res://assets/environments/stone_statue.svg")
	if texture:
		sprite.texture = texture
		sprite.position = Vector2(size.x / 2, size.y / 2)  # Center the sprite
		print("✨ Loaded detailed stone statue SVG")
	else:
		print("❌ Failed to load stone statue SVG, using fallback")
		# Fallback to simple visual if SVG fails
		var fallback = ColorRect.new()
		fallback.size = size
		fallback.color = Color(0.5, 0.45, 0.4, 1.0)
		barrier.add_child(fallback)
	
	barrier.add_child(sprite)
	
	# Set collision properties
	barrier.collision_layer = 2
	barrier.collision_mask = 0
	barrier.add_child(collision)
	barrier.position = pos
	barrier.name = "StoneStatue"
	parent.add_child(barrier)
	
	entity_count += 1
	print("✨ Created enhanced stone statue at ", pos)

func create_small_tombstone(parent: Node2D, pos: Vector2):
	var barrier = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Small tombstone - detailed SVG asset
	var size = Vector2(50, 70)
	shape.size = size
	collision.position = Vector2(size.x / 2, size.y / 2)
	collision.shape = shape
	
	# Load detailed tombstone SVG
	var sprite = Sprite2D.new()
	var texture = load("res://assets/environments/tombstone.svg")
	if texture:
		sprite.texture = texture
		sprite.position = Vector2(size.x / 2, size.y / 2)  # Center the sprite
		print("✨ Loaded detailed tombstone SVG")
	else:
		print("❌ Failed to load tombstone SVG, using fallback")
		# Fallback to simple visual if SVG fails
		var fallback = ColorRect.new()
		fallback.size = size
		fallback.color = Color(0.45, 0.4, 0.35, 1.0)
		barrier.add_child(fallback)
	
	barrier.add_child(sprite)
	
	# Set collision properties
	barrier.collision_layer = 2
	barrier.collision_mask = 0
	barrier.add_child(collision)
	barrier.position = pos
	barrier.name = "Tombstone"
	parent.add_child(barrier)
	
	entity_count += 1
	print("✨ Created enhanced tombstone at ", pos)

# Old barrier creation functions removed - using only large stone statues and small tombstones

func create_player():
	print("Creating player with selected character: ", selected_character.name)
	
	# Create player from scene
	player = player_scene.instantiate()
	player.name = "Player"
	
	# Set character data
	player.set_character_data(selected_character)
	
	# Position player at center
	player.position = ARENA_SIZE / 2
	
	# Connect player signals
	player.health_changed.connect(_on_player_health_changed)
	player.character_died.connect(_on_player_died)
	player.ability_used.connect(_on_player_ability_used)
	
	add_child(player)
	entity_count += 1
	
	print("Player created: ", selected_character.name)

func create_camera():
	print("Creating optimized camera system...")
	
	# Camera is now part of the Player scene
	if player:
		camera = Camera2D.new()
		camera.name = "GameCamera"
		
		# Camera configuration
		camera.zoom = Vector2(1.2, 1.2)  # Slight zoom for better view
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 8.0
		camera.enabled = true
		
		# Set camera bounds to arena size
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(ARENA_SIZE.x)
		camera.limit_bottom = int(ARENA_SIZE.y)
		camera.limit_smoothed = true
		
		# Add camera to player for automatic following
		player.add_child(camera)
		camera.make_current()
		print("Camera attached to player with arena bounds: ", ARENA_SIZE)

func create_combat_containers():
	print("Creating combat containers...")
	
	# Container for enemies
	enemies_container = Node2D.new()
	enemies_container.name = "Enemies"
	add_child(enemies_container)
	
	# Container for projectiles
	projectiles_container = Node2D.new()
	projectiles_container.name = "Projectiles"
	add_child(projectiles_container)
	
	# Container for pickups (healing orbs, etc.)
	pickups_container = Node2D.new()
	pickups_container.name = "Pickups"
	add_child(pickups_container)
	
	print("Combat containers created")







func _physics_process(delta):
	# Skip game logic if game is over or paused
	if game_over or game_paused:
		return
	
	# Update cooldowns for all characters
	_update_cooldowns(delta)
	
	# Update projectiles
	update_projectiles(delta)
	
	# Update pickups (healing orbs)
	update_pickups(delta)
	
	# Update game time for tracking
	game_time += delta
	# Use round-based scaling instead of time-based (very subtle progression)
	enemy_scale_factor = 1.0 + floor((current_round - 1) / 3) * 0.1  # Increase by 10% every 3 rounds
	
	# CRITICAL MULTIPLAYER FIX: Only HOST runs game logic, clients receive updates
	if current_game_mode == GameMode.PLAYABLE:
		if is_multiplayer_game:
			if network_manager and network_manager.is_host:
				# HOST: Runs full game logic including round progression and enemy spawning
				if fmod(game_time, 5.0) < delta:
					print("🏠 HOST: Processing full game logic - Game Time: ", int(game_time), "s")
				handle_round_progression(delta)
				
				# Host syncs enemy positions frequently
				enemy_sync_timer += delta
				if enemy_sync_timer >= enemy_sync_interval:
					sync_all_enemy_positions()
					enemy_sync_timer = 0.0
			else:
				# CLIENT: Only handles local UI and waits for updates from host
				if fmod(game_time, 5.0) < delta:
					print("👥 CLIENT: Waiting for game updates from host...")
				# Client doesn't run round progression - waits for enemy spawns from host
		else:
			# Single player - handle normally
			if fmod(game_time, 5.0) < delta:
				print("⚙️ Single Player: Processing game logic - Game Time: ", int(game_time), "s")
			handle_round_progression(delta)
	else:
		# Debug mode
		if fmod(game_time, 5.0) < delta:
			print("🔧 Debug Mode: Game Time: ", int(game_time), "s")

# NEW: Position synchronization for enemies (more frequent and reliable)
@rpc("any_peer", "call_remote", "reliable")
func sync_enemy_position(enemy_id: int, pos: Vector2, velocity: Vector2, state_data: Dictionary):
	# Safety check for enemies container
	if not enemies_container:
		print("⚠️ PEER: enemies_container not found - cannot sync enemy position")
		return
		
	# Find enemy by deterministic ID and update position
	var enemy_name = "Enemy_" + str(enemy_id)
	var enemy_node = enemies_container.get_node_or_null(enemy_name)
	
	if enemy_node:
		# Update position with interpolation for smoother movement
		enemy_node.global_position = pos
		
		# Update velocity if enemy has the method
		if enemy_node.has_method("set_enemy_velocity"):
			enemy_node.set_enemy_velocity(velocity)
		
		# Update AI state for consistency
		if state_data.has("current_state") and enemy_node.has_method("set_current_state"):
			enemy_node.set_current_state(state_data.current_state)
		
		# Update animation state
		if state_data.has("animation") and enemy_node.has_method("play_sync_animation"):
			enemy_node.play_sync_animation(state_data.animation)
		
		print("🔄 PEER: Updated enemy ", enemy_id, " position to ", pos, " with state: ", state_data.get("current_state", "unknown"))
	else:
		print("⚠️ PEER: Enemy ", enemy_id, " not found for position sync")

# Update enemy sync to be more comprehensive
var enemy_sync_timer: float = 0.0
var enemy_sync_interval: float = 0.05  # Sync every 50ms for smoother movement

# Sync all enemy positions from host to clients (more comprehensive)
func sync_all_enemy_positions():
	if not (network_manager and network_manager.is_host):
		return  # Only host should sync
	
	var synced_count = 0
	for enemy in enemies:
		if is_instance_valid(enemy):
			var enemy_id = enemy.get_meta("enemy_id", 0)
			if enemy_id > 0:
				# Gather comprehensive enemy state
				var velocity = Vector2.ZERO
				if enemy.has_method("get_enemy_velocity"):
					velocity = enemy.get_enemy_velocity()
				else:
					velocity = enemy.velocity
				
				# Gather state data for synchronization
				var state_data = {}
				if enemy.has_method("get_current_state"):
					state_data.current_state = enemy.get_current_state()
				
				if enemy.has_method("get_current_animation"):
					state_data.animation = enemy.get_current_animation()
				
				# Send comprehensive sync
				sync_enemy_position.rpc(enemy_id, enemy.global_position, velocity, state_data)
				synced_count += 1
	
	# Only log when there are enemies to sync
	if synced_count > 0:
		print("🤝 HOST: Synced ", synced_count, " enemy positions to clients")

# NEW: Shared Random Number Generator for deterministic gameplay
var shared_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var multiplayer_session_seed: int = 0

func initialize_shared_session():
	# Create a shared random seed for deterministic gameplay
	multiplayer_session_seed = randi()  # Host generates seed
	shared_rng.seed = multiplayer_session_seed
	
	if is_multiplayer_game:
		# Share the seed with all players
		sync_session_seed.rpc(multiplayer_session_seed)
	
	print("🎲 Shared session initialized with seed: ", multiplayer_session_seed)

@rpc("any_peer", "call_local", "reliable")
func sync_session_seed(seed: int):
	multiplayer_session_seed = seed
	shared_rng.seed = seed
	print("🤝 PEER: Synchronized with session seed: ", seed)

# NEW: Deterministic position generation using shared RNG
func get_deterministic_spawn_position() -> Vector2:
	var margin = 100
	var x = shared_rng.randf_range(margin, ARENA_SIZE.x - margin)
	var y = shared_rng.randf_range(margin, ARENA_SIZE.y - margin)
	return Vector2(x, y)

# NEW: Sync critical game state from host to clients periodically
func sync_game_state_to_clients():
	if not is_multiplayer_game or not network_manager or not network_manager.is_host:
		return
	
	# Send game state every few seconds to keep clients in sync
	if fmod(game_time, 2.0) < 0.016:  # Every 2 seconds (approximately)
		sync_game_state_rpc.rpc(
			current_round,
			enemies_spawned_this_round,
			enemies_to_spawn_this_round,
			round_completed,
			between_rounds,
			round_timer,
			game_time
		)

# NEW: RPC to sync game state from host to clients
@rpc("any_peer", "call_remote", "reliable")
func sync_game_state_rpc(round_num: int, spawned: int, to_spawn: int, completed: bool, between: bool, timer: float, host_time: float):
	print("👥 CLIENT: Syncing game state from host - Round: ", round_num, " Time: ", int(host_time))
	
	# Update local game state to match host
	current_round = round_num
	enemies_spawned_this_round = spawned
	enemies_to_spawn_this_round = to_spawn
	round_completed = completed
	between_rounds = between
	round_timer = timer
	game_time = host_time  # Sync time with host to prevent drift
	
	# Update UI to match host state
	if round_label:
		if current_game_mode == GameMode.DEBUG:
			round_label.text = "Debug"
		else:
			round_label.text = "Round: " + str(current_round)

# NEW: RPC to sync individual enemy state from host to clients
@rpc("any_peer", "call_remote", "unreliable")
func sync_enemy_state_rpc(enemy_name: String, pos: Vector2, vel: Vector2, ai_state: int, health: float):
	# Find the enemy by name
	var enemy_node = enemies_container.get_node_or_null(enemy_name)
	if enemy_node:
		# Update position and velocity smoothly
		enemy_node.global_position = pos
		enemy_node.velocity = vel
		
		# Update AI state (for animation sync)
		if enemy_node.has_method("sync_ai_state"):
			enemy_node.ai_state = ai_state
		
		# Update health (for health bar sync)
		if enemy_node.has_method("sync_health_direct"):
			enemy_node.current_health = health

func _input(event):
	if not player:
		return
	
	# Skip input if game over (except for game over UI buttons)
	if game_over:
		return
	
	# Handle keyboard inputs
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_QUOTELEFT:  # Backtick key
				# Toggle debug mode
				toggle_debug_mode()
				return
			KEY_1, KEY_2, KEY_3, KEY_4:
				# Debug enemy spawning - only in debug mode
				if current_game_mode == GameMode.DEBUG:
					handle_debug_enemy_spawn(event.keycode)
				else:
					print("⚠️  Debug spawning only available in Debug Mode. Press D to toggle.")
				return
	
	# Handle combat inputs through player (always available)
	if event.is_action_pressed("primary_attack"):
		player.perform_primary_attack()
	elif event.is_action_pressed("special_ability"):
		player.perform_special_ability()
	elif event.is_action_pressed("ultimate_ability"):
		player.perform_ultimate_ability()
	elif event.is_action_pressed("dodge_roll"):
		player.perform_dodge_roll()
	elif event.is_action_pressed("ui_cancel"):
		if game_over:
			return  # Let game over UI handle this
		print("Escape pressed - returning to main menu")
		# Return to main menu (handled by GameManager)
		get_tree().change_scene_to_file("res://scenes/GameManager.tscn")

# Player attack handler - called by Player.gd
func handle_player_attack(attack_type: String, attack_position: Vector2, attack_range: float, damage: float, direction: Vector2 = Vector2.ZERO):
	if attack_type == "melee":
		handle_melee_attack(attack_position, attack_range, damage)
	elif attack_type == "ranged":
		handle_ranged_attack(attack_position, damage, direction)

# New directional attack handler for better combat feel
func handle_player_directional_attack(attack_type: String, attack_position: Vector2, attack_range: float, damage: float, direction: Vector2):
	if attack_type == "melee":
		# Find the attacking player based on position
		var character_name = ""
		var attacking_player = null
		
		# Check multiplayer players first
		for mp_player in multiplayer_players:
			if is_instance_valid(mp_player) and mp_player.global_position.distance_to(attack_position) < 10.0:
				attacking_player = mp_player
				break
		
		# Fall back to single player if not found
		if not attacking_player and player:
			attacking_player = player
		
		if attacking_player and attacking_player.character_data:
			character_name = attacking_player.character_data.name
		
		handle_directional_melee_attack(attack_position, attack_range, damage, direction, character_name)
	elif attack_type == "ranged":
		handle_ranged_attack(attack_position, damage, direction)

func handle_directional_melee_attack(attack_center: Vector2, attack_range: float, damage: float, attack_direction: Vector2, character_name: String = ""):
	# Create visual feedback for directional attack with character-specific effects
	create_directional_attack_visual(attack_center, attack_direction, attack_range, character_name)
	
	# Use physics-based collision detection for the cone area
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	# Create a circle shape for the attack area (we'll filter by angle later)
	var attack_shape = CircleShape2D.new()
	attack_shape.radius = attack_range
	query.shape = attack_shape
	query.transform = Transform2D(0, attack_center)
	query.collision_mask = 4  # Enemy layer
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query)
	
	print("⚔️ Directional attack at ", attack_center, " with range ", attack_range, " found ", results.size(), " potential targets")
	
	# Attack cone parameters
	var attack_angle = 60.0  # 60 degree cone for sword swing
	var attack_cone_rad = deg_to_rad(attack_angle)
	
	# Check each physics result against the attack cone
	for result in results:
		var body = result.collider
		if body and body.has_method("take_damage"):
			var to_enemy = body.position - attack_center
			var angle_to_enemy = to_enemy.normalized().angle_to(attack_direction)
			
			# Check if enemy is within attack cone
			if abs(angle_to_enemy) <= attack_cone_rad / 2:
				hit_enemy(body, damage)
				match character_name:
					"Berserker":
						print("💥 BERSERKER powerful strike hit ", body.name, " at ", body.position)
					"Knight":
						print("⚔️ KNIGHT quick slash hit ", body.name, " at ", body.position)
					_:
						print("Directional melee attack hit ", body.name, " at ", body.position)

func handle_melee_attack(attack_center: Vector2, attack_range: float, damage: float):
	# Create visual feedback for attack
	create_attack_visual(attack_center)
	
	# Use physics-based collision detection for accurate hits
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	# Create a circle shape for the attack area
	var attack_shape = CircleShape2D.new()
	attack_shape.radius = attack_range
	query.shape = attack_shape
	query.transform = Transform2D(0, attack_center)
	query.collision_mask = 4  # Enemy layer
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query)
	
	print("🗡️ Melee attack at ", attack_center, " with range ", attack_range, " found ", results.size(), " targets")
	
	for result in results:
		var body = result.collider
		if body and body.has_method("take_damage"):
			hit_enemy(body, damage)
			print("💥 Physics-based hit on ", body.name, " at ", body.position)

func handle_ranged_attack(start_pos: Vector2, damage: float, direction: Vector2):
	# Determine projectile type based on player character
	var projectile_type = ProjectileType.ARROW  # Default to arrow
	if player and player.character_data:
		match player.character_data.name:
			"Wizard":
				projectile_type = ProjectileType.FIREBALL
				print("🔥 Wizard firing HOMING FIREBALL!")
			"Huntress":
				projectile_type = ProjectileType.ARROW
				print("🏹 Huntress firing ARROW!")
			_:
				projectile_type = ProjectileType.ARROW
				print("🏹 Default character firing ARROW!")
	
	var projectile = create_projectile(start_pos, direction, damage, projectile_type)
	
	# Add homing abilities for wizard fireballs
	if player and player.character_data and player.character_data.name == "Wizard" and projectile:
		projectile.set_meta("homing", true)
		projectile.set_meta("homing_strength", 2.0)  # Strong homing force
		projectile.set_meta("max_turn_rate", 3.0)  # Fast turning ability
		print("🎯 Wizard fireball enhanced with HOMING capabilities!")

func create_projectile(start_pos: Vector2, direction: Vector2, damage: float, projectile_type: ProjectileType):
	var projectile = RigidBody2D.new()
	projectile.name = "Projectile"
	projectile.gravity_scale = 0  # No gravity for top-down
	
	# Get projectile stats
	var stats = PROJECTILE_STATS[projectile_type]
	
	# Projectile collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = stats.collision_radius
	collision.shape = shape
	projectile.add_child(collision)
	
	# Projectile visual using custom sprite
	var sprite = Sprite2D.new()
	sprite.texture = load(stats.sprite_path)
	sprite.position = Vector2.ZERO
	
	# Rotate sprite to face direction (except for stationary effects)
	if stats.speed > 0:
		sprite.rotation = direction.angle()
	
	# Scale sprite appropriately
	sprite.scale = Vector2(1.0, 1.0)
	
	projectile.add_child(sprite)
	
	# Debug information
	print("✨ Created projectile - Type: ", projectile_type, ", Speed: ", stats.speed, ", Damage: ", damage, ", Sprite: ", stats.sprite_path)
	
	# Projectile properties
	projectile.set_meta("velocity", direction * stats.speed)
	projectile.set_meta("damage", damage)
	projectile.set_meta("type", projectile_type)
	projectile.set_meta("stats", stats)
	projectile.set_meta("created_time", Time.get_ticks_msec() / 1000.0)
	
	# Enhanced properties for new projectile types
	if stats.has("homing") and stats.homing:
		projectile.set_meta("homing", true)
		projectile.set_meta("homing_strength", stats.get("homing_strength", 100.0))
		projectile.set_meta("target", find_nearest_enemy(start_pos))
	
	if stats.has("piercing") and stats.piercing:
		projectile.set_meta("piercing", true)
		projectile.set_meta("pierce_count", stats.get("pierce_count", 1))
		projectile.set_meta("hit_enemies", [])
	
	if stats.has("explosion_radius") and stats.explosion_radius > 0:
		projectile.set_meta("explosion_radius", stats.explosion_radius)
		projectile.set_meta("explosion_damage", stats.get("explosion_damage", damage * 0.5))
	
	if stats.has("duration"):
		projectile.set_meta("duration", stats.duration)
		if stats.speed == 0:  # Stationary effect
			projectile.set_meta("stationary", true)
			create_aoe_visual_indicator(start_pos, stats.collision_radius, stats.duration)
	
	if stats.has("heal_amount"):
		projectile.set_meta("heal_amount", stats.heal_amount)
	
	projectile.collision_layer = 16  # Projectile layer
	projectile.collision_mask = 2 | 4  # Collides with walls and enemies
	projectile.position = start_pos
	
	projectiles_container.add_child(projectile)
	projectiles.append(projectile)
	entity_count += 1
	
	return projectile  # Return the projectile so boss can mark it

func find_nearest_enemy(pos: Vector2):
	var nearest_enemy = null
	var nearest_distance = INF
	
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			var distance = pos.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_enemy = enemy
	
	return nearest_enemy

func get_living_enemies() -> Array:
	# Return array of all living enemies for targeting abilities
	var living_enemies = []
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("is_dead") and not enemy.is_dead:
			living_enemies.append(enemy)
	return living_enemies

func create_aoe_visual_indicator(pos: Vector2, radius: float, duration: float):
	# Create a visual circle to show AOE area
	var indicator = Node2D.new()
	indicator.position = pos
	indicator.name = "AOE_Indicator"
	
	# Create circle outline
	var circle = ColorRect.new()
	circle.size = Vector2(radius * 2, radius * 2)
	circle.position = Vector2(-radius, -radius)
	circle.color = Color(1.0, 1.0, 0.0, 0.3)  # Semi-transparent yellow
	
	# Make it circular using a shader or just use ColorRect with transparency
	circle.material = create_circle_material()
	
	indicator.add_child(circle)
	add_child(indicator)
	
	# Pulse effect
	var tween = create_tween()
	tween.set_loops(-1)  # Loop indefinitely
	tween.tween_property(circle, "modulate:a", 0.1, 0.5)
	tween.tween_property(circle, "modulate:a", 0.5, 0.5)
	
	# Remove after duration
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): 
		if is_instance_valid(indicator):
			indicator.queue_free()
	)
	add_child(timer)
	timer.start()

func create_circle_material():
	# Simple material for circle rendering
	var circle_material = CanvasItemMaterial.new()
	circle_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return circle_material

func handle_stationary_effect(projectile: RigidBody2D, delta: float):
	# Handle area effects for stationary projectiles like Divine Shield, Blood Wave
	var stats = projectile.get_meta("stats")
	var projectile_type = projectile.get_meta("type")
	
	match projectile_type:
		ProjectileType.DIVINE_ENERGY:
			# Divine Shield: Heal player and damage nearby enemies
			if player and projectile.global_position.distance_to(player.global_position) <= stats.collision_radius:
				# Heal player continuously
				var heal_amount = stats.get("heal_amount", 40.0) * delta  # Heal per second
				player.heal(heal_amount)
			
			# Damage nearby enemies
			for enemy in enemies:
				if is_instance_valid(enemy) and not enemy.is_dead:
					if projectile.global_position.distance_to(enemy.global_position) <= stats.collision_radius:
						enemy.take_damage(stats.damage * delta)  # Damage per second
		
		ProjectileType.BLOOD_WAVE:
			# Blood Wave: Damage all enemies in range
			for enemy in enemies:
				if is_instance_valid(enemy) and not enemy.is_dead:
					if projectile.global_position.distance_to(enemy.global_position) <= stats.collision_radius:
						enemy.take_damage(stats.damage * delta)  # Damage per second

func create_attack_visual(center_pos: Vector2):
	# Create temporary visual feedback for melee attack
	var attack_visual = ColorRect.new()
	attack_visual.size = Vector2(MELEE_ATTACK_RANGE * 2, MELEE_ATTACK_RANGE * 2)
	attack_visual.position = center_pos - Vector2(MELEE_ATTACK_RANGE, MELEE_ATTACK_RANGE)
	attack_visual.color = Color(1.0, 1.0, 1.0, 0.3)  # Semi-transparent white
	
	add_child(attack_visual)
	
	# Remove visual after short duration
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	timer.timeout.connect(_on_attack_visual_timeout.bind(attack_visual))
	add_child(timer)
	timer.start()

func _on_attack_visual_timeout(visual: ColorRect):
	if is_instance_valid(visual):
		visual.queue_free()

func create_directional_attack_visual(center_pos: Vector2, direction: Vector2, attack_range: float, character_name: String = ""):
	# Create a visual representation of the attack cone
	var attack_visual = Node2D.new()
	attack_visual.position = center_pos
	
	# Create multiple small rectangles to represent the attack cone
	var cone_segments = 5
	var cone_angle = 60.0  # degrees
	var start_angle = direction.angle() - deg_to_rad(cone_angle / 2)
	
	# Character-specific visual effects
	var effect_color = Color(1.0, 1.0, 0.8, 0.6)  # Default golden
	var effect_size = Vector2(20, 8)
	var effect_duration = 0.15
	
	match character_name:
		"Berserker":
			effect_color = Color(1.0, 0.3, 0.3, 0.8)  # Red for berserker power
			effect_size = Vector2(25, 12)  # Larger for powerful strike
			effect_duration = 0.2  # Longer duration for powerful attack
		"Knight":
			effect_color = Color(0.8, 0.8, 1.0, 0.7)  # Blue for knight precision
			effect_size = Vector2(18, 6)  # Smaller for quick slash
			effect_duration = 0.1  # Shorter duration for quick attack
		_:
			effect_color = Color(1.0, 1.0, 0.8, 0.6)  # Default golden
	
	for i in range(cone_segments):
		var angle = start_angle + (deg_to_rad(cone_angle) * i / cone_segments)
		var segment_pos = Vector2(cos(angle), sin(angle)) * attack_range * 0.7
		
		var segment = ColorRect.new()
		segment.size = effect_size
		segment.position = segment_pos - segment.size / 2
		segment.rotation = angle
		segment.color = effect_color
		attack_visual.add_child(segment)
	
	add_child(attack_visual)
	
	# Remove visual after character-specific duration
	var timer = Timer.new()
	timer.wait_time = effect_duration
	timer.one_shot = true
	timer.timeout.connect(_on_directional_attack_visual_timeout.bind(attack_visual))
	add_child(timer)
	timer.start()

func _on_directional_attack_visual_timeout(visual: Node2D):
	if is_instance_valid(visual):
		visual.queue_free()

# Helper function removed - now using physics-based collision detection

func hit_enemy(enemy: CharacterBody2D, damage: float):
	# This function is now mainly for compatibility with old placeholder enemies
	# New skeleton enemies use their own take_damage method
	if not is_instance_valid(enemy):
		return
	
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	else:
		print("⚠️ Hit enemy without take_damage method - this shouldn't happen with new skeleton enemies")

func create_hit_visual(pos: Vector2):
	# Create temporary red flash for hit feedback
	var hit_visual = ColorRect.new()
	hit_visual.size = Vector2(30, 30)
	hit_visual.position = pos - Vector2(15, 15)
	hit_visual.color = Color(1.0, 0.0, 0.0, 0.6)  # Red flash
	
	add_child(hit_visual)
	
	# Remove visual after short duration
	var timer = Timer.new()
	timer.wait_time = 0.2
	timer.one_shot = true
	timer.timeout.connect(_on_hit_visual_timeout.bind(hit_visual))
	add_child(timer)
	timer.start()

func _on_hit_visual_timeout(visual: ColorRect):
	if is_instance_valid(visual):
		visual.queue_free()

func destroy_enemy(enemy: CharacterBody2D):
	print("Enemy destroyed!")
	
	# Remove from enemies array
	var index = enemies.find(enemy)
	if index >= 0:
		enemies.remove_at(index)
	
	# Clean up
	if is_instance_valid(enemy):
		enemy.queue_free()
		entity_count -= 1

# New skeleton enemy spawning functions
func spawn_skeleton_enemy(enemy_type: Enemy.EnemyType):
	var spawn_pos = get_random_spawn_position()
	# Make sure enemies don't spawn too close to player
	while spawn_pos.distance_to(player.position) < 120:
		spawn_pos = get_random_spawn_position()
	
	create_skeleton_enemy(spawn_pos, enemy_type)

func create_skeleton_enemy(pos: Vector2, enemy_type: Enemy.EnemyType):
	var enemy = enemy_scene.instantiate()
	enemy.position = pos
	enemy.initialize_enemy(enemy_type, enemy_scale_factor)
	
	enemies_container.add_child(enemy)
	enemies.append(enemy)
	entity_count += 1
	
	print("✨ Spawned ", enemy.get_enemy_type_name(), " at ", pos, " with scale factor: ", enemy_scale_factor)
	
	return enemy

# Function for archer skeletons to create arrows
func create_enemy_arrow(start_pos: Vector2, direction: Vector2, damage: float):
	var arrow = RigidBody2D.new()
	arrow.name = "EnemyArrow"
	arrow.gravity_scale = 0  # No gravity for top-down
	
	# Arrow collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 4.0
	collision.shape = shape
	arrow.add_child(collision)
	
	# Arrow visual using existing arrow sprite
	var sprite = Sprite2D.new()
	sprite.texture = load("res://assets/arrow.svg")
	sprite.position = Vector2.ZERO
	sprite.rotation = direction.angle()
	sprite.scale = Vector2(1.0, 1.0)
	sprite.modulate = Color(0.8, 0.4, 0.4, 1.0)  # Reddish tint for enemy arrows
	arrow.add_child(sprite)
	
	# Arrow properties (slower than player arrows)
	var arrow_speed = 400.0  # Slower than player arrows (600.0)
	arrow.set_meta("velocity", direction * arrow_speed)
	arrow.set_meta("damage", damage)
	arrow.set_meta("enemy_projectile", true)
	arrow.collision_layer = 32  # Enemy projectile layer
	arrow.collision_mask = 1 | 2  # Collides with player and walls
	arrow.position = start_pos
	
	projectiles_container.add_child(arrow)
	projectiles.append(arrow)
	entity_count += 1
	
	print("🏹 Created enemy arrow with damage: ", damage)

# Function for stone golem ground pound attack
func handle_golem_ground_pound(golem_position: Vector2, damage_radius: float, damage: float):
	print("🌊 GROUND POUND at position: ", golem_position, " with radius: ", damage_radius)
	
	# Check if player is within damage radius
	if player and player.position.distance_to(golem_position) <= damage_radius:
		if player.has_method("take_damage"):
			player.take_damage(damage)
			print("💥 GROUND POUND hit player for ", damage, " damage!")
	
	# Create visual shockwave effect
	create_ground_pound_shockwave(golem_position, damage_radius)

func create_ground_pound_shockwave(center: Vector2, radius: float):
	# Create expanding shockwave visual effect
	var shockwave_container = Node2D.new()
	shockwave_container.position = center
	add_child(shockwave_container)
	
	# Create multiple expanding circles for shockwave effect
	var wave_count = 3
	for i in range(wave_count):
		var wave = Node2D.new()
		shockwave_container.add_child(wave)
		
		# Create circle segments for the wave
		var segments = 12
		for j in range(segments):
			var angle = (PI * 2 * j) / segments
			var segment = ColorRect.new()
			segment.size = Vector2(8, 4)
			segment.position = Vector2(cos(angle), sin(angle)) * (radius * 0.3) - segment.size / 2
			segment.rotation = angle
			segment.color = Color(1.0, 0.6, 0.0, 0.8)  # Orange shockwave
			wave.add_child(segment)
		
		# Animate the wave expansion
		var tween = create_tween()
		tween.parallel().tween_property(wave, "scale", Vector2(3.0, 3.0), 0.6)
		tween.parallel().tween_property(wave, "modulate:a", 0.0, 0.6)
		
		# Delay each wave slightly
		await get_tree().create_timer(0.15 * i).timeout
	
	# Remove the entire shockwave container after animation
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 1.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): shockwave_container.queue_free())
	add_child(cleanup_timer)
	cleanup_timer.start()
	
	print("🌊 Ground pound shockwave visual effect created")

# Function for Enemy class to call when removing enemies
func remove_enemy(enemy: Enemy):
	var index = enemies.find(enemy)
	if index >= 0:
		enemies.remove_at(index)
		entity_count -= 1
		print("🤝 PEER: Enemy removed from tracking")

# RPC to remove enemy on all clients when it dies
@rpc("any_peer", "call_remote", "reliable") 
func remove_enemy_rpc(enemy_name: String):
	print("👥 CLIENT: Removing enemy via RPC: ", enemy_name)
	var enemy_node = enemies_container.get_node_or_null(enemy_name)
	if enemy_node:
		var index = enemies.find(enemy_node)
		if index >= 0:
			enemies.remove_at(index)
			entity_count -= 1
		enemy_node.queue_free()
		print("✅ CLIENT: Enemy removed: ", enemy_name)
	else:
		print("⚠️ CLIENT: Enemy not found for removal: ", enemy_name)

# RPC to synchronize enemy damage to all clients
@rpc("any_peer", "call_remote", "reliable")
func sync_enemy_damage_rpc(enemy_name: String, new_health: float, max_health: float):
	# Find the enemy by name
	var enemy_node = enemies_container.get_node_or_null(enemy_name)
	if enemy_node and enemy_node.has_method("sync_health"):
		# Only sync if the new health is lower (prevent healing from network lag)
		if new_health < enemy_node.current_health:
			print("👥 CLIENT: Syncing enemy damage: ", enemy_name, " -> ", new_health, "/", max_health)
			enemy_node.sync_health(new_health, max_health)
		# If enemy died on sender but not locally, kill it
		elif new_health <= 0 and enemy_node.current_health > 0:
			print("👥 CLIENT: Enemy died on remote, syncing death: ", enemy_name)
			enemy_node.sync_health(0, max_health)
	else:
		print("⚠️ CLIENT: Enemy not found for health sync: ", enemy_name)

# Healing orb spawning system
func spawn_healing_orb(position: Vector2, enemy_type: Enemy.EnemyType, player_count: int):
	# Load HealingOrb class
	var healing_orb_script = preload("res://scripts/HealingOrb.gd")
	
	# Create healing orb instance
	var orb = RigidBody2D.new()
	orb.script = healing_orb_script
	orb.position = position
	
	# Calculate heal amount based on enemy type and player count
	orb.heal_amount = healing_orb_script.calculate_heal_amount(enemy_type, player_count)
	
	# Add to scene and tracking
	pickups_container.add_child(orb)
	pickups.append(orb)
	entity_count += 1
	
	print("💚 Spawned healing orb at ", position, " healing for ", orb.heal_amount, " HP")

func update_pickups(delta):
	# Clean up destroyed pickups
	for i in range(pickups.size() - 1, -1, -1):
		var pickup = pickups[i]
		if not is_instance_valid(pickup):
			pickups.remove_at(i)
			entity_count -= 1

# Optional: Add sound effect for pickup
func play_pickup_sound():
	# This can be called by HealingOrb when collected
	print("🔊 *Healing orb collected sound*")
	# TODO: Add actual audio when audio system is implemented

func update_projectiles(delta):
	for i in range(projectiles.size() - 1, -1, -1):
		var projectile = projectiles[i]
		if not is_instance_valid(projectile):
			projectiles.remove_at(i)
			continue
		
		# Handle lifetime tracking for special projectiles
		if projectile.has_meta("lifetime"):
			var created_time = projectile.get_meta("created_time")
			created_time += delta
			projectile.set_meta("created_time", created_time)
			
			var lifetime = projectile.get_meta("lifetime")
			if created_time >= lifetime:
				print("🔮 Large orb expired after ", lifetime, " seconds")
				destroy_projectile(projectile, i)
				continue
		
		# Handle stationary effects (like divine shield, blood rage)
		if projectile.has_meta("stationary") and projectile.get_meta("stationary"):
			handle_stationary_effect(projectile, delta)
			
			# Check duration for stationary effects
			if projectile.has_meta("duration"):
				var created_time = projectile.get_meta("created_time")
				var current_time = Time.get_ticks_msec() / 1000.0
				if current_time - created_time >= projectile.get_meta("duration"):
					destroy_projectile(projectile, i)
					continue
			continue
		
		# Move projectile
		var velocity = projectile.get_meta("velocity") if projectile.has_meta("velocity") else Vector2.ZERO
		
		# Skip projectiles with zero velocity to avoid issues (unless stationary)
		if velocity.length() == 0.0:
			destroy_projectile(projectile, i)
			continue
		
		# Handle homing behavior for special projectiles
		if projectile.has_meta("homing") and projectile.get_meta("homing"):
			var homing_strength = projectile.get_meta("homing_strength") if projectile.has_meta("homing_strength") else 1.0
			var max_turn_rate = projectile.get_meta("max_turn_rate") if projectile.has_meta("max_turn_rate") else 1.0
			
			# Determine homing target based on projectile type
			var is_enemy_projectile = projectile.has_meta("enemy_projectile") and projectile.get_meta("enemy_projectile")
			var target = null
			
			if is_enemy_projectile:
				# Enemy projectiles home toward player
				target = player
			else:
				# Player projectiles home toward nearest enemy
				target = find_nearest_enemy_to_position(projectile.position)
			
			if target:
				var to_target = (target.global_position - projectile.position).normalized()
				var current_direction = velocity.normalized()
				
				# Calculate the angle to turn towards target
				var angle_to_target = current_direction.angle_to(to_target)
				
				# Limit turning rate
				var turn_amount = clamp(angle_to_target, -max_turn_rate * delta, max_turn_rate * delta)
				
				# Apply homing force
				var new_direction = current_direction.rotated(turn_amount * homing_strength)
				var speed = velocity.length()
				velocity = new_direction * speed
				
				# Update stored velocity
				projectile.set_meta("velocity", velocity)
				
				# Debug homing behavior occasionally
				if randf() < 0.01:  # 1% chance per frame for debug
					var projectile_name = "missile"
					if projectile.has_meta("type"):
						var debug_type = projectile.get_meta("type")
						if typeof(debug_type) == TYPE_STRING and debug_type == "large_orb":
							projectile_name = "large orb"
					var target_name = "player" if is_enemy_projectile else "enemy"
					print("🎯 ", projectile_name, " homing toward ", target_name, ": distance=", projectile.position.distance_to(target.position), " angle=", rad_to_deg(angle_to_target))
		
		projectile.position += velocity * delta
		
		# Check if projectile is out of bounds (but allow large orbs more leeway)
		var bounds_check = get_arena_bounds()
		var projectile_type = projectile.get_meta("type") if projectile.has_meta("type") else null
		
		# Check if this is a large orb (handle both string and potential future enum cases)
		var is_large_orb = false
		if projectile_type != null:
			# Handle string type safely
			if typeof(projectile_type) == TYPE_STRING and projectile_type == "large_orb":
				is_large_orb = true
			# Handle enum type (future-proofing) - no current large orb enum exists
			elif typeof(projectile_type) == TYPE_INT:
				# No enum case for large orb currently, but kept for future compatibility
				pass
		
		if is_large_orb:
			# Expand bounds for large orbs
			bounds_check = bounds_check.grow(100)
		
		if not bounds_check.has_point(projectile.position):
			destroy_projectile(projectile, i)
			continue
		
		# Check collision with walls and barriers using physics
		if check_projectile_wall_collision(projectile):
			# Large orbs can pass through some obstacles
			if is_large_orb:
				print("🔮 Large orb passed through obstacle")
				# Don't destroy large orbs on wall hits
				continue
			else:
				destroy_projectile(projectile, i)
				continue
		
		# Check if this is an enemy projectile
		var is_enemy_projectile = projectile.has_meta("enemy_projectile") and projectile.get_meta("enemy_projectile")
		var damage = projectile.get_meta("damage") if projectile.has_meta("damage") else 0.0
		
		if is_enemy_projectile:
			# Enemy projectile - check collision with player
			var collision_radius = 20.0
			if is_large_orb:
				collision_radius = 30.0  # Larger collision for large orbs
			
			if player and projectile.position.distance_to(player.position) < collision_radius:
				# Check if player is invincible (dodging) - projectiles pass through
				if player.is_invincible:
					print("💫 Projectile passed through invincible player!")
					continue  # Projectile continues without being destroyed
				
				if player.has_method("take_damage"):
					player.take_damage(damage)
					print("🔮 Projectile hit player for ", damage, " damage!")
				destroy_projectile(projectile, i)
				continue
		else:
			# Enhanced collision detection for all projectile types
			handle_enhanced_projectile_collision(projectile, i)



func check_projectile_wall_collision(projectile) -> bool:
	# Use Godot's physics to check if projectile is colliding with walls
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = projectile.position
	query.collision_mask = 2  # Wall layer
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_point(query)
	
	if result.size() > 0:
		# Create impact effect at collision point
		create_projectile_impact_effect(projectile.position)
		print("💥 Projectile hit wall at position: ", projectile.position)
		return true
	
	return false

func handle_enhanced_projectile_collision(projectile: RigidBody2D, projectile_index: int):
	# Enhanced collision system for new projectile types
	var damage = projectile.get_meta("damage")
	var stats = projectile.get_meta("stats")
	var projectile_type = projectile.get_meta("type")
	
	# Check for collision with enemies
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = projectile.position
	query.collision_mask = 4  # Enemy layer
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	
	if results.size() > 0:
		var body = results[0].collider
		if body and body.has_method("take_damage"):
			# Check if this is a boss projectile hitting the boss itself
			var is_boss_projectile = projectile.has_meta("boss_projectile") and projectile.get_meta("boss_projectile")
			var is_boss = body.has_method("is_boss_entity") and body.is_boss_entity()
			
			if is_boss_projectile and is_boss:
				print("🚫 Boss projectile blocked from hitting boss")
				destroy_projectile(projectile, projectile_index)
				return
			
			# Handle piercing projectiles
			if stats.has("piercing") and stats.piercing:
				var hit_enemies = projectile.get_meta("hit_enemies", [])
				
				# Check if we already hit this enemy
				if body in hit_enemies:
					return  # Don't hit the same enemy twice, continue moving
				
				# Add enemy to hit list
				hit_enemies.append(body)
				projectile.set_meta("hit_enemies", hit_enemies)
				
				# Deal damage
				body.take_damage(damage)
				print("🎯 Piercing projectile hit ", body.name, " for ", damage, " damage!")
				
				# Check if we've pierced through max targets
				var pierce_count = stats.get("pierce_count", 1)
				if hit_enemies.size() >= pierce_count:
					print("🎯 Piercing projectile exhausted after ", hit_enemies.size(), " hits")
					handle_projectile_destruction(projectile, projectile_index)
				return
			else:
				# Normal hit - deal damage and destroy/explode
				body.take_damage(damage)
				print("🏹 Projectile hit ", body.name, " for ", damage, " damage!")
				handle_projectile_destruction(projectile, projectile_index)
				return
		else:
			# Hit something without take_damage method (wall, etc.)
			handle_projectile_destruction(projectile, projectile_index)
			return

func handle_projectile_destruction(projectile: RigidBody2D, projectile_index: int):
	# Handle projectile destruction with potential explosion effects
	var stats = projectile.get_meta("stats")
	
	# Check for explosion effects
	if stats.has("explosion_radius") and stats.explosion_radius > 0:
		create_explosion_effect(projectile.global_position, stats.explosion_radius, stats.get("explosion_damage", 0.0))
	
	# Destroy the projectile
	destroy_projectile(projectile, projectile_index)

func create_explosion_effect(pos: Vector2, radius: float, explosion_damage: float):
	# Create visual explosion effect
	var explosion_visual = ColorRect.new()
	explosion_visual.size = Vector2(radius * 2, radius * 2)
	explosion_visual.position = pos - Vector2(radius, radius)
	explosion_visual.color = Color(1.0, 0.5, 0.0, 0.6)  # Orange explosion
	
	add_child(explosion_visual)
	
	# Animate explosion
	var tween = create_tween()
	tween.parallel().tween_property(explosion_visual, "scale", Vector2(1.5, 1.5), 0.3)
	tween.parallel().tween_property(explosion_visual, "modulate:a", 0.0, 0.3)
	tween.tween_callback(explosion_visual.queue_free)
	
	# Deal explosion damage to all enemies in radius
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			var distance = pos.distance_to(enemy.global_position)
			if distance <= radius:
				# Damage falls off with distance
				var damage_multiplier = 1.0 - (distance / radius)
				var final_damage = explosion_damage * damage_multiplier
				enemy.take_damage(final_damage)
				print("💥 Explosion hit ", enemy.get_enemy_type_name(), " for ", final_damage, " damage!")
	
	print("💥 Explosion created at ", pos, " with radius ", radius, " and damage ", explosion_damage)

func create_projectile_impact_effect(pos: Vector2):
	# Create small visual effect when projectile hits wall
	var impact_visual = ColorRect.new()
	impact_visual.size = Vector2(8, 8)
	impact_visual.position = pos - Vector2(4, 4)
	impact_visual.color = Color(1.0, 0.8, 0.0, 0.7)  # Yellow impact flash
	
	add_child(impact_visual)
	
	# Remove visual after short duration
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	timer.timeout.connect(_on_impact_visual_timeout.bind(impact_visual))
	add_child(timer)
	timer.start()

func _on_impact_visual_timeout(visual: ColorRect):
	if is_instance_valid(visual):
		visual.queue_free()

func destroy_projectile(projectile, index: int):
	if is_instance_valid(projectile):
		# Clean up any stored tweens to prevent warnings
		if projectile.has_meta("pulse_tween"):
			var pulse_tween = projectile.get_meta("pulse_tween")
			if pulse_tween:
				pulse_tween.kill()
		
		if projectile.has_meta("homing_pulse"):
			var homing_pulse = projectile.get_meta("homing_pulse")
			if homing_pulse:
				homing_pulse.kill()
		
		projectile.queue_free()
		entity_count -= 1
	projectiles.remove_at(index)



# Performance monitoring (less frequent updates)
var performance_timer: float = 0.0

func find_nearest_enemy_to_position(pos: Vector2) -> Node2D:
	var nearest_enemy = null
	var nearest_distance = 999999.0
	
	# Search through all enemies
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			var distance = enemy.position.distance_to(pos)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_enemy = enemy
	
	# Also check boss if it exists and is active
	if current_boss and is_instance_valid(current_boss) and current_boss.current_health > 0:
		var boss_distance = current_boss.position.distance_to(pos)
		if boss_distance < nearest_distance:
			nearest_enemy = current_boss
	
	return nearest_enemy

func _process(delta):
	frame_time_accumulator += delta
	if frame_time_accumulator >= 5.0:  # Update every 5 seconds instead of 1
		var fps = Engine.get_frames_per_second()
		if fps < 45:  # Performance warning threshold
			print("Performance Warning: FPS =", fps, " Entities =", entity_count)
		else:
			print("Performance Good: FPS =", fps, " Entities =", entity_count)
		frame_time_accumulator = 0.0
	
	# Update HUD cooldown indicators
	update_hud_cooldowns()

# Player signal handlers
func _on_player_health_changed(new_health: float, max_health: float):
	var health_percentage = new_health / max_health
	print("Player health: ", new_health, "/", max_health, " (", health_percentage * 100, "%)")

func _on_player_died():
	print("Player died! Game over.")
	# For Step 3, just print message. Game over screen will be implemented later.
	handle_player_death()

func handle_player_death():
	if game_over:
		return  # Already handled
	
	game_over = true
	game_paused = true
	
	print("🔥 GAME OVER - Player has fallen!")
	
	# Clear all UI elements before showing death screen
	clear_all_ui()
	
	# Wait a frame to ensure UI changes are processed
	await get_tree().process_frame
	
	# Show game over screen
	show_game_over_screen()
	
	print("💀 Death UI sequence complete")

func clear_all_ui():
	print("🧹 Clearing all UI elements...")
	
	# Hide round UI
	if round_ui_canvas:
		round_ui_canvas.visible = false
		print("  ✓ Round UI Canvas hidden")
	
	if round_label:
		round_label.visible = false
		print("  ✓ Round Label hidden")
	
	# Hide boss UI if active
	if boss_ui_canvas:
		boss_ui_canvas.visible = false
		print("  ✓ Boss UI hidden")
	
	# Hide HUD cooldown system
	if hud_canvas:
		hud_canvas.visible = false
		print("  ✓ HUD Canvas hidden")
	
	print("🧹 All UI cleared for death screen")

func show_game_over_screen():
	if not game_over_ui_canvas or not game_over_container:
		print("❌ Game over UI not initialized!")
		return
	
	# Update the round reached text
	var round_reached_label = game_over_container.get_node("RoundReachedLabel")
	if round_reached_label:
		round_reached_label.text = "You made it to Round " + str(current_round)
	
	# Show the game over screen
	game_over_ui_canvas.visible = true
	print("💀 YOU DIED screen displayed - Round: ", current_round)

func count_enemies_defeated() -> int:
	# Simple approximation based on rounds and spawning
	return (current_round - 1) * 5  # Rough estimate

# Round System Functions
func calculate_enemies_for_round(round_number: int) -> int:
	# Start with 3 enemies in round 1, increase gradually
	var base_enemies = 3
	var additional = (round_number - 1) / 2  # Add 1 enemy every 2 rounds
	return base_enemies + additional

func start_new_round():
	print("🌟 Starting Round ", current_round)
	
	# Reset round state
	enemies_spawned_this_round = 0
	enemies_to_spawn_this_round = calculate_enemies_for_round(current_round)
	round_completed = false
	between_rounds = false
	round_timer = 0.0
	spawn_timer = 0.0
	
	# Update UI
	update_round_ui()
	
	# HOST: Sync round start to clients
	if is_multiplayer_game and network_manager and network_manager.is_host:
		# Wait a frame to ensure we're in the tree
		await get_tree().process_frame
		if is_inside_tree():
			sync_round_start.rpc(current_round, enemies_to_spawn_this_round)
			print("🏠 HOST: Synced round ", current_round, " start to clients")
		else:
			print("⚠️ HOST: Cannot sync round - not in tree yet")
	
	print("Round ", current_round, " - Enemies to spawn: ", enemies_to_spawn_this_round)
	print("🔧 Round state reset - between_rounds: ", between_rounds, " round_completed: ", round_completed)

# RPC to sync round start to clients
@rpc("any_peer", "call_remote", "reliable")
func sync_round_start(round_number: int, enemies_count: int):
	print("👥 CLIENT: Received round start from host - Round ", round_number)
	current_round = round_number
	enemies_to_spawn_this_round = enemies_count
	enemies_spawned_this_round = 0
	round_completed = false
	between_rounds = false
	round_timer = 0.0
	spawn_timer = 0.0
	
	# Update client UI
	update_round_ui()
	print("✅ CLIENT: Round ", round_number, " synchronized")

func update_round_ui():
	if round_label:
		if current_game_mode == GameMode.DEBUG:
			round_label.text = "Debug"
		else:
			round_label.text = "Round: " + str(current_round)
	print("📱 UI updated - Mode: ", GameMode.keys()[current_game_mode], " | Display: ", round_label.text if round_label else "None")

func complete_round():
	print("🎉 Round ", current_round, " completed!")
	round_completed = true
	between_rounds = true
	round_timer = 0.0
	
	# Give players brief respite between rounds
	print("⏰ Next round starts in ", between_round_duration, " seconds...")



# RPC to synchronize new round start to all clients
@rpc("any_peer", "call_remote", "reliable")
func start_new_round_rpc(round_number: int, enemies_to_spawn: int):
	print("🌟 CLIENT: Starting Round ", round_number, " via RPC")
	
	# Update round state on client
	current_round = round_number
	enemies_spawned_this_round = 0
	enemies_to_spawn_this_round = enemies_to_spawn
	round_completed = false
	between_rounds = false
	round_timer = 0.0
	spawn_timer = 0.0
	
	# Update UI on client
	if round_label:
		if current_game_mode == GameMode.DEBUG:
			round_label.text = "Debug"
		else:
			round_label.text = "Round: " + str(current_round)
	
	print("👥 CLIENT: Round ", current_round, " - Enemies to spawn: ", enemies_to_spawn_this_round)

# RPC to synchronize UI state to all clients
@rpc("any_peer", "call_remote", "reliable")
func sync_ui_rpc(round_number: int, game_mode: GameMode):
	print("📱 CLIENT: Syncing UI - Round: ", round_number, " Mode: ", GameMode.keys()[game_mode])
	current_round = round_number
	current_game_mode = game_mode
	if round_label:
		if current_game_mode == GameMode.DEBUG:
			round_label.text = "Debug"
		else:
			round_label.text = "Round: " + str(round_number)

func handle_round_progression(delta: float):
	# Handle between-round timing
	if between_rounds:
		round_timer += delta
		if round_timer >= between_round_duration:
			# Start next round
			current_round += 1
			start_new_round()
		return
	
	# Debug: Log current state every few seconds
	if fmod(game_time, 2.0) < delta:  # Log every 2 seconds
		print("🔍 ROUND DEBUG - Round: ", current_round, 
			" | Spawned: ", enemies_spawned_this_round, "/", enemies_to_spawn_this_round,
			" | Round Complete: ", round_completed,
			" | Between Rounds: ", between_rounds)
	
	# Check if all enemies are defeated and round should end
	# Only check for completion if we've actually spawned some enemies
	if not round_completed and enemies_spawned_this_round > 0 and enemies_spawned_this_round >= enemies_to_spawn_this_round:
		if are_all_enemies_defeated():
			complete_round()
			return
	
	# Handle enemy spawning during active round
	if enemies_spawned_this_round < enemies_to_spawn_this_round:
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_round_enemy()
			spawn_timer = 0.0

func are_all_enemies_defeated() -> bool:
	# Check if any enemies are still alive
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			return false
	
	# Check boss
	if current_boss and is_instance_valid(current_boss) and current_boss.current_health > 0:
		return false
	
	return true

func spawn_round_enemy():
	# Choose enemy type based on current round using shared RNG
	var enemy_type = choose_enemy_type_for_round_deterministic(current_round)
	
	# Get deterministic spawn position using shared RNG
	var spawn_pos = get_deterministic_spawn_position()
	
	# Ensure enemy doesn't spawn too close to ANY player 
	var attempts = 0
	var min_distance_from_players = 150
	var too_close = true
	
	while too_close and attempts < 10:
		too_close = false
		
		# Check distance to all players
		if is_multiplayer_game:
			for mp_player in multiplayer_players:
				if is_instance_valid(mp_player) and spawn_pos.distance_to(mp_player.position) < min_distance_from_players:
					too_close = true
					break
		else:
			# Single player - check main player
			if player and spawn_pos.distance_to(player.position) < min_distance_from_players:
				too_close = true
		
		if too_close:
			spawn_pos = get_deterministic_spawn_position()
			attempts += 1
	
	# Use deterministic enemy ID based on round and spawn count
	var enemy_id = current_round * 1000 + enemies_spawned_this_round
	
	# HOST: Create enemy locally and sync to clients
	if is_multiplayer_game and network_manager and network_manager.is_host:
		# Host creates enemy locally
		create_enemy_locally(spawn_pos, enemy_type, enemy_id)
		
		# Sync enemy spawn to all clients
		spawn_enemy_on_clients.rpc(spawn_pos, enemy_type, enemy_id)
		print("🏠 HOST: Spawned enemy ", enemies_spawned_this_round + 1, " and synced to clients")
	else:
		# Single player or client (shouldn't reach here for client)
		create_enemy_locally(spawn_pos, enemy_type, enemy_id)
	
	enemies_spawned_this_round += 1

# Create enemy locally (used by both host and client)
func create_enemy_locally(spawn_pos: Vector2, enemy_type: Enemy.EnemyType, enemy_id: int):
	var enemy = enemy_scene.instantiate()
	enemy.position = spawn_pos
	enemy.initialize_enemy(enemy_type, enemy_scale_factor)
	enemy.name = "Enemy_" + str(enemy_id)
	enemy.set_meta("enemy_id", enemy_id)
	
	enemies_container.add_child(enemy)
	enemies.append(enemy)
	entity_count += 1
	
	print("🤝 PEER: Created enemy ", Enemy.EnemyType.keys()[enemy_type], " with ID ", enemy_id, " at ", spawn_pos)

# RPC to spawn enemy on clients
@rpc("any_peer", "call_remote", "reliable")
func spawn_enemy_on_clients(spawn_pos: Vector2, enemy_type: Enemy.EnemyType, enemy_id: int):
	print("👥 CLIENT: Received enemy spawn from host - creating enemy ", enemy_id)
	print("📍 CLIENT: Current node path: ", get_path())
	create_enemy_locally(spawn_pos, enemy_type, enemy_id)
	print("✅ CLIENT: Enemy created successfully")

# NEW: Deterministic enemy type selection using shared RNG
func choose_enemy_type_for_round_deterministic(round_number: int) -> Enemy.EnemyType:
	# Use shared RNG for identical enemy selection on all clients
	if round_number <= 3:
		# Early rounds: Only sword skeletons
		return Enemy.EnemyType.SWORD_SKELETON
	elif round_number <= 6:
		# Mid rounds: Mix of sword and archer skeletons
		return Enemy.EnemyType.SWORD_SKELETON if shared_rng.randf() < 0.7 else Enemy.EnemyType.ARCHER_SKELETON
	elif round_number <= 10:
		# Later rounds: Add stone golems occasionally
		var rand = shared_rng.randf()
		if rand < 0.5:
			return Enemy.EnemyType.SWORD_SKELETON
		elif rand < 0.8:
			return Enemy.EnemyType.ARCHER_SKELETON
		else:
			return Enemy.EnemyType.STONE_GOLEM
	else:
		# High rounds: All enemy types with heavier weighting on stronger enemies
		var rand = shared_rng.randf()
		if rand < 0.3:
			return Enemy.EnemyType.SWORD_SKELETON
		elif rand < 0.6:
			return Enemy.EnemyType.ARCHER_SKELETON
		else:
			return Enemy.EnemyType.STONE_GOLEM

func create_round_ui():
	print("Creating round UI system...")
	
	# Create CanvasLayer for round UI overlay
	round_ui_canvas = CanvasLayer.new()
	round_ui_canvas.name = "RoundUICanvas"
	round_ui_canvas.layer = 15  # Above boss UI
	add_child(round_ui_canvas)
	
	# Create round label
	round_label = Label.new()
	round_label.name = "RoundLabel"
	round_label.text = "Round: 1"
	round_label.position = Vector2(50, 50)
	round_label.size = Vector2(200, 40)
	round_label.add_theme_font_size_override("font_size", 24)
	round_label.add_theme_color_override("font_color", Color.WHITE)
	round_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	round_label.add_theme_constant_override("shadow_offset_x", 2)
	round_label.add_theme_constant_override("shadow_offset_y", 2)
	round_ui_canvas.add_child(round_label)
	
	print("Round UI system created")

func create_game_over_ui():
	print("Creating simple game over UI system...")
	
	# Create CanvasLayer for game over overlay
	game_over_ui_canvas = CanvasLayer.new()
	game_over_ui_canvas.name = "GameOverUICanvas"
	game_over_ui_canvas.layer = 20  # Top layer
	game_over_ui_canvas.visible = false
	add_child(game_over_ui_canvas)
	
	# Create pure black background that covers the entire screen
	var background = ColorRect.new()
	background.name = "GameOverBackground"
	background.color = Color.BLACK
	
	# Get the actual viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	background.size = viewport_size
	background.position = Vector2.ZERO
	
	# Set anchors to ensure it covers the full screen regardless of size
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	game_over_ui_canvas.add_child(background)
	
	# Create game over container centered on screen
	game_over_container = Control.new()
	game_over_container.name = "GameOverContainer"
	# Position at center of actual viewport
	game_over_container.position = Vector2(viewport_size.x / 2, viewport_size.y / 2)
	game_over_container.size = Vector2(400, 200)
	game_over_ui_canvas.add_child(game_over_container)
	
	# "YOU DIED" text in red
	var death_label = Label.new()
	death_label.name = "DeathLabel"
	death_label.text = "YOU DIED"
	death_label.position = Vector2(-100, -100)  # Center relative to container
	death_label.size = Vector2(200, 60)
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.add_theme_font_size_override("font_size", 48)
	death_label.add_theme_color_override("font_color", Color.RED)
	game_over_container.add_child(death_label)
	
	# Round reached text
	var round_label = Label.new()
	round_label.name = "RoundReachedLabel"
	round_label.text = "You made it to Round 1"
	round_label.position = Vector2(-150, -20)  # Center relative to container
	round_label.size = Vector2(300, 30)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_label.add_theme_font_size_override("font_size", 20)
	round_label.add_theme_color_override("font_color", Color.WHITE)
	game_over_container.add_child(round_label)
	
	# Play Again button
	var restart_button = Button.new()
	restart_button.name = "RestartButton"
	restart_button.text = "Play Again"
	restart_button.position = Vector2(-100, 40)  # Center relative to container
	restart_button.size = Vector2(80, 30)
	restart_button.pressed.connect(restart_game)
	game_over_container.add_child(restart_button)
	
	# Main Menu button
	var menu_button = Button.new()
	menu_button.name = "MainMenuButton"
	menu_button.text = "Main Menu"
	menu_button.position = Vector2(20, 40)  # Center relative to container
	menu_button.size = Vector2(80, 30)
	menu_button.pressed.connect(return_to_main_menu)
	game_over_container.add_child(menu_button)
	
	print("Simple game over UI system created")

func restart_game():
	print("Restarting game...")
	# Reset all game state
	game_over = false
	game_paused = false
	current_round = 1
	game_time = 0.0
	
	# Clear enemies
	clear_all_enemies()
	
	# Reset player
	if player:
		player.current_health = player.base_health
		player.is_alive = true
		player.update_health_bar()
		player.position = ARENA_SIZE / 2
	
	# Hide game over screen
	if game_over_ui_canvas:
		game_over_ui_canvas.visible = false
	
	# Restore all UI elements
	restore_all_ui()
	
	# Ensure we're in playable mode for restart
	current_game_mode = GameMode.PLAYABLE
	
	# Restart round system
	setup_round_system()
	
	# Force UI update to show correct round/mode
	update_round_ui()
	
	print("🔄 Game restarted - Round: ", current_round, " | Mode: ", GameMode.keys()[current_game_mode])

func restore_all_ui():
	print("🔧 Restoring all UI elements...")
	
	# Show round UI
	if round_ui_canvas:
		round_ui_canvas.visible = true
		print("  ✓ Round UI Canvas restored")
	
	if round_label:
		round_label.visible = true
		print("  ✓ Round Label restored")
	
	# Show HUD cooldown system
	if hud_canvas:
		hud_canvas.visible = true
		print("  ✓ HUD Canvas restored")
	
	# Boss UI will be shown/hidden based on boss state
	
	print("�� All UI restored")

func return_to_main_menu():
	print("Returning to main menu...")
	get_tree().change_scene_to_file("res://scenes/GameManager.tscn")

func clear_all_enemies():
	# Remove all enemies from the scene
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	
	# Clear boss if active
	if current_boss and is_instance_valid(current_boss):
		current_boss.queue_free()
		current_boss = null
		if boss_health_bar_container:
			boss_health_bar_container.visible = false
	
	# Clear all pickups (healing orbs)
	for pickup in pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	pickups.clear()
	
	entity_count = 1  # Reset to just player

func _on_player_ability_used(ability_name: String):
	print("Player used ability: ", ability_name)

# Performance-optimized helper functions
func get_arena_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, ARENA_SIZE)

func is_position_valid(pos: Vector2) -> bool:
	var bounds = get_arena_bounds()
	return bounds.has_point(pos)

func get_random_spawn_position() -> Vector2:
	var margin = 100
	var x = randf_range(margin, ARENA_SIZE.x - margin)
	var y = randf_range(margin, ARENA_SIZE.y - margin)
	return Vector2(x, y)

# Future step preparations (optimized)
func spawn_entity(_entity_type: String, _spawn_position: Vector2):
	if entity_count >= MAX_ENTITIES:
		print("Entity limit reached, cannot spawn more")
		return null
	# Implementation for future steps
	pass

func cleanup_entities():
	# Will be used for entity pooling in future steps
	pass

# Boss UI System
func create_boss_ui():
	print("Creating boss UI system...")
	
	# Create CanvasLayer for HUD overlay - this ensures it stays on screen
	boss_ui_canvas = CanvasLayer.new()
	boss_ui_canvas.name = "BossUICanvas"
	boss_ui_canvas.layer = 10  # High layer to ensure it's on top
	add_child(boss_ui_canvas)
	
	# Create UI container for boss health bar
	boss_health_bar_container = Control.new()
	boss_health_bar_container.name = "BossHealthBarContainer"
	# Position at top of screen, centered horizontally
	var viewport_size = get_viewport().get_visible_rect().size
	var container_size = Vector2(640, 80)
	boss_health_bar_container.position = Vector2(
		(viewport_size.x - container_size.x) / 2,  # Center horizontally
		20  # Top of screen with margin
	)
	boss_health_bar_container.size = container_size
	boss_health_bar_container.visible = false
	# Add to canvas layer instead of world space
	boss_ui_canvas.add_child(boss_health_bar_container)
	
	# Create boss name label
	boss_name_label = Label.new()
	boss_name_label.name = "BossNameLabel"
	boss_name_label.text = "Blue Witch"
	boss_name_label.position = Vector2(0, 0)
	boss_name_label.size = Vector2(640, 30)  # Match container width
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER  # Center the text
	boss_name_label.add_theme_font_size_override("font_size", 24)
	boss_name_label.add_theme_color_override("font_color", Color.WHITE)
	# Add shadow for better visibility
	boss_name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	boss_name_label.add_theme_constant_override("shadow_offset_x", 2)
	boss_name_label.add_theme_constant_override("shadow_offset_y", 2)
	boss_health_bar_container.add_child(boss_name_label)
	
	# Create boss health bar background
	var health_bar_bg = ColorRect.new()
	health_bar_bg.name = "HealthBarBackground"
	health_bar_bg.position = Vector2(0, 35)
	health_bar_bg.size = Vector2(600, 24)
	health_bar_bg.color = Color(0.1, 0.1, 0.1, 0.9)  # Darker background for better contrast
	boss_health_bar_container.add_child(health_bar_bg)
	
	# Create boss health bar
	boss_health_bar = ProgressBar.new()
	boss_health_bar.name = "BossHealthBar"
	boss_health_bar.position = Vector2(2, 37)  # Slight inset from background
	boss_health_bar.size = Vector2(596, 20)
	boss_health_bar.min_value = 0.0
	boss_health_bar.max_value = 100.0
	boss_health_bar.value = 100.0
	boss_health_bar.show_percentage = false
	
	# Style the progress bar
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.8, 0.2, 0.2, 0.85)  # Red health bar with slightly more transparency
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	style_box.border_width_top = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color(0.4, 0.1, 0.1, 0.85)  # Darker red border with matching transparency
	boss_health_bar.add_theme_stylebox_override("fill", style_box)
	
	boss_health_bar_container.add_child(boss_health_bar)
	
	print("Boss UI system created successfully as HUD overlay!")

func show_boss_health_bar(boss_name: String, max_health: float):
	if boss_health_bar_container:
		boss_name_label.text = boss_name
		boss_health_bar.max_value = max_health
		boss_health_bar.value = max_health
		boss_health_bar_container.visible = true
		boss_is_active = true
		print("Boss health bar shown for: ", boss_name)

func update_boss_health_bar(current_health: float, max_health: float):
	if boss_health_bar and boss_is_active:
		boss_health_bar.value = current_health
		var percentage = (current_health / max_health) * 100
		print("Boss health: ", current_health, "/", max_health, " (", percentage, "%)")

func hide_boss_health_bar():
	if boss_health_bar_container:
		boss_health_bar_container.visible = false
		boss_is_active = false
		current_boss = null
		print("Boss health bar hidden")

func create_hud_cooldown_system():
	print("Creating HUD cooldown indicator system...")
	
	# Create CanvasLayer for HUD overlay
	hud_canvas = CanvasLayer.new()
	hud_canvas.name = "HUDCanvas"
	hud_canvas.layer = 5  # Lower than boss UI (10) but above game world
	add_child(hud_canvas)
	
	# Create HUD container positioned at bottom left
	hud_container = Control.new()
	hud_container.name = "HUDContainer"
	hud_container.position = Vector2(20, 0)  # 20px margin from left edge
	hud_container.size = Vector2(300, 150)  # Enough space for 4 cooldown icons
	hud_canvas.add_child(hud_container)
	
	# Position at bottom of screen with margin
	var viewport_size = get_viewport().get_visible_rect().size
	hud_container.position.y = viewport_size.y - 170  # 170px from bottom to fit icons + margins
	
	# Create cooldown icons for each ability
	create_cooldown_icon("dodge", "Dodge (Space)", Vector2(0, 0), Color.GREEN)
	create_cooldown_icon("special", "Special (RClick)", Vector2(0, 40), Color.BLUE) 
	create_cooldown_icon("ultimate", "Ultimate (R)", Vector2(0, 80), Color.PURPLE)
	create_cooldown_icon("primary", "Primary Attack", Vector2(0, 120), Color.ORANGE)
	
	print("HUD cooldown system created successfully!")

func create_cooldown_icon(ability_name: String, display_name: String, position: Vector2, color: Color):
	# Create container for this cooldown icon
	var icon_container = Control.new()
	icon_container.name = ability_name + "_container"
	icon_container.position = position
	icon_container.size = Vector2(200, 35)
	hud_container.add_child(icon_container)
	
	# Create background for the icon
	var background = ColorRect.new()
	background.name = ability_name + "_background"
	background.size = Vector2(32, 32)
	background.color = Color(0.2, 0.2, 0.2, 0.8)  # Dark semi-transparent background
	icon_container.add_child(background)
	
	# Create the actual icon/indicator
	var icon = ColorRect.new()
	icon.name = ability_name + "_icon"
	icon.size = Vector2(28, 28)
	icon.position = Vector2(2, 2)  # Slight inset from background
	icon.color = color
	background.add_child(icon)
	cooldown_icons[ability_name] = icon
	
	# Create progress bar for cooldown visualization
	var progress_bar = ProgressBar.new()
	progress_bar.name = ability_name + "_progress"
	progress_bar.position = Vector2(2, 2)
	progress_bar.size = Vector2(28, 28)
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = 1.0  # Start ready (full)
	progress_bar.show_percentage = false
	
	# Style the progress bar with circular/overlay appearance
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(1.0, 1.0, 1.0, 0.3)  # Semi-transparent white overlay
	progress_bar.add_theme_stylebox_override("fill", style_box)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color.TRANSPARENT  # Transparent background
	progress_bar.add_theme_stylebox_override("background", bg_style)
	
	background.add_child(progress_bar)
	cooldown_progress_bars[ability_name] = progress_bar
	
	# Create label for ability name
	var label = Label.new()
	label.name = ability_name + "_label" 
	label.position = Vector2(40, 6)  # To the right of the icon
	label.size = Vector2(150, 20)
	label.text = display_name
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	icon_container.add_child(label)
	cooldown_labels[ability_name] = label
	
	print("Created cooldown icon for: ", ability_name)

func update_hud_cooldowns():
	if not player or not hud_container:
		return
	
	# Update dodge cooldown
	var dodge_cooldown = player.dodge_roll_cooldown_timer
	var dodge_max = 1.0  # 1 second cooldown
	update_cooldown_display("dodge", dodge_cooldown, dodge_max)
	
	# Update special ability cooldown  
	var special_cooldown = player.special_ability_timer
	var special_max = get_special_ability_max_cooldown()
	update_cooldown_display("special", special_cooldown, special_max)
	
	# Update ultimate ability cooldown
	var ultimate_cooldown = player.ultimate_ability_timer  
	var ultimate_max = 15.0  # 15 second cooldown
	update_cooldown_display("ultimate", ultimate_cooldown, ultimate_max)
	
	# Update primary attack cooldown (only for characters that have it)
	var primary_cooldown = player.primary_attack_timer
	var primary_max = get_primary_attack_max_cooldown()
	if primary_max > 0:
		update_cooldown_display("primary", primary_cooldown, primary_max)
		cooldown_icons["primary"].get_parent().visible = true
	else:
		cooldown_icons["primary"].get_parent().visible = false  # Hide for characters without primary cooldown

func get_special_ability_max_cooldown() -> float:
	if not player or not player.character_data:
		return 2.0  # Default
	
	match player.character_data.name:
		"Wizard":
			return 1.5
		"Huntress": 
			return 0.8
		_:
			return 2.0

func get_primary_attack_max_cooldown() -> float:
	# In multiplayer, check all players for their character
	if is_multiplayer_game:
		# Find the local player in multiplayer
		for mp_player in multiplayer_players:
			if mp_player and is_instance_valid(mp_player) and mp_player.get_multiplayer_authority() == multiplayer.get_unique_id():
				if mp_player.character_data:
					match mp_player.character_data.name:
						"Wizard":
							return 0.6  # Medium cooldown for wizard
						"Berserker": 
							return 0.8  # Shorter cooldown for berserker
						"Knight":
							return 0.3  # Quick cooldown for knight
						"Huntress":
							return 0.2  # Fastest cooldown for huntress
						_:
							return 0.5  # Default cooldown
		return 0.5  # Fallback in multiplayer
	else:
		# Single player mode
		if not player or not player.character_data:
			return 0.5  # Default cooldown
		
		match player.character_data.name:
			"Wizard":
				return 0.6  # Medium cooldown for wizard
			"Berserker": 
				return 0.8  # Shorter cooldown for berserker
			"Knight":
				return 0.3  # Quick cooldown for knight
			"Huntress":
				return 0.2  # Fastest cooldown for huntress
			_:
				return 0.5  # Default cooldown

func update_cooldown_display(ability_name: String, current_cooldown: float, max_cooldown: float):
	if not cooldown_progress_bars.has(ability_name) or not cooldown_icons.has(ability_name):
		return
	
	var progress_bar = cooldown_progress_bars[ability_name]
	var icon = cooldown_icons[ability_name]
	
	if current_cooldown <= 0:
		# Ability ready
		progress_bar.value = 1.0  # Full bar = ready
		icon.modulate = Color.WHITE  # Full brightness
	else:
		# Ability on cooldown
		var progress = 1.0 - (current_cooldown / max_cooldown)  # Inverted so bar fills as cooldown completes
		progress_bar.value = progress
		icon.modulate = Color(0.5, 0.5, 0.5, 0.7)  # Dimmed while on cooldown

func spawn_blue_witch_boss():
	print("Spawning Blue Witch Boss...")
	
	# Remove any existing boss
	if current_boss:
		current_boss.queue_free()
	
	# Calculate spawn position (top of map between tombstones)
	var spawn_position = Vector2(600, 200)  # Between top tombstones
	
	# Load and instantiate the BlueBoss scene
	var boss_scene = preload("res://scenes/BlueBoss.tscn")
	var boss = boss_scene.instantiate()
	boss.position = spawn_position
	boss.name = "BlueBoss"
	
	enemies_container.add_child(boss)
	enemies.append(boss)
	current_boss = boss
	
	# Show boss health bar
	show_boss_health_bar("Blue Witch", boss.max_health)
	
	print("Blue Witch Boss spawned at position: ", spawn_position)
	print("Boss health: ", boss.max_health)
	entity_count += 1

func add_elite_skeleton(elite_skeleton: Enemy):
	# Add to enemies container and tracking
	enemies_container.add_child(elite_skeleton)
	enemies.append(elite_skeleton)
	entity_count += 1
	
	print("Elite skeleton added to main scene") 

# Game Mode Helper Functions
func is_debug_mode() -> bool:
	return current_game_mode == GameMode.DEBUG

func is_playable_mode() -> bool:
	return current_game_mode == GameMode.PLAYABLE

func toggle_debug_mode():
	# Switch between debug and playable modes
	if current_game_mode == GameMode.DEBUG:
		current_game_mode = GameMode.PLAYABLE
		print("🎮 Switched to PLAYABLE MODE")
		print("Round-based progression enabled")
		# Update UI to show round number
		update_round_ui()
		# Restart round system if not already running
		if not between_rounds and enemies_spawned_this_round >= enemies_to_spawn_this_round:
			setup_round_system()
	else:
		current_game_mode = GameMode.DEBUG
		print("🔧 Switched to DEBUG MODE")
		print("Manual enemy spawning enabled:")
		print("  1 - Spawn Sword Skeleton")
		print("  2 - Spawn Archer Skeleton")
		print("  3 - Spawn Blue Witch Boss")
		print("  4 - Spawn Stone Golem")
		# Update UI to show "Debug"
		update_round_ui()
		# Pause round progression
		between_rounds = true
		round_completed = true

func handle_debug_enemy_spawn(keycode: int):
	match keycode:
		KEY_1:
			spawn_skeleton_enemy(Enemy.EnemyType.SWORD_SKELETON)
			print("🗡️  Debug: Spawned Sword Skeleton")
		KEY_2:
			spawn_skeleton_enemy(Enemy.EnemyType.ARCHER_SKELETON)
			print("🏹 Debug: Spawned Archer Skeleton")
		KEY_3:
			spawn_blue_witch_boss()
			print("🧙‍♀️ Debug: Spawned Blue Witch Boss")
		KEY_4:
			spawn_skeleton_enemy(Enemy.EnemyType.STONE_GOLEM)
			print("🗿 Debug: Spawned Stone Golem") 

# NEW: Event-based damage synchronization (replaces state streaming)
@rpc("any_peer", "call_remote", "reliable")
func sync_damage_event(enemy_id: int, damage: float):
	# Find enemy by deterministic ID and apply damage
	var enemy_name = "Enemy_" + str(enemy_id)
	var enemy_node = enemies_container.get_node_or_null(enemy_name)
	
	if enemy_node and enemy_node.has_method("apply_remote_damage"):
		print("🤝 PEER: Received damage event for enemy ", enemy_id, " - damage: ", damage)
		enemy_node.apply_remote_damage(damage)
	else:
		print("⚠️ PEER: Enemy ", enemy_id, " not found for damage event")

# NEW: Event-based death synchronization
@rpc("any_peer", "call_remote", "reliable") 
func sync_enemy_death_event(enemy_id: int):
	# Find enemy by deterministic ID and kill it if still alive
	var enemy_name = "Enemy_" + str(enemy_id)
	var enemy_node = enemies_container.get_node_or_null(enemy_name)
	
	if enemy_node and not enemy_node.is_dead:
		print("💀 PEER: Received death event for enemy ", enemy_id, " - killing enemy")
		enemy_node.die()
	else:
		print("👻 PEER: Enemy ", enemy_id, " already dead or not found")

# NEW: Getter for shared RNG (used by enemies for deterministic behavior)
func get_shared_rng() -> RandomNumberGenerator:
	return shared_rng
