class_name AchievementArt
extends RefCounted
## What an achievement is struck on, GAME.md 8.10: a commemorative chip, its color its
## denomination, with the achievement's own picture on a cream inlay in its middle; or, for the
## story's four, an enamel pin, the House's in its gold, black and red and Kit's in his grays,
## painted by hand, each cut to a shape of its own. One not earned yet is the same in gray, its
## picture faint; a hidden one is a scrap of Kit's graph paper folded over it and taped shut, a
## question mark on it in pencil. Drawn as shapes, so the same drawing serves a row of the list,
## the toast and a store's page alike, at any size. See [AchievementIcons] for the pictures.

## How an achievement is drawn: earned, not earned yet, or hidden.
enum Look { EARNED, LOCKED, HIDDEN }

## The chips' faces by denomination, white, red, green and black, the casino's own colors, and the
## notches round each: a white chip's are blue, as a casino's ones are, the rest cream.
const FACES: Array[Color] = [Color("#efe9dc"), Color("#b8332c"), Color("#2c7a52"), Color("#1d1c22")]
const WHITE_NOTCHES := Color("#2f5ea8")
## The cream inlay, how much of the chip it takes, and its rim.
const INLAY := HouseTheme.PAPER
const INLAY_SIZE := 0.64
const INLAY_RIM := 0.03
## The gold ring struck round the inlay of every commemorative chip, and the beads in the band
## between it and the notches on a chip big enough to show them.
const GILT := HouseTheme.FOIL
const BEADS := 24
const BEADS_FROM := 70.0
## The gray of one not earned yet: the face, the notches, the inlay and the ink of its picture.
const LOCKED_FACE := Color("#6f6e74")
const LOCKED_NOTCHES := Color("#a9a8ad")
const LOCKED_INLAY := Color("#c9c6bf")
const LOCKED_INK := Color(0.33, 0.32, 0.35, 0.55)
## The pins: the House's gold edge on black or red enamel with its pictures in gold, Kit's pewter
## edge on pale gray with his in pencil, and how thick the edge is.
const HOUSE_EDGE := HouseTheme.FOIL
const HOUSE_EDGE_LOW := HouseTheme.FOIL_LOW
const HOUSE_ENAMEL := Color("#1c1a20")
const HOUSE_RED := Color("#a32c27")
const KIT_EDGE := Color("#8f9094")
const KIT_EDGE_LOW := Color("#5f6064")
const KIT_ENAMEL := Color("#d9dbd8")
const PENCIL := Color(0.25, 0.25, 0.27)
const EDGE := 0.07
## Kit's graph paper and its lines, the tape over the fold, and how many squares across it is.
const GRAPH := Color("#eef0ea")
const GRAPH_LINES := Color(0.42, 0.55, 0.66, 0.35)
const TAPE := Color(0.86, 0.8, 0.62, 0.62)
const SQUARES := 7
const HAND: Font = preload("res://assets/fonts/Caveat-Variable.ttf")
## How many times a picture's own pixels it is drawn at once, see [method drawn], rounded up to a
## step of these, and the group every [Picture] is in, drawn again from it once it is.
const SHARPER := 2.0
const STEP := 32
const PICTURES := &"achievement_pictures"


## A control drawing one achievement, round and centered in whatever room it is given.
class Picture:
	extends Control

	var achievement: Achievement:
		set(value):
			achievement = value
			queue_redraw()
	var look := Look.EARNED:
		set(value):
			look = value
			queue_redraw()
	## How far round it has spun, for the toast's toss: 0 face on, a quarter turn edge on.
	var spin := 0.0:
		set(value):
			spin = value
			queue_redraw()

	func _init() -> void:
		add_to_group(AchievementArt.PICTURES)

	func _draw() -> void:
		if achievement == null:
			return
		var radius := minf(size.x, size.y) * 0.5
		var across := cos(spin)
		var back := across < 0.0
		draw_set_transform(size * 0.5, 0.0, Vector2(maxf(absf(across), 0.04), 1.0))
		# Drawn once a run into a picture and shown from that, GAME.md 10.7: a chip is a hundred
		# small shapes, and a case of them was most of what the dialog cost a frame. Drawn as
		# shapes only until its picture is ready.
		var drawn := AchievementArt.drawn(self, achievement, look, back, radius)
		if drawn != null:
			draw_texture_rect(
				drawn, Rect2(-Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false
			)
		else:
			AchievementArt.draw(self, Vector2.ZERO, radius, achievement, look, back)
		draw_set_transform(Vector2.ZERO)


## A chip or a pin drawn once for [method drawn], filling its size.
class Drawing:
	extends Control

	var achievement: Achievement
	var look := Look.EARNED
	var back := false

	func _draw() -> void:
		var radius := minf(size.x, size.y) * 0.5
		AchievementArt.draw(self, size * 0.5, radius, achievement, look, back)


## [param achievement] as [param look], its back for [param back], drawn once into a picture for
## [param radius] on [param host]'s screen, at twice its pixels so it stays sharp turning and
## scaled, see [KeptPictures]; null until the picture is ready, when every [Picture] is drawn again.
## A hidden one's scrap is the same for every achievement, and kept once.
static func drawn(
	host: Control, achievement: Achievement, look: Look, back: bool, radius: float
) -> Texture2D:
	if not host.is_inside_tree():
		return null
	var scale := maxf(KeptPictures.scale_of(host), 0.25)
	var pixels := KeptPictures.step_up(radius * 2.0 * scale * SHARPER, STEP)
	var named := "hidden" if look == Look.HIDDEN else String(achievement.id)
	return KeptPictures.of(
		host,
		"achievement|%s|%d|%d" % [named, look, int(back)],
		Vector2i(pixels, pixels),
		func() -> Control:
			var drawing := Drawing.new()
			drawing.achievement = achievement
			drawing.look = look
			drawing.back = back
			return drawing,
		PICTURES
	)


## [param achievement] as a node [param side] across, drawn as [param look].
static func picture(achievement: Achievement, look: Look, side: float) -> Picture:
	var drawn := Picture.new()
	drawn.achievement = achievement
	drawn.look = look
	drawn.custom_minimum_size = Vector2(side, side)
	drawn.size = drawn.custom_minimum_size
	drawn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return drawn


## How [param achievement] is drawn for [param profile]: earned, hidden while it is one of the
## hidden ones not earned yet, or not earned yet.
static func look_of(achievement: Achievement, profile: Profile) -> Look:
	if profile != null and profile.achievements.has(achievement.id):
		return Look.EARNED
	return Look.HIDDEN if achievement.hidden else Look.LOCKED


## [param achievement] round [param middle], [param radius] out, onto [param on], as [param look];
## its back for [param back], the chip's face without its picture, as a coin's turned over.
static func draw(
	on: CanvasItem,
	middle: Vector2,
	radius: float,
	achievement: Achievement,
	look: Look,
	back := false
) -> void:
	if look == Look.HIDDEN:
		scrap(on, middle, radius)
	elif achievement.is_pin():
		_pin(on, middle, radius, achievement, look == Look.LOCKED, back)
	else:
		_chip(on, middle, radius, achievement, look == Look.LOCKED, back)


## A commemorative chip: the table's chip in its denomination, a ring of gold and of beads, and
## the picture on its inlay.
static func _chip(
	on: CanvasItem,
	middle: Vector2,
	radius: float,
	achievement: Achievement,
	locked: bool,
	back: bool
) -> void:
	var tier := clampi(achievement.chip, 0, FACES.size() - 1)
	var face := LOCKED_FACE if locked else FACES[tier]
	var notches := LOCKED_NOTCHES if locked else (WHITE_NOTCHES if tier == 0 else ChipArt.NOTCHES)
	ChipArt.chip(on, middle, radius, face, ChipArt.NOTCH_COUNT, notches)
	var inlay := radius * INLAY_SIZE
	var gilt := LOCKED_NOTCHES if locked else GILT
	on.draw_arc(middle, radius * 0.715, 0.0, TAU, 64, gilt, maxf(radius * 0.025, 1.0), true)
	if radius >= BEADS_FROM:
		for i: int in BEADS:
			var toward := Vector2.from_angle(TAU * (i + 0.5) / BEADS)
			on.draw_circle(middle + toward * radius * 0.68, radius * 0.012, gilt, true, -1.0, true)
	on.draw_circle(middle, inlay, LOCKED_INLAY if locked else INLAY, true, -1.0, true)
	var rim := maxf(radius * INLAY_RIM, 1.0)
	on.draw_arc(middle, inlay, 0.0, TAU, 48, face.darkened(0.35), rim, true)
	if back:
		IconShapes.star(on, _box(middle, inlay), 0.5, 0.5, 0.3, Color(face, 0.5))
		return
	var ink := LOCKED_INK if locked else HouseTheme.INK
	AchievementIcons.draw_into(on, _box(middle, inlay), achievement.id, ink, INLAY)


## An enamel pin cut to the achievement's own shape: its metal edge, its enamel and its picture,
## a glint across the top of the edge.
static func _pin(
	on: CanvasItem,
	middle: Vector2,
	radius: float,
	achievement: Achievement,
	locked: bool,
	back: bool
) -> void:
	var house := achievement.chip == Achievement.Chip.HOUSE_PIN
	var outline := pin_shape(achievement.id, middle, radius)
	var edge := KIT_EDGE if not house else HOUSE_EDGE
	var low := KIT_EDGE_LOW if not house else HOUSE_EDGE_LOW
	var enamel := KIT_ENAMEL if not house else _house_enamel(achievement.id)
	var ink := PENCIL if not house else HOUSE_EDGE
	if locked:
		edge = LOCKED_NOTCHES
		low = LOCKED_FACE
		enamel = LOCKED_INLAY if not house else LOCKED_FACE
		ink = LOCKED_INK
	# A shadow under it, then the metal, darker at its foot, and the enamel set into it.
	var shadow := PackedVector2Array()
	for point: Vector2 in outline:
		shadow.append(point + Vector2(0.0, radius * 0.05))
	on.draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.3))
	on.draw_colored_polygon(outline, low)
	var upper := PackedVector2Array()
	for point: Vector2 in outline:
		upper.append(point.lerp(middle, 0.02) + Vector2(0.0, -radius * 0.02))
	on.draw_colored_polygon(upper, edge)
	var inset := Geometry2D.offset_polygon(outline, -radius * EDGE)
	if inset.is_empty():
		return
	var face: PackedVector2Array = inset[0]
	on.draw_colored_polygon(face, enamel)
	var glint := face.duplicate()
	glint.append(face[0])
	on.draw_polyline(glint, Color(edge.lightened(0.3), 0.5), maxf(radius * 0.02, 1.0), true)
	if back:
		return
	var inside := _box(middle, radius * 0.62)
	if not house and not locked:
		# Kit painted his by hand: the paper's grain under his pencil, a few strokes askew.
		for i: int in 3:
			var y := inside.position.y + inside.size.y * (0.2 + 0.3 * i)
			on.draw_line(
				Vector2(inside.position.x, y),
				Vector2(inside.end.x, y + radius * 0.03),
				Color(PENCIL, 0.08),
				maxf(radius * 0.02, 1.0),
				true
			)
	AchievementIcons.draw_into(on, inside, achievement.id, ink, enamel)


## The enamel of the House's pin [param id]: Employee of the Month's red, the rest black.
static func _house_enamel(id: StringName) -> Color:
	return HOUSE_RED if id == &"employee_of_the_month" else HOUSE_ENAMEL


## The outline of the pin [param id] round [param middle], [param radius] out: Terms Accepted a
## seal with a scalloped edge, Employee of the Month a shield, Off the Books a folder with its tab
## and A Fresh Start a calendar's page on its rings.
static func pin_shape(id: StringName, middle: Vector2, radius: float) -> PackedVector2Array:
	var shape := PackedVector2Array()
	match id:
		&"terms_accepted":
			var points := 64
			for i: int in points:
				var angle := TAU * i / points
				var out := radius * (0.94 + 0.06 * cos(angle * 16.0))
				shape.append(middle + Vector2.from_angle(angle) * out)
		&"employee_of_the_month":
			for corner: Vector2 in [
				Vector2(-0.82, -0.86),
				Vector2(0.0, -0.98),
				Vector2(0.82, -0.86),
				Vector2(0.86, 0.1),
				Vector2(0.46, 0.66),
				Vector2(0.0, 0.98),
				Vector2(-0.46, 0.66),
				Vector2(-0.86, 0.1),
			]:
				shape.append(middle + corner * radius)
		&"off_the_books":
			for corner: Vector2 in [
				Vector2(-0.92, -0.62),
				Vector2(-0.6, -0.62),
				Vector2(-0.48, -0.8),
				Vector2(-0.04, -0.8),
				Vector2(0.06, -0.62),
				Vector2(0.92, -0.62),
				Vector2(0.92, 0.78),
				Vector2(-0.92, 0.78),
			]:
				shape.append(middle + corner * radius)
		_:
			for corner: Vector2 in [
				Vector2(-0.74, -0.84),
				Vector2(0.74, -0.84),
				Vector2(0.8, -0.78),
				Vector2(0.8, 0.9),
				Vector2(-0.8, 0.9),
				Vector2(-0.8, -0.78),
			]:
				shape.append(middle + corner * radius)
	return shape


## The hidden one, GAME.md 8.10: a scrap of Kit's graph paper folded over something round and
## taped shut, its edges torn, a question mark on it in pencil.
static func scrap(on: CanvasItem, middle: Vector2, radius: float) -> void:
	var outline := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var corners: Array[Vector2] = [
		Vector2(-0.78, -0.74), Vector2(0.8, -0.8), Vector2(0.76, 0.78), Vector2(-0.82, 0.74)
	]
	for i: int in corners.size():
		var from := corners[i]
		var to := corners[(i + 1) % corners.size()]
		for step: int in 7:
			var t := step / 7.0
			var jag := Vector2(rng.randf_range(-0.03, 0.03), rng.randf_range(-0.03, 0.03))
			outline.append(middle + (from.lerp(to, t) + jag) * radius)
	var shadow := PackedVector2Array()
	for point: Vector2 in outline:
		shadow.append(point + Vector2(radius * 0.03, radius * 0.06))
	on.draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.3))
	on.draw_colored_polygon(outline, GRAPH)
	# The squares, kept inside the paper.
	var step := radius * 1.6 / SQUARES
	var width := maxf(radius * 0.012, 1.0)
	for i: int in range(1, SQUARES):
		var x := middle.x - radius * 0.8 + step * i
		var y := middle.y - radius * 0.76 + step * i
		on.draw_line(
			Vector2(x, middle.y - radius * 0.72),
			Vector2(x, middle.y + radius * 0.7),
			GRAPH_LINES,
			width,
			true
		)
		on.draw_line(
			Vector2(middle.x - radius * 0.74, y),
			Vector2(middle.x + radius * 0.72, y),
			GRAPH_LINES,
			width,
			true
		)
	# The fold across it, shaded under, with something round pressing up through the paper.
	on.draw_line(
		middle + Vector2(-0.8, 0.1) * radius,
		middle + Vector2(0.78, -0.04) * radius,
		Color(0.0, 0.0, 0.0, 0.12),
		maxf(radius * 0.05, 1.0),
		true
	)
	on.draw_arc(middle, radius * 0.5, 0.0, TAU, 48, Color(0.0, 0.0, 0.0, 0.07), radius * 0.06, true)
	# The tape over the fold.
	var tape := PackedVector2Array(
		[
			middle + Vector2(-0.24, -0.92) * radius,
			middle + Vector2(0.12, -0.96) * radius,
			middle + Vector2(0.2, -0.46) * radius,
			middle + Vector2(-0.16, -0.42) * radius,
		]
	)
	on.draw_colored_polygon(tape, TAPE)
	var size := roundi(radius * 1.2)
	var mark := "?"
	var wide := HAND.get_string_size(mark, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	on.draw_string(
		HAND,
		middle + Vector2(-wide * 0.5, radius * 0.38),
		mark,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		Color(PENCIL, 0.85)
	)


## A square box [param half] out each way round [param middle], a little in from its edge, for a
## picture.
static func _box(middle: Vector2, half: float) -> Rect2:
	var side := half * 2.0 * 0.86
	return Rect2(middle - Vector2.ONE * side * 0.5, Vector2.ONE * side)
