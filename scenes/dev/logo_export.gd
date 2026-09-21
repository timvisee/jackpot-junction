extends Node
## Renders [LogoArt] to the icon the project wears and quits, which is what `make logo` runs.
## The mark lives in code, GAME.md 8.1, and this is the one place it becomes a file: change the
## drawing, run this, and the icon on the window and the desktop follows.
##
## Windowed rather than headless: reading a viewport back needs a rendering device.

const OUT := "res://icon.png"
## Big enough for a desktop icon on a high-density screen, and square because every use of it is.
const SIZE := 512


func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(SIZE, SIZE)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var art := LogoArt.new()
	art.size = Vector2(SIZE, SIZE)
	viewport.add_child(art)
	add_child(viewport)
	# Two frames: one to lay the control out, one to draw it.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var failed := image.save_png(OUT)
	if failed != OK:
		push_error("could not write %s" % OUT)
	print("logo %s: %dx%d" % [OUT, image.get_width(), image.get_height()])
	get_tree().quit()
