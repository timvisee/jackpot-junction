extends GdUnitTestSuite
## Emotes, GAME.md 3.8: a flick of the right stick or a key, a bubble over the kart for a moment,
## decided where the karts are run and put up on every screen.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DT := 1.0 / 60.0

var _runner: GdUnitSceneRunner


## A player whose emotes are whatever the test asks for.
class Emoting:
	extends PlayerInput

	var asked := -1

	func poll(_delta: float) -> void:
		emote = asked
		asked = -1


func after_test() -> void:
	for action: StringName in InputActions.EMOTES + [InputActions.AIM_RIGHT, InputActions.AIM_UP]:
		Input.action_release(action)


func test_a_key_or_a_flick_of_the_right_stick_asks_for_an_emote_once() -> void:
	var player := PlayerInput.new(DeviceInput.ANY, -1)
	Input.action_press(InputActions.EMOTE_3)
	player.poll(DT)
	assert_int(player.emote).is_equal(2)
	player.poll(DT)
	assert_int(player.emote).is_equal(-1)
	Input.action_release(InputActions.EMOTE_3)
	# Right is the second of them; held over it asks once, and up after the middle is the first.
	Input.action_press(InputActions.AIM_RIGHT)
	player.poll(DT)
	assert_int(player.emote).is_equal(1)
	player.poll(DT)
	assert_int(player.emote).is_equal(-1)
	Input.action_release(InputActions.AIM_RIGHT)
	player.poll(DT)
	Input.action_press(InputActions.AIM_UP)
	player.poll(DT)
	assert_int(player.emote).is_equal(0)


func test_an_emote_pops_up_over_the_kart_and_goes() -> void:
	var player := Emoting.new()
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([player] as Array[KartInput], 3)
	await _runner.simulate_frames(10, 17)
	var heard := [0]
	var count := func(_slot: int, _emote: int) -> void: heard[0] += 1
	Events.emoted.connect(count)
	player.asked = 3
	await _runner.simulate_frames(3, 17)
	var kart := match_node.slots[0].kart
	assert_int(heard[0]).is_equal(1)
	assert_object(kart.get_node_or_null("Emote")).is_not_null()
	# Another straight away is too soon to be read, and is not put up.
	player.asked = 1
	await _runner.simulate_frames(3, 17)
	assert_int(heard[0]).is_equal(1)
	await _runner.simulate_frames(int(Emotes.SHOWN * 60.0) + 20, 17)
	assert_object(kart.get_node_or_null("Emote")).is_null()
	Events.emoted.disconnect(count)


func test_an_emote_goes_over_the_wire() -> void:
	var source := KartInput.new()
	source.emote = 2
	var remote := NetInput.new()
	remote.receive(NetInput.encode(source), 1)
	remote.receive(NetInput.encode(KartInput.new()), 2)
	remote.poll(DT)
	assert_int(remote.emote).is_equal(2)
	remote.poll(DT)
	assert_int(remote.emote).is_equal(-1)
	# A client from before emotes sends none.
	var old := NetInput.new()
	var packet := NetInput.encode(source)
	packet.resize(NetInput.FIELDS + 4)
	old.receive(packet, 1)
	old.receive(packet, 2)
	old.poll(DT)
	assert_int(old.emote).is_equal(-1)


func test_every_emote_has_a_picture() -> void:
	for i: int in EmoteArt.EMOTES.size():
		var drawn: EmoteArt.Picture = auto_free(EmoteArt.picture(i, Color.RED, 64.0))
		assert_int(drawn.emote).is_equal(i)
	assert_int(InputActions.EMOTES.size()).is_equal(EmoteArt.EMOTES.size())
