extends Node

# Game states
enum GameState {
	MAIN_MENU,
	CHARACTER_SELECT,
	GAME
}

# Current game state
var current_state: GameState = GameState.MAIN_MENU

# Selected character data
var selected_character: CharacterData.Character = null
var selected_character_index: int = 0

# Scene references
var main_menu_scene: PackedScene = preload("res://MainMenu.tscn")
var character_select_scene: PackedScene = preload("res://CharacterSelect.tscn")
var game_scene: PackedScene = preload("res://Main.tscn")

# Current scene instance
var current_scene: Node = null

func _ready():
	print("=== Game Manager - Step 3: Character System ===")
	
	# Start with main menu
	change_to_main_menu()

func change_to_main_menu():
	print("Changing to main menu")
	current_state = GameState.MAIN_MENU
	
	# Clear current scene
	if current_scene:
		current_scene.queue_free()
	
	# Load main menu
	current_scene = main_menu_scene.instantiate()
	get_tree().current_scene.add_child(current_scene)
	
	# Connect signals
	current_scene.start_game.connect(_on_main_menu_start_game)
	current_scene.show_options.connect(_on_main_menu_show_options)
	current_scene.quit_game.connect(_on_main_menu_quit_game)

func change_to_character_select():
	print("Changing to character selection")
	current_state = GameState.CHARACTER_SELECT
	
	# Clear current scene
	if current_scene:
		current_scene.queue_free()
	
	# Load character select
	current_scene = character_select_scene.instantiate()
	get_tree().current_scene.add_child(current_scene)
	
	# Connect signals
	current_scene.character_selected.connect(_on_character_selected)
	current_scene.ready_pressed.connect(_on_character_ready)
	current_scene.back_pressed.connect(_on_character_select_back)

func change_to_game():
	print("Changing to game with character: ", selected_character.name)
	current_state = GameState.GAME
	
	# Clear current scene
	if current_scene:
		current_scene.queue_free()
	
	# Load game scene
	current_scene = game_scene.instantiate()
	get_tree().current_scene.add_child(current_scene)
	
	# Pass selected character to game AFTER it's been added to the scene
	await get_tree().process_frame
	current_scene.set_selected_character(selected_character)

# Main menu signal handlers
func _on_main_menu_start_game():
	print("Main menu: Start game selected")
	change_to_character_select()

func _on_main_menu_show_options():
	print("Main menu: Options selected (not implemented in Step 3)")

func _on_main_menu_quit_game():
	print("Main menu: Quit game selected")
	get_tree().quit()

# Character select signal handlers
func _on_character_selected(character_index: int):
	print("Character selected: ", character_index)
	selected_character_index = character_index
	selected_character = CharacterData.get_character(character_index)

func _on_character_ready(character_index: int):
	print("Character ready: ", character_index)
	selected_character_index = character_index
	selected_character = CharacterData.get_character(character_index)
	
	if selected_character:
		change_to_game()
	else:
		print("Error: Invalid character selected")

func _on_character_select_back():
	print("Character select: Back pressed")
	change_to_main_menu()

func _input(event):
	# Handle global input (ESC to go back)
	if event.is_action_pressed("ui_cancel"):
		match current_state:
			GameState.CHARACTER_SELECT:
				change_to_main_menu()
			GameState.GAME:
				change_to_main_menu()
			GameState.MAIN_MENU:
				get_tree().quit()

func get_selected_character() -> CharacterData.Character:
	return selected_character

func get_selected_character_index() -> int:
	return selected_character_index 
