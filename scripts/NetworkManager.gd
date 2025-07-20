extends Node
class_name NetworkManager

# Networking configuration
const DEFAULT_PORT: int = 7000
const MAX_PLAYERS: int = 4
const DEBUG_MULTIPLAYER: bool = true  # Set to true for detailed testing logs

# Network state
var is_host: bool = false
var lobby_code: String = ""
var connected_players: Dictionary = {}  # id -> player_data
var player_characters: Dictionary = {}  # id -> character_index

# Signals
signal lobby_created(code: String)
signal lobby_joined(success: bool)
signal player_connected(id: int, player_name: String)
signal player_disconnected(id: int)
signal all_players_ready()
signal character_selection_started()
signal character_selection_updated(player_id: int, character_index: int)
signal multiplayer_game_ready()

func _ready():
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# Host a lobby
func create_lobby() -> String:
	is_host = true
	lobby_code = _generate_lobby_code()
	
	# Create server
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Lobby created with code: ", lobby_code)
		
		# Add host to players list
		var host_id = multiplayer.get_unique_id()
		connected_players[host_id] = {
			"name": "Host",
			"ready": false
		}
		
		lobby_created.emit(lobby_code)
		return lobby_code
	else:
		print("Failed to create lobby: ", error)
		return ""

# Join a lobby
func join_lobby(code: String) -> bool:
	lobby_code = code
	is_host = false
	
	# Extract IP from code (in real implementation, you'd use a matchmaking server)
	# For now, we'll just use localhost
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client("127.0.0.1", DEFAULT_PORT)
	
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Attempting to join lobby: ", code)
		return true
	else:
		print("Failed to join lobby: ", error)
		lobby_joined.emit(false)
		return false

# Disconnect from network
func disconnect_from_lobby():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	connected_players.clear()
	player_characters.clear()
	is_host = false
	lobby_code = ""

# Set player character
@rpc("any_peer", "call_local", "reliable")
func set_player_character(player_id: int, character_index: int):
	player_characters[player_id] = character_index
	character_selection_updated.emit(player_id, character_index)
	print("Player ", player_id, " selected character ", character_index)

# Mark player as ready
@rpc("any_peer", "call_local", "reliable")
func set_player_ready(player_id: int, is_ready: bool):
	if player_id in connected_players:
		connected_players[player_id]["ready"] = is_ready
		
		# Check if all players are ready
		if _all_players_ready():
			all_players_ready.emit()

# Start character selection (host only)
@rpc("any_peer", "call_local", "reliable")
func start_character_select():
	print("Starting character selection for all players")
	character_selection_started.emit()

# Tell all clients the multiplayer game is ready to join (NOT host)
@rpc("any_peer", "call_remote", "reliable") 
func join_multiplayer_game():
	print("👥 CLIENT: Joining shared multiplayer arena...")
	multiplayer_game_ready.emit()

# Start the actual game (host only) - called after all players ready  
@rpc("any_peer", "call_remote", "reliable")
func start_multiplayer_game():
	print("👥 CLIENT: Received multiplayer game start signal")
	# This RPC doesn't need to do anything - it's just a signal that game started

# Sync player list to all clients
@rpc("any_peer", "call_local", "reliable")
func sync_player_list(players_data: Dictionary):
	connected_players = players_data
	# Update UI for all players when player list changes
	for player_id in players_data:
		var player_data = players_data[player_id]
		player_connected.emit(player_id, player_data["name"])

# Network event handlers
func _on_peer_connected(id: int):
	print("Player connected: ", id)
	connected_players[id] = {
		"name": "Player " + str(id),
		"ready": false
	}
	
	# Sync the updated player list to all clients
	sync_player_list.rpc(connected_players)
	player_connected.emit(id, "Player " + str(id))

func _on_peer_disconnected(id: int):
	print("Player disconnected: ", id)
	if id in connected_players:
		connected_players.erase(id)
	if id in player_characters:
		player_characters.erase(id)
	player_disconnected.emit(id)

func _on_connected_to_server():
	print("Successfully connected to server")
	# Add ourselves to the local player list
	var our_id = multiplayer.get_unique_id()
	connected_players[our_id] = {
		"name": "Player " + str(our_id),
		"ready": false
	}
	lobby_joined.emit(true)

func _on_connection_failed():
	print("Failed to connect to server")
	lobby_joined.emit(false)

func _on_server_disconnected():
	print("Server disconnected")
	disconnect_from_lobby()

# Helper functions
func _generate_lobby_code() -> String:
	var code = ""
	for i in range(6):
		code += str(randi() % 10)
	return code

func _all_players_ready() -> bool:
	if connected_players.is_empty():
		return false
	
	for player_data in connected_players.values():
		if not player_data["ready"]:
			return false
	
	return true

# Getters
func get_player_count() -> int:
	return connected_players.size()

func get_connected_players() -> Dictionary:
	return connected_players

func get_player_characters() -> Dictionary:
	return player_characters

func is_multiplayer() -> bool:
	return multiplayer.multiplayer_peer != null
