extends CharacterBody2D
class_name Enemy

# Enemy type definitions
enum EnemyType {
	SWORD_SKELETON,
	ARCHER_SKELETON
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
var sprite: Sprite2D
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

# Base enemy stats (before scaling)
const BASE_ENEMY_STATS = {
	EnemyType.SWORD_SKELETON: {
		"health": 60.0,
		"damage": 15.0,
		"speed": 70.0,
		"attack_cooldown": SWORD_COOLDOWN_TIME,
		"attack_range": SWORD_ATTACK_RANGE,
		"sprite_path": "res://assets/skeleton_sword.svg"
	},
	EnemyType.ARCHER_SKELETON: {
		"health": 25.0,
		"damage": 24.0,
		"speed": 80.0,
		"attack_cooldown": ARCHER_COOLDOWN_TIME,
		"attack_range": 180.0,
		"sprite_path": "res://assets/skeleton_archer.svg"
	}
}

func _ready():
	# Set up collision
	collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	collision_shape.shape = shape
	add_child(collision_shape)
	
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

func initialize_enemy(type: EnemyType, scaling: float = 1.0):
	enemy_type = type
	scale_factor = scaling
	
	# Get base stats for this enemy type
	base_stats = BASE_ENEMY_STATS[enemy_type].duplicate()
	
	# Apply scaling to stats
	current_stats = {}
	for key in base_stats:
		if key == "sprite_path":
			current_stats[key] = base_stats[key]
		else:
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
	sprite = Sprite2D.new()
	sprite.texture = load(current_stats.sprite_path)
	sprite.scale = Vector2(1.0, 1.0)
	add_child(sprite)

func create_health_bar():
	# Create health bar container
	health_bar_container = Node2D.new()
	health_bar_container.name = "HealthBarContainer"
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
	if not target_player or not is_instance_valid(target_player):
		return
	
	state_timer += delta
	
	# Update AI behavior based on enemy type
	match enemy_type:
		EnemyType.SWORD_SKELETON:
			update_sword_skeleton_hades_ai(delta)
		EnemyType.ARCHER_SKELETON:
			update_archer_skeleton_hades_ai(delta)
	
	# Move the enemy
	move_and_slide()
	
	# Update sprite facing direction
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false

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
			
			# Flash sprite to show windup
			if int(windup_timer * 8) % 2 == 0:
				sprite.modulate = Color.RED
			else:
				sprite.modulate = Color.WHITE
			
			# After windup, commit to attack
			if windup_timer >= SWORD_WINDUP_TIME:
				ai_state = AIState.ATTACK
				state_timer = 0.0
				sprite.modulate = Color.WHITE
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
			
			# Flash sprite to show vulnerability
			if int(state_timer * 4) % 2 == 0:
				sprite.modulate = Color(0.7, 0.7, 1.0)  # Slightly blue
			else:
				sprite.modulate = Color.WHITE
			
			# Return to patrol after individual cooldown time
			if state_timer >= individual_cooldown_time:
				ai_state = AIState.PATROL
				state_timer = 0.0
				sprite.modulate = Color.WHITE
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
			
			# Flash sprite to show windup
			if int(windup_timer * 6) % 2 == 0:
				sprite.modulate = Color.YELLOW
			else:
				sprite.modulate = Color.WHITE
			
			# After windup, commit to attack
			if windup_timer >= ARCHER_WINDUP_TIME:
				ai_state = AIState.ATTACK
				state_timer = 0.0
				sprite.modulate = Color.WHITE
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
			
			# Flash sprite to show cooldown
			if int(state_timer * 3) % 2 == 0:
				sprite.modulate = Color(0.7, 1.0, 0.7)  # Slightly green
			else:
				sprite.modulate = Color.WHITE
			
			# Return to patrol after individual cooldown time
			if state_timer >= individual_cooldown_time:
				ai_state = AIState.PATROL
				state_timer = 0.0
				sprite.modulate = Color.WHITE
				print("🔄 Archer skeleton ready after ", individual_cooldown_time, " seconds - returning to patrol")

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
	current_health -= amount
	print("💔 Enemy took ", amount, " damage! Health: ", current_health, "/", max_health)
	
	# Flash red when hit
	sprite.modulate = Color.RED
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	# Update health bar
	update_health_bar()
	
	if current_health <= 0:
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
	print("💀 Enemy died!")
	
	# Remove from parent
	queue_free()

func get_enemy_type_name() -> String:
	return EnemyType.keys()[enemy_type] 
