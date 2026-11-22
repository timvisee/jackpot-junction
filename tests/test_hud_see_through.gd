extends GdUnitTestSuite
## The HUD going see-through over a kart, GAME.md 8.2 and 8.3, see [HudCovers]: a kart driven under
## a player's corner shows through it rather than the camera moving to get it out from under, and
## the corner comes back once the kart has gone. The camera is told only of what nothing shows
## through.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner
var _was_seeing := true


func before_test() -> void:
	_was_seeing = Game.settings.see_through_hud
	Game.settings.see_through_hud = true


func after_test() -> void:
	Game.settings.see_through_hud = _was_seeing


## A match with a player at this screen, its HUD up.
func _playing() -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, -1), KartInput.new()]
	match_node.start(inputs, 5)
	await _runner.simulate_frames(12, 17)
	return match_node


## Where on the floor [param screen], a point on the screen, shows from [param rig]'s camera.
static func _floor_under(rig: CameraRig, screen: Vector2) -> Vector3:
	var from := rig.camera.project_ray_origin(screen)
	var way := rig.camera.project_ray_normal(screen)
	return from + way * (-from.y / way.y)


## [param seconds] of frames of [param gathering] at sixty a second, with nothing else moving.
static func _run(gathering: HudCovers, seconds: float) -> void:
	for i: int in int(seconds * 60.0):
		gathering._process(1.0 / 60.0)


func test_a_corner_goes_see_through_over_a_kart_and_comes_back() -> void:
	var match_node := await _playing()
	var hud := match_node.hud
	var gathering := hud.get_node("Covers") as HudCovers
	var box := hud.block_of(0)
	assert_object(box).is_not_null()
	var kart := match_node.kart_of(1)
	var middle := box.get_global_rect().get_center()
	kart.global_position = _floor_under(match_node.camera_rig, middle)
	_run(gathering, 0.5)
	assert_float(box.modulate.a).is_equal_approx(HudCovers.SEE_THROUGH, 0.01)
	# Gone again: held a moment, then back.
	var screen := hud.get_viewport().get_visible_rect().size
	kart.global_position = _floor_under(match_node.camera_rig, screen * 0.5)
	_run(gathering, HudCovers.CLEAR_FOR * 0.5)
	assert_float(box.modulate.a).is_equal_approx(HudCovers.SEE_THROUGH, 0.01)
	_run(gathering, HudCovers.CLEAR_FOR + HudCovers.FADE_IN + 0.2)
	assert_float(box.modulate.a).is_equal(1.0)


## The camera is not told of the corners, which a kart shows through: what it keeps the karts out
## from under is what nothing shows through, here nothing at all.
func test_the_camera_is_told_only_of_what_nothing_shows_through() -> void:
	var match_node := await _playing()
	var gathering := match_node.hud.get_node("Covers") as HudCovers
	gathering._process(HudCovers.EVERY)
	assert_array(gathering.covers()).is_not_empty()
	assert_array(gathering.kept()).is_empty()
	assert_array(match_node.camera_rig.covers).is_empty()
	# With see-through turned off, GAME.md 8.5, the camera keeps the karts out from under all of it.
	Game.settings.see_through_hud = false
	gathering._process(HudCovers.EVERY)
	assert_array(match_node.camera_rig.covers).is_equal(gathering.covers())


## A panel that sets its own see-through, as the standings do when a joker blinds them, takes it.
func test_the_standings_take_their_share_on_top_of_their_own() -> void:
	var match_node := await _playing()
	var board := match_node.hud.scoreboard()
	HudCovers._show(board, 0.4)
	board._process(0.0)
	assert_float(board.modulate.a).is_equal_approx(0.4, 0.001)
	HudCovers._show(board, 1.0)
	board._process(0.0)
	assert_float(board.modulate.a).is_equal(1.0)


## How far round the kart standing on the floor under [param screen] the HUD counts it as under,
## on the screen, as [method HudCovers._look_under] has it.
static func _reach(rig: CameraRig, screen: Vector2) -> float:
	var middle := _floor_under(rig, screen) + Vector3.UP * CameraRig.KART_MIDDLE
	var side := rig.camera.global_basis.x * ClearView.KART_ROOM
	return rig.camera.unproject_position(middle).distance_to(
		rig.camera.unproject_position(middle + side)
	)


## Stands [param kart] on the floor under [param screen], so its middle is there on the screen.
static func _stand_under(rig: CameraRig, kart: Node3D, screen: Vector2) -> void:
	var floor_at := _floor_under(rig, screen)
	var lifted := rig.camera.unproject_position(floor_at + Vector3.UP * CameraRig.KART_MIDDLE)
	kart.global_position = _floor_under(rig, screen + (screen - lifted))


## The hand of cards goes see-through only for a kart under the cards: not for one over the soft
## dark behind them, which reaches well above them, GAME.md 8.2. The description of a lifted card
## goes on its own, only while it is shown, and the cards stay as they are for a kart under it.
func test_the_cards_and_their_description_go_see_through_apart() -> void:
	var match_node := await _playing()
	var kart := match_node.kart_of(0)
	kart.jokers.add(load("res://data/jokers/hair_trigger.tres"))
	kart.jokers.add(load("res://data/jokers/rubber_bumpers.tres"))
	await _runner.simulate_frames(20, 17)
	var hud := match_node.hud
	var rig := match_node.camera_rig
	var gathering := hud.get_node("Covers") as HudCovers
	var hand := hud.hand_of(0)
	var fan := hand.fan()
	var rival := match_node.kart_of(1)
	var cards := hand.cards_rect()
	var shade := HudCovers._drawn_rect(fan.shade)
	# Over the dark above the cards, clear of the cards by more than a kart's room.
	var above := Vector2(cards.get_center().x, (shade.position.y + cards.position.y) * 0.5)
	assert_float(cards.position.y - above.y).is_greater(_reach(rig, above))
	assert_bool(shade.has_point(above)).is_true()
	_stand_under(rig, rival, above)
	_run(gathering, 0.5)
	assert_float(fan.modulate.a).is_equal(1.0)
	# Under the cards.
	_stand_under(rig, rival, cards.get_center())
	_run(gathering, 0.5)
	assert_float(fan.modulate.a).is_equal_approx(HudCovers.SEE_THROUGH, 0.01)
	_stand_under(rig, rival, hud.get_viewport().get_visible_rect().size * 0.5)
	_run(gathering, HudCovers.CLEAR_FOR + HudCovers.FADE_IN + 0.2)
	assert_float(fan.modulate.a).is_equal(1.0)
	# Hidden, the description is nothing over the room.
	assert_bool(hand.detail().visible).is_false()
	var detail_rect := HudCovers._drawn_rect(hand.detail())
	assert_bool(detail_rect.has_area()).is_false()
	# Lifted, it goes on its own for a kart under it, the cards staying as they are.
	Input.action_press(InputActions.JOKER_MENU)
	await _runner.simulate_frames(10, 17)
	assert_bool(hand.detail().visible).is_true()
	detail_rect = HudCovers._drawn_rect(hand.detail())
	cards = hand.cards_rect()
	var on := Vector2(detail_rect.get_center().x, detail_rect.position.y + detail_rect.size.y * 0.3)
	var gap := on.distance_to(on.clamp(cards.position, cards.end))
	assert_float(gap).is_greater(_reach(rig, on))
	_stand_under(rig, rival, on)
	_run(gathering, 0.5)
	assert_float(hand.detail().modulate.a).is_equal_approx(HudCovers.SEE_THROUGH, 0.01)
	assert_float(fan.modulate.a).is_equal(1.0)
	Input.action_release(InputActions.JOKER_MENU)
	await _runner.simulate_frames(2, 17)
