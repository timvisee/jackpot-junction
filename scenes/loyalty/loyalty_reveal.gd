class_name LoyaltyReveal
extends Node
## The bets won since the loyalty map last showed them, shown being won as it opens, GAME.md 8.9
## "Bets won, shown", and the slip road's in the first look, see [LoyaltyTour]: the cursor at each
## in turn in the order they were won, the map coming round to it, its stamp coming down on its
## sign and its roads drawing out from it in gold to the bets they open, whose signs come up off the
## House's plans as the gold reaches them, and then the next, each a little quicker than the one
## before. The first [constant ALONE] are shown so; any more are shown all together in one last
## beat after them, where they are, the cursor staying where it was, so twenty bets won while the
## map was away take no longer than four.
##
## The view draws the sheet's picture as the map was before them, the profile's map with them not
## won yet, see [method held_back], and this over it, under the kart, see
## [member LoyaltyMapView.reveal]; once all are shown the picture is drawn again as the map is now,
## this drawing over it until that is up, and then it is gone.

## The cursor has come to [param id], to be shown being won.
signal came_to(id: StringName)
## [param id] has been shown being won with the others in the last beat, the cursor elsewhere.
signal passed(id: StringName)
## Every one shown, and the sheet's picture drawn again as the map is now.
signal finished

## How long each part takes, in seconds: the map coming round to it before the stamp comes down,
## the stamp coming down and settling, the roads drawing out, the signs at their ends coming up,
## and the moment before the next.
const ROUND_TO := 0.4
const STAMP := 0.2
const SETTLE := 0.12
const DRAW := 0.6
const COME_UP := 0.3
const BETWEEN := 0.3
const STEP := ROUND_TO + STAMP + SETTLE + DRAW + COME_UP + BETWEEN
## How many are shown one after another before the rest come all together, and how much quicker
## each is than the one before, a share of the first's pace.
const ALONE := 3
const QUICKER := 0.25
## How big the stamp is as it starts coming down, and how far it squashes as it lands.
const STAMP_FROM := 2.6
const SQUASH := 0.88
## The dust thrown up round it as it lands: how many specks, how far out they go at a zoom of one,
## and for how long.
const DUST := 12
const DUST_OUT := 44.0
const DUST_TIME := 0.45
const DUST_INK := Color(0.42, 0.36, 0.3)
## How much bigger a sign coming up is as it starts.
const COME_UP_FROM := 1.3

var view: LoyaltyMapView
## The bets shown, in the order they were won, and whose map it is.
var ids: Array[StringName] = []
var profile: Profile

## Each beat, the first ones a bet each and the last any more together: the bets in it; the roads
## that draw out from them, each its points from its bet outward, the points as the sheet has them
## and whether it is Kit's pencil; and the bets whose signs come up as they are reached.
var _beats: Array[Dictionary] = []
## The beat being shown, and how far into it, at its own pace; -1 before the first.
var _at := -1
var _time := 0.0
## Whether all have been shown, the sheet drawn again, and how many frames since.
var _shown := false
var _waited := 0


## Shows [param showing], the bets [param of] won, on [param on]: the sheet's picture drawn again
## as the map was before them, the cursor at the first.
static func over(on: LoyaltyMapView, of: Profile, showing: Array[StringName]) -> LoyaltyReveal:
	var reveal := LoyaltyReveal.new()
	reveal.name = "Reveal"
	reveal.view = on
	reveal.profile = of
	reveal.ids = showing
	on.reveal = reveal
	on.profile = held_back(of, showing)
	on.add_child(reveal)
	on.redraw_sheet()
	return reveal


## The bets won on [param of]'s map since it last showed them, on [param sheet], in the order they
## were won: none of those the map does not draw.
static func due(of: Profile, sheet: LoyaltyMapLayout.Sheet) -> Array[StringName]:
	var showing: Array[StringName] = []
	for id: String in of.loyalty.fresh:
		var landmark := Loyalty.map().landmark(StringName(id))
		if landmark == null or not Loyalty.is_drawn(of, landmark):
			continue
		if LoyaltyMapLayout.sheet_of(landmark) == sheet:
			showing.append(landmark.id)
	return showing


## [param of] as its map was before it won [param ids], for the map to be drawn as it was: the same
## profile but for those not won, nor new, never kept anywhere.
static func held_back(of: Profile, unwon: Array[StringName]) -> Profile:
	var before := Profile.new()
	for property: Dictionary in of.get_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			before.set(property["name"], of.get(property["name"]))
	before.transient = true
	var state := LoyaltyState.new()
	for property: Dictionary in of.loyalty.get_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value: Variant = of.loyalty.get(property["name"])
			if value is PackedStringArray:
				value = (value as PackedStringArray).duplicate()
			state.set(property["name"], value)
	for id: StringName in unwon:
		var at := state.won.find(String(id))
		if at >= 0:
			state.won.remove_at(at)
		at = state.fresh.find(String(id))
		if at >= 0:
			state.fresh.remove_at(at)
	before.loyalty = state
	return before


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var from := 0
	while from < ids.size():
		var count := 1 if from < ALONE else ids.size() - from
		_beats.append(_beat_of(from, count))
		from += count


## The beat of the [param count] bets from the [param from]th: their roads out to landmarks not won
## before them, and the signs those open.
func _beat_of(from: int, count: int) -> Dictionary:
	var these := ids.slice(from, from + count)
	var before := held_back(profile, ids.slice(from))
	var after := held_back(profile, ids.slice(from + count))
	var roads: Array[Dictionary] = []
	var taken: Array[Dictionary] = []
	for id: StringName in these:
		for road: Dictionary in view.layout.roads:
			var ends: Array = road["ends"]
			if not id in ends or road in taken:
				continue
			# A road with one end runs into the roundabout or off the sheet, from the bet outward.
			var other: StringName = &""
			if ends.size() >= 2:
				other = ends[1] if ends[0] == id else ends[0]
			if other != &"" and before.loyalty.has_won(other):
				continue
			taken.append(road)
			var points: PackedVector2Array = road["points"]
			var outward := points.duplicate()
			if ends[0] != id:
				outward.reverse()
			roads.append({"points": points, "outward": outward, "pencil": road["pencil"]})
	var opens: Array[StringName] = []
	for id: StringName in these:
		for other: StringName in Loyalty.map().roads_of(id):
			var landmark := Loyalty.map().landmark(other)
			if landmark == null or other in these or other in opens or not view.is_on_sheet(other):
				continue
			if not Loyalty.is_drawn(after, landmark):
				continue
			var was := Loyalty.standing(before, landmark)
			if was == Loyalty.Standing.CLOSED and Loyalty.standing(after, landmark) != was:
				opens.append(other)
	return {"ids": these, "roads": roads, "opens": opens}


## The landmarks the [param i]th beat opens as it is shown, for the first look to light.
func opens_of(i: int) -> Array[StringName]:
	var opens: Array[StringName] = []
	if i >= 0 and i < _beats.size():
		opens.assign(_beats[i]["opens"])
	return opens


## Whether the [param i]th beat's roads have drawn out to the bets they open, their signs coming up.
func has_reached(i: int) -> bool:
	return i < _beats.size() and _shares(i).y >= 1.0


## Whether every one has been shown, and the sheet drawn again.
func is_done() -> bool:
	return _shown


func _process(delta: float) -> void:
	if _shown:
		_waited += 1
		# The picture drawn again as the map is now, before what is drawn over it goes.
		if _waited > 2 and not view.sheet_drawing():
			_gone()
		return
	if _at < 0:
		_come_to(0)
	var was := _time
	# Each beat a little quicker than the one before.
	_time += delta * (1.0 + QUICKER * _at)
	_sound(was, _time)
	if _time >= STEP:
		if _at + 1 < _beats.size():
			_come_to(_at + 1)
		else:
			_all_shown()
	view.queue_redraw()


## The [param i]th beat begun: the cursor at its bet, the map coming round to it, the pane saying
## it; or for the last beat of many, each of them said as seen, the cursor left where it was.
func _come_to(i: int) -> void:
	_at = i
	_time = 0.0
	var these: Array = _beats[i]["ids"]
	if these.size() == 1:
		view.stand_at(these[0], true)
		came_to.emit(these[0])
	else:
		# Where the last one alone was, the map not coming round to any of them.
		_time = ROUND_TO
		for id: StringName in these:
			passed.emit(id)
	_keep_new_tags()


## Every one shown at once, as a press asks: the cursor at the last shown alone, each said as it is
## passed, and the sheet drawn again as the map is now.
func finish_now() -> void:
	if _shown:
		return
	var last := &""
	for i: int in range(maxi(_at + 1, 0), _beats.size()):
		var these: Array = _beats[i]["ids"]
		for id: StringName in these:
			if these.size() == 1:
				last = id
				came_to.emit(id)
			else:
				passed.emit(id)
	if last != &"":
		view.stand_at(last)
	_all_shown()


func _all_shown() -> void:
	_at = _beats.size()
	_shown = true
	_waited = 0
	view.profile = profile
	view.redraw_sheet()
	view.queue_redraw()


func _gone() -> void:
	if view.reveal == self:
		view.reveal = null
	view.queue_redraw()
	finished.emit()
	queue_free()


## The NEW tags as the profile has them now, those come to gone and none on those still to come,
## which are new as they are shown.
func _keep_new_tags() -> void:
	var fresh := profile.loyalty.fresh.duplicate()
	for id: StringName in ids:
		var at := fresh.find(String(id))
		if at >= 0:
			fresh.remove_at(at)
	view.profile.loyalty.fresh = fresh


## The stamp's thump as it lands and the signs' click as they come up, once each a beat; and what
## has landed won on the map as it is drawn live, the kart's landmark and the pins.
func _sound(was: float, now: float) -> void:
	var these: Array = _beats[_at]["ids"]
	var lands := ROUND_TO + STAMP
	if was < lands and now >= lands:
		var kit := true
		for id: StringName in these:
			view.profile.loyalty.win(id)
			kit = (
				kit
				and Loyalty.map().landmark(id).district == LoyaltyLandmark.District.OFF_THE_BOOKS
			)
		_keep_new_tags()
		Audio.play_sfx(&"pencil" if kit else &"stamp", -6.0 if these.size() == 1 else -3.0, 0.05)
	var up := lands + SETTLE + DRAW
	if was < up and now >= up and not (_beats[_at]["opens"] as Array).is_empty():
		Audio.play_sfx(&"pad_claim", -10.0, 0.05)


## How far along the [param i]th beat's showing is: its stamps, from 0 to 1 landed and settled; its
## roads; and its signs coming up. All done for one already shown.
func _shares(i: int) -> Vector3:
	if i < _at or _shown:
		return Vector3.ONE
	if i > _at:
		return Vector3.ZERO
	var stamp := clampf((_time - ROUND_TO) / (STAMP + SETTLE), 0.0, 1.0)
	var roads := clampf((_time - ROUND_TO - STAMP - SETTLE) / DRAW, 0.0, 1.0)
	var up := clampf((_time - ROUND_TO - STAMP - SETTLE - DRAW) / COME_UP, 0.0, 1.0)
	return Vector3(stamp, roads, up)


## Draws on [param on], the view, from inside its draw: every road drawn out so far, the signs come
## up and the stamps come down, and the dust of those landing.
func draw_on(on: LoyaltyMapView) -> void:
	var zoom := on.zoom
	var base := Transform2D(0.0, Vector2.ONE * zoom, 0.0, on.offset)
	on.draw_set_transform_matrix(base)
	var house: Array[PackedVector2Array] = []
	var any := false
	for i: int in mini(_at + 1, _beats.size()):
		var drawn := _shares(i).y
		if drawn <= 0.0:
			continue
		for road: Dictionary in _beats[i]["roads"]:
			# Drawn whole as the sheet has it once it is out, so it is the picture's road to the
			# pixel; drawing out, from the bet along it.
			var points: PackedVector2Array = (
				road["points"] if drawn >= 1.0 else part_of(road["outward"], ease(drawn, 0.6))
			)
			LoyaltyMapArt.road(on, points, road["pencil"], true)
			if not road["pencil"]:
				house.append(points)
			any = true
	for points: PackedVector2Array in house:
		LoyaltyMapArt.road_inside(on, points, true)
	for points: PackedVector2Array in house:
		LoyaltyMapArt.road_middle(on, points, true)
	if any:
		for bridge: PackedVector2Array in on.layout.bridges:
			LoyaltyMapArt.bridge(on, bridge)
	on.draw_set_transform_matrix(Transform2D.IDENTITY)
	for i: int in mini(_at + 1, _beats.size()):
		_draw_signs(on, i)


## The [param i]th beat's signs as far as its showing has come: those it opens coming up, and its
## own with their stamps coming down on them.
func _draw_signs(on: LoyaltyMapView, i: int) -> void:
	var shares := _shares(i)
	for other: StringName in _beats[i]["opens"]:
		if shares.z <= 0.0:
			break
		var landmark := Loyalty.map().landmark(other)
		var rect := on.sign_rect(other)
		var stands := Loyalty.standing(on.profile, landmark)
		if stands == Loyalty.Standing.OPEN and landmark.kind != LoyaltyLandmark.Kind.CARD:
			LoyaltyMapPrint.bet(on, landmark, rect)
		var grown := lerpf(COME_UP_FROM, 1.0, ease(shares.z, 0.4))
		var big := Rect2(rect.get_center() - rect.size * grown * 0.5, rect.size * grown)
		LoyaltyArt.draw_sign(on, big, landmark, stands, on.zoom * grown)
	if shares.x <= 0.0:
		return
	var landed := shares.x * (STAMP + SETTLE) >= STAMP
	for id: StringName in _beats[i]["ids"]:
		var landmark := Loyalty.map().landmark(id)
		var rect := on.sign_rect(id)
		var stands := Loyalty.Standing.WON if landed else Loyalty.Standing.OPEN
		LoyaltyArt.draw_sign(on, rect, landmark, stands, on.zoom)
		if not landed:
			var falling := shares.x * (STAMP + SETTLE) / STAMP
			var grow := lerpf(STAMP_FROM, SQUASH, falling * falling)
			LoyaltyArt.draw_won(on, rect, landmark, on.zoom, grow)
		elif shares.x < 1.0:
			var settling := (shares.x * (STAMP + SETTLE) - STAMP) / SETTLE
			LoyaltyArt.draw_won(
				on, rect, landmark, on.zoom, lerpf(SQUASH, 1.0, ease(settling, 0.5))
			)
		if i == _at and not _shown:
			_draw_dust(on, rect, landmark)


## The dust thrown up as the stamp lands on [param rect]'s corner, specks going out and fading.
func _draw_dust(on: LoyaltyMapView, rect: Rect2, landmark: LoyaltyLandmark) -> void:
	var since := _time - ROUND_TO - STAMP
	if since < 0.0 or since > DUST_TIME:
		return
	var along := since / DUST_TIME
	var at := Vector2(rect.end.x, rect.position.y)
	var seed := float(landmark.mark.unicode_at(0))
	for k: int in DUST:
		var way := Vector2.from_angle(TAU * k / DUST + sin(seed + k) * 0.3)
		var out := DUST_OUT * on.zoom * ease(along, 0.4) * (0.7 + 0.3 * sin(seed * 3.0 + k))
		var speck := (2.6 - along * 1.6) * on.zoom
		on.draw_circle(at + way * out, speck, Color(DUST_INK, 0.55 * (1.0 - along)))


## Whether [param event] is a press that brings a showing all at once: a key, a pad's button or
## its repeat, see [PadRepeat], a click or a finger's emulated click.
static func is_press(event: InputEvent) -> bool:
	if event.is_echo() or not event.is_pressed():
		return false
	var click := event as InputEventMouseButton
	if click != null:
		return click.button_index == MOUSE_BUTTON_LEFT
	return event is InputEventKey or event is InputEventJoypadButton or event is InputEventAction


## The first [param share] of [param points] by its length along them.
static func part_of(points: PackedVector2Array, share: float) -> PackedVector2Array:
	var whole := 0.0
	for k: int in range(1, points.size()):
		whole += points[k - 1].distance_to(points[k])
	var left := whole * clampf(share, 0.0, 1.0)
	var part := PackedVector2Array()
	if points.is_empty():
		return part
	part.append(points[0])
	for k: int in range(1, points.size()):
		var step := points[k - 1].distance_to(points[k])
		if step >= left:
			part.append(points[k - 1].lerp(points[k], left / maxf(step, 0.001)))
			break
		part.append(points[k])
		left -= step
	return part
