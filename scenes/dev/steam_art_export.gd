extends "res://scenes/dev/key_art.gd"
## Renders the pictures Steamworks asks for, docs/STEAM.md, into build/steam-art and quits, which is
## what `make steam-art` runs, each named after its field on Steamworks: the store's capsules and
## its page's background, the library's capsule, header, hero and logo, the icons, the avatars, the
## description's headings and pictures, and an announcement's cover and header. They are the game's
## own pieces, see key_art.gd, so they follow the game as it changes. The screenshots come from
## tools/screenshots.
##
## `-- --only=header,hero` renders those alone: the names of [constant SHOTS], or background, logo,
## icons, avatars, headings and pictures.

const OUT := "res://build/steam-art"
## The description's headings and pictures, kept with the words they go with too: docs/STEAM.md
## and docs/ITCH.md show them, and itch.io's page wears them as well.
const DESCRIBED := "res://docs/description"
## How many times over the pictures are drawn, scaled down after so their edges are smooth.
const OVER := 2

## Every picture of the table: its file, its size, how many times over it is drawn if not
## [constant OVER], the camera [eye, at, fov, fov across, focus], see [method look], the seal and
## the name over it if any [mark, name size, gap, stacked, middle as a share of the picture], see
## [method lockup], and the bands of stock that keep them legible, each [ink, hold, held, from, to,
## rect as shares], see [method band].
const SHOTS: Dictionary[String, Dictionary] = {
	"header":
	{
		"file": "store/header_capsule.png",
		"size": Vector2i(920, 430),
		"camera": [Vector3(0.0, 5.2, 10.0), Vector3(0.0, 0.6, 0.5), 42.0, false],
		"lockup": [150.0, 80, 18.0, false, Vector2(0.5, 0.23)],
		"bands": [[0.92, 0.45, 0.7, Vector2(0.5, 0.0), Vector2(0.5, 1.0), Rect2(0, 0, 1, 0.6)]],
	},
	"small":
	{
		"file": "store/small_capsule.png",
		"size": Vector2i(462, 174),
		"camera": [Vector3(0.0, 5.2, 10.0), Vector3(0.0, 0.6, 0.5), 42.0, false],
		"lockup": [138.0, 66, 14.0, false, Vector2(0.5, 0.5)],
		"bands": [[0.8, 0.5, 0.72, Vector2(0.5, 0.0), Vector2(0.5, 1.0), Rect2(0, 0, 1, 1)]],
	},
	"main":
	{
		"file": "store/main_capsule.png",
		"size": Vector2i(1232, 706),
		"camera": [Vector3(0.0, 5.2, 10.0), Vector3(0.0, 0.6, 0.5), 42.0, false],
		"lockup": [190.0, 104, 22.0, false, Vector2(0.5, 0.2)],
		"bands": [[0.92, 0.45, 0.7, Vector2(0.5, 0.0), Vector2(0.5, 1.0), Rect2(0, 0, 1, 0.55)]],
	},
	"vertical":
	{
		"file": "store/vertical_capsule.png",
		"size": Vector2i(748, 896),
		"camera": [Vector3(0.0, 8.5, 9.5), Vector3(0.0, 0.0, -3.8), 50.0, true],
		"lockup": [178.0, 87, 0.0, true, Vector2(0.5, 0.235)],
		"bands": [[0.95, 0.55, 0.8, Vector2(0.5, 0.0), Vector2(0.5, 1.0), Rect2(0, 0, 1, 0.54)]],
	},
	"library_capsule":
	{
		"file": "library/library_capsule.png",
		"size": Vector2i(600, 900),
		"camera": [Vector3(0.0, 9.0, 9.0), Vector3(0.0, 0.0, -4.5), 48.0, true],
		"lockup": [180.0, 84, 0.0, true, Vector2(0.5, 0.24)],
		"bands": [[0.95, 0.55, 0.8, Vector2(0.5, 0.0), Vector2(0.5, 1.0), Rect2(0, 0, 1, 0.58)]],
	},
	"library_header":
	{
		"file": "library/library_header.png",
		"size": Vector2i(920, 430),
		"camera": [Vector3(0.0, 5.2, 10.0), Vector3(0.0, 0.6, 0.5), 42.0, false],
		"lockup": [150.0, 80, 18.0, false, Vector2(0.5, 0.23)],
		"bands": [[0.92, 0.45, 0.7, Vector2(0.5, 0.0), Vector2(0.5, 1.0), Rect2(0, 0, 1, 0.6)]],
	},
	# No words: Steam lays the logo over it, on its left, so the table sits a little right of the
	# middle with a shade on the left for the logo, and the room behind is blurred past reading.
	"hero":
	{
		"file": "library/library_hero.png",
		"size": Vector2i(3840, 1240),
		"over": 1,
		"camera":
		[
			Vector3(-2.0, 5.6, 12.5),
			Vector3(-2.0, 0.2, 0.0),
			30.0,
			false,
			Vector3(17.0, 5.0, 0.14),
		],
		"bands": [[0.7, 0.4, 0.4, Vector2(0.0, 0.5), Vector2(1.0, 0.5), Rect2(0, 0, 0.5, 1)]],
	},
	"event_cover":
	{
		"file": "event/event_cover.png",
		"size": Vector2i(800, 450),
		"camera": [Vector3(1.0, 4.0, 9.0), Vector3(0.6, 0.6, 2.0), 40.0, false],
	},
	"event_header":
	{
		"file": "event/event_header.png",
		"size": Vector2i(1920, 622),
		"camera":
		[
			Vector3(0.0, 5.6, 12.5),
			Vector3(0.0, 0.2, 0.0),
			30.0,
			false,
			Vector3(17.0, 5.0, 0.14),
		],
	},
}

## The store page's background: what is behind the title screen, its burst high behind the page's
## column. Steam lays a template of its own over it.
const BACKGROUND := Vector2i(1438, 810)
const BACKGROUND_FOCUS := Vector2(0.5, 0.2)
const BACKGROUND_MARK := 200.0
## The library's logo, laid over the hero: as big as it may be inside this, on nothing.
const LOGO := Vector2i(1280, 720)
## The icons: the mark on nothing at each size, the seal from [constant SEAL_FROM] up and the foil
## chip under it, drawn over and brought down so the seal is drawn there rather than the chip, see
## [constant LogoArt.SMALL]; the same in a shortcut's icon files, Windows' [constant ICO], macOS'
## [constant ICNS] and Linux' [constant LINUX], and one picture of [constant SHORTCUT], which the
## library's list wears for a game installed from them; and the app's icon, the list's fallback, a
## JPEG, so on the engraved stock, as an app's icon is the square of its own: the foil chip as big
## as it goes, since the list draws it 20 pixels across.
const ICONS: Array[int] = [16, 24, 32, 48, 64, 96, 128, 256, 512, 1024]
const ICO: Array[int] = [16, 24, 32, 48, 64, 128, 256]
## Each picture in Apple's icon file, its kind and its side: 16, 32, 128, 256 and 512 points, once
## and twice over. Without it, a shortcut on macOS wears Steam's own logo.
const ICNS: Array[Array] = [
	["icp4", 16],
	["ic11", 32],
	["icp5", 32],
	["ic12", 64],
	["ic07", 128],
	["ic13", 256],
	["ic08", 256],
	["ic14", 512],
	["ic09", 512],
	["ic10", 1024],
]
## The sides in the ZIP for Linux, each a PNG named after its side, which Steam puts in the
## desktop's icon theme for a shortcut and the library's list wears for the Linux build. Without it,
## a shortcut there has no icon at all and the list wears the app's icon.
const LINUX: Array[int] = [16, 24, 32, 48, 64, 96, 128, 256, 512]
const SHORTCUT := 512
const SEAL_FROM := 64
const APP_ICON := 184

## The avatars, each on a sunburst in a seat's color, or the foil's for -1, numbered in this order:
## the seal, drivers and a kart, chips, the multiplier die, achievements, jokers and the house's
## card back.
const AVATAR := 184
const AVATARS: Array[Dictionary] = [
	{"name": "seal", "seat": -1, "seal": true},
	{"name": "driver_red", "seat": 0, "driver": {"paint": 5, "hat": 2, "body": 0}},
	{"name": "driver_blue", "seat": 1, "driver": {"paint": 1, "hat": 3, "body": 0}},
	{"name": "driver_green", "seat": 3, "driver": {"paint": 2, "hat": 6, "body": 0}},
	{"name": "driver_pink", "seat": 7, "driver": {"paint": 7, "hat": 4, "body": 0}},
	{"name": "kart", "seat": 5, "kart": {"paint": 6, "hat": 8, "flag": 3, "body": 0}},
	{"name": "chip_stack", "seat": 3, "stack": true},
	{"name": "gold_chip", "seat": -1, "chip": true},
	{"name": "chip_flat", "seat": 3, "flat_chip": Color("#d23a32"), "text": ""},
	{"name": "chip_hundred", "seat": 5, "flat_chip": Color("#24222b"), "text": "100"},
	{"name": "die", "seat": 1, "die": true},
	{"name": "terms_accepted", "seat": 1, "achievement": &"terms_accepted"},
	{"name": "dressed_to_the_nines", "seat": 0, "achievement": &"dressed_to_the_nines"},
	{"name": "beat_the_house", "seat": 4, "achievement": &"beat_the_house"},
	{"name": "most_valued_member", "seat": 2, "achievement": &"most_valued_member"},
	{"name": "clean_sweep", "seat": 2, "achievement": &"clean_sweep"},
	{"name": "royal_court", "seat": 0, "joker": &"royal_court"},
	{"name": "aimbot", "seat": 6, "joker": &"aimbot"},
	{"name": "road_rage", "seat": 1, "joker": &"road_rage"},
	{"name": "wild_card", "seat": 4, "joker": &"wild_card"},
	{"name": "card_back", "seat": 6, "card_back": true},
]
## The seats whose colors the candidates' sunbursts take in turn, see [method _candidates].
const CANDIDATE_SEATS: Array[int] = [1, 3, 4, 6, 2, 7, 5, 0]
## How high the camera looks at a driver, at the face under the hat, in meters off the felt.
const DRIVER_AT := 1.1

## The description's headings, docs/ITCH.md's own, as wide as Steam's column of words, and its
## pictures under them.
const HEADING := Vector2i(616, 96)
const HEADING_TEXT := 46
const HEADINGS: Dictionary[String, String] = {
	"heading_how_the_cards_roll": "How the cards roll",
	"heading_whats_in_the_deck": "What's in the deck, you ask?",
	"heading_never_play_alone": "You never play cards alone. Or do you?",
	"heading_your_ride": "Your ride, your way",
}
const PICTURE := 616
## How tall a hand of cards is, and how much of it a card is.
const HAND := 240
const CARD := 0.66
const PICTURE_JOKERS: Array[StringName] = [
	&"loaded_dice", &"curve_ball", &"pickpocket", &"guardian_angel", &"wild_card"
]
const PICTURE_ITEMS: Array[StringName] = [&"rocket", &"shield", &"bomb", &"turret", &"decoy_kart"]
const PICTURE_KARTS: Array[Dictionary] = [
	{"seat": 3, "style": {"paint": 3, "hat": 8, "flag": 7, "body": 2}},
	{"seat": 1, "style": {"paint": 6, "hat": 3, "flag": 1, "body": 1}},
	{"seat": 0, "style": {"paint": 5, "hat": 2, "flag": 3, "body": 0}},
	{"seat": 4, "style": {"paint": 4, "hat": 10, "flag": 4, "body": 3}},
	{"seat": 7, "style": {"paint": 7, "hat": 15, "flag": 5, "body": 0}},
]

var _only: PackedStringArray = []


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",", false)
	for folder: String in ["", "/store", "/library", "/client", "/community", "/description"]:
		make_out(OUT + folder)
	make_out(OUT + "/event")
	make_out(DESCRIBED)
	for shot: String in SHOTS:
		if _wanted(shot):
			var spec := SHOTS[shot]
			save(await _shot(spec), OUT + "/" + spec["file"], spec["size"])
	if _wanted("background"):
		save(
			await backdrop(BACKGROUND, BACKGROUND_FOCUS, BACKGROUND_MARK),
			OUT + "/store/page_background.png",
			BACKGROUND
		)
	if _wanted("logo"):
		await _logo()
	if _wanted("icons"):
		await _icons()
	if _wanted("avatars"):
		for i: int in AVATARS.size():
			var spec := AVATARS[i]
			save(
				await _avatar(spec),
				OUT + "/community/avatar_%02d_%s.jpg" % [i + 1, spec["name"]],
				Vector2i.ONE * AVATAR,
				0.95
			)
	if _wanted("headings"):
		for heading: String in HEADINGS:
			_described(
				await _heading(HEADINGS[heading], HEADINGS.keys().find(heading)),
				"%s.png" % heading,
				HEADING
			)
	if OS.get_cmdline_user_args().has("--candidates"):
		await _candidates()
	if _wanted("pictures"):
		await _pictures()
	get_tree().quit()


func _wanted(name_of: String) -> bool:
	return _only.is_empty() or _only.has(name_of)


## With `-- --candidates`, every achievement as an avatar, its pins first, then every joker, into
## build/steam-art/candidates, for picking the avatars from.
func _candidates() -> void:
	make_out(OUT + "/candidates")
	var specs: Array[Dictionary] = []
	var pins: Array[Dictionary] = []
	for each: Achievement in Achievements.all():
		var spec := {"name": "achievement_" + each.id, "achievement": each.id}
		if each.is_pin():
			pins.append(spec)
		else:
			specs.append(spec)
	specs = pins + specs
	for joker: Joker in CatalogDialog.jokers_in_order():
		specs.append({"name": "joker_" + joker.id, "joker": joker.id})
	for i: int in specs.size():
		var spec := specs[i]
		spec["seat"] = CANDIDATE_SEATS[i % CANDIDATE_SEATS.size()]
		save(
			await _avatar(spec),
			OUT + "/candidates/%03d_%s.jpg" % [i + 1, spec["name"]],
			Vector2i.ONE * AVATAR,
			0.95
		)


## The table with the karts round its Junction as [param spec] has it.
func _shot(spec: Dictionary) -> Image:
	var over: int = spec.get("over", OVER)
	var size: Vector2i = spec["size"] * over
	var world := stage(size)
	var viewport: SubViewport = world["viewport"]
	var camera: Array = spec["camera"]
	var focus: Vector3 = camera[4] if camera.size() > 4 else Vector3.ZERO
	look(world, camera[0], camera[1], camera[2], camera[3], focus)
	put_table(world)
	for each: Array in spec.get("bands", []):
		var shade := band(each[0], each[1], each[2], each[3], each[4])
		var rect: Rect2 = each[5]
		shade.position = rect.position * Vector2(size)
		shade.size = rect.size * Vector2(size)
		viewport.add_child(shade)
	if spec.has("lockup"):
		var mark: Array = spec["lockup"]
		var seal := lockup(mark[0] * over, mark[1] * over, mark[2] * over, mark[3])
		viewport.add_child(seal)
		seal.reset_size()
		seal.position = Vector2(size) * (mark[4] as Vector2) - seal.size / 2.0
	var image := await taken(viewport, DRIVE_FRAMES)
	park()
	return image


## The seal and the name on nothing, for the library to lay over the hero, as big as fits
## [constant LOGO], with a dark edge round the name's letters so they hold on any part of it.
func _logo() -> void:
	var seal := lockup(560.0, 260, 40.0)
	for label: Label in seal.find_children("*", "Label", true, false):
		label.add_theme_color_override("font_outline_color", HouseTheme.STOCK_DOWN)
		label.add_theme_constant_override("outline_size", 22)
	var room := CenterContainer.new()
	room.size = Vector2(LOGO * OVER)
	room.add_child(seal)
	var image := await drawn(room, LOGO * OVER)
	var used := image.get_used_rect()
	var cut := image.get_region(used)
	var fit := minf(float(LOGO.x) / used.size.x, float(LOGO.y) / used.size.y)
	save(cut, OUT + "/library/library_logo.png", Vector2i(Vector2(used.size) * fit))


## The mark at every size of [constant ICONS], a shortcut's icon files for Windows, macOS and Linux,
## and the app's icon.
func _icons() -> void:
	var pictures := {}
	for side: int in ICONS:
		var drawn_at := side * OVER if side >= SEAL_FROM else side
		var art := LogoArt.new()
		art.plate = false
		art.size = Vector2.ONE * drawn_at
		var image := await drawn(art, Vector2i.ONE * drawn_at)
		image.resize(side, side, Image.INTERPOLATE_LANCZOS)
		save(image, OUT + "/client/icon_%d.png" % side, Vector2i.ONE * side)
		pictures[side] = image.save_png_to_buffer()
		if side == SHORTCUT:
			save(image, OUT + "/client/shortcut_icon.png", Vector2i.ONE * side)
	_write_ico(OUT + "/client/shortcut_icon.ico", pictures)
	_write_icns(OUT + "/client/mac_icon.icns", pictures)
	_write_linux_icons(OUT + "/client/linux_icons.zip", pictures)
	var plate := Panel.new()
	var engraved := TicketStyle.cut(HouseTheme.STOCK_RAISED, 0.0, 0.0, 0.0)
	engraved.engraving = Color(HouseTheme.FOIL, 0.1)
	engraved.waves = APP_ICON * OVER
	plate.add_theme_stylebox_override("panel", engraved)
	plate.size = Vector2.ONE * APP_ICON * OVER
	var mark := LogoArt.new()
	mark.plate = false
	mark.chip_only = true
	mark.size = plate.size
	plate.add_child(mark)
	save(
		await drawn(plate, Vector2i.ONE * APP_ICON * OVER, false),
		OUT + "/client/app_icon.jpg",
		Vector2i.ONE * APP_ICON,
		0.95
	)


## The avatar [param spec] says: its thing on a sunburst in its seat's color.
func _avatar(spec: Dictionary) -> Image:
	var side := AVATAR * OVER
	var seat: int = spec["seat"]
	var burst := Sunburst.new()
	burst.ink = HouseTheme.FOIL if seat < 0 else Palette.PLAYER_COLORS[seat]
	burst.size = Vector2.ONE * side
	if spec.has("seal"):
		var seal := LogoArt.new()
		seal.plate = false
		seal.size = Vector2.ONE * side * 0.84
		seal.position = (burst.size - seal.size) / 2.0
		burst.add_child(seal)
	elif spec.has("achievement"):
		var badge := Control.new()
		badge.size = burst.size
		var achievement := _achievement(spec["achievement"])
		badge.draw.connect(
			func() -> void:
				AchievementArt.draw(
					badge, badge.size / 2.0, side * 0.42, achievement, AchievementArt.Look.EARNED
				)
		)
		burst.add_child(badge)
	elif spec.has("flat_chip"):
		var face: Color = spec["flat_chip"]
		var words: String = spec["text"]
		var chip := Control.new()
		chip.size = burst.size
		chip.draw.connect(
			func() -> void:
				var middle := chip.size / 2.0
				var radius := side * 0.4
				ChipArt.chip(chip, middle, radius, face)
				if words != "":
					var font := Type.numbers_font()
					var tall := roundi(radius * 0.62)
					var wide := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, tall).x
					var foot := middle.y + tall * Type.CAP_HEIGHT * 0.5
					chip.draw_string(
						font,
						Vector2(middle.x - wide / 2.0, foot),
						words,
						HORIZONTAL_ALIGNMENT_LEFT,
						-1,
						tall,
						ChipArt.NOTCHES
					)
		)
		burst.add_child(chip)
	elif spec.has("joker") or spec.has("card_back"):
		var card: Control = (
			JokerCard.create(load("res://data/jokers/%s.tres" % spec["joker"]))
			if spec.has("joker")
			else CardBack.new()
		)
		card.size = JokerCard.SIZE
		card.pivot_offset = JokerCard.SIZE / 2.0
		card.scale = Vector2.ONE * side * 0.8 / JokerCard.SIZE.y
		card.rotation = deg_to_rad(-9.0)
		card.position = burst.size / 2.0 - JokerCard.SIZE / 2.0
		burst.add_child(card)
	var back := await drawn(burst, Vector2i.ONE * side, false)
	for flat: String in ["seal", "achievement", "flat_chip", "joker", "card_back"]:
		if spec.has(flat):
			return back
	var room := studio(Vector2i.ONE * side)
	if spec.has("chip"):
		# Its face turned up toward the camera, a little off square, as one flipped onto the felt.
		_chip_at(room, spec["chip"], Vector3.ZERO, Vector3(62.0, 0.0, -10.0))
		var reach := 1.25 if spec["chip"] else 1.0
		look_in(room, Vector3(0.0, 0.0, 1.55) * reach, Vector3.ZERO, 30.0)
	elif spec.has("stack"):
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i: int in 6:
			var jitter := Vector3(rng.randf_range(-0.02, 0.02), 0.0, rng.randf_range(-0.02, 0.02))
			_chip_at(room, i == 5, jitter + Vector3.UP * Chip.THICKNESS * i, Vector3(0, i * 37, 0))
		look_in(room, Vector3(0.0, 1.25, 2.1), Vector3(0.0, 0.28, 0.0), 30.0)
	elif spec.has("die"):
		var die := MultDie.new()
		room.add_child(die)
		var middle := Vector3.UP * die.hover
		look_in(room, middle + Vector3(0.75, 0.85, 1.1), middle, 30.0)
	elif spec.has("driver"):
		# Square on to the camera unless the spec turns it.
		var turn: float = spec.get("turn", 0.0)
		var model := _model(room, seat, spec["driver"], PI + turn)
		model.position.y = -KartVisuals.MODEL_LIFT
		var head := Vector3(0.0, DRIVER_AT, 0.0)
		var eye := Vector3(0.9, 0.35, 2.6) if turn != 0.0 else Vector3(0.0, 0.66, 2.95)
		look_in(room, head + eye, head + Vector3(0.0, -0.1, 0.0), 30.0)
	elif spec.has("kart"):
		_model(room, seat, spec["kart"], PI + 0.6)
		look_in(room, Vector3(1.8, 2.0, 3.7), Vector3(0.0, 0.8, 0.0), 30.0)
	return over(back, await taken(room, 8))


## A camera in [param room] at [param eye] looking at [param at].
func look_in(room: SubViewport, eye: Vector3, at: Vector3, fov: float) -> Camera3D:
	var camera := Camera3D.new()
	camera.fov = fov
	camera.near = 0.05
	room.add_child(camera)
	camera.look_at_from_position(eye, at, Vector3.UP)
	return camera


## A chip off the table in [param room], gold or not, at [param at] turned by [param turn] degrees.
func _chip_at(room: SubViewport, gold: bool, at: Vector3, turn: Vector3) -> void:
	var chip := MeshInstance3D.new()
	chip.mesh = Chip.mesh_for(gold)
	chip.material_override = Chip.paint_for(gold)
	chip.position = at
	chip.rotation_degrees = turn
	room.add_child(chip)


## A kart as the podium shows it, in [param seat]'s color and [param style], turned [param turn].
func _model(room: SubViewport, seat: int, style: Dictionary, turn: float) -> Node3D:
	var dress := KartStyle.new()
	for field: String in style:
		dress.set(field, style[field])
	var model := KartVisuals.display_model(seat, dress)
	model.rotation.y = turn
	room.add_child(model)
	return model


func _achievement(id: StringName) -> Achievement:
	for each: Achievement in Achievements.all():
		if each.id == id:
			return each
	push_error("no achievement %s" % id)
	return Achievements.all()[0]


## [param words] as a heading of the description: the foil on a strip of the stock, its corners
## notched as the game's tickets are, a hairline inside its edge, and the suit [param suit] either
## side, the words set smaller where they would not fit between them.
func _heading(words: String, suit: int) -> Image:
	var size := HEADING * OVER
	var strip := Panel.new()
	var cut := TicketStyle.cut(HouseTheme.STOCK_RAISED, 12.0 * OVER, 0.0, 0.0)
	cut.engraving = Color(HouseTheme.FOIL, 0.08)
	cut.waves = size.x
	cut.frame = Color(HouseTheme.FOIL, 0.55)
	cut.frame_inset = 6.0 * OVER
	strip.add_theme_stylebox_override("panel", cut)
	strip.size = Vector2(size)
	var side := 30.0 * OVER
	var room := size.x - (side * 2.0 + 30.0 * OVER) * 2.0
	var text := HEADING_TEXT * OVER
	var font := Type.display_font()
	while (
		font.get_string_size(words.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, text).x > room
		and text > 20
	):
		text -= 1
	var wide := font.get_string_size(words.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, text).x
	var label := MenuTheme.title(words, text)
	label.size = Vector2(size)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	strip.add_child(label)
	var pips := Control.new()
	pips.size = Vector2(size)
	pips.draw.connect(
		func() -> void:
			for way: float in [-1.0, 1.0]:
				var middle := Vector2(size) / 2.0 + Vector2(way * (wide / 2.0 + side * 1.1), 0.0)
				var box := Rect2(middle - Vector2.ONE * side / 2.0, Vector2.ONE * side)
				SuitArt.draw_into(pips, box, suit % 4, HouseTheme.FOIL)
	)
	strip.add_child(pips)
	return await drawn(strip, size)


## The description's pictures, on nothing so they sit on Steam's column and on itch.io's: a fan of
## jokers, a fan of power-ups, and a line of karts in their dress.
func _pictures() -> void:
	var jokers: Array[Control] = []
	for id: StringName in PICTURE_JOKERS:
		jokers.append(JokerCard.create(load("res://data/jokers/%s.tres" % id)))
	_described(await _fan(jokers, HAND, 6.0), "picture_jokers.png", Vector2i(PICTURE, HAND))
	var items: Array[Control] = []
	for id: StringName in PICTURE_ITEMS:
		items.append(ItemCard.create(load("res://data/powerups/%s.tres" % id)))
	_described(await _fan(items, HAND, 6.0), "picture_power_ups.png", Vector2i(PICTURE, HAND))
	var high := 200
	var room := studio(Vector2i(PICTURE, high) * OVER)
	for i: int in PICTURE_KARTS.size():
		var kart: Dictionary = PICTURE_KARTS[i]
		# The middle one square on, the ones beside it turned in toward it.
		var model := _model(room, kart["seat"], kart["style"], PI + (2 - i) * 0.22)
		model.position = Vector3((i - 2) * 1.45, -KartVisuals.MODEL_LIFT, -absf(i - 2) * 0.4)
	look_in(room, Vector3(0.0, 1.9, 6.3), Vector3(0.0, 1.05, -0.3), 25.0)
	var karts := await taken(room, 8)
	straighten(karts)
	_described(karts, "picture_karts.png", Vector2i(PICTURE, high))


## [param cards] held as a hand across a picture [param high] tall, each turned [param spread]
## degrees from the one before round a point under the picture, on nothing, a card's name clear of
## the next.
func _fan(cards: Array[Control], high: int, spread: float) -> Image:
	var size := Vector2i(PICTURE, high) * OVER
	var room := Control.new()
	room.size = Vector2(size)
	var tall := size.y * CARD
	var scale := tall / JokerCard.SIZE.y
	# The hand's pivot, far under the picture, and how far out the cards' middles are from it.
	var reach := size.y * 4.0
	var pivot := Vector2(size.x / 2.0, size.y * 0.48 + reach)
	for i: int in cards.size():
		var turn := deg_to_rad((i - (cards.size() - 1) / 2.0) * spread)
		var card := cards[i]
		card.size = JokerCard.SIZE
		card.pivot_offset = JokerCard.SIZE / 2.0
		card.scale = Vector2.ONE * scale
		card.rotation = turn
		card.position = pivot + Vector2(sin(turn), -cos(turn)) * reach - JokerCard.SIZE / 2.0
		room.add_child(card)
	return await drawn(room, size)


## A heading or picture of the description, [param image] at [param size], as [param file] in
## both [constant OUT]'s description and [constant DESCRIBED].
func _described(image: Image, file: String, size: Vector2i) -> void:
	save(image, OUT + "/description/" + file, size)
	save(image, DESCRIBED + "/" + file, size)


## An icon file at [param path] of [param pictures], PNGs by side, one for each side of
## [constant ICO]: the header, a line about each, and the pictures one after another.
func _write_ico(path: String, pictures: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("could not write %s" % path)
		return
	file.store_16(0)
	file.store_16(1)
	file.store_16(ICO.size())
	var at := 6 + 16 * ICO.size()
	for side: int in ICO:
		var picture: PackedByteArray = pictures[side]
		file.store_8(side % 256)
		file.store_8(side % 256)
		file.store_8(0)
		file.store_8(0)
		file.store_16(1)
		file.store_16(32)
		file.store_32(picture.size())
		file.store_32(at)
		at += picture.size()
	for side: int in ICO:
		file.store_buffer(pictures[side])
	file.close()
	print("%s: %s" % [path.trim_prefix("res://"), ICO])


## Apple's icon file at [param path] of [param pictures], PNGs by side, big-endian: "icns" and the
## file's length, then each of [constant ICNS], its kind, its length and its picture.
func _write_icns(path: String, pictures: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("could not write %s" % path)
		return
	file.big_endian = true
	var length := 8
	for entry: Array in ICNS:
		length += 8 + (pictures[entry[1]] as PackedByteArray).size()
	file.store_buffer("icns".to_ascii_buffer())
	file.store_32(length)
	for entry: Array in ICNS:
		var picture: PackedByteArray = pictures[entry[1]]
		file.store_buffer((entry[0] as String).to_ascii_buffer())
		file.store_32(8 + picture.size())
		file.store_buffer(picture)
	file.close()
	print("%s: %s" % [path.trim_prefix("res://"), ICNS])


## A ZIP at [param path] of [param pictures], PNGs by side, one for each side of [constant LINUX],
## each named after its side, 16x16.png and on.
func _write_linux_icons(path: String, pictures: Dictionary) -> void:
	var zip := ZIPPacker.new()
	if zip.open(ProjectSettings.globalize_path(path)) != OK:
		push_error("could not write %s" % path)
		return
	for side: int in LINUX:
		zip.start_file("%dx%d.png" % [side, side])
		zip.write_file(pictures[side])
		zip.close_file()
	zip.close()
	print("%s: %s" % [path.trim_prefix("res://"), LINUX])
