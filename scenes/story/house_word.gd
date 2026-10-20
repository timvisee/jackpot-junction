class_name HouseWord
extends MeshInstance3D
## The word the House says to a room, STORY.md 6.1: KEEP CLEAR to start with, then the story's
## words, said off the table in the room's own medium, where the shot a match opens on sees it,
## GAME.md 8.2. A room's style says where and in what, see [method RoomStyle.house_word]: chalked
## on Kit's slate, stenciled on the Yard's hoarding, lit in the Arcade's display. A room that says
## nothing has it painted on its near apron, the House's paint, as it was once painted on the road.
##
## One picture drawn once, the letters and whatever plate the medium has under them, worn on one
## flat face by [code]house_word.gdshader[/code], which is the medium: it wears the paint thin,
## leaves the chalk grainy, lights the dots and lays the thread. It collides with nothing and
## decides nothing, and it is kept out of the room's bake, since its words are drawn rather than
## built.

## What the word is put on with. Each is a few numbers for the shader rather than a look of its
## own, so every room's word is the one shader.
enum Medium { PAINT, CHALK, GILT, STENCIL, DOTS, STICKER, STITCH }

const SHADER := preload("res://scenes/story/house_word.gdshader")
## Lying on a floor face up, its letters read from the near side, where the camera is.
const FLAT := Basis(Vector3(1.0, 0.0, 0.0), Vector3(0.0, 0.0, -1.0), Vector3(0.0, 1.0, 0.0))
## How finely the picture is drawn, in pixels to a meter, and the most it may be across: a word is
## one small picture, and the camera never comes close enough to one to want more.
const PER_METER := 64.0
const MOST_PIXELS := 1024
const FONT_SIZE := 96
## How much of its face the letters fill, across and up.
const FILL := Vector2(0.88, 0.62)
## How far over the floor a word painted on one lies, and how much taller than wide its letters
## are stretched there, the way a road stretches its own to read from a low angle.
const LIFT := 0.014
const STRETCH := 1.6
## How far apart a display's dots are, and a satin stitch's threads, in meters.
const DOT := 0.16
const THREAD := 0.11
## The near apron's word: how big, and how far apart the places it tries are, along it and out.
const APRON := Vector2(10.0, 2.4)
const APRON_STEP := Vector2(3.0, 1.5)

## A box of road paint, see [method road_box]: how many cells across and deep, what may not stand
## beside it, how far over the floor it lies, and how wide its line is, as a share of its depth.
const ROAD_CELLS := 6
const ROAD_ROWS := 2
const ROAD_AVOID: Array[String] = [
	ArenaGrid.PIT, ArenaGrid.JUNCTION, ArenaGrid.JACKPOT, ArenaGrid.GATE, ArenaGrid.PORTAL
]
const ROAD_LIFT := 0.014
const ROAD_LINE := 0.035

## The words said, as filled in for the profile playing.
var text := ""
## What it is put on with, and how big it is, in meters across and up.
var medium := Medium.PAINT
var size := Vector2.ONE
## Whether the word is painted in a box of road paint, as KEEP CLEAR is on a road, see
## [method road_box].
var boxed := false

var _stretch := 1.0
var _plated := false


## Puts [param words] up in [param arena]'s room, wherever and in whatever its style says, and on
## the near apron in the House's paint where it says nothing, and returns the word.
static func put_up(arena: Arena, words: String) -> HouseWord:
	var word := HouseWord.new()
	word.name = "HouseWord"
	word.text = words
	arena.add_child(word)
	var style := arena.kit.style
	if style == null or not style.house_word(word, arena):
		word.on_the_apron(arena, arena.room.marking, Medium.PAINT)
	return word


## Lays the word with its middle at [param at] in the room's space, [param across] meters wide and
## up, facing along [param facing]'s z: [constant FLAT] for one lying on the floor. In
## [param ink], over [param under] where the medium has a plate under its letters, which a sticker
## and a display do, and with its letters [param stretch] times as tall as the type has them.
func lay(
	at: Vector3,
	across: Vector2,
	ink: Color,
	how: Medium,
	facing := Basis.IDENTITY,
	stretch := 1.0,
	under := Color(0.0, 0.0, 0.0, 0.0)
) -> void:
	medium = how
	size = across
	_stretch = stretch
	_plated = under.a > 0.0
	transform = Transform3D(facing, at)
	var face := QuadMesh.new()
	face.size = across
	mesh = face
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var skin := material(how, ink, under, across)
	skin.set_shader_parameter(&"seed", fmod(absf(at.x * 0.37 + at.z * 0.71), 13.0))
	material_override = skin
	var pixels := Vector2i((across * PER_METER).round())
	var most := maxi(pixels.x, pixels.y)
	if most > MOST_PIXELS:
		pixels = Vector2i((Vector2(pixels) * float(MOST_PIXELS) / float(most)).round())
	var drawing := Control.new()
	drawing.draw.connect(func() -> void: _draw_word(drawing))
	DrawnTexture.kept(
		self,
		drawing,
		pixels.max(Vector2i.ONE),
		func(texture: Texture2D) -> void: skin.set_shader_parameter(&"picture", texture)
	)


## Where a box of road paint goes on [param grid], as KEEP CLEAR is painted across a lane: [param
## cells] floor cells across and [param rows] deep, nothing on any of them and nothing a kart falls
## down or banks on beside them, as near the near side as it fits and as near the middle of its rows
## as it will go, its bottom row kept one up from the wall where it can be, since the near wall
## stands in front of the row against it. An empty rect for a map with no such place.
static func road_box(grid: ArenaGrid, cells := ROAD_CELLS, rows := ROAD_ROWS) -> Rect2i:
	var bottoms: Array[int] = [grid.height - 3, grid.height - 2]
	for row: int in range(grid.height - 4, grid.height / 2, -1):
		bottoms.append(row)
	for bottom: int in bottoms:
		var top := bottom - rows + 1
		var best := Rect2i()
		var nearest := INF
		for start: int in range(1, grid.width - cells):
			var box := Rect2i(start, top, cells, rows)
			if not _bare(grid, box):
				continue
			var off := absf(start + cells * 0.5 - grid.width * 0.5)
			if off < nearest:
				nearest = off
				best = box
		if best.size != Vector2i.ZERO:
			return best
	return Rect2i()


## Whether [param box] is all bare floor with nothing beside it a kart falls down or banks on.
static func _bare(grid: ArenaGrid, box: Rect2i) -> bool:
	for y: int in range(box.position.y, box.end.y):
		for x: int in range(box.position.x, box.end.x):
			if grid.glyph(Vector2i(x, y)) != ArenaGrid.FLOOR:
				return false
	for y: int in range(box.position.y - 1, box.end.y + 1):
		for x: int in range(box.position.x - 1, box.end.x + 1):
			if x < 0 or y < 0 or x >= grid.width or y >= grid.height:
				continue
			if grid.glyph(Vector2i(x, y)) in ROAD_AVOID:
				return false
	return true


## Paints the word flat on [param arena]'s near apron in [param ink] as [param how] puts it on, in
## the first place along it from the middle out that nothing lying there has spoken for, and keeps
## that place: past the crowd, where the camera looks across the table, and clear of the table
## the karts drive on.
func on_the_apron(arena: Arena, ink: Color, how: Medium) -> void:
	var props := arena.get_node_or_null("Props") as RoomProps
	var half := arena.world_size() * 0.5
	var from := half.y + RoomBuild.NEAR + RoomProps.APRON_CLEAR + APRON.y * 0.5 + 0.6
	if props != null:
		from = half.y + props.clutter_from + RoomProps.APRON_CLEAR + APRON.y * 0.5 + 0.6
	var spot := Vector2(0.0, from)
	var found := false
	for out: int in 3:
		for step: int in int(half.x / APRON_STEP.x) * 2 + 1:
			var x := ceilf(step * 0.5) * APRON_STEP.x * (1.0 if step % 2 == 1 else -1.0)
			var here := Vector2(x, from + float(out) * APRON_STEP.y)
			if props == null or props._free(_patch(here)):
				spot = here
				found = true
				break
		if found:
			break
	if props != null:
		props._taken.append(_patch(spot))
	lay(Vector3(spot.x, RoomBuild.TOP + LIFT, spot.y), APRON, ink, how, FLAT, STRETCH)


## The worn face's material for [param how] in [param ink] over [param under], for a word
## [param across] meters wide and up.
static func material(how: Medium, ink: Color, under: Color, across: Vector2) -> ShaderMaterial:
	var skin := ShaderMaterial.new()
	skin.shader = SHADER
	skin.set_shader_parameter(&"ink", ink)
	skin.set_shader_parameter(&"plate", under)
	skin.set_shader_parameter(&"meters", across)
	# The paint is old road paint, worn thin and chipped; chalk is rubbed and grainy; a stencil is
	# sprayed, its edges soft; gilt is metal with a little light in it, as the room's sunburst has;
	# a display's dots are lit; thread is laid in satin stitch with a sheen along it.
	match how:
		Medium.PAINT:
			_tune(skin, {&"wear": 0.36, &"grain": 0.3, &"strength": 0.7})
		Medium.CHALK:
			_tune(skin, {&"wear": 0.2, &"grain": 0.55, &"strength": 0.74})
		Medium.STENCIL:
			_tune(skin, {&"wear": 0.15, &"grain": 0.25, &"strength": 0.95})
		Medium.GILT:
			_tune(skin, {&"foil": 0.75, &"glow": 0.22})
		Medium.DOTS:
			_tune(skin, {&"dots": DOT, &"glow": 1.6})
		Medium.STITCH:
			_tune(skin, {&"stitch": THREAD, &"foil": 0.25})
	return skin


static func _tune(skin: ShaderMaterial, values: Dictionary) -> void:
	for key: StringName in values:
		skin.set_shader_parameter(key, values[key])


## The patch of table a word on the apron at [param middle] covers, with a little room round it.
static func _patch(middle: Vector2) -> Rect2:
	return Rect2(middle - APRON * 0.5, APRON).grow(0.5)


## The type the word is set in: the House's display cut, and for gilt and a sticker its heaviest,
## gilt tracked out as a deco sign's capitals are.
func _font() -> Font:
	if medium == Medium.GILT or medium == Medium.STICKER:
		var deco := FontVariation.new()
		deco.base_font = Type.MARK
		deco.spacing_glyph = 14 if medium == Medium.GILT else 4
		return deco
	return Type.display_font()


## The letters in red, and the plate under them in green where the word has one: the shader inks
## the one and the other. A display's plate is the whole of its glass; any other's is a ticket with
## its corners rounded and a line in the letters' ink inside its edge, run in stitches on felt. Gilt
## has a rule over and under the word, as a deco sign does; a stencil's paint is oversprayed a
## little round its letters.
func _draw_word(on: Control) -> void:
	var area := on.size
	var letters := Color(1.0, 1.0 if _plated else 0.0, 0.0, 1.0)
	if _plated and medium == Medium.DOTS:
		on.draw_rect(Rect2(Vector2.ZERO, area), Color(0.0, 1.0, 0.0, 1.0))
	elif _plated:
		_ticket(on, area, letters)
	var font := _font()
	var span := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	if span <= 0.0:
		return
	var cap := Type.CAP_HEIGHT * FONT_SIZE
	var room := area * FILL
	var by := minf(room.x / span, room.y / (_stretch * cap))
	var middle := area * 0.5
	if medium == Medium.GILT:
		var wide := span * by
		var high := cap * by * _stretch
		var rule := maxf(high * 0.05, 1.0)
		for side: float in [-1.0, 1.0]:
			var y := middle.y + side * (high * 0.5 + rule * 3.0)
			on.draw_line(
				Vector2(middle.x - wide * 0.5, y), Vector2(middle.x + wide * 0.5, y), letters, rule
			)
	# The capitals' middle on the face's: half the line back, and the baseline half a capital down.
	if boxed:
		var line := maxf(area.y * ROAD_LINE, 1.0)
		on.draw_rect(
			Rect2(Vector2.ONE * line, area - Vector2.ONE * line * 2.0), letters, false, line
		)
	var at := Vector2(-span * 0.5, cap * 0.5)
	on.draw_set_transform(middle, 0.0, Vector2(by, by * _stretch))
	if medium == Medium.STENCIL:
		var spray := Color(letters, 0.22)
		on.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 10, spray)
	on.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, letters)
	on.draw_set_transform(Vector2.ZERO)


## A ticket for the word to stand on, the whole of [param area], with a line inside its edge in
## [param letters]: drawn on a sticker, stitched on felt.
func _ticket(on: Control, area: Vector2, letters: Color) -> void:
	var ticket := StyleBoxFlat.new()
	ticket.bg_color = Color(0.0, 1.0, 0.0, 1.0)
	ticket.set_corner_radius_all(int(area.y * 0.16))
	ticket.draw(on.get_canvas_item(), Rect2(Vector2.ZERO, area))
	var inset := area.y * 0.08
	var line := maxf(area.y * 0.035, 1.0)
	var edge := Rect2(Vector2.ONE * inset, area - Vector2.ONE * inset * 2.0)
	if medium != Medium.STITCH:
		var keyline := StyleBoxFlat.new()
		keyline.draw_center = false
		keyline.border_color = letters
		keyline.set_border_width_all(int(ceilf(line)))
		keyline.set_corner_radius_all(int(area.y * 0.1))
		keyline.draw(on.get_canvas_item(), edge)
		return
	var corners: Array[Vector2] = [
		edge.position,
		Vector2(edge.end.x, edge.position.y),
		edge.end,
		Vector2(edge.position.x, edge.end.y)
	]
	for i: int in 4:
		on.draw_dashed_line(corners[i], corners[(i + 1) % 4], letters, line, line * 3.0)
