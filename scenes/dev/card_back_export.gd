extends Node
## Renders each of [constant CardBack.STYLES] won in the loyalty program to the picture the cards in
## the rooms wear face down, GAME.md 8.9, and quits, which is what `make card-backs` runs. The backs
## live in code, see [CardBack], and this is the one place they become files for the 3D cards: each
## on its square board, without the question mark of a card not known yet, as a card of the deck
## has none. The house's is the deck's red lattice there, see [constant Surfaces.CARD_BACKS].
##
## Windowed rather than headless: reading a viewport back needs a rendering device.

## As big as the faces of the deck's cards, and the shape of a [JokerCard].
const SIZE := Vector2i(256, 358)
## How broad the rim is, in a card's pixels, and how much stronger the lines are, for a back seen
## from over the table.
const FAR_RIM := 9
const FAR_LINES := 2.2


func _ready() -> void:
	for style: int in CardBack.STYLES.size():
		var path: String = Surfaces.CARD_BACK_FILES[style]
		if path.is_empty():
			continue
		var image := await _render(style)
		if image.save_png(path) != OK:
			push_error("could not write %s" % path)
		print("card back %s: %dx%d" % [path, image.get_width(), image.get_height()])
	get_tree().quit()


## The back [param style] at [constant SIZE], its corners the board's.
func _render(style: int) -> Image:
	var viewport := SubViewport.new()
	viewport.size = SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var board := ColorRect.new()
	board.color = Color(CardBack.BOARDS[style], 1.0)
	board.size = Vector2(SIZE)
	viewport.add_child(board)
	var scaled := Node2D.new()
	scaled.scale = Vector2(SIZE) / JokerCard.SIZE
	var back := CardBack.new(style, false)
	# Its shadow is for a card lying on a screen, not printed on one; and seen from over the table,
	# far off and small, its rim is broader and its lines stronger, so it reads as its own colors
	# rather than as its board alone.
	var look := (back.get_theme_stylebox(&"panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	look.shadow_size = 0
	look.set_border_width_all(FAR_RIM)
	back.add_theme_stylebox_override(&"panel", look)
	var face := back.get_node("Face") as CanvasItem
	face.set(&"lines", minf(float(face.get(&"lines")) * FAR_LINES, 1.0))
	scaled.add_child(back)
	viewport.add_child(scaled)
	add_child(viewport)
	# Two frames: one to lay it out, one to draw it.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	image.convert(Image.FORMAT_RGB8)
	return image
