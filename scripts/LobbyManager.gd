extends Control

# Node references
@onready var host_button: Button = $VBoxContainer/HostJoinContainer/HostButton
@onready var join_button: Button = $VBoxContainer/HostJoinContainer/JoinButton
@onready var join_code_input: LineEdit = $VBoxContainer/JoinCodeContainer/JoinCodeInput
@onready var join_code_button: Button = $VBoxContainer/JoinCodeContainer/JoinCodeButtonContainer/JoinCodeButton
@onready var change_mode_button: Button = $VBoxContainer/JoinCodeContainer/JoinCodeButtonContainer/ChangeModeButton
@onready var lobby_code_label: Label = $VBoxContainer/LobbyInfoContainer/LobbyCodeLabel
@onready var players_label: Label = $VBoxContainer/LobbyInfoContainer/PlayersLabel
@onready var players_list: VBoxContainer = $VBoxContainer/LobbyInfoContainer/PlayersList
@onready var start_button: Button = $VBoxContainer/ButtonContainer/StartButton
@onready var back_button: Button = $VBoxContainer/ButtonContainer/BackButton
@onready var status_label: Label = $VBoxContainer/StatusLabel

# Containers for better UI management
@onready var host_join_container: HBoxContainer = $VBoxContainer/HostJoinContainer
@onready var join_code_container: VBoxContainer = $VBoxContainer/JoinCodeContainer
@onready var lobby_info_container: VBoxContainer = $VBoxContainer/LobbyInfoContainer

# Signals
signal start_game_pressed()
signal back_pressed()

# State
var is_host: bool = false
var is_in_lobby: bool = false
var network_manager: NetworkManager

func _ready():
	print("=== Lobby Manager ===")
	setup_ui_connections()
	
	# Get network manager reference from GameManager
	network_manager = get_node("/root/GameManager").network_manager
	
	# Connect network signals
	if network_manager:
		network_manager.lobby_created.connect(_on_lobby_created)
		network_manager.lobby_joined.connect(_on_lobby_joined)
		network_manager.player_connected.connect(_on_player_connected)
		network_manager.player_disconnected.connect(_on_player_disconnected)
	
	# Set initial UI state
	_reset_to_initial_state()
	
	# Set initial focus
	if host_button:
		host_button.grab_focus()

func setup_ui_connections():
	if host_button:
		host_button.pressed.connect(_on_host_pressed)
	
	if join_button:
		join_button.pressed.connect(_on_join_pressed)
	
	if join_code_button:
		join_code_button.pressed.connect(_on_join_code_pressed)
	
	if change_mode_button:
		change_mode_button.pressed.connect(_on_change_mode_pressed)
	
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	if join_code_input:
		join_code_input.text_submitted.connect(_on_join_code_submitted)

func _on_host_pressed():
	print("Host lobby pressed")
	if network_manager:
		var code = network_manager.create_lobby()
		if code != "":
			is_host = true
			is_in_lobby = true
			_update_lobby_ui()

func _on_join_pressed():
	print("Join lobby pressed")
	# Switch to join code input mode
	_show_join_code_input()

func _on_join_code_pressed():
	var code = join_code_input.text.strip_edges()
	if code.length() == 6 and code.is_valid_int():
		print("Attempting to join lobby: ", code)
		if network_manager:
			network_manager.join_lobby(code)
	else:
		status_label.text = "Invalid lobby code format"

func _on_join_code_submitted(_text: String):
	_on_join_code_pressed()

func _on_change_mode_pressed():
	print("Change mode pressed - returning to host/join selection")
	_reset_to_initial_state()

func _on_start_pressed():
	print("Start game pressed")
	if is_host and network_manager:
		network_manager.start_character_select.rpc()

func _on_back_pressed():
	print("Back pressed")
	if network_manager:
		network_manager.disconnect_from_lobby()
	back_pressed.emit()

# Network event handlers
func _on_lobby_created(code: String):
	print("Lobby created with code: ", code)
	lobby_code_label.text = "Lobby Code: " + code
	status_label.text = "Lobby created! Share code with friends."
	_update_lobby_ui()

func _on_lobby_joined(success: bool):
	if success:
		print("Successfully joined lobby")
		status_label.text = "Connected to lobby!"
		is_host = false
		is_in_lobby = true
		_update_lobby_ui()
	else:
		print("Failed to join lobby")
		status_label.text = "Failed to join lobby. Check the code."
		# Stay in join code input mode for retry

func _on_player_connected(id: int, player_name: String):
	print("Player connected: ", player_name)
	_update_players_list()

func _on_player_disconnected(id: int):
	print("Player disconnected: ", id)
	_update_players_list()

# UI helper functions
func _reset_to_initial_state():
	print("Resetting lobby UI to initial state")
	# Show host/join selection
	host_join_container.visible = true
	host_button.visible = true
	join_button.visible = true
	
	# Hide other UI elements
	join_code_container.visible = false
	lobby_info_container.visible = false
	
	# Reset state
	is_host = false
	is_in_lobby = false
	
	# Clear status
	status_label.text = ""
	
	# Set focus to host button
	host_button.grab_focus()

func _show_join_code_input():
	print("Showing join code input")
	# Hide host/join buttons
	host_join_container.visible = false
	
	# Show join code input
	join_code_container.visible = true
	join_code_input.visible = true
	join_code_button.visible = true
	change_mode_button.visible = true
	
	# Hide lobby info
	lobby_info_container.visible = false
	
	# Clear and focus input
	join_code_input.text = ""
	join_code_input.grab_focus()
	status_label.text = "Enter the 6-digit lobby code to join"

func _update_lobby_ui():
	print("Updating lobby UI - In lobby: ", is_in_lobby, ", Is host: ", is_host)
	# Hide host/join selection and join code input
	host_join_container.visible = false
	join_code_container.visible = false
	
	# Show lobby info
	lobby_info_container.visible = true
	lobby_code_label.visible = true
	players_label.visible = true
	players_list.visible = true
	
	# Enable start button for host only
	start_button.disabled = not is_host
	
	_update_players_list()

func _update_players_list():
	# Clear existing player labels
	for child in players_list.get_children():
		child.queue_free()
	
	if network_manager:
		var connected_players = network_manager.get_connected_players()
		players_label.text = "Players: " + str(connected_players.size()) + "/4"
		
		# Add player labels
		for player_id in connected_players:
			var player_data = connected_players[player_id]
			var player_label = Label.new()
			player_label.text = player_data["name"] + " (Ready: " + str(player_data["ready"]) + ")"
			player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			players_list.add_child(player_label)

func _input(event):
	# Handle ESC key to go back
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
