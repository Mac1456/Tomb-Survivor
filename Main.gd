extends Node2D

# Performance-optimized game setup
const ARENA_SIZE = Vector2(1200, 800)
const WALL_THICKNESS = 32
const MAX_ENTITIES = 50  # Performance cap

# Combat constants
const MELEE_ATTACK_RANGE = 50.0
const MELEE_ATTACK_DAMAGE = 25.0

# Projectile type definitions
enum ProjectileType {
	ARROW,
	FIREBALL
}

# Projectile stats by type
const PROJECTILE_STATS = {
	ProjectileType.ARROW: {
		"speed": 600.0,
		"damage": 20.0,
		"sprite_path": "res://assets/arrow.svg",
		"size": Vector2(24, 8),
		"collision_radius": 4.0
	},
	ProjectileType.FIREBALL: {
		"speed": 300.0,
		"damage": 45.0,
		"sprite_path": "res://assets/fireball.svg",
		"size": Vector2(12, 12),
		"collision_radius": 6.0
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
var enemies_container: Node2D
var projectiles_container: Node2D

# Enemy scaling system
var game_time: float = 0.0
var enemy_scale_factor: float = 1.0

# Enemy scene reference
var enemy_scene: PackedScene = preload("res://Enemy.tscn")

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
	
	# Position background at center of arena
	background_sprite.position = ARENA_SIZE / 2
	
	# Scale background to cover arena (adjust as needed)
	background_sprite.scale = Vector2(2.0, 2.0)
	
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
	
	# If game hasn't been set up yet, set it up now
	if not player:
		setup_performance_optimized_game()
	else:
		# Update existing player with new character
		player.set_character_data(selected_character)

func setup_performance_optimized_game():
	# Create all nodes programmatically for guaranteed compatibility
	create_background()
	create_arena()
	create_player()
	create_camera()
	create_combat_containers()
	create_boss_ui()
	
	print("Step 3 systems initialized successfully!")
	print("Selected character: ", selected_character.name)
	print("Controls: WASD to move, Left Click to attack, Right Click for special ability")
	print("Additional: Spacebar for dodge roll, R for ultimate ability")
	print("Enemy Testing: 1 - Spawn Sword Skeleton, 2 - Spawn Archer Skeleton, 4 - Spawn Stone Golem")
	print("Boss Testing: 3 - Spawn Blue Witch Boss")
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
	
	print("Combat containers created")







func _physics_process(delta):
	# Update projectiles
	update_projectiles(delta)
	
	# Update game time for enemy scaling
	game_time += delta
	enemy_scale_factor = 1.0 + (game_time / 30.0)  # Increase by 1.0 every 30 seconds

func _input(event):
	if not player:
		return
	
	# Handle enemy spawning for testing
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				spawn_skeleton_enemy(Enemy.EnemyType.SWORD_SKELETON)
				return
			KEY_2:
				spawn_skeleton_enemy(Enemy.EnemyType.ARCHER_SKELETON)
				return
			KEY_3:
				spawn_blue_witch_boss()
				return
			KEY_4:
				spawn_skeleton_enemy(Enemy.EnemyType.STONE_GOLEM)
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
func handle_player_attack(attack_type: String, attack_position: Vector2, attack_range: float, damage: float, direction: Vector2 = Vector2.ZERO):
	if attack_type == "melee":
		handle_melee_attack(attack_position, attack_range, damage)
	elif attack_type == "ranged":
		handle_ranged_attack(attack_position, damage, direction)

# New directional attack handler for better combat feel
func handle_player_directional_attack(attack_type: String, attack_position: Vector2, attack_range: float, damage: float, direction: Vector2):
	if attack_type == "melee":
		# Pass character info for differentiated melee visuals
		var character_name = ""
		if player and player.character_data:
			character_name = player.character_data.name
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
				print("🔥 Wizard firing FIREBALL!")
			"Huntress":
				projectile_type = ProjectileType.ARROW
				print("🏹 Huntress firing ARROW!")
			_:
				projectile_type = ProjectileType.ARROW
				print("🏹 Default character firing ARROW!")
	
	create_projectile(start_pos, direction, damage, projectile_type)

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
	
	# Rotate sprite to face direction
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
	projectile.collision_layer = 16  # Projectile layer
	projectile.collision_mask = 2 | 4  # Collides with walls and enemies
	projectile.position = start_pos
	
	projectiles_container.add_child(projectile)
	projectiles.append(projectile)
	entity_count += 1
	
	return projectile  # Return the projectile so boss can mark it

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
		
		# Move projectile
		var velocity = projectile.get_meta("velocity") if projectile.has_meta("velocity") else Vector2.ZERO
		
		# Skip projectiles with zero velocity to avoid issues
		if velocity.length() == 0.0:
			destroy_projectile(projectile, i)
			continue
		
		# Handle homing behavior for special projectiles
		if projectile.has_meta("homing") and projectile.get_meta("homing"):
			var homing_strength = projectile.get_meta("homing_strength") if projectile.has_meta("homing_strength") else 1.0
			var max_turn_rate = projectile.get_meta("max_turn_rate") if projectile.has_meta("max_turn_rate") else 1.0
			
			# Find the player for homing
			if player:
				var to_player = (player.global_position - projectile.position).normalized()
				var current_direction = velocity.normalized()
				
				# Calculate the angle to turn towards player
				var angle_to_player = current_direction.angle_to(to_player)
				
				# Limit turning rate
				var turn_amount = clamp(angle_to_player, -max_turn_rate * delta, max_turn_rate * delta)
				
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
					print("🎯 ", projectile_name, " homing: distance=", projectile.position.distance_to(player.position), " angle=", rad_to_deg(angle_to_player))
		
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
				if player.has_method("take_damage"):
					player.take_damage(damage)
					print("🔮 Projectile hit player for ", damage, " damage!")
				destroy_projectile(projectile, i)
				continue
		else:
			# Player projectile OR boss projectile - use physics-based collision detection
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
						# Boss projectile hitting boss - destroy projectile without damage
						print("🚫 Boss projectile blocked from hitting boss")
						destroy_projectile(projectile, i)
						break
					
					body.take_damage(damage)
					print("🏹 Projectile hit ", body.name, " for ", damage, " damage!")
					destroy_projectile(projectile, i)
					break
				else:
					# Hit something without take_damage method (wall, etc.)
					destroy_projectile(projectile, i)
					break



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

func spawn_blue_witch_boss():
	print("Spawning Blue Witch Boss...")
	
	# Remove any existing boss
	if current_boss:
		current_boss.queue_free()
	
	# Calculate spawn position (top of map between tombstones)
	var spawn_position = Vector2(600, 200)  # Between top tombstones
	
	# Load and instantiate the BlueBoss scene
	var boss_scene = preload("res://BlueBoss.tscn")
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
