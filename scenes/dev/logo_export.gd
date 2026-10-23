extends Node
## Renders [LogoArt] to the icons the project wears and quits, which is what `make logo` runs. The
## mark lives in code, GAME.md 8.1, and this is the one place it becomes files: change the drawing,
## run this, and the icons on the window and the desktop follow.
##
## The icon is the mark on nothing, the seal; the splash the mark on its plate, the house's ticket,
## which the boot splash shows. Each comes as a big picture and, for Windows, which shows a window's
## icon at a size of its own choosing from a set, as an icon file of every size it asks for, each
## drawn at that size, so the small ones are the foil chip rather than a seal shrunk to mush, see
## [constant LogoArt.SMALL]. [constant SHEET] holds the same at a few sizes, the foil chip alone
## too, the banner the README opens with, for whatever else wants the mark, and Android's
## launcher icon. The Mac has an icon file of its own, see [constant MACOS].
##
## Windowed rather than headless: reading a viewport back needs a rendering device.

const ICON := "res://assets/app/icon"
const SPLASH := "res://assets/app/splash"
## Big enough for a desktop icon on a high-density screen, and square because every use of it is.
const SIZE := 512
const ICO_SIZES: Array[int] = [16, 24, 32, 48, 64, 128, 256]
## The mark for other uses, kept out of the game by a .gdignore.
const SHEET := "res://assets/logo/"
const SHEET_SIZES: Array[int] = [128, 512, 2048]
## The banner: the mark and the name as the About page sets them, the name beside the mark rather
## than under it, drawn this many times over for a dense screen.
const BANNER_SCALE := 2.0
const BANNER_GAP := 32.0
## A second banner with transparent padding round it, the same on every side, this share of its
## height, for a place that crops to the edges of what it is given, like itch.io's header, so the
## mark is not jammed against the sides.
const BANNER_PAD := 0.15
## Android's launcher icon. Since Android 8 a launcher cuts it to a shape of its own from layers
## this big: the house's stock behind, the seal in front, and the foil chip in one ink for a
## launcher that tints its icons. Before that it shows a picture as it is, the splash at
## [constant ANDROID_LEGACY]. The export preset names the files.
const ANDROID_LAYER := 432
const ANDROID_LEGACY := 192
## The mark's share of a layer: inside the 66 of its 108 dp across that no launcher's shape cuts
## into, with a little to spare.
const ANDROID_MARK := 0.6
## The one-ink chip smaller, the way the glyphs of a launcher's tinted icons sit.
const ANDROID_TINTED := 0.44
## The Mac's icon, as macOS draws its own since Big Sur: a plate with rounded corners, the share
## [constant MACOS_PLATE] of the picture across, Apple's 824 of 1024, with a shadow under it; the
## house's stock engraved, a foil hairline inside its edge and the mark on it, the foil chip when
## small. An icns file of every size macOS asks for, by the type each goes under, which the project
## names for the Mac the way it names icon.ico for Windows.
const MACOS := "res://assets/app/icon.icns"
const MACOS_SIZES: Dictionary[String, int] = {
	"ic11": 32,
	"ic12": 64,
	"ic07": 128,
	"ic08": 256,
	"ic13": 256,
	"ic09": 512,
	"ic14": 512,
	"ic10": 1024,
}
const MACOS_PLATE := 0.805
## How round the plate's corners are, against its side, and the mark's share of it.
const MACOS_ROUND := 0.225
const MACOS_MARK := 0.72


func _ready() -> void:
	for kind: Array in [[ICON, false], [SPLASH, true]]:
		var big := await _render(SIZE, kind[1])
		_save(big, kind[0] + ".png")
		var pictures: Array[PackedByteArray] = []
		for side: int in ICO_SIZES:
			pictures.append((await _render(side, kind[1])).save_png_to_buffer())
		_write_ico(kind[0] + ".ico", pictures)
		print("logo %s.ico: %s" % [kind[0], ICO_SIZES])
	for side: int in SHEET_SIZES:
		_save(await _render(side, false), "%sicon-%d.png" % [SHEET, side])
		_save(await _render(side, false, true), "%schip-%d.png" % [SHEET, side])
		_save(await _render(side, true), "%ssplash-%d.png" % [SHEET, side])
	var banner := await _banner()
	_save(banner, SHEET + "banner.png")
	_save(_padded(banner, BANNER_PAD), SHEET + "banner-padded.png")
	_save(await _render(ANDROID_LEGACY, true), SHEET + "android-main-%d.png" % ANDROID_LEGACY)
	var front := LogoArt.new()
	front.plate = false
	_save(
		await _android_layer(front, ANDROID_MARK),
		SHEET + "android-foreground-%d.png" % ANDROID_LAYER
	)
	_save(await _android_backdrop(), SHEET + "android-background-%d.png" % ANDROID_LAYER)
	var tinted := LogoArt.new()
	tinted.mono = true
	_save(
		await _android_layer(tinted, ANDROID_TINTED),
		SHEET + "android-monochrome-%d.png" % ANDROID_LAYER
	)
	var drawn: Dictionary[int, PackedByteArray] = {}
	var pictures: Dictionary[String, PackedByteArray] = {}
	for kind: String in MACOS_SIZES:
		var side: int = MACOS_SIZES[kind]
		if not drawn.has(side):
			drawn[side] = (await _macos(side)).save_png_to_buffer()
		pictures[kind] = drawn[side]
	_write_icns(MACOS, pictures)
	print("logo %s: %s" % [MACOS, MACOS_SIZES.values()])
	get_tree().quit()


func _save(image: Image, path: String) -> void:
	if image.save_png(path) != OK:
		push_error("could not write %s" % path)
	print("logo %s: %dx%d" % [path, image.get_width(), image.get_height()])


## The mark, [param side] pixels square, on its plate or not, and the foil chip alone if asked.
func _render(side: int, plated: bool, chip_only := false) -> Image:
	var art := LogoArt.new()
	art.plate = plated
	art.chip_only = chip_only
	art.size = Vector2(side, side)
	return await _picture(art, Vector2i(side, side))


## The mark with the game's name to the right of it, as big as the About page draws them.
func _banner() -> Image:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", roundi(BANNER_GAP * BANNER_SCALE))
	var art := LogoArt.new()
	art.plate = false
	art.custom_minimum_size = Vector2.ONE * AboutTab.MARK * BANNER_SCALE
	row.add_child(art)
	var name_label := MenuTheme.title("Jackpot Junction", roundi(Type.TITLE * BANNER_SCALE))
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_label)
	return await _picture(row)


## [param image] centered on a transparent canvas grown by the same margin on every side, that
## margin [param pad] of its height, so the padding reads even all round whatever the shape.
static func _padded(image: Image, pad: float) -> Image:
	var margin := roundi(image.get_height() * pad)
	var out := Image.create_empty(
		image.get_width() + margin * 2, image.get_height() + margin * 2, false, image.get_format()
	)
	out.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(margin, margin))
	return out


## A layer of Android's launcher icon with [param art] in its middle, [param share] of its side
## across.
func _android_layer(art: Control, share: float) -> Image:
	var layer := Control.new()
	layer.size = Vector2.ONE * ANDROID_LAYER
	art.size = Vector2.ONE * ANDROID_LAYER * share
	art.position = (layer.size - art.size) * 0.5
	layer.add_child(art)
	return await _picture(layer, Vector2i.ONE * ANDROID_LAYER)


## The layer behind: the plate's stock and engraved waves out to every edge, with neither its
## notches nor its hairline, since a launcher cuts it to a shape of its own.
func _android_backdrop() -> Image:
	var stock := Panel.new()
	var look := TicketStyle.cut(HouseTheme.STOCK_RAISED, 0.0, 0.0, 0.0)
	look.engraving = Color(HouseTheme.FOIL, 0.1)
	look.waves = ANDROID_LAYER
	stock.add_theme_stylebox_override("panel", look)
	stock.size = Vector2.ONE * ANDROID_LAYER
	return await _picture(stock, Vector2i.ONE * ANDROID_LAYER)


## The Mac's icon [param side] pixels square, see [constant MACOS]. The plate clips the engraving
## and the mark to its rounded corners; the shadow is a plate of its own under it, so the clip does
## not take in the shadow.
func _macos(side: int) -> Image:
	var canvas := Control.new()
	canvas.size = Vector2.ONE * side
	var across := side * MACOS_PLATE
	var at := Vector2.ONE * (side - across) * 0.5
	var radius := roundi(across * MACOS_ROUND)
	var stock := StyleBoxFlat.new()
	stock.bg_color = HouseTheme.STOCK_RAISED
	stock.set_corner_radius_all(radius)
	stock.corner_detail = 16
	var shaded := stock.duplicate() as StyleBoxFlat
	shaded.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	shaded.shadow_size = maxi(1, roundi(side * 0.028))
	shaded.shadow_offset = Vector2(0.0, side * 0.012)
	var under := Panel.new()
	under.add_theme_stylebox_override("panel", shaded)
	canvas.add_child(under)
	var plate := Panel.new()
	plate.add_theme_stylebox_override("panel", stock)
	plate.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	canvas.add_child(plate)
	for each: Control in [under, plate]:
		each.position = at
		each.size = Vector2.ONE * across
	var waves := Panel.new()
	var engraved := TicketStyle.cut(HouseTheme.STOCK_RAISED, 0.0, 0.0, 0.0)
	engraved.engraving = Color(HouseTheme.FOIL, 0.1)
	engraved.waves = across
	waves.add_theme_stylebox_override("panel", engraved)
	waves.size = Vector2.ONE * across
	plate.add_child(waves)
	var mark := LogoArt.new()
	mark.plate = false
	mark.size = Vector2.ONE * across * MACOS_MARK
	mark.position = (Vector2.ONE * across - mark.size) * 0.5
	plate.add_child(mark)
	var inset := across * 0.04
	var line := StyleBoxFlat.new()
	line.draw_center = false
	line.border_color = Color(HouseTheme.FOIL, 0.5)
	line.set_border_width_all(maxi(1, roundi(side * 0.003)))
	line.set_corner_radius_all(maxi(0, roundi(radius - inset)))
	line.corner_detail = 16
	var hairline := Panel.new()
	hairline.add_theme_stylebox_override("panel", line)
	hairline.position = at + Vector2.ONE * inset
	hairline.size = Vector2.ONE * (across - inset * 2.0)
	canvas.add_child(hairline)
	return await _picture(canvas, Vector2i.ONE * side)


## An icns file at [param path] of [param pictures], each a PNG under its type, as macOS reads one:
## its magic and its length, then each picture after its type and its length, every length counting
## its own header and written big-endian.
func _write_icns(path: String, pictures: Dictionary[String, PackedByteArray]) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("could not write %s" % path)
		return
	file.big_endian = true
	var total := 8
	for kind: String in pictures:
		total += 8 + pictures[kind].size()
	file.store_buffer("icns".to_ascii_buffer())
	file.store_32(total)
	for kind: String in pictures:
		file.store_buffer(kind.to_ascii_buffer())
		file.store_32(8 + pictures[kind].size())
		file.store_buffer(pictures[kind])
	file.close()


## [param control] drawn on nothing into a picture [param side] big, or as big as it asks to be.
func _picture(control: Control, side := Vector2i.ZERO) -> Image:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(4096, 4096) if side == Vector2i.ZERO else side
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.add_child(control)
	add_child(viewport)
	# Two frames: one to lay the control out, one to draw it.
	await RenderingServer.frame_post_draw
	if side == Vector2i.ZERO:
		var room := control.get_combined_minimum_size()
		control.size = room
		viewport.size = Vector2i(ceili(room.x), ceili(room.y))
		await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	_straighten(image)
	return image


## A viewport cleared to nothing keeps what is drawn on it premultiplied, its colors darkened by
## how much of a pixel they cover; a picture file keeps them whole. Without this every soft edge
## would have a dark rim on a light page.
func _straighten(image: Image) -> void:
	var data := image.get_data()
	for i: int in range(0, data.size(), 4):
		var cover := data[i + 3]
		if cover == 0 or cover == 255:
			continue
		for channel: int in 3:
			data[i + channel] = mini(roundi(data[i + channel] * 255.0 / cover), 255)
	image.set_data(image.get_width(), image.get_height(), false, image.get_format(), data)


## An icon file at [param path] of [param pictures], each a PNG, one per size in
## [constant ICO_SIZES]: the header, a line about each, and the pictures one after another.
func _write_ico(path: String, pictures: Array[PackedByteArray]) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("could not write %s" % path)
		return
	file.store_16(0)
	file.store_16(1)
	file.store_16(pictures.size())
	var at := 6 + 16 * pictures.size()
	for i: int in pictures.size():
		var side := ICO_SIZES[i]
		file.store_8(side % 256)
		file.store_8(side % 256)
		file.store_8(0)
		file.store_8(0)
		file.store_16(1)
		file.store_16(32)
		file.store_32(pictures[i].size())
		file.store_32(at)
		at += pictures[i].size()
	for picture: PackedByteArray in pictures:
		file.store_buffer(picture)
	file.close()
