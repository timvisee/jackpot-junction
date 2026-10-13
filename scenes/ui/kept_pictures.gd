class_name KeptPictures
extends RefCounted
## Pictures drawn once a run and shown from then on, GAME.md 10.7. Something drawn of many shapes
## or many controls that does not change, an achievement's chip or a card in the catalog, costs a
## draw call or more for each of them every frame it is shown, and as a picture one. Each is kept by
## what it is and how many pixels it is drawn at, drawn under the first node that asks for it; until
## it is ready the asker shows itself as before, and then every node waiting on it is told. Nothing
## is drawn with no screen to draw on.

static var _kept: Dictionary[String, Texture2D] = {}
static var _drawing: Dictionary[String, Node] = {}


## The picture of [param key] at [param pixels], or null until it is ready: drawn once, from the
## control [param make] returns, under [param host], after which [param method] is called on every
## node in [param group] for them to show it. Asked for again should [param host] go before its
## drawing is done, which takes the drawing with it.
static func of(
	host: Node,
	key: String,
	pixels: Vector2i,
	make: Callable,
	group: StringName,
	method: StringName = &"queue_redraw"
) -> Texture2D:
	if not host.is_inside_tree() or Game.is_headless():
		return null
	var named := "%s|%d|%d" % [key, pixels.x, pixels.y]
	var kept: Texture2D = _kept.get(named)
	if kept != null:
		return kept
	if not _drawing.has(named) or not is_instance_valid(_drawing[named]):
		_drawing[named] = host
		DrawnTexture.kept(
			host,
			make.call(),
			pixels,
			func(texture: Texture2D) -> void:
				_kept[named] = texture
				_drawing.erase(named)
				(Engine.get_main_loop() as SceneTree).call_group(group, method)
		)
	return null


## How many of the screen's own pixels one of [param item]'s is across: its place's scale, the
## screen's stretch and the UI scale with it.
static func scale_of(item: CanvasItem) -> float:
	var canvas := item.get_global_transform_with_canvas().get_scale().x
	return canvas * item.get_viewport().get_final_transform().get_scale().x


## [param pixels] rounded up to a step of [param step], so a window dragged to another size draws
## a few sizes again rather than one for every pixel it passes.
static func step_up(pixels: float, step: int) -> int:
	return maxi(ceili(pixels / step) * step, step)
