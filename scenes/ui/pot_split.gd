class_name PotSplit
extends Control
## What becomes of a pot when it is split, GAME.md 3.6 and 3.13: at a death, and at the whistle for
## a pot still being carried. The share that banks leaves the wreck as a stream of gold coins that
## flies into that player's banked score, in their corner of the screen or on their row of the
## standings, and says how much it was when it lands; the share that is lost bursts out of the wreck
## in coins that go gray and crumble to dust where they fall, and says how much went. A number over
## a wreck saying half was banked left a player to work out for themselves what became of the rest.

## Seconds a banked coin takes from the wreck to the score, and between one coin leaving and the
## next, so they string out into a stream rather than arriving as one.
const FLIGHT := 0.65
const STAGGER := 0.05
## How far above the straight line a banked coin's flight arcs, as a share of its length.
const ARC := 0.3
## How long a lost coin lives, and how much of that it spends gold before it goes gray.
const CRUMBLE := 0.85
const GRAY_AT := 0.18
## Where in its life a lost coin falls apart into dust, and how long the dust lasts.
const DUST_AT := 0.6
const DUST_LIFE := 0.5
## How fast a lost coin is thrown out of the wreck, the least and the most, in pixels a second,
## and how fast it falls.
const BURST := Vector2(140.0, 300.0)
const FALL := 700.0
const COIN := 8.5
## One coin drawn for so many points, never fewer than the least nor more than the most: a small
## pot still reads as coins and a fortune does not fill the screen.
const POINTS_PER_COIN := 15
const FEWEST := 3
const MOST := 12
## How long a number stays up, how far it rises in that time, and how big it is.
const WORDS_FOR := 1.2
const WORDS_RISE := 34.0
const WORDS_SIZE := 30
const GRAY := Color(0.52, 0.52, 0.56)
const LOST := Color(0.95, 0.36, 0.36)

var hud: MatchHud

var _coins: Array[Dictionary] = []
var _dust: Array[Dictionary] = []
var _words: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


static func attach(owner: MatchHud) -> PotSplit:
	var split := PotSplit.new()
	split.name = "PotSplit"
	split.hud = owner
	split.mouse_filter = Control.MOUSE_FILTER_IGNORE
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Over the corners and the standings it flies into.
	split.z_index = 10
	owner.add_child(split)
	split.set_process(false)
	return split


## [param slot]'s pot split: [param banked] into the score and [param lost] gone.
func play(slot: int, banked: int, lost: int) -> void:
	var from := _wreck(slot)
	if not from.is_finite():
		return
	if banked > 0:
		var spot := hud.score_spot(slot)
		if not spot.is_empty():
			var to := spot[0]
			for i: int in _count(banked):
				var bend := from.lerp(to, 0.5) + Vector2(0.0, -from.distance_to(to) * ARC)
				_coins.append(
					{"bank": true, "from": from, "to": to, "bend": bend, "age": -i * STAGGER}
				)
			# Beside the score it went into, once the first of it is there; the baseline a little
			# under the middle, so the number sits level with the score.
			var beside := spot[1] + Vector2(0.0, WORDS_SIZE * 0.35)
			_say("+%d" % banked, beside, Palette.CHIP_GOLD, -FLIGHT)
		else:
			_say("+%d" % banked, from + Vector2(0.0, -40.0), Palette.CHIP_GOLD, 0.0)
	if lost > 0:
		for i: int in _count(lost):
			var angle := _rng.randf_range(-PI * 0.9, -PI * 0.1)
			var speed := _rng.randf_range(BURST.x, BURST.y)
			var throw := Vector2(cos(angle), sin(angle)) * speed
			_coins.append(
				{"bank": false, "from": from, "velocity": throw, "age": 0.0, "dusted": false}
			)
		_say("−%d" % lost, from + Vector2(0.0, -40.0), LOST, -0.1)
	set_process(true)


## How many coins [param points] are drawn with.
static func _count(points: int) -> int:
	return clampi(ceili(float(points) / POINTS_PER_COIN), FEWEST, MOST)


## Where [param slot]'s kart is on this screen, a little above the floor, or not finite when it is
## nowhere to be seen.
func _wreck(slot: int) -> Vector2:
	var match_node := hud.match_node
	if slot < 0 or slot >= match_node.slots.size() or match_node.slots[slot].kart == null:
		return Vector2.INF
	var camera := get_viewport().get_camera_3d()
	var at := match_node.slots[slot].kart.global_position + Vector3(0.0, 0.6, 0.0)
	if camera == null or camera.is_position_behind(at):
		return Vector2.INF
	return camera.unproject_position(at)


## A number that rises and fades at [param at], once [param wait] seconds have gone by: negative
## ages count up to it.
func _say(text: String, at: Vector2, color: Color, wait: float) -> void:
	_words.append({"text": text, "at": at, "color": color, "age": wait})


func _process(delta: float) -> void:
	for coin: Dictionary in _coins:
		coin["age"] += delta
		if not coin["bank"] and not coin["dusted"] and coin["age"] >= CRUMBLE * DUST_AT:
			coin["dusted"] = true
			_crumble(_lost_spot(coin))
	_coins = _coins.filter(
		func(coin: Dictionary) -> bool: return coin["age"] < (FLIGHT if coin["bank"] else CRUMBLE)
	)
	for speck: Dictionary in _dust:
		speck["age"] += delta
	_dust = _dust.filter(func(speck: Dictionary) -> bool: return speck["age"] < DUST_LIFE)
	for said: Dictionary in _words:
		said["age"] += delta
	_words = _words.filter(func(said: Dictionary) -> bool: return said["age"] < WORDS_FOR)
	queue_redraw()
	if _coins.is_empty() and _dust.is_empty() and _words.is_empty():
		set_process(false)


## A lost coin come apart: a few specks of gray that drift down and fade where it was.
func _crumble(at: Vector2) -> void:
	for i: int in 5:
		var drift := Vector2(_rng.randf_range(-40.0, 40.0), _rng.randf_range(-30.0, 10.0))
		_dust.append({"at": at, "velocity": drift, "age": 0.0})


func _lost_spot(coin: Dictionary) -> Vector2:
	var age: float = coin["age"]
	var from: Vector2 = coin["from"]
	var velocity: Vector2 = coin["velocity"]
	return from + velocity * age + Vector2(0.0, 0.5 * FALL * age * age)


func _draw() -> void:
	for coin: Dictionary in _coins:
		var age: float = coin["age"]
		if age < 0.0:
			continue
		if coin["bank"]:
			var t := clampf(age / FLIGHT, 0.0, 1.0)
			# Drawn in by the score rather than lobbed at it: slow off the wreck, quick at the end.
			var along := t * t
			var from: Vector2 = coin["from"]
			var bend: Vector2 = coin["bend"]
			var to: Vector2 = coin["to"]
			var at := from.lerp(bend, along).lerp(bend.lerp(to, along), along)
			_draw_coin(at, COIN * lerpf(1.0, 0.7, t), Palette.CHIP_GOLD, 1.0)
			continue
		var life := age / CRUMBLE
		if life >= DUST_AT:
			continue
		var tone := Palette.CHIP_GOLD.lerp(GRAY, clampf(life / GRAY_AT, 0.0, 1.0))
		var shrink := 1.0 - clampf((life - DUST_AT * 0.6) / (DUST_AT * 0.4), 0.0, 1.0) * 0.4
		_draw_coin(_lost_spot(coin), COIN * shrink, tone, 1.0)
	for speck: Dictionary in _dust:
		var age: float = speck["age"]
		var at: Vector2 = speck["at"] + speck["velocity"] * age + Vector2(0.0, 60.0 * age * age)
		var fade := 1.0 - age / DUST_LIFE
		draw_rect(Rect2(at - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color(GRAY, 0.9 * fade))
	var font := Type.display_font()
	for said: Dictionary in _words:
		var age: float = said["age"]
		if age < 0.0:
			continue
		var t := age / WORDS_FOR
		var fade := 1.0 - clampf((t - 0.6) / 0.4, 0.0, 1.0)
		var color: Color = said["color"]
		var text: String = said["text"]
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, WORDS_SIZE).x
		var at: Vector2 = said["at"] + Vector2(-width * 0.5, -WORDS_RISE * t)
		draw_string_outline(
			font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, WORDS_SIZE, 8, Color(0.0, 0.0, 0.0, fade)
		)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, WORDS_SIZE, Color(color, fade))


## A coin: a disc with a dark rim and a glint, so it reads as a coin over the felt and over the
## dark of a corner alike.
func _draw_coin(at: Vector2, radius: float, color: Color, alpha: float) -> void:
	draw_circle(at, radius + 1.5, Color(0.0, 0.0, 0.0, 0.5 * alpha))
	draw_circle(at, radius, Color(color, alpha))
	draw_circle(
		at - Vector2(radius, radius) * 0.3, radius * 0.35, Color(1.0, 1.0, 1.0, 0.35 * alpha)
	)
