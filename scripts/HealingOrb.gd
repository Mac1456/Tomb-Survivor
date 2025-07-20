extends RigidBody2D
class_name HealingOrb

# Healing orb properties
var heal_amount: float = 20.0
var pickup_radius: float = 40.0
var lifetime: float = 30.0  # Auto-despawn after 30 seconds
var bob_speed: float = 2.0
var bob_range: float = 5.0
var sparkle_timer: float = 0.0

# Visual components
var sprite: Sprite2D
var collision_shape: CollisionShape2D
var pickup_area: Area2D
var pickup_collision: CollisionShape2D
var glow_tween: Tween
var bob_tween: Tween

# State
var collected: bool = false
var spawn_time: float = 0.0
var original_y: float = 0.0

func _ready():
	# Set physics properties
	gravity_scale = 0  # Float in air
	collision_layer = 64  # Pickup layer
	collision_mask = 2   # Only collide with walls
	freeze = true  # Don't fall through floor
	
	# Create visual sprite
	create_sprite()
	
	# Create pickup area
	create_pickup_area()
	
	# Start visual effects
	start_visual_effects()
	
	# Store spawn time and original position
	spawn_time = Time.get_ticks_msec() / 1000.0
	original_y = global_position.y
	
	print("💚 Healing orb spawned with ", heal_amount, " healing at ", global_position)

func create_sprite():
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/healing_orb.svg")
	sprite.scale = Vector2(1.2, 1.2)  # Slightly larger for visibility
	add_child(sprite)
	
	# Create collision for physics (so it bounces off walls)
	collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 8.0
	collision_shape.shape = circle_shape
	add_child(collision_shape)

func create_pickup_area():
	# Create area for pickup detection
	pickup_area = Area2D.new()
	pickup_area.name = "PickupArea"
	pickup_area.collision_layer = 0  # No collision layer
	pickup_area.collision_mask = 1   # Detect player layer
	
	# Create area collision shape
	pickup_collision = CollisionShape2D.new()
	var pickup_shape = CircleShape2D.new()
	pickup_shape.radius = pickup_radius
	pickup_collision.shape = pickup_shape
	pickup_area.add_child(pickup_collision)
	
	add_child(pickup_area)
	
	# Connect signals
	pickup_area.body_entered.connect(_on_pickup_area_entered)

func start_visual_effects():
	# Gentle bobbing animation
	bob_tween = create_tween()
	bob_tween.set_loops(-1)  # -1 means infinite loops, but properly configured
	bob_tween.tween_method(_update_bob, 0.0, TAU, bob_speed)
	
	# Glowing pulse effect
	glow_tween = create_tween()
	glow_tween.set_loops(-1)  # -1 means infinite loops, but properly configured
	glow_tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.8)
	glow_tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8)

func _update_bob(angle: float):
	if sprite and not collected:
		var offset = sin(angle) * bob_range
		global_position.y = original_y + offset

func _physics_process(delta):
	if collected:
		return
	
	# Check lifetime
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - spawn_time > lifetime:
		despawn()
		return
	
	# Add sparkle effects occasionally
	sparkle_timer += delta
	if sparkle_timer > 0.3:
		create_sparkle_effect()
		sparkle_timer = 0.0

func _on_pickup_area_entered(body):
	if collected or not body.has_method("heal"):
		return
	
	# Check if it's a player
	if body.is_in_group("player") or body.has_method("get_character_type"):
		collect_orb(body)

func collect_orb(player):
	if collected:
		return
	
	collected = true
	print("💚 Player collected healing orb for ", heal_amount, " HP!")
	
	# Heal the player
	player.heal(heal_amount)
	
	# Play collection effects
	play_collection_effects()
	
	# Play pickup sound if available
	play_pickup_sound()
	
	# Remove after effect animation
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 0.5
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)
	add_child(cleanup_timer)
	cleanup_timer.start()

func play_collection_effects():
	# Stop existing tweens
	if bob_tween:
		bob_tween.kill()
	if glow_tween:
		glow_tween.kill()
	
	# Scale up and fade out effect
	var collection_tween = create_tween()
	collection_tween.parallel().tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.3)
	collection_tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)
	
	# Create healing text popup
	create_healing_popup()
	
	# Create particle burst effect
	create_collection_particles()

func create_healing_popup():
	# Create floating heal text
	var heal_label = Label.new()
	heal_label.text = "+" + str(int(heal_amount))
	heal_label.position = global_position + Vector2(-10, -20)
	heal_label.add_theme_font_size_override("font_size", 20)
	heal_label.add_theme_color_override("font_color", Color.GREEN)
	heal_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	heal_label.add_theme_constant_override("shadow_offset_x", 2)
	heal_label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Add to scene
	var scene = get_tree().current_scene
	scene.add_child(heal_label)
	
	# Create tween on the scene tree (not on this dying object)
	var text_tween = scene.create_tween()
	text_tween.parallel().tween_property(heal_label, "position:y", heal_label.position.y - 30, 1.0)
	text_tween.parallel().tween_property(heal_label, "modulate:a", 0.0, 1.0)
	text_tween.tween_callback(func(): 
		if is_instance_valid(heal_label):
			heal_label.queue_free()
	)
	
	# Safety cleanup timer in case tween fails
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 1.5  # Slightly longer than tween
	cleanup_timer.one_shot = true
	
	# Create a safer callback that doesn't capture variables that might be freed
	cleanup_timer.timeout.connect(func():
		# Find and remove any remaining heal labels that match our text
		var scene_tree = cleanup_timer.get_tree()
		if scene_tree and scene_tree.current_scene:
			var children = scene_tree.current_scene.get_children()
			for child in children:
				if child is Label and child.text.begins_with("+"):
					child.queue_free()
		cleanup_timer.queue_free()
	)
	scene.add_child(cleanup_timer)
	cleanup_timer.start()

func create_collection_particles():
	# Create simple particle burst effect
	for i in range(6):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color.GREEN
		particle.position = global_position
		
		# Random direction
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var distance = randf_range(20, 40)
		
		get_tree().current_scene.add_child(particle)
		
		var particle_tween = create_tween()
		particle_tween.parallel().tween_property(particle, "position", global_position + direction * distance, 0.5)
		particle_tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		particle_tween.tween_callback(func(): 
			if is_instance_valid(particle):
				particle.queue_free()
		)

func create_sparkle_effect():
	# Create occasional sparkle
	var sparkle = ColorRect.new()
	sparkle.size = Vector2(3, 3)
	sparkle.color = Color.WHITE
	sparkle.position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
	
	get_tree().current_scene.add_child(sparkle)
	
	var sparkle_tween = create_tween()
	sparkle_tween.tween_property(sparkle, "modulate:a", 0.0, 0.5)
	sparkle_tween.tween_callback(func(): 
		if is_instance_valid(sparkle):
			sparkle.queue_free()
	)

func play_pickup_sound():
	# Try to play pickup sound if available
	var main_scene = get_tree().get_first_node_in_group("main")
	if main_scene and main_scene.has_method("play_pickup_sound"):
		main_scene.play_pickup_sound()
	else:
		print("🔊 *Healing orb pickup sound*")

func despawn():
	print("💔 Healing orb despawned after ", lifetime, " seconds")
	
	# Fade out effect
	var despawn_tween = create_tween()
	despawn_tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
	despawn_tween.tween_callback(func():
		if is_instance_valid(self):
			queue_free()
	)

# Static helper function to determine healing amount based on enemy type and scaling
static func calculate_heal_amount(enemy_type: Enemy.EnemyType, player_count: int) -> float:
	var base_heal: float
	
	match enemy_type:
		Enemy.EnemyType.SWORD_SKELETON, Enemy.EnemyType.ARCHER_SKELETON:
			base_heal = 15.0  # Small heal for common enemies
		Enemy.EnemyType.STONE_GOLEM:
			base_heal = 35.0  # Larger heal for tank enemy
		Enemy.EnemyType.BOSS:
			base_heal = 50.0  # Large heal for boss
		_:
			base_heal = 20.0  # Default
	
	# Scale slightly with player count (but not too much to avoid imbalance)
	var player_scaling = 1.0 + (player_count - 1) * 0.2  # 20% more heal per additional player
	
	return base_heal * player_scaling

# Static helper function to determine drop chance
static func get_drop_chance(enemy_type: Enemy.EnemyType) -> float:
	match enemy_type:
		Enemy.EnemyType.SWORD_SKELETON, Enemy.EnemyType.ARCHER_SKELETON:
			return 0.15  # 15% chance for normal enemies
		Enemy.EnemyType.STONE_GOLEM:
			return 0.75  # 75% chance for golem (high chance as requested)
		Enemy.EnemyType.BOSS:
			return 1.0   # 100% chance for boss (multiple drops)
		_:
			return 0.1   # 10% default

# Static helper function to determine number of orbs to drop
static func get_orb_count(enemy_type: Enemy.EnemyType, player_count: int) -> int:
	match enemy_type:
		Enemy.EnemyType.SWORD_SKELETON, Enemy.EnemyType.ARCHER_SKELETON:
			return 1  # Always single orb
		Enemy.EnemyType.STONE_GOLEM:
			return 1 + (player_count - 1)  # 1 base + 1 per additional player
		Enemy.EnemyType.BOSS:
			return 2 + player_count  # 2 base + 1 per player (scales well)
		_:
			return 1 