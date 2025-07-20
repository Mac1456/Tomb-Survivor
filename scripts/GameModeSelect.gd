extends Control

# Node references
@onready var single_player_button: Button = $VBoxContainer/ButtonContainer/SinglePlayerButton
@onready var multiplayer_button: Button = $VBoxContainer/ButtonContainer/MultiplayerButton
@onready var back_button: Button = $VBoxContainer/BackButton

# Signals
signal single_player_selected()
signal multiplayer_selected()
signal back_pressed()

func _ready():
	print("=== Game Mode Select ===")
	setup_ui_connections()
	
	# Set focus to single player button
	if single_player_button:
		single_player_button.grab_focus()

func setup_ui_connections():
	if single_player_button:
		single_player_button.pressed.connect(_on_single_player_pressed)
	
	if multiplayer_button:
		multiplayer_button.pressed.connect(_on_multiplayer_pressed)
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _on_single_player_pressed():
	print("Single player selected")
	single_player_selected.emit()

func _on_multiplayer_pressed():
	print("Multiplayer selected")
	multiplayer_selected.emit()

func _on_back_pressed():
	print("Back pressed")
	back_pressed.emit()

func _input(event):
	# Handle ESC key to go back
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
