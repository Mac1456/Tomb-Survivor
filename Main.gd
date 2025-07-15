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
const ENEMY_SPAWN_COUNT = 3

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
var enemies_container: Node2D
var projectiles_container: Node2D

# Performance tracking
var entity_count: int = 0
var frame_time_accumulator: float = 0.0

# Player scene reference
var player_scene: PackedScene = preload("res://Player.tscn")

func _ready():
	# Add to main group so Player.gd can find this node
	add_to_group("main")
	
	print("=== Tomb Survivor - Step 3: Character System & Selection ===")
	
	# Set up input actions for the new system
	setup_input_actions()
	
	# Default character if none selected
	if not selected_character:
		selected_character = CharacterData.get_character(0)
	
	# Wait for character to be set before initializing game
	if selected_character:
		setup_performance_optimized_game()

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
	
	# If game hasn't been set up yet, set it up now
	if not player:
		setup_performance_optimized_game()
	else:
		# Update existing player with new character
		player.set_character_data(selected_character)

func setup_performance_optimized_game():
	# Create all nodes programmatically for guaranteed compatibility
	create_arena()
	create_player()
	create_camera()
	create_combat_containers()
	spawn_placeholder_enemies()
	
	print("Step 3 systems initialized successfully!")
	print("Selected character: ", selected_character.name)
	print("Controls: WASD to move, Left Click to attack, Right Click for special ability")
	print("Additional: Spacebar for dodge roll, R for ultimate ability")
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
		
		# Add camera to player for automatic following
		player.add_child(camera)
		camera.make_current()
		print("Camera attached to player and made current")

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
	
	# Create health bar
	create_enemy_health_bar(enemy)
	
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

func _physics_process(delta):
	# Update projectiles
	update_projectiles(delta)
	
	# Simple enemy AI (basic chase behavior)
	update_enemy_ai(delta)

func _input(event):
	if not player:
		return
	
	# Handle combat inputs through player
	if event.is_action_pressed("primary_attack"):
		player.perform_primary_attack()
	elif event.is_action_pressed("special_ability"):
		player.perform_special_ability()
	elif event.is_action_pressed("ultimate_ability"):
		player.perform_ultimate_ability()
	elif event.is_action_pressed("dodge_roll"):
		player.perform_dodge_roll()
	elif event.is_action_pressed("ui_cancel"):
		print("Escape pressed - returning to main menu")
		# Return to main menu (handled by GameManager)
		get_tree().change_scene_to_file("res://GameManager.tscn")

# Player attack handler - called by Player.gd
func handle_player_attack(attack_type: String, position: Vector2, range: float, damage: float, direction: Vector2 = Vector2.ZERO):
	if attack_type == "melee":
		handle_melee_attack(position, range, damage)
	elif attack_type == "ranged":
		handle_ranged_attack(position, damage, direction)

# New directional attack handler for better combat feel
func handle_player_directional_attack(attack_type: String, position: Vector2, range: float, damage: float, direction: Vector2):
	if attack_type == "melee":
		handle_directional_melee_attack(position, range, damage, direction)
	elif attack_type == "ranged":
		handle_ranged_attack(position, damage, direction)

func handle_directional_melee_attack(attack_center: Vector2, attack_range: float, damage: float, attack_direction: Vector2):
	# Create visual feedback for directional attack
	create_directional_attack_visual(attack_center, attack_direction, attack_range)
	
	# Attack cone parameters
	var attack_angle = 60.0  # 60 degree cone for sword swing
	var attack_cone_rad = deg_to_rad(attack_angle)
	
	# Check for enemies in attack cone
	for enemy in enemies:
		if is_instance_valid(enemy):
			var to_enemy = enemy.position - attack_center
			var distance = to_enemy.length()
			
			# Check if enemy is within range
			if distance <= attack_range:
				# Check if enemy is within attack cone
				var angle_to_enemy = to_enemy.normalized().angle_to(attack_direction)
				if abs(angle_to_enemy) <= attack_cone_rad / 2:
					hit_enemy(enemy, damage)
					print("Enemy hit with directional melee attack!")

func handle_melee_attack(attack_center: Vector2, attack_range: float, damage: float):
	# Create visual feedback for attack
	create_attack_visual(attack_center)
	
	# Check for enemies in attack range
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = enemy.position.distance_to(attack_center)
			if distance <= attack_range:
				hit_enemy(enemy, damage)
				print("Enemy hit with melee attack!")

func handle_ranged_attack(start_pos: Vector2, damage: float, direction: Vector2):
	create_projectile(start_pos, direction, damage)

func create_projectile(start_pos: Vector2, direction: Vector2, damage: float):
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
	projectile.set_meta("damage", damage)
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

func create_directional_attack_visual(center_pos: Vector2, direction: Vector2, range: float):
	# Create a visual representation of the attack cone
	var attack_visual = Node2D.new()
	attack_visual.position = center_pos
	
	# Create multiple small rectangles to represent the attack cone
	var cone_segments = 5
	var cone_angle = 60.0  # degrees
	var start_angle = direction.angle() - deg_to_rad(cone_angle / 2)
	
	for i in range(cone_segments):
		var angle = start_angle + (deg_to_rad(cone_angle) * i / cone_segments)
		var segment_pos = Vector2(cos(angle), sin(angle)) * range * 0.7
		
		var segment = ColorRect.new()
		segment.size = Vector2(20, 8)
		segment.position = segment_pos - segment.size / 2
		segment.rotation = angle
		segment.color = Color(1.0, 1.0, 0.8, 0.6)  # Golden attack effect
		attack_visual.add_child(segment)
	
	add_child(attack_visual)
	
	# Remove visual after short duration
	var timer = Timer.new()
	timer.wait_time = 0.15
	timer.one_shot = true
	timer.timeout.connect(_on_directional_attack_visual_timeout.bind(attack_visual))
	add_child(timer)
	timer.start()

func _on_directional_attack_visual_timeout(visual: Node2D):
	if is_instance_valid(visual):
		visual.queue_free()

func hit_enemy(enemy: CharacterBody2D, damage: float):
	if not is_instance_valid(enemy):
		return
	
	var current_health = enemy.get_meta("health")
	current_health -= damage
	enemy.set_meta("health", current_health)
	
	print("Enemy hit! Health: ", current_health)
	
	# Update health bar
	update_enemy_health_bar(enemy)
	
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
				var damage = projectile.get_meta("damage")
				hit_enemy(enemy, damage)
				destroy_projectile(projectile, i)
				break

func update_enemy_ai(_delta):
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		# Calculate distance to player
		var distance_to_player = enemy.position.distance_to(player.position)
		var min_distance = 35.0  # Minimum distance to maintain from player
		var overlap_distance = 25.0  # Distance considered as overlapping
		
		# Check if enemy is overlapping with player
		if distance_to_player < overlap_distance:
			# Strong push-back when overlapping
			var push_back_direction = (enemy.position - player.position).normalized()
			# Handle case where enemy is exactly on player position
			if push_back_direction.length() == 0:
				push_back_direction = Vector2(randf() - 0.5, randf() - 0.5).normalized()
			enemy.velocity = push_back_direction * 150.0  # Strong push-back force
		elif distance_to_player < min_distance:
			# Medium push-back when too close
			var push_back_direction = (enemy.position - player.position).normalized()
			enemy.velocity = push_back_direction * 80.0  # Medium push-back force
		else:
			# Normal chase behavior when at proper distance
			var direction = (player.position - enemy.position).normalized()
			var speed = enemy.get_meta("speed")
			enemy.velocity = direction * speed
		
		enemy.move_and_slide()

func destroy_projectile(projectile, index: int):
	if is_instance_valid(projectile):
		projectile.queue_free()
		entity_count -= 1
	projectiles.remove_at(index)

func create_enemy_health_bar(enemy: CharacterBody2D):
	# Create health bar container
	var health_bar_container = Node2D.new()
	health_bar_container.name = "HealthBarContainer"
	health_bar_container.position = Vector2(0, -25)  # Position above enemy
	
	# Background bar (red)
	var bg_bar = ColorRect.new()
	bg_bar.size = Vector2(30, 4)
	bg_bar.position = Vector2(-15, -2)
	bg_bar.color = Color(0.3, 0.0, 0.0, 1.0)  # Dark red background
	health_bar_container.add_child(bg_bar)
	
	# Health bar (green)
	var health_bar = ColorRect.new()
	health_bar.name = "HealthBar"
	health_bar.size = Vector2(30, 4)
	health_bar.position = Vector2(-15, -2)
	health_bar.color = Color(0.0, 0.8, 0.0, 1.0)  # Green health
	health_bar_container.add_child(health_bar)
	
	enemy.add_child(health_bar_container)

func update_enemy_health_bar(enemy: CharacterBody2D):
	var health_bar_container = enemy.get_node("HealthBarContainer")
	if not health_bar_container:
		return
	
	var health_bar = health_bar_container.get_node("HealthBar")
	if not health_bar:
		return
	
	var current_health = enemy.get_meta("health")
	var max_health = enemy.get_meta("max_health")
	var health_percentage = current_health / max_health
	
	# Update health bar width
	health_bar.size.x = 30 * health_percentage
	
	# Change color based on health
	if health_percentage > 0.6:
		health_bar.color = Color(0.0, 0.8, 0.0, 1.0)  # Green
	elif health_percentage > 0.3:
		health_bar.color = Color(0.8, 0.8, 0.0, 1.0)  # Yellow
	else:
		health_bar.color = Color(0.8, 0.0, 0.0, 1.0)  # Red

# Performance monitoring (less frequent updates)
func _process(delta):
	frame_time_accumulator += delta
	if frame_time_accumulator >= 5.0:  # Update every 5 seconds instead of 1
		var fps = Engine.get_frames_per_second()
		if fps < 45:  # Performance warning threshold
			print("Performance Warning: FPS =", fps, " Entities =", entity_count)
		else:
			print("Performance Good: FPS =", fps, " Entities =", entity_count)
		frame_time_accumulator = 0.0

# Player signal handlers
func _on_player_health_changed(new_health: float, max_health: float):
	var health_percentage = new_health / max_health
	print("Player health: ", new_health, "/", max_health, " (", health_percentage * 100, "%)")

func _on_player_died():
	print("Player died! Game over.")
	# For Step 3, just print message. Game over screen will be implemented later.

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
