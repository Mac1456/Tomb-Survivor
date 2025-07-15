extends Control

# Character selection state
var selected_character_index: int = 0
var is_character_selected: bool = false

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
	sprite_frames.set_animation_speed("idle", 6.0)  # Slower for character selection
	sprite_frames.set_animation_loop("idle", true)
	
	match character_name:
		"Knight":
			# Knight uses sprite sheet - split into 8 frames (32x32 each)
			var idle_sheet = load("res://assets/characters/knight/Sprites/Idle.png")
			if idle_sheet:
				var frame_width = idle_sheet.get_width() / 8
				var frame_height = idle_sheet.get_height()
				for i in range(8):
					var atlas_tex = AtlasTexture.new()
					atlas_tex.atlas = idle_sheet
					atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
					sprite_frames.add_frame("idle", atlas_tex)
			print("Loaded and split animated sprite for Knight")
		"Berserker":
			# Berserker uses sprite sheet - split into 8 frames (32x32 each)
			var idle_sheet = load("res://assets/characters/berserker/Sprites/Idle.png")
			if idle_sheet:
				var frame_width = idle_sheet.get_width() / 8
				var frame_height = idle_sheet.get_height()
				for i in range(8):
					var atlas_tex = AtlasTexture.new()
					atlas_tex.atlas = idle_sheet
					atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
					sprite_frames.add_frame("idle", atlas_tex)
			print("Loaded and split animated sprite for Berserker")
		"Huntress":
			# Huntress uses sprite sheet - split into 8 frames (32x32 each)
			var idle_sheet = load("res://assets/characters/huntress/Sprites/Idle.png")
			if idle_sheet:
				var frame_width = idle_sheet.get_width() / 8
				var frame_height = idle_sheet.get_height()
				for i in range(8):
					var atlas_tex = AtlasTexture.new()
					atlas_tex.atlas = idle_sheet
					atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
					sprite_frames.add_frame("idle", atlas_tex)
			print("Loaded and split animated sprite for Huntress")
		"Wizard":
			# Wizard uses sprite sheet - split into 8 frames (32x32 each)
			var idle_sheet = load("res://assets/characters/wizard/Sprites/Idle.png")
			if idle_sheet:
				var frame_width = idle_sheet.get_width() / 8
				var frame_height = idle_sheet.get_height()
				for i in range(8):
					var atlas_tex = AtlasTexture.new()
					atlas_tex.atlas = idle_sheet
					atlas_tex.region = Rect2(i * frame_width, 0, frame_width, frame_height)
					sprite_frames.add_frame("idle", atlas_tex)
			print("Loaded and split animated sprite for Wizard")
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
	
	# Update character info labels
	character_name_label.text = character.name
	character_description_label.text = character.description
	
	# Stats display
	stats_label.text = "STR:%d SPD:%d ARM:%d HP:%d" % [character.strength, character.speed, character.armor, character.health]
	
	# Abilities
	primary_attack_label.text = "Primary Attack: " + character.primary_attack_type.capitalize()
	special_ability_label.text = "Special: " + character.special_ability_name + " - " + character.special_ability_description
	ultimate_ability_label.text = "Ultimate: " + character.ultimate_ability_name + " - " + character.ultimate_ability_description

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
