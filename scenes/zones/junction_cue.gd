class_name JunctionCue
extends RefCounted
## The Junction's call to attention, GAME.md 3.4: what a room puts on its cash-out pad to say that
## a pot worth banking is out on the table, played by the pad from the hint and the winning pot the
## match works out for it. Every room says it in its own medium, 8.1c: a wheel that starts to turn,
## bulbs chasing round a rim, road studs, a running stitch. A room that says nothing of its own has
## the House's magenta ring say it, see [method RoomKit.junction].
##
## It plays three notes. With nothing at stake it is still: its lamps as the room lit them, its
## wheel at rest. From the hint's threshold up the wheel turns and the lamps come on, running
## round where there are several, quicker and brighter and further toward gold the more is at
## stake. A pot that would win the match is a different thing to say, so it is said a different
## way rather than as more of the first: every lamp gold, on and off together three times a
## second, and the wheel at its quickest. For a player who asked for fewer flashes, 8.5, the lamps
## hold steady instead, as bright as the hint says and gold for a winning pot, and the wheel, which
## is no flash, still turns.
##
## It is cheap by rule, 10.7: a few materials of its own whose colors and glow are set each frame,
## and a node or two turned about its own up. Nothing is built or freed while it plays, and every
## lamp is the plain lit material the room's neon already is, so nothing is compiled after the
## warm-up. What turns is baked into a mesh of its own per material, see [method turning], so the
## pad's own bake, which merges whatever wears the same material, leaves it where it hangs.

## The winning note: flashes a second, how bright at the top of each, and how much quicker than
## at the top of the hint the wheel turns for it.
const WIN_RATE := 3.2
const WIN_GLOW := 2.6
const WIN_SPIN := 1.6
## How many lamps behind the head of a chase are still lit, fading out along it, and how lit the
## rest of the lamps are while the hint is up, so the ring reads as one ring with a light running
## round it rather than as a few lights jumping.
const TAIL := 1.5
const FLOOR := 0.15
## How lit the lamps hold for fewer flashes, of what the hint and the winning note would make them
## at their brightest.
const STEADY := 0.65
## How quickly a wheel gets up to speed or runs down, in its top speed a second: a wheel coasts.
const PICKUP := 0.8

## Lamps in the order a chase runs round them. Each is a material of its own, worn by every part
## that lamp lights. One alone pulses as the ring did; several take turns.
var chase: Array[StandardMaterial3D] = []
## Lamps lit together, pulsing: a bumper's cap, the House's ring.
var pulse: Array[StandardMaterial3D] = []
## What turns as the hint climbs, about its own up: a wheel's head, a turntable, a turret.
var turns: Array[Node3D] = []
## A lamp's light at the top of the hint, the gold of the winning note, and how bright a lamp is at
## the top of the hint.
var lit := Palette.NEON_MAGENTA
var win := Palette.CHIP_GOLD
var glow := 2.0
## How lit a lamp is with nothing at stake: a room whose lamps are always on holds them there.
var rest_glow := 0.0
## How far toward gold a lamp's light goes at the top of the hint: a little, so a fortune is
## warmer than a pot just worth banking, and no further, so the gold stays the winning note's. The
## House's ring goes further, as it always did.
var drift := 0.25
## Turns a second of whatever turns, at the top of the hint.
var spin := 0.5
## Steps a second a chase runs round its lamps at the bottom of the hint and at the top.
var steps := Vector2(2.5, 9.0)
## Whether this is the House's magenta ring, for a room with no call of its own.
var house := false

## Each lamp's color unlit, by lamp, and the light of each lamp that has one of its own rather
## than [member lit].
var _dark: Dictionary[StandardMaterial3D, Color] = {}
var _own: Dictionary[StandardMaterial3D, Color] = {}
var _phase := 0.0
var _pulse := 0.0
var _beat := 0.0
var _speed := 0.0


## A lamp that is [param dark] unlit, and, for [param metallic], a metal one, as the pins round a
## processor are: the plain lit material, see the class's notes. It lights in [member lit], or in
## [param light] of its own where one is given, a bumper's red cap among warm bulbs. Not yet one of
## the cue's: hand it to [member chase] or [member pulse], or ask [method chase_lamps] or [method
## pulse_lamp].
func lamp(dark: Color, metallic := 0.0, light := Color.TRANSPARENT) -> StandardMaterial3D:
	var lamp_skin := StandardMaterial3D.new()
	lamp_skin.albedo_color = dark
	lamp_skin.emission_enabled = true
	lamp_skin.emission = lit if light.a <= 0.0 else light
	lamp_skin.emission_energy_multiplier = rest_glow
	lamp_skin.metallic = metallic
	lamp_skin.roughness = 0.4
	_dark[lamp_skin] = dark
	if light.a > 0.0:
		_own[lamp_skin] = light
	return lamp_skin


## [param count] lamps, [param dark] unlit, that a chase runs round in the order given.
func chase_lamps(count: int, dark: Color, metallic := 0.0) -> Array[StandardMaterial3D]:
	var made: Array[StandardMaterial3D] = []
	for i: int in count:
		made.append(lamp(dark, metallic))
	chase.append_array(made)
	return made


## A lamp, [param dark] unlit, that pulses with the hint, in [param light] of its own if given.
func pulse_lamp(dark: Color, metallic := 0.0, light := Color.TRANSPARENT) -> StandardMaterial3D:
	var made := lamp(dark, metallic, light)
	pulse.append(made)
	return made


## Every lamp the cue lights.
func lamps() -> Array[StandardMaterial3D]:
	var all: Array[StandardMaterial3D] = []
	all.append_array(chase)
	all.append_array(pulse)
	return all


## Whether the room gave it nothing to play, which leaves it to the House's ring.
func is_empty() -> bool:
	return chase.is_empty() and pulse.is_empty() and turns.is_empty()


## Turns [param pivot] with the hint, and bakes what hangs under it into one mesh for each
## material it wears, each a material of its own: two parts of a wheel in one red would otherwise
## be merged by the pad's bake with every other piece of that red on the pad, into a mesh that
## does not turn, see [method Bake.merge]. A lamp keeps its own material, which is already the
## cue's alone. Built round the pad's middle, which is what it turns about.
func turning(pivot: Node3D) -> void:
	Bake.merge(pivot)
	var own := lamps()
	for node: Node in pivot.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		if part.material_override != null and not own.has(part.material_override):
			part.material_override = part.material_override.duplicate()
	turns.append(pivot)


## Plays the cue for [param delta] seconds: [param hint] how loudly, 0 to 1, [param winning]
## whether a pot on this screen would win the match, and [param calm] whether the player asked
## for fewer flashes. Called by the pad each frame.
func play(delta: float, hint: float, winning: bool, calm := false) -> void:
	_turn(delta, hint, winning)
	if winning:
		_beat += delta * WIN_RATE
		var beat := STEADY if calm else 0.12 + 0.88 * (0.5 + 0.5 * sin(_beat * TAU))
		for lamp_skin: StandardMaterial3D in lamps():
			_light(lamp_skin, win, WIN_GLOW * beat, 1.0)
		return
	if hint <= 0.0:
		for lamp_skin: StandardMaterial3D in lamps():
			_light(lamp_skin, _own.get(lamp_skin, lit), rest_glow, 0.0)
		return
	_phase = fmod(_phase + delta * lerpf(steps.x, steps.y, hint), maxf(float(chase.size()), 1.0))
	_pulse = fmod(_pulse + delta * (1.3 + 2.6 * hint), 1.0)
	var wave := STEADY if calm else 0.5 + 0.5 * sin(_pulse * TAU)
	var level := 0.3 + 0.7 * hint
	for i: int in chase.size():
		var on := STEADY if calm else _bump(i, wave)
		var color: Color = _own.get(chase[i], lit).lerp(win, hint * drift * on)
		_light(chase[i], color, maxf(rest_glow, glow * level * (FLOOR + (1.0 - FLOOR) * on)), on)
	for lamp_skin: StandardMaterial3D in pulse:
		var color: Color = _own.get(lamp_skin, lit).lerp(win, hint * drift * wave)
		_light(lamp_skin, color, maxf(rest_glow, glow * hint * (0.15 + 0.85 * wave)), wave)


## How bright the brightest lamp is just now, for the tests and for anything that wants to know.
func glow_now() -> float:
	var most := 0.0
	for lamp_skin: StandardMaterial3D in lamps():
		most = maxf(most, lamp_skin.emission_energy_multiplier)
	return most


## How quickly what turns is turning just now, in turns a second.
func speed() -> float:
	return _speed


## How lit lamp [param i] of the chase is, 0 to 1: the head of the chase lit, the lamps behind it
## fading out along the tail. A lone lamp has no chase to run, and pulses with [param wave].
func _bump(i: int, wave: float) -> float:
	var count := float(chase.size())
	if count < 2.0:
		return wave
	var behind := fposmod(_phase - float(i), count)
	return clampf(1.0 - behind / TAIL, 0.0, 1.0)


## [param lamp_skin] lit in [param color] at [param energy], its face [param on] of the way from
## its own unlit color to the light.
func _light(lamp_skin: StandardMaterial3D, color: Color, energy: float, on: float) -> void:
	lamp_skin.emission = color
	lamp_skin.emission_energy_multiplier = energy
	lamp_skin.albedo_color = _dark.get(lamp_skin, color).lerp(color, clampf(on, 0.0, 1.0))


## Turns whatever turns: still with nothing at stake, quicker as the hint climbs and quickest for
## a winning pot, getting up to speed and running down the way a wheel does rather than at once.
func _turn(delta: float, hint: float, winning: bool) -> void:
	if turns.is_empty():
		return
	var target := 0.0
	if winning:
		target = spin * WIN_SPIN
	elif hint > 0.0:
		target = spin * (0.3 + 0.7 * hint)
	_speed = move_toward(_speed, target, delta * spin * PICKUP)
	if _speed <= 0.0:
		return
	for pivot: Node3D in turns:
		pivot.rotation.y = wrapf(pivot.rotation.y + _speed * TAU * delta, -PI, PI)
