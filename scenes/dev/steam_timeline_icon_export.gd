extends Node
## Renders the game's own icons for the timeline of Steam's game recording, GAME.md 10.8, and quits,
## which is what `make steam-timeline-icons` runs: each of [constant Timeline.OWN_ICONS] white on
## nothing, as Steam's own are, at [constant SIZE] pixels and named as the game calls it, into
## `build/steam-timeline-icons/`, emptied first, for uploading by hand on Steamworks, docs/STEAM.md.
## The pictures are the game's own drawings of GAME.md 8.3a, the suits, three of the slot machines'
## sevens and the table card of the suits and hands, and this is the one place they become files.
##
## Windowed rather than headless: reading a viewport back needs a rendering device.

const OUT := "res://build/steam-timeline-icons"
const SIZE := 256
## How far in from the square's edge a picture keeps, and how big each suit of the four is.
const MARGIN := 0.06
const SUIT := 0.44
## The drawings of the three sevens and of a hand of cards, see [method draw_icon].
const SEVENS := &"timeline_777"
const HAND := &"table_suits_and_hands"


func _ready() -> void:
	var folder := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(folder)
	var ignored := OUT.get_base_dir().path_join(".gdignore")
	if not FileAccess.file_exists(ignored):
		FileAccess.open(ignored, FileAccess.WRITE).close()
	for old: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(old))
	for icon: String in Timeline.OWN_ICONS:
		var image := await _render(icon)
		var path := OUT.path_join(icon + ".png")
		if image.save_png(path) != OK:
			push_error("could not write %s" % path)
	print("timeline icons: %d into %s" % [Timeline.OWN_ICONS.size(), OUT])
	get_tree().quit()


## [param icon] drawn white on black, read back, and the black made nothing: how white a pixel is,
## how much of it there is.
func _render(icon: String) -> Image:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(SIZE, SIZE)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var back := ColorRect.new()
	back.color = Color.BLACK
	back.size = Vector2(SIZE, SIZE)
	viewport.add_child(back)
	var canvas := Control.new()
	canvas.size = Vector2(SIZE, SIZE)
	canvas.draw.connect(
		func() -> void:
			var box := Rect2(Vector2.ZERO, canvas.size).grow(-SIZE * MARGIN)
			draw_icon(canvas, box, icon, Color.WHITE)
	)
	viewport.add_child(canvas)
	add_child(viewport)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	image.convert(Image.FORMAT_RGBA8)
	for y: int in image.get_height():
		for x: int in image.get_width():
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, image.get_pixel(x, y).r))
	return image


## The game's own timeline icon [param icon] into [param box] on [param on], in [param ink], each a
## drawing of GAME.md 8.3a printed flat, its cream left unprinted: the four suits two by two, the
## game's three sevens, or the table card of the suits and hands, a hand of cards fanned.
static func draw_icon(on: CanvasItem, box: Rect2, icon: String, ink: Color) -> void:
	match icon:
		"jj_royal_flush":
			var side := box.size * SUIT
			for suit: int in JokerSuits.PICTURES.size():
				var at := box.position + Vector2(suit % 2, suit / 2) * (box.size - side)
				IconPress.draw(
					on, Rect2(at, side), JokerSuits.PICTURES[suit], ink, IconPress.Ground.PAPER
				)
		"jj_777":
			IconPress.draw(on, box, SEVENS, ink, IconPress.Ground.PAPER)
		"jj_cards":
			IconPress.draw(on, box, HAND, ink, IconPress.Ground.PAPER)
		_:
			push_error("no picture for the timeline icon %s" % icon)
