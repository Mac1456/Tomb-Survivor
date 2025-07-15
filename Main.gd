extends Node2D

# Performance-optimized game setup
const ARENA_SIZE = Vector2(1200, 800)
const WALL_THICKNESS = 32
const MAX_ENTITIES = 50  # Performance cap

# Combat constants
const MELEE_ATTACK_RANGE = 50.0
const MELEE_ATTACK_DAMAGE = 25.0
const PROJECTILE_SPEED = 400.0
const PROJECTILE_DAMAGE = 30.0
const SPECIAL_ABILITY_COOLDOWN = 2.0
const ENEMY_SPAWN_COUNT = 3

# Core game objects
var player: CharacterBody2D
var camera: Camera2D
var arena_bounds: Array = []

# Combat system
var enemies: Array = []
var projectiles: Array = []
var special_ability_timer: float = 0.0
var enemies_container: Node2D
var projectiles_container: Node2D

# Performance tracking
var entity_count: int = 0
var frame_time_accumulator: float = 0.0

func _ready():
	print("=== Tomb Survivor - Step 2: Core Combat Mechanics ===")
	setup_performance_optimized_game()

func setup_performance_optimized_game():
	# Create all nodes programmatically for guaranteed compatibility
	create_arena()
	create_player()
	create_camera()
	create_combat_containers()
	spawn_placeholder_enemies()
	
	print("Step 2 systems initialized successfully!")
	print("Controls: WASD to move, Left Click to melee attack, Right Click for projectile (2s cooldown)")
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
	
	print("Combat containers created")

func spawn_placeholder_enemies():
	print("Spawning placeholder enemies...")
	
	for i in range(ENEMY_SPAWN_COUNT):
		var enemy_pos = get_random_spawn_position()
		# Make sure enemies don't spawn too close to player
		while enemy_pos.distance_to(player.position) < 150:
			enemy_pos = get_random_spawn_position()
		
		create_placeholder_enemy(enemy_pos)
	
	print("Spawned ", ENEMY_SPAWN_COUNT, " placeholder enemies")

func create_placeholder_enemy(pos: Vector2):
	var enemy = CharacterBody2D.new()
	enemy.name = "Enemy"
	
	# Enemy collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	collision.shape = shape
	enemy.add_child(collision)
	
	# Enemy visual (red square)
	var visual = ColorRect.new()
	visual.size = Vector2(20, 20)
	visual.position = Vector2(-10, -10)
	visual.color = Color(1.0, 0.3, 0.3, 1.0)  # Red enemy
	enemy.add_child(visual)
	
	# Enemy stats
	enemy.set_meta("health", 50.0)
	enemy.set_meta("max_health", 50.0)
	enemy.set_meta("speed", 100.0)
	
	# Enemy configuration
	enemy.collision_layer = 4  # Enemy layer
	enemy.collision_mask = 1 | 2  # Collides with player and walls
	enemy.position = pos
	
	enemies_container.add_child(enemy)
	enemies.append(enemy)
	entity_count += 1
	
	return enemy

# Handle player movement in the main script
func _physics_process(delta):
	if player:
		handle_player_movement(delta)
	
	# Update combat timers
	if special_ability_timer > 0:
		special_ability_timer -= delta
	
	# Update projectiles
	update_projectiles(delta)
	
	# Simple enemy AI (basic chase behavior)
	update_enemy_ai(delta)

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
		perform_melee_attack()
	elif event.is_action_pressed("special_ability"):
		perform_special_ability()
	elif event.is_action_pressed("ultimate_ability"):
		print("Ultimate ability - will implement in Step 6")
	elif event.is_action_pressed("ui_cancel"):
		print("Escape pressed - will implement pause menu in future steps")

func perform_melee_attack():
	print("Performing melee attack!")
	
	# Get player facing direction
	var facing_direction = player.get_meta("facing_direction")
	var attack_center = player.position + facing_direction * (MELEE_ATTACK_RANGE / 2)
	
	# Create visual feedback for attack
	create_attack_visual(attack_center)
	
	# Check for enemies in attack range
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = enemy.position.distance_to(attack_center)
			if distance <= MELEE_ATTACK_RANGE:
				hit_enemy(enemy, MELEE_ATTACK_DAMAGE)
				print("Enemy hit with melee attack!")

func perform_special_ability():
	if special_ability_timer > 0:
		print("Special ability on cooldown! Wait ", "%.1f" % special_ability_timer, " seconds")
		return
	
	print("Performing special ability - projectile attack!")
	special_ability_timer = SPECIAL_ABILITY_COOLDOWN
	
	# Create projectile
	var facing_direction = player.get_meta("facing_direction")
	create_projectile(player.position, facing_direction)

func create_projectile(start_pos: Vector2, direction: Vector2):
	var projectile = RigidBody2D.new()
	projectile.name = "Projectile"
	projectile.gravity_scale = 0  # No gravity for top-down
	
	# Projectile collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 5
	collision.shape = shape
	projectile.add_child(collision)
	
	# Projectile visual (yellow circle)
	var visual = ColorRect.new()
	visual.size = Vector2(10, 10)
	visual.position = Vector2(-5, -5)
	visual.color = Color(1.0, 1.0, 0.3, 1.0)  # Yellow projectile
	projectile.add_child(visual)
	
	# Projectile properties
	projectile.set_meta("velocity", direction * PROJECTILE_SPEED)
	projectile.collision_layer = 16  # Projectile layer
	projectile.collision_mask = 2 | 4  # Collides with walls and enemies
	projectile.position = start_pos
	
	projectiles_container.add_child(projectile)
	projectiles.append(projectile)
	entity_count += 1

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

func hit_enemy(enemy: CharacterBody2D, damage: float):
	if not is_instance_valid(enemy):
		return
	
	var current_health = enemy.get_meta("health")
	current_health -= damage
	enemy.set_meta("health", current_health)
	
	print("Enemy hit! Health: ", current_health)
	
	# Create hit visual effect
	create_hit_visual(enemy.position)
	
	# Check if enemy is dead
	if current_health <= 0:
		destroy_enemy(enemy)

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
	
	# Spawn new enemy to maintain count (for testing)
	if enemies.size() < ENEMY_SPAWN_COUNT:
		var new_pos = get_random_spawn_position()
		while new_pos.distance_to(player.position) < 150:
			new_pos = get_random_spawn_position()
		create_placeholder_enemy(new_pos)

func update_projectiles(delta):
	for i in range(projectiles.size() - 1, -1, -1):
		var projectile = projectiles[i]
		if not is_instance_valid(projectile):
			projectiles.remove_at(i)
			continue
		
		# Move projectile
		var velocity = projectile.get_meta("velocity")
		projectile.position += velocity * delta
		
		# Check if projectile is out of bounds
		if not get_arena_bounds().has_point(projectile.position):
			destroy_projectile(projectile, i)
			continue
		
		# Check collision with enemies
		for enemy in enemies:
			if is_instance_valid(enemy) and projectile.position.distance_to(enemy.position) < 15:
				hit_enemy(enemy, PROJECTILE_DAMAGE)
				destroy_projectile(projectile, i)
				break

func update_enemy_ai(delta):
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		# Simple chase AI - move toward player
		var direction = (player.position - enemy.position).normalized()
		var speed = enemy.get_meta("speed")
		enemy.velocity = direction * speed
		enemy.move_and_slide()

func destroy_projectile(projectile, index: int):
	if is_instance_valid(projectile):
		projectile.queue_free()
		entity_count -= 1
	projectiles.remove_at(index)

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
