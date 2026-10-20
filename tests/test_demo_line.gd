extends GdUnitTestSuite
## The line of the demo for a booth, GAME.md 9.8: Press any button to play along the foot of the
## screen, on the title and in a match's HUD, kept clear of by the camera and put away over the
## payout slip; and the mouse pointer out of sight while nobody moves the mouse.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")


func after_test() -> void:
	Demo.on = false


## On the title the line is the title's; in a match, the HUD's; anywhere else nowhere.
func test_the_line_goes_on_the_title_or_in_the_hud() -> void:
	var title: Control = auto_free(Control.new())
	title.scene_file_path = Game.TITLE_SCENE
	assert_object(DemoHost.line_home(title)).is_same(title)
	var room: Node3D = auto_free(Node3D.new())
	var match_node: Match = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	room.add_child(match_node)
	add_child(room)
	match_node.start([DemoInput.new(0), BotInput.new()] as Array[KartInput], 3)
	assert_object(DemoHost.line_home(room)).is_same(match_node.hud)
	var elsewhere: Node = auto_free(Node.new())
	assert_object(DemoHost.line_home(elsewhere)).is_null()


## In a match the camera keeps the karts out from under the line, as from any panel of the HUD.
func test_the_camera_keeps_clear_of_the_line() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	add_child(match_node)
	match_node.start([DemoInput.new(0), BotInput.new()] as Array[KartInput], 4)
	var covers: HudCovers = match_node.hud.get_node("Covers")
	var line := DemoLine.add_to(match_node.hud)
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(_covered_at_the_foot(covers.covers())).is_true()
	line.wanted = false
	await await_idle_frame()
	assert_bool(_covered_at_the_foot(covers.covers())).is_false()


## The line stands over everything else on the screen, GAME.md 9.8, a joker pick in the HUD, a
## toast, a dialog or a menu, whatever comes up after it; only the loading screen goes over it.
func test_the_line_stands_over_everything_else() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	add_child(match_node)
	match_node.start([DemoInput.new(0), BotInput.new()] as Array[KartInput], 5)
	var line := DemoLine.add_to(match_node.hud)
	assert_object(DemoLine.of(match_node.hud)).is_same(line)
	assert_object(line.home()).is_same(match_node.hud)
	var holder := line.get_parent() as CanvasLayer
	assert_object(holder).is_not_null()
	for under: int in [
		match_node.hud.layer,
		PauseMenu.LAYER,
		CatalogDialog.LAYER,
		AchievementToasts.LAYER,
		LastLines.LAYER,
		NoticePane.LAYER,
	]:
		assert_int(holder.layer).is_greater(under)
	assert_int(holder.layer).is_less(LoadingScreen.LAYER)


## Whether something in [param rects] stands in the middle of the foot of the screen.
func _covered_at_the_foot(rects: Array[Rect2]) -> bool:
	for rect: Rect2 in rects:
		var middle := rect.get_center()
		if middle.x > 0.4 and middle.x < 0.6 and rect.end.y > 0.9:
			return true
	return false


## Over the payout slip the line is put away: the slip's ways on stand where it would.
func test_the_line_is_put_away_over_the_slip() -> void:
	var hud: Control = auto_free(Control.new())
	add_child(hud)
	var slip := Control.new()
	slip.name = "Results"
	slip.visible = false
	hud.add_child(slip)
	var line := DemoLine.add_to(hud)
	line._process(0.016)
	assert_bool(line.visible).is_true()
	slip.visible = true
	line._process(0.016)
	assert_bool(line.visible).is_false()


## The line says how to play, GAME.md 9.8: Press Escape to play on the keys, Press Menu to play on
## a pad, the key or the button drawn in its words, and drawn again as the hand changes.
func test_the_line_says_the_key_or_the_button_that_opens_the_menu() -> void:
	var hud: Control = auto_free(Control.new())
	add_child(hud)
	var line := DemoLine.add_to(hud)
	line.keyboard = true
	line._process(0.016)
	assert_str(line.said()).is_equal("Press Escape to play")
	var words := line.get_node("Words")
	assert_int(words.get_child_count()).is_equal(3)
	line.keyboard = false
	line._process(0.016)
	await await_idle_frame()
	assert_str(line.said()).is_equal("Press Menu to play")
	assert_object(line.get_node("Words")).is_not_same(words)


## The mouse pointer comes back as the mouse moves, and goes again once it has rested.
func test_the_pointer_rests_out_of_sight() -> void:
	Demo.on = true
	var host: DemoHost = auto_free(load(Game.DEMO_HOST).new())
	var moved := InputEventMouseMotion.new()
	moved.relative = Vector2(4.0, 2.0)
	host._input(moved)
	assert_float(host._pointer_left).is_equal(DemoHost.POINTER_REST)
	host._rest_the_pointer(DemoHost.POINTER_REST * 0.5)
	assert_float(host._pointer_left).is_greater(0.0)
	host._rest_the_pointer(DemoHost.POINTER_REST)
	assert_float(host._pointer_left).is_less_equal(0.0)
