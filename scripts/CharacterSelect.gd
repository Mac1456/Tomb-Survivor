extends Control

# Character selection state
var selected_character_index: int = 0
var is_character_selected: bool = false

# Multiplayer state
var is_multiplayer_mode: bool = false
var network_manager: NetworkManager = null
var multiplayer_players: Dictionary = {}  # player_id -> {name, character_index, ready}

# Node references
@onready var character_grid: GridContainer = $VBoxContainer/MainContainer/LeftSide/CharacterGrid
@onready var character_name_label: Label = $VBoxContainer/MainContainer/RightSide/CharacterInfo/NameLabel
@onready var character_description_label: Label = $VBoxContainer/MainContainer/RightSide/CharacterInfo/DescriptionLabel
@onready var stats_label: Label = $VBoxContainer/MainContainer/RightSide/CharacterInfo/StatsLabel
@onready var primary_attack_label: Label = $VBoxContainer/MainContainer/RightSide/CharacterInfo/PrimaryAttackLabel
@onready var special_ability_label: Label = $VBoxContainer/MainContainer/RightSide/CharacterInfo/SpecialAbilityLabel
@onready var ultimate_ability_label: Label = $VBoxContainer/MainContainer/RightSide/CharacterInfo/UltimateAbilityLabel
@onready var ready_button: Button = $VBoxContainer/ButtonContainer/ReadyButton
@onready var back_button: Button = $VBoxContainer/ButtonContainer/BackButton

# Character selection buttons
var character_buttons: Array = []
var character_sprites: Array = []  # Store animated sprites for each character

# Signals
signal character_selected(character_index: int)
signal ready_pressed(character_index: int)
signal back_pressed()

func _ready():
	print("=== Character Selection Screen - Medieval Fantasy ===")
	setup_character_grid()
	setup_ui_connections()
	update_character_info()

func setup_character_grid():
	# Clear existing children
	for child in character_grid.get_children():
		child.queue_free()
	
	character_buttons.clear()
	character_sprites.clear()
	
	# Set grid to 2x2 for 4 characters with better spacing
	character_grid.columns = 2
	character_grid.add_theme_constant_override("h_separation", 20)
	character_grid.add_theme_constant_override("v_separation", 20)
	
	# Create character selection buttons
	for i in range(CharacterData.get_character_count()):
		var character = CharacterData.get_character(i)
		var button = create_character_button(character, i)
		character_grid.add_child(button)
		character_buttons.append(button)
	
	# Select first character by default
	if character_buttons.size() > 0:
		select_character(0)

func create_character_button(character: CharacterData.Character, index: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 180)  # Larger for better visibility
	button.flat = false
	
	# Create button content
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 5)
	
	# Character animated sprite preview
	var preview_container = Control.new()
	preview_container.custom_minimum_size = Vector2(80, 80)
	preview_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var animated_sprite = AnimatedSprite2D.new()
	var sprite_frames = create_character_sprite_frames(character.name)
	if sprite_frames:
		animated_sprite.sprite_frames = sprite_frames
		animated_sprite.play("idle")
		
		# Adjust scale and position based on character to fit preview
		match character.name:
			"Knight":
				animated_sprite.scale = Vector2(2.0, 2.0)
				animated_sprite.position = Vector2(40, 45)
			"Berserker":
				animated_sprite.scale = Vector2(2.0, 2.0)
				animated_sprite.position = Vector2(40, 45)
			"Huntress":
				animated_sprite.scale = Vector2(2.0, 2.0)
				animated_sprite.position = Vector2(40, 40)
			"Wizard":
				animated_sprite.scale = Vector2(1.8, 1.8)
				animated_sprite.position = Vector2(40, 50)
		
		preview_container.add_child(animated_sprite)
		character_sprites.append(animated_sprite)
	else:
		# Fallback to colored rectangle
		var fallback_sprite = ColorRect.new()
		fallback_sprite.size = Vector2(60, 60)
		fallback_sprite.position = Vector2(10, 10)
		fallback_sprite.color = get_character_fallback_color(character.name)
		preview_container.add_child(fallback_sprite)
	
	vbox.add_child(preview_container)
	
	# Character name
	var name_label = Label.new()
	name_label.text = character.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)
	
	# Character class/type
	var class_label = Label.new()
	class_label.text = get_character_class(character.name)
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_label.modulate = Color(0.8, 0.8, 0.8, 1.0)
	class_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	class_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(class_label)
	
	button.add_child(vbox)
	
	# Connect button signal
	button.pressed.connect(_on_character_button_pressed.bind(index))
	
	return button

func create_character_sprite_frames(character_name: String) -> SpriteFrames:
	var sprite_frames = SpriteFrames.new()
	
	# Create idle animation
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_speed("idle", 8.0)  # Match game speed for visibility
	sprite_frames.set_animation_loop("idle", true)
	
	match character_name:
		"Knight":
			# Knight uses new multi-frame SVG sprites
			for i in range(1, 5):  # 4 frames
				var idle_texture = load("res://assets/characters/knight/sprites/knight_idle_%02d.svg" % i)
				if idle_texture:
					sprite_frames.add_frame("idle", idle_texture)
			print("Loaded Knight multi-frame SVG sprite for character selection")
		"Berserker":
			# Berserker uses new multi-frame SVG sprites
			for i in range(1, 5):  # 4 frames
				var idle_texture = load("res://assets/characters/berserker/Sprites/berserker_idle_%02d.svg" % i)
				if idle_texture:
					sprite_frames.add_frame("idle", idle_texture)
			print("Loaded Berserker multi-frame SVG sprite for character selection")
		"Huntress":
			# Huntress uses new multi-frame SVG sprites
			for i in range(1, 5):  # 4 frames
				var idle_texture = load("res://assets/characters/huntress/Sprites/huntress_idle_%02d.svg" % i)
				if idle_texture:
					sprite_frames.add_frame("idle", idle_texture)
			print("Loaded Huntress multi-frame SVG sprite for character selection")
		"Wizard":
			# Wizard uses new multi-frame SVG sprites
			for i in range(1, 5):  # 4 frames
				var idle_texture = load("res://assets/characters/wizard/sprites/wizard_idle_%02d.svg" % i)
				if idle_texture:
					sprite_frames.add_frame("idle", idle_texture)
			print("Loaded Wizard multi-frame SVG sprite for character selection")
		_:
			print("Unknown character: ", character_name)
			return null
	
	return sprite_frames

func load_character_sprite(character_name: String) -> Texture2D:
	# Fallback function - still kept for compatibility
	var sprite_path: String = ""
	
	match character_name:
		"Knight":
			sprite_path = "res://assets/characters/knight/Sprites/Idle.png"
		"Berserker":
			sprite_path = "res://assets/characters/berserker/Sprites/Idle.png"
		"Huntress":
			sprite_path = "res://assets/characters/huntress/Sprites/Idle.png"
		"Wizard":
			sprite_path = "res://assets/characters/wizard/Sprites/Idle.png"
		_:
			return null
	
	var texture = load(sprite_path)
	if texture:
		print("Loaded sprite for ", character_name, ": ", sprite_path)
		return texture
	else:
		print("Failed to load sprite for ", character_name, ": ", sprite_path)
		return null

func get_character_fallback_color(character_name: String) -> Color:
	# Fallback colors for characters if sprites fail to load
	match character_name:
		"Knight": return Color(0.4, 0.4, 0.8, 1.0)  # Blue
		"Berserker": return Color(0.9, 0.2, 0.1, 1.0)  # Red
		"Huntress": return Color(0.1, 0.7, 0.1, 1.0)  # Green
		"Wizard": return Color(0.5, 0.1, 0.8, 1.0)  # Purple
		_: return Color.WHITE

func get_character_class(character_name: String) -> String:
	# Return character class names for display
	match character_name:
		"Knight": return "Swordsman"
		"Berserker": return "Berserker"
		"Huntress": return "Ranger"
		"Wizard": return "Mage"
		_: return "Unknown"

func setup_ui_connections():
	# Connect button signals
	ready_button.pressed.connect(_on_ready_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Disable ready button initially
	ready_button.disabled = not is_character_selected

func _on_character_button_pressed(index: int):
	print("Character button pressed: ", index)
	select_character(index)

func select_character(index: int):
	if index < 0 or index >= CharacterData.get_character_count():
		return
	
	# Update selection state
	selected_character_index = index
	is_character_selected = true
	
	# Update button states
	for i in range(character_buttons.size()):
		if i == index:
			character_buttons[i].modulate = Color(1.2, 1.2, 0.8, 1.0)  # Highlight selected
		else:
			character_buttons[i].modulate = Color.WHITE
	
	# Update character info
	update_character_info()
	
	# Enable ready button
	ready_button.disabled = false
	
	# Emit signal
	character_selected.emit(index)
	
	print("Character selected: ", index)

func update_character_info():
	if selected_character_index < 0 or selected_character_index >= CharacterData.get_character_count():
		return
	
	var character = CharacterData.get_character(selected_character_index)
	
	# Update character info labels with enhanced formatting
	character_name_label.text = character.name
	character_description_label.text = character.description
	
	# Enhanced stats display with descriptions
	stats_label.text = create_enhanced_stats_text(character)
	
	# Enhanced abilities display with key bindings
	primary_attack_label.text = create_ability_text("Left Click", "Primary Attack", "Standard combat attack")
	special_ability_label.text = create_ability_text("Right Click", character.special_ability_name, character.special_ability_description)
	ultimate_ability_label.text = create_ability_text("R", character.ultimate_ability_name, character.ultimate_ability_description)

func _on_ready_button_pressed():
	if is_character_selected:
		print("Ready button pressed with character: ", CharacterData.get_character(selected_character_index).name)
		ready_pressed.emit(selected_character_index)
	else:
		print("No character selected")

func _on_back_button_pressed():
	print("Back button pressed")
	back_pressed.emit()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
	elif event.is_action_pressed("ui_accept"):
		if is_character_selected:
			_on_ready_button_pressed()

func _exit_tree():
	# Clean up animated sprites
	for sprite in character_sprites:
		if sprite:
			sprite.queue_free()
	character_sprites.clear()

# Enhanced character info display functions
func create_enhanced_stats_text(character: CharacterData.Character) -> String:
	var stats_text = ""
	stats_text += "Strength: %d\n" % character.strength
	stats_text += "Speed: %d\n" % character.speed
	stats_text += "Armor: %d\n" % character.armor
	stats_text += "Health: %d" % character.health
	return stats_text

func create_ability_text(key_binding: String, ability_name: String, description: String) -> String:
	return "[%s] %s\n%s" % [key_binding, ability_name, description]

# Multiplayer functionality
func set_multiplayer_mode(is_mp: bool, net_manager):
	is_multiplayer_mode = is_mp
	if is_mp and net_manager:
		network_manager = net_manager
		setup_multiplayer_connections()
		update_multiplayer_ui()

func setup_multiplayer_connections():
	if network_manager:
		network_manager.character_selection_updated.connect(_on_multiplayer_character_updated)
		network_manager.player_connected.connect(_on_multiplayer_player_connected)
		network_manager.player_disconnected.connect(_on_multiplayer_player_disconnected)

func update_multiplayer_ui():
	if is_multiplayer_mode:
		# Update ready button text for multiplayer
		ready_button.text = "Ready!"
		# Could add multiplayer player list here if needed

func _on_multiplayer_character_updated(player_id: int, character_index: int):
	print("Player ", player_id, " selected character ", character_index)
	# Update visual indicators for other players' selections

func _on_multiplayer_player_connected(player_id: int, player_name: String):
	print("Player connected to character select: ", player_name)

func _on_multiplayer_player_disconnected(player_id: int):
	print("Player disconnected from character select: ", player_id) 
