extends "res://tests/test_online.gd"
## Every test of [code]test_online.gd[/code] again, over a line with the round trip of a slow LAN,
## see [NetLag]: what works with no round trip at all has to work with one.

## What became of a chip on the client's floor: still there, flown into a kart, or blinked out.
enum { WATCHING, FLEW, BLINKED }

## An open floor with nothing on it to get in a kart's way: a kart from either spawn drives
## through the middle and on to the far corner, well clear of the other one.
const OPEN_FLOOR := (
	"########################################\n"
	+ "#S....................................S#\n"
	+ "#......................................#\n"
	+ "#......................................#\n"
	+ "#......................................#\n"
	+ "#......................................#\n"
	+ "########################################"
)


func _init() -> void:
	port = 7891


func before_test() -> void:
	super()
	NetLag.ping = 0.05
	NetLag.jitter = 0.01


func after_test() -> void:
	NetLag.ping = 0.0
	NetLag.jitter = 0.0
	super()


## GAME.md 10.3: a line that puts packets out of order never shows a client an older snapshot over
## a newer one, which would run its clock backwards and its karts back the way they had come.
func test_a_late_snapshot_is_not_shown_over_a_newer_one() -> void:
	NetLag.jitter = 0.04
	var pair := await _pair()
	var client_match: Match = pair[1]
	var clocks: Array[float] = []
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 2000:
		clocks.append(client_match.time_left)
		await get_tree().process_frame
	var backwards := 0
	for i: int in range(1, clocks.size()):
		if clocks[i] > clocks[i - 1] + 0.001:
			backwards += 1
	(
		assert_int(backwards)
		. override_failure_message("the clock ran back %d times" % backwards)
		. is_zero()
	)


## GAME.md 8.3 and 10.3: what a client's own kart drives through flat out flies into it on the
## client's screen rather than blinking out. The kart there runs ahead of the host's by the round
## trip, so by the time the host's word that a chip has gone arrives it is well past the chip.
func test_what_a_client_drives_through_flies_into_its_kart() -> void:
	var open := ArenaLayout.new()
	open.grid = OPEN_FLOOR
	var pair := await _pair(open)
	var host_match: Match = pair[0]
	var client_match: Match = pair[1]
	var client_session: NetSession = pair[2]
	var host_kart := host_match.kart_of(client_session.local_slot)
	client_session.local_input.throttle = 1.0
	client_session.local_input.nitro = true
	await await_millis(400)
	# A chip laid a little way down the road every so often, wherever the road goes, so the kart
	# runs through them at whatever speed it has got up to.
	var chips: Array[Chip] = []
	var flew: Dictionary[int, int] = {}
	var fastest := 0.0
	for i: int in 10:
		var chip := Chip.new()
		chip.value = 1
		host_match.arena.pickups.add_child(chip)
		var heading := host_kart.motor.velocity.normalized()
		chip.global_position = host_kart.global_position + heading * 3.0
		chips.append(chip)
		fastest = maxf(fastest, host_kart.motor.velocity.length())
		await await_millis(100)
		_watch_leaving(client_match, chips, flew)
	await await_millis(500)
	var seen_taken := flew.keys().filter(func(id: int) -> bool: return flew[id] != WATCHING)
	assert_int(seen_taken.size()).override_failure_message("took too few").is_greater(3)
	assert_float(fastest).is_greater(10.0)
	var blinked := flew.keys().filter(func(id: int) -> bool: return flew[id] == BLINKED)
	assert_int(blinked.size()).override_failure_message("%d blinked out" % blinked.size()).is_zero()


## Hooks the client's copy of each chip in [param chips] it has heard of, to put down in
## [param flew] whether it flew into a kart or blinked out when it went.
func _watch_leaving(client_match: Match, chips: Array[Chip], flew: Dictionary[int, int]) -> void:
	for chip: Chip in chips:
		var id := chip.get_instance_id() if is_instance_valid(chip) else -1
		if id < 0 or flew.has(id) or not client_match.puppet_pickups.has(id):
			continue
		var there: Pickup = client_match.puppet_pickups[id]
		flew[id] = WATCHING
		there.tree_exiting.connect(
			func() -> void: flew[id] = FLEW if there._visual == null else BLINKED
		)


## GAME.md 10.3: a line too slow to play on is warned of, in the client's own corner with how
## slow it is, and beside that player's name in the running order on the host's screen and the
## client's alike.
func test_a_slow_line_is_warned_of_on_both_screens() -> void:
	NetLag.ping = 0.2
	var pair := await _pair(null, true)
	var host_match: Match = pair[0]
	var client_match: Match = pair[1]
	var client_session: NetSession = pair[2]
	var seat := client_session.local_slot
	var timed := func() -> bool: return client_match.slots[seat].round_trip > NetPing.SLOW
	assert_bool(await _wait_until(timed, 3000)).override_failure_message("never timed").is_true()
	assert_float(host_match.slots[seat].round_trip).is_between(180.0, 400.0)
	# The host's own player is at the host, and has no line to be slow.
	assert_float(host_match.slots[0].round_trip).is_zero()
	await await_millis(100)
	var corner: LagWarning = client_match.hud._blocks[seat]["lag"]
	assert_bool(corner.is_up()).is_true()
	for hud: MatchHud in [host_match.hud, client_match.hud]:
		var row: LagWarning = hud._scoreboard._rows[seat]["lag"]
		assert_bool(row.is_up()).is_true()
		var own: LagWarning = hud._scoreboard._rows[0]["lag"]
		assert_bool(own.is_up()).is_false()


## A line as quick as a LAN's is not warned of, but one gone quiet is, however quick it last was:
## a client that has heard nothing from the host for a while is as slow as the wait.
func test_a_quick_line_is_not_warned_of_but_a_quiet_one_is() -> void:
	# Quicker than the rest of this suite's line, well clear of the warning's edge.
	NetLag.ping = 0.03
	NetLag.jitter = 0.0
	var pair := await _pair(null, true)
	var client_match: Match = pair[1]
	var client_session: NetSession = pair[2]
	var seat := client_session.local_slot
	var timed := func() -> bool: return client_match.slots[seat].round_trip > 0.0
	assert_bool(await _wait_until(timed, 3000)).is_true()
	await await_millis(600)
	assert_float(client_match.slots[seat].round_trip).is_between(20.0, NetPing.SLOW)
	var corner: LagWarning = client_match.hud._blocks[seat]["lag"]
	assert_bool(corner.is_up()).is_false()
	client_match.heard_at = Time.get_ticks_msec() - 900
	assert_float(client_match.hud._round_trip(client_match.slots[seat])).is_greater(850.0)


## A host with a bot for the client to take over, and the client, joined and playing, on
## [param layout] or the usual map, each with a HUD when [param hud]: the host's match, the
## client's and the client's session.
func _pair(layout: ArenaLayout = null, hud := false) -> Array:
	var host_match: Match = auto_free(MATCH_SCENE.instantiate())
	host_match.name = "Match"
	host_match.arena_layout = layout
	host_match.rules = _quick_rules()
	host_match.with_hud = hud
	host_match.offer_size = 0
	_host_root.add_child(host_match)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()]
	host_match.start(inputs, 23)
	var host_session: NetSession = auto_free(NetSession.new())
	host_session.name = "Session"
	host_session.match_node = host_match
	_host_root.add_child(host_session)
	assert_int(host_session.host(port)).is_equal(OK)
	var client_match: Match = auto_free(MATCH_SCENE.instantiate())
	client_match.name = "Match"
	client_match.arena_layout = layout
	client_match.rules = _quick_rules()
	client_match.with_hud = hud
	_client_root.add_child(client_match)
	client_match.start_puppet()
	var client_session: NetSession = auto_free(NetSession.new())
	client_session.name = "Session"
	client_session.match_node = client_match
	client_session.local_input = KartInput.new()
	_client_root.add_child(client_session)
	assert_int(client_session.join("127.0.0.1", port)).is_equal(OK)
	var playing := func() -> bool:
		return (
			client_match.state == Match.State.PLAYING
			and client_session.local_slot >= 0
			and client_match.slots[client_session.local_slot].kart != null
		)
	assert_bool(await _wait_until(playing, 4000)).is_true()
	return [host_match, client_match, client_session]
