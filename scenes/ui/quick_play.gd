class_name QuickPlay
extends Node
## Quick Play, GAME.md 10.8: a public Steam game near the player joined in one press, or one
## started with bots when there is none. Steam is asked for public games in the player's region and
## those next to it, then farther; a game it may join is public, on this version, with a seat for
## the player, nobody in it they have blocked, and a ping of 100 ms at most. Of those it takes a
## friend's first, then one under 50 ms, then the most people, then one in its lobby before one
## playing a map, then the lowest ping. With none, it waits a moment and asks once more, so two
## players pressing at once do not both start an empty game; still none, it starts one: a quick
## match open to anyone, the bots making up four karts.
##
## Said in a dialog over Play Online while it looks, with Cancel.

## Done looking: a game joined, one started, or Cancel pressed.
signal finished

## Where it is: asking Steam near, far, and once more after a moment; joining a game found;
## starting one; or doing nothing.
enum Step { NEAR, FAR, WAITING, AGAIN, JOINING, STARTING, DONE }

## Steam's pings Quick Play prefers, and the most it takes, in milliseconds, GAME.md 10.8: one
## number each, to tune in the Playtest.
const PREFERRED_PING := 50
const MOST_PING := 100
## The longest it waits before asking once more, in seconds, and how long it says it is starting a
## game before it does.
const WAIT_MOST := 2.0
const STARTING_FOR := 2.0
## How long the bar takes to ease along while it looks, in seconds, and how far it goes.
const LOOK_FOR := 3.0
const LOOK_REACH := 0.9
## What the dialog says while it looks, and once it starts a game.
const LOOKING := "Finding a game near you..."
const STARTING := "No games near you yet. Starting one with bots: people join as they come."

var dialog: FormDialog
var bar: ProgressBar
var cancel_button: Button
var step := Step.DONE
## Where it goes once it has a game, to join it or to host it: the game's waiting room, unless a
## test says otherwise.
var join_game: Callable = Game.go_to_waiting
var host_game: Callable = Game.go_to_waiting
## The longest wait before asking once more, and how long starting a game is said, in seconds: a
## test's shorter.
var wait_most := WAIT_MOST
var starting_for := STARTING_FOR

## The games still to try, best first, and the lobby being joined.
var _candidates: Array[Dictionary] = []
var _joining := 0
var _rng := RandomNumberGenerator.new()
var _easing: Tween


## Quick Play on [param screen], its dialog over it.
static func add_to(screen: Control) -> QuickPlay:
	var made := QuickPlay.new()
	made.name = "QuickPlay"
	screen.add_child(made)
	made.dialog = FormDialog.add_to(screen, "Quick Play", LOOKING)
	made.dialog.name = "QuickPlayDialog"
	made.bar = made.dialog.add_bar()
	made.cancel_button = made.dialog.add_button("Cancel")
	made.cancel_button.pressed.connect(made.stop)
	return made


## Looks for a game, the dialog up; nothing without Steam, or while it already looks.
func start() -> void:
	if not Store.on() or step != Step.DONE:
		return
	_rng.randomize()
	var lobbies := Store.steam.lobbies
	if not lobbies.entered.is_connected(_on_entered):
		lobbies.entered.connect(_on_entered)
		lobbies.failed.connect(_on_failed)
	dialog.set_title("Quick Play", LOOKING)
	bar.value = 0.0
	if _easing != null:
		_easing.kill()
	_easing = create_tween()
	_easing.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_easing.tween_property(bar, "value", LOOK_REACH, LOOK_FOR)
	dialog.open(cancel_button)
	_ask(Step.NEAR)


## Whether it is looking, or joining or starting a game, its dialog up.
func is_busy() -> bool:
	return step != Step.DONE


## Cancel: whatever it was doing stopped, a lobby being joined left, the dialog put away.
func stop() -> void:
	if step == Step.DONE:
		return
	if step == Step.JOINING and Store.on():
		Store.steam.lobbies.leave()
	step = Step.DONE
	_joining = 0
	_candidates.clear()
	dialog.close()
	finished.emit()


func _ask(at: Step) -> void:
	step = at
	var distance := SteamPublic.NEAR if at == Step.NEAR else SteamPublic.FAR
	Store.steam.public.ask(distance, _on_listed.bind(at))


func _on_listed(games: Array[Dictionary], at: Step) -> void:
	if step != at:
		return
	var found := ranked(fitting(games, at == Step.NEAR))
	if not found.is_empty():
		_candidates = found
		_next()
		return
	match at:
		Step.NEAR:
			_ask(Step.FAR)
		Step.FAR:
			# A moment, as long as chance says, before asking once more: two players pressing at
			# once would otherwise both start an empty game.
			step = Step.WAITING
			get_tree().create_timer(_rng.randf_range(0.0, wait_most)).timeout.connect(_again)
		_:
			_start_one()


func _again() -> void:
	if step == Step.WAITING:
		_ask(Step.AGAIN)


## The best game left joined, or one started once none is left.
func _next() -> void:
	if _candidates.is_empty():
		_start_one()
		return
	step = Step.JOINING
	var game: Dictionary = _candidates.pop_front()
	_joining = int(game["steam_lobby"])
	Store.steam.lobbies.join(_joining)


func _on_entered(lobby: int, host: int) -> void:
	if step != Step.JOINING or lobby != _joining:
		return
	var lobbies := Store.steam.lobbies
	# Somebody in it the player has blocked: the next game instead, GAME.md 10.8.
	if lobbies.anybody_blocked(lobby):
		lobbies.leave()
		_next()
		return
	step = Step.DONE
	_joining = 0
	join_game.call(SteamJoins.join_config(lobby, host, lobbies.host_of(lobby)))
	finished.emit()


func _on_failed(_why: String) -> void:
	if step == Step.JOINING:
		_joining = 0
		_next()


## Nothing to join: the dialog says a game is being started, and a moment later it is.
func _start_one() -> void:
	step = Step.STARTING
	dialog.set_title("Quick Play", STARTING)
	if _easing != null:
		_easing.kill()
	bar.value = 1.0
	get_tree().create_timer(starting_for).timeout.connect(_host)


func _host() -> void:
	if step != Step.STARTING:
		return
	step = Step.DONE
	host_game.call(config())
	finished.emit()


## Of [param games], those Quick Play may join, GAME.md 10.8: a seat for the player and a ping of
## [constant MOST_PING] at most; a game nobody could tell the ping of only from a search close by,
## [param near].
static func fitting(games: Array[Dictionary], near: bool) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for game: Dictionary in games:
		if GameList.is_full(game) or bool(game.get("password", false)):
			continue
		if int(game.get("players", 0)) + 1 > int(game.get("most", 0)):
			continue
		var ping := int(game.get("ping", SteamPublic.NO_PING))
		if ping > MOST_PING or (ping < 0 and not near):
			continue
		found.append(game)
	return found


## [param games] best first, see [method better].
static func ranked(games: Array[Dictionary]) -> Array[Dictionary]:
	var sorted := games.duplicate()
	sorted.sort_custom(better)
	return sorted


## Whether Quick Play tries [param a] before [param b], GAME.md 10.8: a friend's first, then one
## under [constant PREFERRED_PING], then the most people, then one in its lobby, then the lowest
## ping.
static func better(a: Dictionary, b: Dictionary) -> bool:
	if bool(a.get("friend", false)) != bool(b.get("friend", false)):
		return bool(a.get("friend", false))
	var close_a := _close(a)
	if close_a != _close(b):
		return close_a
	var people_a := int(a.get("players", 0))
	var people_b := int(b.get("players", 0))
	if people_a != people_b:
		return people_a > people_b
	if bool(a.get("lobby", false)) != bool(b.get("lobby", false)):
		return bool(a.get("lobby", false))
	return _ping_or_far(a) < _ping_or_far(b)


static func _close(game: Dictionary) -> bool:
	var ping := int(game.get("ping", SteamPublic.NO_PING))
	return ping >= 0 and ping < PREFERRED_PING


static func _ping_or_far(game: Dictionary) -> int:
	var ping := int(game.get("ping", SteamPublic.NO_PING))
	return ping if ping >= 0 else MOST_PING + 1


## The game Quick Play starts, GAME.md 10.8: open to anyone, a quick match on a map dealt from those
## a Grand Prix deals, the Standard preset at the profile playing's table, normal bots making up
## four karts, and room for eight.
static func config() -> MatchConfig:
	var made := SteamJoins.host_config(SteamLobby.Who.ANYONE)
	made.quick_play = true
	made.rounds = 0
	made.final_hand = false
	made.teams = 0
	made.make_up = MatchConfig.MAKE_UP
	made.difficulty = "normal"
	for preset: Dictionary in MatchPresets.PRESETS:
		if preset["name"] == "Standard":
			made.duration = float(preset["seconds"])
			made.target_score = preset["target"]
			made.joker_slots = preset["slots"]
			made.item_set = "first"
			made.own_bullets_hurt = preset["own_bullets"]
			made.overtime = preset["overtime"]
			made.catch_up = preset["catch_up"]
			made.roulette = preset["roulette"]
	made.table = Game.settings.profile.table_opened()
	var maps := ArenaMaps.pool(true, false)
	made.map = maps[randi() % maps.size()]
	return made
