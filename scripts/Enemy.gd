extends CharacterBody2D
class_name Enemy

# Note: HealingOrb is available as a global class, no need to import

# Enemy type definitions
enum EnemyType {
	SWORD_SKELETON,
	ARCHER_SKELETON,
	STONE_GOLEM,
	BOSS
}

# Proper Hades-style AI states
enum AIState {
	IDLE,
	PATROL,
	CHASE,
	WINDUP,     # Telegraph/anticipation phase
	ATTACK,     # Committed attack phase
	COOLDOWN,   # Recovery phase
	REPOSITION  # For ranged enemies
}

# Enemy configuration
var enemy_type: EnemyType
var base_stats: Dictionary = {}
var current_stats: Dictionary = {}
var scale_factor: float = 1.0

# Combat and AI state
var max_health: float
var current_health: float
var attack_damage: float
var attack_range: float
var attack_cooldown: float
var movement_speed: float
var is_dead: bool = false

# Hades-style AI variables
var target_player: Node2D = null
var ai_state: AIState = AIState.IDLE
var state_timer: float = 0.0
var last_attack_time: float = 0.0

# Movement and positioning
var patrol_direction: Vector2 = Vector2.ZERO
var patrol_timer: float = 0.0
var dash_target: Vector2 = Vector2.ZERO
var reposition_target: Vector2 = Vector2.ZERO

# Natural movement randomization
var movement_randomness_timer: float = 0.0
var current_movement_offset: Vector2 = Vector2.ZERO
var wander_angle: float = 0.0
var movement_personality: float = randf()  # Each enemy has unique movement personality

# Attack telegraph system
var windup_timer: float = 0.0
var individual_cooldown_time: float = 0.0

# Visual and collision components
var sprite: Node2D
var health_bar_container: Node2D
var health_bar: ColorRect
var collision_shape: CollisionShape2D

# Navigation components
var navigation_agent: NavigationAgent2D
var is_using_navigation: bool = false

# Constants for Hades-style AI - Simplified and focused
const PATROL_CHANGE_TIME: float = 1.5      # Very fast patrol changes for responsiveness
const IDLE_TO_PATROL_TIME: float = 0.3     # Almost immediate transition from idle to patrol
const LOSE_INTEREST_MULTIPLIER: float = 1.3 # Stay interested longer

# General constants for archer/golem compatibility
const DETECTION_RANGE: float = 250.0       # Default detection range for other enemy types
const LOSE_INTEREST_RANGE: float = 350.0   # Default lose interest range for other enemy types

# Sword skeleton constants - CROSS-MAP HUNTERS
const SWORD_DETECTION_RANGE: float = 2000.0 # MASSIVE detection - they see you from anywhere on map
const SWORD_ATTACK_RANGE: float = 80.0      # Attack initiation range
const SWORD_DAMAGE_RANGE: float = 50.0      # Actual damage radius
const SWORD_WINDUP_TIME: float = 0.5        # Telegraph time as requested
const SWORD_ATTACK_SPEED: float = 300.0     # Speed during attack lunge
const SWORD_COOLDOWN_TIME: float = 1.0      # Cooldown as requested

# Archer skeleton constants
const ARCHER_OPTIMAL_RANGE: float = 200.0  # Increased from 120
const ARCHER_MIN_RANGE: float = 80.0  # Increased from 60
const ARCHER_WINDUP_TIME: float = 1.2
const ARCHER_COOLDOWN_TIME: float = 3.0
const ARCHER_REPOSITION_SPEED: float = 100.0

# Stone golem constants
const GOLEM_GROUND_POUND_RANGE: float = 150.0  # Increased from 100 for better engagement
const GOLEM_ATTACK_RANGE: float = 80.0  # Increased from 60 for better hit detection
const GOLEM_WINDUP_TIME: float = 2.0
const GOLEM_COOLDOWN_TIME: float = 4.0
const GOLEM_MOVE_SPEED: float = 30.0

# Base enemy stats (before scaling)
const BASE_ENEMY_STATS = {
	EnemyType.SWORD_SKELETON: {
		"health": 60.0,
		"damage": 30.0,
		"speed": 70.0,
		"attack_cooldown": SWORD_COOLDOWN_TIME,
		"attack_range": SWORD_ATTACK_RANGE
	},
	EnemyType.ARCHER_SKELETON: {
		"health": 25.0,
		"damage": 20.0,
		"speed": 80.0,
		"attack_cooldown": ARCHER_COOLDOWN_TIME,
		"attack_range": 180.0
	},
	EnemyType.STONE_GOLEM: {
		"health": 800.0,
		"damage": 80.0,
		"speed": GOLEM_MOVE_SPEED,
		"attack_cooldown": GOLEM_COOLDOWN_TIME,
		"attack_range": GOLEM_ATTACK_RANGE
	}
}

func _ready():
	# Set up collision
	collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()

	# Set collision size based on enemy type and sprite scaling
	match enemy_type:
		EnemyType.SWORD_SKELETON:
			# Sword skeletons: 24x30 sprite * 1.5 scale = 36x45 visual
			# Use slightly smaller collision for better gameplay
			shape.size = Vector2(30, 40)
		EnemyType.ARCHER_SKELETON:
			# Archer skeletons: 24x30 sprite * 1.5 scale = 36x45 visual
			# Use slightly smaller collision for better gameplay
			shape.size = Vector2(28, 38)
		EnemyType.STONE_GOLEM:
			# Stone golem: 80x120 sprite = large imposing collision
			# Use full sprite size for accurate hitbox including legs
			shape.size = Vector2(80, 120)
		_:
			# Default collision for other enemy types
			shape.size = Vector2(20, 20)
	
	collision_shape.shape = shape
	collision_shape.position = Vector2(0, 0)
	add_child(collision_shape)
	
	# Set collision layers
	collision_layer = 4  # Enemy layer
	collision_mask = 1 | 2  # Collides with player and walls
	
	# Find player target (works for both single-player and multiplayer)
	find_nearest_player_target()
	
	# Initialize AI state
	ai_state = AIState.PATROL  # Start in patrol immediately, not idle
	state_timer = 0.0
	patrol_timer = 0.0
	
	# PEER-TO-PEER: Use deterministic patrol direction based on enemy ID
	var enemy_id = get_meta("enemy_id", 0)
	if enemy_id > 0:
		var shared_rng = get_shared_rng()
		if shared_rng:
			# Create deterministic but varied behavior per enemy
			var temp_seed = shared_rng.seed + enemy_id
			shared_rng.seed = temp_seed
			patrol_direction = get_new_patrol_direction()
			shared_rng.seed = temp_seed  # Reset seed for consistent behavior
			print("🤝 PEER: Enemy ", enemy_id, " using deterministic patrol direction")
	else:
		# Fallback for enemies without ID
		patrol_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	# Ensure initial patrol direction avoids walls
	patrol_direction = apply_boundary_avoidance(patrol_direction)
	
	add_to_group("enemies")
	print("Enemy created: ", EnemyType.keys()[enemy_type], " at ", global_position, " facing ", patrol_direction)

	# DISABLED: Navigation system causing issues - using direct movement instead
	navigation_agent = get_node_or_null("NavigationAgent2D")
	is_using_navigation = false  # Force disable navigation
	
	if navigation_agent:
		print("📍 NavigationAgent2D found but disabled - using direct movement for reliability")
	else:
		print("📍 No NavigationAgent2D found - using direct movement")



# Get random patrol direction with boundary checking
func get_new_patrol_direction() -> Vector2:
	# Pure random direction - biasing is handled in patrol state logic
	var new_direction: Vector2
	var shared_rng = get_shared_rng()
	var angle = shared_rng.randf_range(0, 2 * PI) if shared_rng else randf_range(0, 2 * PI)
	new_direction = Vector2(cos(angle), sin(angle)).normalized()
	
	return apply_boundary_avoidance(new_direction)

# IMPROVED: Predictive boundary avoidance with look-ahead
func apply_boundary_avoidance(direction: Vector2) -> Vector2:
	var new_direction = direction
	
	# Arena boundaries (from Main.gd)
	var arena_width = 1600
	var arena_height = 1000
	var safety_margin = 150  # Larger margin for predictive avoidance
	var look_ahead_distance = 100  # How far ahead to check
	
	# Current position
	var current_pos = global_position
	
	# Predicted future position
	var future_pos = current_pos + direction * look_ahead_distance
	
	# Check if future position would be near/outside boundaries
	var will_hit_left = future_pos.x < safety_margin
	var will_hit_right = future_pos.x > arena_width - safety_margin
	var will_hit_top = future_pos.y < safety_margin
	var will_hit_bottom = future_pos.y > arena_height - safety_margin
	
	# Calculate avoidance force based on predicted collision
	var avoidance_force = Vector2.ZERO
	var avoidance_strength = 1.5  # Stronger avoidance
	
	if will_hit_left:
		# Turn right to avoid left wall
		var distance_factor = max(0.1, future_pos.x / safety_margin)
		avoidance_force.x = avoidance_strength * (1.0 - distance_factor)
	elif will_hit_right:
		# Turn left to avoid right wall
		var distance_factor = max(0.1, (arena_width - future_pos.x) / safety_margin)
		avoidance_force.x = -avoidance_strength * (1.0 - distance_factor)
	
	if will_hit_top:
		# Turn down to avoid top wall
		var distance_factor = max(0.1, future_pos.y / safety_margin)
		avoidance_force.y = avoidance_strength * (1.0 - distance_factor)
	elif will_hit_bottom:
		# Turn up to avoid bottom wall
		var distance_factor = max(0.1, (arena_height - future_pos.y) / safety_margin)
		avoidance_force.y = -avoidance_strength * (1.0 - distance_factor)
	
	# Apply avoidance force to direction
	if avoidance_force != Vector2.ZERO:
		new_direction = (direction + avoidance_force).normalized()
	
	# Special handling for corners - turn away strongly
	var near_corner = false
	if (will_hit_left or will_hit_right) and (will_hit_top or will_hit_bottom):
		near_corner = true
		var center = Vector2(arena_width / 2, arena_height / 2)
		var to_center = (center - current_pos).normalized()
		
		# Strong turn toward center when approaching corner
		new_direction = new_direction.lerp(to_center, 0.8)
		
		# Add perpendicular movement to avoid getting stuck
		var perpendicular = Vector2(-to_center.y, to_center.x)
		if randf() > 0.5:  # Random left/right choice
			perpendicular = -perpendicular
		new_direction = (new_direction + perpendicular * 0.3).normalized()
	
	# Emergency correction if already too close to walls (fallback)
	var emergency_margin = 50
	var emergency_correction = Vector2.ZERO
	
	if current_pos.x < emergency_margin:
		emergency_correction.x = 1.0  # Push right
	elif current_pos.x > arena_width - emergency_margin:
		emergency_correction.x = -1.0  # Push left
	
	if current_pos.y < emergency_margin:
		emergency_correction.y = 1.0  # Push down
	elif current_pos.y > arena_height - emergency_margin:
		emergency_correction.y = -1.0  # Push up
	
	if emergency_correction != Vector2.ZERO:
		new_direction = (new_direction + emergency_correction * 2.0).normalized()
		if fmod(Time.get_ticks_msec() / 1000.0, 1.0) < 0.1:  # Log every second
			print("🚨 Emergency wall avoidance for ", name, " at ", current_pos)
	
	return new_direction.normalized()

# SMART OBSTACLE AVOIDANCE: Use raycasting to detect obstacles ahead
func get_safe_direction(intended_direction: Vector2) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var safe_direction = intended_direction
	
	# Cast rays in multiple directions to find safe path
	var ray_length = 80.0  # How far ahead to check
	var ray_directions = [
		intended_direction,  # Straight ahead
		intended_direction.rotated(-PI/6),  # 30 degrees left
		intended_direction.rotated(PI/6),   # 30 degrees right
		intended_direction.rotated(-PI/3),  # 60 degrees left
		intended_direction.rotated(PI/3),   # 60 degrees right
		intended_direction.rotated(-PI/2),  # 90 degrees left
		intended_direction.rotated(PI/2),   # 90 degrees right
	]
	
	var best_direction = intended_direction
	var best_score = -1.0
	
	for i in range(ray_directions.size()):
		var test_direction = ray_directions[i]
		var ray_end = global_position + test_direction * ray_length
		
		# Create ray query
		var query = PhysicsRayQueryParameters2D.create(global_position, ray_end)
		query.collision_mask = 2  # Only check walls (layer 2)
		query.exclude = [self]  # Don't hit ourselves
		
		var result = space_state.intersect_ray(query)
		
		# Calculate score based on clearance and direction preference
		var score = 0.0
		if result.is_empty():
			# No collision - full clearance
			score = 1.0
		else:
			# Collision detected - partial clearance based on distance
			var hit_distance = global_position.distance_to(result.position)
			score = hit_distance / ray_length
		
		# Prefer directions closer to intended direction
		var direction_alignment = intended_direction.dot(test_direction)
		score *= (direction_alignment + 1.0) / 2.0  # Normalize to 0-1
		
		# First direction (straight ahead) gets bonus
		if i == 0:
			score *= 1.2
		
		if score > best_score:
			best_score = score
			best_direction = test_direction
	
	# If no good direction found, try perpendicular movement
	if best_score < 0.1:
		var perpendicular_options = [
			Vector2(-intended_direction.y, intended_direction.x),  # 90 degrees
			Vector2(intended_direction.y, -intended_direction.x),  # -90 degrees
		]
		
		for perp_dir in perpendicular_options:
			var ray_end = global_position + perp_dir * ray_length
			var query = PhysicsRayQueryParameters2D.create(global_position, ray_end)
			query.collision_mask = 2
			query.exclude = [self]
			
			var result = space_state.intersect_ray(query)
			if result.is_empty():
				best_direction = perp_dir
				break
	
	return best_direction.normalized()

# Deterministic cooldown durations
func get_attack_cooldown() -> float:
	var shared_rng = get_shared_rng()
	var base_cooldown = 2.0
	var variation = shared_rng.randf_range(-0.5, 0.5) if shared_rng else randf_range(-0.5, 0.5)
	return max(1.0, base_cooldown + variation)  # 1.5-2.5 seconds

func initialize_enemy(type: EnemyType, scaling: float = 1.0):
	enemy_type = type
	scale_factor = scaling
	
	# Get base stats for this enemy type
	base_stats = BASE_ENEMY_STATS[enemy_type].duplicate()
	
	# Apply scaling to stats
	current_stats = {}
	for key in base_stats:
		current_stats[key] = base_stats[key] * scale_factor
	
	# Set current stats
	max_health = current_stats.health
	current_health = max_health
	attack_damage = current_stats.damage
	movement_speed = current_stats.speed
	attack_cooldown = current_stats.attack_cooldown
	attack_range = current_stats.attack_range
	
	# Create visual components
	create_sprite()
	create_health_bar()
	
	print("✨ Initialized ", EnemyType.keys()[enemy_type], " with scaling: ", scale_factor)
	print("   Health: ", max_health, " Damage: ", attack_damage, " Speed: ", movement_speed)

func create_sprite():
	# Create AnimatedSprite2D for multi-frame animations
	var animated_sprite = AnimatedSprite2D.new()
	animated_sprite.name = "AnimatedSprite2D"
	
	# Set up animation frames based on enemy type
	var sprite_frames = SpriteFrames.new()
	setup_skeleton_animations(sprite_frames)
	
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.play("idle")
	
	# Set sprite scale based on enemy type
	match enemy_type:
		EnemyType.STONE_GOLEM:
			# Golem is already large (80x120), use 1.0 scale
			animated_sprite.scale = Vector2(1.0, 1.0)
		_:
			# Skeletons and other small enemies scale up for visibility
			animated_sprite.scale = Vector2(1.5, 1.5)
	
	# Store reference as sprite for backward compatibility
	sprite = animated_sprite
	add_child(animated_sprite)
	
	print("✨ Created enhanced skeleton animations for ", EnemyType.keys()[enemy_type])
	
	# Debug sprite positioning for golem
	if enemy_type == EnemyType.STONE_GOLEM:
		print("🗿 GOLEM SPRITE DEBUG:")
		print("   Sprite scale: ", animated_sprite.scale)
		print("   Sprite position: ", animated_sprite.position)
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
			var frame = animated_sprite.sprite_frames.get_frame_texture("idle", 0)
			if frame:
				print("   Frame size: ", frame.get_size())

func setup_skeleton_animations(sprite_frames: SpriteFrames):
	match enemy_type:
		EnemyType.SWORD_SKELETON:
			setup_sword_skeleton_animations(sprite_frames)
		EnemyType.ARCHER_SKELETON:
			setup_archer_skeleton_animations(sprite_frames)
		EnemyType.STONE_GOLEM:
			setup_stone_golem_animations(sprite_frames)
		_:
			print("No enhanced animations for enemy type: ", EnemyType.keys()[enemy_type])

func setup_sword_skeleton_animations(sprite_frames: SpriteFrames):
	# Setup idle animation (6 FPS for menacing presence)
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_speed("idle", 6.0)
	sprite_frames.set_animation_loop("idle", true)
	
	for i in range(1, 4):  # 3 frames
		var idle_texture = load("res://assets/enemies/skeletons/sword_skeleton/sword_skeleton_idle_%02d.svg" % i)
		if idle_texture:
			sprite_frames.add_frame("idle", idle_texture)
	print("Loaded Sword Skeleton idle animation (3 frames)")
	
	# Setup move animation (8 FPS for walking)
	sprite_frames.add_animation("move")
	sprite_frames.set_animation_speed("move", 8.0)
	sprite_frames.set_animation_loop("move", true)
	
	for i in range(1, 5):  # 4 frames
		var move_texture = load("res://assets/enemies/skeletons/sword_skeleton/sword_skeleton_move_%02d.svg" % i)
		if move_texture:
			sprite_frames.add_frame("move", move_texture)
	print("Loaded Sword Skeleton move animation (4 frames)")
	
	# Setup attack animation (12 FPS for impact)
	sprite_frames.add_animation("attack")
	sprite_frames.set_animation_speed("attack", 12.0)
	sprite_frames.set_animation_loop("attack", false)
	
	var attack_texture = load("res://assets/enemies/skeletons/sword_skeleton/sword_skeleton_attack_01.svg")
	if attack_texture:
		sprite_frames.add_frame("attack", attack_texture)
	print("Loaded Sword Skeleton attack animation")
	
	# Setup hit animation (8 FPS for impact reaction)
	sprite_frames.add_animation("hit")
	sprite_frames.set_animation_speed("hit", 8.0)
	sprite_frames.set_animation_loop("hit", false)
	
	var hit_texture = load("res://assets/enemies/skeletons/sword_skeleton/sword_skeleton_hit.svg")
	if hit_texture:
		sprite_frames.add_frame("hit", hit_texture)
	print("Loaded Sword Skeleton hit animation")
	
	# Setup death animation (6 FPS for dramatic death)
	sprite_frames.add_animation("death")
	sprite_frames.set_animation_speed("death", 6.0)
	sprite_frames.set_animation_loop("death", false)
	
	var death_texture = load("res://assets/enemies/skeletons/sword_skeleton/sword_skeleton_death.svg")
	if death_texture:
		sprite_frames.add_frame("death", death_texture)
	print("Loaded Sword Skeleton death animation")

func setup_archer_skeleton_animations(sprite_frames: SpriteFrames):
	# Setup idle animation (6 FPS for alert stance)
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_speed("idle", 6.0)
	sprite_frames.set_animation_loop("idle", true)
	
	var idle_texture = load("res://assets/enemies/skeletons/archer_skeleton/archer_skeleton_idle.svg")
	if idle_texture:
		sprite_frames.add_frame("idle", idle_texture)
	print("Loaded Archer Skeleton idle animation")
	
	# Setup move animation (2-frame walking cycle)
	sprite_frames.add_animation("move")
	sprite_frames.set_animation_speed("move", 8.0)
	sprite_frames.set_animation_loop("move", true)
	
	for i in range(1, 3):  # 2 frames
		var move_texture = load("res://assets/enemies/skeletons/archer_skeleton/archer_skeleton_move_%02d.svg" % i)
		if move_texture:
			sprite_frames.add_frame("move", move_texture)
	print("Loaded Archer Skeleton move animation (", sprite_frames.get_frame_count("move"), " frames)")
	
	# Setup attack animation (10 FPS for bow draw and release)
	sprite_frames.add_animation("attack")
	sprite_frames.set_animation_speed("attack", 10.0)
	sprite_frames.set_animation_loop("attack", false)
	
	var attack_texture = load("res://assets/enemies/skeletons/archer_skeleton/archer_skeleton_attack.svg")
	if attack_texture:
		sprite_frames.add_frame("attack", attack_texture)
	print("Loaded Archer Skeleton attack animation")
	
	# Setup hit animation
	sprite_frames.add_animation("hit")
	sprite_frames.set_animation_speed("hit", 8.0)
	sprite_frames.set_animation_loop("hit", false)
	
	var hit_texture = load("res://assets/enemies/skeletons/archer_skeleton/archer_skeleton_hit.svg")
	if hit_texture:
		sprite_frames.add_frame("hit", hit_texture)
	print("Loaded Archer Skeleton hit animation")
	
	# Setup death animation
	sprite_frames.add_animation("death")
	sprite_frames.set_animation_speed("death", 6.0)
	sprite_frames.set_animation_loop("death", false)
	
	var death_texture = load("res://assets/enemies/skeletons/archer_skeleton/archer_skeleton_death.svg")
	if death_texture:
		sprite_frames.add_frame("death", death_texture)
	print("Loaded Archer Skeleton death animation")

func setup_stone_golem_animations(sprite_frames: SpriteFrames):
	# Setup idle animation (6 FPS for imposing presence)
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_speed("idle", 6.0)
	sprite_frames.set_animation_loop("idle", true)
	
	for i in range(1, 3):  # 2 frames for breathing cycle
		var idle_texture = load("res://assets/enemies/stone_golem/stone_golem_idle_%02d.svg" % i)
		if idle_texture:
			sprite_frames.add_frame("idle", idle_texture)
	print("Loaded Stone Golem idle animation (2 frames)")
	
	# Setup move animation (4 FPS for slow, heavy movement)
	sprite_frames.add_animation("move")
	sprite_frames.set_animation_speed("move", 4.0)
	sprite_frames.set_animation_loop("move", true)
	
	for i in range(1, 3):  # 2 frames for walking cycle
		var move_texture = load("res://assets/enemies/stone_golem/stone_golem_move_%02d.svg" % i)
		if move_texture:
			sprite_frames.add_frame("move", move_texture)
	print("Loaded Stone Golem move animation (2 frames)")
	
	# Setup attack animation (8 FPS for powerful ground pound)
	sprite_frames.add_animation("attack")
	sprite_frames.set_animation_speed("attack", 8.0)
	sprite_frames.set_animation_loop("attack", false)
	
	var attack_texture = load("res://assets/enemies/stone_golem/stone_golem_attack.svg")
	if attack_texture:
		sprite_frames.add_frame("attack", attack_texture)
	print("Loaded Stone Golem attack animation")
	
	# Setup hit animation (6 FPS for heavy impact reaction)
	sprite_frames.add_animation("hit")
	sprite_frames.set_animation_speed("hit", 6.0)
	sprite_frames.set_animation_loop("hit", false)
	
	var hit_texture = load("res://assets/enemies/stone_golem/stone_golem_hit.svg")
	if hit_texture:
		sprite_frames.add_frame("hit", hit_texture)
	print("Loaded Stone Golem hit animation")
	
	# Setup death animation (6 FPS for dramatic collapse)
	sprite_frames.add_animation("death")
	sprite_frames.set_animation_speed("death", 6.0)
	sprite_frames.set_animation_loop("death", false)
	
	var death_texture = load("res://assets/enemies/stone_golem/stone_golem_death.svg")
	if death_texture:
		sprite_frames.add_frame("death", death_texture)
	print("Loaded Stone Golem death animation")

func create_health_bar():
	# Create health bar container
	health_bar_container = Node2D.new()
	health_bar_container.name = "HealthBarContainer"
	
	# Position health bar based on enemy type and sprite size
	match enemy_type:
		EnemyType.SWORD_SKELETON, EnemyType.ARCHER_SKELETON:
			# Enhanced skeletons are taller (45 pixels scaled), position bar higher
			health_bar_container.position = Vector2(0, -35)
		EnemyType.STONE_GOLEM:
			# Stone golem is very tall (120 pixels), position bar much higher
			health_bar_container.position = Vector2(0, -70)
		_:
			# Default position for other enemy types
			health_bar_container.position = Vector2(0, -25)
	
	# Background bar (dark red)
	var bg_bar = ColorRect.new()
	bg_bar.size = Vector2(30, 4)
	bg_bar.position = Vector2(-15, -2)
	bg_bar.color = Color(0.3, 0.0, 0.0, 1.0)
	health_bar_container.add_child(bg_bar)
	
	# Health bar (green)
	health_bar = ColorRect.new()
	health_bar.name = "HealthBar"
	health_bar.size = Vector2(30, 4)
	health_bar.position = Vector2(-15, -2)
	health_bar.color = Color(0.0, 0.8, 0.0, 1.0)
	health_bar_container.add_child(health_bar)
	
	add_child(health_bar_container)

func _physics_process(delta):
	if is_dead:
		return
	
	# PEER-TO-PEER FIX: Only host runs enemy AI, clients receive position updates
	var main_node = get_tree().get_first_node_in_group("main")
	var is_multiplayer = main_node and main_node.is_multiplayer_game
	var is_host = main_node and main_node.network_manager and main_node.network_manager.is_host
	
	if is_multiplayer and not is_host:
		# CLIENT: Don't run AI, just wait for position updates from host
		return
	
	# HOST or SINGLE PLAYER: Run full AI and physics [[memory:3835173]]
	
	# Update timers first
	state_timer += delta
	patrol_timer += delta
	
	# Periodically try to find a player if we don't have one
	if not target_player or not is_instance_valid(target_player):
		# Try to find a player every 0.5 seconds when we don't have a target
		if not has_meta("last_player_search") or Time.get_ticks_msec() / 1000.0 - get_meta("last_player_search") > 0.5:
			find_nearest_player_target()
			set_meta("last_player_search", Time.get_ticks_msec() / 1000.0)
	
	# Periodically update target to find closer players
	if fmod(state_timer, 3.0) < delta:  # Every 3 seconds
		update_player_target()
	
	# Update AI behavior based on enemy type - ALWAYS run this [[memory:3835173]]
	match enemy_type:
		EnemyType.SWORD_SKELETON:
			update_sword_skeleton_hades_ai(delta)
		EnemyType.ARCHER_SKELETON:
			update_archer_skeleton_hades_ai(delta)
		EnemyType.STONE_GOLEM:
			update_stone_golem_ai(delta)
	
	# Move the enemy (host only)
	move_and_slide()
	
	# Sync position and state to clients if multiplayer
	if is_multiplayer and is_host:
		sync_enemy_state_to_clients()
	
	# Update sprite facing direction and animations
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false
	
	# Update animations based on state and movement
	update_skeleton_animations()

# NEW: Sync enemy position and state from host to clients
func sync_enemy_state_to_clients():
	# Only sync every few frames to avoid spam
	if Engine.get_process_frames() % 5 != 0:  # Sync every 5th frame (~12 FPS)
		return
	
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node and main_node.has_method("sync_enemy_state_rpc"):
		main_node.sync_enemy_state_rpc.rpc(
			name,  # Enemy identifier
			global_position,
			velocity,
			ai_state,
			current_health
		)

func update_skeleton_animations():
	if not sprite or not sprite.has_method("play") or is_dead:
		return
	
	var animated_sprite = sprite as AnimatedSprite2D
	if not animated_sprite:
		return
	
	var current_anim = animated_sprite.animation
	var should_play_anim = ""
	
	# Determine animation based on AI state
	match ai_state:
		AIState.IDLE:
			should_play_anim = "idle"
		AIState.PATROL:
			should_play_anim = "move" if velocity.length() > 10 else "idle"
		AIState.CHASE:
			should_play_anim = "move"
		AIState.WINDUP:
			should_play_anim = "idle"  # Windup uses idle with flashing
		AIState.ATTACK:
			should_play_anim = "attack"
		AIState.COOLDOWN:
			should_play_anim = "move" if velocity.length() > 10 else "idle"  # Fixed: Check velocity during cooldown
		AIState.REPOSITION:
			should_play_anim = "move"
	
	# Only change animation if different and not playing a one-shot animation
	if should_play_anim != current_anim and not (current_anim in ["attack", "hit", "death"] and animated_sprite.is_playing()):
		animated_sprite.play(should_play_anim)

func play_hit_animation():
	if sprite and sprite.has_method("play") and not is_dead:
		var animated_sprite = sprite as AnimatedSprite2D
		if animated_sprite:
			animated_sprite.play("hit")

func play_death_animation():
	if sprite and sprite.has_method("play"):
		var animated_sprite = sprite as AnimatedSprite2D
		if animated_sprite:
			animated_sprite.play("death")

# OVERHAULED: Clean, Hades-style AI for sword skeletons
func update_sword_skeleton_hades_ai(delta):
	# Get distance to player if we have a valid target
	var distance_to_player = INF
	var player_position = Vector2.ZERO
	
	if target_player and is_instance_valid(target_player):
		distance_to_player = global_position.distance_to(target_player.global_position)
		player_position = target_player.global_position
	
	# Update target to nearest player in multiplayer
	update_nearest_target()
	
	# CROSS-MAP HUNTING: Always chase if player exists (massive detection range)
	var should_chase = false
	if target_player and is_instance_valid(target_player):
		# With 2000 unit detection, they can see across entire map (1600x1000)
		var current_distance = global_position.distance_to(target_player.global_position)
		if current_distance <= SWORD_DETECTION_RANGE:  # Will always be true with 2000 range
			# STAGGERED DETECTION: Add small random delay to prevent clustering
			if not has_meta("detection_delay"):
				var detection_delay = randf_range(0.0, 1.0)  # 0-1 second delay
				set_meta("detection_delay", detection_delay)
				set_meta("detection_start_time", Time.get_ticks_msec() / 1000.0)
			
			var elapsed_time = Time.get_ticks_msec() / 1000.0 - get_meta("detection_start_time")
			if elapsed_time >= get_meta("detection_delay"):
				should_chase = true
				# Store player position for search patterns
				dash_target = target_player.global_position
	
	match ai_state:
		AIState.IDLE:
			# Stand still and look menacing
			velocity = Vector2.ZERO
			
			# IMMEDIATE CHASE if player detected
			if should_chase:
				ai_state = AIState.CHASE
				state_timer = 0.0
				print("🏃 Skeleton SPOTTED PLAYER - immediate chase from idle!")
			# RANDOMIZED transition to patrol - like old logic
			elif state_timer > randf_range(0.5, 1.5):  # Random timing prevents clustering
				ai_state = AIState.PATROL
				state_timer = 0.0
				print("🚶 Skeleton entering patrol")
		
		AIState.PATROL:
			# AGGRESSIVE patrol movement - always looking for player
			handle_patrol_movement()
			
			# IMMEDIATE CHASE if player detected (already checked above)
			if should_chase:
				ai_state = AIState.CHASE
				state_timer = 0.0
				var current_distance = global_position.distance_to(target_player.global_position)
				print("🏃 Skeleton detected player at ", current_distance, " units - CHASING!")
		
		AIState.CHASE:
			# SIMPLE DIRECT CHASE - like the old logic
			if not target_player or not is_instance_valid(target_player):
				return_to_patrol()
				return
			
			# Direct movement toward player with basic obstacle avoidance
			var direction = (target_player.global_position - global_position).normalized()
			var smart_direction = get_safe_direction(direction)
			var safe_direction = apply_boundary_avoidance(smart_direction)
			
			# NATURAL SPEED VARIATION: Prevent perfect clustering during chase
			var base_chase_speed = movement_speed
			var speed_variation = lerp(0.85, 1.15, movement_personality)  # ±15% speed variation
			var natural_chase_speed = base_chase_speed * speed_variation
			
			velocity = safe_direction * natural_chase_speed
			
			var current_distance = global_position.distance_to(target_player.global_position)
			
			# Close enough to attack?
			if current_distance <= SWORD_ATTACK_RANGE:
				start_attack_windup()
			# Lost the player?
			elif current_distance > SWORD_DETECTION_RANGE * LOSE_INTEREST_MULTIPLIER:
				return_to_patrol()
				print("🚶 Skeleton lost interest - too far away")
		
		AIState.WINDUP:
			# Telegraph attack - CANNOT be cancelled once started
			velocity = Vector2.ZERO
			windup_timer += delta
			
			# Visual telegraph with red flashing
			if not is_dead:
				var flash_speed = 10.0  # Fast flashing for urgency
				if int(windup_timer * flash_speed) % 2 == 0:
					sprite.modulate = Color.RED
				else:
					sprite.modulate = get_restore_color()
			
			# Commit to attack after windup time
			if windup_timer >= SWORD_WINDUP_TIME:
				execute_attack()
		
		AIState.ATTACK:
			# Committed attack - lunge forward
			perform_attack_lunge(delta)
			
			# End attack after brief duration
			if state_timer > 0.3:  # Quick attack execution
				start_cooldown()
		
		AIState.COOLDOWN:
			# Recovery period - can reposition but not attack
			handle_cooldown_movement()
			
			# Ready to fight again? Use INDIVIDUAL cooldown time like old logic
			if state_timer >= individual_cooldown_time:
				ai_state = AIState.CHASE if has_nearby_target() else AIState.PATROL
				state_timer = 0.0
				if not is_dead:
					sprite.modulate = get_restore_color()
				print("✅ Skeleton ready to fight again after ", individual_cooldown_time, " seconds!")

# HADES-STYLE AI HELPER FUNCTIONS - Clean and focused

func update_nearest_target():
	# Find nearest player in multiplayer scenarios
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node and "is_multiplayer_game" in main_node and main_node.is_multiplayer_game:
		if "multiplayer_players" in main_node and main_node.multiplayer_players.size() > 1:
			var closest_player = null
			var closest_distance = INF
			
			for player in main_node.multiplayer_players:
				if is_instance_valid(player):
					var distance = global_position.distance_to(player.global_position)
					if distance < closest_distance:
						closest_distance = distance
						closest_player = player
			
			# Switch target if significantly closer
			if closest_player and target_player and closest_player != target_player:
				var current_distance = global_position.distance_to(target_player.global_position)
				if closest_distance < current_distance - 30.0:  # 30 unit threshold
					target_player = closest_player

func handle_patrol_movement():
	# NATURAL hunting patrol with organic movement
	patrol_timer -= get_physics_process_delta_time()
	if patrol_timer <= 0:
		# Get natural patrol direction with personality-based variation
		patrol_direction = get_natural_patrol_direction()
		
		# Apply smart obstacle avoidance to patrol direction
		patrol_direction = get_safe_direction(patrol_direction)
		patrol_direction = apply_boundary_avoidance(patrol_direction)
		
		# Vary patrol change timing based on personality
		var base_patrol_time = PATROL_CHANGE_TIME
		var time_variation = lerp(0.5, 2.0, movement_personality)  # 0.5x to 2x variation
		patrol_timer = base_patrol_time * time_variation
	
	# AGGRESSIVE patrol speed - they're always hunting
	var base_speed_multiplier = 0.9  # INCREASED from 0.8 - faster hunting
	var speed_variation = lerp(0.7, 1.1, movement_personality)  # INCREASED variation range
	var patrol_speed_multiplier = base_speed_multiplier * speed_variation
	
	# Add natural speed fluctuation for organic movement
	var speed_fluctuation = sin(Time.get_ticks_msec() / 1000.0 * movement_personality * 2.0) * 0.15  # INCREASED fluctuation
	patrol_speed_multiplier += speed_fluctuation
	
	velocity = patrol_direction * movement_speed * patrol_speed_multiplier

# ENHANCED: Smart movement with obstacle detection, boundary avoidance, and natural variation
func move_toward_target(target_pos: Vector2, speed_multiplier: float = 1.0) -> Vector2:
	# Add tactical positioning to avoid clustering and create natural spread
	var tactical_target = add_tactical_positioning_offset(target_pos)
	
	# Get raw direction to tactical target
	var raw_direction = (tactical_target - global_position).normalized()
	
	# Apply smart obstacle avoidance using raycasting
	var smart_direction = get_safe_direction(raw_direction)
	
	# Apply boundary avoidance as secondary layer
	var final_direction = apply_boundary_avoidance(smart_direction)
	
	# Add natural speed variation based on personality
	var natural_speed_multiplier = speed_multiplier * lerp(0.8, 1.2, movement_personality)
	
	return final_direction * movement_speed * natural_speed_multiplier

func return_to_patrol():
	ai_state = AIState.PATROL
	state_timer = 0.0
	patrol_timer = 0.0  # Reset to immediately pick new direction

func start_attack_windup():
	ai_state = AIState.WINDUP
	state_timer = 0.0
	windup_timer = 0.0
	
	# Record target position for attack
	if target_player and is_instance_valid(target_player):
		dash_target = target_player.global_position
	else:
		dash_target = global_position + patrol_direction * 50  # Fallback
	
	print("⚡ Skeleton winding up attack - COMMITTED!")

func execute_attack():
	ai_state = AIState.ATTACK
	state_timer = 0.0
	if not is_dead:
		sprite.modulate = get_restore_color()
	
	print("💥 Skeleton executing attack lunge!")

func perform_attack_lunge(delta):
	# Fast lunge toward recorded position
	var direction_to_target = (dash_target - global_position).normalized()
	velocity = direction_to_target * SWORD_ATTACK_SPEED
	
	# Check for damage during lunge
	if target_player and is_instance_valid(target_player):
		var distance_to_player = global_position.distance_to(target_player.global_position)
		if distance_to_player <= SWORD_DAMAGE_RANGE:
			# Only damage once per attack
			if not get_meta("attack_damage_dealt", false):
				deal_damage_to_player()
				set_meta("attack_damage_dealt", true)
				print("🗡️ Skeleton attack hit for ", attack_damage, " damage!")

func start_cooldown():
	ai_state = AIState.COOLDOWN
	state_timer = 0.0
	set_meta("attack_damage_dealt", false)  # Reset damage flag
	
	# INDIVIDUAL cooldown times like old logic to prevent clustering
	individual_cooldown_time = randf_range(1.5, 3.0)  # Each skeleton different timing
	print("😴 Skeleton entering cooldown for ", individual_cooldown_time, " seconds")
	
	# Slight knockback for dramatic effect
	if target_player and is_instance_valid(target_player):
		var away_from_player = (global_position - target_player.global_position).normalized()
		velocity = away_from_player * 100  # Brief knockback
	else:
		velocity = Vector2.ZERO
	
	print("😴 Skeleton entering cooldown")

func handle_cooldown_movement():
	# SIMPLE COOLDOWN - mostly stationary like old logic
	velocity = Vector2.ZERO
	
	# Add minimal movement to avoid being completely static
	if state_timer > 0.5:  # After half second of cooldown
		var slight_movement = Vector2(randf_range(-8, 8), randf_range(-8, 8))
		velocity = slight_movement

func has_nearby_target() -> bool:
	if target_player and is_instance_valid(target_player):
		var distance = global_position.distance_to(target_player.global_position)
		return distance <= SWORD_DETECTION_RANGE
	return false

# Hades-style AI for archer skeletons: Idle → Patrol → Reposition → Windup → Attack → Cooldown
func update_archer_skeleton_hades_ai(delta):
	# Calculate distance to player only if we have a valid target
	var distance_to_player = INF  # Default to infinite distance if no target
	
	if target_player and is_instance_valid(target_player):
		distance_to_player = global_position.distance_to(target_player.global_position)
	
	match ai_state:
		AIState.IDLE:
			velocity = Vector2.ZERO
			# Brief idle before starting patrol
			if state_timer > randf_range(0.5, 1.0):
				ai_state = AIState.PATROL
				state_timer = 0.0
				patrol_timer = 0.0  # Reset patrol timer when entering patrol
		
		AIState.PATROL:
			# Smart patrol - always tracking from anywhere on map
			patrol_timer -= delta
			if patrol_timer <= 0:
				if target_player and is_instance_valid(target_player):
					var current_distance = global_position.distance_to(target_player.global_position)
					
					# Only act "unaware" when within optimal shooting range (pretend we haven't noticed yet)
					if current_distance <= ARCHER_OPTIMAL_RANGE * 1.5:  # 300 units - act unaware when in good range
						patrol_direction = get_new_patrol_direction()  # Random patrol
					else:
						# Always creep toward player from anywhere on map
						var toward_player = (target_player.global_position - global_position).normalized()
						var random_angle = randf_range(-1.0, 1.0)  # Moderate randomness for archers
						var original_direction = toward_player.rotated(random_angle).normalized()
						patrol_direction = apply_boundary_avoidance(original_direction)
				else:
					patrol_direction = get_new_patrol_direction()
				
				patrol_timer = PATROL_CHANGE_TIME
			
			velocity = patrol_direction * movement_speed * 0.4
			
			# Check if we should shoot
			if target_player and is_instance_valid(target_player):
				var current_distance = global_position.distance_to(target_player.global_position)
				
				# Archers have longer detection range and shoot from afar
				var archer_detection_range = DETECTION_RANGE * 1.5  # 450 units
				
				if current_distance <= archer_detection_range:
					if current_distance < ARCHER_MIN_RANGE:
						# Too close - need to reposition
						ai_state = AIState.REPOSITION
						state_timer = 0.0
						find_reposition_target()
						print("🏃 Archer skeleton needs to reposition - player too close!")
					else:
						# Good range - prepare to shoot
						ai_state = AIState.WINDUP
						state_timer = 0.0
						windup_timer = 0.0
						print("🏹 Archer skeleton detected player - preparing to shoot from distance: ", current_distance)
		
		AIState.REPOSITION:
			# Dynamically adjust reposition target as player moves
			if target_player and is_instance_valid(target_player):
				# Recalculate reposition target to maintain distance from moving player
				if Engine.get_process_frames() % 30 == 0:  # Update every 0.5 seconds
					find_reposition_target()
			
			# Move to optimal shooting position with boundary avoidance
			var raw_direction = (reposition_target - global_position).normalized()
			var direction = apply_boundary_avoidance(raw_direction)
			velocity = direction * ARCHER_REPOSITION_SPEED
			
			# Check current distance to player
			if target_player and is_instance_valid(target_player):
				var current_distance = global_position.distance_to(target_player.global_position)
				
				# Check if we've reached good position or are far enough from player
				if current_distance >= ARCHER_MIN_RANGE:
					# Far enough from player - can shoot now
					ai_state = AIState.WINDUP
					state_timer = 0.0
					windup_timer = 0.0
					print("🎯 Archer skeleton repositioned - preparing to shoot!")
				elif global_position.distance_to(reposition_target) <= 20.0:
					# Reached target position but player still too close - find new position
					find_reposition_target()
					print("🔄 Archer skeleton reached position but player still close - finding new spot")
				elif current_distance > LOSE_INTEREST_RANGE:
					ai_state = AIState.PATROL
					state_timer = 0.0
					print("🚶 Archer skeleton lost interest - returning to patrol")
			else:
				# Lost target - return to patrol
				ai_state = AIState.PATROL
				state_timer = 0.0
				print("❓ Archer skeleton lost target during reposition - returning to patrol")
		
		AIState.WINDUP:
			# Telegraph phase - show attack intent
			velocity = Vector2.ZERO
			windup_timer += delta
			
			# Flash sprite to show windup (only if not dead)
			if not is_dead:
				if int(windup_timer * 6) % 2 == 0:
					sprite.modulate = Color.YELLOW
				else:
					sprite.modulate = get_restore_color()
			
			# After windup, commit to attack
			if windup_timer >= ARCHER_WINDUP_TIME:
				ai_state = AIState.ATTACK
				state_timer = 0.0
				if not is_dead:
					sprite.modulate = get_restore_color()
				print("💥 Archer skeleton firing arrow!")
		
		AIState.ATTACK:
			# Committed attack - cannot be cancelled
			velocity = Vector2.ZERO
			
			# Fire arrow immediately when entering attack state
			if state_timer < 0.1:
				fire_arrow()
			
			# Attack animation lasts for a short time
			if state_timer >= 0.3:
				ai_state = AIState.COOLDOWN
				state_timer = 0.0
				last_attack_time = Time.get_ticks_msec() / 1000.0
				individual_cooldown_time = randf_range(6.0, 15.0)  # Set individual cooldown time
				print("😴 Archer skeleton entering cooldown for ", individual_cooldown_time, " seconds")
		
		AIState.COOLDOWN:
			# Recovery phase - slow tactical movement during cooldown
			if target_player and is_instance_valid(target_player):
				var current_distance = global_position.distance_to(target_player.global_position)
				
				# Move to maintain optimal distance during cooldown
				if current_distance < ARCHER_OPTIMAL_RANGE:
					# Too close - back away slowly
					var away_direction = (global_position - target_player.global_position).normalized()
					var retreat_direction = apply_boundary_avoidance(away_direction)
					velocity = retreat_direction * movement_speed * 0.3
				else:
					# Good distance - slow patrol
					patrol_timer -= delta
					if patrol_timer <= 0:
						patrol_direction = get_new_patrol_direction()
						patrol_timer = PATROL_CHANGE_TIME
					velocity = patrol_direction * movement_speed * 0.3
			else:
				velocity = Vector2.ZERO
			
			# Check if player is nearby even during cooldown
			if target_player and is_instance_valid(target_player):
				var current_distance = global_position.distance_to(target_player.global_position)
				if current_distance <= DETECTION_RANGE and state_timer > individual_cooldown_time * 0.5:
					# Flash to show we're aware of player but still on cooldown
					if int(state_timer * 4) % 2 == 0:
						sprite.modulate = Color(1.0, 1.0, 0.7)  # Light yellow
					else:
						sprite.modulate = get_restore_color()
				else:
					# Normal cooldown visual
					if not is_dead:
						if int(state_timer * 3) % 2 == 0:
							sprite.modulate = Color(0.7, 1.0, 0.7)  # Slightly green
						else:
							sprite.modulate = get_restore_color()
			
			# Return to patrol after individual cooldown time
			if state_timer >= individual_cooldown_time:
				ai_state = AIState.PATROL
				state_timer = 0.0
				patrol_timer = 0.0  # Reset patrol timer to immediately check for players
				if not is_dead:
					sprite.modulate = get_restore_color()
				print("🔄 Archer skeleton ready after ", individual_cooldown_time, " seconds - returning to patrol")

# Stone Golem AI: Similar to sword skeleton but slower and with ground pound attack
func update_stone_golem_ai(delta):
	# Calculate distance to player only if we have a valid target
	var distance_to_player = INF  # Default to infinite distance if no target
	
	if target_player and is_instance_valid(target_player):
		distance_to_player = global_position.distance_to(target_player.global_position)
	
	match ai_state:
		AIState.IDLE:
			velocity = Vector2.ZERO
			# Longer idle time for imposing presence
			if state_timer > randf_range(1.0, 2.0):
				ai_state = AIState.PATROL
				state_timer = 0.0
				patrol_timer = 0.0  # Reset patrol timer when entering patrol
		
		AIState.PATROL:
			# Slow, methodical patrol - always tracking from anywhere
			patrol_timer -= delta
			if patrol_timer <= 0:
				if target_player and is_instance_valid(target_player):
					var current_distance = global_position.distance_to(target_player.global_position)
					
					# Only act "unaware" when VERY close
					if current_distance <= GOLEM_GROUND_POUND_RANGE * 1.5:  # 225 units - pretend unaware when close
						# Random patrol when very close
						patrol_direction = get_new_patrol_direction()
					else:
						# Always slowly move toward player from anywhere on map
						var toward_player = (target_player.global_position - global_position).normalized()
						var slight_variation = randf_range(-0.5, 0.5)  # Small randomness
						var original_direction = toward_player.rotated(slight_variation).normalized()
						patrol_direction = apply_boundary_avoidance(original_direction)
				else:
					patrol_direction = get_new_patrol_direction()
				
				patrol_timer = PATROL_CHANGE_TIME * 1.5  # Slower direction changes
			
			# Golems move at their full slow speed during patrol
			velocity = patrol_direction * movement_speed
			
			# Detect player at shorter range than skeletons
			if target_player and is_instance_valid(target_player):
				var current_distance = global_position.distance_to(target_player.global_position)
				var golem_detection = DETECTION_RANGE * 0.8  # 240 units
				
				if current_distance <= golem_detection:
					ai_state = AIState.CHASE
					state_timer = 0.0
					print("🗿 Stone golem detected player - beginning slow pursuit!")
		
		AIState.CHASE:
			# Slow but relentless pursuit
			if not target_player or not is_instance_valid(target_player):
				# Lost target - return to patrol
				ai_state = AIState.PATROL
				state_timer = 0.0
				print("❓ Stone golem lost target during chase - returning to patrol")
				return
			
			# Chase with boundary avoidance
			var raw_direction = (target_player.global_position - global_position).normalized()
			var direction = apply_boundary_avoidance(raw_direction)
			velocity = direction * movement_speed
			
			# Recalculate distance for state transitions
			var current_distance = global_position.distance_to(target_player.global_position)
			
			# When close enough, prepare for ground pound
			if current_distance <= GOLEM_GROUND_POUND_RANGE:
				ai_state = AIState.WINDUP
				state_timer = 0.0
				windup_timer = 0.0
				print("⚡ Stone golem preparing GROUND POUND attack!")
			# Lose interest at much closer range (persistent but slow)
			elif current_distance > LOSE_INTEREST_RANGE * 0.7:  # 280 units instead of 400
				ai_state = AIState.PATROL
				state_timer = 0.0
				print("🚶 Stone golem lost interest - returning to patrol")
		
		AIState.WINDUP:
			# Long telegraph phase for powerful attack
			velocity = Vector2.ZERO
			windup_timer += delta
			
			# Dramatic buildup effect (only if not dead)
			if not is_dead:
				# Intense flashing during long windup
				if int(windup_timer * 10) % 2 == 0:
					sprite.modulate = Color.ORANGE  # Orange for ground pound energy
				else:
					sprite.modulate = get_restore_color()
			
			# Much longer windup than skeletons
			if windup_timer >= GOLEM_WINDUP_TIME:
				ai_state = AIState.ATTACK
				state_timer = 0.0
				if not is_dead:
					sprite.modulate = get_restore_color()
				print("💥 Stone golem executing GROUND POUND!")
		
		AIState.ATTACK:
			# Ground pound attack with area damage
			velocity = Vector2.ZERO  # Stationary during ground pound
			
			# Execute ground pound immediately when entering attack state
			if state_timer < 0.1:
				perform_ground_pound_attack()
			
			# Attack animation lasts longer than skeleton attacks
			if state_timer >= 1.0:
				ai_state = AIState.COOLDOWN
				state_timer = 0.0
				last_attack_time = Time.get_ticks_msec() / 1000.0
				individual_cooldown_time = randf_range(3.0, 5.0)  # Longer cooldown
				print("😴 Stone golem entering cooldown for ", individual_cooldown_time, " seconds")
		
		AIState.COOLDOWN:
			# Recovery phase - very slow movement while vulnerable
			if target_player and is_instance_valid(target_player):
				# Slowly back away during cooldown
				var away_direction = (global_position - target_player.global_position).normalized()
				var retreat_direction = apply_boundary_avoidance(away_direction)
				velocity = retreat_direction * movement_speed * 0.15  # Very slow for golems
			else:
				velocity = Vector2.ZERO
			
			# Check if player is nearby even during cooldown
			if target_player and is_instance_valid(target_player):
				var current_distance = global_position.distance_to(target_player.global_position)
				if current_distance <= DETECTION_RANGE * 0.8 and state_timer > individual_cooldown_time * 0.7:
					# Show awareness of player near end of cooldown
					if not is_dead:
						if int(state_timer * 6) % 2 == 0:
							sprite.modulate = Color(1.0, 0.6, 0.6)  # Red warning
						else:
							sprite.modulate = Color(0.6, 0.6, 1.0)  # Blue vulnerability
				else:
					# Normal vulnerability visual
					if not is_dead:
						if int(state_timer * 2) % 2 == 0:
							sprite.modulate = Color(0.6, 0.6, 1.0)  # Blue vulnerability
						else:
							sprite.modulate = get_restore_color()
			
			# Return to patrol after cooldown
			if state_timer >= individual_cooldown_time:
				ai_state = AIState.PATROL
				state_timer = 0.0
				patrol_timer = 0.0  # Reset patrol timer to immediately check for players
				if not is_dead:
					sprite.modulate = get_restore_color()
				print("🔄 Stone golem ready after ", individual_cooldown_time, " seconds - resuming patrol")

func perform_ground_pound_attack():
	# Create area damage around the golem
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node and main_node.has_method("handle_golem_ground_pound"):
		main_node.handle_golem_ground_pound(global_position, GOLEM_ATTACK_RANGE, attack_damage)
	else:
		# Fallback: Direct damage check
		if target_player and is_instance_valid(target_player):
			var distance_to_player = global_position.distance_to(target_player.global_position)
			if distance_to_player <= GOLEM_ATTACK_RANGE:
				deal_damage_to_player()
				print("💥 GROUND POUND hit player for ", attack_damage, " damage!")
	
	print("🌊 Stone golem GROUND POUND creates shockwave in ", GOLEM_ATTACK_RANGE, " unit radius!")

func find_reposition_target():
	# Find a position that's at safe distance from player
	if not target_player or not is_instance_valid(target_player):
		# No target - just move to a random position
		reposition_target = global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		return
	
	var away_from_player = (global_position - target_player.global_position).normalized()
	var angle_variation = randf_range(-0.8, 0.8)  # More variation for interesting positioning
	away_from_player = away_from_player.rotated(angle_variation)
	# Use a safe distance that's well beyond minimum range
	var safe_distance = ARCHER_MIN_RANGE + 40.0  # 80 + 40 = 120 units away
	reposition_target = target_player.global_position + away_from_player * safe_distance
	
	# Ensure reposition target stays within arena bounds
	var arena_margin = 50
	var arena_width = 1600
	var arena_height = 1000
	
	reposition_target.x = clamp(reposition_target.x, arena_margin, arena_width - arena_margin)
	reposition_target.y = clamp(reposition_target.y, arena_margin, arena_height - arena_margin)



func deal_damage_to_player():
	if target_player and target_player.has_method("take_damage"):
		target_player.take_damage(attack_damage)
		print("⚔️ Enemy dealt ", attack_damage, " damage to player!")

func fire_arrow():
	if not target_player or not is_instance_valid(target_player):
		return  # Can't fire without a target
	
	var arrow_direction = (target_player.global_position - global_position).normalized()
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node:
		main_node.create_enemy_arrow(global_position, arrow_direction, attack_damage)

# Handle taking damage with event-based multiplayer sync
func take_damage(amount: float):
	if is_dead:
		return  # Don't take damage if already dead
	
	var main_node = get_tree().get_first_node_in_group("main")
	var is_multiplayer = main_node and main_node.is_multiplayer_game
	
	# MULTIPLAYER FIX: Both host and client can damage enemies
	current_health -= amount
	print("💔 Enemy took ", amount, " damage! Health: ", current_health, "/", max_health)
	
	# Update health bar immediately for local feedback
	update_health_bar()
	
	# In multiplayer, broadcast damage event to synchronize across peers
	if is_multiplayer:
		var enemy_id = get_meta("enemy_id", 0)
		if main_node.has_method("sync_damage_event"):
			# Only send RPC if we're not already processing a remote damage event
			if not get_meta("processing_remote_damage", false):
				# Send damage event to all other players
				main_node.sync_damage_event.rpc(enemy_id, amount)
				print("🤝 PEER: Broadcasting damage event for enemy ", enemy_id, " - damage: ", amount)
	
	# Check if dead and handle death
	if current_health <= 0:
		# Broadcast death event before dying
		if is_multiplayer:
			var enemy_id = get_meta("enemy_id", 0)
			if main_node.has_method("sync_enemy_death_event"):
				# Only send death RPC if not already processing remote death
				if not get_meta("processing_remote_death", false):
					main_node.sync_enemy_death_event.rpc(enemy_id)
					print("💀 PEER: Broadcasting death event for enemy ", enemy_id)
		die()
		return  # Exit immediately after death
	
	# Play hit animation only if not dead
	play_hit_animation()
	
	# Flash red when hit (only if not dead)
	if not is_dead:
		sprite.modulate = Color.RED
		create_tween().tween_property(sprite, "modulate", get_restore_color(), 0.2)

# Function to sync health from host to clients
func sync_health(new_health: float, new_max_health: float):
	current_health = new_health
	max_health = new_max_health
	update_health_bar()
	
	# Check if should die based on synced health
	if current_health <= 0 and not is_dead:
		die()

func update_health_bar():
	if health_bar:
		var health_percentage = current_health / max_health
		health_bar.size.x = 30 * health_percentage
		
		# Color based on health
		if health_percentage > 0.6:
			health_bar.color = Color(0.0, 0.8, 0.0, 1.0)  # Green
		elif health_percentage > 0.3:
			health_bar.color = Color(0.8, 0.8, 0.0, 1.0)  # Yellow
		else:
			health_bar.color = Color(0.8, 0.0, 0.0, 1.0)  # Red

func die():
	if is_dead:
		return  # Prevent multiple death calls
	
	is_dead = true
	velocity = Vector2.ZERO  # Stop all movement immediately
	current_health = 0  # Ensure health is exactly 0
	
	print("💀 ", EnemyType.keys()[enemy_type], " has died!")
	play_death_animation()
	
	# Update health bar to show empty
	update_health_bar()
	
	# Try to drop healing orb
	try_drop_healing_orb()
	
	# Notify main scene for cleanup
	if get_tree().get_first_node_in_group("main").has_method("remove_enemy"):
		get_tree().get_first_node_in_group("main").remove_enemy(self)
	
	# Remove after death animation
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func try_drop_healing_orb():
	# Check if we should drop a healing orb based on enemy type
	var drop_chance = HealingOrb.get_drop_chance(enemy_type)
	
	if randf() <= drop_chance:
		# Get main scene to spawn orb
		var main_scene = get_tree().get_first_node_in_group("main")
		if main_scene and main_scene.has_method("spawn_healing_orb"):
			# Get player count for scaling
			var player_count = get_player_count()
			var orb_count = HealingOrb.get_orb_count(enemy_type, player_count)
			
			print("💚 ", EnemyType.keys()[enemy_type], " dropping ", orb_count, " healing orb(s) (", int(drop_chance * 100), "% chance)")
			
			# Spawn multiple orbs if needed (for high-value enemies)
			for i in range(orb_count):
				var spawn_offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
				main_scene.spawn_healing_orb(global_position + spawn_offset, enemy_type, player_count)
		else:
			print("⚠️ Could not spawn healing orb - main scene not found or missing spawn_healing_orb method")

func get_player_count() -> int:
	# Get current player count for scaling
	var players = get_tree().get_nodes_in_group("player")
	return max(1, players.size())

func get_enemy_type_name() -> String:
	return EnemyType.keys()[enemy_type]

func apply_elite_modulation():
	# Apply purple tint for elite skeletons
	if sprite:
		sprite.modulate = Color(0.8, 0.3, 0.8, 1.0)  # Purple tint
		# Store the elite color for restoration after hit flashes
		sprite.set_meta("elite_color", Color(0.8, 0.3, 0.8, 1.0))
		print("Elite skeleton purple tint applied")

func get_restore_color() -> Color:
	# Get the proper color to restore sprite to (elite color if exists, otherwise white)
	if sprite and sprite.has_meta("elite_color"):
		return sprite.get_meta("elite_color")
	return Color.WHITE 

# Find the nearest player target (works for both single-player and multiplayer)
func find_nearest_player_target():
	var main_node = get_tree().get_first_node_in_group("main")
	if not main_node:
		return
	
	# Check if this is multiplayer mode
	var is_multiplayer = false
	if "is_multiplayer_game" in main_node:
		is_multiplayer = main_node.is_multiplayer_game
	
	var previous_target = target_player
	
	if is_multiplayer and "multiplayer_players" in main_node:
		# Multiplayer: Find nearest player from multiplayer_players array
		var players = main_node.multiplayer_players
		if players.size() > 0:
			var nearest_player = null
			var nearest_distance = INF
			
			for player in players:
				if is_instance_valid(player):
					var distance = global_position.distance_to(player.global_position)
					if distance < nearest_distance:
						nearest_distance = distance
						nearest_player = player
			
			target_player = nearest_player
			# AGGRESSIVE: If we found a new target, immediately start hunting
			if target_player and target_player != previous_target and enemy_type == EnemyType.SWORD_SKELETON:
				print("🎯 Skeleton found new multiplayer target - switching to hunting mode!")
		else:
			target_player = null
	else:
		# Single-player: Find all nodes in the "player" group
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			# Simply find the first valid player (should only be one in single player)
			for player in players:
				if is_instance_valid(player):
					target_player = player
					# AGGRESSIVE: If we found a new target, immediately start hunting
					if target_player != previous_target and enemy_type == EnemyType.SWORD_SKELETON:
						var distance = global_position.distance_to(player.global_position)
						print("🎯 Skeleton found player at distance: ", distance, " - starting hunt!")
					break
		else:
			target_player = null

# Update target periodically in case players move or new players join
func update_player_target():
	# Re-find nearest player every few seconds
	find_nearest_player_target() 

# NEW: Handle damage received from other players (no additional sync)
func apply_remote_damage(amount: float):
	if is_dead:
		return  # Don't take damage if already dead
	
	# Set flag to prevent sync loops
	set_meta("processing_remote_damage", true)
	
	# Apply damage locally without triggering more sync events
	current_health -= amount
	print("🤝 PEER: Applied remote damage ", amount, " - Health: ", current_health, "/", max_health)
	
	# Update health bar
	update_health_bar()
	
	# Check if dead and handle death (without additional sync)
	if current_health <= 0:
		set_meta("processing_remote_death", true)
		die()
		return
	
	# Play hit animation
	play_hit_animation()
	
	# Flash red when hit
	if not is_dead:
		sprite.modulate = Color.RED
		create_tween().tween_property(sprite, "modulate", get_restore_color(), 0.2)
	
	# Clear flag after processing
	set_meta("processing_remote_damage", false) 

func get_shared_rng() -> RandomNumberGenerator:
	# Get shared RNG from Main scene for deterministic behavior
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node and main_node.has_method("get_shared_rng"):
		return main_node.shared_rng
	else:
		# Fallback to global RNG if not available
		return RandomNumberGenerator.new() 

# Helper methods for multiplayer position synchronization
func get_enemy_velocity() -> Vector2:
	return velocity

func set_enemy_velocity(new_velocity: Vector2):
	velocity = new_velocity

func get_current_state() -> String:
	if ai_state == AIState.IDLE:
		return "idle"
	elif ai_state == AIState.PATROL:
		return "patrol"  
	elif ai_state == AIState.CHASE:
		return "chase"
	elif ai_state == AIState.ATTACK:
		return "attack"
	else:
		return "unknown"

func set_current_state(state_name: String):
	match state_name:
		"idle":
			ai_state = AIState.IDLE
		"patrol":
			ai_state = AIState.PATROL
		"chase":
			ai_state = AIState.CHASE
		"attack":
			ai_state = AIState.ATTACK

func get_current_animation() -> String:
	if sprite and sprite.animation:
		return sprite.animation
	return ""

func play_sync_animation(animation_name: String):
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name) 

# SIMPLE DIRECT CHASE - remove complex randomization during chase
# This function is no longer used for chase but kept for patrol variety
func get_natural_patrol_movement() -> Vector2:
	# Only used for patrol movement, not chase
	wander_angle += randf_range(-0.05, 0.05)
	return Vector2(cos(wander_angle), sin(wander_angle)).normalized()

func get_natural_patrol_direction() -> Vector2:
	var base_direction: Vector2
	
	if target_player and is_instance_valid(target_player):
		# ALWAYS hunt toward player - no wandering off randomly
		var to_player = (target_player.global_position - global_position).normalized()
		
		# Add natural variation to hunting approach (NOT wandering away)
		var approach_angle_variation = lerp(0.1, 0.3, movement_personality)  # Small angle variation
		var random_angle = randf_range(-approach_angle_variation, approach_angle_variation)
		
		# Apply the variation to the hunting direction
		base_direction = to_player.rotated(random_angle)
		
		# Ensure we're still generally moving toward player
		if base_direction.dot(to_player) < 0.5:  # If angle too extreme, correct it
			base_direction = to_player.rotated(random_angle * 0.5)  # Reduce the angle
		
		print("🔍 Skeleton hunting toward player with approach variation: ", movement_personality)
	else:
		# NO RANDOM WANDERING - actively search for player in last known direction
		if dash_target != Vector2.ZERO:
			# Move toward last known player position
			base_direction = (dash_target - global_position).normalized()
		else:
			# Search pattern toward map center where player likely is
			var map_center = Vector2(800, 500)  # Center of 1600x1000 arena
			base_direction = (map_center - global_position).normalized()
		
		print("🔍 Skeleton searching for player - no random wandering")
	
	return base_direction

func add_tactical_positioning_offset(base_target: Vector2) -> Vector2:
	# Add smart positioning and STRONG wall avoidance
	var tactical_target = base_target
	
	# STRONG wall repulsion to prevent clustering against walls
	var wall_repulsion = Vector2.ZERO
	var wall_repulsion_distance = 200.0  # INCREASED - stay further from walls
	var arena_width = 1600
	var arena_height = 1000
	
	# Check distance to each wall and apply strong repulsion
	if global_position.x < wall_repulsion_distance:
		# Too close to left wall
		wall_repulsion.x = (wall_repulsion_distance - global_position.x) * 2.0  # Strong push right
	elif global_position.x > arena_width - wall_repulsion_distance:
		# Too close to right wall  
		wall_repulsion.x = -(global_position.x - (arena_width - wall_repulsion_distance)) * 2.0  # Strong push left
	
	if global_position.y < wall_repulsion_distance:
		# Too close to top wall
		wall_repulsion.y = (wall_repulsion_distance - global_position.y) * 2.0  # Strong push down
	elif global_position.y > arena_height - wall_repulsion_distance:
		# Too close to bottom wall
		wall_repulsion.y = -(global_position.y - (arena_height - wall_repulsion_distance)) * 2.0  # Strong push up
	
	# Apply wall repulsion first (highest priority)
	if wall_repulsion.length() > 0:
		tactical_target += wall_repulsion
		print("🚧 Strong wall repulsion applied: ", wall_repulsion.length())
	
	# Anti-clustering with other enemies (secondary priority)
	var nearby_enemies = get_tree().get_nodes_in_group("enemies")
	var repulsion_force = Vector2.ZERO
	var min_distance = 60.0  # REDUCED - allow closer formations but prevent overlap
	
	for other_enemy in nearby_enemies:
		if other_enemy == self or not is_instance_valid(other_enemy):
			continue
			
		var distance_to_other = global_position.distance_to(other_enemy.global_position)
		if distance_to_other < min_distance and distance_to_other > 0:
			# Push away from other enemy
			var away_direction = (global_position - other_enemy.global_position).normalized()
			var repulsion_strength = (min_distance - distance_to_other) / min_distance
			repulsion_force += away_direction * repulsion_strength * 25.0
	
	# Apply enemy separation (lower priority than walls)
	if repulsion_force.length() > 0:
		tactical_target += repulsion_force * 0.5  # REDUCED strength to prioritize wall avoidance
		
		# Add randomness to avoid perfect formations
		var random_scatter = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		tactical_target += random_scatter
	
	return tactical_target 
