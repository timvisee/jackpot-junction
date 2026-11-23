extends Node
## Renders the game's own icons for the timeline of Steam's game recording, GAME.md 10.8, and quits,
## which is what `make steam-timeline-icons` runs: each of [constant Timeline.OWN_ICONS] white on
## nothing, as Steam's own are, at [constant SIZE] pixels and named as the game calls it, into
## `build/steam-timeline-icons/`, emptied first, for uploading by hand on Steamworks, docs/STEAM.md.
## The pictures live in code, the suits of the Royal Flush pads, the slot machine's sevens and the
## achievements' cards, and this is the one place they become files.
##
## Windowed rather than headless: reading a viewport back needs a rendering device.

const OUT := "res://build/steam-timeline-icons"
const SIZE := 256
## How far in from the square's edge a picture keeps, and how big each suit of the four is.
const MARGIN := 0.06
const SUIT := 0.44


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
			draw_icon(canvas, box, icon, Color.WHITE, Color.BLACK)
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


## The game's own timeline icon [param icon] into [param box] on [param on], in [param ink] with
## [param paper] for what is cut out of it: the four suits two by two, three sevens, or a hand of
## cards.
static func draw_icon(on: CanvasItem, box: Rect2, icon: String, ink: Color, paper: Color) -> void:
	match icon:
		"jj_royal_flush":
			var side := box.size * SUIT
			for suit: int in 4:
				var at := box.position + Vector2(suit % 2, suit / 2) * (box.size - side)
				SuitArt.draw_into(on, Rect2(at, side), suit, ink)
		"jj_777":
			var high := box.size.y * 0.62
			var at := box.position + Vector2(0.0, box.size.y * 0.5 + high * 0.34)
			var font := Type.display_font()
			on.draw_string(font, at, "777", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, int(high), ink)
		"jj_cards":
			AchievementIcons.draw_into(on, box, &"full_house", ink, paper)
		_:
			push_error("no picture for the timeline icon %s" % icon)
