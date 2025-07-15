extends Control

# Node references
@onready var start_button: Button = $VBoxContainer/ButtonContainer/StartButton
@onready var options_button: Button = $VBoxContainer/ButtonContainer/OptionsButton
@onready var quit_button: Button = $VBoxContainer/ButtonContainer/QuitButton
@onready var title_label: Label = $VBoxContainer/TitleLabel

# Signals
signal start_game()
signal show_options()
signal quit_game()

func _ready():
	print("=== Main Menu ===")
	setup_ui_connections()
	
	# Set focus to start button
	if start_button:
		start_button.grab_focus()

func setup_ui_connections():
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	
	if options_button:
		options_button.pressed.connect(_on_options_button_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	print("Start button pressed - proceeding to character selection")
	start_game.emit()

func _on_options_button_pressed():
	print("Options button pressed")
	show_options.emit()

func _on_quit_button_pressed():
	print("Quit button pressed")
	quit_game.emit()

func _input(event):
	# Handle ESC key to quit
	if event.is_action_pressed("ui_cancel"):
		_on_quit_button_pressed() 