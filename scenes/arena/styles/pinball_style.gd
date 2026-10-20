class_name PinballStyle
extends RoomStyle
## The Arcade, GAME.md 8.1c: the table is a pinball playfield the House printed, kept the way a
## careful restorer keeps a machine of the sixties rather than the way a new one shouts. The
## floor is the playfield under a satin coat, its art in plum, teal, ochre and cream with the
## House's layout laid over it ([PinballPrints]), lit a little from under by the machine's own
## bulbs; every pad, turbo plate and lane is set among the playfield's inserts, about half of
## them lit ([PinballInserts]); the inner walls are guides, a
## lacquered block in a ring of cream rubber round chrome posts with a screened plastic held
## over it on ochre spacers, a fan of cards, a pair of dice or a star, and the bulbs under it
## warming the coat round it; the boxes are drop targets, an ivory block in a steel slot with a
## card's rank on it; the pop bumpers of the map's threes are red caps over the chrome ring that
## kicks, lit when they fire; the pits are drains, a steel-lined hole with a ball waiting in
## it; the Junction is a roulette insert ringed with chase lamps and a pop bumper's cap on its
## spindle; and a Jackpot is a pile of chips under a clear dome on a lit pan. Round the table
## stands the rest of the machine ([PinballMachine]): its flippers below the near rail, its top
## lanes past the far one, its shooter lane down the right flank and its head behind the far
## crowd. The House's rail is still the outer wall, as on every table.
##
## The lamps are kept in hand, which is what keeps a machine this busy readable: half of the chase
## lamps and the inserts are dark, the lit ones glow rather than blaze, and nothing on the floor is
## brighter than a kart or a shot.

const WALNUT := Color("#4E2E20")
const CABINET := Color("#2A1E2C")
const STEEL := Color("#AEB2BA")
const DARK_STEEL := Color("#4F535B")
const RUBBER := Color("#E6DCC4")
const RED_RUBBER := Color("#A83A2C")
const PLASTIC := Color("#E6D9B8")
const PANEL := Color("#2B5A5C")
const OCHRE := Color("#C4943F")
const LACQUER := Color("#4A2B22")
const IVORY := Color("#EEE5D0")
const INK := Color("#141017")
const PLUM := Color("#4A2F50")
## The bulbs of the chase lamps round the wheel, of the bumpers' lenses and of the top lanes'
## inserts.
const BULB := Color("#FFD9A0")
const POCKET_RED := Color("#6C2E2B")
const POCKET_GREEN := Color("#2C6449")
## How far a guide's lacquered block stands in from its rubber and how tall the rubber is, round
## the block at the height a shot flies at; how far in the plastic stands, how thick it is and
## how high its spacers hold it over the block; and how thick a post is.
const RUBBER_IN := 0.12
const RUBBER_TALL := 0.16
const PLASTIC_IN := 0.05
const PLASTIC_TALL := 0.035
const SPACER := 0.06
const POST := 0.11
## The chips a Jackpot's pile is stacked from, never the coin pads' blue.
const PILE: Array[Color] = [
	Color("#B4473C"), Color("#E9DFC8"), Color("#C4943F"), Color("#5B3A63"), Color("#2E6B6C")
]
## How much the playfield's own print lights the coat, see [method _print_field].
const FIELD_GLOW := 2.1
## The clutter round the table, at the size a pinball's spares are beside a model this big.
const BALL := 0.7
## The machine round the table, see [method room_round].
const MACHINE := "res://scenes/arena/styles/pinball_machine.gd"

var _floor: StandardMaterial3D
## How many drop targets have been built, for the rank each one wears.
var _targets := 0
var _made: Dictionary[String, StandardMaterial3D] = {}


## A guide: a lacquered block in a ring of cream rubber at the height a shot strikes it, a chrome
## post at each corner with a red ring round it, and over it, on ochre spacers, a die-cut plastic
## screened with the machine's art, a fan of cards down a long guide, a pair of dice on a short
## one and a star on a post. The plastic's twin on the other side of the table is turned end for
## end, as a machine's plastics come in mirrored pairs. All of it inside the block's own box.
func wall(holder: Node3D, size: Vector3, index: int) -> bool:
	var foot := -size.y * 0.5
	var top := size.y * 0.5
	var long_x := size.x >= size.z
	var length := maxf(size.x, size.z)
	var depth := minf(size.x, size.z)
	var plastic_y := top - PLASTIC_TALL * 0.5
	# The block first and the plastic second, which share no plane, as every room's block and step.
	var under := plastic_y - PLASTIC_TALL * 0.5 - SPACER
	var body := Vector3(size.x - RUBBER_IN * 2.0, under - foot, size.z - RUBBER_IN * 2.0)
	ToyParts.box(holder, body, _satin(LACQUER), Vector3(0.0, (foot + under) * 0.5, 0.0))
	var plastic := Vector3(size.x - PLASTIC_IN * 2.0, PLASTIC_TALL, size.z - PLASTIC_IN * 2.0)
	ToyParts.box(holder, plastic, _satin(PLASTIC, 0.3), Vector3(0.0, plastic_y, 0.0))
	var keyline := Vector3(plastic.x + 0.03, 0.012, plastic.z + 0.03)
	ToyParts.box(holder, keyline, _satin(INK), Vector3(0.0, plastic_y - PLASTIC_TALL * 0.4, 0.0))
	# The plastic's screened face, the long way along the guide.
	var face := Vector2(length - PLASTIC_IN * 2.0, depth - PLASTIC_IN * 2.0)
	var uv := PinballPrints.plastic_uv(_plastic_kind(length, depth))
	var screened := ToyParts.quad(holder, face, uv, _plastics(), _up(top + 0.002))
	screened.rotation.y = (0.0 if long_x else PI * 0.5) + (PI if index % 2 == 1 else 0.0)
	ToyParts.flat(screened)
	# The ring of rubber round the posts at the height a shot strikes it.
	ToyParts.rounded(
		holder, Vector3(size.x, RUBBER_TALL, size.z), POST, _rubber(RUBBER), Vector3.ZERO, 8
	)
	# A chrome post at each corner inside the rubber, with a red ring round it over the rubber, an
	# ochre spacer under the plastic and a chrome nut over it.
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var at := Vector3((size.x * 0.5 - POST) * corner.x, 0.0, (size.z * 0.5 - POST) * corner.y)
		var post_at := at + _up((under + foot) * 0.5)
		ToyParts.cylinder(holder, POST * 0.7, under - foot, _steel(), post_at, 8)
		ToyParts.ring(holder, POST * 0.7, POST, _rubber(RED_RUBBER), at + _up(RUBBER_TALL), 8, 4)
		ToyParts.cylinder(holder, POST * 0.8, SPACER, _satin(OCHRE), at + _up(under + SPACER * 0.5))
		ToyParts.cylinder(holder, POST * 0.6, 0.04, _steel(), at + _up(top + 0.02), 8)
	return true


## Which of the plastics a guide [param length] by [param depth] wears.
func _plastic_kind(length: float, depth: float) -> PinballPrints.Plastic:
	if length >= depth * 3.0:
		return PinballPrints.Plastic.CARDS
	if length >= depth * 1.5:
		return PinballPrints.Plastic.DICE
	return PinballPrints.Plastic.STAR


## A drop target standing in its slot, inside its cube: a steel slot in the floor, an ivory target
## block standing up out of it and a card's rank on its top, A, K, Q, J and 10 across the field as
## a machine of the sixties has them. Shot, it drops, and it is back up when the box is. Three
## materials, the steel, the ivory and the sheet the faces are printed on.
func crate(holder: Node3D, size: Vector3) -> bool:
	var foot := -size.y * 0.5
	var slot := Vector3(size.x * 0.96, 0.05, size.z * 0.96)
	ToyParts.box(holder, slot, _satin(DARK_STEEL, 0.35), _up(foot + slot.y * 0.5))
	var block := Vector3(size.x * 0.84, size.y * 0.78, size.z * 0.84)
	ToyParts.rounded(holder, block, 0.06, _satin(IVORY, 0.4), _up(foot + block.y * 0.5), 6)
	var face := Vector2(block.x - 0.12, block.z - 0.12)
	var rank := (
		(PinballPrints.Plastic.TARGET_A + _targets % PinballPrints.TARGETS) as PinballPrints.Plastic
	)
	_targets += 1
	var print_at := _up(foot + block.y + 0.003)
	ToyParts.flat(
		ToyParts.quad(holder, face, PinballPrints.plastic_uv(rank), _plastics(), print_at)
	)
	return true


## A pop bumper, GAME.md 6.2, inside its cylinder: a chrome skirt on the floor round a chrome body,
## the ring that kicks round it at the height a shot flies at, so a shot meets the bumper where it
## meets a wall, and a red cap with the bulb under its cream lens, which is what lights when it
## fires, see [Bumper]. The map sets them out in threes, as a machine does. Three materials, the
## chrome, the red and the lens, which is the bumper's own so it lights alone.
func bumper(holder: Node3D, radius: float, _height: float) -> bool:
	var chrome := _steel()
	ToyParts.cylinder(holder, radius * 0.98, 0.04, chrome, _up(0.02), 16)
	ToyParts.cylinder(holder, radius * 0.6, 0.62, chrome, _up(0.35), 12)
	ToyParts.ring(holder, radius * 0.6, radius * 0.95, chrome, _up(0.5), 16, 4)
	ToyParts.cylinder(holder, radius * 0.92, 0.18, _rubber(RED_RUBBER), _up(0.75), 16)
	var lens := ToyParts.dome(holder, radius * 0.76, 0.12, _lamp(BULB, 0.4), _up(0.84), 16)
	lens.name = "Lamp"
	ToyParts.flat(lens)
	return true


## A drain: a steel lip round the hole, steel down its sides and a ball waiting at the bottom.
func pit(into: Node3D, size: Vector2) -> bool:
	var lip := 0.16
	for side: int in 4:
		var along := side % 2 == 0
		var out := ((size.y if along else size.x) * 0.5 + lip * 0.5) * (1.0 if side < 2 else -1.0)
		var run := Vector3(size.x + lip * 2.0, 0.012, lip) if along else Vector3(lip, 0.012, size.y)
		var at := Vector3(0.0, 0.007, out) if along else Vector3(out, 0.007, 0.0)
		ToyParts.flat(ToyParts.box(into, run, _steel(), at))
		var deep := Arena.PIT_DEPTH * 0.8
		var inside := ((size.y if along else size.x) * 0.5 - 0.03) * (1.0 if side < 2 else -1.0)
		var plate := (
			Vector3(size.x - 0.06, deep, 0.03) if along else Vector3(0.03, deep, size.y - 0.06)
		)
		var down := -0.03 - deep * 0.5
		var plate_at := Vector3(0.0, down, inside) if along else Vector3(inside, down, 0.0)
		ToyParts.box(into, plate, _satin(DARK_STEEL, 0.35), plate_at)
	var radius := minf(size.x, size.y) * 0.17
	var rest := Vector3(
		rng.randf_range(-0.2, 0.2) * size.x,
		-Arena.PIT_DEPTH + radius,
		rng.randf_range(-0.2, 0.2) * size.y
	)
	ToyParts.ball(into, radius, _chrome(), rest, 16)
	return true


## The Junction as a roulette insert let into the playfield: a walnut rim with chase lamps round
## it, muted pockets, a cream ball track, a plum turntable with ochre spokes and the red cap of a
## pop bumper domed on its spindle. All of it low, for the karts to bank on. Its call to attention,
## GAME.md 3.4, is a pinball machine's own: the chase lamps run round the rim, quicker the more is
## at stake, the cap flashes and the turntable spins, see [method _chase_lamps] and [method
## _spinning_disc]; with nothing at stake the lamps and the cap glow softly and hold still.
func junction(into: Node3D, radius: float, cue: JunctionCue) -> bool:
	var pad := RoomKit.PAD
	var layer := RoomKit.LAYER
	var face := radius - RoomKit.RIM
	ToyParts.flat(ToyParts.disc(into, face, _satin(WALNUT, 0.4), pad * 0.5, pad, 48))
	_chase_lamps(into, face, cue)
	var outer := face - 0.26
	var inner := radius * 0.5
	var deep := outer - inner
	var pockets := RoomKit.POCKETS
	for i: int in pockets:
		var turn := TAU * float(i) / float(pockets)
		var ink := (
			_satin(POCKET_GREEN, 0.4) if i == 0 else _satin(POCKET_RED if i % 2 == 1 else INK, 0.4)
		)
		var lift := pad + layer + (layer * 0.25 if i % 2 == 1 else 0.0)
		var at := Vector3(sin(turn), 0.0, cos(turn)) * (inner + deep * 0.5)
		var wide := TAU * (inner + deep * 0.5) / float(pockets) * 1.12
		var pocket := ToyParts.box(into, Vector3(wide, 0.01, deep), ink, at + _up(lift))
		pocket.rotation.y = turn
		ToyParts.flat(pocket)
	ToyParts.flat(ToyParts.disc(into, inner, _lamp(PLASTIC, 0.25), pad + layer * 2.0, 0.01, 48))
	ToyParts.flat(ToyParts.disc(into, inner - 0.12, _satin(PLUM, 0.4), pad + layer * 3.0, 0.01, 48))
	_spinning_disc(into, inner, cue)
	# The pop bumper's cap on the spindle, kept low enough for a kart to bank over it.
	ToyParts.flat(ToyParts.disc(into, 0.36, _steel(), pad + layer * 5.0, 0.02, 24))
	var cap := _up(pad + layer * 5.0 + 0.01)
	var red := Color("#D2483A")
	var lens := cue.pulse_lamp(red.darkened(0.25), 0.0, red.darkened(0.35))
	ToyParts.flat(ToyParts.dome(into, 0.27, 0.1, lens, cap, 16))
	return true


## A pile of chips under a clear dome on a lit amber pan, the chips round its edge so the count
## painted in the middle of the tile still shows through the glass, and as many of them as the
## Jackpot is full, [JackpotPile].
func jackpot(into: Node3D, size: Vector2) -> bool:
	var reach := minf(size.x, size.y) * 0.42
	var pan := 0.085
	ToyParts.flat(ToyParts.disc(into, reach, _lamp(Color("#E0A040"), 0.45), pan, 0.01, 32))
	ToyParts.flat(ToyParts.ring(into, reach - 0.04, reach + 0.03, _steel(), _up(pan + 0.01), 32))
	var stacks := 7
	var pile := JackpotPile.on(into)
	for i: int in stacks:
		var turn := TAU * (float(i) + rng.randf_range(-0.15, 0.15)) / float(stacks)
		var at := Vector3(sin(turn), 0.0, cos(turn)) * reach * 0.66 + _up(pan + 0.005)
		var high := rng.randi_range(3, 7)
		var stack := pile.stack()
		for chip: int in high:
			var ink: Color = PILE[(i + chip) % PILE.size()]
			var piece := ToyParts.cylinder(
				stack,
				0.17,
				0.045,
				surfaces.printed(Surfaces.CHIP_FACE, ink),
				at + _up(0.0225 + 0.045 * float(chip)),
				12
			)
			piece.position.x += rng.randf_range(-0.015, 0.015)
	var glass := ToyParts.dome(into, reach + 0.02, 0.36, _glass(), _up(pan + 0.005), 24)
	ToyParts.flat(glass)
	return true


func floor_top() -> StandardMaterial3D:
	if _floor == null:
		_floor = StandardMaterial3D.new()
		_floor.albedo_color = PinballPrints.GROUND
		# Satin, not a mirror: the lamp a soft sheen across the coat rather than a hot spot, so
		# the print reads through it everywhere, the inserts included.
		_floor.roughness = 0.64
		_floor.metallic_specular = 0.38
		_floor.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		# The coat over the print, on the renderer that can afford one: thin and soft.
		if Settings.full_renderer():
			_floor.clearcoat_enabled = true
			_floor.clearcoat = 0.12
			_floor.clearcoat_roughness = 0.7
	return _floor


## The cabinet the playfield is set in, where the crowd stands: painted the dark plum of a
## machine's cabinet under a satin varnish, the grain of the wood just showing through it.
func surround() -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = CABINET
	paint.albedo_texture = Surfaces.WOOD_ALBEDO
	paint.normal_enabled = true
	paint.normal_texture = Surfaces.WOOD_NORMAL
	paint.normal_scale = 0.2
	paint.uv1_scale = Vector3.ONE / Surfaces.WOOD_TILE
	paint.roughness = 0.5
	paint.metallic_specular = 0.45
	return paint


## The arcade the machine stands in, dark past the table: the playfield's art drawn from the map,
## its inserts set round the pads, the cabinet's edge and its chrome legs, the machine's head
## behind the far crowd with its backglass lit, and a pinball's spares laid out round the table.
func room_round(props: RoomProps) -> bool:
	var arena := props.arena
	_print_field(arena)
	_print_plastics(arena)
	load(MACHINE).new(self, props).lay()
	return true


func layout_inks() -> Array[Color]:
	return [Color("#C79A45"), Color("#E3D5B2")]


## The playfield's art, sharp, under the House's layout, GAME.md 8.1c: the picture a player sees
## of the floor, at the layout's own size and smoothed as it is, see [constant LayoutPrint.SMOOTH].
func print_under(on: LayoutPrint) -> void:
	PinballPrints.draw_field(on, on.grid, LayoutPrint.CELL_PIXELS)


## Draws the playfield's art soft for this map and lays it on the floor, corner to corner over the
## arena as the layout is, once it has been drawn: the light the coat gives back of its print, and
## its picture until the layout's sharp one is drawn over it, see [method print_under]. A few
## pixels a cell, [constant PinballPrints.CELL_PIXELS], since a glow wants no more.
func _print_field(arena: Arena) -> void:
	var across := arena.world_size()
	var field := floor_top()
	field.uv1_scale = Vector3(1.0 / across.x, 1.0 / across.y, 1.0)
	field.uv1_offset = Vector3(0.5, 0.5, 0.0)
	DrawnTexture.kept(
		arena,
		PinballPrints.field(arena.grid),
		PinballPrints.field_pixels(arena.grid),
		func(texture: Texture2D) -> void:
			field.albedo_color = Color.WHITE
			field.albedo_texture = texture
			# The machine's own bulbs light the coat from under the plastics, a little and
			# evenly, so the field reads past the reach of the room's lamp.
			field.emission_enabled = true
			field.emission = PinballPrints.COAT_GLOW
			field.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			field.emission_texture = texture
			field.emission_energy_multiplier = FIELD_GLOW,
		LayoutPrint.SMOOTH
	)


## Draws the sheet of plastics the guides wear and puts it on them, under [param arena] as the
## floor's is.
func _print_plastics(arena: Arena) -> void:
	var screened := _plastics()
	DrawnTexture.kept(
		arena,
		PinballPrints.plastics(),
		PinballPrints.PLASTICS_PIXELS,
		func(texture: Texture2D) -> void:
			screened.albedo_color = Color.WHITE
			screened.albedo_texture = texture,
		LayoutPrint.SMOOTH
	)


func _up(lift: float) -> Vector3:
	return Vector3(0.0, lift, 0.0)


# --- the materials ---------------------------------------------------------------


## Satin: the lacquer, the plastics and the ivory, each with a soft highlight and no mirror in it.
func _satin(color: Color, roughness := 0.45) -> StandardMaterial3D:
	var key := "satin%s%.2f" % [color.to_html(false), roughness]
	if not _made.has(key):
		var paint := StandardMaterial3D.new()
		paint.albedo_color = color
		paint.roughness = roughness
		paint.metallic_specular = 0.5
		_made[key] = paint
	return _made[key]


## Rubber: matte, with the barest sheen.
func _rubber(color: Color) -> StandardMaterial3D:
	var key := "rubber" + color.to_html(false)
	if not _made.has(key):
		var band := StandardMaterial3D.new()
		band.albedo_color = color
		band.roughness = 0.8
		band.metallic_specular = 0.25
		_made[key] = band
	return _made[key]


## Satin steel: the posts, the rails and the lip of a drain. Light rather than metal, since a
## dark room gives a metal nothing to show but the dark.
func _steel() -> StandardMaterial3D:
	if not _made.has("steel"):
		var steel := StandardMaterial3D.new()
		steel.albedo_color = STEEL
		steel.metallic = 0.35
		steel.roughness = 0.32
		steel.metallic_specular = 0.7
		_made["steel"] = steel
	return _made["steel"]


## The chrome of a ball, brighter than the steel and with a hard highlight.
func _chrome() -> StandardMaterial3D:
	if not _made.has("chrome"):
		var chrome := StandardMaterial3D.new()
		chrome.albedo_color = Color("#B4B9C2")
		chrome.metallic = 0.7
		chrome.roughness = 0.24
		chrome.metallic_specular = 0.6
		chrome.rim_enabled = true
		chrome.rim = 0.5
		chrome.rim_tint = 0.3
		_made["chrome"] = chrome
	return _made["chrome"]


## A lamp under plastic: lit from inside at [param energy], kept low so a shot outshines it.
func _lamp(color: Color, energy: float) -> StandardMaterial3D:
	var key := "lamp%s%.2f" % [color.to_html(false), energy]
	if not _made.has(key):
		var lit := StandardMaterial3D.new()
		lit.albedo_color = color.darkened(0.25)
		lit.roughness = 0.35
		lit.emission_enabled = true
		lit.emission = color
		lit.emission_energy_multiplier = energy
		_made[key] = lit
	return _made[key]


## The screened face of every guide's plastic, see [method wall]: the plastic's teal until the
## sheet has been drawn, by [method _print_plastics], and then its print.
func _plastics() -> StandardMaterial3D:
	if not _made.has("plastics"):
		var screened := StandardMaterial3D.new()
		screened.albedo_color = PANEL
		screened.roughness = 0.3
		screened.metallic_specular = 0.5
		screened.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_made["plastics"] = screened
	return _made["plastics"]


## The clear dome over a Jackpot's pile: a glint of glass and little else.
func _glass() -> StandardMaterial3D:
	if not _made.has("glass"):
		var clear := StandardMaterial3D.new()
		clear.albedo_color = Color(0.85, 0.9, 0.95, 0.16)
		clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		clear.roughness = 0.08
		clear.metallic_specular = 0.9
		clear.rim_enabled = true
		clear.rim = 0.6
		clear.rim_tint = 0.0
		_made["glass"] = clear
	return _made["glass"]


## The House's word, STORY.md 6.1: lit on the machine's score display, the dot matrix in the panel
## under its backglass, where the shot a match opens on looks past the far crowd.
func house_word(word: HouseWord, arena: Arena) -> bool:
	var back := -(arena.world_size().y * 0.5 + RoomBuild.BACK_FAR + RoomBuild.BACK_WALL)
	var at := Vector3(0.0, RoomBuild.TOP + 1.9, back + 2.04)
	word.lay(at, Vector2(12.0, 2.8), BULB, HouseWord.Medium.DOTS, Basis.IDENTITY, 1.0, INK)
	return true


## What a pinball machine's glass keeps off its playfield and its floor does not, GAME.md 8.1c: a
## ball that drained and rolled away, gone dull; a quarter; and a strip of prize tickets torn off.
func litter(into: Node3D, which: int, _dice: RandomNumberGenerator) -> bool:
	match which % 3:
		0:
			var ball := RoomStyle.bead(0.055, 12)
			dropped(into, ball, STEEL, _up(0.055), Vector3.ZERO, true)
		1:
			dropped(into, RoomStyle.rod(0.1, 0.012, 14), STEEL, _up(0.006), Vector3.ZERO, true)
			var face := RoomStyle.rod(0.082, 0.016, 14)
			dropped(into, face, STEEL.darkened(0.2), _up(0.008), Vector3.ZERO, true)
		_:
			for i: int in 3:
				var at := Vector3((float(i) - 1.0) * 0.13, 0.0, 0.0)
				var turn := Vector3(0.0, (float(i) - 1.0) * 0.12, 0.0)
				var ticket := RoomStyle.slab(Vector3(0.124, 0.006 + i * 0.001, 0.09))
				dropped(into, ticket, OCHRE, at + _up(0.003), turn)
				var words := RoomStyle.slab(Vector3(0.07, 0.004, 0.012))
				dropped(into, words, IVORY, at + _up(0.007 + i * 0.001), turn)
	return true


## The chase lamps round the Junction's walnut rim of [param face], lit by [param cue] in three
## sets, a lamp in three, running round as a playfield's chase does; with nothing at stake every
## one of them glows softly and still, as an insert does between balls.
func _chase_lamps(into: Node3D, face: float, cue: JunctionCue) -> void:
	var lamps := 24
	cue.lit = BULB
	cue.glow = 1.9
	cue.rest_glow = 0.25
	cue.steps = Vector2(4.0, 14.0)
	var inserts := cue.chase_lamps(3, BULB.darkened(0.55))
	for i: int in lamps:
		var turn := TAU * (float(i) + 0.5) / float(lamps)
		var at := Vector3(sin(turn), 0.0, cos(turn)) * (face - 0.13)
		var insert := inserts[i % 3]
		ToyParts.flat(
			ToyParts.cylinder(into, 0.11, 0.01, insert, at + _up(RoomKit.PAD + RoomKit.LAYER), 8)
		)


## The plum turntable's four ochre spokes inside [param inner], on a pivot of their own put in
## [param cue], spinning as a playfield's spinning disc does.
func _spinning_disc(into: Node3D, inner: float, cue: JunctionCue) -> void:
	cue.spin = 0.45
	var disc := Node3D.new()
	disc.name = "Spinner"
	into.add_child(disc)
	for i: int in 4:
		var spoke := ToyParts.box(
			disc,
			Vector3(0.08, 0.01, (inner - 0.16) * 2.0),
			_satin(OCHRE, 0.3),
			_up(RoomKit.PAD + RoomKit.LAYER * 4.0)
		)
		spoke.rotation.y = PI * 0.25 + PI * 0.5 * float(i)
		ToyParts.flat(spoke)
	cue.turning(disc)
