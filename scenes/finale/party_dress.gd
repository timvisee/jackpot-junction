class_name PartyDress
extends RefCounted
## What the House's party is built of in the room a Grand Prix ended in, GAME.md 9.7: the room's
## own materials and palette for the House's podium and the stage behind it, so a run that ended in
## the Arcade has a party of a pinball machine's teal panels, cream plastics and rubber, its floor's
## lamps round as a playfield's inserts, one in the Workbench a party of Kit's maple and walnut, and
## one after a showdown a party of High Limit's lacquer, ivory and chrome, while the shape of the
## podium, its tickets and the House's rail round the floor are the House's own in every room, see
## [GrandPrixFinale].
##
## Read off the room's style rather than asked of it: a style that keeps a textured material of its
## own, Kit's grained maple, After Hours' flutes or the Yard's corrugated steel, lends it, and
## everything else is plain paint in the style's own colors, so the party draws only shaders the
## room has already compiled, GAME.md 10.7. A room with no style dresses its party in its palette.

## How rough the plain paint of the party is, satin, and how much it shines.
const SATIN := 0.5
const SHEEN := 0.42

## The darkest a hall's walls are let be, as a luminance, and how much lighter one darker than that
## is made.
const HALL_LEAST := 0.12
const HALL_LIFT := 0.1

## What the steps of the podium are built of, on a box.
var body: Material
## What the riser the booth stands on and the booth's speakers are built of, on a box: darker than
## the steps, so they stand out against it.
var base: Material
## The ticket each step's top is cut from, in plain paint, see [method Bake.tinted].
var cap := Color("#1B1A22")
## The room's metal: the speakers' cones, and the piping under a step's ticket unless the room
## pipes it in something of its own, [member trim].
var metal: Material
var trim: Material
## The dance floor: the room's floor color, and the tiles let into it a shade off it, as the
## House's pads are, GAME.md 8.1c.
var ground := Color("#2F5D45")
var tile := Color("#2F5D45")
## The hall's walls over the room's material along their foot, in the room's own wall color, as
## the room round its table has it, GAME.md 8.1c.
var hall_wall := Color(0.25, 0.22, 0.19)
## Whether the floor's lamps are round, as a pinball playfield's inserts are, rather than square.
var round := false


## The dress for [param room], read off [param surfaces]' style.
static func of(room: RoomLook, surfaces: Surfaces) -> PartyDress:
	var dress := PartyDress.new()
	dress.ground = room.felt.darkened(0.45)
	dress.tile = room.felt.darkened(0.12)
	var style := surfaces.style
	if style is WorkbenchStyle:
		var kit := style as WorkbenchStyle
		dress.body = kit.wood(WorkbenchStyle.MAPLE)
		dress.base = kit.wood(WorkbenchStyle.WALNUT)
		dress.cap = WorkbenchStyle.WALNUT
		dress.metal = kit.metal(WorkbenchStyle.BRASS)
		dress.hall_wall = Color(0.25, 0.22, 0.19)
	elif style is VaultStyle:
		var deco := style as VaultStyle
		dress.body = deco.fluted()
		dress.base = deco.lacquer()
		dress.cap = VaultStyle.LACQUER
		dress.metal = deco.metal(VaultStyle.BRASS)
		dress.hall_wall = Color(0.13, 0.06, 0.09)
	elif style is HighLimitStyle:
		dress.body = plain(HighLimitStyle.LACQUER)
		dress.base = plain(HighLimitStyle.LACQUER.darkened(0.2))
		dress.cap = HighLimitStyle.IVORY
		dress.metal = shiny(HighLimitStyle.CHROME)
		dress.hall_wall = HighLimitSalon.WALLS
	elif style is PinballStyle:
		# A machine's teal panels under cream plastics, piped in the cream rubber of its guides.
		dress.body = plain(PinballStyle.PANEL)
		dress.base = plain(PinballStyle.CABINET)
		dress.cap = PinballStyle.PLASTIC
		dress.metal = shiny(PinballStyle.STEEL)
		dress.trim = plain(PinballStyle.RUBBER, 0.8)
		dress.round = true
		dress.hall_wall = Color("#1A1220")
	elif style is YardStyle:
		dress.body = (style as YardStyle).corrugated(YardStyle.RUST)
		dress.base = plain(YardStyle.IRON)
		dress.cap = YardStyle.CONCRETE
		dress.metal = shiny(YardStyle.STEEL)
		dress.hall_wall = Color(0.33, 0.31, 0.28)
	elif style is GarageStyle:
		dress.body = (style as GarageStyle).cabinet(GarageStyle.CABINET)
		dress.base = plain(GarageStyle.DARK)
		dress.cap = GarageStyle.WORKTOP
		dress.metal = shiny(GarageStyle.STEEL)
		dress.hall_wall = Color(0.42, 0.45, 0.49)
	elif style is StitchStyle:
		dress.body = plain(StitchStyle.OATMEAL, 0.9)
		dress.base = plain(StitchStyle.PLUM, 0.9)
		dress.cap = StitchStyle.PLUM
		dress.metal = shiny(StitchStyle.STEEL)
		dress.hall_wall = Color("#3A2E2A")
	elif style is PlaysetStyle:
		dress.body = plain(PlaysetStyle.CREAM)
		dress.base = plain(PlaysetStyle.DEEP)
		dress.cap = PlaysetStyle.PLUM
		dress.metal = plain(PlaysetStyle.OCHRE)
		dress.hall_wall = Color("#3B3036")
	elif style is SchoolStyle:
		dress.body = plain(SchoolStyle.DEPARTMENT)
		dress.base = plain(SchoolStyle.ROAD)
		dress.cap = SchoolStyle.PAINT
		dress.metal = shiny(Color(0.64, 0.67, 0.71))
		dress.hall_wall = RoadMat.HALL_WALL
	else:
		dress.body = plain(room.wall)
		dress.base = plain(room.wall_edge.darkened(0.3))
		dress.cap = room.marking.darkened(0.4)
		dress.metal = shiny(room.trim)
		dress.hall_wall = room.table.darkened(0.5)
	if dress.trim == null:
		dress.trim = dress.metal
	# The arena's walls are far off in the dark past its table; the party's are close by, and a
	# room as dark as the Arcade's would leave the hall black.
	if dress.hall_wall.get_luminance() < HALL_LEAST:
		dress.hall_wall = dress.hall_wall.lightened(HALL_LIFT)
	return dress


## Plain paint in [param color], satin unless [param roughness] says otherwise: the one shader
## every plain thing in the game is drawn with.
static func plain(color: Color, roughness := SATIN) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	paint.roughness = roughness
	paint.metallic_specular = SHEEN
	return paint


## Metal in [param color], satin rather than polished: a dark room gives a mirror nothing to show.
static func shiny(color: Color) -> StandardMaterial3D:
	var steel := plain(color, 0.36)
	steel.metallic = 0.6
	return steel
