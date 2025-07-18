extends CharacterBody2D
class_name Enemy

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

# Attack telegraph system
var windup_timer: float = 0.0
var individual_cooldown_time: float = 0.0

# Visual and collision components
var sprite: Node2D
var health_bar_container: Node2D
var health_bar: ColorRect
var collision_shape: CollisionShape2D

# Constants for Hades-style AI
const PATROL_CHANGE_TIME: float = 3.0
const DETECTION_RANGE: float = 100.0
const CHASE_RANGE: float = 120.0
const LOSE_INTEREST_RANGE: float = 150.0

# Sword skeleton constants
const SWORD_DASH_RANGE: float = 80.0
const SWORD_ATTACK_RANGE: float = 40.0
const SWORD_WINDUP_TIME: float = 0.8
const SWORD_DASH_SPEED: float = 200.0
const SWORD_COOLDOWN_TIME: float = 2.0

# Archer skeleton constants
const ARCHER_OPTIMAL_RANGE: float = 120.0
const ARCHER_MIN_RANGE: float = 60.0
const ARCHER_WINDUP_TIME: float = 1.2
const ARCHER_COOLDOWN_TIME: float = 3.0
const ARCHER_REPOSITION_SPEED: float = 100.0

# Stone golem constants
const GOLEM_GROUND_POUND_RANGE: float = 100.0
const GOLEM_ATTACK_RANGE: float = 60.0
const GOLEM_WINDUP_TIME: float = 2.0
const GOLEM_COOLDOWN_TIME: float = 4.0
const GOLEM_MOVE_SPEED: float = 30.0

# Base enemy stats (before scaling)
const BASE_ENEMY_STATS = {
	EnemyType.SWORD_SKELETON: {
		"health": 60.0,
		"damage": 15.0,
		"speed": 70.0,
		"attack_cooldown": SWORD_COOLDOWN_TIME,
		"attack_range": SWORD_ATTACK_RANGE
	},
	EnemyType.ARCHER_SKELETON: {
		"health": 25.0,
		"damage": 24.0,
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
	
	# Set collision shape position based on enemy type
	match enemy_type:
		EnemyType.STONE_GOLEM:
			# Position collision to match sprite exactly (both are centered)
			# No offset needed - sprite and collision both center on node position
			collision_shape.position = Vector2(0, 0)
		_:
			# Default positioning for other enemies
			collision_shape.position = Vector2(0, 0)
	
	add_child(collision_shape)
	
	print("✨ Set collision size: ", shape.size, " at position: ", collision_shape.position, " for ", EnemyType.keys()[enemy_type])
	
	# Debug collision bounds for golem
	if enemy_type == EnemyType.STONE_GOLEM:
		print("🗿 GOLEM COLLISION DEBUG:")
		print("   Collision shape size: ", shape.size)
		print("   Collision shape position: ", collision_shape.position)
		print("   Collision layer: ", collision_layer)
		print("   Collision mask: ", collision_mask)
		print("   Expected collision bounds: Left:", -shape.size.x/2, " Right:", shape.size.x/2, " Top:", -shape.size.y/2, " Bottom:", shape.size.y/2)
	
	# Set collision layers
	collision_layer = 4  # Enemy layer
	collision_mask = 1 | 2  # Collides with player and walls
	
	# Find player
	target_player = get_tree().get_first_node_in_group("main").player
	
	# Initialize AI state
	ai_state = AIState.IDLE
	state_timer = 0.0
	patrol_timer = 0.0
	
	# Set initial patrol direction
	patrol_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	print("Enemy created: ", EnemyType.keys()[enemy_type])
	
	# Final verification for golem collision setup
	if enemy_type == EnemyType.STONE_GOLEM:
		await get_tree().process_frame  # Wait one frame for setup to complete
		print("🗿 GOLEM FINAL VERIFICATION:")
		print("   Node position: ", global_position)
		print("   Collision shape exists: ", collision_shape != null)
		if collision_shape and collision_shape.shape:
			print("   Final collision size: ", collision_shape.shape.size)
		print("   Is collision enabled: ", collision_shape.disabled if collision_shape else "N/A")

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
	if not target_player or not is_instance_valid(target_player) or is_dead:
		return
	
	state_timer += delta
	
	# Update AI behavior based on enemy type
	match enemy_type:
		EnemyType.SWORD_SKELETON:
			update_sword_skeleton_hades_ai(delta)
		EnemyType.ARCHER_SKELETON:
			update_archer_skeleton_hades_ai(delta)
		EnemyType.STONE_GOLEM:
			update_stone_golem_ai(delta)
	
	# Move the enemy
	move_and_slide()
	
	# Update sprite facing direction and animations
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false
	
	# Update animations based on state and movement
	update_skeleton_animations()

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

# Hades-style AI for sword skeletons: Idle → Patrol → Chase → Windup → Attack → Cooldown
func update_sword_skeleton_hades_ai(delta):
	var distance_to_player = global_position.distance_to(target_player.global_position)
	
	# Check if player is ranged character for more aggressive behavior
	var is_ranged_player = false
	var player_character_type = ""
	if target_player.has_method("get_character_type"):
		player_character_type = target_player.get_character_type()
		is_ranged_player = (player_character_type == "Huntress" or player_character_type == "Evil Wizard")
	
	# Adjust detection and chase ranges based on player type
	var detection_range = DETECTION_RANGE
	var lose_interest_range = LOSE_INTEREST_RANGE
	
	if is_ranged_player:
		detection_range = DETECTION_RANGE * 1.4  # 140 units instead of 100
		lose_interest_range = LOSE_INTEREST_RANGE * 1.3  # 195 units instead of 150
		# print("🎯 Sword skeleton targeting ranged player: ", player_character_type)
	
	match ai_state:
		AIState.IDLE:
			velocity = Vector2.ZERO
			# Brief idle before starting patrol
			if state_timer > randf_range(0.5, 1.5):
				ai_state = AIState.PATROL
				state_timer = 0.0
		
		AIState.PATROL:
			# Patrol around looking for player with subtle bias toward player direction
			patrol_timer -= delta
			if patrol_timer <= 0:
				if distance_to_player > detection_range:
					# When out of detection range, patrol with bias toward player
					var toward_player = (target_player.global_position - global_position).normalized()
					var random_angle = randf_range(-1.2, 1.2)  # About 70 degrees of randomness
					# More aggressive bias for ranged players
					if is_ranged_player:
						random_angle = randf_range(-0.8, 0.8)  # Tighter cone (±45 degrees)
					var biased_direction = toward_player.rotated(random_angle)
					patrol_direction = biased_direction.normalized()
				else:
					# Within detection range, use pure random patrol
					patrol_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				patrol_timer = PATROL_CHANGE_TIME
			
			# Move faster when targeting ranged players
			var patrol_speed = movement_speed * 0.5
			if is_ranged_player and distance_to_player > detection_range:
				patrol_speed = movement_speed * 0.65  # 30% faster when hunting ranged players
			
			velocity = patrol_direction * patrol_speed
			
			# Detect player and start chase
			if distance_to_player <= detection_range:
				ai_state = AIState.CHASE
				state_timer = 0.0
				if is_ranged_player:
					print("🗡️ Sword skeleton detected ranged player (", player_character_type, ") - entering aggressive chase!")
				else:
					print("🗡️ Sword skeleton detected player - entering chase!")
		
		AIState.CHASE:
			# Chase player until in dash range
			var direction = (target_player.global_position - global_position).normalized()
			# Move faster when chasing ranged players
			var chase_speed = movement_speed
			if is_ranged_player:
				chase_speed = movement_speed * 1.15  # 15% faster when chasing ranged players
			
			velocity = direction * chase_speed
			
			# When close enough, prepare to dash attack
			if distance_to_player <= SWORD_DASH_RANGE:
				ai_state = AIState.WINDUP
				state_timer = 0.0
				windup_timer = 0.0
				dash_target = target_player.global_position
				print("⚡ Sword skeleton winding up for dash attack!")
			# Lose interest if player gets too far (more persistent with ranged players)
			elif distance_to_player > lose_interest_range:
				ai_state = AIState.PATROL
				state_timer = 0.0
				if is_ranged_player:
					print("🚶 Sword skeleton lost interest in ranged player - returning to patrol")
				else:
					print("🚶 Sword skeleton lost interest - returning to patrol")
		
		AIState.WINDUP:
			# Telegraph phase - show attack intent
			velocity = Vector2.ZERO
			windup_timer += delta
			
			# Flash sprite to show windup (only if not dead)
			if not is_dead:
				if int(windup_timer * 8) % 2 == 0:
					sprite.modulate = Color.RED
				else:
					# Restore to elite color if it exists, otherwise use white
					var restore_color = Color.WHITE
					if sprite.has_meta("elite_color"):
						restore_color = sprite.get_meta("elite_color")
					sprite.modulate = restore_color
			
			# After windup, commit to attack
			if windup_timer >= SWORD_WINDUP_TIME:
				ai_state = AIState.ATTACK
				state_timer = 0.0
				if not is_dead:
					sprite.modulate = get_restore_color()
				print("💥 Sword skeleton executing dash attack!")
		
		AIState.ATTACK:
			# Committed dash attack - cannot be cancelled
			var dash_direction = (dash_target - global_position).normalized()
			velocity = dash_direction * SWORD_DASH_SPEED
			
			# Check if we hit the player during dash
			if distance_to_player <= SWORD_ATTACK_RANGE:
				deal_damage_to_player()
			
			# Attack lasts for a short time
			if state_timer >= 0.4:
				ai_state = AIState.COOLDOWN
				state_timer = 0.0
				last_attack_time = Time.get_ticks_msec() / 1000.0
				individual_cooldown_time = randf_range(1.5, 3.0)  # Set individual cooldown time
				print("😴 Sword skeleton entering cooldown for ", individual_cooldown_time, " seconds")
		
		AIState.COOLDOWN:
			# Recovery phase - vulnerable and slow
			velocity = Vector2.ZERO
			
			# Flash sprite to show vulnerability (only if not dead)
			if not is_dead:
				if int(state_timer * 4) % 2 == 0:
					sprite.modulate = Color(0.7, 0.7, 1.0)  # Slightly blue
				else:
					sprite.modulate = get_restore_color()
			
			# Return to patrol after individual cooldown time
			if state_timer >= individual_cooldown_time:
				ai_state = AIState.PATROL
				state_timer = 0.0
				if not is_dead:
					sprite.modulate = get_restore_color()
				print("🔄 Sword skeleton ready after ", individual_cooldown_time, " seconds - returning to patrol")

# Hades-style AI for archer skeletons: Idle → Patrol → Reposition → Windup → Attack → Cooldown
func update_archer_skeleton_hades_ai(delta):
	var distance_to_player = global_position.distance_to(target_player.global_position)
	
	match ai_state:
		AIState.IDLE:
			velocity = Vector2.ZERO
			# Brief idle before starting patrol
			if state_timer > randf_range(0.5, 1.0):
				ai_state = AIState.PATROL
				state_timer = 0.0
		
		AIState.PATROL:
			# Patrol around looking for player
			patrol_timer -= delta
			if patrol_timer <= 0:
				patrol_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				patrol_timer = PATROL_CHANGE_TIME
			
			velocity = patrol_direction * movement_speed * 0.4
			
			# Detect player from anywhere on the map - shoot unless too close
			if distance_to_player < ARCHER_MIN_RANGE:
				# Too close - need to reposition
				ai_state = AIState.REPOSITION
				state_timer = 0.0
				find_reposition_target()
				print("🏃 Archer skeleton needs to reposition - player too close!")
			else:
				# Good range - prepare to shoot from any distance
				ai_state = AIState.WINDUP
				state_timer = 0.0
				windup_timer = 0.0
				print("🏹 Archer skeleton detected player - preparing to shoot from distance: ", distance_to_player)
		
		AIState.REPOSITION:
			# Move to optimal shooting position
			var direction = (reposition_target - global_position).normalized()
			velocity = direction * ARCHER_REPOSITION_SPEED
			
			# Check if we've reached good position or are far enough from player
			if distance_to_player >= ARCHER_MIN_RANGE:
				# Far enough from player - can shoot now
				ai_state = AIState.WINDUP
				state_timer = 0.0
				windup_timer = 0.0
				print("🎯 Archer skeleton repositioned - preparing to shoot!")
			elif global_position.distance_to(reposition_target) <= 20.0:
				# Reached target position but player still too close - find new position
				find_reposition_target()
				print("🔄 Archer skeleton reached position but player still close - finding new spot")
			elif distance_to_player > LOSE_INTEREST_RANGE:
				ai_state = AIState.PATROL
				state_timer = 0.0
				print("🚶 Archer skeleton lost interest - returning to patrol")
		
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
			# Recovery phase - patrol around during cooldown
			patrol_timer -= delta
			if patrol_timer <= 0:
				patrol_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				patrol_timer = PATROL_CHANGE_TIME
			
			velocity = patrol_direction * movement_speed * 0.3  # Slow patrol during cooldown
			
			# Flash sprite to show cooldown (only if not dead)
			if not is_dead:
				if int(state_timer * 3) % 2 == 0:
					sprite.modulate = Color(0.7, 1.0, 0.7)  # Slightly green
				else:
					sprite.modulate = get_restore_color()
			
			# Return to patrol after individual cooldown time
			if state_timer >= individual_cooldown_time:
				ai_state = AIState.PATROL
				state_timer = 0.0
				if not is_dead:
					sprite.modulate = get_restore_color()
				print("🔄 Archer skeleton ready after ", individual_cooldown_time, " seconds - returning to patrol")

# Stone Golem AI: Similar to sword skeleton but slower and with ground pound attack
func update_stone_golem_ai(delta):
	var distance_to_player = global_position.distance_to(target_player.global_position)
	
	match ai_state:
		AIState.IDLE:
			velocity = Vector2.ZERO
			# Longer idle time for imposing presence
			if state_timer > randf_range(1.0, 2.0):
				ai_state = AIState.PATROL
				state_timer = 0.0
		
		AIState.PATROL:
			# Slow, methodical patrol with heavy footsteps
			patrol_timer -= delta
			if patrol_timer <= 0:
				# More predictable movement patterns than skeletons
				var toward_player = (target_player.global_position - global_position).normalized()
				var slight_variation = randf_range(-0.5, 0.5)  # Small randomness
				patrol_direction = toward_player.rotated(slight_variation).normalized()
				patrol_timer = PATROL_CHANGE_TIME * 1.5  # Slower direction changes
			
			velocity = patrol_direction * movement_speed
			
			# Detect player at shorter range than skeletons (less aware)
			if distance_to_player <= DETECTION_RANGE * 0.8:  # 80 units instead of 100
				ai_state = AIState.CHASE
				state_timer = 0.0
				print("🗿 Stone golem detected player - beginning slow pursuit!")
		
		AIState.CHASE:
			# Slow but relentless pursuit
			var direction = (target_player.global_position - global_position).normalized()
			velocity = direction * movement_speed
			
			# When close enough, prepare for ground pound
			if distance_to_player <= GOLEM_GROUND_POUND_RANGE:
				ai_state = AIState.WINDUP
				state_timer = 0.0
				windup_timer = 0.0
				print("⚡ Stone golem preparing GROUND POUND attack!")
			# Lose interest at much closer range (persistent but slow)
			elif distance_to_player > LOSE_INTEREST_RANGE * 0.7:  # 105 units instead of 150
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
			# Recovery phase - completely stationary and vulnerable
			velocity = Vector2.ZERO
			
			# Show vulnerability with blue tinting (only if not dead)
			if not is_dead:
				if int(state_timer * 2) % 2 == 0:
					sprite.modulate = Color(0.6, 0.6, 1.0)  # Blue vulnerability
				else:
					sprite.modulate = get_restore_color()
			
			# Return to patrol after cooldown
			if state_timer >= individual_cooldown_time:
				ai_state = AIState.PATROL
				state_timer = 0.0
				if not is_dead:
					sprite.modulate = get_restore_color()
				print("🔄 Stone golem ready after ", individual_cooldown_time, " seconds - resuming patrol")

func perform_ground_pound_attack():
	# Create area damage around the golem
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node and main_node.has_method("handle_golem_ground_pound"):
		main_node.handle_golem_ground_pound(global_position, GOLEM_GROUND_POUND_RANGE, attack_damage)
	else:
		# Fallback: Direct damage check
		var distance_to_player = global_position.distance_to(target_player.global_position)
		if distance_to_player <= GOLEM_GROUND_POUND_RANGE:
			deal_damage_to_player()
			print("💥 GROUND POUND hit player for ", attack_damage, " damage!")
	
	print("🌊 Stone golem GROUND POUND creates shockwave in ", GOLEM_GROUND_POUND_RANGE, " unit radius!")

func find_reposition_target():
	# Find a position that's at safe distance from player
	var away_from_player = (global_position - target_player.global_position).normalized()
	var angle_variation = randf_range(-0.8, 0.8)  # More variation for interesting positioning
	away_from_player = away_from_player.rotated(angle_variation)
	# Use a safe distance that's well beyond minimum range
	var safe_distance = ARCHER_MIN_RANGE + 30.0  # 60 + 30 = 90 units away
	reposition_target = target_player.global_position + away_from_player * safe_distance



func deal_damage_to_player():
	if target_player and target_player.has_method("take_damage"):
		target_player.take_damage(attack_damage)
		print("⚔️ Enemy dealt ", attack_damage, " damage to player!")

func fire_arrow():
	var arrow_direction = (target_player.global_position - global_position).normalized()
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node:
		main_node.create_enemy_arrow(global_position, arrow_direction, attack_damage)

func take_damage(amount: float):
	if is_dead:
		return  # Don't take damage if already dead
	
	current_health -= amount
	print("💔 Enemy took ", amount, " damage! Health: ", current_health, "/", max_health)
	
	# Update health bar
	update_health_bar()
	
	# Check if dead
	if current_health <= 0:
		die()
		return  # Exit immediately after death
	
	# Play hit animation only if not dead
	play_hit_animation()
	
	# Flash red when hit (only if not dead)
	if not is_dead:
		sprite.modulate = Color.RED
		create_tween().tween_property(sprite, "modulate", get_restore_color(), 0.2)

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
