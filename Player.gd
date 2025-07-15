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

# Dodge roll system
var dodge_roll_timer: float = 0.0
var dodge_roll_cooldown_timer: float = 0.0
var dodge_roll_direction: Vector2 = Vector2.ZERO
var is_dodge_rolling: bool = false

# Player state
var facing_direction: Vector2 = Vector2.RIGHT
var is_alive: bool = true

# Custom effects
var dodge_effect_sprite: AnimatedSprite2D = null

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
	
	configure_character()
	create_health_bar()
	setup_dodge_effect()
	
	print("Player created: ", character_data.name)

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
	# Knight uses sprite sheets
	
	# Setup idle animation (8 frames)
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_speed("idle", 8.0)
	sprite_frames.set_animation_loop("idle", true)
	
	var idle_sheet = load("res://assets/characters/knight/Sprites/Idle.png")
	if idle_sheet:
		var frame_width = idle_sheet.get_width() / 8
		var frame_height = idle_sheet.get_height()
		for i in range(8):
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = idle_sheet
			atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("idle", atlas_tex)
		print("Split idle animation for Knight")
	
	# Setup attack animation (6 frames)
	sprite_frames.add_animation("attack")
	sprite_frames.set_animation_speed("attack", 12.0)
	sprite_frames.set_animation_loop("attack", false)
	
	var attack_sheet = load("res://assets/characters/knight/Sprites/Attack.png")
	if attack_sheet:
		var frame_width = attack_sheet.get_width() / 6
		var frame_height = attack_sheet.get_height()
		for i in range(6):
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = attack_sheet
			atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("attack", atlas_tex)
		print("Split attack animation for Knight")
	
	# Setup run animation (8 frames)
	sprite_frames.add_animation("run")
	sprite_frames.set_animation_speed("run", 10.0)
	sprite_frames.set_animation_loop("run", true)
	
	var run_sheet = load("res://assets/characters/knight/Sprites/Run.png")
	if run_sheet:
		var frame_width = run_sheet.get_width() / 8
		var frame_height = run_sheet.get_height()
		for i in range(8):
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = run_sheet
			atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("run", atlas_tex)
		print("Split run animation for Knight")

func setup_berserker_animations(sprite_frames: SpriteFrames):
	# Berserker uses custom sprite sheets
	
	# Setup idle animation (8 frames)
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_speed("idle", 8.0)
	sprite_frames.set_animation_loop("idle", true)
	
	var idle_sheet = load("res://assets/characters/berserker/Sprites/Idle.png")
	if idle_sheet:
		var frame_width = idle_sheet.get_width() / 8
		var frame_height = idle_sheet.get_height()
		for i in range(8):
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = idle_sheet
			atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("idle", atlas_tex)
		print("Split idle animation for Berserker")
	
	# Setup attack animation (6 frames)
	sprite_frames.add_animation("attack")
	sprite_frames.set_animation_speed("attack", 12.0)
	sprite_frames.set_animation_loop("attack", false)
	
	var attack_sheet = load("res://assets/characters/berserker/Sprites/Attack.png")
	if attack_sheet:
		var frame_width = attack_sheet.get_width() / 6
		var frame_height = attack_sheet.get_height()
		for i in range(6):
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = attack_sheet
			atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("attack", atlas_tex)
		print("Split attack animation for Berserker")
	
	# Setup run animation (8 frames)
	sprite_frames.add_animation("run")
	sprite_frames.set_animation_speed("run", 10.0)
	sprite_frames.set_animation_loop("run", true)
	
	var run_sheet = load("res://assets/characters/berserker/Sprites/Run.png")
	if run_sheet:
		var frame_width = run_sheet.get_width() / 8
		var frame_height = run_sheet.get_height()
		for i in range(8):
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = run_sheet
			atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("run", atlas_tex)
		print("Split run animation for Berserker")

func setup_huntress_animations(sprite_frames: SpriteFrames):
	# Huntress uses custom sprite sheets
	
	# Setup idle animation (8 frames)
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_speed("idle", 8.0)
	sprite_frames.set_animation_loop("idle", true)
	
	var idle_sheet = load("res://assets/characters/huntress/Sprites/Idle.png")
	if idle_sheet:
		var frame_width = idle_sheet.get_width() / 8
		var frame_height = idle_sheet.get_height()
		for i in range(8):
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = idle_sheet
			atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("idle", atlas_tex)
		print("Split idle animation for Huntress")
	
	# Setup attack animation (6 frames)
	sprite_frames.add_animation("attack")
	sprite_frames.set_animation_speed("attack", 12.0)
	sprite_frames.set_animation_loop("attack", false)
	
	var attack_sheet = load("res://assets/characters/huntress/Sprites/Attack.png")
	if attack_sheet:
		var frame_width = attack_sheet.get_width() / 6
		var frame_height = attack_sheet.get_height()
		for i in range(6):
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = attack_sheet
			atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("attack", atlas_tex)
		print("Split attack animation for Huntress")
	
	# Setup run animation (8 frames)
	sprite_frames.add_animation("run")
	sprite_frames.set_animation_speed("run", 10.0)
	sprite_frames.set_animation_loop("run", true)
	
	var run_sheet = load("res://assets/characters/huntress/Sprites/Run.png")
	if run_sheet:
		var frame_width = run_sheet.get_width() / 8
		var frame_height = run_sheet.get_height()
		for i in range(8):
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = run_sheet
			atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("run", atlas_tex)
		print("Split run animation for Huntress")

func setup_wizard_animations(sprite_frames: SpriteFrames):
	# Wizard uses custom sprite sheets
	
	# Setup idle animation (8 frames)
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_speed("idle", 8.0)
	sprite_frames.set_animation_loop("idle", true)
	
	var idle_sheet = load("res://assets/characters/wizard/Sprites/Idle.png")
	if idle_sheet:
		var frame_width = idle_sheet.get_width() / 8
		var frame_height = idle_sheet.get_height()
		for i in range(8):
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = idle_sheet
			atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("idle", atlas_tex)
		print("Split idle animation for Wizard")
	
	# Setup attack animation (6 frames)
	sprite_frames.add_animation("attack")
	sprite_frames.set_animation_speed("attack", 12.0)
	sprite_frames.set_animation_loop("attack", false)
	
	var attack_sheet = load("res://assets/characters/wizard/Sprites/Attack.png")
	if attack_sheet:
		var frame_width = attack_sheet.get_width() / 6
		var frame_height = attack_sheet.get_height()
		for i in range(6):
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = attack_sheet
			atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("attack", atlas_tex)
		print("Split attack animation for Wizard")
	
	# Setup run animation (8 frames)
	sprite_frames.add_animation("run")
	sprite_frames.set_animation_speed("run", 10.0)
	sprite_frames.set_animation_loop("run", true)
	
	var run_sheet = load("res://assets/characters/wizard/Sprites/Run.png")
	if run_sheet:
		var frame_width = run_sheet.get_width() / 8
		var frame_height = run_sheet.get_height()
		for i in range(8):
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = run_sheet
			atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("run", atlas_tex)
		print("Split run animation for Wizard")

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
		print("Dodge roll ended")

func update_timers(delta):
	# Update ability cooldowns
	if special_ability_timer > 0:
		special_ability_timer -= delta
	if ultimate_ability_timer > 0:
		ultimate_ability_timer -= delta
	if dodge_roll_cooldown_timer > 0:
		dodge_roll_cooldown_timer -= delta

func update_animations():
	# Update character animations based on current state
	if not animated_sprite:
		return
	
	# Don't change animation if attacking
	if animated_sprite.animation == "attack" and animated_sprite.is_playing():
		return
	
	# Set animation based on movement
	if velocity.length() > 10:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
	
	# Flip sprite based on direction
	if facing_direction.x < 0:
		animated_sprite.flip_h = true
	elif facing_direction.x > 0:
		animated_sprite.flip_h = false

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
	print("Primary attack: ", character_data.primary_attack_type)
	
	# Play attack animation
	if animated_sprite:
		animated_sprite.play("attack")
	
	# Get cursor position for directional attack
	var cursor_pos = get_global_mouse_position()
	var attack_direction = (cursor_pos - global_position).normalized()
	
	# Update facing direction to cursor direction
	facing_direction = attack_direction
	
	# Play attack sound
	ability_used.emit("primary_attack")
	
	# Call Main.gd attack handler with directional attack
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node:
		main_node.handle_player_directional_attack(character_data.primary_attack_type, global_position, 80.0, 25.0, attack_direction)

func special_ability():
	if special_ability_timer > 0:
		print("Special ability on cooldown: ", special_ability_timer)
		return
	
	print("Special ability: ", character_data.special_ability_name)
	
	# Play attack animation
	if animated_sprite:
		animated_sprite.play("attack")
	
	# Set cooldown
	special_ability_timer = 5.0  # 5 second cooldown
	
	# Play ability sound
	ability_used.emit("special_ability")

func ultimate_ability():
	if ultimate_ability_timer > 0:
		print("Ultimate ability on cooldown: ", ultimate_ability_timer)
		return
	
	print("Ultimate ability: ", character_data.ultimate_ability_name)
	
	# Play attack animation
	if animated_sprite:
		animated_sprite.play("attack")
	
	# Set cooldown
	ultimate_ability_timer = 15.0  # 15 second cooldown
	
	# Play ability sound
	ability_used.emit("ultimate_ability")

func dodge_roll():
	if dodge_roll_cooldown_timer > 0:
		print("Dodge roll on cooldown: ", dodge_roll_cooldown_timer)
		return
	
	print("Dodge roll")
	
	# Set dodge roll state
	is_dodge_rolling = true
	dodge_roll_timer = 0.3  # 0.3 second duration
	dodge_roll_cooldown_timer = 1.0  # 1 second cooldown
	
	# Set direction (use facing direction or movement direction)
	dodge_roll_direction = facing_direction
	if dodge_roll_direction == Vector2.ZERO:
		dodge_roll_direction = Vector2.RIGHT
	
	# Create custom dodge effect
	create_dodge_effect()
	
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

func take_damage(damage: float):
	if not is_alive:
		return
	
	# Apply armor reduction
	var final_damage = damage * (1.0 - armor_reduction)
	current_health -= final_damage
	
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
	character_died.emit()
	
	# TODO: Add death animation/VFX 