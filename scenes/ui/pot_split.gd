class_name PotSplit
extends Control
## What becomes of a pot when it is split, GAME.md 3.6 and 3.13: at a death, and at the whistle for
## a pot still being carried. The share that banks leaves the wreck as a stream of gold coins that
## flies into that player's banked score, in their corner of the screen or on their row of the
## standings, and says how much it was when it lands; the share that is lost is thrown into a
## trash can that comes up beside the wreck, going gray on the way, and the can says how much went
## into it, shuts and goes. A number over a wreck saying half was banked left a player to work out
## what became of the rest, and coins that crumbled where they fell were gone before they were seen
## to be lost.

## Seconds a banked coin takes from the wreck to the score, and between one coin leaving and the
## next, so they string out into a stream rather than arriving as one.
const FLIGHT := 0.65
const STAGGER := 0.05
## How far above the straight line a banked coin's flight arcs, as a share of its length.
const ARC := 0.3
## Seconds a lost coin takes to drop into the can, between one and the next, and how much of the
## flight it spends gold before it has gone gray.
const THROW := 0.6
const THROW_STAGGER := 0.07
const GRAY_BY := 0.35
## How high over the can's mouth a lost coin is tossed, in pixels.
const TOSS := 70.0
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
## The can: how far from the wreck it stands, toward the middle of the screen and down a little,
## how big it is, how long it takes to come up, how long it stays once the last coin is in, how
## long it takes to go, and how far off the edge of the screen it is kept.
const CAN_OFFSET := Vector2(76.0, 34.0)
const CAN_SIZE := Vector2(30.0, 34.0)
const CAN_RISE := 0.15
const CAN_HOLD := 0.6
const CAN_FADE := 0.3
const CAN_MARGIN := 40.0
const CAN_BODY := Color(0.2, 0.21, 0.24)
const CAN_RIM := Color(0.72, 0.72, 0.76)

var hud: MatchHud

var _coins: Array[Dictionary] = []
var _cans: Array[Dictionary] = []
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
		_throw_away(from, lost)
	set_process(true)


## The lost share into a can beside the wreck: the can up, the coins tossed in one after another,
## and the number over it once the first is in.
func _throw_away(from: Vector2, lost: int) -> void:
	var count := _count(lost)
	var toward := 1.0 if from.x < size.x * 0.5 else -1.0
	var at := from + Vector2(CAN_OFFSET.x * toward, CAN_OFFSET.y)
	at = at.clamp(Vector2.ONE * CAN_MARGIN, size - Vector2.ONE * CAN_MARGIN)
	var last := (count - 1) * THROW_STAGGER + THROW
	_cans.append({"at": at, "age": 0.0, "full": last, "bump": 0.0})
	var mouth := at + Vector2(0.0, -CAN_SIZE.y * 0.5)
	for i: int in count:
		var aim := mouth + Vector2(_rng.randf_range(-6.0, 6.0), 0.0)
		var bend := from.lerp(aim, 0.5) + Vector2(0.0, -TOSS)
		(
			_coins
			. append(
				{
					"bank": false,
					"from": from,
					"to": aim,
					"bend": bend,
					"age": -i * THROW_STAGGER,
					"can": _cans.size() - 1,
					"in": false,
				}
			)
		)
	_say("−%d" % lost, mouth + Vector2(0.0, -26.0), LOST, -THROW)


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
		if not coin["bank"] and not coin["in"] and coin["age"] >= THROW:
			coin["in"] = true
			var can: int = coin["can"]
			if can < _cans.size():
				_cans[can]["bump"] = 1.0
	_coins = _coins.filter(
		func(coin: Dictionary) -> bool: return coin["age"] < (FLIGHT if coin["bank"] else THROW)
	)
	for can: Dictionary in _cans:
		can["age"] += delta
		can["bump"] = maxf(float(can["bump"]) - delta * 6.0, 0.0)
	# The cans go once every one of them has shut and faded, not one at a time: the coins still
	# flying find theirs by where it is in the list.
	var done := _cans.all(
		func(can: Dictionary) -> bool: return can["age"] >= can["full"] + CAN_HOLD + CAN_FADE
	)
	if done:
		_cans.clear()
	for said: Dictionary in _words:
		said["age"] += delta
	_words = _words.filter(func(said: Dictionary) -> bool: return said["age"] < WORDS_FOR)
	queue_redraw()
	if _coins.is_empty() and _cans.is_empty() and _words.is_empty():
		set_process(false)


func _draw() -> void:
	for can: Dictionary in _cans:
		_draw_can(can)
	for coin: Dictionary in _coins:
		var age: float = coin["age"]
		if age < 0.0:
			continue
		var t := clampf(age / (FLIGHT if coin["bank"] else THROW), 0.0, 1.0)
		var from: Vector2 = coin["from"]
		var bend: Vector2 = coin["bend"]
		var to: Vector2 = coin["to"]
		if coin["bank"]:
			# Drawn in by the score rather than lobbed at it: slow off the wreck, quick at the end.
			var along := t * t
			var into := from.lerp(bend, along).lerp(bend.lerp(to, along), along)
			_draw_coin(into, COIN * lerpf(1.0, 0.7, t), Palette.CHIP_GOLD)
			continue
		# Tossed, so up and over at an even pace and down into the can, going gray on the way.
		var at := from.lerp(bend, t).lerp(bend.lerp(to, t), t)
		var tone := Palette.CHIP_GOLD.lerp(GRAY, clampf(t / GRAY_BY, 0.0, 1.0))
		_draw_coin(at, COIN * lerpf(1.0, 0.6, t * t), tone)
	_draw_words()


func _draw_words() -> void:
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


## The trash can: a tapered body with its ribs and rim, and a lid held up and open while coins go
## in, which drops shut once the last one has. It pops up, bumps as each coin lands and fades.
func _draw_can(can: Dictionary) -> void:
	var age: float = can["age"]
	var full: float = can["full"]
	var fade := 1.0 - clampf((age - full - CAN_HOLD) / CAN_FADE, 0.0, 1.0)
	if fade <= 0.0:
		return
	var up := clampf(age / CAN_RISE, 0.0, 1.0)
	var grow := (1.0 - (1.0 - up) * (1.0 - up)) * (1.0 + 0.12 * float(can["bump"]))
	var middle: Vector2 = can["at"]
	var half := CAN_SIZE * 0.5 * grow
	var top := middle.y - half.y
	var bottom := middle.y + half.y
	var body := PackedVector2Array(
		[
			Vector2(middle.x - half.x, top),
			Vector2(middle.x + half.x, top),
			Vector2(middle.x + half.x * 0.78, bottom),
			Vector2(middle.x - half.x * 0.78, bottom),
		]
	)
	var shadow := PackedVector2Array()
	for point: Vector2 in body:
		shadow.append(middle + (point - middle) * 1.12)
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.45 * fade))
	draw_colored_polygon(body, Color(CAN_BODY, fade))
	for x: float in [-0.4, 0.0, 0.4]:
		draw_line(
			Vector2(middle.x + half.x * x, top + half.y * 0.35),
			Vector2(middle.x + half.x * x * 0.8, bottom - half.y * 0.25),
			Color(CAN_RIM, 0.55 * fade),
			2.0
		)
	var rim := Color(CAN_RIM, fade)
	draw_polyline(body + PackedVector2Array([body[0]]), rim, 2.0)
	# Open and tipped back while it is collecting, shut once the last coin is in.
	var shut := clampf((age - full) / 0.15, 0.0, 1.0)
	var hinge := Vector2(middle.x + half.x, top - 2.0)
	var tilt := lerpf(1.1, 0.0, shut)
	var along := Vector2(-cos(tilt), -sin(tilt)) * half.x * 2.2
	var thick := Vector2(-sin(tilt), cos(tilt)) * -5.0
	var lid := PackedVector2Array([hinge, hinge + along, hinge + along + thick, hinge + thick])
	draw_colored_polygon(lid, Color(CAN_BODY, fade))
	draw_polyline(lid + PackedVector2Array([lid[0]]), rim, 2.0)


## A coin: a disc with a dark rim and a glint, so it reads as a coin over the felt and over the
## dark of a corner alike.
func _draw_coin(at: Vector2, radius: float, color: Color) -> void:
	draw_circle(at, radius + 1.5, Color(0.0, 0.0, 0.0, 0.5))
	draw_circle(at, radius, color)
	draw_circle(at - Vector2(radius, radius) * 0.3, radius * 0.35, Color(1.0, 1.0, 1.0, 0.35))
