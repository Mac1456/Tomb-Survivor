extends Node2D

# Performance-optimized game setup
const ARENA_SIZE = Vector2(1200, 800)
const WALL_THICKNESS = 32
const MAX_ENTITIES = 50  # Performance cap

# Core game objects
var player: CharacterBody2D
var camera: Camera2D
var arena_bounds: Array = []

# Performance tracking
var entity_count: int = 0
var frame_time_accumulator: float = 0.0

func _ready():
	print("=== Tomb Survivor - Step 1: Core Movement & Arena Setup ===")
	setup_performance_optimized_game()

func setup_performance_optimized_game():
	# Create all nodes programmatically for guaranteed compatibility
	create_arena()
	create_player()
	create_camera()
	
	print("Step 1 systems initialized successfully!")
	print("Controls: WASD to move, mouse to aim")
	print("Performance: Entity limit =", MAX_ENTITIES)

func create_arena():
	print("Creating performance-optimized arena...")
	
	# Create arena container
	var arena_container = Node2D.new()
	arena_container.name = "Arena"
	add_child(arena_container)
	
	# Create walls efficiently using StaticBody2D (performance optimized)
	create_wall_boundaries(arena_container)
	create_tactical_barriers(arena_container)
	create_safe_zones(arena_container)
	
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
	var barriers_container = Node2D.new()
	barriers_container.name = "Barriers"
	parent.add_child(barriers_container)
	
	# Limited number of barriers for performance
	var barrier_positions = [
		Vector2(300, 200),   # Top-left
		Vector2(900, 200),   # Top-right
		Vector2(600, 400),   # Center
		Vector2(300, 600),   # Bottom-left
		Vector2(900, 600),   # Bottom-right
	]
	
	for pos in barrier_positions:
		create_optimized_barrier(barriers_container, pos)

func create_optimized_barrier(parent: Node2D, pos: Vector2):
	var barrier = StaticBody2D.new()
	var size = Vector2(64, 64)  # Smaller for performance
	
	# Collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.position = size / 2
	
	# Visual
	var visual = ColorRect.new()
	visual.size = size
	visual.color = Color(0.2, 0.15, 0.1, 1.0)  # Darker brown
	
	barrier.collision_layer = 2
	barrier.collision_mask = 0
	
	barrier.add_child(collision)
	barrier.add_child(visual)
	barrier.position = pos
	parent.add_child(barrier)
	
	entity_count += 1

func create_safe_zones(parent: Node2D):
	var safe_zones_container = Node2D.new()
	safe_zones_container.name = "SafeZones"
	parent.add_child(safe_zones_container)
	
	# Corner safe zones
	var corner_positions = [
		Vector2(80, 80),
		Vector2(ARENA_SIZE.x - 80, 80),
		Vector2(80, ARENA_SIZE.y - 80),
		Vector2(ARENA_SIZE.x - 80, ARENA_SIZE.y - 80)
	]
	
	for pos in corner_positions:
		create_safe_zone(safe_zones_container, pos)

func create_safe_zone(parent: Node2D, pos: Vector2):
	# Visual indicator only (no collision needed for performance)
	var zone = Node2D.new()
	var visual = ColorRect.new()
	
	visual.size = Vector2(60, 60)
	visual.position = Vector2(-30, -30)
	visual.color = Color(0.2, 0.4, 0.2, 0.2)  # Transparent green
	
	zone.add_child(visual)
	zone.position = pos
	parent.add_child(zone)

func create_player():
	print("Creating performance-optimized player...")
	
	# Create player as CharacterBody2D
	player = CharacterBody2D.new()
	player.name = "Player"
	
	# Player collision setup
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 24)
	collision.shape = shape
	player.add_child(collision)
	
	# Simple visual representation
	var visual = ColorRect.new()
	visual.size = Vector2(24, 24)
	visual.position = Vector2(-12, -12)
	visual.color = Color(0.4, 0.7, 1.0, 1.0)  # Blue player
	player.add_child(visual)
	
	# Player configuration
	player.collision_layer = 1  # Player layer
	player.collision_mask = 2   # Collides with walls
	player.position = ARENA_SIZE / 2  # Center position
	
	# Add player movement variables
	player.set_meta("base_speed", 300.0)
	player.set_meta("acceleration", 2000.0)
	player.set_meta("friction", 1500.0)
	player.set_meta("facing_direction", Vector2.RIGHT)
	
	add_child(player)
	entity_count += 1
	
	print("Player created at center position")

func create_camera():
	print("Creating optimized camera system...")
	
	camera = Camera2D.new()
	camera.name = "GameCamera"
	
	# Camera configuration
	camera.zoom = Vector2(1.2, 1.2)  # Slight zoom for better view
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.enabled = true  # Ensure camera is enabled
	
	# Add camera to player for automatic following
	if player:
		player.add_child(camera)
		# Make this camera current
		camera.make_current()
		print("Camera attached to player and made current")
	else:
		add_child(camera)
		camera.make_current()
		print("Camera created as independent node and made current")

# Handle player movement in the main script
func _physics_process(delta):
	if player:
		handle_player_movement(delta)

func handle_player_movement(delta):
	# Get movement variables
	var base_speed = player.get_meta("base_speed")
	var acceleration = player.get_meta("acceleration")
	var friction = player.get_meta("friction")
	
	# Get input direction
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	input_dir = input_dir.normalized()
	
	# Apply movement with smooth acceleration
	if input_dir != Vector2.ZERO:
		player.velocity = player.velocity.move_toward(input_dir * base_speed, acceleration * delta)
	else:
		player.velocity = player.velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Update facing direction
	var mouse_pos = get_global_mouse_position()
	var facing_direction = (mouse_pos - player.global_position).normalized()
	player.set_meta("facing_direction", facing_direction)
	
	# Move the player
	player.move_and_slide()

func _input(event):
	# Handle combat inputs
	if event.is_action_pressed("primary_attack"):
		print("Primary attack - will implement in Step 2")
	elif event.is_action_pressed("special_ability"):
		print("Special ability - will implement in Step 2")
	elif event.is_action_pressed("ultimate_ability"):
		print("Ultimate ability - will implement in Step 6")
	elif event.is_action_pressed("ui_cancel"):
		print("Escape pressed - will implement pause menu in future steps")

# Optimized performance monitoring (less frequent updates)
func _process(delta):
	frame_time_accumulator += delta
	if frame_time_accumulator >= 5.0:  # Update every 5 seconds instead of 1
		var fps = Engine.get_frames_per_second()
		if fps < 45:  # Performance warning threshold
			print("Performance Warning: FPS =", fps, " Entities =", entity_count)
		else:
			print("Performance Good: FPS =", fps, " Entities =", entity_count)
		frame_time_accumulator = 0.0

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

# Future step preparations (optimized) - Fixed parameter names
func spawn_entity(_entity_type: String, _spawn_position: Vector2):
	if entity_count >= MAX_ENTITIES:
		print("Entity limit reached, cannot spawn more")
		return null
	# Implementation for future steps
	pass

func cleanup_entities():
	# Will be used for entity pooling in future steps
	pass 
