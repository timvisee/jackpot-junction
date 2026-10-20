class_name DrawnTexture
extends RefCounted
## A picture drawn once into a texture for something in the world to wear, GAME.md 8.3a: the
## items' and the jokers' pictures are drawn rather than loaded, and a mesh can only wear one as a
## texture. The drawing is kept in a small viewport under the node that wears it, so it goes
## wherever that node goes, as a pickup's look does into the kart that takes it.

## How many frames [method kept] waits at most for a drawing to be drawn.
const KEEP_TRIES := 4


## Draws [param drawing], a control, once into [param pixels] kept under [param parent], and
## returns the texture it is in. With [param msaa] the shapes' edges are smoothed as they are drawn:
## a polygon's edge is not otherwise, and a picture worn large, a floor's print, shows its pixels
## along every one, GAME.md 8.1c. With [param scale] it is drawn that many times as many pixels a
## side, the drawing laid out at [param pixels] as ever and only its pixels finer, its words set at
## the size they come out rather than enlarged, see [method LayoutPrint.screen_scale].
static func of(
	parent: Node, drawing: Control, pixels: Vector2i, msaa := Viewport.MSAA_DISABLED, scale := 1.0
) -> ViewportTexture:
	var render := SubViewport.new()
	render.name = "Drawn"
	render.transparent_bg = true
	render.disable_3d = true
	render.gui_disable_input = true
	render.msaa_2d = msaa
	render.size = Vector2i((Vector2(pixels) * scale).round())
	if render.size != pixels:
		render.size_2d_override = pixels
		render.size_2d_override_stretch = true
	render.render_target_update_mode = SubViewport.UPDATE_ONCE
	drawing.size = Vector2(pixels)
	drawing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	render.add_child(drawing)
	# Drawn again should it be moved, and a viewport taken out of the tree and put back is.
	render.tree_entered.connect(
		func() -> void: render.render_target_update_mode = SubViewport.UPDATE_ONCE
	)
	parent.add_child(render)
	return render.get_texture()


## Draws [param drawing] once into [param pixels] under [param host], as [method of] does, and once
## it has drawn hands [param keep] a picture of it with smaller copies of itself, to be shown
## moved, turned and faded rather than drawn again; the viewport goes then. Nothing is handed on
## where it never draws, with no screen to draw on, nor to [param keep] once its object has gone.
## [param msaa] and [param scale] as for [method of].
static func kept(
	host: Node,
	drawing: Control,
	pixels: Vector2i,
	keep: Callable,
	msaa := Viewport.MSAA_DISABLED,
	scale := 1.0
) -> void:
	of(host, drawing, pixels, msaa, scale)
	var render := host.get_child(host.get_child_count() - 1) as SubViewport
	var keeper := Keeper.new()
	keeper.keep = keep
	render.add_child(keeper)


## Waits in the viewport of [method kept] for it to have drawn, and hands its picture on; goes with
## the viewport, its wait with it, whenever that goes first.
class Keeper:
	extends Node

	var keep: Callable
	var _tries := KEEP_TRIES

	func _ready() -> void:
		RenderingServer.frame_post_draw.connect(_look)

	func _look() -> void:
		var render := get_parent() as SubViewport
		var image := render.get_texture().get_image()
		# Drawn once anything shows: a picture with nothing in its middle, a ring round a clear
		# one, is drawn as much as one that fills it.
		if image == null or image.is_empty() or image.is_invisible():
			_tries -= 1
			if _tries <= 0:
				RenderingServer.frame_post_draw.disconnect(_look)
			return
		RenderingServer.frame_post_draw.disconnect(_look)
		image.generate_mipmaps()
		render.queue_free()
		if keep.is_valid():
			keep.call(ImageTexture.create_from_image(image))


## An unlit, see-through material wearing [param texture], for a face to be branded with.
static func decal(texture: Texture2D) -> StandardMaterial3D:
	var ink := StandardMaterial3D.new()
	ink.albedo_texture = texture
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return ink


## A flat rectangle of [param size] wearing [param material], facing along its own +Z, with no
## shadow of its own.
static func face(size: Vector2, material: Material) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = size
	var shown := MeshInstance3D.new()
	shown.mesh = quad
	shown.material_override = material
	shown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return shown
