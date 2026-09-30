class_name BotEmotes
extends Node
## The bots have something to say now and then, GAME.md 3.8 and 9.1: an emote, put up the way a
## player's is, on the moments a player would put one up. Pleased with a double kill or better and
## with shoving somebody down a hole; cross at being shoved down one, at being shot at over and over
## by the same player, and at being killed the moment they came back; and a gg for winning the
## match, which a beaten bot now and then says too. Never every time: each moment is a chance,
## weighed by how chatty the bot is, after a moment's thought, and a bot that has just said
## something says nothing more for a while, so they read as the table's other players rather than as
## a machine answering every event.
##
## Decided where the karts run, the host online, and said to every machine as a player's emote is.

## Which of [constant EmoteArt.EMOTES] each is.
const GG := 0
const HAPPY := 1
const ANGRY := 2
## The chance a moment gets an emote, for a bot of [member BotTrait.chattiness] 1.
const CHANCE := 0.35
## How much of that a beaten bot's gg at the end of the match has, being the rarer grace.
const LOSING_GG := 0.2
## How long a bot thinks before it says it, in seconds, and how long before it says anything else.
const DELAY_MIN := 0.3
const DELAY_MAX := 1.2
const QUIET := 20.0
## Shots at a bot by one player, hits or near misses, within how many seconds, that make it cross.
const HOUNDED := 3
const HOUNDED_WITHIN := 6.0
## How soon after coming back a death is being killed the moment it came back, in seconds.
const SPAWN_KILL := 3.0

var match_node: Match
## [constant CHANCE], unless a test says otherwise.
var chance := CHANCE
var rng := RandomNumberGenerator.new()

var _clock := 0.0
## When each bot may next say something, on [member _clock].
var _next: Dictionary[int, float] = {}
## When each bot last came back.
var _back_at: Dictionary[int, float] = {}
## When each player last shot at each bot: "bot|shooter" to the times.
var _shots: Dictionary[String, Array] = {}
## What is waiting to be said: [when, slot, emote].
var _waiting: Array[Array] = []
## The karts listened to for their near misses, by instance.
var _heard_karts: Dictionary[int, bool] = {}


static func add_to(in_match: Match) -> BotEmotes:
	var emotes := BotEmotes.new()
	emotes.name = "BotEmotes"
	emotes.match_node = in_match
	in_match.add_child(emotes)
	return emotes


func _ready() -> void:
	rng.randomize()
	Events.announced.connect(_on_announced)
	Events.kart_shot.connect(_on_shot)
	Events.kart_killed.connect(_on_killed)
	Events.kart_respawned.connect(_on_back)
	Events.match_state_changed.connect(_on_state)


func _exit_tree() -> void:
	for connected: Array in [
		[Events.announced, _on_announced],
		[Events.kart_shot, _on_shot],
		[Events.kart_killed, _on_killed],
		[Events.kart_respawned, _on_back],
		[Events.match_state_changed, _on_state],
	]:
		var event: Signal = connected[0]
		if event.is_connected(connected[1]):
			event.disconnect(connected[1])


func _physics_process(delta: float) -> void:
	if match_node.puppet:
		return
	_clock += delta
	_listen_to_the_karts()
	for i: int in range(_waiting.size() - 1, -1, -1):
		var said: Array = _waiting[i]
		if float(said[0]) > _clock:
			continue
		_waiting.remove_at(i)
		if _is_bot(said[1]):
			Events.emoted.emit(said[1], said[2])


## A near miss is a kart's own to say, with who fired it, so each kart is listened to once it is
## there, which is after the match has seated everybody.
func _listen_to_the_karts() -> void:
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if kart == null or _heard_karts.has(kart.get_instance_id()):
			continue
		_heard_karts[kart.get_instance_id()] = true
		var victim := slot.index
		kart.grazed_by.connect(func(by: int) -> void: _on_shot(victim, by))


## [param slot], a bot, may say [param emote]: a chance, weighed by its chattiness and by
## [param share] of the usual, and said after a moment unless it has said something lately.
func want(slot: int, emote: int, share := 1.0) -> void:
	if match_node.puppet or not _is_bot(slot) or _clock < _next.get(slot, 0.0):
		return
	var bot_trait := match_node.slots[slot].bot_trait
	var chatty := bot_trait.chattiness if bot_trait != null else 1.0
	if rng.randf() >= chance * chatty * share:
		return
	_next[slot] = _clock + QUIET
	_waiting.append([_clock + rng.randf_range(DELAY_MIN, DELAY_MAX), slot, emote])


func _is_bot(slot: int) -> bool:
	return (
		slot >= 0
		and slot < match_node.slots.size()
		and match_node.slots[slot].input is BotInput
		and match_node.slots[slot].bot_trait != null
	)


func _on_announced(slot: int, call: String) -> void:
	if call in Announcer.COMBOS:
		want(slot, HAPPY)


func _on_shot(victim: int, by: int) -> void:
	if by < 0 or by == victim or not _is_bot(victim):
		return
	var key := "%d|%d" % [victim, by]
	var times: Array = _shots.get(key, [])
	while not times.is_empty() and _clock - float(times[0]) > HOUNDED_WITHIN:
		times.pop_front()
	times.append(_clock)
	_shots[key] = times
	if times.size() >= HOUNDED:
		_shots.erase(key)
		want(victim, ANGRY)


func _on_killed(victim: int, killer: int, cause: StringName) -> void:
	if cause == &"pit" and killer >= 0 and killer != victim:
		want(killer, HAPPY)
		want(victim, ANGRY)
	elif _clock - _back_at.get(victim, -INF) <= SPAWN_KILL:
		want(victim, ANGRY)


func _on_back(slot: int, _at: Vector3) -> void:
	_back_at[slot] = _clock


func _on_state(state: int) -> void:
	if state != Match.State.RESULTS:
		return
	var ranked := match_node.standings()
	for place: int in ranked.size():
		want(ranked[place].index, GG, 1.0 if place == 0 else LOSING_GG)
