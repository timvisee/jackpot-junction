extends Node
## Renders [LogoArt] to the icons the project wears and quits, which is what `make logo` runs. The
## mark lives in code, GAME.md 8.1, and this is the one place it becomes files: change the drawing,
## run this, and the icons on the window and the desktop follow.
##
## Two files: the icon every platform wears, big, the seal on its plate; and for Windows, which
## shows a window's icon at a size of its own choosing from a set, the same at every size it asks
## for, each drawn at that size, so the small ones are the foil chip rather than a seal shrunk to
## mush, see [constant LogoArt.SMALL].
##
## Windowed rather than headless: reading a viewport back needs a rendering device.

const OUT := "res://icon.png"
## Big enough for a desktop icon on a high-density screen, and square because every use of it is.
const SIZE := 512
const ICO := "res://icon.ico"
const ICO_SIZES: Array[int] = [16, 24, 32, 48, 64, 128, 256]


func _ready() -> void:
	var big := await _render(SIZE)
	var failed := big.save_png(OUT)
	if failed != OK:
		push_error("could not write %s" % OUT)
	print("logo %s: %dx%d" % [OUT, big.get_width(), big.get_height()])
	var pictures: Array[PackedByteArray] = []
	for side: int in ICO_SIZES:
		pictures.append((await _render(side)).save_png_to_buffer())
	_write_ico(pictures)
	print("logo %s: %s" % [ICO, ICO_SIZES])
	get_tree().quit()


## The mark on its plate, [param side] pixels square.
func _render(side: int) -> Image:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(side, side)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var art := LogoArt.new()
	art.size = Vector2(side, side)
	viewport.add_child(art)
	add_child(viewport)
	# Two frames: one to lay the control out, one to draw it.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	return image


## An icon file of [param pictures], each a PNG, one per size in [constant ICO_SIZES]: the
## header, a line about each, and the pictures one after another.
func _write_ico(pictures: Array[PackedByteArray]) -> void:
	var file := FileAccess.open(ICO, FileAccess.WRITE)
	if file == null:
		push_error("could not write %s" % ICO)
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
