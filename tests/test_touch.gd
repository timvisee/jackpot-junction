extends GdUnitTestSuite
## Playing on a touch screen, GAME.md 4.2: the controls drawn over the room and answered finger by
## finger.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")
const BOOST: PowerUp = preload("res://data/powerups/boost.tres")
const SHIELD: PowerUp = preload("res://data/powerups/shield.tres")
const SPREAD: PowerUp = preload("res://data/powerups/spread_cannon.tres")

var _was_enabled := false
var _runner: GdUnitSceneRunner


func before_test() -> void:
	_was_enabled = TouchInput.enabled


func after_test() -> void:
	TouchInput.enabled = _was_enabled
	TouchInput.release()
	Input.emulate_touch_from_mouse = false
	get_tree().paused = false


## The controls on their own, with no match under them: the menu and nothing to drive.
func _controls() -> TouchControls:
	var layer: CanvasLayer = auto_free(CanvasLayer.new())
	var controls := TouchControls.new()
	layer.add_child(controls)
	add_child(layer)
	return controls


## A match with a player at this screen on a touch screen, and the controls the HUD put up for them.
func _driving(jokers: Array[String] = []) -> TouchControls:
	TouchInput.enabled = true
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = true
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 5)
	for id: String in jokers:
		match_node.kart_of(0).jokers.add(load("res://data/jokers/%s.tres" % id))
	_runner = runner
	await runner.simulate_frames(12, 17)
	return match_node.hud.get_node("TouchControls")


## Every word under [param node], for asking what a pane says without walking its boxes.
func _said(node: Node) -> String:
	var words: PackedStringArray = []
	if node is Label:
		words.append((node as Label).text)
	for child: Node in node.get_children():
		words.append(_said(child))
	return " ".join(words)


func _drag(controls: TouchControls, finger: int, at: Vector2) -> void:
	var drag := InputEventScreenDrag.new()
	drag.index = finger
	drag.position = at
	controls._input(drag)


func _touch(controls: TouchControls, finger: int, at: Vector2, down: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = finger
	touch.position = at
	touch.pressed = down
	controls._input(touch)


## Off on a desktop unless asked for, and asked for either way on the command line.
func test_touch_is_for_phones_unless_asked_for() -> void:
	TouchInput.detect(PackedStringArray())
	assert_bool(TouchInput.enabled).is_equal(OS.has_feature("mobile"))
	TouchInput.detect(PackedStringArray(["--touch=1"]))
	assert_bool(TouchInput.enabled).is_true()
	TouchInput.detect(PackedStringArray(["--touch=0"]))
	assert_bool(TouchInput.enabled).is_false()


## The menu button is the way to the room's menu for a player with no Escape key: it opens as the
## finger comes up on it, and not if the finger slid off it first.
func test_the_menu_button_opens_the_rooms_menu() -> void:
	var room: Node = auto_free(Node.new())
	add_child(room)
	var menu := PauseMenu.add_to(room)
	var controls := _controls()
	await await_idle_frame()
	var button := controls.pad(TouchControls.MENU)
	assert_float(button.center.x).is_greater(controls.size.x * 0.5)
	assert_float(button.center.y).is_less(controls.size.y * 0.5)
	_touch(controls, 0, button.center, true)
	assert_int(button.held).is_equal(1)
	assert_bool(menu.is_open()).is_false()
	_touch(controls, 0, button.center, false)
	assert_bool(menu.is_open()).is_true()
	assert_int(button.held).is_equal(0)
	menu.set_paused(false)
	_touch(controls, 1, button.center, true)
	_touch(controls, 1, button.center + Vector2(-300.0, 300.0), false)
	assert_bool(menu.is_open()).is_false()
	# And nothing under the menu is pressed while it is up.
	menu.set_paused(true)
	_touch(controls, 2, button.center, true)
	assert_int(button.held).is_equal(0)


## The slider under the right thumb drives: a thumb down on it is on the zone under it, sliding
## takes it from zone to zone, and it answers to the slider until it comes up, off the ends and the
## side of it too. Nitro and drift hold the gas as well, and brake is the brake alone. Rolled across
## onto fire it fires as well. The player at this screen reads it with everything else; a player on
## a pad of their own does not.
func test_the_slider_drives_the_player_here() -> void:
	var controls := await _driving()
	assert_bool(controls.driving()).is_true()
	var gas := controls.zone_rect(TouchControls.GAS).get_center()
	_touch(controls, 0, gas, true)
	assert_str(String(controls.slid())).is_equal("gas")
	assert_float(TouchInput.throttle).is_equal(1.0)
	var here := PlayerInput.new()
	here.poll(0.016)
	assert_float(here.throttle).is_equal(1.0)
	var pinned := PlayerInput.new(DeviceInput.KEYBOARD)
	pinned.poll(0.016)
	assert_float(pinned.throttle).is_equal(0.0)
	_drag(controls, 0, controls.zone_rect(TouchControls.NITRO).get_center())
	assert_bool(TouchInput.nitro).is_true()
	assert_float(TouchInput.throttle).is_equal(1.0)
	_drag(controls, 0, controls.slider_rect().position - Vector2(0.0, 80.0))
	assert_bool(TouchInput.nitro).is_true()
	_drag(controls, 0, controls.zone_rect(TouchControls.BRAKE).get_center())
	assert_float(TouchInput.brake).is_equal(1.0)
	assert_float(TouchInput.throttle).is_equal(0.0)
	assert_bool(TouchInput.nitro).is_false()
	var drift := controls.zone_rect(TouchControls.DRIFT).get_center()
	_drag(controls, 0, drift + Vector2(-60.0, 200.0))
	assert_bool(TouchInput.handbrake).is_true()
	assert_float(TouchInput.throttle).is_equal(1.0)
	assert_float(TouchInput.brake).is_equal(0.0)
	# Rolled across onto fire at the height of the gas: driving and firing both.
	_drag(controls, 0, controls.pad(TouchControls.FIRE).center)
	assert_str(String(controls.slid())).is_equal("gas")
	assert_float(TouchInput.throttle).is_equal(1.0)
	assert_bool(TouchInput.fire).is_true()
	here.poll(0.016)
	assert_bool(here.fire_pressed).is_true()
	_touch(controls, 0, controls.pad(TouchControls.FIRE).center, false)
	assert_float(TouchInput.throttle).is_equal(0.0)
	assert_bool(TouchInput.fire).is_false()
	assert_str(String(controls.slid())).is_equal("")
	# A finger that comes down again without having been seen to come up is the one finger, and
	# lets go of whatever it was on first.
	_touch(controls, 3, controls.zone_rect(TouchControls.BRAKE).get_center(), true)
	_touch(controls, 3, gas, true)
	assert_str(String(controls.slid())).is_equal("gas")
	assert_float(TouchInput.brake).is_equal(0.0)
	_touch(controls, 3, gas, false)
	# Fire on its own, by another finger.
	_touch(controls, 4, controls.pad(TouchControls.FIRE).center, true)
	assert_bool(TouchInput.fire).is_true()
	assert_float(TouchInput.throttle).is_equal(0.0)


## The stick comes to wherever the left thumb goes down in the lower left and steers by how far it
## is pushed to the side, while the other thumb holds the gas.
func test_the_stick_steers_where_the_thumb_goes_down() -> void:
	var controls := await _driving()
	var down := Vector2(controls.size.x * 0.2, controls.size.y * 0.7)
	_touch(controls, 0, down, true)
	assert_vector(controls._stick_at).is_equal(down)
	assert_float(TouchInput.steer).is_equal(0.0)
	_touch(controls, 1, controls.zone_rect(TouchControls.GAS).get_center(), true)
	_drag(controls, 0, down + Vector2(TouchControls.STICK_RADIUS * 0.5, 40.0))
	assert_float(TouchInput.steer).is_between(0.3, 0.6)
	_drag(controls, 0, down + Vector2(-TouchControls.STICK_RADIUS * 3.0, 0.0))
	assert_float(TouchInput.steer).is_equal(-1.0)
	var here := PlayerInput.new()
	here.poll(0.016)
	assert_float(here.steer).is_equal(-1.0)
	assert_float(here.throttle).is_equal(1.0)
	_touch(controls, 0, down, false)
	assert_float(TouchInput.steer).is_equal(0.0)
	assert_float(TouchInput.throttle).is_equal(1.0)
	assert_vector(controls._stick_at).is_equal(controls.stick_home())
	# The top of the screen is the corner of the HUD, not the stick's.
	_touch(controls, 2, Vector2(controls.size.x * 0.2, controls.size.y * 0.2), true)
	assert_int(controls._stick_finger).is_equal(-1)


## Over the podium there is nothing to drive, and the buttons go rather than sit over its own.
func test_the_driving_buttons_go_when_the_match_is_over() -> void:
	var controls := await _driving()
	controls.match_node.state = Match.State.RESULTS
	assert_bool(controls.driving()).is_false()
	_touch(controls, 0, controls.zone_rect(TouchControls.GAS).get_center(), true)
	assert_float(TouchInput.throttle).is_equal(0.0)


## The item button is always there and faint with nothing to play; with an item in hand, and the
## box it came in open, it plays it.
func test_the_item_button_plays_what_is_in_hand() -> void:
	var controls := await _driving()
	var kart := controls.match_node.kart_of(0)
	kart.held_item = null
	assert_bool(controls.has_item()).is_false()
	kart.held_item = BOOST
	kart.item_reveal_left = 0.5
	assert_bool(controls.has_item()).is_false()
	kart.item_reveal_left = 0.0
	assert_bool(controls.has_item()).is_true()
	var here := PlayerInput.new()
	_touch(controls, 0, controls.pad(TouchControls.ITEM).center, true)
	here.poll(0.016)
	assert_bool(here.use_item_pressed).is_true()
	here.poll(0.016)
	assert_bool(here.use_item_pressed).is_false()
	_touch(controls, 0, controls.pad(TouchControls.ITEM).center, false)
	assert_bool(TouchInput.use_item).is_false()


## A finger held on a card opens the hand on it for as long as it stays, and the other thumb on the
## stick steers the kart rather than walking the cursor off the card; sliding along the hand reads
## the next one. Nothing on the pane names a button, and nothing beside the hand does either.
func test_holding_a_card_reads_it() -> void:
	var controls := await _driving(["hair_trigger", "rubber_bumpers", "curve_ball"])
	var kart := controls.match_node.kart_of(0)
	var hand: JokerHand = controls.match_node.hud._hands[0]
	await _runner.simulate_frames(20, 17)
	assert_int(hand.card_count()).is_equal(3)
	assert_object(hand._cap).is_null()
	var middle: JokerCard = hand._cards[1]
	var on_it := middle.get_global_rect().get_center()
	_touch(controls, 0, on_it, true)
	assert_int(TouchInput.joker_inspect).is_equal(1)
	var stick := Vector2(controls.size.x * 0.2, controls.size.y * 0.7)
	_touch(controls, 1, stick, true)
	_drag(controls, 1, stick + Vector2(TouchControls.STICK_RADIUS, 0.0))
	await _runner.simulate_frames(12, 17)
	assert_bool(kart.menu_open).is_true()
	assert_int(kart.menu_index).is_equal(1)
	assert_int(hand.selected()).is_equal(1)
	assert_bool(hand._detail.visible).is_true()
	assert_str(_said(hand._detail._hints)).contains("Tap the card to keep it open")
	assert_bool(hand.touch_buttons().is_empty()).is_true()
	# The card has lifted out from under the finger; the finger still holds it.
	assert_int(controls._card_in(hand, on_it)).is_equal(1)
	_drag(controls, 0, (hand._cards[2] as JokerCard).get_global_rect().get_center())
	await _runner.simulate_frames(4, 17)
	assert_int(kart.menu_index).is_equal(2)
	_touch(controls, 0, on_it, false)
	await _runner.simulate_frames(4, 17)
	assert_bool(kart.menu_open).is_false()
	assert_int(TouchInput.joker_inspect).is_equal(-1)


## A client's finger on a card goes over the wire with the rest of its controls, so the host holds
## the hand open on the same card, and a client from before touch sends none.
func test_the_card_a_finger_rests_on_goes_over_the_wire() -> void:
	var sent := KartInput.new()
	sent.joker_inspect = 2
	var got := NetInput.new()
	got._apply(NetInput.encode(sent))
	assert_int(got.joker_inspect).is_equal(2)
	var old := NetInput.encode(KartInput.new())
	old.resize(NetInput.FIELDS + 2)
	var older := NetInput.new()
	older.joker_inspect = 1
	older._apply(old)
	assert_int(older.joker_inspect).is_equal(-1)


## A pick open in front of the player here, answerable at once, on a kart waiting to come back.
func _pick(controls: TouchControls) -> JokerOffer:
	var slot := controls.match_node.slots[0]
	slot.kart.die(&"pit", -1)
	await _runner.simulate_frames(2, 17)
	var choices: Array[Joker] = []
	for id: String in ["hair_trigger", "rubber_bumpers", "curve_ball"]:
		choices.append(load("res://data/jokers/%s.tres" % id))
	slot.offer = JokerOffer.new(slot.kart, choices)
	slot.offer.answer_at = 0.0
	slot.respawn_left = 30.0
	await _runner.simulate_frames(4, 17)
	return slot.offer


func _card_center(picker: JokerPicker, index: int) -> Vector2:
	return (picker._cards[index] as JokerCard).get_global_rect().get_center()


## Holding a card of the pick reads it, and letting go after reading takes nothing; a quick tap
## takes the card tapped. The pane says so rather than naming buttons.
func test_a_tap_takes_a_card_of_the_pick_and_a_hold_reads_it() -> void:
	var controls := await _driving()
	var offer := await _pick(controls)
	var picker: JokerPicker = controls.match_node.hud._pickers[0]
	assert_bool(picker.visible).is_true()
	assert_str((picker._detail._hints as Label).text).contains("Tap a card to take it")
	var second := _card_center(picker, 1)
	_touch(controls, 0, second, true)
	await _runner.simulate_frames(3, 17)
	assert_int(offer.selected).is_equal(1)
	controls._pick_since -= 1.0
	_touch(controls, 0, second, false)
	await _runner.simulate_frames(3, 17)
	assert_bool(offer.is_done()).is_false()
	var third := _card_center(picker, 2)
	_touch(controls, 0, third, true)
	await _runner.simulate_frames(1, 17)
	_touch(controls, 0, third, false)
	await _runner.simulate_frames(3, 17)
	assert_bool(offer.is_done()).is_true()
	assert_str(String(offer.taken.id)).is_equal("curve_ball")


## The button under the pane skips the pick, with the stick held by the other thumb; keeping one
## of last map's has nothing to skip to, and no button.
func test_the_button_under_the_pick_skips_it() -> void:
	var controls := await _driving()
	var offer := await _pick(controls)
	var picker: JokerPicker = controls.match_node.hud._pickers[0]
	var button := picker.touch_button()
	assert_object(button).is_not_null()
	assert_str(button.text).is_equal("Skip")
	var stick := Vector2(controls.size.x * 0.2, controls.size.y * 0.7)
	_touch(controls, 0, stick, true)
	var on_it := button.get_global_rect().get_center()
	# Lit up with the pressed look while the finger is on it, and not once it has slid off.
	assert_bool(button.button_pressed).is_false()
	_touch(controls, 1, on_it, true)
	assert_bool(button.button_pressed).is_true()
	_drag(controls, 1, on_it + Vector2(0.0, 300.0))
	assert_bool(button.button_pressed).is_false()
	_drag(controls, 1, on_it)
	assert_bool(button.button_pressed).is_true()
	_touch(controls, 1, on_it, false)
	assert_bool(button.button_pressed).is_false()
	await _runner.simulate_frames(3, 17)
	assert_bool(offer.is_done()).is_true()
	assert_object(offer.taken).is_null()
	offer.stage = JokerOffer.Stage.CHOOSING
	offer.keeping = true
	await _runner.simulate_frames(2, 17)
	assert_object(picker.touch_button()).is_null()


func _hand_card(hand: JokerHand, index: int) -> Vector2:
	return (hand._cards[index] as JokerCard).get_global_rect().get_center()


func _tap(controls: TouchControls, finger: int, at: Vector2) -> void:
	_touch(controls, finger, at, true)
	_touch(controls, finger, at, false)


## A quick tap keeps a card open, with a button each on its pane for dropping and destroying it,
## while the stick still drives; tapping it again closes it, and so does a finger on nothing.
func test_a_tapped_card_stays_open_until_tapped_again() -> void:
	var controls := await _driving(["hair_trigger", "rubber_bumpers", "curve_ball"])
	var kart := controls.match_node.kart_of(0)
	var hand: JokerHand = controls.match_node.hud._hands[0]
	await _runner.simulate_frames(20, 17)
	var first := _hand_card(hand, 0)
	_tap(controls, 0, first)
	await _runner.simulate_frames(4, 17)
	assert_bool(kart.menu_open).is_true()
	assert_int(kart.menu_index).is_equal(0)
	assert_bool(TouchInput.joker_pinned).is_true()
	assert_int(hand.touch_buttons().size()).is_equal(2)
	assert_str(_said(hand._detail._hints)).contains("Tap it again to close it")
	var stick := Vector2(controls.size.x * 0.2, controls.size.y * 0.7)
	_touch(controls, 1, stick, true)
	_drag(controls, 1, stick + Vector2(TouchControls.STICK_RADIUS, 0.0))
	await _runner.simulate_frames(4, 17)
	assert_bool(kart.menu_open).is_true()
	assert_int(kart.menu_index).is_equal(0)
	_touch(controls, 1, stick, false)
	_tap(controls, 0, _hand_card(hand, 0))
	await _runner.simulate_frames(4, 17)
	assert_bool(kart.menu_open).is_false()
	# Open again, and closed by a finger coming down in the middle of the room.
	_tap(controls, 0, _hand_card(hand, 1))
	await _runner.simulate_frames(4, 17)
	assert_int(kart.menu_index).is_equal(1)
	_tap(controls, 0, controls.size * Vector2(0.5, 0.35))
	await _runner.simulate_frames(4, 17)
	assert_bool(kart.menu_open).is_false()
	# Held rather than tapped is only reading it, and letting go closes it.
	_touch(controls, 0, _hand_card(hand, 2), true)
	controls._inspect_since -= 1.0
	_touch(controls, 0, _hand_card(hand, 2), false)
	await _runner.simulate_frames(4, 17)
	assert_bool(kart.menu_open).is_false()


## The pane's buttons drop and destroy the card it is open on, and the pane goes with it.
func test_the_open_card_can_be_dropped_or_destroyed() -> void:
	var controls := await _driving(["hair_trigger", "rubber_bumpers", "curve_ball"])
	var kart := controls.match_node.kart_of(0)
	var hand: JokerHand = controls.match_node.hud._hands[0]
	await _runner.simulate_frames(20, 17)
	_tap(controls, 0, _hand_card(hand, 1))
	await _runner.simulate_frames(4, 17)
	var drop: Button = hand.touch_buttons()[&"drop"]
	_touch(controls, 0, drop.get_global_rect().get_center(), true)
	assert_bool(drop.button_pressed).is_true()
	_touch(controls, 0, drop.get_global_rect().get_center(), false)
	await _runner.simulate_frames(4, 17)
	assert_int(kart.jokers.count()).is_equal(2)
	assert_bool(kart.jokers.ids().has(&"rubber_bumpers")).is_false()
	assert_bool(kart.menu_open).is_false()
	await _runner.simulate_frames(12, 17)
	_tap(controls, 0, _hand_card(hand, 0))
	await _runner.simulate_frames(4, 17)
	var destroy: Button = hand.touch_buttons()[&"destroy"]
	_tap(controls, 0, destroy.get_global_rect().get_center())
	await _runner.simulate_frames(4, 17)
	assert_int(kart.jokers.count()).is_equal(1)
	assert_bool(kart.jokers.ids().has(&"hair_trigger")).is_false()
	assert_bool(kart.menu_open).is_false()


## A kart waiting to come back can keep a card open to read it, and throw none of its hand away.
func test_a_dead_kart_reads_an_open_card_without_the_buttons() -> void:
	var controls := await _driving(["hair_trigger", "rubber_bumpers"])
	var kart := controls.match_node.kart_of(0)
	var hand: JokerHand = controls.match_node.hud._hands[0]
	await _runner.simulate_frames(20, 17)
	kart.die(&"pit", -1)
	controls.match_node.slots[0].respawn_left = 30.0
	await _runner.simulate_frames(4, 17)
	_tap(controls, 0, _hand_card(hand, 0))
	await _runner.simulate_frames(4, 17)
	assert_bool(kart.menu_open).is_true()
	assert_bool(hand.touch_buttons().is_empty()).is_true()
	assert_str(_said(hand._detail._hints)).contains("Tap it again to close it")
	assert_int(kart.jokers.count()).is_equal(2)


## On the grid and while waiting to come back the kart cannot be driven: the stick and the driving
## buttons gray out and press nothing, so a thumb left on fire after a death takes no card of the
## pick, and the gas held through the lamps takes the kart away as they go green.
func test_the_driving_controls_gray_out_while_the_kart_cannot_drive() -> void:
	var controls := await _driving()
	var kart := controls.match_node.kart_of(0)
	assert_bool(controls.can_drive()).is_true()
	kart.frozen = true
	assert_bool(controls.can_drive()).is_false()
	_touch(controls, 0, controls.zone_rect(TouchControls.GAS).get_center(), true)
	assert_float(TouchInput.throttle).is_equal(0.0)
	kart.frozen = false
	await _runner.simulate_frames(1, 17)
	assert_float(TouchInput.throttle).is_equal(1.0)
	_touch(controls, 0, controls.zone_rect(TouchControls.GAS).get_center(), false)
	kart.die(&"pit", -1)
	controls.match_node.slots[0].respawn_left = 30.0
	await _runner.simulate_frames(1, 17)
	assert_bool(controls.can_drive()).is_false()
	_touch(controls, 1, controls.pad(TouchControls.FIRE).center, true)
	var stick := Vector2(controls.size.x * 0.2, controls.size.y * 0.7)
	_touch(controls, 2, stick, true)
	_drag(controls, 2, stick + Vector2(TouchControls.STICK_RADIUS, 0.0))
	await _runner.simulate_frames(1, 17)
	assert_bool(TouchInput.fire).is_false()
	assert_float(TouchInput.steer).is_equal(0.0)


## Once played, what an item started keeps its picture on the button, with how much of it is left:
## a shield counting down in time, a loaded cannon in shots.
func test_the_item_button_shows_what_is_still_running() -> void:
	var controls := await _driving()
	var kart := controls.match_node.kart_of(0)
	assert_bool(controls.running().is_empty()).is_true()
	kart.held_item = SHIELD
	kart.use_item()
	var shield := controls.running()
	assert_str(String(shield["id"])).is_equal("shield")
	assert_float(shield["left"]).is_greater(0.9)
	await _runner.simulate_frames(30, 17)
	assert_float(controls.running()["left"]).is_less(shield["left"])
	for effect: KartEffect in kart.effects:
		effect.finished = true
	await _runner.simulate_frames(2, 17)
	kart.held_item = SPREAD
	kart.use_item()
	var loaded := controls.running()
	assert_str(String(loaded["id"])).is_equal("spread_cannon")
	assert_float(loaded["left"]).is_equal(1.0)


## The pick and the hand under it answer their own fingers: reading a card of the pick leaves the
## hand shut, and reading the hand leaves the pick's cursor where it was.
func test_the_pick_and_the_hand_are_read_apart() -> void:
	var controls := await _driving(["hair_trigger", "rubber_bumpers"])
	var kart := controls.match_node.kart_of(0)
	var hand: JokerHand = controls.match_node.hud._hands[0]
	await _runner.simulate_frames(20, 17)
	var offer := await _pick(controls)
	var picker: JokerPicker = controls.match_node.hud._pickers[0]
	offer.selected = 0
	_touch(controls, 0, _card_center(picker, 2), true)
	await _runner.simulate_frames(3, 17)
	assert_int(offer.selected).is_equal(2)
	assert_bool(kart.menu_open).is_false()
	controls._pick_since -= 1.0
	_touch(controls, 0, _card_center(picker, 2), false)
	await _runner.simulate_frames(3, 17)
	assert_bool(offer.is_done()).is_false()
	_touch(controls, 1, _hand_card(hand, 1), true)
	await _runner.simulate_frames(3, 17)
	assert_bool(kart.menu_open).is_true()
	assert_int(kart.menu_index).is_equal(1)
	assert_int(offer.selected).is_equal(2)


## Whichever of the pick and the hand was touched last is drawn over the other, so the pane being
## read is never under the other's cards; a pick coming up comes up in front, and without one both
## go back to where the HUD put them.
func test_the_last_touched_of_the_pick_and_the_hand_is_on_top() -> void:
	var controls := await _driving(["hair_trigger", "rubber_bumpers"])
	var hand: JokerHand = controls.match_node.hud._hands[0]
	var picker: JokerPicker = controls.match_node.hud._pickers[0]
	await _runner.simulate_frames(20, 17)
	assert_int(hand.z_index).is_equal(0)
	assert_int(picker.z_index).is_equal(0)
	var offer := await _pick(controls)
	assert_str(String(controls.front())).is_equal("pick")
	assert_int(picker.z_index).is_greater(hand.z_index)
	# Into the hand: the hand and its pane come over the pick, and stay there while kept open.
	_tap(controls, 0, _hand_card(hand, 1))
	await _runner.simulate_frames(2, 17)
	assert_str(String(controls.front())).is_equal("hand")
	assert_int(hand.z_index).is_greater(picker.z_index)
	assert_bool(controls.match_node.kart_of(0).menu_open).is_true()
	# Back to the pick: it comes over the hand again.
	_touch(controls, 1, _card_center(picker, 0), true)
	await _runner.simulate_frames(2, 17)
	assert_int(picker.z_index).is_greater(hand.z_index)
	controls._pick_since -= 1.0
	_touch(controls, 1, _card_center(picker, 0), false)
	offer.skip()
	await _runner.simulate_frames(3, 17)
	assert_int(hand.z_index).is_equal(0)
	assert_int(picker.z_index).is_equal(0)


## Only one of the pick and the hand has a card picked out: going to the hand leaves the pick with
## none lifted and no pane, and going back to the pick closes the hand.
func test_only_one_of_the_pick_and_the_hand_has_a_card_out() -> void:
	var controls := await _driving(["hair_trigger", "rubber_bumpers"])
	var kart := controls.match_node.kart_of(0)
	var hand: JokerHand = controls.match_node.hud._hands[0]
	var picker: JokerPicker = controls.match_node.hud._pickers[0]
	await _runner.simulate_frames(20, 17)
	var offer := await _pick(controls)
	assert_bool(picker._detail.visible).is_true()
	assert_int((picker._cards[offer.selected] as JokerCard).z_index).is_equal(1)
	_tap(controls, 0, _hand_card(hand, 1))
	await _runner.simulate_frames(3, 17)
	assert_bool(kart.menu_open).is_true()
	assert_bool(picker.quiet).is_true()
	assert_bool(picker._detail.visible).is_false()
	for card: JokerCard in picker._cards:
		assert_int(card.z_index).is_equal(0)
	assert_object(picker.touch_button()).is_not_null()
	# Back to the pick: its card comes out again and the hand shuts.
	_touch(controls, 1, _card_center(picker, 2), true)
	await _runner.simulate_frames(3, 17)
	assert_bool(picker.quiet).is_false()
	assert_bool(picker._detail.visible).is_true()
	assert_int(offer.selected).is_equal(2)
	assert_bool(kart.menu_open).is_false()
	assert_bool(TouchInput.joker_pinned).is_false()
	controls._pick_since -= 1.0
	_touch(controls, 1, _card_center(picker, 2), false)
	await _runner.simulate_frames(3, 17)
	assert_bool(offer.is_done()).is_false()


## However big the UI is drawn, the touch HUD keeps its pieces off each other: the board hangs
## under the menu button, the hand stays between the stick and the buttons, shrinking to fit a
## narrow lane, the pick's button stays above the hand, and the feed stops short of the buttons.
func test_the_touch_hud_keeps_its_pieces_apart() -> void:
	var controls := await _driving(["hair_trigger", "rubber_bumpers", "curve_ball", "odometer"])
	var hud := controls.match_node.hud
	var board: Control = hud.get_node("Scoreboard")
	assert_float(board.offset_top).is_equal(TouchControls.below_menu())
	assert_float(board.anchor_top).is_equal(0.0)
	var hand: JokerHand = hud._hands[0]
	await _runner.simulate_frames(20, 17)
	var lane := hand.lane
	assert_float(lane.x).is_greater(TouchControls.STICK_HOME.x + TouchControls.STICK_RADIUS)
	for card: JokerCard in hand._cards:
		var rect := card.get_global_rect()
		assert_float(rect.position.x).is_greater_equal(lane.x - 1.0)
		assert_float(rect.end.x).is_less_equal(lane.y + 1.0)
	# A narrow lane shrinks the hand rather than letting it spill out of it. The controls set the
	# lane every frame, so they are held still while this one is tried.
	controls.set_process(false)
	var middle := (lane.x + lane.y) * 0.5
	hand.lane = Vector2(middle - 220.0, middle + 220.0)
	await _runner.simulate_frames(20, 17)
	assert_float((hand._cards[0] as JokerCard).scale.x).is_less(1.0)
	controls.set_process(true)
	var feed: KillFeed = hud.get_node("KillFeed")
	assert_float(feed.room).is_greater(0.0)
	assert_float(TouchControls.feed_top(board) + feed.room).is_less(controls._buttons_top())
	await _pick(controls)
	var picker: JokerPicker = hud._pickers[0]
	await _runner.simulate_frames(4, 17)
	var skip := picker.touch_button()
	assert_float(skip.get_global_rect().end.y).is_less_equal(hand.top())


## Crossing from one zone of the slider into the next clicks, and so does rolling onto fire, so a
## wrong zone is felt without looking; staying in one does not.
func test_the_slider_clicks_from_zone_to_zone() -> void:
	var controls := await _driving()
	var gas := controls.zone_rect(TouchControls.GAS)
	_touch(controls, 0, gas.get_center(), true)
	assert_int(controls.clicks).is_equal(0)
	_drag(controls, 0, gas.get_center() + Vector2(0.0, gas.size.y * 0.3))
	assert_int(controls.clicks).is_equal(0)
	_drag(controls, 0, controls.zone_rect(TouchControls.BRAKE).get_center())
	assert_int(controls.clicks).is_equal(1)
	_drag(controls, 0, controls.zone_rect(TouchControls.DRIFT).get_center())
	assert_int(controls.clicks).is_equal(2)
	_drag(controls, 0, controls.zone_rect(TouchControls.NITRO).get_center())
	assert_int(controls.clicks).is_equal(3)
	_drag(controls, 0, gas.get_center())
	assert_int(controls.clicks).is_equal(4)
	_drag(controls, 0, controls.pad(TouchControls.FIRE).center)
	assert_int(controls.clicks).is_equal(5)
	# The two ends are a little bigger than the brake, for the thumb that reaches for them.
	var brake := controls.zone_rect(TouchControls.BRAKE).size.y
	assert_float(controls.zone_rect(TouchControls.NITRO).size.y).is_greater(brake)
	assert_float(controls.zone_rect(TouchControls.DRIFT).size.y).is_greater(brake)
	assert_float(gas.size.y).is_greater(controls.zone_rect(TouchControls.NITRO).size.y)


## The slider says what it does: its nitro is grayed while the tank is short of a burn, though it
## still holds the gas, and its brake says reverse on a kart standing still or rolling back.
func test_the_slider_says_what_it_does() -> void:
	var controls := await _driving()
	var kart := controls.match_node.kart_of(0)
	kart.nitro_charge = 1.0
	assert_bool(controls.nitro_ready()).is_true()
	kart.nitro_charge = kart.stats.nitro_min_start * 0.5
	assert_bool(controls.nitro_ready()).is_false()
	_touch(controls, 0, controls.zone_rect(TouchControls.NITRO).get_center(), true)
	assert_float(TouchInput.throttle).is_equal(1.0)
	_touch(controls, 0, controls.zone_rect(TouchControls.NITRO).get_center(), false)
	kart.motor.forward_speed = 0.0
	assert_str(controls.zone_word(TouchControls.BRAKE)).starts_with("REV")
	kart.motor.forward_speed = -2.0
	assert_str(controls.zone_word(TouchControls.BRAKE)).starts_with("REV")
	kart.motor.forward_speed = 6.0
	assert_str(controls.zone_word(TouchControls.BRAKE)).is_equal("BRAKE")
	assert_str(controls.zone_word(TouchControls.GAS)).is_equal("GAS")


## The item button is under fire, and far enough under it that a thumb between the two presses one
## of them and not both.
func test_the_item_button_is_under_fire() -> void:
	var controls := await _driving()
	var fire := controls.pad(TouchControls.FIRE)
	var item := controls.pad(TouchControls.ITEM)
	assert_float(item.center.y).is_greater(fire.center.y)
	assert_float(item.center.y + item.radius * TouchControls.REACH).is_less_equal(controls.size.y)
	var between := fire.center.lerp(item.center, fire.radius / (fire.radius + item.radius))
	assert_bool(fire.reaches(between) and item.reaches(between)).is_false()
