class_name LoyaltyReveal
extends Node
## The bets won since the loyalty map last showed them, shown being won as it opens, GAME.md 8.9
## "Bets won, shown", and the slip road's in the first look, see [LoyaltyTour]: the cursor at each
## in turn in the order they were won, the map coming round to it, its stamp coming down on its
## sign and its roads drawing out from it in gold to the bets they open, whose signs come up off the
## House's plans as the gold reaches them, and then the next.
##
## The view draws the sheet's picture as the map was before them, the profile's map with them not
## won yet, see [method held_back], and this over it, under the kart, see
## [member LoyaltyMapView.reveal]; once all are shown the picture is drawn again as the map is now,
## this drawing over it until that is up, and then it is gone.

## The cursor has come to [param id], to be shown being won.
signal came_to(id: StringName)
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
## The most shown one after another at an opening: any won before those are drawn won already,
## seen, as a debug build's every landmark won or a long time away would have many.
const MOST := 6

var view: LoyaltyMapView
## The bets shown, in the order they were won, and whose map it is.
var ids: Array[StringName] = []
var profile: Profile

## Each bet's own parts, by its place in [member ids]: the roads that draw out from it, each its
## points from it outward, the points as the sheet has them and whether it is Kit's pencil; and the
## bets whose signs come up as they are reached.
var _parts: Array[Dictionary] = []
## The one being shown, and how long since it was come to; -1 before the first.
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
## were won: none of those the map does not draw, and the last [constant MOST] of them at the most,
## those won before them seen, their NEW tags gone.
static func due(of: Profile, sheet: LoyaltyMapLayout.Sheet) -> Array[StringName]:
	var showing: Array[StringName] = []
	for id: String in of.loyalty.fresh:
		var landmark := Loyalty.map().landmark(StringName(id))
		if landmark == null or not Loyalty.is_drawn(of, landmark):
			continue
		if LoyaltyMapLayout.sheet_of(landmark) == sheet:
			showing.append(landmark.id)
	while showing.size() > MOST:
		of.loyalty.look_at(showing.pop_front())
	return showing


## [param of] as its map was before it won [param ids], for the map to be drawn as it was: the same
## profile but for those not won, never kept anywhere.
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
	before.loyalty = state
	return before


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in ids.size():
		_parts.append(_parts_of(i))


## What showing the [param i]th bet draws: its roads from it to landmarks not won before it, and
## the signs those open.
func _parts_of(i: int) -> Dictionary:
	var id := ids[i]
	var before := held_back(profile, ids.slice(i))
	var after := held_back(profile, ids.slice(i + 1))
	var roads: Array[Dictionary] = []
	for road: Dictionary in view.layout.roads:
		var ends: Array = road["ends"]
		if not id in ends:
			continue
		# A road with one end runs into the roundabout or off the sheet, from the bet outward.
		var other: StringName = &""
		if ends.size() >= 2:
			other = ends[1] if ends[0] == id else ends[0]
		if other != &"" and before.loyalty.has_won(other):
			continue
		var points: PackedVector2Array = road["points"]
		var outward := points.duplicate()
		if ends[0] != id:
			outward.reverse()
		roads.append({"points": points, "outward": outward, "pencil": road["pencil"]})
	var opens: Array[StringName] = []
	for other: StringName in Loyalty.map().roads_of(id):
		var landmark := Loyalty.map().landmark(other)
		if landmark == null or not view.is_on_sheet(other) or not Loyalty.is_drawn(after, landmark):
			continue
		var was := Loyalty.standing(before, landmark)
		if was == Loyalty.Standing.CLOSED and Loyalty.standing(after, landmark) != was:
			opens.append(other)
	return {"roads": roads, "opens": opens}


## The landmarks the [param i]th bet opens as it is shown, for the first look to light.
func opens_of(i: int) -> Array[StringName]:
	var opens: Array[StringName] = []
	if i >= 0 and i < _parts.size():
		opens.assign(_parts[i]["opens"])
	return opens


## Whether the [param i]th bet's roads have drawn out to the bets they open, their signs coming up.
func has_reached(i: int) -> bool:
	return i < ids.size() and _shares(i).y >= 1.0


## The bet being shown now, or none before the first and after the last.
func showing() -> StringName:
	return ids[_at] if _at >= 0 and _at < ids.size() and not _shown else &""


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
	_time += delta
	_sound(was, _time)
	if _time >= STEP:
		if _at + 1 < ids.size():
			_come_to(_at + 1)
		else:
			_all_shown()
	view.queue_redraw()


## The cursor at the [param i]th bet, the map coming round to it, the pane saying it.
func _come_to(i: int) -> void:
	_at = i
	_time = 0.0
	view.stand_at(ids[i], true)
	came_to.emit(ids[i])
	_keep_new_tags()


## Every one shown at once, as a press asks: the cursor at the last, each said as the cursor passes
## it, and the sheet drawn again as the map is now.
func finish_now() -> void:
	if _shown:
		return
	for i: int in range(maxi(_at + 1, 0), ids.size()):
		_at = i
		came_to.emit(ids[i])
	if not ids.is_empty():
		view.stand_at(ids[-1])
	_all_shown()


func _all_shown() -> void:
	_at = ids.size()
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


## The NEW tags as the profile has them now, the one come to gone, and what has landed won on the
## map as it is drawn live, the kart's landmark and the pins.
func _keep_new_tags() -> void:
	view.profile.loyalty.fresh = profile.loyalty.fresh.duplicate()


## The stamp's thump as it lands and the signs' click as they come up, once each.
func _sound(was: float, now: float) -> void:
	var lands := ROUND_TO + STAMP
	if was < lands and now >= lands:
		var kit := (
			Loyalty.map().landmark(ids[_at]).district == LoyaltyLandmark.District.OFF_THE_BOOKS
		)
		Audio.play_sfx(&"pencil" if kit else &"stamp", -6.0, 0.05)
		# Won, as drawn live: the kart's landmark lit and stamped under it.
		view.profile.loyalty.win(ids[_at])
		view.profile.loyalty.fresh = profile.loyalty.fresh.duplicate()
	var up := lands + SETTLE + DRAW
	if was < up and now >= up and not (_parts[_at]["opens"] as Array).is_empty():
		Audio.play_sfx(&"pad_claim", -10.0, 0.05)


## How far along the [param i]th bet's showing is: its stamp, from 0 to 1 landed and settled; its
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
## up and the stamps come down, and the dust of the one landing.
func draw_on(on: LoyaltyMapView) -> void:
	var zoom := on.zoom
	var base := Transform2D(0.0, Vector2.ONE * zoom, 0.0, on.offset)
	on.draw_set_transform_matrix(base)
	var house: Array[PackedVector2Array] = []
	var any := false
	for i: int in mini(_at + 1, ids.size()):
		var drawn := _shares(i).y
		if drawn <= 0.0:
			continue
		for road: Dictionary in _parts[i]["roads"]:
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
	for i: int in mini(_at + 1, ids.size()):
		_draw_signs(on, i)


## The [param i]th bet's signs as far as its showing has come: those it opens coming up, and its
## own with its stamp coming down on it.
func _draw_signs(on: LoyaltyMapView, i: int) -> void:
	var shares := _shares(i)
	for other: StringName in _parts[i]["opens"]:
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
	var landmark := Loyalty.map().landmark(ids[i])
	if shares.x <= 0.0:
		return
	var rect := on.sign_rect(ids[i])
	var landed := shares.x * (STAMP + SETTLE) >= STAMP
	LoyaltyArt.draw_sign(
		on, rect, landmark, Loyalty.Standing.WON if landed else Loyalty.Standing.OPEN, on.zoom
	)
	if not landed:
		var falling := shares.x * (STAMP + SETTLE) / STAMP
		LoyaltyArt.draw_won(
			on, rect, landmark, on.zoom, lerpf(STAMP_FROM, SQUASH, falling * falling)
		)
	elif shares.x < 1.0:
		var settling := (shares.x * (STAMP + SETTLE) - STAMP) / SETTLE
		LoyaltyArt.draw_won(on, rect, landmark, on.zoom, lerpf(SQUASH, 1.0, ease(settling, 0.5)))
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
