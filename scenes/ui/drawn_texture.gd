class_name DrawnTexture
extends RefCounted
## A picture drawn once into a texture for something in the world to wear, GAME.md 8.3a: the
## items' and the jokers' pictures are drawn rather than loaded, and a mesh can only wear one as a
## texture. The drawing is kept in a small viewport under the node that wears it, so it goes
## wherever that node goes, as a pickup's look does into the kart that takes it.


## Draws [param drawing], a control, once into a square of [param pixels] kept under
## [param parent], and returns the texture it is in.
static func of(parent: Node, drawing: Control, pixels: int) -> ViewportTexture:
	var render := SubViewport.new()
	render.name = "Drawn"
	render.transparent_bg = true
	render.disable_3d = true
	render.gui_disable_input = true
	render.size = Vector2i.ONE * pixels
	render.render_target_update_mode = SubViewport.UPDATE_ONCE
	drawing.size = Vector2.ONE * pixels
	drawing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	render.add_child(drawing)
	# Drawn again should it be moved, and a viewport taken out of the tree and put back is.
	render.tree_entered.connect(
		func() -> void: render.render_target_update_mode = SubViewport.UPDATE_ONCE
	)
	parent.add_child(render)
	return render.get_texture()


## An unlit, see-through material wearing [param texture], for a face to be branded with.
static func decal(texture: Texture2D) -> StandardMaterial3D:
	var ink := StandardMaterial3D.new()
	ink.albedo_texture = texture
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return ink


## A flat square [param side] across wearing [param material], facing along its own +Z, with no
## shadow of its own.
static func face(side: float, material: Material) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * side
	var shown := MeshInstance3D.new()
	shown.mesh = quad
	shown.material_override = material
	shown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return shown
