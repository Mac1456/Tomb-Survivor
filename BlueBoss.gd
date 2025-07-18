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
var spell_cooldown_duration: float = 5.0  # Increased from 2.0 to 5.0 seconds
var repel_cooldown: float = 0.0
var repel_cooldown_duration: float = 12.0  # Increased from 8.0 to 12.0
var elite_spawn_cooldown: float = 0.0
var elite_spawn_cooldown_duration: float = 18.0  # Increased from 12.0 to 18.0

# Attack execution tracking
var current_attack_duration: float = 0.0
var is_executing_attack: bool = false
var attack_chain_counter: int = 0
var max_chain_attacks: int = 1  # Start with single attacks

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

# Animation state management
var movement_state_timer: float = 0.0
var movement_state_delay: float = 0.5  # Prevent rapid animation switching
var last_movement_state: bool = false

# Reference to main scene
var main_scene: Node2D = null

# Animation system
var animated_sprite: AnimatedSprite2D = null
var current_animation: String = "idle"
var animation_queue: Array = []
var is_casting: bool = false

# Shield visual effect
var shield_effect: Node2D = null
var shield_particles: Array = []
var shield_rotation_tween: Tween = null
var shield_pulse_tweens: Array = []

# Animation state tracking
enum AnimationState {
	IDLE,
	MOVING,
	CASTING,
	SHIELDED,
	DYING
}

var animation_state: AnimationState = AnimationState.IDLE

func _ready():
	# Set up boss properties
	enemy_type = EnemyType.BOSS
	
	# Initialize wander target
	wander_target = global_position
	
	# Connect to main scene
	main_scene = get_tree().get_first_node_in_group("main")
	
	# Set up boss collision and groups
	setup_boss_collision_and_groups()
	
	# Initialize the boss without calling Enemy's _ready()
	initialize_boss()
	
	print("BlueBoss _ready() complete")

func initialize_enemy(type: EnemyType, scaling: float = 1.0):
	# Override Enemy's initialize_enemy to prevent conflicts with BlueBoss scene setup
	print("BlueBoss: Overriding initialize_enemy to prevent conflicts")
	
	# Set basic properties
	enemy_type = type
	scale_factor = scaling
	
	# Use BlueBoss-specific health calculation instead of Enemy's
	max_health = calculate_scaled_health()
	current_health = max_health
	
	# Set other stats
	attack_damage = 50.0 * scale_factor  # Boss-specific damage
	movement_speed = 45.0  # Boss-specific speed
	attack_cooldown = 2.0
	attack_range = 100.0
	
	# Use BlueBoss-specific sprite setup instead of Enemy's
	setup_boss_animated_sprite()
	
	# Use BlueBoss-specific health bar setup instead of Enemy's
	# create_health_bar()  # Removed - using main scene boss health bar only
	
	print("✨ BlueBoss initialized with scaling: ", scale_factor)
	print("   Health: ", max_health, " Damage: ", attack_damage, " Speed: ", movement_speed)

func initialize_boss():
	# Boss-specific initialization
	max_health = calculate_scaled_health()
	current_health = max_health
	movement_speed = 45.0  # Slower than regular enemies
	
	# Set up sprite system
	setup_boss_animated_sprite()
	
	# Create boss health bar
	# create_health_bar()  # Removed - using main scene boss health bar only
	
	# Initialize spell cooldown to prevent immediate casting
	spell_cooldown = 1.0  # 1 second delay before first spell
	
	# Initialize wander timer
	wander_timer = wander_duration
	
	print("BlueBoss initialized with health: ", max_health)

func setup_boss_collision_and_groups():
	# Set up collision layers for boss
	collision_layer = 4  # Enemy layer
	collision_mask = 1 | 2  # Can collide with player and walls
	
	# Add boss to important groups
	add_to_group("enemies")
	add_to_group("boss")
	
	# Ensure collision shape is properly configured
	if has_node("CollisionShape2D"):
		var collision_node = get_node("CollisionShape2D")
		if collision_node and collision_node.shape:
			print("Boss collision shape configured: ", collision_node.shape.get_class())
		else:
			print("WARNING: Boss collision shape not properly configured!")
	
	print("Boss collision and groups set up - Layer: ", collision_layer, " Mask: ", collision_mask)

func create_sprite():
	# Override Enemy's create_sprite method to prevent conflicts
	# The BlueBoss scene already has an AnimatedSprite2D configured
	print("BlueBoss: Using scene-configured AnimatedSprite2D instead of creating new one")
	
	# Get the AnimatedSprite2D from the scene
	if has_node("AnimatedSprite2D"):
		var anim_sprite = get_node("AnimatedSprite2D")
		if anim_sprite:
			sprite = anim_sprite
			animated_sprite = anim_sprite
			print("BlueBoss: AnimatedSprite2D configured successfully")
		else:
			print("ERROR: AnimatedSprite2D node not found in BlueBoss scene!")
	else:
		print("ERROR: AnimatedSprite2D node missing from BlueBoss scene!")

func setup_boss_animated_sprite():
	# Get the animated sprite node from the scene
	if has_node("AnimatedSprite2D"):
		var anim_sprite_node = get_node("AnimatedSprite2D")
		if anim_sprite_node and is_instance_valid(anim_sprite_node):
			animated_sprite = anim_sprite_node
			# Set the sprite reference for backward compatibility
			sprite = anim_sprite_node
			
			# Connect animation finished signal if not already connected
			if not animated_sprite.is_connected("animation_finished", _on_animation_finished):
				animated_sprite.connect("animation_finished", _on_animation_finished)
			
			# Start with idle animation
			play_animation("idle")
			
			# Debug: List available animations
			if animated_sprite.sprite_frames:
				print("🎭 Available boss animations: ", animated_sprite.sprite_frames.get_animation_names())
			
			print("✅ Boss animated sprite setup complete")
		else:
			print("ERROR: AnimatedSprite2D node is invalid in BlueBoss scene!")
	else:
		print("ERROR: Could not find AnimatedSprite2D node in BlueBoss scene!")

func get_sprite_node() -> Node2D:
	# Try to use cached animated sprite first
	if animated_sprite and is_instance_valid(animated_sprite):
		return animated_sprite
	
	# If cached sprite is invalid, try to get it from the scene
	if has_node("AnimatedSprite2D"):
		var anim_sprite_node = get_node("AnimatedSprite2D")
		if anim_sprite_node and is_instance_valid(anim_sprite_node):
			animated_sprite = anim_sprite_node
			return anim_sprite_node
	
	# If still no sprite, print error and return null
	print("ERROR: Could not find valid AnimatedSprite2D node in BlueBoss!")
	return null

func play_animation(animation_name: String, force: bool = false):
	var sprite_node = get_sprite_node()
	if not sprite_node:
		print("ERROR: No valid animated sprite available for animation: ", animation_name)
		return
	
	# Don't interrupt casting animations unless forced
	if not force and is_casting and animation_name != "shield":
		animation_queue.append(animation_name)
		print("Animation queued: ", animation_name)
		return
	
	# Don't play the same animation if it's already playing (unless forced)
	if not force and current_animation == animation_name and sprite_node.is_playing():
		return
	
	# Play the animation
	if sprite_node.sprite_frames and sprite_node.sprite_frames.has_animation(animation_name):
		sprite_node.play(animation_name)
		current_animation = animation_name
		print("✨ Boss playing animation: ", animation_name)
		
		# Reset movement state timer when animation changes
		if animation_name in ["move", "idle"]:
			movement_state_timer = 0.0
	else:
		print("WARNING: Animation not found: ", animation_name)
		print("Available animations: ", sprite_node.sprite_frames.get_animation_names() if sprite_node.sprite_frames else "No sprite frames")
		# Fall back to idle if animation doesn't exist
		if animation_name != "idle":
			play_animation("idle")

func _on_animation_finished():
	var finished_animation = current_animation
	
	# Only clear casting state if we're not currently executing an attack
	# This prevents animation flickering during charge periods
	if not is_executing_attack:
		is_casting = false
	else:
		# If we're executing an attack, keep the casting animation playing
		# This prevents reverting to idle during charge periods
		if finished_animation.begins_with("attack_"):
			print("🎭 Keeping casting animation active during attack execution: ", finished_animation)
			play_animation(finished_animation, true)  # Replay the casting animation
			return
	
	print("🎭 Animation finished: ", finished_animation)
	
	# Handle specific animation completions
	match finished_animation:
		"death":
			animation_state = AnimationState.DYING
			# Don't queue anything after death
			return
		"shield":
			# Shield animation finished, check if shield is still active
			if is_shielded:
				# Shield is still active, just stay in shield state
				animation_state = AnimationState.SHIELDED
				# Don't change animation - let shield stay active
				print("Shield animation finished but shield still active")
			else:
				# Shield is no longer active, transition to appropriate state
				if velocity.length() > 30.0:
					animation_state = AnimationState.MOVING
					play_animation("move", true)  # Force the animation change
				else:
					animation_state = AnimationState.IDLE
					play_animation("idle", true)  # Force the animation change
		"attack_fireball", "attack_orb", "attack_missile", "attack_lightning", "repel", "summon":
			# After casting, determine state based on current movement
			# Reset movement state timer to allow immediate state check
			movement_state_timer = movement_state_delay
			
			if velocity.length() > 30.0:  # Use same threshold as movement logic
				animation_state = AnimationState.MOVING
				play_animation("move")
			else:
				animation_state = AnimationState.IDLE
				play_animation("idle")
	
	# Process animation queue if any
	if not animation_queue.is_empty():
		var next_animation = animation_queue.pop_front()
		play_animation(next_animation)
		print("🎭 Playing queued animation: ", next_animation)

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
	
	# Update attack execution tracking
	if is_executing_attack:
		current_attack_duration -= delta
		if current_attack_duration <= 0:
			is_executing_attack = false
			attack_chain_counter += 1
			print("🎯 Attack execution completed. Chain counter: ", attack_chain_counter)
			
			# Check if we should chain another attack
			if attack_chain_counter < max_chain_attacks and randf() < 0.6:  # 60% chance to chain
				print("🔗 Chaining another attack!")
				# Start next attack immediately
				cast_random_spell()
			else:
				attack_chain_counter = 0
				print("🏁 Attack chain completed")
	
	# Update shield
	if is_shielded:
		shield_timer -= delta
		if shield_timer <= 0:
			is_shielded = false
			remove_shield_visual_effect()
			print("Boss shield deactivated")
			
			# Create shield deactivation message
			create_shield_deactivated_message()
			
			# Force transition back to appropriate state
			is_casting = false  # Ensure casting flag is cleared
			if velocity.length() > 30.0:
				animation_state = AnimationState.MOVING
				play_animation("move", true)  # Force the animation change
			else:
				animation_state = AnimationState.IDLE
				play_animation("idle", true)  # Force the animation change
	
	# Handle movement
	handle_movement(delta)
	
	# Handle spell casting - only if not currently executing an attack
	if not is_executing_attack and spell_cooldown <= 0:
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
	
	var previous_velocity = velocity
	
	if is_stationary:
		stationary_timer -= delta
		if stationary_timer <= 0:
			is_stationary = false
			set_new_wander_target()
		velocity = Vector2.ZERO
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
	
	# Improved animation state management - prevent rapid switching
	var movement_threshold = 30.0  # Higher threshold for more stable switching
	var is_moving_now = velocity.length() > movement_threshold
	
	# Update movement state timer
	movement_state_timer += delta
	
	# Only change animation if movement state has been consistent for a while AND we're not casting
	if not is_casting and movement_state_timer >= movement_state_delay:
		if is_moving_now != last_movement_state:
			if is_moving_now:
				animation_state = AnimationState.MOVING
				play_animation("move")
				print("🚶 Boss started moving")
			else:
				animation_state = AnimationState.IDLE
				play_animation("idle")
				print("🧘 Boss stopped moving")
			
			last_movement_state = is_moving_now
			movement_state_timer = 0.0  # Reset timer after state change
	
	# Update sprite facing direction only if moving significantly
	var sprite_node = get_sprite_node()
	if sprite_node and velocity.length() > movement_threshold:
		sprite_node.flip_h = velocity.x < 0

func set_new_wander_target():
	var arena_bounds = Rect2(Vector2(100, 100), Vector2(1000, 600))
	var new_target = Vector2(
		randf_range(arena_bounds.position.x, arena_bounds.position.x + arena_bounds.size.x),
		randf_range(arena_bounds.position.y, arena_bounds.position.y + arena_bounds.size.y)
	)
	wander_target = new_target
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
	print("🔥 Boss casts Fireball Barrage!")
	is_casting = true
	is_executing_attack = true
	current_attack_duration = 3.0  # 3 seconds for full barrage execution
	animation_state = AnimationState.CASTING
	play_animation("attack_fireball", true)  # Force animation
	
	# Add casting delay with visual warning
	create_spell_warning("Fireball Barrage incoming!")
	
	# Execute the spell immediately instead of delaying
	_execute_fireball_barrage()

func _execute_fireball_barrage():
	# Cast multiple fireballs in succession toward player
	var player = get_tree().get_first_node_in_group("player")
	if player and main_scene:
		var num_fireballs = 6  # Number of fireballs in barrage
		var damage = 30.0  # Damage per fireball
		
		for i in range(num_fireballs):
			var delay = max(0.1, i * 0.2)  # Ensure minimum 0.1s delay, prevent zero or negative
			# Calculate direction to player with slight randomness
			var direction = (player.global_position - global_position).normalized()
			var random_angle = randf_range(-15, 15)  # Small spread
			direction = direction.rotated(deg_to_rad(random_angle))
			
			# Create delayed fireball
			var timer = Timer.new()
			timer.wait_time = delay
			timer.one_shot = true
			timer.timeout.connect(func(): cast_single_fireball(direction))
			add_child(timer)
			timer.start()
			
		print("🔥 FIREBALL BARRAGE: ", num_fireballs, " fireballs targeting player!")

func cast_single_fireball(direction: Vector2):
	# Use the main scene's projectile system to create a fireball
	if main_scene and main_scene.has_method("create_projectile"):
		var damage = 35.0  # Boss fireball damage
		var fireball_speed = 450.0  # Fast fireball speed
		
		# Use the Main.gd projectile system properly
		var fireball_type = main_scene.ProjectileType.FIREBALL
		var projectile = main_scene.create_projectile(global_position, direction, damage, fireball_type)
		# Mark this as a boss projectile so it doesn't hit the boss itself
		if projectile:
			projectile.set_meta("boss_projectile", true)
			projectile.set_meta("enemy_projectile", true)  # This makes it target the player
			# Override velocity with boss fireball speed
			projectile.set_meta("velocity", direction * fireball_speed)
		print("🔥 Boss cast fireball at direction: ", direction, " with speed: ", fireball_speed)

func cast_large_magic_orb():
	print("🔮 Boss casts Large Magic Orb!")
	is_casting = true
	is_executing_attack = true
	
	# Set charge time
	var charge_time = 2.0  # 2 seconds to charge the orb
	current_attack_duration = charge_time + 0.5  # Keep animation for charge time + buffer for orb spawn
	
	animation_state = AnimationState.CASTING
	play_animation("attack_orb", true)  # Force animation
	
	# Create a timer to maintain the casting animation throughout the charge period
	var animation_maintain_timer = Timer.new()
	animation_maintain_timer.wait_time = 0.5  # Check every 0.5 seconds
	animation_maintain_timer.timeout.connect(_maintain_casting_animation)
	add_child(animation_maintain_timer)
	animation_maintain_timer.start()
	
	# Store timer reference to clean up later
	set_meta("animation_timer", animation_maintain_timer)
	
	# Add casting warning
	create_spell_warning("Charging powerful orb...")
	
	# Cast a large, fast-moving orb that deals heavy damage
	var player = get_tree().get_first_node_in_group("player")
	if player and main_scene:
		var direction = (player.global_position - global_position).normalized()
		var damage = 60.0  # High damage for large orb
		
		# Create delayed orb cast with extended charge time
		var timer = Timer.new()
		timer.wait_time = charge_time  # Use the charge_time variable for consistency
		timer.one_shot = true
		timer.timeout.connect(func(): cast_single_orb(direction, damage))
		add_child(timer)
		timer.start()
		
		print("🔮 Charging orb for ", charge_time, " seconds, animation lasts ", current_attack_duration, " seconds")

func _maintain_casting_animation():
	# This function is called every 0.5 seconds to ensure the casting animation
	# continues playing even if the spell is charging
	if is_executing_attack and is_casting:
		var sprite_node = get_sprite_node()
		if sprite_node and sprite_node is AnimatedSprite2D:
			var anim_sprite = sprite_node as AnimatedSprite2D
			if anim_sprite.is_playing() and anim_sprite.animation == current_animation:
				# Animation is playing correctly, do nothing
				print("🎭 Casting animation playing correctly: ", current_animation)
			else:
				# Animation stopped or wrong animation, force it to play
				play_animation(current_animation, true)
				print("🎭 Forcing casting animation to continue: ", current_animation)
		else:
			print("⚠️ No valid sprite node found for animation maintenance")

func cast_single_orb(direction: Vector2, damage: float):
	print("🔮 ORB FIRED! Charging complete - launching orb at player!")
	
	# Clear casting state now that orb is actually firing
	is_casting = false
	
	# Clean up animation maintain timer
	if has_meta("animation_timer"):
		var timer = get_meta("animation_timer")
		if is_instance_valid(timer):
			timer.queue_free()
		remove_meta("animation_timer")
	
	# Add a brief flash effect when orb is fired
	create_orb_fire_flash()
	
	if main_scene and main_scene.has_method("create_projectile"):
		# Use the Main.gd projectile system for the large orb
		var fireball_type = main_scene.ProjectileType.FIREBALL
		var projectile = main_scene.create_projectile(global_position, direction, damage, fireball_type)
		var orb_speed = 320.0  # Medium speed for large orb (allows better homing)
		
		# Mark this as a boss projectile so it doesn't hit the boss itself
		if projectile:
			projectile.set_meta("boss_projectile", true)
			projectile.set_meta("enemy_projectile", true)  # This makes it target the player
			projectile.set_meta("type", "large_orb")  # Mark as large orb
			projectile.set_meta("lifetime", 20.0)  # Extended 20 second lifetime
			projectile.set_meta("created_time", 0.0)  # Initialize time counter
			projectile.set_meta("homing", true)  # Enable strong homing
			projectile.set_meta("homing_strength", 1.5)  # Reduced homing force (was 4.0)
			projectile.set_meta("max_turn_rate", 1.2)  # Slower turn rate (was 2.0)
			
			# Override velocity with orb speed
			projectile.set_meta("velocity", direction * orb_speed)
			
			# Make the orb visually larger and more distinctive
			for child in projectile.get_children():
				if child is Sprite2D:
					child.scale = Vector2(2.5, 2.5)  # Make it much larger
					child.modulate = Color(1.0, 0.5, 1.0, 1.0)  # Purple/pink color for large orb
					
					# Add pulsing effect to show it's homing
					# Use call_deferred to ensure the projectile is fully initialized
					call_deferred("_create_orb_pulse_effect", projectile, child)
					
				elif child is CollisionShape2D and child.shape:
					child.shape.radius = 15.0  # Larger collision radius
		
		print("🔮 Boss cast homing large magic orb at direction: ", direction, " with speed: ", orb_speed, " and ", 20.0, "s lifetime")

func create_orb_fire_flash():
	# Create a brief flash effect when the orb is fired
	var flash_effect = ColorRect.new()
	flash_effect.size = Vector2(100, 100)  # Larger flash
	flash_effect.position = global_position - Vector2(50, 50)  # Center it on the boss
	flash_effect.color = Color(1.0, 0.8, 1.0, 0.8)  # Bright purple flash
	
	if main_scene:
		main_scene.add_child(flash_effect)
		
		# Animate the flash
		var flash_tween = create_tween()
		flash_tween.tween_property(flash_effect, "scale", Vector2(1.5, 1.5), 0.1)
		flash_tween.parallel().tween_property(flash_effect, "modulate:a", 0.0, 0.1)
		flash_tween.tween_callback(func(): flash_effect.queue_free())
		
	print("✨ Orb fire flash effect created!")

func cast_magic_missile_storm():
	print("🚀 Boss casts Magic Missile Storm!")
	is_casting = true
	is_executing_attack = true
	current_attack_duration = 3.5  # 3.5 seconds for full missile storm
	animation_state = AnimationState.CASTING
	play_animation("attack_missile", true)  # Force animation
	
	# Add casting warning
	create_spell_warning("Missile barrage incoming!")
	
	# Create missile launch indicators
	create_missile_launch_indicators()
	
	# Execute missiles immediately
	_execute_missile_storm()

func _execute_missile_storm():
	# Cast multiple small missiles in rapid succession at the player
	var player = get_tree().get_first_node_in_group("player")
	if player and main_scene:
		var num_missiles = 12  # Number of missiles
		var damage = 25.0  # Damage per missile
		
		for i in range(num_missiles):
			var delay = (i * 0.12) + 0.1  # Faster succession: 0.1-1.44 seconds
			# Calculate fresh direction to player for each missile (accounting for player movement)
			var base_direction = (player.global_position - global_position).normalized()
			# Add some randomness for spread
			var random_angle = randf_range(-25, 25)  # Wider spread for missiles
			var direction = base_direction.rotated(deg_to_rad(random_angle))
			
			create_delayed_missile(direction, damage, delay)
		
		print("🚀 MISSILE STORM: ", num_missiles, " missiles targeting player area!")

func create_missile_launch_indicators():
	# Create multiple small targeting circles around the boss
	var num_indicators = 12  # Increased from 8 to 12
	var container = Node2D.new()
	container.name = "MissileLaunchIndicators"
	container.position = global_position
	
	if main_scene:
		main_scene.add_child(container)
		
		for i in range(num_indicators):
			var indicator = ColorRect.new()
			indicator.size = Vector2(10, 10)  # Slightly larger indicators
			indicator.color = Color(1.0, 0.3, 0.0, 0.8)  # More opaque orange indicators
			
			# Position indicators in a circle around boss
			var angle = (i * 2 * PI) / num_indicators
			var radius = 35.0  # Slightly larger radius
			var indicator_pos = Vector2(cos(angle), sin(angle)) * radius
			indicator.position = indicator_pos - Vector2(5, 5)
			
			container.add_child(indicator)
		
		# Animate the indicators more aggressively
		var pulse_tween = create_tween()
		pulse_tween.set_loops(10)  # Limited loops instead of infinite
		pulse_tween.tween_property(container, "scale", Vector2(1.4, 1.4), 0.15)  # Faster and bigger pulse
		pulse_tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.15)
		
		# Remove indicators after storm duration
		var cleanup_timer = Timer.new()
		cleanup_timer.wait_time = 2.0  # Longer duration
		cleanup_timer.one_shot = true
		cleanup_timer.timeout.connect(func(): 
			pulse_tween.kill()  # Kill the tween
			container.queue_free()
		)
		main_scene.add_child(cleanup_timer)
		cleanup_timer.start()

func create_delayed_missile(direction: Vector2, damage: float, delay: float):
	# Ensure minimum delay to prevent timer errors
	var safe_delay = max(0.1, delay)
	var timer = Timer.new()
	timer.wait_time = safe_delay
	timer.one_shot = true
	timer.timeout.connect(func(): cast_single_missile(direction, damage))
	add_child(timer)
	timer.start()
	print("⏰ Scheduling missile in ", safe_delay, " seconds")

func cast_single_missile(direction: Vector2, damage: float):
	if main_scene and main_scene.has_method("create_projectile"):
		# Use the Main.gd projectile system properly
		var fireball_type = main_scene.ProjectileType.FIREBALL
		var projectile = main_scene.create_projectile(global_position, direction, damage, fireball_type)
		var missile_speed = 380.0  # Fast missile speed
		
		# Mark this as a boss projectile so it doesn't hit the boss itself
		if projectile:
			projectile.set_meta("boss_projectile", true)
			projectile.set_meta("enemy_projectile", true)  # This makes it target the player
			projectile.set_meta("homing", true)  # Enable light homing
			projectile.set_meta("homing_strength", 0.8)  # Much weaker homing force (was 2.0)
			projectile.set_meta("max_turn_rate", 0.8)  # Slower turn rate (was 1.5)
			# Override velocity with missile speed
			projectile.set_meta("velocity", direction * missile_speed)
			
			# Make missiles visually unique - create purple orb instead of using sprite
			for child in projectile.get_children():
				if child is Sprite2D:
					child.queue_free()  # Remove the default sprite
			
			# Create custom purple orb visual
			var orb_visual = ColorRect.new()
			orb_visual.size = Vector2(12, 12)
			orb_visual.position = Vector2(-6, -6)  # Center it
			orb_visual.color = Color(0.6, 0.2, 1.0, 0.9)  # Purple orb
			projectile.add_child(orb_visual)
			
			# Add glow effect
			var glow_visual = ColorRect.new()
			glow_visual.size = Vector2(16, 16)
			glow_visual.position = Vector2(-8, -8)  # Center it
			glow_visual.color = Color(0.4, 0.1, 0.8, 0.5)  # Purple glow
			glow_visual.z_index = -1  # Behind the main orb
			projectile.add_child(glow_visual)
			
			# Add pulsing animation to show homing missiles
			# Use call_deferred to ensure the projectile is fully initialized
			call_deferred("_create_missile_pulse_effect", projectile, glow_visual)
			
		print("🚀 Boss cast homing purple magic missile at direction: ", direction, " with speed: ", missile_speed)

func cast_area_lightning():
	print("⚡ Boss casts Area Lightning!")
	is_casting = true
	is_executing_attack = true
	current_attack_duration = 4.0  # 4 seconds for full lightning storm
	animation_state = AnimationState.CASTING
	play_animation("attack_lightning", true)  # Force animation
	
	# Add casting warning
	create_spell_warning("Lightning storm brewing!")
	
	# Create lightning strikes around the player with much larger coverage
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var num_strikes = 8  # Increased from 4 to 8
		var damage = 50.0  # Increased from 45 to 50
		
		for i in range(num_strikes):
			var delay = (i * 0.25) + 0.2  # Slightly slower but more strikes: 0.2-2.0 seconds
			# Larger spread area around player
			var offset = Vector2(randf_range(-120, 120), randf_range(-120, 120))  # Increased from -80,80 to -120,120
			var strike_position = player.global_position + offset
			
			create_delayed_lightning_strike(strike_position, damage, delay)

func create_delayed_lightning_strike(strike_position: Vector2, damage: float, delay: float):
	# Create telegraphing effect immediately
	create_lightning_telegraph(strike_position, delay)
	
	var timer = Timer.new()
	timer.wait_time = delay
	timer.one_shot = true
	timer.timeout.connect(func(): cast_lightning_strike(strike_position, damage))
	add_child(timer)
	timer.start()

func create_lightning_telegraph(strike_position: Vector2, delay: float):
	# Create warning square on the ground - made larger
	var warning_square = ColorRect.new()
	warning_square.size = Vector2(140, 140)  # Increased from 80x80 to 140x140
	warning_square.position = strike_position - Vector2(70, 70)
	warning_square.color = Color(1.0, 1.0, 0.0, 0.3)  # Transparent yellow
	warning_square.name = "LightningTelegraph"
	
	if main_scene:
		main_scene.add_child(warning_square)
		
		# Animate the warning square (pulsing effect)
		var pulse_tween = create_tween()
		pulse_tween.set_loops(int(delay * 5))  # Limited loops based on delay
		pulse_tween.tween_property(warning_square, "modulate:a", 0.1, 0.2)
		pulse_tween.tween_property(warning_square, "modulate:a", 0.5, 0.2)
		
		# Remove warning after delay
		var cleanup_timer = Timer.new()
		cleanup_timer.wait_time = delay
		cleanup_timer.one_shot = true
		cleanup_timer.timeout.connect(func(): 
			pulse_tween.kill()  # Kill the tween
			warning_square.queue_free()
		)
		main_scene.add_child(cleanup_timer)
		cleanup_timer.start()

func create_lightning_visual(strike_position: Vector2):
	# Create detailed lightning bolt effect
	var lightning_container = Node2D.new()
	lightning_container.name = "LightningBolt"
	lightning_container.position = strike_position
	
	if main_scene:
		main_scene.add_child(lightning_container)
		
		# Create multiple lightning segments for a jagged effect
		var num_segments = 8
		var segment_height = 60.0 / num_segments
		
		for i in range(num_segments):
			var segment = ColorRect.new()
			segment.size = Vector2(4, segment_height)
			
			# Add random horizontal offset for jagged effect
			var offset_x = randf_range(-15, 15)
			segment.position = Vector2(offset_x - 2, i * segment_height - 30)
			
			# Vary the brightness for each segment
			var brightness = randf_range(0.8, 1.0)
			segment.color = Color(brightness, brightness, 0.0, 0.9)
			
			lightning_container.add_child(segment)
		
		# Create main lightning core
		var main_bolt = ColorRect.new()
		main_bolt.size = Vector2(8, 60)
		main_bolt.position = Vector2(-4, -30)
		main_bolt.color = Color(1.0, 1.0, 1.0, 0.8)  # Bright white core
		lightning_container.add_child(main_bolt)
		
		# Create electric sparks around the impact
		for i in range(6):
			var spark = ColorRect.new()
			spark.size = Vector2(2, 8)
			var angle = (i * 2 * PI) / 6
			var spark_distance = 25.0
			var spark_pos = Vector2(cos(angle), sin(angle)) * spark_distance
			spark.position = spark_pos - Vector2(1, 4)
			spark.color = Color(1.0, 1.0, 0.0, 0.6)
			lightning_container.add_child(spark)
		
		# Create impact flash
		var impact_flash = ColorRect.new()
		impact_flash.size = Vector2(40, 40)
		impact_flash.position = Vector2(-20, -20)
		impact_flash.color = Color(1.0, 1.0, 1.0, 0.7)
		lightning_container.add_child(impact_flash)
		
		# Animate the lightning effect
		var flash_tween = create_tween()
		flash_tween.tween_property(impact_flash, "modulate:a", 0.0, 0.1)
		flash_tween.parallel().tween_property(lightning_container, "modulate:a", 0.0, 0.3)
		flash_tween.tween_callback(func(): lightning_container.queue_free())
		
		print("⚡ Detailed lightning bolt created at: ", strike_position)

func cast_lightning_strike(strike_position: Vector2, damage: float):
	# Create area damage at the strike position - ONLY damage player with larger area
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance = player.global_position.distance_to(strike_position)
		if distance < 70:  # Increased area from 40 to 70
			# Make sure it's not hitting the boss itself
			if player.global_position.distance_to(global_position) > 50:  # Increased safety distance
				if player.has_method("take_damage"):
					player.take_damage(damage)
					print("⚡ Lightning strike hit player for ", damage, " damage!")
	
	# Create visual effect
	create_lightning_visual(strike_position)



func cast_repel_wave():
	print("💨 Boss casts Repel Wave!")
	repel_cooldown = repel_cooldown_duration
	is_casting = true
	is_executing_attack = true
	current_attack_duration = 2.0  # 2 seconds for repel wave execution
	animation_state = AnimationState.CASTING
	play_animation("repel", true)  # Force animation
	
	# Add casting warning and charging effect
	create_spell_warning("Repel wave charging...")
	create_repel_charging_effect()
	
	# Delay the wave to give players time to react
	var delay_timer = Timer.new()
	delay_timer.wait_time = 1.0
	delay_timer.one_shot = true
	delay_timer.timeout.connect(_execute_repel_wave)
	add_child(delay_timer)
	delay_timer.start()

func create_repel_charging_effect():
	# Create a charging effect that shows the incoming wave
	var charge_container = Node2D.new()
	charge_container.name = "RepelCharging"
	charge_container.position = global_position
	
	if main_scene:
		main_scene.add_child(charge_container)
		
		# Create multiple ring indicators
		for i in range(3):
			var ring = ColorRect.new()
			var ring_size = 40 + (i * 30)  # Increasing ring sizes
			ring.size = Vector2(ring_size, ring_size)
			ring.position = Vector2(-ring_size/2, -ring_size/2)
			ring.color = Color(0.0, 0.8, 1.0, 0.3 - (i * 0.1))  # Decreasing opacity
			
			charge_container.add_child(ring)
		
		# Animate the charging rings
		var pulse_tween = create_tween()
		pulse_tween.set_loops(4)  # Limited loops for charging effect
		pulse_tween.tween_property(charge_container, "scale", Vector2(1.3, 1.3), 0.3)
		pulse_tween.tween_property(charge_container, "scale", Vector2(1.0, 1.0), 0.3)
		
		# Remove charging effect after delay
		var cleanup_timer = Timer.new()
		cleanup_timer.wait_time = 1.0
		cleanup_timer.one_shot = true
		cleanup_timer.timeout.connect(func(): 
			pulse_tween.kill()  # Kill the tween
			charge_container.queue_free()
		)
		main_scene.add_child(cleanup_timer)
		cleanup_timer.start()

func _execute_repel_wave():
	# Create a wave that pushes the player away - ONLY affects player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance = player.global_position.distance_to(global_position)
		if distance < 200 and distance > 20:  # Increased range from 150 to 200
			var repel_direction = (player.global_position - global_position).normalized()
			
			# Apply knockback effect by directly modifying player velocity
			if player.has_method("apply_knockback"):
				var repel_force = 500.0  # Increased force
				player.apply_knockback(repel_direction * repel_force)
			else:
				# If player doesn't have knockback method, use velocity directly
				var repel_force = 800.0  # Strong knockback
				player.velocity = repel_direction * repel_force
				print("💨 Applied direct velocity knockback to player!")
			
			# Also deal damage
			if player.has_method("take_damage"):
				player.take_damage(35.0)  # Increased damage from 25 to 35
				print("💨 Repel wave hit player for 35 damage!")
			
			# Create enhanced visual effect
			create_enhanced_repel_visual()

func create_enhanced_repel_visual():
	# Create an enhanced circular wave effect
	var wave_container = Node2D.new()
	wave_container.name = "RepelWave"
	wave_container.position = global_position
	
	if main_scene:
		main_scene.add_child(wave_container)
		
		# Create multiple wave rings for depth
		for i in range(4):
			var wave_ring = ColorRect.new()
			var ring_size = 60 + (i * 20)
			wave_ring.size = Vector2(ring_size, ring_size)
			wave_ring.position = Vector2(-ring_size/2, -ring_size/2)
			wave_ring.color = Color(0.0, 0.7, 1.0, 0.6 - (i * 0.15))  # Blue wave with decreasing opacity
			
			wave_container.add_child(wave_ring)
		
		# Create energy particles at the edge
		var num_particles = 16
		for i in range(num_particles):
			var particle = ColorRect.new()
			particle.size = Vector2(4, 12)
			particle.color = Color(0.8, 0.9, 1.0, 0.8)  # Light blue particles
			
			var angle = (i * 2 * PI) / num_particles
			var particle_distance = 80.0
			var particle_pos = Vector2(cos(angle), sin(angle)) * particle_distance
			particle.position = particle_pos - Vector2(2, 6)
			
			wave_container.add_child(particle)
		
		# Animate the wave expanding
		var expand_tween = create_tween()
		expand_tween.parallel().tween_property(wave_container, "scale", Vector2(4.0, 4.0), 0.8)
		expand_tween.parallel().tween_property(wave_container, "modulate:a", 0.0, 0.8)
		expand_tween.tween_callback(func(): wave_container.queue_free())

func spawn_elite_skeleton():
	print("💀 Boss spawns Elite Skeleton!")
	elite_spawn_cooldown = elite_spawn_cooldown_duration
	is_casting = true
	is_executing_attack = true
	current_attack_duration = 3.0  # 3 seconds for skeleton summoning
	animation_state = AnimationState.CASTING
	play_animation("summon", true)  # Force animation
	
	# Clean up dead elite skeletons from tracking
	elite_skeletons = elite_skeletons.filter(func(skeleton): return is_instance_valid(skeleton))
	
	# Don't spawn if we're at max
	if elite_skeletons.size() >= max_elite_skeletons:
		is_executing_attack = false  # Cancel execution if can't summon
		return
	
	# Add casting warning
	create_spell_warning("Summoning elite minion...")
	
	# Choose spawn location near boss but not too close
	var spawn_offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
	var spawn_position = global_position + spawn_offset
	
	# Create summoning circle first
	create_summoning_circle(spawn_position)
	
	# Delay actual skeleton creation
	var summon_timer = Timer.new()
	summon_timer.wait_time = 1.5  # Time for summoning circle animation
	summon_timer.one_shot = true
	summon_timer.timeout.connect(func(): _execute_skeleton_summon(spawn_position))
	add_child(summon_timer)
	summon_timer.start()

func create_summoning_circle(spawn_position: Vector2):
	# Create a magical summoning circle
	var circle_container = Node2D.new()
	circle_container.name = "SummoningCircle"
	circle_container.position = spawn_position
	
	if main_scene:
		main_scene.add_child(circle_container)
		
		# Create outer circle
		var outer_circle = ColorRect.new()
		outer_circle.size = Vector2(80, 80)
		outer_circle.position = Vector2(-40, -40)
		outer_circle.color = Color(0.5, 0.0, 0.8, 0.4)  # Purple outer ring
		circle_container.add_child(outer_circle)
		
		# Create inner circle
		var inner_circle = ColorRect.new()
		inner_circle.size = Vector2(50, 50)
		inner_circle.position = Vector2(-25, -25)
		inner_circle.color = Color(0.8, 0.2, 1.0, 0.6)  # Brighter purple center
		circle_container.add_child(inner_circle)
		
		# Create runes around the circle
		var num_runes = 8
		for i in range(num_runes):
			var rune = ColorRect.new()
			rune.size = Vector2(6, 6)
			rune.color = Color(1.0, 0.0, 1.0, 0.8)  # Bright magenta runes
			
			var angle = (i * 2 * PI) / num_runes
			var rune_distance = 35.0
			var rune_pos = Vector2(cos(angle), sin(angle)) * rune_distance
			rune.position = rune_pos - Vector2(3, 3)
			
			circle_container.add_child(rune)
		
		# Create energy tendrils
		for i in range(4):
			var tendril = ColorRect.new()
			tendril.size = Vector2(2, 20)
			tendril.color = Color(0.9, 0.4, 1.0, 0.7)  # Purple energy
			
			var angle = (i * PI) / 2  # Cardinal directions
			var tendril_pos = Vector2(cos(angle), sin(angle)) * 15
			tendril.position = tendril_pos - Vector2(1, 10)
			
			circle_container.add_child(tendril)
		
		# Animate the summoning circle
		var spin_tween = create_tween()
		spin_tween.set_loops(2)  # Limited spins for summoning
		spin_tween.tween_property(circle_container, "rotation", 2 * PI, 2.0)
		
		# Pulse the circle
		var pulse_tween = create_tween()
		pulse_tween.set_loops(5)  # Limited pulses for summoning
		pulse_tween.tween_property(circle_container, "scale", Vector2(1.2, 1.2), 0.4)
		pulse_tween.tween_property(circle_container, "scale", Vector2(1.0, 1.0), 0.4)
		
		# Remove circle after summoning
		var cleanup_timer = Timer.new()
		cleanup_timer.wait_time = 2.0
		cleanup_timer.one_shot = true
		cleanup_timer.timeout.connect(func(): 
			spin_tween.kill()  # Kill the tween
			pulse_tween.kill()  # Kill the tween
			circle_container.queue_free()
		)
		main_scene.add_child(cleanup_timer)
		cleanup_timer.start()

func _execute_skeleton_summon(spawn_position: Vector2):
	# Create elite skeleton
	var elite_skeleton = create_elite_skeleton()
	if elite_skeleton:
		elite_skeletons.append(elite_skeleton)
		
		# Set spawn position
		elite_skeleton.global_position = spawn_position
		
		# Add to scene
		if main_scene and main_scene.has_method("add_elite_skeleton"):
			main_scene.add_elite_skeleton(elite_skeleton)
		else:
			# Fallback - add to enemies container
			var enemies_container = get_tree().get_first_node_in_group("enemies_container")
			if enemies_container:
				enemies_container.add_child(elite_skeleton)
		
		# Create spawn flash effect
		create_spawn_flash(spawn_position)
		
		print("💀 Elite skeleton summoned! Active count: ", elite_skeletons.size())

func create_spawn_flash(spawn_position: Vector2):
	# Create a flash effect when skeleton spawns
	var flash_effect = ColorRect.new()
	flash_effect.size = Vector2(60, 60)
	flash_effect.position = spawn_position - Vector2(30, 30)
	flash_effect.color = Color(1.0, 0.8, 1.0, 0.9)  # Bright purple flash
	
	if main_scene:
		main_scene.add_child(flash_effect)
		
		# Animate the flash
		var flash_tween = create_tween()
		flash_tween.tween_property(flash_effect, "scale", Vector2(2.0, 2.0), 0.2)
		flash_tween.parallel().tween_property(flash_effect, "modulate:a", 0.0, 0.2)
		flash_tween.tween_callback(func(): flash_effect.queue_free())

func create_elite_skeleton():
	# Use existing enemy scene but enhance it
	var enemy_scene = preload("res://Enemy.tscn")
	var elite_skeleton = enemy_scene.instantiate()
	
	# Initialize the skeleton properly first
	elite_skeleton.initialize_enemy(Enemy.EnemyType.SWORD_SKELETON, 2.0)  # 2x scale factor
	
	# Enhanced stats (additional buffs on top of scale factor)
	elite_skeleton.max_health *= 2.0  # Additional 2x health multiplier
	elite_skeleton.current_health = elite_skeleton.max_health
	elite_skeleton.movement_speed *= 1.2  # Slightly faster
	elite_skeleton.attack_damage *= 1.5  # More damage
	
	# Mark as elite
	elite_skeleton.name = "EliteSkeleton"
	elite_skeleton.add_to_group("elite_enemies")
	
	# Apply purple tint after the sprite is ready
	elite_skeleton.call_deferred("apply_elite_modulation")
	
	return elite_skeleton

func take_damage(damage: float, source: Node2D = null):
	if is_shielded:
		print("🛡️ Boss damage blocked by shield!")
		# Create prominent "IMMUNE" feedback for player
		create_shield_immune_message()
		return
	
	# Comprehensive self-damage prevention
	if source == self:
		print("🚫 Boss prevented self-damage from its own attack!")
		return
	
	# Check if damage source is boss-related
	if source and (source.get_groups().has("boss") or source.name.begins_with("BlueBoss")):
		print("🚫 Boss prevented damage from boss-related source!")
		return
	
	# Check for boss projectiles or effects
	if source and source.has_meta("boss_projectile"):
		print("🚫 Boss prevented damage from own projectile!")
		return
	
	# Additional protection: Don't take damage if very close to own position (area effects)
	if source and source.global_position.distance_to(global_position) < 10.0:
		print("🚫 Boss prevented damage from nearby source (likely own area effect)!")
		return
	
	var old_health = current_health
	
	# Handle damage manually instead of calling super.take_damage
	current_health -= damage
	print("💔 Boss took ", damage, " damage! Health: ", current_health, "/", max_health)
	
	# Flash red when hit - ensure sprite is valid
	var sprite_node = get_sprite_node()
	if sprite_node:
		sprite_node.modulate = Color.RED
		create_tween().tween_property(sprite_node, "modulate", Color.WHITE, 0.2)
	else:
		print("WARNING: Sprite node not found for boss damage flash!")
	
	# Check for phase transitions
	check_phase_transition(old_health)
	
	# Check if boss is defeated
	if current_health <= 0:
		die()

func check_phase_transition(old_health: float):
	var health_percentage = current_health / max_health
	
	# Update attack chaining based on health
	if health_percentage <= 0.75:
		max_chain_attacks = 2  # Can chain 2 attacks
		print("🔗 Boss can now chain 2 attacks!")
	if health_percentage <= 0.5:
		max_chain_attacks = 3  # Can chain 3 attacks
		print("🔗 Boss can now chain 3 attacks!")
	if health_percentage <= 0.25:
		max_chain_attacks = 4  # Can chain 4 attacks
		print("🔗 Boss can now chain 4 attacks!")
	
	# Original phase transition logic
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
	animation_state = AnimationState.SHIELDED
	play_animation("shield", true)  # Force shield animation
	
	# Create dramatic shield activation message
	create_shield_activation_message()
	
	# Create visual shield effect
	create_shield_visual_effect()
	
	print("Boss activated shield for ", shield_duration, " seconds!")

func create_shield_activation_message():
	# Create a dramatic message label
	var message_label = Label.new()
	message_label.text = "Shield Activated!"
	message_label.position = global_position + Vector2(-50, -40)
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color.YELLOW)
	message_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	message_label.add_theme_constant_override("shadow_offset_x", 3)
	message_label.add_theme_constant_override("shadow_offset_y", 3)
	
	if main_scene:
		main_scene.add_child(message_label)
	else:
		add_child(message_label)
	
	# Animate and remove
	var tween = create_tween()
	tween.parallel().tween_property(message_label, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(message_label, "position:y", message_label.position.y - 20, 1.0)
	tween.tween_callback(func(): message_label.queue_free())

func create_shield_visual_effect():
	# Remove existing shield effect if any
	if shield_effect:
		shield_effect.queue_free()
	
	# Create shield effect container
	shield_effect = Node2D.new()
	shield_effect.name = "ShieldEffect"
	add_child(shield_effect)
	
	# Create multiple shield rings for a more dramatic effect
	var num_rings = 3
	for ring_idx in range(num_rings):
		var ring_radius = 30.0 + (ring_idx * 20.0)  # Increasing radius for each ring
		var num_particles = 12 + (ring_idx * 4)  # More particles for outer rings
		
		for i in range(num_particles):
			var particle = ColorRect.new()
			particle.size = Vector2(8, 8)  # Bigger particles
			particle.color = Color(0.2, 0.4, 1.0, 0.9 - (ring_idx * 0.2))  # More vibrant blue, fading outward
			
			# Position particles in a circle around the boss
			var angle = (i * 2 * PI) / num_particles
			var offset = Vector2(cos(angle), sin(angle)) * ring_radius
			particle.position = offset - Vector2(4, 4)  # Center the particle
			
			shield_effect.add_child(particle)
			shield_particles.append(particle)
	
	# Create central shield core - much more prominent
	var shield_core = ColorRect.new()
	shield_core.size = Vector2(24, 24)  # Much bigger core
	shield_core.position = Vector2(-12, -12)
	shield_core.color = Color(0.8, 0.9, 1.0, 0.8)  # Bright blue core
	shield_effect.add_child(shield_core)
	
	# Create shield dome effect
	var dome_effect = ColorRect.new()
	dome_effect.size = Vector2(120, 120)  # Large dome
	dome_effect.position = Vector2(-60, -60)
	dome_effect.color = Color(0.3, 0.5, 1.0, 0.3)  # Semi-transparent blue dome
	shield_effect.add_child(dome_effect)
	
	# Animate the shield effect
	animate_shield_effect()
	
	print("✨ Enhanced shield visual effect created!")

func animate_shield_effect():
	if not shield_effect:
		return
	
	# Rotate the shield particles - faster rotation for more dramatic effect
	var tween = create_tween()
	tween.set_loops(15)  # More loops for longer shield duration
	tween.tween_property(shield_effect, "rotation", shield_effect.rotation + 2 * PI, 1.5)  # Faster rotation
	
	# Store tween for cleanup
	shield_rotation_tween = tween
	
	# Pulse the shield particles - more dramatic pulsing
	for i in range(shield_particles.size()):
		var particle = shield_particles[i]
		if particle:
			var pulse_tween = create_tween()
			pulse_tween.set_loops(25)  # More pulses for shield effect
			pulse_tween.tween_property(particle, "modulate:a", 0.3, 0.3)  # More dramatic fade
			pulse_tween.tween_property(particle, "modulate:a", 1.0, 0.3)  # Full brightness
			
			# Store tweens for cleanup
			shield_pulse_tweens.append(pulse_tween)
	
	# Add scale pulsing to the entire shield effect
	var scale_tween = create_tween()
	scale_tween.set_loops(12)
	scale_tween.tween_property(shield_effect, "scale", Vector2(1.1, 1.1), 0.4)
	scale_tween.tween_property(shield_effect, "scale", Vector2(1.0, 1.0), 0.4)
	
	# Store scale tween for cleanup
	shield_pulse_tweens.append(scale_tween)
	
	print("🛡️ Enhanced shield animations started!")

func remove_shield_visual_effect():
	# Clean up shield tweens
	if shield_rotation_tween:
		shield_rotation_tween.kill()
		shield_rotation_tween = null
	
	for tween in shield_pulse_tweens:
		if tween:
			tween.kill()
	shield_pulse_tweens.clear()
	
	if shield_effect:
		shield_effect.queue_free()
		shield_effect = null
	shield_particles.clear()

func die():
	print("Boss defeated!")
	animation_state = AnimationState.DYING
	play_animation("death", true)  # Force death animation
	
	# Remove shield effect if active
	remove_shield_visual_effect()
	
	# Wait for death animation to complete before cleanup
	var sprite_node = get_sprite_node()
	if sprite_node:
		await sprite_node.animation_finished
	else:
		# If no sprite, wait a short time before cleanup
		await get_tree().create_timer(1.0).timeout
	
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

func create_spell_warning(warning_text: String):
	# Create a visual and text warning for incoming spells
	var warning_label = Label.new()
	warning_label.text = warning_text
	warning_label.position = global_position + Vector2(-50, -40)
	warning_label.add_theme_font_size_override("font_size", 16)
	warning_label.add_theme_color_override("font_color", Color.YELLOW)
	warning_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	warning_label.add_theme_constant_override("shadow_offset_x", 2)
	warning_label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Add to scene
	if main_scene:
		main_scene.add_child(warning_label)
	else:
		add_child(warning_label)
	
	# Animate and remove
	var tween = create_tween()
	tween.parallel().tween_property(warning_label, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(warning_label, "position:y", warning_label.position.y - 20, 1.0)
	tween.tween_callback(func(): warning_label.queue_free())

# Add method to identify this as a boss for projectile collision detection
func get_current_phase() -> int:
	return int(current_phase)

func is_boss_entity() -> bool:
	return true

func _create_missile_pulse_effect(projectile, glow_visual):
	# Safety check to ensure objects are still valid
	if not is_instance_valid(projectile) or not is_instance_valid(glow_visual):
		return
		
	var pulse_tween = create_tween()
	pulse_tween.set_loops(15)  # Reduced loops to prevent excessive tweening
	pulse_tween.tween_property(glow_visual, "modulate:a", 0.2, 0.4)  # Slower pulse
	pulse_tween.tween_property(glow_visual, "modulate:a", 0.6, 0.4)  # Less intense pulse
	
	# Store tween reference for cleanup
	projectile.set_meta("pulse_tween", pulse_tween)

func _create_orb_pulse_effect(projectile, sprite_child):
	# Safety check to ensure objects are still valid
	if not is_instance_valid(projectile) or not is_instance_valid(sprite_child):
		return
		
	var homing_pulse = create_tween()
	homing_pulse.set_loops(20)  # Reduced loops to prevent excessive tweening
	homing_pulse.tween_property(sprite_child, "modulate", Color(1.0, 0.4, 1.0, 1.0), 0.6)  # Slower pulse
	homing_pulse.tween_property(sprite_child, "modulate", Color(1.0, 0.6, 1.0, 1.0), 0.6)  # Less dramatic pulse
	
	# Store tween reference for cleanup
	projectile.set_meta("homing_pulse", homing_pulse)

func create_shield_immune_message():
	# Create a prominent "IMMUNE" message label
	var immune_label = Label.new()
	immune_label.text = "IMMUNE"
	immune_label.position = global_position + Vector2(-50, -40)
	immune_label.add_theme_font_size_override("font_size", 24)
	immune_label.add_theme_color_override("font_color", Color.CYAN)
	immune_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	immune_label.add_theme_constant_override("shadow_offset_x", 3)
	immune_label.add_theme_constant_override("shadow_offset_y", 3)
	
	if main_scene:
		main_scene.add_child(immune_label)
	else:
		add_child(immune_label)
	
	# Animate and remove
	var tween = create_tween()
	tween.parallel().tween_property(immune_label, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(immune_label, "position:y", immune_label.position.y - 20, 1.0)
	tween.tween_callback(func(): immune_label.queue_free())

func create_shield_deactivated_message():
	# Create a prominent "SHIELD DEACTIVATED" message label
	var shield_deactivated_label = Label.new()
	shield_deactivated_label.text = "SHIELD DEACTIVATED"
	shield_deactivated_label.position = global_position + Vector2(-50, -40)
	shield_deactivated_label.add_theme_font_size_override("font_size", 20)
	shield_deactivated_label.add_theme_color_override("font_color", Color.YELLOW)
	shield_deactivated_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	shield_deactivated_label.add_theme_constant_override("shadow_offset_x", 2)
	shield_deactivated_label.add_theme_constant_override("shadow_offset_y", 2)
	
	if main_scene:
		main_scene.add_child(shield_deactivated_label)
	else:
		add_child(shield_deactivated_label)
	
	# Animate and remove
	var tween = create_tween()
	tween.parallel().tween_property(shield_deactivated_label, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(shield_deactivated_label, "position:y", shield_deactivated_label.position.y - 20, 1.0)
	tween.tween_callback(func(): shield_deactivated_label.queue_free())
