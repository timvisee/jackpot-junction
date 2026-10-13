extends GdUnitTestSuite
## The toast of GAME.md 8.10: one achievement at a time, the rest waiting their turn; beside the
## corner of the seat that earned it in a room, under a BET WON there; at the top right elsewhere.
## See [AchievementToasts] and [AchievementToast].

var _runner: GdUnitSceneRunner


func _toasts_in(node: Node) -> Array[AchievementToast]:
	var found: Array[AchievementToast] = []
	for child: Node in node.get_children():
		if child is AchievementToast and not child.is_queued_for_deletion():
			found.append(child)
	return found


## Two earned at once come up one after the other, the second once the first has gone.
func test_one_at_a_time() -> void:
	var holder: Node = auto_free(Node.new())
	_runner = scene_runner(holder)
	var layer := AchievementToasts.new()
	holder.add_child(layer)
	var playing := Game.settings.profile.id
	Events.achievement_earned.emit(playing, &"bank_shot", -1)
	Events.achievement_earned.emit(playing, &"parry", -1)
	await _runner.simulate_frames(3, 17)
	var up := _toasts_in(layer)
	assert_int(up.size()).is_equal(1)
	assert_str(String(up[0].achievement.id)).is_equal("bank_shot")
	await _runner.simulate_frames(int(AchievementToast.LASTS * 60.0) + 10, 17)
	up = _toasts_in(layer)
	assert_int(up.size()).is_equal(1)
	assert_str(String(up[0].achievement.id)).is_equal("parry")


## Beside a seat's block it stands toward the middle of the screen, level with the block's top, and
## under a BET WON already beside it rather than over it.
func test_beside_the_block_and_under_a_bet_won() -> void:
	var hud: Control = auto_free(Control.new())
	hud.size = Vector2(1920.0, 1080.0)
	_runner = scene_runner(hud)
	var block := Control.new()
	block.name = "Block0"
	block.position = Vector2(20.0, 20.0)
	block.size = Vector2(300.0, 100.0)
	hud.add_child(block)
	var bank_shot := Achievements.find(&"bank_shot")
	var toast := AchievementToast.of(bank_shot, "", block)
	hud.add_child(toast)
	await _runner.simulate_frames(30, 17)
	assert_float(toast.position.x).is_equal_approx(332.0, 0.5)
	assert_float(toast.position.y).is_equal_approx(20.0, 0.5)
	toast.queue_free()
	var stamp := LoyaltyStamp.show_beside(hud, 0, Loyalty.map().landmark(&"dealers_visor"))
	var under := AchievementToast.of(bank_shot, "", block)
	hud.add_child(under)
	await _runner.simulate_frames(30, 17)
	assert_float(under.position.y).is_greater_equal(20.0 + stamp.size.y)


## With no block it comes in at the top right corner of the screen.
func test_at_the_top_right_elsewhere() -> void:
	var screen: Control = auto_free(Control.new())
	_runner = scene_runner(screen)
	var toast := AchievementToast.of(Achievements.find(&"street_legal"))
	screen.add_child(toast)
	await _runner.simulate_frames(30, 17)
	var width := toast.get_viewport_rect().size.x
	assert_float(toast.position.x).is_equal_approx(
		width - AchievementToast.SIZE.x - AchievementToast.INSET, 0.5
	)
	assert_float(toast.position.y).is_equal_approx(AchievementToast.INSET, 0.5)


## The profile playing's toast names nobody; a profile nobody sits in is nobody's either.
func test_whose_name_it_carries() -> void:
	assert_str(AchievementToasts._named(Game.settings.profile.id)).is_empty()
	assert_str(AchievementToasts._named("no such profile")).is_empty()
