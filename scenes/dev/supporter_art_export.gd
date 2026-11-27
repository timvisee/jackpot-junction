extends "res://scenes/dev/steam_art_export.gd"
## Renders the supporter pack's own pictures for its DLC's store page, docs/STEAM.md "The supporter
## pack", into build/steam-art/supporter and quits, which `make steam-supporter-art` runs, and
## `make steam-art` after the game's: the store's capsules, the table's karts in the pack's dress
## under the seal and the pack's name; and the description's headings, a row of five karts in the
## pack's dress and a hand of its card backs, kept in docs/description/supporter as well; and two
## of its screenshots, the table close up, the rest coming from `tools/screenshots --supporter`.
##
## `-- --only=header,karts` renders those alone: the names of [constant PACK_SHOTS], or screens,
## headings, karts and backs. `-- --language=nl` draws the headings alone in another language the
## game speaks, the only pictures with words in them but the pack's name, see [method _described].

const PACK_OUT := "res://build/steam-art/supporter"
const PACK_DESCRIBED := "res://docs/description/supporter"
## The pack's name under the seal, and the star pinned either side of it, see
## [method PartTray.draw_star].
const PACK_NAME := "Supporter Pack"
## The store's capsules, as the game's are, see [constant SHOTS], the seal smaller to leave room
## for the pack's name under it, which is [code]pack[/code] pixels tall.
const PACK_SHOTS: Dictionary[String, Dictionary] = {
	"header":
	{
		"file": "store/header_capsule.png",
		"size": Vector2i(920, 430),
		"camera": [Vector3(0.0, 5.2, 10.0), Vector3(0.0, 0.6, 0.5), 42.0, false],
		"lockup": [118.0, 64, 16.0, false, Vector2(0.5, 0.27)],
		"pack": 30,
		"bands": [[0.94, 0.5, 0.74, Vector2(0.5, 0.0), Vector2(0.5, 1.0), Rect2(0, 0, 1, 0.68)]],
	},
	"small":
	{
		"file": "store/small_capsule.png",
		"size": Vector2i(462, 174),
		"camera": [Vector3(0.0, 5.2, 10.0), Vector3(0.0, 0.6, 0.5), 42.0, false],
		"lockup": [92.0, 44, 10.0, false, Vector2(0.5, 0.5)],
		"pack": 20,
		"bands": [[0.84, 0.55, 0.76, Vector2(0.5, 0.0), Vector2(0.5, 1.0), Rect2(0, 0, 1, 1)]],
	},
	"main":
	{
		"file": "store/main_capsule.png",
		"size": Vector2i(1232, 706),
		"camera": [Vector3(0.0, 5.2, 10.0), Vector3(0.0, 0.6, 0.5), 42.0, false],
		"lockup": [160.0, 88, 20.0, false, Vector2(0.5, 0.22)],
		"pack": 40,
		"bands": [[0.94, 0.5, 0.74, Vector2(0.5, 0.0), Vector2(0.5, 1.0), Rect2(0, 0, 1, 0.6)]],
	},
	"vertical":
	{
		"file": "store/vertical_capsule.png",
		"size": Vector2i(748, 896),
		"camera": [Vector3(0.0, 8.5, 9.5), Vector3(0.0, 0.0, -3.8), 50.0, true],
		"lockup": [160.0, 78, 0.0, true, Vector2(0.5, 0.25)],
		"pack": 36,
		"bands": [[0.95, 0.58, 0.82, Vector2(0.5, 0.0), Vector2(0.5, 1.0), Rect2(0, 0, 1, 0.6)]],
	},
}
## The description's headings, as the game's are, see [constant HEADINGS].
const PACK_HEADINGS: Dictionary[String, String] = {
	"heading_supporter_thanks": "A thank-you you can wear",
	"heading_supporter_pieces": "Everything in the pack",
}
## The headings in each other language the game speaks, by its locale, see [constant HEADINGS_IN].
const PACK_HEADINGS_IN: Dictionary[String, Dictionary] = {
	"nl":
	{
		"heading_supporter_thanks": "Een bedankje om te dragen",
		"heading_supporter_pieces": "Alles in het pakket",
	},
	"zh_CN":
	{
		"heading_supporter_thanks": "穿在身上的谢意",
		"heading_supporter_pieces": "礼包内容一览",
	},
}

## The store page's screenshots of the table, at the size Steam takes, drawn as the capsules are
## with no seal over them, the camera close enough for the pieces to be seen, which at a match's
## own zoom they are not: the pack's karts round the Junction, and three karts in its hats of
## character parked on the felt, each its seat and its outfit, see [SupporterArt].
const SCREEN := Vector2i(1920, 1080)
const TABLE_SHOT := "screenshots/01-at-the-junction.png"
const TABLE_CAMERA: Array = [Vector3(0.3, 3.6, 8.4), Vector3(0.3, 0.4, 1.2), 40.0, false]
const PARKED_SHOT := "screenshots/03-hats-of-character.png"
const PARKED_CAMERA: Array = [Vector3(0.0, 2.3, 7.8), Vector3(0.0, 1.0, 2.4), 32.0, false]
const PARKED: Array[Array] = [[3, 2], [1, 3], [7, 4]]
## The row of five karts in the description: each its seat and its outfit, see [SupporterArt].
const ROW: Array[Array] = [[3, 6], [1, 3], [0, 0], [4, 5], [7, 4]]
## The beam of the lighthouse in the middle of the row: how far its lamp is turned from facing the
## camera, in degrees, so the beam falls back and away to the side, behind the karts. `-- --beam=`
## tries another.
const ROW_BEAM := -160.0

var _beam_turn := ROW_BEAM


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",", false)
		elif arg.begins_with("--beam="):
			_beam_turn = float(arg.trim_prefix("--beam="))
	for folder: String in ["", "/store", "/description", "/screenshots"]:
		make_out(PACK_OUT + folder)
	make_out(PACK_DESCRIBED)
	if language != Lang.ENGLISH:
		if not PACK_HEADINGS_IN.has(language):
			push_error("no headings in %s: give them in PACK_HEADINGS_IN" % language)
		elif _wanted("headings"):
			await _pack_headings(PACK_HEADINGS_IN[language])
		get_tree().quit()
		return
	for shot: String in PACK_SHOTS:
		if _wanted(shot):
			var spec := PACK_SHOTS[shot]
			save(await _pack_shot(spec), PACK_OUT + "/" + spec["file"], spec["size"])
	if _wanted("screens"):
		await _screens()
	if _wanted("headings"):
		await _pack_headings(PACK_HEADINGS)
	if _wanted("karts"):
		await _karts()
	if _wanted("backs"):
		await _backs()
	get_tree().quit()


## The karts round the Junction in the pack's first outfits, see [SupporterArt], and what lies round
## them.
func put_table(world: Dictionary) -> void:
	for i: int in KARTS.size():
		var kart: Dictionary = KARTS[i].duplicate()
		kart["style"] = SupporterArt.fields_of(SupporterArt.OUTFITS[i])
		put_kart(world["viewport"], kart)
	lay(world["arena"], GOLD_CHIPS, CHIPS, DIE, BOX, BOX_ITEM)


## The table as [param spec] has it, as the game's capsules are, see [method _shot], with the
## pack's name under the seal.
func _pack_shot(spec: Dictionary) -> Image:
	var over_by := OVER
	var size: Vector2i = spec["size"] * over_by
	var world := stage(size)
	var viewport: SubViewport = world["viewport"]
	var camera: Array = spec["camera"]
	look(world, camera[0], camera[1], camera[2], camera[3])
	put_table(world)
	for each: Array in spec["bands"]:
		var shade := band(each[0], each[1], each[2], each[3], each[4])
		var rect: Rect2 = each[5]
		shade.position = rect.position * Vector2(size)
		shade.size = rect.size * Vector2(size)
		viewport.add_child(shade)
	var mark: Array = spec["lockup"]
	var named := VBoxContainer.new()
	named.alignment = BoxContainer.ALIGNMENT_CENTER
	named.add_theme_constant_override("separation", roundi(mark[2] * 0.6 * over_by))
	named.add_child(lockup(mark[0] * over_by, mark[1] * over_by, mark[2] * over_by, mark[3]))
	named.add_child(_pack_name(int(spec["pack"]) * over_by))
	viewport.add_child(named)
	named.reset_size()
	named.position = Vector2(size) * (mark[4] as Vector2) - named.size / 2.0
	var image := await taken(viewport, DRIVE_FRAMES)
	park()
	return image


## The table at [constant SCREEN], see [constant TABLE_SHOT] and [constant PARKED_SHOT].
func _screens() -> void:
	var size := SCREEN * OVER
	var world := stage(size)
	look(world, TABLE_CAMERA[0], TABLE_CAMERA[1], TABLE_CAMERA[2], TABLE_CAMERA[3])
	put_table(world)
	save(await taken(world["viewport"], DRIVE_FRAMES), PACK_OUT + "/" + TABLE_SHOT, SCREEN)
	park()
	world = stage(size)
	look(world, PARKED_CAMERA[0], PARKED_CAMERA[1], PARKED_CAMERA[2], PARKED_CAMERA[3])
	for i: int in PARKED.size():
		var outfit := SupporterArt.fields_of(SupporterArt.OUTFITS[PARKED[i][1]])
		var model := _model(world["viewport"], PARKED[i][0], outfit, PI + (1 - i) * 0.3)
		model.position = Vector3((i - 1) * 1.7, -KartVisuals.MODEL_LIFT, 2.6 - absf(i - 1) * 0.3)
	save(await taken(world["viewport"], DRIVE_FRAMES), PACK_OUT + "/" + PARKED_SHOT, SCREEN)
	park()


## The pack's name, [param tall] pixels, in the house's foil between two of the pack's star pins.
static func _pack_name(tall: int) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", roundi(tall * 0.45))
	var words := MenuTheme.title(PACK_NAME, tall)
	for side: int in 3:
		if side == 1:
			line.add_child(words)
			continue
		var pin := Control.new()
		pin.custom_minimum_size = Vector2.ONE * tall
		pin.draw.connect(func() -> void: PartTray.draw_star(pin, pin.size / 2.0, tall * 0.42))
		line.add_child(pin)
	return line


## The row of five karts in the pack's dress, see [constant ROW], as the game's row is, on nothing;
## the lighthouse's beam behind them, see [constant ROW_BEAM]. A beam is light added over what is
## under it, which on nothing is next to nothing, so it is drawn on its own on black, its light
## taken for how much it covers, and the karts laid over it.
func _karts() -> void:
	var size := Vector2i(PICTURE, 200)
	var karts := await taken(_row(false), 8)
	straighten(karts)
	var picture := _light_as_cover(await taken(_row(true), 8))
	picture.blend_rect(karts, Rect2i(Vector2i.ZERO, karts.get_size()), Vector2i.ZERO)
	_pack_described(picture, "picture_supporter_karts.png", size)


## The row in a studio of its own: the karts with no light of their own, or for [param beam] the
## lighthouse's beam and glow alone, on black.
func _row(beam: bool) -> SubViewport:
	var room := studio(Vector2i(PICTURE, 200) * OVER)
	for i: int in ROW.size():
		var outfit := SupporterArt.fields_of(SupporterArt.OUTFITS[ROW[i][1]])
		var model := _model(room, ROW[i][0], outfit, PI + (2 - i) * 0.22)
		model.position = Vector3((i - 2) * 1.45, -KartVisuals.MODEL_LIFT, -absf(i - 2) * 0.4)
		var lamps := model.find_children("*", "LighthouseLamp", true, false)
		for lamp: Node in lamps:
			lamp.set_process(false)
			(lamp as LighthouseLamp).head.rotation.y = deg_to_rad(_beam_turn)
		for node: Node in model.find_children("*", "GeometryInstance3D", true, false):
			var light := SupporterDress.is_light(node)
			(node as GeometryInstance3D).visible = (
				light and not lamps.is_empty() if beam else not light
			)
	if beam:
		room.transparent_bg = false
		var air := room.find_children("*", "WorldEnvironment", true, false)[0] as WorldEnvironment
		air.environment.background_mode = Environment.BG_COLOR
		air.environment.background_color = Color.BLACK
	look_in(room, Vector3(0.0, 1.9, 6.3), Vector3(0.0, 1.1, -0.3), 25.0)
	return room


## [param shone], light drawn on black, as that light in its own color covering as much as it is
## bright: what a light on nothing looks like laid over anything.
static func _light_as_cover(shone: Image) -> Image:
	var light := shone.duplicate() as Image
	light.convert(Image.FORMAT_RGBA8)
	for y: int in light.get_height():
		for x: int in light.get_width():
			var lit := light.get_pixel(x, y)
			var cover := maxf(lit.r, maxf(lit.g, lit.b))
			if cover <= 0.0:
				light.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
			else:
				light.set_pixel(x, y, Color(lit.r / cover, lit.g / cover, lit.b / cover, cover))
	return light


## A hand of the pack's three card backs, as the game's hands of cards are, see [method _fan].
func _backs() -> void:
	var backs: Array[Control] = []
	for back: int in CardBack.SUPPORTER:
		backs.append(CardBack.new(back, false))
	_pack_described(
		await _fan(backs, HAND, 9.0), "picture_supporter_backs.png", Vector2i(PICTURE, HAND)
	)


## Each of [param headings], by its file's name, as the game's are.
func _pack_headings(headings: Dictionary) -> void:
	for heading: String in headings:
		_pack_described(
			await _heading(headings[heading], headings.keys().find(heading) + 1),
			"%s.png" % heading,
			HEADING
		)


## A heading or picture of the pack's description, as [param file] in both [constant PACK_OUT]'s
## description and [constant PACK_DESCRIBED], in a language's folder in another, see
## [method in_language].
func _pack_described(image: Image, file: String, size: Vector2i) -> void:
	for folder: String in [PACK_OUT + "/description", PACK_DESCRIBED]:
		save(image, in_language(folder, file), size)
