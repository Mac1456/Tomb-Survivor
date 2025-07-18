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
@onready var health_bar_container: Node2D = $HealthBarContainer
@onready var health_bar: ColorRect = $HealthBarContainer/HealthBar

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
	
	configure_character()
	create_health_bar()
	setup_dodge_effect()
	
	# Connect animation finished signal for Knight
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	print("Player created: ", character_data.name)
	print("Player added to 'player' group")

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
	var death_texture = load("res://assets/characters/berserker/Sprites/berserker_death.svg")
	if death_texture:
		sprite_frames.add_animation("death")
		sprite_frames.set_animation_speed("death", 8.0)
		sprite_frames.set_animation_loop("death", false)
		sprite_frames.add_frame("death", death_texture)
		print("Loaded Berserker death animation")
	else:
		print("Berserker death animation not found, skipping")
	
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
	# Health bar is created in the scene file, just update it
	update_health_bar()

func update_health_bar():
	if health_bar:
		var health_percentage = current_health / base_health
		health_bar.size.x = 60 * health_percentage
		
		# Change color based on health
		if health_percentage > 0.6:
			health_bar.color = Color.GREEN
		elif health_percentage > 0.3:
			health_bar.color = Color.YELLOW
		else:
			health_bar.color = Color.RED

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
	
	# Update animations based on movement
	update_animations()

func handle_movement(delta):
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
	# Primary attack
	if Input.is_action_just_pressed("primary_attack"):
		primary_attack()
	
	# Special ability
	if Input.is_action_just_pressed("special_ability"):
		special_ability()
	
	# Ultimate ability
	if Input.is_action_just_pressed("ultimate_ability"):
		ultimate_ability()
	
	# Dodge roll
	if Input.is_action_just_pressed("dodge_roll"):
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
	# Check for character-specific primary attack cooldowns
	if primary_attack_timer > 0:
		match character_data.name:
			"Wizard":
				print("🔥 Wizard primary attack on cooldown: ", primary_attack_timer)
				return
			"Berserker":
				print("⚔️ Berserker primary attack on cooldown: ", primary_attack_timer)
				return
			_:
				# Knight and Huntress have no primary attack cooldown
				pass
	
	print("Primary attack: ", character_data.primary_attack_type)
	
	# Play attack animation
	play_attack_animation()
	
	# Get cursor position for directional attack
	var cursor_pos = get_global_mouse_position()
	var attack_direction = (cursor_pos - global_position).normalized()
	
	# Update facing direction to cursor direction
	facing_direction = attack_direction
	
	# Set character-specific primary attack cooldowns and damage
	var attack_damage = 25.0 * damage_multiplier  # Base damage
	
	match character_data.name:
		"Wizard":
			primary_attack_timer = 1.0  # 1 second cooldown for wizard
			print("🔥 Wizard primary attack cooldown set: 1.0 seconds")
		"Berserker":
			primary_attack_timer = 1.2  # 1.2 second cooldown for berserker (slower but powerful)
			attack_damage = 40.0 * damage_multiplier  # Higher damage for berserker
			print("⚔️ Berserker powerful strike cooldown set: 1.2 seconds")
		"Knight":
			# Knight has no cooldown but lower damage (quick slashes)
			attack_damage = 18.0 * damage_multiplier  # Lower damage for knight
			print("🗡️ Knight quick slash - no cooldown")
		"Huntress":
			# Huntress has no cooldown for primary attack (already differentiated in special)
			print("🏹 Huntress quick shot - no cooldown")
	
	# Play attack sound
	ability_used.emit("primary_attack")
	
	# Call Main.gd attack handler with directional attack
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node:
		main_node.handle_player_directional_attack(character_data.primary_attack_type, global_position, 80.0, attack_damage, attack_direction)

func special_ability():
	if special_ability_timer > 0:
		print("Special ability on cooldown: ", special_ability_timer)
		return
	
	print("Special ability: ", character_data.special_ability_name)
	
	# Play special animation
	play_special_animation()
	
	# Character-specific special abilities
	match character_data.name:
		"Wizard":
			# Wizard: Powerful magical attack, slower firing rate
			perform_wizard_special_attack()
			special_ability_timer = 1.5  # 1.5 second cooldown for wizard (slower but powerful)
			print("🔥 Wizard special attack cooldown: 1.5 seconds")
		"Huntress":
			# Huntress: Quick arrow attack, faster firing rate
			perform_huntress_special_attack()
			special_ability_timer = 0.8  # 0.8 second cooldown for huntress (faster but weaker)
			print("🏹 Huntress special attack cooldown: 0.8 seconds")
		_:
			# Default behavior for melee characters
			special_ability_timer = 2.0  # Default cooldown
			print("⚔️ Default special attack cooldown: 2.0 seconds")
	
	# Play ability sound
	ability_used.emit("special_ability")

func ultimate_ability():
	if ultimate_ability_timer > 0:
		print("Ultimate ability on cooldown: ", ultimate_ability_timer)
		return
	
	print("Ultimate ability: ", character_data.ultimate_ability_name)
	
	# Play ultimate animation
	play_ultimate_animation()
	
	# Set cooldown
	ultimate_ability_timer = 15.0  # 15 second cooldown
	
	# Play ability sound
	ability_used.emit("ultimate_ability")

func dodge_roll():
	if dodge_roll_cooldown_timer > 0:
		print("Dodge roll on cooldown: ", dodge_roll_cooldown_timer)
		return
	
	print("Dodge roll")
	
	# Play dodge animation
	play_dodge_animation()
	
	# Set dodge roll state
	is_dodge_rolling = true
	dodge_roll_timer = 0.3  # 0.3 second duration
	dodge_roll_cooldown_timer = 1.0  # 1 second cooldown
	
	# Enable invincibility frames during dodge
	is_invincible = true
	
	# Set direction (use facing direction or movement direction)
	dodge_roll_direction = facing_direction
	if dodge_roll_direction == Vector2.ZERO:
		dodge_roll_direction = Vector2.RIGHT
	
	# Create custom dodge effect
	create_dodge_effect()
	
	# Apply visual feedback for invincibility
	start_invincibility_visual_feedback()
	
	# Play dodge sound
	ability_used.emit("dodge_roll")

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
		invincibility_tween.set_loops()  # Loop indefinitely
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
	# Wizard shoots powerful magical projectiles
	var cursor_pos = get_global_mouse_position()
	var attack_direction = (cursor_pos - global_position).normalized()
	
	# Update facing direction
	facing_direction = attack_direction
	
	# Call Main.gd attack handler for ranged attack
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node:
		# Use higher damage for wizard's special attack
		var special_damage = 45.0 * damage_multiplier
		main_node.handle_ranged_attack(global_position, special_damage, attack_direction)
	
	print("Wizard special attack: Fireball launched!")

func perform_huntress_special_attack():
	# Huntress shoots rapid arrows
	var cursor_pos = get_global_mouse_position()
	var attack_direction = (cursor_pos - global_position).normalized()
	
	# Update facing direction
	facing_direction = attack_direction
	
	# Call Main.gd attack handler for ranged attack
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node:
		# Use moderate damage for huntress's special attack
		var special_damage = 25.0 * damage_multiplier
		main_node.handle_ranged_attack(global_position, special_damage, attack_direction)
	
	print("Huntress special attack: Arrow fired!")

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
	
	# Check if dead
	if current_health <= 0:
		die()
	
	print("Player took ", final_damage, " damage. Health: ", current_health)

func die():
	is_alive = false
	print("Player died")
	
	# Play death animation
	play_death_animation()
	
	character_died.emit()

func get_character_type() -> String:
	if character_data:
		return character_data.name
	return "Unknown" 
