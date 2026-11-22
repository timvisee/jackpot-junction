extends "res://scenes/dev/steam_art_export.gd"
## Renders the supporter pack's own pictures for its DLC's store page, docs/STEAM.md "The supporter
## pack", into build/steam-art/supporter and quits, which `make steam-supporter-art` runs, and
## `make steam-art` after the game's: the store's capsules, the table's karts in the pack's dress
## under the seal and the pack's name; and the description's headings, a row of five karts in the
## pack's dress and a hand of its card backs, kept in docs/description/supporter as well; and two
## of its screenshots, the table close up, the rest coming from `tools/screenshots --supporter`.
##
## `-- --only=header,karts` renders those alone: the names of [constant PACK_SHOTS], or screens,
## headings, karts and backs.

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


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",", false)
	for folder: String in ["", "/store", "/description", "/screenshots"]:
		make_out(PACK_OUT + folder)
	make_out(PACK_DESCRIBED)
	for shot: String in PACK_SHOTS:
		if _wanted(shot):
			var spec := PACK_SHOTS[shot]
			save(await _pack_shot(spec), PACK_OUT + "/" + spec["file"], spec["size"])
	if _wanted("screens"):
		await _screens()
	if _wanted("headings"):
		for heading: String in PACK_HEADINGS:
			_pack_described(
				await _heading(PACK_HEADINGS[heading], PACK_HEADINGS.keys().find(heading) + 1),
				"%s.png" % heading,
				HEADING
			)
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


## The row of five karts in the pack's dress, see [constant ROW], as the game's row is, their light
## left out as the rack's pictures leave it, on nothing.
func _karts() -> void:
	var high := 200
	var room := studio(Vector2i(PICTURE, high) * OVER)
	for i: int in ROW.size():
		var outfit := SupporterArt.fields_of(SupporterArt.OUTFITS[ROW[i][1]])
		var model := _model(room, ROW[i][0], outfit, PI + (2 - i) * 0.22)
		model.position = Vector3((i - 2) * 1.45, -KartVisuals.MODEL_LIFT, -absf(i - 2) * 0.4)
		for node: Node in model.find_children("*", "MeshInstance3D", true, false):
			if SupporterDress.is_light(node):
				(node as MeshInstance3D).visible = false
	look_in(room, Vector3(0.0, 1.9, 6.3), Vector3(0.0, 1.1, -0.3), 25.0)
	var karts := await taken(room, 8)
	straighten(karts)
	_pack_described(karts, "picture_supporter_karts.png", Vector2i(PICTURE, high))


## A hand of the pack's three card backs, as the game's hands of cards are, see [method _fan].
func _backs() -> void:
	var backs: Array[Control] = []
	for back: int in CardBack.SUPPORTER:
		backs.append(CardBack.new(back, false))
	_pack_described(
		await _fan(backs, HAND, 9.0), "picture_supporter_backs.png", Vector2i(PICTURE, HAND)
	)


## A heading or picture of the pack's description, as [param file] in both [constant PACK_OUT]'s
## description and [constant PACK_DESCRIBED].
func _pack_described(image: Image, file: String, size: Vector2i) -> void:
	save(image, PACK_OUT + "/description/" + file, size)
	save(image, PACK_DESCRIBED + "/" + file, size)
