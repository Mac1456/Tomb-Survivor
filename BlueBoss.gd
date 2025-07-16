extends Enemy

class_name BlueBoss

# Boss-specific properties
@export var boss_name: String = "Blue Witch"
@export var base_health: float = 500.0
@export var phase_threshold_1: float = 0.66  # 66% health for phase 2
@export var phase_threshold_2: float = 0.33  # 33% health for phase 3

# Phase system
enum BossPhase {
	PHASE_1,
	PHASE_2,
	PHASE_3
}

var current_phase: BossPhase = BossPhase.PHASE_1
var is_shielded: bool = false
var shield_duration: float = 3.0
var shield_timer: float = 0.0

# Spell system
var spell_cooldown: float = 0.0
var spell_cooldown_duration: float = 2.0
var repel_cooldown: float = 0.0
var repel_cooldown_duration: float = 8.0
var elite_spawn_cooldown: float = 0.0
var elite_spawn_cooldown_duration: float = 12.0

# Elite skeleton tracking
var elite_skeletons: Array = []
var max_elite_skeletons: int = 3

# Movement behavior
var wander_target: Vector2
var wander_timer: float = 0.0
var wander_duration: float = 3.0
var stationary_timer: float = 0.0
var stationary_duration: float = 2.0
var is_stationary: bool = false

# Reference to main scene
var main_scene: Node2D = null

# Sprite reference
var sprite: Sprite2D = null

func _ready():
	# Set up boss properties before calling super._ready()
	enemy_type = EnemyType.BOSS
	max_health = calculate_scaled_health()
	current_health = max_health
	movement_speed = 50.0  # Slower than regular enemies
	
	# Initialize wander target
	wander_target = global_position
	
	# Connect to main scene
	main_scene = get_tree().get_first_node_in_group("main")
	
	# Don't call super._ready() as it might interfere with boss logic
	# Just set up the basic collision and sprite
	setup_boss_sprite()
	
	print("BlueBoss initialized with health: ", max_health)

func setup_boss_sprite():
	# Get the sprite node from the scene
	var sprite_node = get_node("Sprite2D")
	if sprite_node:
		sprite = sprite_node
		print("Boss sprite setup complete")

# Health property for compatibility with main scene
func get_health() -> float:
	return current_health

func set_health(value: float):
	current_health = value

func calculate_scaled_health() -> float:
	# Scale health based on player count
	var player_count = get_player_count()
	
	# Base health scales by 50% per additional player
	var scaled_health = base_health * (1.0 + (player_count - 1) * 0.5)
	
	print("Boss health scaled for ", player_count, " players: ", scaled_health)
	return scaled_health

func get_player_count() -> int:
	# For now, return 1 (single player)
	# TODO: Implement actual player count detection for multiplayer
	var players = get_tree().get_nodes_in_group("player")
	return max(1, players.size())

func _physics_process(delta):
	if current_health <= 0:
		return
	
	# Update cooldowns
	update_cooldowns(delta)
	
	# Update shield
	if is_shielded:
		shield_timer -= delta
		if shield_timer <= 0:
			is_shielded = false
			print("Boss shield deactivated")
	
	# Handle movement
	handle_movement(delta)
	
	# Handle spell casting
	if spell_cooldown <= 0:
		cast_random_spell()
		spell_cooldown = spell_cooldown_duration
	
	# Update boss health bar
	if main_scene and main_scene.has_method("update_boss_health_bar"):
		main_scene.update_boss_health_bar(current_health, max_health)

func update_cooldowns(delta: float):
	spell_cooldown = max(0, spell_cooldown - delta)
	repel_cooldown = max(0, repel_cooldown - delta)
	elite_spawn_cooldown = max(0, elite_spawn_cooldown - delta)

func handle_movement(delta: float):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	if is_stationary:
		stationary_timer -= delta
		if stationary_timer <= 0:
			is_stationary = false
			set_new_wander_target()
	else:
		wander_timer -= delta
		if wander_timer <= 0:
			# Randomly choose between wandering and being stationary
			if randf() < 0.3:  # 30% chance to be stationary
				is_stationary = true
				stationary_timer = stationary_duration
				velocity = Vector2.ZERO
			else:
				set_new_wander_target()
		else:
			# Move towards wander target while subtly avoiding player
			var direction_to_target = (wander_target - global_position).normalized()
			var direction_from_player = (global_position - player.global_position).normalized()
			
			# Blend wander direction with subtle player avoidance
			var final_direction = direction_to_target * 0.7 + direction_from_player * 0.3
			velocity = final_direction.normalized() * movement_speed
			
			# Stop if close to target
			if global_position.distance_to(wander_target) < 20:
				set_new_wander_target()
	
	move_and_slide()

func set_new_wander_target():
	var arena_bounds = Rect2(Vector2(100, 100), Vector2(1000, 600))
	wander_target = Vector2(
		randf_range(arena_bounds.position.x, arena_bounds.position.x + arena_bounds.size.x),
		randf_range(arena_bounds.position.y, arena_bounds.position.y + arena_bounds.size.y)
	)
	wander_timer = wander_duration

func cast_random_spell():
	var available_spells = get_available_spells()
	if available_spells.is_empty():
		return
	
	var spell_choice = available_spells[randi() % available_spells.size()]
	
	match spell_choice:
		"fireball_barrage":
			cast_fireball_barrage()
		"large_magic_orb":
			cast_large_magic_orb()
		"magic_missile_storm":
			cast_magic_missile_storm()
		"area_lightning":
			cast_area_lightning()
		"repel_wave":
			cast_repel_wave()
		"spawn_elite_skeleton":
			spawn_elite_skeleton()

func get_available_spells() -> Array:
	var spells = ["fireball_barrage", "large_magic_orb", "magic_missile_storm", "area_lightning"]
	
	# Add phase-specific spells
	if current_phase >= BossPhase.PHASE_2:
		if repel_cooldown <= 0:
			spells.append("repel_wave")
		if elite_spawn_cooldown <= 0 and elite_skeletons.size() < max_elite_skeletons:
			spells.append("spawn_elite_skeleton")
	
	return spells

func cast_fireball_barrage():
	print("Boss casts Fireball Barrage!")
	# TODO: Implement fireball barrage spell
	
func cast_large_magic_orb():
	print("Boss casts Large Magic Orb!")
	# TODO: Implement large magic orb spell

func cast_magic_missile_storm():
	print("Boss casts Magic Missile Storm!")
	# TODO: Implement magic missile storm spell

func cast_area_lightning():
	print("Boss casts Area Lightning!")
	# TODO: Implement area lightning spell

func cast_repel_wave():
	print("Boss casts Repel Wave!")
	repel_cooldown = repel_cooldown_duration
	# TODO: Implement repel wave spell

func spawn_elite_skeleton():
	print("Boss spawns Elite Skeleton!")
	elite_spawn_cooldown = elite_spawn_cooldown_duration
	
	# Clean up dead elite skeletons from tracking
	elite_skeletons = elite_skeletons.filter(func(skeleton): return is_instance_valid(skeleton))
	
	# Don't spawn if we're at max
	if elite_skeletons.size() >= max_elite_skeletons:
		return
	
	# Create elite skeleton
	var elite_skeleton = create_elite_skeleton()
	if elite_skeleton:
		elite_skeletons.append(elite_skeleton)
		
		# Spawn near boss but not too close
		var spawn_offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		elite_skeleton.global_position = global_position + spawn_offset
		
		# Add to scene
		if main_scene and main_scene.has_method("add_elite_skeleton"):
			main_scene.add_elite_skeleton(elite_skeleton)
		else:
			# Fallback - add to enemies container
			var enemies_container = get_tree().get_first_node_in_group("enemies_container")
			if enemies_container:
				enemies_container.add_child(elite_skeleton)
		
		print("Elite skeleton spawned! Active count: ", elite_skeletons.size())

func create_elite_skeleton():
	# Use existing enemy scene but enhance it
	var enemy_scene = preload("res://Enemy.tscn")
	var elite_skeleton = enemy_scene.instantiate()
	
	# Set as sword skeleton type
	elite_skeleton.enemy_type = Enemy.EnemyType.SWORD_SKELETON
	
	# Enhanced stats (8x health)
	elite_skeleton.max_health = 400.0  # 8x regular skeleton health (assuming 50)
	elite_skeleton.current_health = elite_skeleton.max_health
	elite_skeleton.movement_speed *= 1.2  # Slightly faster
	elite_skeleton.attack_damage *= 1.5  # More damage
	
	# Mark as elite
	elite_skeleton.name = "EliteSkeleton"
	elite_skeleton.add_to_group("elite_enemies")
	
	# Apply purple tint after the sprite is ready
	elite_skeleton.call_deferred("apply_elite_modulation")
	
	return elite_skeleton

func take_damage(damage: float):
	if is_shielded:
		print("Boss damage blocked by shield!")
		return
	
	var old_health = current_health
	
	# Handle damage manually instead of calling super.take_damage
	current_health -= damage
	print("💔 Boss took ", damage, " damage! Health: ", current_health, "/", max_health)
	
	# Flash red when hit
	if sprite:
		sprite.modulate = Color.RED
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	# Check for phase transitions
	check_phase_transition(old_health)
	
	# Check if boss is defeated
	if current_health <= 0:
		die()

func check_phase_transition(_old_health: float):
	var health_percentage = current_health / max_health
	
	if health_percentage <= phase_threshold_2 and current_phase != BossPhase.PHASE_3:
		current_phase = BossPhase.PHASE_3
		activate_shield()
		print("Boss entered Phase 3!")
	elif health_percentage <= phase_threshold_1 and current_phase == BossPhase.PHASE_1:
		current_phase = BossPhase.PHASE_2
		activate_shield()
		print("Boss entered Phase 2!")

func activate_shield():
	is_shielded = true
	shield_timer = shield_duration
	print("Boss activated shield for ", shield_duration, " seconds!")

func die():
	print("Boss defeated!")
	
	# Clean up elite skeletons
	for skeleton in elite_skeletons:
		if is_instance_valid(skeleton):
			skeleton.queue_free()
	elite_skeletons.clear()
	
	# Hide boss health bar
	if main_scene and main_scene.has_method("hide_boss_health_bar"):
		main_scene.hide_boss_health_bar()
	
	# Remove boss from scene
	queue_free() 
