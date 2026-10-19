extends GdUnitTestSuite
## How the room is drawn, GAME.md 8.1b: a look's pass hung on every camera, the light it puts on
## the room's materials, and changing it after a camera that wore its pass has gone, as a match
## that has ended does.


func _look() -> RenderLook:
	var look: RenderLook = auto_free(RenderLook.new())
	add_child(look)
	return look


func test_every_look_has_a_name_and_its_pass_exists() -> void:
	assert_int(RenderLook.ids().size()).is_equal(RenderLook.names().size())
	for row: Array in RenderLook.TABLE:
		assert_array(["made", "toon", "flat"]).contains([row[3]])
		var pass_name: String = row[2]
		if not pass_name.is_empty():
			(
				assert_bool(ResourceLoader.exists("res://scenes/fx/looks/%s.gdshader" % pass_name))
				. is_true()
			)


func test_a_camera_wears_the_pass_of_a_look_that_has_one() -> void:
	var look := _look()
	var camera: Camera3D = auto_free(Camera3D.new())
	add_child(camera)
	look.use("keyline")
	var pass_node := camera.get_node("LookPass") as MeshInstance3D
	assert_bool(pass_node.visible).is_true()
	look.use("clean")
	assert_bool(pass_node.visible).is_false()


func test_the_look_changes_after_a_camera_with_its_pass_has_gone() -> void:
	var look := _look()
	var camera := Camera3D.new()
	add_child(camera)
	look.use("keyline")
	camera.free()
	look.use("cel")
	look.use("halftone")
	assert_str(look.look).is_equal("halftone")
	assert_int(look._quads.size()).is_equal(0)


func test_a_material_takes_the_light_of_the_look_and_gets_its_own_back() -> void:
	var material := StandardMaterial3D.new()
	RenderLook.light_material(material, "toon")
	assert_int(material.diffuse_mode).is_equal(BaseMaterial3D.DIFFUSE_TOON)
	RenderLook.light_material(material, "flat")
	assert_int(material.shading_mode).is_equal(BaseMaterial3D.SHADING_MODE_UNSHADED)
	RenderLook.light_material(material, "made")
	assert_int(material.shading_mode).is_equal(BaseMaterial3D.SHADING_MODE_PER_PIXEL)
	assert_int(material.diffuse_mode).is_equal(BaseMaterial3D.DIFFUSE_BURLEY)
	assert_bool(material.has_meta(RenderLook.KEPT)).is_false()


func test_a_name_that_is_no_look_is_clean() -> void:
	var look := _look()
	look.use("not a look")
	assert_str(look.look).is_equal("clean")
