extends SceneTree
## Asks the Steam client on this machine the few things GAME.md 10.8 needs and prints what it
## answered: the app and the account, a key of rich presence set and cleared, and a lobby made and
## left again. As Spacewar, unless the checkout names an app in data/steam/app.cfg. By hand only,
## never part of make check: Steam has to be running, and logged in, here.
##
##   godot --headless --path . -s tools/steam_check.gd -- --steam
##
## `make steam-check` runs it so. A script run with -s is compiled before the game's autoloads are
## there to be named, so this names nothing of the game's and reaches it by path and by name.

const STORE := "res://scripts/store/store.gd"
## GodotSteam's friends-only lobby, and Steam's word for a call that went well.
const LOBBY_FRIENDS_ONLY := 1
const RESULT_OK := 1
## How long Steam has to make the lobby, in seconds.
const PATIENCE := 15.0

var _api: Object
var _began := false
var _waited := 0.0
var _done := false


func _process(delta: float) -> bool:
	if not _began:
		_began = true
		_begin()
	elif not _done:
		_waited += delta
		if _waited > PATIENCE:
			_finish("Steam made no lobby in %d s" % PATIENCE)
	return false


func _begin() -> void:
	var store: GDScript = load(STORE)
	var steam: Object = store.get("steam")
	if steam == null:
		var missing := str(store.get("missing"))
		_finish("Steam did not start: %s" % (missing if missing else "pass --steam"))
		return
	_api = steam.get("api")
	print(
		"app %d, account %d, %s" % [steam.get("app"), steam.get("account"), steam.call("persona")]
	)
	var presence := bool(_api.call("setRichPresence", "status", "Checking Jackpot Junction"))
	print("rich presence status set: %s" % presence)
	_api.connect("lobby_created", _on_lobby_created)
	_api.call("createLobby", LOBBY_FRIENDS_ONLY, 2)


func _on_lobby_created(result: int, lobby: int) -> void:
	if result != RESULT_OK:
		_finish("Steam made no lobby: result %d" % result)
		return
	_api.call("setLobbyData", lobby, "game", "jackpot-junction")
	print("lobby %d made, %d member" % [lobby, _api.call("getNumLobbyMembers", lobby)])
	_api.call("leaveLobby", lobby)
	print("lobby %d left" % lobby)
	_finish("")


func _finish(failure: String) -> void:
	_done = true
	if _api != null:
		_api.call("clearRichPresence")
	if failure.is_empty():
		print("Steam answered everything")
		quit(0)
	else:
		printerr(failure)
		quit(1)
