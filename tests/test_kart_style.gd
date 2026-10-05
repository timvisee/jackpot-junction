extends GdUnitTestSuite
## Dressing a kart, GAME.md 4.4: a paint pattern, a hat, a flag and a trail, picked per player,
## remembered between sessions, and the same on every screen.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


func _start(styles: Array) -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 7, [], [], styles)
	return match_node


func _named(node: Node, wanted: String) -> Node:
	for child: Node in node.get_children():
		if child.name == wanted:
			return child
		var deeper := _named(child, wanted)
		if deeper != null:
			return deeper
	return null


func test_four_numbers_survive_a_round_trip_and_nonsense_is_dropped() -> void:
	var style := KartStyle.from_array(PackedInt32Array([1, 2, 1, 2]))
	assert_int(style.paint).is_equal(1)
	assert_int(style.hat).is_equal(2)
	assert_int(style.flag).is_equal(1)
	assert_int(style.trail).is_equal(2)
	assert_array(Array(style.to_array())).contains_exactly([1, 2, 1, 2])
	# A choice this build has never heard of is the plain one rather than a crash.
	var wild := KartStyle.from_array(PackedInt32Array([99, -3, 40, 7]))
	assert_array(Array(wild.to_array())).contains_exactly([0, 0, 0, 0])
	# And nothing at all is a kart as it comes.
	assert_array(Array(KartStyle.from_array(null).to_array())).contains_exactly([0, 0, 0, 0])


## The paint is a pattern laid over the player's color, not instead of it.
func test_paint_keeps_the_player_color_and_only_the_plain_one_has_no_pattern() -> void:
	var plain := KartDress.paint(Palette.player_color(0), KartStyle.new())
	assert_object(plain.albedo_color).is_equal(Palette.player_color(0))
	assert_object(plain.albedo_texture).is_null()
	var striped := KartDress.paint(Palette.player_color(0), KartStyle.from_array([1, 0, 0, 0]))
	assert_object(striped.albedo_color).is_equal(Palette.player_color(0))
	assert_object(striped.albedo_texture).is_not_null()
	assert_bool(striped.uv1_triplanar).is_true()
	# Every pattern is built once and handed out, rather than made per kart.
	assert_object(KartDress.pattern_texture(2)).is_same(KartDress.pattern_texture(2))
	assert_object(KartDress.pattern_texture(1)).is_not_same(KartDress.pattern_texture(2))


func test_a_dressed_kart_wears_all_of_it() -> void:
	var match_node := _start([PackedInt32Array([2, 3, 1, 2]), PackedInt32Array()])
	await _runner.simulate_frames(12, 17)
	var dressed := match_node.kart_of(0)
	var plain := match_node.kart_of(1)
	assert_int(dressed.style.hat).is_equal(3)
	assert_object(_named(dressed, "Hat")).is_not_null()
	assert_object(_named(dressed, "Flag")).is_not_null()
	assert_int(dressed.smoke.trail).is_equal(2)
	# The kart nobody dressed is the kart as it comes.
	assert_object(_named(plain, "Hat")).is_null()
	assert_object(_named(plain, "Flag")).is_null()
	assert_int(plain.smoke.trail).is_equal(0)
	# The marker over a hatted kart stands clear of the hat rather than through it.
	var marker: Node3D = _named(dressed, "RoofMarker")
	assert_object(marker).is_not_null()
	assert_float(marker.position.y).is_greater(KartVisuals.MARKER_HEIGHT)
	assert_float(_named(plain, "RoofMarker").position.y).is_equal(KartVisuals.MARKER_HEIGHT)


## GAME.md 4.4: every player color has a roof marker shape of its own, so a room of eight is eight
## shapes and a color is never the only way to tell two karts apart.
func test_every_color_has_a_roof_marker_of_its_own() -> void:
	var seen: Dictionary[String, int] = {}
	for color: int in Palette.PLAYER_COLORS.size():
		var shape := KartVisuals.marker_shape(color)
		var cylinder := shape as CylinderMesh
		var sphere := shape as SphereMesh
		var key := shape.get_class()
		if cylinder != null:
			key += " top %.2f" % cylinder.top_radius
		elif sphere != null:
			key += " sides %d" % sphere.radial_segments
		(
			assert_bool(seen.has(key))
			. override_failure_message("%d is %d's" % [color, seen.get(key, -1)])
			. is_false()
		)
		seen[key] = color


## Every hat there is to pick is a hat with a height the roof marker clears, the learner's
## block too, the driving school's L on its sides and its top, GAME.md 4.4 and 9.4a.
func test_every_hat_is_worn_and_the_learner_wears_the_block() -> void:
	assert_int(KartDress.HAT_LIFT.size()).is_equal(KartStyle.HATS.size())
	for index: int in range(1, KartStyle.HATS.size()):
		var hat: Node3D = auto_free(KartDress.hat(index, Color.RED))
		assert_object(hat).is_not_null()
		assert_float(KartDress.HAT_LIFT[index]).is_greater(0.0)
	var learner := KartStyle.HATS.find("Learner")
	assert_int(learner).is_greater(0)
	var worn: Node3D = auto_free(KartDress.hat(learner, Color.RED))
	var block := worn.find_child("LearnerBlock", true, false)
	assert_object(block).is_not_null()
	# Four sides and the top, each the L.
	assert_int(block.find_children("*", "MeshInstance3D", false, false).size()).is_equal(6)
	# A style with it survives the wire.
	var style := KartStyle.from_array(PackedInt32Array([0, learner, 0, 0]))
	assert_int(style.hat).is_equal(learner)


## GAME.md 10.3: a kart looks the same on every screen, so the dress rides with it.
func test_a_dressed_kart_reaches_a_client() -> void:
	var host := _start([PackedInt32Array([3, 2, 2, 1])])
	await _runner.simulate_frames(12, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = RULES.duplicate()
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(host.build_snapshot())
	await _runner.simulate_frames(2, 17)
	var puppet: Kart = client.slots[0].kart
	assert_object(puppet).is_not_null()
	assert_array(Array(puppet.style.to_array())).contains_exactly([3, 2, 2, 1])
	assert_object(_named(puppet, "Hat")).is_not_null()


## Four blank seats, so a test of the lobby is a test of the lobby rather than of whatever the
## person at this keyboard last dressed their kart in.
func _plain_settings() -> Array:
	var saved: Array = Game.settings.kart_styles
	Game.settings.kart_styles = [
		PackedInt32Array([0, 0, 0, 0]),
		PackedInt32Array([0, 0, 0, 0]),
		PackedInt32Array([0, 0, 0, 0]),
		PackedInt32Array([0, 0, 0, 0]),
	]
	return saved


## GAME.md 4.4: a decoy is only worth anything for as long as somebody takes it for you, so it
## wears what you wear.
func test_a_decoy_is_dressed_like_its_owner() -> void:
	var match_node := _start([PackedInt32Array([2, 3, 1, 1])])
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var item: DecoyKartPowerUp = load("res://data/powerups/decoy_kart.tres")
	item.activate(kart)
	await _runner.simulate_frames(4, 17)
	var decoy: Kart = null
	for child: Node in match_node.get_children():
		var other := child as Kart
		if other != null and other.is_decoy():
			decoy = other
	assert_object(decoy).is_not_null()
	assert_array(Array(decoy.style.to_array())).contains_exactly([2, 3, 1, 1])
	assert_object(_named(decoy, "Hat")).is_not_null()
	assert_object(_named(decoy, "Flag")).is_not_null()
