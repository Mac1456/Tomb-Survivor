extends Node

# Game states
enum GameState {
	MAIN_MENU,
	GAME_MODE_SELECT,
	LOBBY_MANAGER,
	CHARACTER_SELECT,
	GAME
}

# Current game state
var current_state: GameState = GameState.MAIN_MENU

# Selected character data
var selected_character: CharacterData.Character = null
var selected_character_index: int = 0

# Scene references
var main_menu_scene: PackedScene = preload("res://scenes/MainMenu.tscn")
var game_mode_select_scene: PackedScene = preload("res://scenes/GameModeSelect.tscn")
var lobby_scene: PackedScene = preload("res://scenes/LobbyManager.tscn")
var character_select_scene: PackedScene = preload("res://scenes/CharacterSelect.tscn")
var game_scene: PackedScene = preload("res://scenes/Main.tscn")

# Current scene instance
var current_scene: Node = null

# Networking
var network_manager: NetworkManager
var is_multiplayer_game: bool = false

func _ready():
	print("=== Game Manager - Multiplayer System ===")
	
	# Initialize network manager
	network_manager = NetworkManager.new()
	add_child(network_manager)
	
	# Connect network signals
	network_manager.lobby_created.connect(_on_lobby_created)
	network_manager.lobby_joined.connect(_on_lobby_joined)
	network_manager.character_selection_started.connect(_on_character_selection_started)
	network_manager.all_players_ready.connect(_on_all_players_ready)
	network_manager.multiplayer_game_ready.connect(_on_multiplayer_game_ready)
	
	# Start with main menu
	change_to_main_menu()

func change_to_main_menu():
	print("Changing to main menu")
	current_state = GameState.MAIN_MENU
	is_multiplayer_game = false
	
	# Disconnect from any network session
	if network_manager:
		network_manager.disconnect_from_lobby()
	
	# Clear current scene
	if current_scene:
		current_scene.queue_free()
	
	# Load main menu - FIX: Add to GameManager instead of current_scene
	current_scene = main_menu_scene.instantiate()
	add_child(current_scene)
	
	# Connect signals
	current_scene.start_game.connect(_on_main_menu_start_game)
	current_scene.show_options.connect(_on_main_menu_show_options)
	current_scene.quit_game.connect(_on_main_menu_quit_game)

func change_to_game_mode_select():
	print("Changing to game mode selection")
	current_state = GameState.GAME_MODE_SELECT
	
	# Clear current scene
	if current_scene:
		current_scene.queue_free()
	
	# Load game mode select - FIX: Add to GameManager instead of current_scene
	current_scene = game_mode_select_scene.instantiate()
	add_child(current_scene)
	
	# Connect signals
	current_scene.single_player_selected.connect(_on_single_player_selected)
	current_scene.multiplayer_selected.connect(_on_multiplayer_selected)
	current_scene.back_pressed.connect(_on_game_mode_back)

func change_to_lobby_manager():
	print("Changing to lobby manager")
	current_state = GameState.LOBBY_MANAGER
	is_multiplayer_game = true
	
	# Clear current scene
	if current_scene:
		current_scene.queue_free()
	
	# Load lobby manager - FIX: Add to GameManager instead of current_scene
	current_scene = lobby_scene.instantiate()
	add_child(current_scene)
	
	# Connect signals
	current_scene.back_pressed.connect(_on_lobby_back)

func change_to_character_select():
	print("Changing to character selection")
	current_state = GameState.CHARACTER_SELECT
	
	# Clear current scene
	if current_scene:
		current_scene.queue_free()
	
	# Load character select - FIX: Add to GameManager instead of current_scene
	current_scene = character_select_scene.instantiate()
	add_child(current_scene)
	
	# Set multiplayer mode if needed
	if is_multiplayer_game and current_scene.has_method("set_multiplayer_mode"):
		current_scene.set_multiplayer_mode(true, network_manager)
	
	# Connect signals
	current_scene.character_selected.connect(_on_character_selected)
	current_scene.ready_pressed.connect(_on_character_ready)
	current_scene.back_pressed.connect(_on_character_select_back)

func change_to_game():
	print("Changing to game with character: ", selected_character.name if selected_character else "None")
	current_state = GameState.GAME
	
	# Clear current scene
	if current_scene:
		current_scene.queue_free()
	
	# Load game scene - FIX: Add to GameManager instead of current_scene
	current_scene = game_scene.instantiate()
	current_scene.name = "Main"  # Set explicit name for RPC targeting
	add_child(current_scene)
	
	# Pass selected character and multiplayer settings to game AFTER it's been added to the scene
	await get_tree().process_frame
	
	if current_scene.has_method("set_multiplayer_mode"):
		current_scene.set_multiplayer_mode(is_multiplayer_game, network_manager)
	
	if selected_character:
		current_scene.set_selected_character(selected_character)

# Main menu signal handlers
func _on_main_menu_start_game():
	print("Main menu: Start game selected")
	change_to_game_mode_select()

func _on_main_menu_show_options():
	print("Main menu: Options selected (not implemented)")

func _on_main_menu_quit_game():
	print("Main menu: Quit game selected")
	get_tree().quit()

# Game mode select signal handlers
func _on_single_player_selected():
	print("Single player mode selected")
	is_multiplayer_game = false
	change_to_character_select()

func _on_multiplayer_selected():
	print("Multiplayer mode selected")
	is_multiplayer_game = true
	change_to_lobby_manager()

func _on_game_mode_back():
	print("Game mode select: Back pressed")
	change_to_main_menu()

# Lobby signal handlers
func _on_lobby_back():
	print("Lobby: Back pressed")
	change_to_game_mode_select()

# Character select signal handlers
func _on_character_selected(character_index: int):
	print("Character selected: ", character_index)
	selected_character_index = character_index
	selected_character = CharacterData.get_character(character_index)
	
	# Character selection is only synced when player clicks "Ready"
	# This allows players to browse characters without affecting others

func _on_character_ready(character_index: int):
	print("Character ready: ", character_index)
	selected_character_index = character_index
	selected_character = CharacterData.get_character(character_index)
	
	if selected_character:
		if is_multiplayer_game:
			# In multiplayer, sync our character selection and mark as ready
			var player_id = multiplayer.get_unique_id()
			network_manager.set_player_character.rpc(player_id, character_index)
			network_manager.set_player_ready.rpc(player_id, true)
			print("Multiplayer: Player ", player_id, " selected character ", character_index, " and is ready")
		else:
			# In single player, start immediately
			change_to_game()
	else:
		print("Error: Invalid character selected")

func _on_character_select_back():
	print("Character select: Back pressed")
	if is_multiplayer_game:
		change_to_lobby_manager()
	else:
		change_to_game_mode_select()

# Network signal handlers
func _on_lobby_created(code: String):
	print("Game Manager: Lobby created with code ", code)

func _on_lobby_joined(success: bool):
	print("Game Manager: Lobby join result: ", success)

func _on_character_selection_started():
	print("Game Manager: Character selection started for all players")
	change_to_character_select()

func _on_multiplayer_game_ready():
	print("👥 CLIENT: Multiplayer game ready - setting up client scene")
	print("👥 CLIENT: is_multiplayer_game = ", is_multiplayer_game)
	print("👥 CLIENT: selected_character = ", selected_character)
	change_to_game()

func _on_all_players_ready():
	print("Game Manager: All players ready, starting game")
	print("DEBUG: is_multiplayer_game = ", is_multiplayer_game)
	if network_manager:
		print("DEBUG: network_manager.is_host = ", network_manager.is_host)
	
	if is_multiplayer_game:
		if network_manager and network_manager.is_host:
			# Host creates the game and spawns all players
			print("🏠 HOST: Creating shared multiplayer arena...")
			change_to_game()
			network_manager.start_multiplayer_game.rpc()
		else:
			# Clients wait for host to create the game, then join
			print("👥 CLIENT: Waiting for host to create shared arena...")
	else:
		# Single player - start immediately
		print("🎮 SINGLE PLAYER: Starting game immediately")
		change_to_game()

func _input(event):
	# Handle global input (ESC to go back)
	if event.is_action_pressed("ui_cancel"):
		match current_state:
			GameState.GAME_MODE_SELECT:
				change_to_main_menu()
			GameState.LOBBY_MANAGER:
				change_to_game_mode_select()
			GameState.CHARACTER_SELECT:
				if is_multiplayer_game:
					change_to_lobby_manager()
				else:
					change_to_game_mode_select()
			GameState.GAME:
				change_to_main_menu()
			GameState.MAIN_MENU:
				get_tree().quit()

# Getters
func get_selected_character() -> CharacterData.Character:
	return selected_character

func get_selected_character_index() -> int:
	return selected_character_index

func get_network_manager() -> NetworkManager:
	return network_manager

func is_multiplayer() -> bool:
	return is_multiplayer_game
