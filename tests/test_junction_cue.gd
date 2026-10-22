extends GdUnitTestSuite
## The Junction's call to attention, GAME.md 3.4 and 8.1c: every room calls a pot in its own way,
## quiet with nothing at stake, louder as the hint climbs, a note of its own for a pot that would
## win the match, steady for anybody who asked for fewer flashes, 8.5, and the House's ring for a
## room with nothing of its own.

## A table in every room that has a Junction: High Limit's showdown has none, 6.3.
const ROOMS: Array[String] = [
	"lucky_crossing",
	"vault",
	"crossfire",
	"loose_threads",
	"pin_alley",
	"toy_box",
	"garage",
	"tutorial",
	"house_rules",
]
## The step a frame is played at, and how long each note is held to be measured.
const STEP := 1.0 / 60.0
const HOLD := 3.0

var _was_calm := false


func before_test() -> void:
	_was_calm = Game.settings.flash_reduction
	Game.settings.flash_reduction = false


func after_test() -> void:
	Game.settings.flash_reduction = _was_calm


func _arena(map: String, bake := false) -> Arena:
	var arena: Arena = auto_free(Arena.new())
	arena.layout = load("res://data/maps/%s.tres" % map)
	arena.bake_scenery = bake
	add_child(arena)
	return arena


## Every Junction of [param map], the tutorial's several among them.
func _cues(map: String, bake := false) -> Array[JunctionCue]:
	var cues: Array[JunctionCue] = []
	for pad: JunctionPad in _arena(map, bake).junctions:
		cues.append(pad.cue)
	return cues


## Plays [param cue] for [param seconds] and says what it did: the brightest any lamp got and the
## dimmest the brightest was, the mean glow of the lamps that call, whether any lamp changed from
## frame to frame, and how fast what turns was turning at the end.
func _play(
	cue: JunctionCue, seconds: float, hint: float, winning: bool, calm := false
) -> Dictionary:
	var most := 0.0
	var least := INF
	var total := 0.0
	var samples := 0
	var changed := false
	var last: Array[float] = []
	for frame: int in int(seconds / STEP):
		cue.play(STEP, hint, winning, calm)
		var now: Array[float] = []
		var calling := cue.calling()
		for lamp: StandardMaterial3D in cue.lamps():
			now.append(lamp.emission_energy_multiplier)
			if calling.has(lamp):
				total += lamp.emission_energy_multiplier
				samples += 1
		if not last.is_empty():
			for i: int in now.size():
				changed = changed or absf(now[i] - last[i]) > 0.001
		last = now
		most = maxf(most, cue.glow_now())
		least = minf(least, cue.glow_now())
	return {
		"most": most,
		"least": least,
		"mean": total / maxf(float(samples), 1.0),
		"changed": changed,
		"speed": cue.speed(),
	}


## Each room calls in its own medium rather than with the House's ring, GAME.md 8.1c: lamps of its
## own, and in every room with a wheel to turn, a wheel that turns.
func test_every_room_has_a_call_of_its_own() -> void:
	for map: String in ROOMS:
		for cue: JunctionCue in _cues(map):
			assert_object(cue).override_failure_message("%s: no cue" % map).is_not_null()
			assert_bool(cue.house).override_failure_message("%s: the House's ring" % map).is_false()
			assert_int(cue.lamps().size()).is_greater(0)
	for map: String in ["lucky_crossing", "vault", "loose_threads", "pin_alley", "toy_box"]:
		assert_int(_cues(map)[0].turns.size()).override_failure_message(map).is_greater(0)
	assert_int(_cues("garage")[0].turns.size()).is_greater(0)


## With nothing at stake nothing moves: the lamps hold as the room lit them, a signal's red lit
## and its green out, and the wheel is still.
func test_it_is_quiet_with_nothing_at_stake() -> void:
	for map: String in ROOMS:
		var cue := _cues(map)[0]
		var turned: Array[float] = []
		for pivot: Node3D in cue.turns:
			turned.append(pivot.rotation.y)
		var quiet := _play(cue, 1.0, 0.0, false)
		var why := "%s: the Junction called with nothing at stake" % map
		assert_bool(quiet["changed"]).override_failure_message(why).is_false()
		for lamp: StandardMaterial3D in cue.calling():
			(
				assert_float(lamp.emission_energy_multiplier)
				. override_failure_message(why)
				. is_equal_approx(cue.rest_glow, 0.0001)
			)
		for lamp: StandardMaterial3D in cue.stops:
			(
				assert_float(lamp.emission_energy_multiplier)
				. override_failure_message(why)
				. is_equal_approx(cue.stop_glow, 0.0001)
			)
		for lamp: StandardMaterial3D in cue.winners:
			assert_float(lamp.emission_energy_multiplier).override_failure_message(why).is_zero()
		for i: int in cue.turns.size():
			assert_float(cue.turns[i].rotation.y).override_failure_message(why).is_equal(turned[i])


## The more is at stake the louder it calls: its lamps brighter, and moving, and its wheel turning
## faster.
func test_it_calls_louder_as_the_hint_climbs() -> void:
	for map: String in ROOMS:
		var cue := _cues(map)[0]
		var low := _play(cue, HOLD, 0.25, false)
		var high := _play(cue, HOLD, 1.0, false)
		var why := "%s: %s at a little, %s at a fortune" % [map, low, high]
		assert_float(low["mean"]).override_failure_message(why).is_greater(cue.rest_glow)
		assert_float(high["mean"]).override_failure_message(why).is_greater(low["mean"])
		assert_bool(high["changed"]).override_failure_message(why).is_true()
		if not cue.turns.is_empty():
			assert_float(low["speed"]).override_failure_message(why).is_greater(0.0)
			assert_float(high["speed"]).override_failure_message(why).is_greater(low["speed"])


## A pot that would win the match is a different note rather than more of the same: every lamp of
## the note in its color, gold or a signal's green, lit together and flashing harder than the hint
## ever does, the rest out, and the wheel at its quickest.
func test_a_winning_pot_is_a_note_of_its_own() -> void:
	for map: String in ROOMS:
		var cue := _cues(map)[0]
		var fortune := _play(cue, HOLD, 1.0, false)
		var won := _play(cue, HOLD, 0.0, true)
		var why := "%s: %s for a fortune, %s for the match" % [map, fortune, won]
		assert_float(won["most"]).override_failure_message(why).is_greater(fortune["most"])
		assert_float(won["least"]).override_failure_message(why).is_less(won["most"] * 0.3)
		var flashing := cue.winning_lamps()
		var first: StandardMaterial3D = flashing[0]
		for lamp: StandardMaterial3D in cue.lamps():
			if not flashing.has(lamp):
				(
					assert_float(lamp.emission_energy_multiplier)
					. override_failure_message(why)
					. is_zero()
				)
				continue
			(
				assert_bool(lamp.emission.is_equal_approx(cue.win))
				. override_failure_message(why)
				. is_true()
			)
			(
				assert_float(lamp.emission_energy_multiplier)
				. override_failure_message(why)
				. is_equal_approx(first.emission_energy_multiplier, 0.0001)
			)
		if not cue.turns.is_empty():
			assert_float(won["speed"]).override_failure_message(why).is_greater(fortune["speed"])


## For a player who asked for fewer flashes, GAME.md 8.5, the lamps hold steady, as lit as the
## hint says, and gold for a winning pot; the wheel, which is no flash, still turns. Played through
## the pad, which reads the setting.
func test_fewer_flashes_hold_it_steady() -> void:
	Game.settings.flash_reduction = true
	for map: String in ROOMS:
		var pad := _arena(map).junction
		var cue := pad.cue
		pad.hint = 0.8
		pad._process(STEP)
		var held := cue.glow_now()
		var each: Array[float] = []
		for lamp: StandardMaterial3D in cue.lamps():
			each.append(lamp.emission_energy_multiplier)
		var why := "%s: flashed for a player who asked for fewer" % map
		for frame: int in 120:
			pad._process(STEP)
			var lamps := cue.lamps()
			for i: int in lamps.size():
				(
					assert_float(lamps[i].emission_energy_multiplier)
					. override_failure_message(why)
					. is_equal_approx(each[i], 0.0001)
				)
		assert_float(held).override_failure_message(why).is_greater(cue.rest_glow)
		if not cue.turns.is_empty():
			assert_float(cue.speed()).override_failure_message(why).is_greater(0.0)
		pad.winning = true
		pad._process(STEP)
		var gold := cue.glow_now()
		for frame: int in 60:
			pad._process(STEP)
			assert_float(cue.glow_now()).override_failure_message(why).is_equal_approx(gold, 0.0001)
		assert_float(gold).override_failure_message(why).is_greater(held)
		for lamp: StandardMaterial3D in cue.winning_lamps():
			(
				assert_bool(lamp.emission.is_equal_approx(cue.win))
				. override_failure_message(why)
				. is_true()
			)


## What turns survives the pad's bake, which merges whatever wears the same material: a wheel
## merged with the pad round it would not turn. And the lamps are still on the pad after it, each
## worn by something, so the lamps the cue lights are lamps that are drawn.
func test_what_turns_and_what_lights_survive_the_bake() -> void:
	for map: String in ROOMS:
		var arena := _arena(map, true)
		var pad := arena.junction
		var worn: Array[Material] = []
		for node: Node in pad.find_children("*", "MeshInstance3D", true, false):
			worn.append((node as MeshInstance3D).material_override)
		for lamp: StandardMaterial3D in pad.cue.lamps():
			(
				assert_bool(worn.has(lamp))
				. override_failure_message("%s: a lamp baked away" % map)
				. is_true()
			)
		for pivot: Node3D in pad.cue.turns:
			var parts := pivot.find_children("*", "MeshInstance3D", true, false)
			var why := "%s: %s was baked into the pad" % [map, pivot.name]
			assert_int(parts.size()).override_failure_message(why).is_greater(0)
			for part: Node in parts:
				var skin := (part as MeshInstance3D).material_override
				assert_int(worn.count(skin)).override_failure_message(why).is_equal(1)


## A room with no call of its own, and no face of its own, has the House's magenta ring: dark with
## nothing at stake, blinking as the hint climbs, and gold for a winning pot.
func test_a_room_with_nothing_of_its_own_has_the_house_ring() -> void:
	var room := RoomLook.new()
	room.id = &"plain"
	var kit := RoomKit.new(room, Surfaces.new(room))
	var holder: Node3D = auto_free(Node3D.new())
	var cue := kit.junction(holder, 2.5)
	assert_bool(cue.house).is_true()
	assert_int(cue.pulse.size()).is_equal(1)
	assert_bool(cue.turns.is_empty()).is_true()
	var ring := cue.pulse[0]
	assert_bool(ring.albedo_color.is_equal_approx(Palette.NEON_MAGENTA)).is_true()
	var quiet := _play(cue, 1.0, 0.0, false)
	assert_bool(quiet["changed"]).is_false()
	assert_float(quiet["most"]).is_equal(0.0)
	var loud := _play(cue, HOLD, 1.0, false)
	assert_bool(loud["changed"]).is_true()
	assert_float(loud["most"]).is_greater(0.5)
	var won := _play(cue, HOLD, 0.0, true)
	assert_float(won["most"]).is_greater(loud["most"])
	assert_bool(ring.emission.is_equal_approx(Palette.CHIP_GOLD)).is_true()


## The driving school's roundabout calls with traffic lights, GAME.md 8.1c: red with nothing at
## stake, amber running from signal to signal as the hint climbs and quicker the more is at stake,
## and every green flashing together for a pot that would win the match, a green nobody takes for
## another room's gold.
func test_the_school_calls_with_traffic_lights() -> void:
	var cue := _cues("tutorial")[0]
	assert_int(cue.stops.size()).is_equal(1)
	assert_int(cue.chase.size()).is_equal(4)
	assert_int(cue.winners.size()).is_equal(1)
	var red := cue.stops[0]
	var go := cue.winners[0]
	cue.play(STEP, 0.0, false)
	assert_float(red.emission_energy_multiplier).is_greater(0.0)
	assert_float(red.emission.h).is_less(0.05)
	assert_float(go.emission_energy_multiplier).is_zero()
	var slow := _play(cue, HOLD, 0.2, false)
	assert_float(red.emission_energy_multiplier).is_zero()
	assert_float(go.emission_energy_multiplier).is_zero()
	var amber_hue := cue.chase[0].emission.h
	assert_float(amber_hue).is_between(0.05, 0.15)
	# Quicker the more is at stake: the head of the amber gets round more often.
	var rounds := func(hint: float) -> int:
		var heads := 0
		var was := -1
		for frame: int in int(HOLD / STEP):
			cue.play(STEP, hint, false)
			var head := 0
			for i: int in cue.chase.size():
				if (
					cue.chase[i].emission_energy_multiplier
					> cue.chase[head].emission_energy_multiplier
				):
					head = i
			if head != was:
				heads += 1
				was = head
		return heads
	assert_int(rounds.call(1.0)).is_greater(rounds.call(0.2))
	assert_float(slow["mean"]).is_greater(0.0)
	var won := _play(cue, HOLD, 0.0, true)
	assert_float(won["most"]).is_greater(0.0)
	assert_float(red.emission_energy_multiplier).is_zero()
	for amber: StandardMaterial3D in cue.chase:
		assert_float(amber.emission_energy_multiplier).is_zero()
	var green_hue := go.emission.h
	assert_float(green_hue).is_between(0.25, 0.45)
	assert_float(absf(green_hue - Palette.CHIP_GOLD.h)).is_greater(0.2)


## The school's traffic lights stand off the pad: past its rim, where nothing drives over them,
## inside the Junction's own cells, where nothing else of the lot stands, shorter than a wall, and
## colliding with nothing.
func test_the_schools_signals_stand_off_the_pad() -> void:
	var arena := _arena("tutorial")
	var pad := arena.junction
	var half := arena.grid.rect_size(arena.grid.junction) * 0.5
	var signals := 0
	for node: Node in pad.get_children():
		if not String(node.name).begins_with("Signal"):
			continue
		signals += 1
		var post := node as Node3D
		for part: Node in post.find_children("*", "MeshInstance3D", true, false):
			var mesh := part as MeshInstance3D
			# In the post's own space, which faces out from the middle of the pad.
			var box := mesh.transform * mesh.get_aabb()
			var why := "%s has a part at %s" % [post.name, box]
			assert_float(box.end.y).override_failure_message(why).is_less(1.4)
			var inner := post.position.length() + box.position.z
			assert_float(inner).override_failure_message(why).is_greater(pad.radius)
			for corner: int in 8:
				var point := post.transform * box.get_endpoint(corner)
				var inside := absf(point.x) <= half.x and absf(point.z) <= half.y
				assert_bool(inside).override_failure_message(why).is_true()
		assert_int(post.find_children("*", "CollisionObject3D", true, false).size()).is_zero()
		assert_int(post.find_children("*", "CollisionShape3D", true, false).size()).is_zero()
	assert_int(signals).is_equal(4)
