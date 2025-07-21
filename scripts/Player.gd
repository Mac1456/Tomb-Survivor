extends CharacterBody2D
class_name Player

# Player character configuration
var character_data: CharacterData.Character
var player_id: int = 0

# Movement constants (will be modified by character stats)
var base_speed: float = 300.0
var acceleration: float = 2000.0
var friction: float = 1500.0

# Combat constants (will be modified by character stats)
var base_health: float = 100.0
var current_health: float = 100.0
var damage_multiplier: float = 1.0
var armor_reduction: float = 0.0

# Combat timers
var special_ability_timer: float = 0.0
var ultimate_ability_timer: float = 0.0
var primary_attack_timer: float = 0.0  # For wizard attack delay

# Dodge roll system
var dodge_roll_timer: float = 0.0
var dodge_roll_cooldown_timer: float = 0.0
var dodge_roll_direction: Vector2 = Vector2.ZERO
var is_dodge_rolling: bool = false

# Invincibility frames during dodge
var is_invincible: bool = false
var original_collision_mask: int = 0

# Player state
var facing_direction: Vector2 = Vector2.RIGHT
var is_alive: bool = true

# Custom effects
var dodge_effect_sprite: AnimatedSprite2D = null
var invincibility_tween: Tween = null

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
# Health bar references - may be null if not in scene, will be created dynamically
var health_bar_container: Node2D
var health_bar: ColorRect

# Signals
signal health_changed(new_health: float, max_health: float)
signal character_died
signal ability_used(ability_name: String)

func _ready():
	# Set default character if none assigned
	if not character_data:
		character_data = CharacterData.get_character(0)  # Default to Hero Knight
	
	# Add player to the "player" group so enemies can find it
	add_to_group("player")
	
	# Configure character first
	configure_character()
	
	# Try to find existing health bar nodes first
	health_bar_container = get_node_or_null("HealthBarContainer")
	if health_bar_container:
		health_bar = health_bar_container.get_node_or_null("HealthBar")
		print("Found existing health bar in scene")
	
	# Create health bar if not found
	if not health_bar_container or not health_bar:
		print("Creating dynamic health bar")
		create_health_bar()
	
	# Setup dodge effect
	setup_dodge_effect()
	
	# Connect animation finished signal for Knight
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Initial health bar update
	update_health_bar()
	
	# SINGLE PLAYER FIX: Set authority for single player mode
	var main_scene = get_tree().get_first_node_in_group("main")
	if main_scene and not main_scene.is_multiplayer_game:
		# In single player, set authority to 1 (local player)
		set_multiplayer_authority(1)
		print("Single player mode: Setting multiplayer authority to 1")
	
	print("Player created: ", character_data.name)
	print("Player added to 'player' group")
	print("Player health: ", current_health, "/", base_health)

func setup_dodge_effect():
	# Create dodge effect sprite
	dodge_effect_sprite = AnimatedSprite2D.new()
	dodge_effect_sprite.name = "DodgeEffect"
	dodge_effect_sprite.visible = false
	add_child(dodge_effect_sprite)
	
	# Create dodge effect animation
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("dodge")
	sprite_frames.set_animation_speed("dodge", 12.0)
	sprite_frames.set_animation_loop("dodge", false)
	
	# Load dodge effect sprite sheet
	var dodge_sheet = load("res://assets/effects/dodge_effect.png")
	if dodge_sheet:
		var frame_width = dodge_sheet.get_width() / 6
		var frame_height = dodge_sheet.get_height()
		for i in range(6):
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = dodge_sheet
			atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("dodge", atlas_tex)
	
	dodge_effect_sprite.sprite_frames = sprite_frames
	print("Dodge effect system initialized")

func configure_character():
	# Apply character stats to player
	base_speed = 200.0 + (character_data.speed * 20.0)  # Speed: 200-380
	base_health = character_data.health * 20.0  # Health: 100-200
	current_health = base_health
	damage_multiplier = 0.5 + (character_data.strength * 0.1)  # Damage: 0.5-1.5x
	armor_reduction = character_data.armor * 0.05  # Armor: 0-50% reduction
	
	# Set visual appearance based on character
	if animated_sprite:
		setup_character_animations()
	
	# Set collision layers
	collision_layer = 1  # Player layer
	collision_mask = 2   # Collides with walls

func setup_character_animations():
	# Create SpriteFrames resource for animations
	var sprite_frames = SpriteFrames.new()
	
	# Create animations based on character type
	match character_data.name:
		"Knight":
			setup_knight_animations(sprite_frames)
		"Berserker":
			setup_berserker_animations(sprite_frames)
		"Huntress":
			setup_huntress_animations(sprite_frames)
		"Wizard":
			setup_wizard_animations(sprite_frames)
		_:
			print("Unknown character: ", character_data.name)
			return
	
	# Apply sprite frames to AnimatedSprite2D
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.play("idle")
	animated_sprite.scale = Vector2(1.5, 1.5)  # Scale up for better visibility

func setup_knight_animations(sprite_frames: SpriteFrames):
	# Knight uses new multi-frame SVG animations following Blue Witch design guide
	
	# Setup idle animation (8 FPS to match other characters) - 4 frames
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_speed("idle", 8.0)
	sprite_frames.set_animation_loop("idle", true)
	
	for i in range(1, 5):  # 4 frames
		var idle_texture = load("res://assets/characters/knight/sprites/knight_idle_%02d.svg" % i)
		if idle_texture:
			sprite_frames.add_frame("idle", idle_texture)
	print("Loaded Knight idle animation (4 frames)")
	
	# Setup move animation (8 FPS as per design guide) - 4 frames
	sprite_frames.add_animation("move")
	sprite_frames.set_animation_speed("move", 8.0)
	sprite_frames.set_animation_loop("move", true)
	
	for i in range(1, 5):  # 4 frames
		var move_texture = load("res://assets/characters/knight/sprites/knight_move_%02d.svg" % i)
		if move_texture:
			sprite_frames.add_frame("move", move_texture)
	print("Loaded Knight move animation (4 frames)")
	
	# Setup attack animation (12 FPS as per design guide) - single frame for now
	sprite_frames.add_animation("attack")
	sprite_frames.set_animation_speed("attack", 12.0)
	sprite_frames.set_animation_loop("attack", false)
	
	var attack_texture = load("res://assets/characters/knight/sprites/knight_attack.svg")
	if attack_texture:
		sprite_frames.add_frame("attack", attack_texture)
		print("Loaded Knight attack animation")
	
	# Setup special animation (6 FPS as per design guide) - 5 frames with blue flash
	sprite_frames.add_animation("special")
	sprite_frames.set_animation_speed("special", 6.0)
	sprite_frames.set_animation_loop("special", false)
	
	for i in range(1, 6):  # 5 frames
		var special_texture = load("res://assets/characters/knight/sprites/knight_special_%02d.svg" % i)
		if special_texture:
			sprite_frames.add_frame("special", special_texture)
	print("Loaded Knight special animation (5 frames with blue flash)")
	
	# Setup ultimate animation (8 FPS as per design guide) - 5 frames with yellow flash
	sprite_frames.add_animation("ultimate")
	sprite_frames.set_animation_speed("ultimate", 8.0)
	sprite_frames.set_animation_loop("ultimate", false)
	
	for i in range(1, 6):  # 5 frames
		var ultimate_texture = load("res://assets/characters/knight/sprites/knight_ultimate_%02d.svg" % i)
		if ultimate_texture:
			sprite_frames.add_frame("ultimate", ultimate_texture)
	print("Loaded Knight ultimate animation (5 frames with yellow flash)")
	
	# Setup dodge animation (12 FPS for quick dodge) - 3 frames
	sprite_frames.add_animation("dodge")
	sprite_frames.set_animation_speed("dodge", 12.0)
	sprite_frames.set_animation_loop("dodge", false)
	
	for i in range(1, 4):  # 3 frames
		var dodge_texture = load("res://assets/characters/knight/sprites/knight_dodge_%02d.svg" % i)
		if dodge_texture:
			sprite_frames.add_frame("dodge", dodge_texture)
	print("Loaded Knight dodge animation (3 frames)")
	
	# Setup death animation (8 FPS as per design guide) - single frame for now
	var death_texture = load("res://assets/characters/knight/sprites/knight_death.svg")
	if death_texture:
		sprite_frames.add_animation("death")
		sprite_frames.set_animation_speed("death", 8.0)
		sprite_frames.set_animation_loop("death", false)
		sprite_frames.add_frame("death", death_texture)
		print("Loaded Knight death animation")
	else:
		print("Knight death animation not found, skipping")
	
	# Keep legacy run animation as alias to move for compatibility
	sprite_frames.add_animation("run")
	sprite_frames.set_animation_speed("run", 8.0)
	sprite_frames.set_animation_loop("run", true)
	
	# Copy move frames to run animation
	for i in range(1, 5):  # 4 frames
		var move_texture = load("res://assets/characters/knight/sprites/knight_move_%02d.svg" % i)
		if move_texture:
			sprite_frames.add_frame("run", move_texture)
	print("Added Knight run animation alias (4 frames)")

func setup_berserker_animations(sprite_frames: SpriteFrames):
	# Berserker uses new multi-frame SVG animations following Blue Witch design guide
	
	# Setup idle animation (8 FPS to match other characters) - 4 frames
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_speed("idle", 8.0)
	sprite_frames.set_animation_loop("idle", true)
	
	for i in range(1, 5):  # 4 frames
		var idle_texture = load("res://assets/characters/berserker/Sprites/berserker_idle_%02d.svg" % i)
		if idle_texture:
			sprite_frames.add_frame("idle", idle_texture)
	print("Loaded Berserker idle animation (4 frames)")
	
	# Setup move animation (8 FPS as per design guide) - 4 frames
	sprite_frames.add_animation("move")
	sprite_frames.set_animation_speed("move", 8.0)
	sprite_frames.set_animation_loop("move", true)
	
	for i in range(1, 5):  # 4 frames
		var move_texture = load("res://assets/characters/berserker/Sprites/berserker_move_%02d.svg" % i)
		if move_texture:
			sprite_frames.add_frame("move", move_texture)
	print("Loaded Berserker move animation (4 frames)")
	
	# Setup attack animation (8 FPS for lingering effect) - 3 frames with enhanced effects
	sprite_frames.add_animation("attack")
	sprite_frames.set_animation_speed("attack", 8.0)
	sprite_frames.set_animation_loop("attack", false)
	
	for i in range(1, 4):  # 3 frames
		var attack_texture = load("res://assets/characters/berserker/Sprites/berserker_attack_%02d.svg" % i)
		if attack_texture:
			sprite_frames.add_frame("attack", attack_texture)
	print("Loaded Berserker attack animation (3 frames with enhanced effects)")
	
	# Setup special animation (6 FPS as per design guide) - 5 frames with blue flash
	sprite_frames.add_animation("special")
	sprite_frames.set_animation_speed("special", 6.0)
	sprite_frames.set_animation_loop("special", false)
	
	for i in range(1, 6):  # 5 frames
		var special_texture = load("res://assets/characters/berserker/Sprites/berserker_special_%02d.svg" % i)
		if special_texture:
			sprite_frames.add_frame("special", special_texture)
	print("Loaded Berserker special animation (5 frames with blue flash)")
	
	# Setup ultimate animation (8 FPS as per design guide) - 5 frames with yellow flash
	sprite_frames.add_animation("ultimate")
	sprite_frames.set_animation_speed("ultimate", 8.0)
	sprite_frames.set_animation_loop("ultimate", false)
	
	for i in range(1, 6):  # 5 frames
		var ultimate_texture = load("res://assets/characters/berserker/Sprites/berserker_ultimate_%02d.svg" % i)
		if ultimate_texture:
			sprite_frames.add_frame("ultimate", ultimate_texture)
	print("Loaded Berserker ultimate animation (5 frames with yellow flash)")
	
	# Setup dodge animation (12 FPS for quick dodge) - 3 frames
	sprite_frames.add_animation("dodge")
	sprite_frames.set_animation_speed("dodge", 12.0)
	sprite_frames.set_animation_loop("dodge", false)
	
	for i in range(1, 4):  # 3 frames
		var dodge_texture = load("res://assets/characters/berserker/Sprites/berserker_dodge_%02d.svg" % i)
		if dodge_texture:
			sprite_frames.add_frame("dodge", dodge_texture)
	print("Loaded Berserker dodge animation (3 frames)")
	
	# Setup death animation (8 FPS as per design guide) - single frame for now
	var death_path = "res://assets/characters/berserker/Sprites/berserker_death.svg"
	if ResourceLoader.exists(death_path):
		var death_texture = load(death_path)
		if death_texture:
			sprite_frames.add_animation("death")
			sprite_frames.set_animation_speed("death", 8.0)
			sprite_frames.set_animation_loop("death", false)
			sprite_frames.add_frame("death", death_texture)
			print("Loaded Berserker death animation")
		else:
			print("Berserker death texture failed to load, skipping")
	else:
		print("Berserker death animation not found (berserker_death.svg missing), skipping")
	
	# Keep legacy run animation as alias to move for compatibility
	sprite_frames.add_animation("run")
	sprite_frames.set_animation_speed("run", 8.0)
	sprite_frames.set_animation_loop("run", true)
	
	# Copy move frames to run animation
	for i in range(1, 5):  # 4 frames
		var move_texture = load("res://assets/characters/berserker/Sprites/berserker_move_%02d.svg" % i)
		if move_texture:
			sprite_frames.add_frame("run", move_texture)
	print("Added Berserker run animation alias (4 frames)")

func setup_huntress_animations(sprite_frames: SpriteFrames):
	# Huntress uses new multi-frame SVG animations following Blue Witch design guide
	
	# Setup idle animation (8 FPS to match other characters) - 4 frames with subtle breathing
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_speed("idle", 8.0)
	sprite_frames.set_animation_loop("idle", true)
	
	for i in range(1, 5):  # 4 frames
		var idle_texture = load("res://assets/characters/huntress/Sprites/huntress_idle_%02d.svg" % i)
		if idle_texture:
			sprite_frames.add_frame("idle", idle_texture)
	print("Loaded Huntress idle animation (4 frames with subtle breathing)")
	
	# Setup move animation (8 FPS as per design guide) - 4 frames
	sprite_frames.add_animation("move")
	sprite_frames.set_animation_speed("move", 8.0)
	sprite_frames.set_animation_loop("move", true)
	
	for i in range(1, 5):  # 4 frames
		var move_texture = load("res://assets/characters/huntress/Sprites/huntress_move_%02d.svg" % i)
		if move_texture:
			sprite_frames.add_frame("move", move_texture)
	print("Loaded Huntress move animation (4 frames)")
	
	# Setup attack animation (8 FPS for lingering archery effect) - 3 frames (draw, aim, release)
	sprite_frames.add_animation("attack")
	sprite_frames.set_animation_speed("attack", 8.0)
	sprite_frames.set_animation_loop("attack", false)
	
	for i in range(1, 4):  # 3 frames
		var attack_texture = load("res://assets/characters/huntress/Sprites/huntress_attack_%02d.svg" % i)
		if attack_texture:
			sprite_frames.add_frame("attack", attack_texture)
	print("Loaded Huntress attack animation (3 frames: draw, aim, release)")
	
	# Setup special animation (6 FPS as per design guide) - 5 frames with nature magic
	sprite_frames.add_animation("special")
	sprite_frames.set_animation_speed("special", 6.0)
	sprite_frames.set_animation_loop("special", false)
	
	for i in range(1, 6):  # 5 frames
		var special_texture = load("res://assets/characters/huntress/Sprites/huntress_special_%02d.svg" % i)
		if special_texture:
			sprite_frames.add_frame("special", special_texture)
	print("Loaded Huntress special animation (5 frames with nature magic)")
	
	# Setup ultimate animation (8 FPS as per design guide) - 5 frames with forest's vengeance
	sprite_frames.add_animation("ultimate")
	sprite_frames.set_animation_speed("ultimate", 8.0)
	sprite_frames.set_animation_loop("ultimate", false)
	
	for i in range(1, 6):  # 5 frames
		var ultimate_texture = load("res://assets/characters/huntress/Sprites/huntress_ultimate_%02d.svg" % i)
		if ultimate_texture:
			sprite_frames.add_frame("ultimate", ultimate_texture)
	print("Loaded Huntress ultimate animation (5 frames with forest's vengeance)")
	
	# Setup dodge animation (12 FPS for quick dodge) - 3 frames
	sprite_frames.add_animation("dodge")
	sprite_frames.set_animation_speed("dodge", 12.0)
	sprite_frames.set_animation_loop("dodge", false)
	
	for i in range(1, 4):  # 3 frames
		var dodge_texture = load("res://assets/characters/huntress/Sprites/huntress_dodge_%02d.svg" % i)
		if dodge_texture:
			sprite_frames.add_frame("dodge", dodge_texture)
	print("Loaded Huntress dodge animation (3 frames)")
	
	# Setup death animation (8 FPS as per design guide) - single frame for now
	var death_texture = load("res://assets/characters/huntress/Sprites/huntress_death.svg")
	if death_texture:
		sprite_frames.add_animation("death")
		sprite_frames.set_animation_speed("death", 8.0)
		sprite_frames.set_animation_loop("death", false)
		sprite_frames.add_frame("death", death_texture)
		print("Loaded Huntress death animation")
	else:
		print("Huntress death animation not found, skipping")
	
	# Keep legacy run animation as alias to move for compatibility
	sprite_frames.add_animation("run")
	sprite_frames.set_animation_speed("run", 8.0)
	sprite_frames.set_animation_loop("run", true)
	
	# Copy move frames to run animation
	for i in range(1, 5):  # 4 frames
		var move_texture = load("res://assets/characters/huntress/Sprites/huntress_move_%02d.svg" % i)
		if move_texture:
			sprite_frames.add_frame("run", move_texture)
	print("Added Huntress run animation alias (4 frames)")

func setup_wizard_animations(sprite_frames: SpriteFrames):
	# Wizard uses new multi-frame SVG animations following Blue Witch design guide
	
	# Setup idle animation (8 FPS to match other characters) - 4 frames
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_speed("idle", 8.0)
	sprite_frames.set_animation_loop("idle", true)
	
	for i in range(1, 5):  # 4 frames
		var idle_texture = load("res://assets/characters/wizard/sprites/wizard_idle_%02d.svg" % i)
		if idle_texture:
			sprite_frames.add_frame("idle", idle_texture)
	print("Loaded Wizard idle animation (4 frames)")
	
	# Setup move animation (8 FPS for robed walking)
	sprite_frames.add_animation("move")
	sprite_frames.set_animation_speed("move", 8.0)
	sprite_frames.set_animation_loop("move", true)
	
	var move_texture = load("res://assets/characters/wizard/sprites/wizard_move.svg")
	if move_texture:
		sprite_frames.add_frame("move", move_texture)
		print("Loaded Wizard move animation")
	
	# Setup attack animation (12 FPS for sharp spellcasting)
	sprite_frames.add_animation("attack")
	sprite_frames.set_animation_speed("attack", 12.0)
	sprite_frames.set_animation_loop("attack", false)
	
	var attack_texture = load("res://assets/characters/wizard/sprites/wizard_attack.svg")
	if attack_texture:
		sprite_frames.add_frame("attack", attack_texture)
		print("Loaded Wizard attack animation")
	
	# Setup special animation (6 FPS for magic missile with blue flash) - 3 frames
	sprite_frames.add_animation("special")
	sprite_frames.set_animation_speed("special", 6.0)
	sprite_frames.set_animation_loop("special", false)
	
	for i in range(1, 4):  # 3 frames
		var special_texture = load("res://assets/characters/wizard/sprites/wizard_special_%02d.svg" % i)
		if special_texture:
			sprite_frames.add_frame("special", special_texture)
	print("Loaded Wizard special animation (3 frames with blue flash)")
	
	# Setup ultimate animation (6 FPS for arcane storm with big effects) - 5 frames
	sprite_frames.add_animation("ultimate")
	sprite_frames.set_animation_speed("ultimate", 6.0)
	sprite_frames.set_animation_loop("ultimate", false)
	
	for i in range(1, 6):  # 5 frames
		var ultimate_texture = load("res://assets/characters/wizard/sprites/wizard_ultimate_%02d.svg" % i)
		if ultimate_texture:
			sprite_frames.add_frame("ultimate", ultimate_texture)
	print("Loaded Wizard ultimate animation (5 frames with big arcane storm effects)")
	
	# Setup dodge animation (12 FPS for quick blink-style evasion)
	sprite_frames.add_animation("dodge")
	sprite_frames.set_animation_speed("dodge", 12.0)
	sprite_frames.set_animation_loop("dodge", false)
	
	var dodge_texture = load("res://assets/characters/wizard/sprites/wizard_dodge.svg")
	if dodge_texture:
		sprite_frames.add_frame("dodge", dodge_texture)
		print("Loaded Wizard dodge animation")
	
	# Setup death animation (8 FPS for magical collapse)
	var death_texture = load("res://assets/characters/wizard/sprites/wizard_death.svg")
	if death_texture:
		sprite_frames.add_animation("death")
		sprite_frames.set_animation_speed("death", 8.0)
		sprite_frames.set_animation_loop("death", false)
		sprite_frames.add_frame("death", death_texture)
		print("Loaded Wizard death animation")
	else:
		print("Wizard death animation not found, skipping")
	
	# Keep legacy run animation as alias to move for compatibility
	sprite_frames.add_animation("run")
	sprite_frames.set_animation_speed("run", 8.0)
	sprite_frames.set_animation_loop("run", true)
	
	# Copy move texture to run animation for compatibility
	var run_texture = load("res://assets/characters/wizard/sprites/wizard_move.svg")
	if run_texture:
		sprite_frames.add_frame("run", run_texture)
		print("Added Wizard run animation alias")

func create_health_bar():
	# Create health bar UI
	health_bar_container = Node2D.new()
	health_bar_container.name = "HealthBarContainer"
	health_bar_container.position = Vector2(0, -30)
	add_child(health_bar_container)
	
	# Background (bright red - shows lost health) - slightly larger for visibility
	var bg = ColorRect.new()
	bg.name = "HealthBarBackground" 
	bg.color = Color(1.0, 0.0, 0.0, 1.0)  # Pure bright red - maximum visibility
	bg.size = Vector2(64, 8)  # Slightly larger than green bar
	bg.position = Vector2(-32, -4)  # Offset to center the larger background
	health_bar_container.add_child(bg)
	
	# Health bar (green - shows remaining health)
	health_bar = ColorRect.new()
	health_bar.name = "HealthBar"
	health_bar.color = Color(0.0, 1.0, 0.0, 1.0)  # Pure bright green
	health_bar.size = Vector2(60, 6)
	health_bar.position = Vector2(-30, -3)
	health_bar_container.add_child(health_bar)
	# Ensure health bar is on top
	health_bar_container.move_child(health_bar, health_bar_container.get_child_count() - 1)
	
	# Ensure health bar is visible and on top
	health_bar_container.visible = true
	health_bar_container.z_index = 100  # Very high z-index to ensure it renders on top of everything
	
	print("Health bar created for player - Reference set: ", health_bar != null)
	print("🎨 Red background: size=", bg.size, " pos=", bg.position, " color=", bg.color)
	print("🎨 Green health bar: size=", health_bar.size, " pos=", health_bar.position, " color=", health_bar.color)
	
	# Initialize health bar to full
	update_health_bar()

func update_health_bar():
	if health_bar and is_instance_valid(health_bar):
		var health_percentage = current_health / base_health
		health_bar.size.x = 60 * health_percentage
		
		# Change color based on health
		if health_percentage > 0.6:
			health_bar.color = Color.GREEN
		elif health_percentage > 0.3:
			health_bar.color = Color.YELLOW
		else:
			health_bar.color = Color.RED
		
		print("🏥 Health bar updated: ", current_health, "/", base_health, " (", (health_percentage * 100), "%) - Width: ", health_bar.size.x, "/60 - Red should be visible: ", health_bar.size.x < 60)
	else:
		print("⚠️ Health bar reference is null or invalid!")
		# Try to find existing health bar
		var container = get_node_or_null("HealthBarContainer")
		if container:
			health_bar = container.get_node_or_null("HealthBar")
			if health_bar:
				print("✅ Found existing health bar, updating reference")
				update_health_bar()  # Retry update
			else:
				print("⚠️ HealthBar node not found in container")
		else:
			print("⚠️ HealthBarContainer not found - creating new health bar")
			create_health_bar()

func set_character_data(new_character: CharacterData.Character):
	character_data = new_character
	print("=== Character Data Set ===")
	print("Character Name: ", character_data.name)
	print("Primary Attack Type: ", character_data.primary_attack_type)
	print("VFX Primary: ", character_data.vfx_primary)
	print("VFX Special: ", character_data.vfx_special)
	print("VFX Ultimate: ", character_data.vfx_ultimate)
	print("VFX Dodge: ", character_data.vfx_dodge)
	print("========================")
	configure_character()
	print("Character updated to: ", character_data.name)

func _physics_process(delta):
	# Handle dodge roll
	if is_dodge_rolling:
		handle_dodge_roll(delta)
	else:
		handle_movement(delta)
	
	# Update timers
	update_timers(delta)
	
	# Handle input
	handle_input()
	
	# Move the player
	move_and_slide()
	
	# MULTIPLAYER FIX: Sync position to other clients
	sync_position_to_clients()
	
	# Update animations based on movement
	update_animations()

# NEW: Sync player position and velocity to other clients  
func sync_position_to_clients():
	# Check if single player mode first
	var main_scene = get_tree().get_first_node_in_group("main")
	var is_single_player = main_scene and not main_scene.is_multiplayer_game
	
	# Don't sync in single player mode
	if is_single_player:
		return
	
	# Safety check for multiplayer system
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return
		
	# Only sync if multiplayer and we are the authority for this player
	if multiplayer.get_unique_id() == get_multiplayer_authority():
		# Sync position periodically but only if we've moved significantly
		if Engine.get_process_frames() % 5 == 0:  # Every 5th frame (~12 FPS)
			# Only sync if position changed by a meaningful amount to reduce bandwidth
			var pos_threshold = 5.0  # Only sync if moved more than 5 pixels
			if not has_meta("last_sync_pos") or global_position.distance_to(get_meta("last_sync_pos")) > pos_threshold:
				sync_player_position.rpc(global_position, velocity, facing_direction)
				set_meta("last_sync_pos", global_position)

# RPC to sync player position to all clients
@rpc("any_peer", "call_remote", "unreliable") 
func sync_player_position(pos: Vector2, vel: Vector2, direction: Vector2):
	# Only apply to remote players (not local player)
	if multiplayer.get_remote_sender_id() != multiplayer.get_unique_id():
		# Smooth position update to avoid jitter - use interpolation
		var lerp_speed = 10.0  # Adjust for smoothness vs responsiveness
		global_position = global_position.lerp(pos, lerp_speed * get_physics_process_delta_time())
		velocity = vel
		facing_direction = direction

func handle_movement(delta):
	# CRITICAL FIX: Check if single player mode first
	var main_scene = get_tree().get_first_node_in_group("main")
	var is_single_player = main_scene and not main_scene.is_multiplayer_game
	
	# Only check authority in multiplayer mode
	if not is_single_player and not is_multiplayer_authority():
		return  # This is a remote player in multiplayer, don't process movement
	
	# Get input direction
	var input_direction = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		input_direction.x += 1
	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("move_down"):
		input_direction.y += 1
	if Input.is_action_pressed("move_up"):
		input_direction.y -= 1
	
	# Normalize diagonal movement
	if input_direction != Vector2.ZERO:
		input_direction = input_direction.normalized()
		facing_direction = input_direction
	
	# Apply movement
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * base_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

func handle_dodge_roll(delta):
	# Continue dodge roll movement
	velocity = dodge_roll_direction * 600.0  # High speed during dodge
	dodge_roll_timer -= delta
	
	if dodge_roll_timer <= 0:
		is_dodge_rolling = false
		is_invincible = false  # Disable invincibility frames
		stop_invincibility_visual_feedback()  # Stop visual feedback
		print("Dodge roll ended - invincibility frames disabled")

func update_timers(delta):
	# Update ability cooldowns
	if special_ability_timer > 0:
		special_ability_timer -= delta
	if ultimate_ability_timer > 0:
		ultimate_ability_timer -= delta
	if primary_attack_timer > 0:
		primary_attack_timer -= delta
	if dodge_roll_cooldown_timer > 0:
		dodge_roll_cooldown_timer -= delta

func update_animations():
	# Update character animations based on current state
	if not animated_sprite:
		return
	
	# Don't change animation if playing special animations
	var current_anim = animated_sprite.animation
	if current_anim in ["attack", "special", "ultimate", "dodge", "death"] and animated_sprite.is_playing():
		return
	
	# Set animation based on movement (use "move" for SVG characters, "run" for legacy sprite sheets)
	if velocity.length() > 10:
		var move_animation = "move" if (character_data.name == "Knight" or character_data.name == "Berserker" or character_data.name == "Huntress" or character_data.name == "Wizard") else "run"
		if animated_sprite.animation != move_animation:
			animated_sprite.play(move_animation)
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
	
	# Flip sprite based on direction
	if facing_direction.x < 0:
		animated_sprite.flip_h = true
	elif facing_direction.x > 0:
		animated_sprite.flip_h = false

# Animation system functions for enhanced Knight
func play_animation(animation_name: String, force: bool = false):
	if not animated_sprite:
		return
	
	# Check if animation exists
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		print("Animation not found: ", animation_name)
		return
	
	# Don't interrupt special animations unless forced
	var current_anim = animated_sprite.animation
	if not force and current_anim in ["attack", "special", "ultimate", "dodge", "death"] and animated_sprite.is_playing():
		return
	
	# Play the animation
	animated_sprite.play(animation_name)
	print("Playing animation: ", animation_name)

func play_attack_animation():
	play_animation("attack", true)

func play_special_animation():
	if character_data.name == "Knight" or character_data.name == "Berserker" or character_data.name == "Huntress" or character_data.name == "Wizard":
		play_animation("special", true)
	else:
		play_attack_animation()  # Fallback for other characters

func play_ultimate_animation():
	if character_data.name == "Knight" or character_data.name == "Berserker" or character_data.name == "Huntress" or character_data.name == "Wizard":
		play_animation("ultimate", true)
	else:
		play_attack_animation()  # Fallback for other characters

func play_dodge_animation():
	if character_data.name == "Knight" or character_data.name == "Berserker" or character_data.name == "Huntress" or character_data.name == "Wizard":
		play_animation("dodge", true)
	else:
		# For other characters, just keep existing dodge effect
		pass

func play_death_animation():
	if character_data.name == "Knight" or character_data.name == "Berserker" or character_data.name == "Huntress" or character_data.name == "Wizard":
		play_animation("death", true)
	else:
		# For other characters, handle death differently
		pass

func _on_animation_finished():
	if not animated_sprite:
		return
	
	var finished_animation = animated_sprite.animation
	
	# Handle animation completion logic
	match finished_animation:
		"attack", "special", "ultimate":
			# Return to appropriate state after combat animations
			if velocity.length() > 10:
				var move_animation = "move" if (character_data.name == "Knight" or character_data.name == "Berserker" or character_data.name == "Huntress" or character_data.name == "Wizard") else "run"
				animated_sprite.play(move_animation)
			else:
				animated_sprite.play("idle")
		"dodge":
			# Return to appropriate state after dodge
			if velocity.length() > 10:
				var move_animation = "move" if (character_data.name == "Knight" or character_data.name == "Berserker" or character_data.name == "Huntress" or character_data.name == "Wizard") else "run"
				animated_sprite.play(move_animation)
			else:
				animated_sprite.play("idle")
		"death":
			# Stay in death state
			pass

# Hit animation implementation (flashing effect)
func play_hit_animation():
	if not animated_sprite:
		return
	
	# Create a flashing effect by modulating the sprite color
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)
	
	print("Playing hit flash effect")

func handle_input():
	# CRITICAL FIX: Check if single player mode first
	var main_scene = get_tree().get_first_node_in_group("main")
	var is_single_player = main_scene and not main_scene.is_multiplayer_game
	
	# Only check authority in multiplayer mode
	if not is_single_player and not is_multiplayer_authority():
		return  # This is a remote player in multiplayer, don't process input
	
	# Primary attack
	if Input.is_action_just_pressed("primary_attack"):
		print("🗡️ LOCAL PLAYER ", name, " performing primary attack")
		primary_attack()
	
	# Special ability
	if Input.is_action_just_pressed("special_ability"):
		print("✨ LOCAL PLAYER ", name, " performing special ability")
		special_ability()
	
	# Ultimate ability
	if Input.is_action_just_pressed("ultimate_ability"):
		print("💥 LOCAL PLAYER ", name, " performing ultimate ability")
		ultimate_ability()
	
	# Dodge roll
	if Input.is_action_just_pressed("dodge_roll"):
		print("🏃 LOCAL PLAYER ", name, " performing dodge roll")
		dodge_roll()

# Functions called by Main.gd
func perform_primary_attack():
	primary_attack()

func perform_special_ability():
	special_ability()

func perform_ultimate_ability():
	ultimate_ability()

func perform_dodge_roll():
	dodge_roll()

func primary_attack():
	# Check if on cooldown (character-specific)
	var main_scene = get_tree().get_first_node_in_group("main")
	var character_name = character_data.name if character_data else "Unknown"
	var cooldown = main_scene.get_character_cooldown(character_name, "primary") if main_scene else 0.0
	if cooldown > 0:
		print("Primary attack on cooldown: ", cooldown)
		return
		
	print("Primary attack: ", character_data.primary_attack_type if character_data else "unknown")
	
	# Play local animation and handle local effects immediately (ONLY for local player)
	play_animation("attack")
	
	# TEMPORARILY DISABLED: No RPC sync to test mirroring fix
	# var is_multiplayer = main_scene and main_scene.is_multiplayer_game
	# if is_multiplayer:
	#     sync_player_action.rpc("primary_attack", multiplayer.get_unique_id())
	
	# Handle attack based on character type (ONLY for local player)
	if main_scene:
		# Set cooldown in main node (character-specific)
		# Use default cooldowns based on character type
		var cooldown_time = 0.5  # Default
		match character_name:
			"Knight": cooldown_time = 0.3
			"Berserker": cooldown_time = 0.8
			"Huntress": cooldown_time = 0.2
			"Wizard": cooldown_time = 0.4
		
		main_scene.set_character_cooldown(character_name, "primary", cooldown_time)
		
		# Handle directional attack with appropriate damage/range per character
		var damage = 25.0  # Default
		var range = 80.0   # Default
		
		match character_name:
			"Knight":
				damage = 25.0
				range = 80.0
			"Berserker":
				damage = 35.0
				range = 75.0
			"Huntress":
				damage = 20.0
				range = 100.0
			"Wizard":
				damage = 30.0
				range = 90.0
		
		var attack_type = character_data.primary_attack_type if character_data else "melee"
		var cursor_pos = get_global_mouse_position()
		var attack_direction = (cursor_pos - global_position).normalized()
		main_scene.handle_player_directional_attack(attack_type, global_position, range, damage, attack_direction)

func special_ability():
	# Check if on cooldown (character-specific)
	var main_scene = get_tree().get_first_node_in_group("main")
	var character_name = character_data.name if character_data else "Unknown"
	var cooldown = main_scene.get_character_cooldown(character_name, "special") if main_scene else 0.0
	if cooldown > 0:
		print("Special ability on cooldown: ", cooldown)
		return
		
	print("Using special ability: ", character_data.special_ability_name if character_data else "unknown")
	
	# Play local animation and handle local effects (ONLY for local player)
	play_animation("special")
	
	# Set cooldown first
	if main_scene:
		var cooldown_time = 5.0  # Default special cooldown
		match character_name:
			"Knight":
				cooldown_time = 5.0
			"Berserker":
				cooldown_time = 6.0
			"Huntress":
				cooldown_time = 4.0
			"Wizard":
				cooldown_time = 5.0
		
		main_scene.set_character_cooldown(character_name, "special", cooldown_time)
	
	# Call character-specific special ability implementation
	match character_name:
		"Knight":
			perform_knight_special_attack()
		"Berserker":
			perform_berserker_special_attack()
		"Huntress":
			perform_huntress_special_attack()
		"Wizard":
			perform_wizard_special_attack()
		_:
			print("Unknown character special ability")

func ultimate_ability():
	# Check if on cooldown (character-specific)
	var main_scene = get_tree().get_first_node_in_group("main")
	var character_name = character_data.name if character_data else "Unknown"
	var cooldown = main_scene.get_character_cooldown(character_name, "ultimate") if main_scene else 0.0
	if cooldown > 0:
		print("Ultimate ability on cooldown: ", cooldown)
		return
		
	print("Using ultimate ability: ", character_data.ultimate_ability_name if character_data else "unknown")
	
	# Play local animation and handle local effects (ONLY for local player) 
	play_animation("ultimate")
	
	# Set cooldown first
	if main_scene:
		var cooldown_time = 15.0  # Default ultimate cooldown
		match character_name:
			"Knight":
				cooldown_time = 15.0
			"Berserker":
				cooldown_time = 18.0
			"Huntress":
				cooldown_time = 12.0
			"Wizard":
				cooldown_time = 15.0
		
		main_scene.set_character_cooldown(character_name, "ultimate", cooldown_time)
	
	# Call character-specific ultimate ability implementation
	match character_name:
		"Knight":
			perform_knight_ultimate_attack()
		"Berserker":
			perform_berserker_ultimate_attack()
		"Huntress":
			perform_huntress_ultimate_attack()
		"Wizard":
			perform_wizard_ultimate_attack()
		_:
			print("Unknown character ultimate ability")

func dodge_roll():
	if dodge_roll_cooldown_timer > 0:
		print("Dodge roll on cooldown: ", dodge_roll_cooldown_timer)
		return
	
	print("Dodge roll")
	
	# Execute dodge locally (ONLY for local player)
	play_dodge_animation()
	
	# Set dodge roll state (ONLY for local player)
	is_dodge_rolling = true
	dodge_roll_timer = 0.3  # 0.3 second duration
	dodge_roll_cooldown_timer = 1.0  # 1 second cooldown
	
	# Enable invincibility frames during dodge (ONLY for local player)
	is_invincible = true
	
	# Set direction (use facing direction or movement direction)
	dodge_roll_direction = facing_direction
	if dodge_roll_direction == Vector2.ZERO:
		dodge_roll_direction = Vector2.RIGHT
	
	# Create custom dodge effect
	create_dodge_effect()
	
	# Apply visual feedback for invincibility
	start_invincibility_visual_feedback()
	
	# TEMPORARILY DISABLED: No RPC sync to test mirroring fix
	# var main_scene = get_tree().get_first_node_in_group("main")
	# var is_multiplayer = main_scene and main_scene.is_multiplayer_game
	# if is_multiplayer:
	#     sync_player_action.rpc("dodge_roll", multiplayer.get_unique_id())

func create_dodge_effect():
	if dodge_effect_sprite:
		dodge_effect_sprite.visible = true
		dodge_effect_sprite.play("dodge")
		
		# Position effect based on dodge direction
		dodge_effect_sprite.position = Vector2.ZERO
		
		# Flip effect based on dodge direction
		if dodge_roll_direction.x < 0:
			dodge_effect_sprite.flip_h = true
		else:
			dodge_effect_sprite.flip_h = false
		
		# Connect to hide effect when animation finishes
		if not dodge_effect_sprite.animation_finished.is_connected(_on_dodge_effect_finished):
			dodge_effect_sprite.animation_finished.connect(_on_dodge_effect_finished)

func _on_dodge_effect_finished():
	if dodge_effect_sprite:
		dodge_effect_sprite.visible = false

func start_invincibility_visual_feedback():
	# Create pulsing transparency effect during invincibility frames
	if animated_sprite:
		# Stop any existing invincibility tween
		if invincibility_tween:
			invincibility_tween.kill()
		
		# Create new tween for invincibility effect
		invincibility_tween = create_tween()
		invincibility_tween.set_loops(-1)  # Loop indefinitely
		invincibility_tween.tween_property(animated_sprite, "modulate:a", 0.5, 0.1)
		invincibility_tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.1)
		print("💫 Invincibility visual feedback started")

func stop_invincibility_visual_feedback():
	# Stop the invincibility tween and restore normal transparency
	if invincibility_tween:
		invincibility_tween.kill()
		invincibility_tween = null
	
	if animated_sprite:
		animated_sprite.modulate.a = 1.0  # Restore full opacity
		print("💫 Invincibility visual feedback stopped")

# Character-specific special attack functions
func perform_wizard_special_attack():
	# Wizard shoots unique Arcane Orb projectile
	var cursor_pos = get_global_mouse_position()
	var attack_direction = (cursor_pos - global_position).normalized()
	
	# Update facing direction
	facing_direction = attack_direction
	
	# Call Main.gd to create the special Arcane Orb projectile
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node:
		# Use high damage for wizard's special attack with explosion
		var special_damage = 90.0 * damage_multiplier
		main_node.create_projectile(global_position, attack_direction, special_damage, main_node.ProjectileType.ARCANE_ORB)
		print("✨ Wizard Arcane Orb launched with explosive power!")
	
	print("Wizard special attack: Arcane Orb launched!")

func perform_huntress_special_attack():
	# Huntress shoots high-damage homing arrow
	var cursor_pos = get_global_mouse_position()
	var attack_direction = (cursor_pos - global_position).normalized()
	
	# Update facing direction
	facing_direction = attack_direction
	
	# Call Main.gd to create the special Homing Arrow projectile
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node:
		# Use high damage for huntress's special homing attack with piercing
		var special_damage = 85.0 * damage_multiplier
		main_node.create_projectile(global_position, attack_direction, special_damage, main_node.ProjectileType.HOMING_ARROW)
		print("🎯 Huntress Piercing Shot launched - seeking enemies!")
	
	print("Huntress special attack: Homing Piercing Shot fired!")

func perform_knight_special_attack():
	# Knight creates Divine Shield - area healing and enemy damage
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node:
		# Create divine energy area effect at player position
		var special_damage = 35.0 * damage_multiplier
		main_node.create_projectile(global_position, Vector2.ZERO, special_damage, main_node.ProjectileType.DIVINE_ENERGY)
		print("🛡️ Knight Divine Shield activated - healing and protection!")

func perform_berserker_special_attack():
	# Berserker uses Blood Rage - sacrifices health for damage boost and area attack
	# Sacrifice some health
	var health_cost = base_health * 0.15  # 15% of max health
	current_health = max(current_health - health_cost, 1.0)  # Don't kill self
	update_health_bar()
	print("🩸 Berserker sacrificed ", health_cost, " health for power!")
	
	# Create blood wave area effect
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node:
		var special_damage = 60.0 * damage_multiplier * 1.5  # 50% bonus damage from rage
		main_node.create_projectile(global_position, Vector2.ZERO, special_damage, main_node.ProjectileType.BLOOD_WAVE)
		print("💥 Blood Wave erupts with berserker's rage!")
	
	# Temporary damage boost
	var original_multiplier = damage_multiplier
	damage_multiplier *= 1.3  # 30% damage boost
	
	# Remove boost after duration
	var timer = Timer.new()
	timer.wait_time = 5.0  # 5 second boost
	timer.one_shot = true
	timer.timeout.connect(func():
		damage_multiplier = original_multiplier
		print("🩸 Berserker rage subsides - damage returns to normal")
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

func perform_wizard_ultimate_attack():
	# Wizard: Meteor Storm - summon multiple meteors over large area
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node:
		# Create 8 meteors in a wide spread pattern
		for i in range(8):
			# Random positions around the player in a large area
			var angle = (i * PI * 2 / 8) + randf_range(-0.3, 0.3)  # Spread around circle with some randomness
			var distance = randf_range(100.0, 200.0)  # Distance from player
			var target_pos = global_position + Vector2(cos(angle), sin(angle)) * distance
			
			# Create meteor with downward trajectory
			var meteor_direction = Vector2(0, 1)  # Falling down
			var ultimate_damage = 150.0 * damage_multiplier
			
			# Delay meteors for dramatic effect
			var delay_timer = Timer.new()
			delay_timer.wait_time = (i + 1) * 0.2  # 0.2, 0.4, 0.6, 0.8, 1.0 second intervals
			delay_timer.one_shot = true
			delay_timer.timeout.connect(func():
				main_node.create_projectile(target_pos, meteor_direction, ultimate_damage, main_node.ProjectileType.METEOR)
				delay_timer.queue_free()
			)
			add_child(delay_timer)
			delay_timer.start()
		
		print("☄️ Wizard Meteor Storm summoned - 8 meteors incoming!")

func perform_huntress_ultimate_attack():
	# Huntress: Rain of Arrows - massive barrage targeting enemies with explosive arrows
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node:
		# Get list of all living enemies for targeting
		var target_enemies = []
		if main_node.has_method("get_living_enemies"):
			target_enemies = main_node.get_living_enemies()
		else:
			# Fallback: try to get enemies from main node
			if main_node.has_member("enemies"):
				for enemy in main_node.enemies:
					if is_instance_valid(enemy) and enemy.has_method("is_dead") and not enemy.is_dead:
						target_enemies.append(enemy)
		
		print("🎯 Huntress ultimate found ", target_enemies.size(), " enemies to target")
		
		# Create 20 explosive arrows in waves targeting enemies
		for wave in range(4):  # 4 waves
			for i in range(5):  # 5 arrows per wave
				var arrow_target: Vector2
				var arrow_start: Vector2
				
				if target_enemies.size() > 0:
					# Target a random enemy
					var target_enemy = target_enemies[randi() % target_enemies.size()]
					arrow_target = target_enemy.global_position
					# Add small random offset so multiple arrows don't hit exact same spot
					var small_offset = Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
					arrow_target += small_offset
				else:
					# Fallback: use cursor position if no enemies found
					var cursor_pos = get_global_mouse_position()
					var spread_radius = 150.0
					var random_offset = Vector2(randf_range(-spread_radius, spread_radius), randf_range(-spread_radius, spread_radius))
					arrow_target = cursor_pos + random_offset
					print("⚠️ No enemies found, falling back to cursor targeting")
				
				# Arrows come from above the target
				arrow_start = arrow_target + Vector2(0, -300)  # Start 300 pixels above target
				var arrow_direction = (arrow_target - arrow_start).normalized()
				var ultimate_damage = 55.0 * damage_multiplier  # Increased from 45.0 to 55.0 for more damage
				
				# Delay waves for sustained barrage effect
				var delay_timer = Timer.new()
				delay_timer.wait_time = wave * 0.4 + i * 0.1  # Waves every 0.4s, arrows every 0.1s within wave
				delay_timer.one_shot = true
				delay_timer.timeout.connect(func():
					var projectile = main_node.create_projectile(arrow_start, arrow_direction, ultimate_damage, main_node.ProjectileType.ARROW)
					# Add area of effect to ultimate arrows for less precision required
					if projectile:
						projectile.set_meta("explosion_radius", 40.0)  # 40 unit explosion radius
						projectile.set_meta("explosion_damage", 30.0 * damage_multiplier)  # Additional explosion damage
						print("💥 Explosive ultimate arrow targeting enemy with AOE!")
					delay_timer.queue_free()
				)
				add_child(delay_timer)
				delay_timer.start()
		
		if target_enemies.size() > 0:
			print("🏹 Huntress Rain of Explosive Arrows - 20 explosive arrows targeting ", target_enemies.size(), " enemies over 4 waves!")
		else:
			print("🏹 Huntress Rain of Explosive Arrows - 20 explosive arrows at cursor position over 4 waves!")

func perform_knight_ultimate_attack():
	# Knight: Divine Storm - massive healing and damage area
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node:
		# Create 3 expanding divine energy waves
		for i in range(3):
			var delay_timer = Timer.new()
			delay_timer.wait_time = (i + 1) * 0.4  # Waves at 0.4, 0.8, 1.2 seconds
			delay_timer.one_shot = true
			delay_timer.timeout.connect(func():
				# Create large divine energy effect
				var ultimate_damage = 70.0 * damage_multiplier
				main_node.create_projectile(global_position, Vector2.ZERO, ultimate_damage, main_node.ProjectileType.DIVINE_ENERGY)
				
				# Massive heal for player
				heal(60.0)
				delay_timer.queue_free()
			)
			add_child(delay_timer)
			delay_timer.start()
		
		print("⚡ Knight Divine Storm - 3 waves of divine energy and healing!")

func perform_berserker_ultimate_attack():
	# Berserker: Berserker's Wrath - massive damage shockwave with huge area
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node:
		# Create 3 expanding blood waves for massive damage
		for i in range(3):
			var delay_timer = Timer.new()
			delay_timer.wait_time = (i + 1) * 0.25  # Quick succession at 0.25s, 0.5s, 0.75s
			delay_timer.one_shot = true
			delay_timer.timeout.connect(func():
				# Create massive blood wave
				var ultimate_damage = 100.0 * damage_multiplier * (1.0 + i * 0.3)  # Increasing damage
				main_node.create_projectile(global_position, Vector2.ZERO, ultimate_damage, main_node.ProjectileType.BLOOD_WAVE)
				delay_timer.queue_free()
			)
			add_child(delay_timer)
			delay_timer.start()
		
		# Huge temporary damage boost
		var original_multiplier = damage_multiplier
		damage_multiplier *= 2.0  # 100% damage boost
		
		# Remove boost after duration
		var boost_timer = Timer.new()
		boost_timer.wait_time = 8.0  # 8 second boost
		boost_timer.one_shot = true
		boost_timer.timeout.connect(func():
			damage_multiplier = original_multiplier
			print("💥 Berserker's ultimate wrath subsides")
			boost_timer.queue_free()
		)
		add_child(boost_timer)
		boost_timer.start()
		
		print("💥 Berserker's Wrath unleashed - massive shockwaves and damage boost!")

func take_damage(damage: float):
	if not is_alive:
		return
	
	# Check for invincibility frames during dodge
	if is_invincible:
		print("💫 Damage blocked by invincibility frames!")
		return
	
	# Apply armor reduction
	var final_damage = damage * (1.0 - armor_reduction)
	current_health -= final_damage
	
	# Play hit animation
	play_hit_animation()
	
	# Update health bar
	update_health_bar()
	
	# Emit signal
	health_changed.emit(current_health, base_health)
	
	# Get main node reference
	var main_node = get_tree().get_first_node_in_group("main")
	
	# NEW: Sync damage to other players in multiplayer
	if main_node and main_node.is_multiplayer_game and multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
		if main_node.has_method("sync_player_damage"):
			main_node.sync_player_damage.rpc(get_multiplayer_authority(), final_damage)
	
	# Check if dead, but not in debug mode
	if current_health <= 0:
		# Check if we're in debug mode
		if main_node and main_node.has_method("is_debug_mode") and main_node.is_debug_mode():
			# In debug mode: clamp health to 1 and continue playing
			current_health = 1.0
			update_health_bar()
			print("🔧 DEBUG MODE: Player would have died, but health clamped to 1")
		else:
			# In playable mode: player dies normally
			die()
	
	print("Player took ", final_damage, " damage. Health: ", current_health)

func die():
	is_alive = false
	print("Player died")
	
	# Play death animation
	play_death_animation()
	
	character_died.emit()

func heal(amount: float):
	if not is_alive:
		return
	
	# Heal the player, clamped to max health
	current_health = min(current_health + amount, base_health)
	
	# Update health bar
	update_health_bar()
	
	# Emit signal
	health_changed.emit(current_health, base_health)
	
	# Visual feedback for healing
	if animated_sprite:
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color.GREEN, 0.1)
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)
	
	# NEW: Sync healing to other players in multiplayer
	if multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
		var main_node = get_tree().get_first_node_in_group("main")
		if main_node and main_node.has_method("sync_player_healing"):
			main_node.sync_player_healing.rpc(get_multiplayer_authority(), amount)
	
	print("💚 Player healed for ", amount, " - Health: ", current_health, "/", base_health)

# NEW: Get health data for synchronization
func get_health_data() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": base_health,
		"is_alive": is_alive
	}

# NEW: Sync health from remote (for display only, not actual health changes)
func sync_health_from_remote(remote_current_health: float, remote_max_health: float):
	# This is for other players to see our health status
	# Update the visual health bar to match remote health
	if health_bar:
		var health_percentage = remote_current_health / remote_max_health
		health_bar.size.x = 60 * health_percentage
		
		# Change color based on health
		if health_percentage > 0.6:
			health_bar.color = Color.GREEN
		elif health_percentage > 0.3:
			health_bar.color = Color.YELLOW
		else:
			health_bar.color = Color.RED
	
	print("🤝 PEER: Received health sync - ", remote_current_health, "/", remote_max_health)

# NEW: Show damage feedback for multiplayer
func show_damage_feedback(damage_amount: float):
	# Visual feedback when other players see us take damage
	if animated_sprite:
		# Flash red briefly
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)
	
	# Create floating damage text
	create_floating_damage_text(damage_amount)

# NEW: Show healing feedback for multiplayer  
func show_healing_feedback(heal_amount: float):
	# Visual feedback when other players see us heal
	if animated_sprite:
		# Flash green briefly
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color.GREEN, 0.1)
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)
	
	# Create floating heal text
	create_floating_heal_text(heal_amount)

# NEW: Create floating damage text for visual feedback
func create_floating_damage_text(damage: float):
	var damage_label = Label.new()
	damage_label.text = "-" + str(int(damage))
	damage_label.position = global_position + Vector2(-10, -40)
	damage_label.add_theme_font_size_override("font_size", 16)
	damage_label.add_theme_color_override("font_color", Color.RED)
	damage_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	damage_label.add_theme_constant_override("shadow_offset_x", 2)
	damage_label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Add to scene
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(damage_label)
		
		# Animate floating upward and fade out
		var text_tween = scene.create_tween()
		text_tween.parallel().tween_property(damage_label, "position:y", damage_label.position.y - 30, 1.0)
		text_tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 1.0)
		text_tween.tween_callback(func():
			if is_instance_valid(damage_label):
				damage_label.queue_free()
		)

# NEW: Create floating heal text for visual feedback
func create_floating_heal_text(heal: float):
	var heal_label = Label.new()
	heal_label.text = "+" + str(int(heal))
	heal_label.position = global_position + Vector2(-10, -40)
	heal_label.add_theme_font_size_override("font_size", 16)
	heal_label.add_theme_color_override("font_color", Color.GREEN)
	heal_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	heal_label.add_theme_constant_override("shadow_offset_x", 2)
	heal_label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Add to scene
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(heal_label)
		
		# Animate floating upward and fade out
		var text_tween = scene.create_tween()
		text_tween.parallel().tween_property(heal_label, "position:y", heal_label.position.y - 30, 1.0)
		text_tween.parallel().tween_property(heal_label, "modulate:a", 0.0, 1.0)
		text_tween.tween_callback(func():
			if is_instance_valid(heal_label):
				heal_label.queue_free()
		)

func get_character_type() -> String:
	if character_data:
		return character_data.name
	return "Unknown" 

# FIXED: RPC to sync player actions across all clients
@rpc("any_peer", "call_remote", "reliable")  
func sync_player_action(action: String, player_id: int):
	# CRITICAL FIX: Only sync visual effects, not actual gameplay
	print("🎭 PEER: Syncing VISUAL effect for action: ", action, " from player ", player_id)
	
	match action:
		"primary_attack":
			# Only play visual animation, no damage or game logic
			if has_method("play_attack_animation_only"):
				play_attack_animation_only()
			else:
				animated_sprite.play("attack")  # Visual only
			print("🎭 Visual: Playing attack animation for remote player")
			
		"dodge_roll":
			# Only play visual animation, no invincibility or movement
			if has_method("play_dodge_animation_only"):
				play_dodge_animation_only()
			else:
				animated_sprite.play("dodge")  # Visual only
			print("🎭 Visual: Playing dodge animation for remote player")
			
		"special_ability":
			# Only play visual animation, no projectiles or effects
			if has_method("play_special_animation_only"):
				play_special_animation_only()
			else:
				animated_sprite.play("special")  # Visual only
			print("🎭 Visual: Playing special animation for remote player")
			
		"ultimate_ability":
			# Only play visual animation, no projectiles or effects
			if has_method("play_ultimate_animation_only"):
				play_ultimate_animation_only()
			else:
				animated_sprite.play("ultimate")  # Visual only
			print("🎭 Visual: Playing ultimate animation for remote player")
		
		_:
			print("🎭 Visual: Unknown action for sync: ", action)

# Visual-only animation methods (no gameplay effects)
func play_attack_animation_only():
	animated_sprite.play("attack")
	# No damage, no cooldowns, just animation

func play_dodge_animation_only():
	animated_sprite.play("dodge") 
	# No invincibility, no movement, just animation

func play_special_animation_only():
	animated_sprite.play("special")
	# No projectiles, no effects, just animation

func play_ultimate_animation_only():
	animated_sprite.play("ultimate")
	# No projectiles, no effects, just animation 
