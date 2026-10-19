class_name DressPicture
extends Control
## A picture of one choice of a part of a kart's dress, GAME.md 4.4, as the kart dialog shows what
## is worn and what there is to wear: a hat, a flag or a body as the thing itself, filmed once in a
## small world of its own, see [method film]; a paint as a patch of its pattern in the player's
## color; a trail as what it leaves behind, puffs, sparks, confetti, chips, flame or pencil; the
## plate in its frame; the tire marks it lays; a card back as the card. Nothing at all for "None"
## but a ring with a line through it. The drawn ones drawn once a run each and shown from then on,
## GAME.md 10.7, see [KeptPictures], every picture waiting on one told when it is ready.

## The pictures' group, told when one they wait on is ready.
const GROUP := &"dress_pictures"
## How far round from the front the camera stands for a hat, and from the side for a flag and a
## body, so each shows its shape: a hat's brim and crown, a flag's cloth flat on, a body's line
## from its nose to its tail; by the part.
const FROM: Dictionary[int, Vector3] = {
	1: Vector3(0.75, 0.45, -1.0),
	2: Vector3(0.45, 0.2, 1.0),
	6: Vector3(-1.0, 0.42, -0.42),
}
## How tight a filmed piece fills its picture, and the steps its pixels are rounded up to.
const FILL := 0.74
## A body is long and seen along its side, its tail nearer: held further off, so all of it is seen.
const BODY_FILL := 0.95
const STEP := 32
## What a plate in a frame reads.
const PLATE_WORDS := "JJ-777"
## The trail's confetti and chips, and the pencil's lead and wood.
const CONFETTI: Array[Color] = [
	Color("#ff4fa3"), Color("#35d0ff"), Color("#f2c14e"), Color("#43c463"), Color("#9b4fe2")
]
const CHIPS: Array[Color] = [Color("#e5483b"), Color("#3fa9f5"), Color("#2b2b30"), Color("#f2c14e")]
const SMOKE := Color(0.78, 0.78, 0.8)
const SPARK := Color("#ffd35a")
const SPARK_HOT := Color("#fff4c0")
const FLAME := Color("#ff7a2a")
const FLAME_HOT := Color("#ffe39a")
const LEAD := Color(0.25, 0.25, 0.28)
const WOOD := Color("#e8c78f")
const PENCIL := Color("#f2b53c")
const MARK := Color(0.08, 0.08, 0.09, 0.9)
## Where the card suits' stickers sit on a patch of the paint, by the suit, as shares of it: the
## spade up in its middle, as on the kart's nose, the heart and the diamond under it either side.
const STICKER_PLACES: Dictionary[int, Vector2] = {
	SuitArt.Suit.SPADE: Vector2(0.5, 0.32),
	SuitArt.Suit.HEART: Vector2(0.27, 0.68),
	SuitArt.Suit.DIAMOND: Vector2(0.73, 0.68),
}
const CHALK := Color(0.95, 0.95, 0.92, 0.75)
## How many pieces are filmed for the first time in one frame at the most: each small world costs
## its first frame, and a tray of fifteen hats at once held one up for a fifteenth of a second.
## The rest ask again in the frames after.
const FILMED_A_FRAME := 1

static var _filmed_frame := -1
static var _filmed := 0

## Which part of [constant KartStyle.CHOICES] this is, or the card back past them, and which
## choice of it, in [member color] and [member finish].
var part := 0
var index := 0
var color := Color.WHITE
var finish := 0
## The ink of "None", the ring with a line through it.
var ink := Color(1.0, 1.0, 1.0, 0.55)
## A hat or a flag as it was filmed, and what of: the small world it stands in is kept for as long
## as the picture is, its picture drawn once and never read back off the screen, which would hold
## the frame up for every one.
var _film: SubViewport
var _film_of := ""


static func make(part_of: int, index_of: int, in_color: Color, finished := 0) -> DressPicture:
	var picture := DressPicture.new()
	picture.part = part_of
	picture.index = index_of
	picture.color = in_color
	picture.finish = finished
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return picture


## Shows [param index_of] of [param part_of] in [param in_color] from now on.
func show_choice(part_of: int, index_of: int, in_color: Color, finished := 0) -> void:
	if part_of == part and index_of == index and in_color == color and finished == finish:
		return
	part = part_of
	index = index_of
	color = in_color
	finish = finished
	queue_redraw()


func _ready() -> void:
	add_to_group(GROUP)
	# A paint's pattern is a tile, laid over and over.
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


## Whether the choice is the part's "None": a hat, a flag or a trail that is not there.
func is_none() -> bool:
	return (part == 1 or part == 2) and index == 0 or part == 3 and index == 3


func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	if is_none():
		none_mark(self, box, ink)
		return
	match part:
		0:
			paint_patch(self, box.grow(-minf(size.x, size.y) * 0.06), index, color)
		1, 2, 6:
			_draw_photo(box)
		7:
			_draw_card(box)
		_:
			_draw_kept(box)


## A hat, a flag or a body, filmed once at the size it is shown, see [method film].
func _draw_photo(box: Rect2) -> void:
	var side := minf(box.size.x, box.size.y)
	var pixels := KeptPictures.step_up(side * KeptPictures.scale_of(self), STEP)
	var key := "%d:%d:%s:%d:%d" % [part, index, color.to_html(), finish, pixels]
	if key != _film_of and _may_film():
		_film_of = key
		if _film != null:
			_film.queue_free()
		_film = film(self, part, index, color, finish, pixels)
	elif key != _film_of and not get_tree().process_frame.is_connected(queue_redraw):
		# Drawn again next frame to ask again, once however often it is drawn meanwhile.
		get_tree().process_frame.connect(queue_redraw, CONNECT_ONE_SHOT)
	if _film != null:
		draw_texture_rect(
			_film.get_texture(),
			Rect2(box.get_center() - Vector2.ONE * side * 0.5, Vector2.ONE * side),
			false
		)


## Whether a piece may be filmed this frame, see [constant FILMED_A_FRAME]; one more has been.
static func _may_film() -> bool:
	var frame := Engine.get_process_frames()
	if frame != _filmed_frame:
		_filmed_frame = frame
		_filmed = 0
	if _filmed >= FILMED_A_FRAME:
		return false
	_filmed += 1
	return true


## A card back, as the card it is, kept the way [CardBack] keeps it.
func _draw_card(box: Rect2) -> void:
	var tall := box.size.y
	var wide := tall * JokerCard.SIZE.x / JokerCard.SIZE.y
	if wide > box.size.x:
		wide = box.size.x
		tall = wide * JokerCard.SIZE.y / JokerCard.SIZE.x
	var card := Rect2(box.get_center() - Vector2(wide, tall) * 0.5, Vector2(wide, tall))
	var shown := index
	CardBack.picture(
		shown,
		self,
		func(texture: Texture2D) -> void:
			if is_instance_valid(self) and shown == index:
				set_meta(&"card", texture)
				if is_inside_tree():
					queue_redraw()
	)
	var texture := get_meta(&"card") as Texture2D if has_meta(&"card") else null
	if texture != null:
		draw_texture_rect(texture, card, false)
	else:
		draw_rect(card, CardBack.BOARDS[clampi(index, 0, CardBack.BOARDS.size() - 1)])


## A trail, a plate in its frame, or tire marks: drawn once at the size it is shown and kept.
func _draw_kept(box: Rect2) -> void:
	var room := box
	if part == 4:
		var wide := box.size.x
		var tall := wide * LicensePlate.SIZE.y / LicensePlate.SIZE.x
		if tall > box.size.y:
			tall = box.size.y
			wide = tall * LicensePlate.SIZE.x / LicensePlate.SIZE.y
		room = Rect2(box.get_center() - Vector2(wide, tall) * 0.5, Vector2(wide, tall))
	var scale_now := KeptPictures.scale_of(self)
	var pixels := Vector2i(
		KeptPictures.step_up(room.size.x * scale_now, STEP),
		KeptPictures.step_up(room.size.y * scale_now, STEP)
	)
	var key := "dress:%d:%d" % [part, index]
	var shown_part := part
	var shown_index := index
	var kept := KeptPictures.of(
		self, key, pixels, func() -> Control: return _sketch(shown_part, shown_index), GROUP
	)
	if kept != null:
		draw_texture_rect(kept, room, false)
	else:
		draw_choice(self, room, part, index)


## The drawing [method _draw_kept] keeps, of [param index_of] of [param part_of].
static func _sketch(part_of: int, index_of: int) -> Control:
	if part_of == 4:
		var holder := PlateHolder.new()
		holder.plate = LicensePlate.of(PLATE_WORDS, LicensePlate.SIZE.x, false, index_of == 1)
		return holder
	var sketch := Sketch.new()
	sketch.drawing = func(on: CanvasItem, box: Rect2) -> void:
		draw_choice(on, box, part_of, index_of)
	return sketch


## A plate at its own size, scaled to the size it is given once it is up, for a picture to be kept
## of it: a plate lays its letters out for its own width.
class PlateHolder:
	extends Control

	var plate: LicensePlate

	func _ready() -> void:
		plate.scale = Vector2.ONE * size.x / LicensePlate.SIZE.x
		add_child(plate)


## A control that draws whatever it is handed, for a picture to be kept of it.
class Sketch:
	extends Control

	var drawing: Callable

	func _draw() -> void:
		drawing.call(self, Rect2(Vector2.ZERO, size))


## The part's choice drawn straight into [param box] on [param on], as it is shown until kept: a
## trail, tire marks, or for a plate's frame the plate's own colors.
static func draw_choice(on: CanvasItem, box: Rect2, part_of: int, index_of: int) -> void:
	match part_of:
		3:
			trail_icon(on, box, index_of)
		4:
			on.draw_rect(box, LicensePlate.GOLD if index_of == 1 else LicensePlate.PLAIN)
		5:
			marks_icon(on, box, index_of)


## The ring with a line through it that says there is none.
static func none_mark(on: CanvasItem, box: Rect2, line_ink: Color) -> void:
	var middle := box.get_center()
	var reach := minf(box.size.x, box.size.y) * 0.24
	var wide := maxf(reach * 0.12, 2.0)
	on.draw_arc(middle, reach, 0.0, TAU, 32, line_ink, wide, true)
	on.draw_line(
		middle + Vector2(-reach, reach) * 0.7,
		middle + Vector2(reach, -reach) * 0.7,
		line_ink,
		wide,
		true
	)


## A paint's pattern on a patch of the player's color; for the card suits the stickers the kart
## wears rather than a pattern, see [method sticker].
static func paint_patch(on: CanvasItem, box: Rect2, index_of: int, in_color: Color) -> void:
	var shape := FeltArt.rounded(box, minf(box.size.x, box.size.y) * 0.12)
	var pattern := KartDress.pattern_texture(index_of)
	if pattern == null:
		on.draw_colored_polygon(shape, in_color)
	else:
		var tile := box.size.x * 0.6
		var uvs := PackedVector2Array()
		for point: Vector2 in shape:
			uvs.append((point - box.position) / tile)
		on.draw_colored_polygon(shape, in_color, uvs, pattern)
	if index_of == KartStickers.PAINT:
		var reach := minf(box.size.x, box.size.y) * 0.25
		for place: Array in KartStickers.PLACES:
			var at: Vector2 = box.position + box.size * STICKER_PLACES[place[4]]
			sticker(on, at, reach, place[4])


## A sticker of the card suits paint, as the kart wears it, see [KartStickers]: [param suit] in
## its card's red or black on a cream disc [param reach] round [param at], with an ink rim.
static func sticker(on: CanvasItem, at: Vector2, reach: float, suit: int) -> void:
	on.draw_circle(at + Vector2(0.0, reach * 0.08), reach, Color(0, 0, 0, 0.3))
	on.draw_circle(at, reach, KartStickers.CREAM)
	var rim := reach * KartStickers.RIM / KartStickers.DISC
	on.draw_arc(at, reach - rim * 0.5, 0.0, TAU, 32, KartStickers.BLACK, rim, true)
	var red := suit == SuitArt.Suit.HEART or suit == SuitArt.Suit.DIAMOND
	var side := reach * KartStickers.SUIT / KartStickers.DISC
	SuitArt.draw_into(
		on,
		Rect2(at - Vector2.ONE * side * 0.5, Vector2.ONE * side),
		suit,
		KartStickers.RED if red else KartStickers.BLACK
	)


## What a trail leaves behind it, in [param box]: smoke puffs, sparks, confetti, poker chips, an
## afterburn's flame or a pencil's scribble.
static func trail_icon(on: CanvasItem, box: Rect2, index_of: int) -> void:
	var middle := box.get_center()
	var side := minf(box.size.x, box.size.y)
	var rng := RandomNumberGenerator.new()
	match index_of:
		0:
			for i: int in 4:
				var at := (
					middle + Vector2(-side * 0.32 + i * side * 0.2, side * 0.08 - i * side * 0.04)
				)
				var reach := side * (0.08 + i * 0.035)
				on.draw_circle(at + Vector2(0, side * 0.02), reach, Color(0, 0, 0, 0.25))
				on.draw_circle(at, reach, Color(SMOKE, 0.95 - i * 0.12))
		1:
			rng.seed = 7
			for i: int in 11:
				var at := (
					middle + Vector2(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.3, 0.3)) * side
				)
				var way := (
					Vector2.from_angle(rng.randf_range(-0.6, 0.6))
					* side
					* rng.randf_range(0.06, 0.14)
				)
				on.draw_line(at, at + way, SPARK, side * 0.03, true)
				on.draw_line(at + way * 0.5, at + way, SPARK_HOT, side * 0.02, true)
		2:
			rng.seed = 3
			for i: int in 14:
				var at := (
					middle
					+ Vector2(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.34, 0.34)) * side
				)
				var scrap := Vector2(side * 0.1, side * 0.06)
				on.draw_set_transform(at, rng.randf_range(0.0, PI), Vector2.ONE)
				on.draw_rect(Rect2(-scrap * 0.5, scrap), CONFETTI[i % CONFETTI.size()])
			on.draw_set_transform(Vector2.ZERO)
		4:
			for i: int in 4:
				var at := (
					middle
					+ Vector2(-side * 0.28 + i * side * 0.19, side * 0.1 - (i % 2) * side * 0.16)
				)
				var reach := side * 0.12
				on.draw_circle(at + Vector2(0, side * 0.02), reach, Color(0, 0, 0, 0.35))
				on.draw_circle(at, reach, CHIPS[i])
				on.draw_arc(at, reach * 0.72, 0, TAU, 20, Color(1, 1, 1, 0.75), side * 0.02, true)
				for k: int in 6:
					var angle := TAU * k / 6.0
					on.draw_line(
						at + Vector2.from_angle(angle) * reach * 0.8,
						at + Vector2.from_angle(angle) * reach,
						Color.WHITE,
						side * 0.03
					)
		5:
			var flame := PackedVector2Array()
			for k: int in 24:
				var angle := TAU * k / 24.0
				var reach := side * (0.22 + 0.1 * absf(sin(angle * 3.0)))
				flame.append(middle + Vector2(cos(angle) * reach * 1.5, sin(angle) * reach * 0.7))
			on.draw_colored_polygon(flame, FLAME)
			var inner := PackedVector2Array()
			for point: Vector2 in flame:
				inner.append(middle + (point - middle) * 0.55 + Vector2(side * 0.08, 0))
			on.draw_colored_polygon(inner, FLAME_HOT)
		6:
			var line := PackedVector2Array()
			for k: int in 30:
				var t := k / 29.0
				line.append(
					(
						middle
						+ Vector2(
							(t - 0.5) * side * 0.7,
							sin(t * 9.0) * side * 0.08 + (t - 0.5) * side * 0.1
						)
					)
				)
			on.draw_polyline(line, LEAD, side * 0.03, true)
			var tip := line[line.size() - 1]
			var lead := side * 0.12
			on.draw_colored_polygon(
				PackedVector2Array(
					[tip, tip + Vector2(lead, -lead * 1.6), tip + Vector2(lead * 1.6, -lead * 1.2)]
				),
				WOOD
			)
			on.draw_line(
				tip + Vector2(lead * 1.3, -lead * 1.4),
				tip + Vector2(lead * 3.2, -lead * 4.0),
				PENCIL,
				side * 0.09
			)


## Tire marks, two tracks across [param box] in the marks' look: plain rubber, chalk, dashes, or a
## pencil's three thin lines.
static func marks_icon(on: CanvasItem, box: Rect2, index_of: int) -> void:
	var middle := box.get_center()
	var side := minf(box.size.x, box.size.y)
	for lane: float in [-0.14, 0.14]:
		var from := middle + Vector2(-side * 0.38, side * lane + side * 0.12)
		var to := middle + Vector2(side * 0.38, side * lane - side * 0.12)
		match index_of:
			0:
				on.draw_line(from, to, MARK, side * 0.1, true)
			1:
				on.draw_line(from, to, CHALK, side * 0.1, true)
				for k: int in 9:
					on.draw_circle(
						from.lerp(to, k / 8.0) + Vector2(0, (k % 3 - 1) * side * 0.02),
						side * 0.02,
						Color(1, 1, 1, 0.5)
					)
			2:
				for k: int in 5:
					on.draw_line(
						from.lerp(to, k / 5.0), from.lerp(to, k / 5.0 + 0.12), MARK, side * 0.1
					)
			_:
				for k: int in 3:
					var by := Vector2(0, (k - 1) * side * 0.03)
					on.draw_line(
						from + by,
						to + by + Vector2(0, k * side * 0.015),
						Color(0.32, 0.32, 0.36, 0.8),
						maxf(side * 0.015, 1.0),
						true
					)


# --- filmed pieces -------------------------------------------------------------------------------


## [param index_of] of [param part_of], a hat, a flag or a body, in [param in_color] and
## [param finished], filmed [param pixels] square once in a small world of its own under
## [param host], which wears it as its picture from then on; null for none, or with no screen to
## film on.
static func film(
	host: Node, part_of: int, index_of: int, in_color: Color, finished: int, pixels: int
) -> SubViewport:
	if not host.is_inside_tree() or Game.is_headless():
		return null
	var thing := _subject(part_of, index_of, in_color)
	if thing == null:
		return null
	KartDress.wear_finish(thing, finished)
	thing.position = Vector3.ZERO
	thing.rotation = Vector3.ZERO
	var sway := thing.get_node_or_null("Sway")
	if sway != null:
		sway.process_mode = Node.PROCESS_MODE_DISABLED
	var render := SubViewport.new()
	render.name = "Film"
	render.size = Vector2i(pixels, pixels)
	render.transparent_bg = true
	render.own_world_3d = true
	render.render_target_update_mode = SubViewport.UPDATE_ONCE
	render.world_3d = _world()
	render.add_child(thing)
	var camera := Camera3D.new()
	camera.fov = 30.0
	var bounds := bounds_of(thing, part_of == 2)
	var reach := bounds.size.length() * 0.5
	var fill := BODY_FILL if part_of == 6 else FILL
	var distance := reach / sin(deg_to_rad(camera.fov * 0.5)) * fill
	var eye := bounds.get_center() + FROM[part_of].normalized() * distance
	camera.transform = Transform3D(Basis.looking_at(bounds.get_center() - eye), eye)
	render.add_child(camera)
	var light := DirectionalLight3D.new()
	light.light_energy = 1.2
	light.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
	render.add_child(light)
	host.add_child(render)
	return render


## What [method film] films of [param index_of] of [param part_of] in [param in_color]: the hat,
## the flag, or the body in a holder, its driver out of it and nothing hanging off it, so its
## shell is what is seen.
static func _subject(part_of: int, index_of: int, in_color: Color) -> Node3D:
	if part_of == 1:
		return KartDress.hat(index_of, in_color)
	if part_of == 2:
		return KartDress.flag(index_of, in_color)
	var holder := Node3D.new()
	var model := KartVisuals.painted(KartVisuals.body_at(index_of), in_color, KartStyle.new())
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var called := node.name.to_lower()
		if called.contains("character") or called == "cap":
			node.free()
	holder.add_child(model)
	return holder


## The box round every mesh of [param thing] in its own space, without a flag's pole for
## [param no_pole], so the picture holds what flies from it.
static func bounds_of(thing: Node3D, no_pole: bool) -> AABB:
	var found := AABB()
	var first := true
	for node: Node in thing.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null or (no_pole and mesh.get_parent() == thing):
			continue
		var placed := Transform3D.IDENTITY
		var at: Node = mesh
		while at != thing and at is Node3D:
			placed = (at as Node3D).transform * placed
			at = at.get_parent()
		var box := placed * mesh.get_aabb()
		found = box if first else found.merge(box)
		first = false
	return found


static func _world() -> World3D:
	var world := World3D.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.62, 0.7)
	environment.ambient_light_energy = 1.0
	world.environment = environment
	return world
