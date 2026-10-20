extends GdUnitTestSuite
## A kart a bot is hunting and cannot ram to death, GAME.md 9.1: held off and shot rather than
## bumped and circled.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


func _match() -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([BotInput.new(), BotInput.new()] as Array[KartInput], 13)
	return match_node


## A kart a bot is hunting and cannot ram to death is held off rather than driven into: inside the
## stand-off the bot stops and turns on the spot to keep its cannon on it, closer still it backs
## away, and with nitro burning it goes on in for the ram.
func test_a_bot_holds_off_a_kart_it_cannot_ram_to_death() -> void:
	var match_node := _match()
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var brain: BotBrain = kart.get_node("Brain")
	var enemy := match_node.kart_of(1)
	enemy.get_node("Brain").queue_free()
	await _runner.simulate_frames(1, 17)
	brain.goal = &"hunt"
	brain.target_node = enemy
	kart.face(Vector3(1.0, 0.0, 0.0))
	enemy.global_position = Vector3.ZERO
	enemy.motor.velocity = Vector3.ZERO
	# In the stand-off: no throttle.
	kart.global_position = Vector3(-(BotDrive.STANDOFF - 1.0), 0.0, 0.0)
	brain._steer(1.0 / 60.0)
	assert_float(brain.input.throttle).is_equal(0.0)
	# Too close, in front: backing straight away.
	kart.global_position = Vector3(-(BotDrive.BACK_OFF - 0.8), 0.0, 0.0)
	brain._steer(1.0 / 60.0)
	assert_float(brain.input.brake).is_equal(1.0)
	assert_float(brain.input.steer).is_equal(0.0)
	# Burning nitro, it goes in.
	kart.nitro_active = true
	kart.global_position = Vector3(-(BotDrive.STANDOFF - 1.0), 0.0, 0.0)
	brain._steer(1.0 / 60.0)
	assert_float(brain.input.throttle).is_greater(0.0)
	kart.nitro_active = false
