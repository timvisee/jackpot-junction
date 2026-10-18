extends GdUnitTestSuite
## The loyalty program's first look and its bets won shown, GAME.md 8.9: where the map opens, the
## House's tour of four steps and when it comes, the bets won since the map last showed them shown
## being won, How it works, and the picture of a pin. See [LoyaltyTour], [LoyaltyReveal],
## [LoyaltyOpening] and [PinPicture].

const PATH := "user://test_loyalty_tour.cfg"

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.profile.story.on = false
	var state := Game.settings.profile.loyalty
	state.welcomed = true
	state.win(&"slip_road")
	state.look_at(&"slip_road")
	_holder = Control.new()
	_holder.size = Vector2(1600.0, 900.0)
	add_child(_holder)


func after_test() -> void:
	Engine.time_scale = 1.0
	LoyaltyOpening.watched = false
	LoyaltyDialog.listed = false
	LoyaltyDialog.stood_at = &""
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _open(at := &"") -> LoyaltyDialog:
	var dialog := LoyaltyDialog.open(_holder, false, at)
	await get_tree().process_frame
	await get_tree().process_frame
	return dialog


func _press(action: StringName) -> InputEventAction:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	return press


## Frames until [param done] says so, as fast as the clock goes; false if it never does.
func _until(done: Callable, frames := 400) -> bool:
	for i: int in frames:
		if done.call():
			return true
		await get_tree().process_frame
	return done.call()


## A new member's map opens at the nearest open bet, the one the first map came furthest with,
## never at the slip road it won by activating its card; what is pinned comes before it, and where
## the cursor was left before that; asked for a landmark, there; an edition owed, the roundabout.
func test_where_the_map_opens() -> void:
	var profile := Game.settings.profile
	profile.stats[&"driven"] = 4000.0
	assert_str(String(LoyaltyOpening.of(profile, &"", &"", false).start)).is_equal("racing_stripes")
	profile.stats[&"banks"] = 20.0
	assert_str(String(Loyalty.nearest_open(profile))).is_equal("dealers_visor")
	var left := LoyaltyOpening.of(profile, &"", &"racing_stripes", false)
	assert_str(String(left.start)).is_equal("racing_stripes")
	profile.loyalty.pinned = &"dealers_visor"
	assert_str(String(LoyaltyOpening.of(profile, &"", &"racing_stripes", false).start)).is_equal(
		"dealers_visor"
	)
	assert_str(String(LoyaltyOpening.of(profile, &"rare_cards", &"", false).start)).is_equal(
		"rare_cards"
	)
	profile.loyalty.owed = 1
	assert_str(String(LoyaltyOpening.of(profile, &"", &"", false).start)).is_equal("roundabout")


## A bet won since the map last showed it is where the map opens, to be shown being won, while
## somebody watches; nobody watching, it keeps its NEW tag and the map rests where it would.
func test_a_bet_won_is_where_it_opens() -> void:
	var profile := Game.settings.profile
	profile.loyalty.win(&"dealers_visor")
	var opening := LoyaltyOpening.of(profile, &"", &"", false)
	assert_array(opening.showing).is_empty()
	LoyaltyOpening.watched = true
	opening = LoyaltyOpening.of(profile, &"", &"", false)
	assert_array(opening.showing).contains_exactly([&"dealers_visor"])
	assert_str(String(opening.start)).is_equal("dealers_visor")
	assert_bool(opening.touring).is_false()


## The map as it was before its bets were won: those not won, the rest of the profile the same.
func test_held_back_is_the_map_as_it_was() -> void:
	var profile := Game.settings.profile
	profile.loyalty.win(&"dealers_visor")
	profile.stats[&"driven"] = 1234.0
	var before := LoyaltyReveal.held_back(profile, [&"dealers_visor"])
	assert_bool(before.loyalty.has_won(&"dealers_visor")).is_false()
	assert_bool(before.loyalty.has_won(&"slip_road")).is_true()
	assert_bool(profile.loyalty.has_won(&"dealers_visor")).is_true()
	assert_float(before.stats[&"driven"]).is_equal(1234.0)
	assert_bool(before.transient).is_true()
	var rare := Loyalty.map().landmark(&"rare_cards")
	assert_int(Loyalty.standing(before, rare)).is_equal(Loyalty.Standing.CLOSED)
	assert_int(Loyalty.standing(profile, rare)).is_equal(Loyalty.Standing.OPEN)


## Opened with two bets won, it shows each being won in the order they were won, the cursor at each
## in turn, its NEW tag gone; then the map is drawn as it is and the showing is gone.
func test_bets_won_are_shown_one_after_another() -> void:
	LoyaltyOpening.watched = true
	var profile := Game.settings.profile
	profile.loyalty.win(&"dealers_visor")
	profile.loyalty.win(&"rare_cards")
	var dialog := await _open()
	assert_str(String(dialog.cursor.at)).is_equal("dealers_visor")
	var reveal := dialog.map_view.reveal
	assert_object(reveal).is_not_null()
	assert_bool(dialog.map_view.profile == profile).is_false()
	assert_bool(dialog.map_view.profile.loyalty.has_won(&"rare_cards")).is_false()
	# The roads drawn out of the first and the signs they open.
	assert_array(reveal.opens_of(1)).is_not_empty()
	var came: Array[StringName] = []
	reveal.came_to.connect(func(id: StringName) -> void: came.append(id))
	Engine.time_scale = 20.0
	assert_bool(await _until(func() -> bool: return dialog.map_view.reveal == null)).is_true()
	Engine.time_scale = 1.0
	assert_array(came).contains([&"rare_cards"])
	assert_str(String(dialog.cursor.at)).is_equal("rare_cards")
	assert_bool(profile.loyalty.is_fresh(&"dealers_visor")).is_false()
	assert_bool(profile.loyalty.is_fresh(&"rare_cards")).is_false()
	assert_bool(dialog.map_view.profile == profile).is_true()


## Six at the most are shown one after another, the last won; those won before them are seen.
func test_six_at_the_most() -> void:
	var profile := Game.settings.profile
	var ids: Array[StringName] = [
		&"dealers_visor",
		&"rare_cards",
		&"chip_trail",
		&"card_suits",
		&"more_rare_cards",
		&"decoy_and_wipe",
		&"high_stakes",
		&"racing_stripes"
	]
	for id: StringName in ids:
		profile.loyalty.win(id)
	var showing := LoyaltyReveal.due(profile, LoyaltyMapLayout.Sheet.HOUSE)
	assert_int(showing.size()).is_equal(LoyaltyReveal.MOST)
	assert_str(String(showing[-1])).is_equal("racing_stripes")
	assert_bool(profile.loyalty.is_fresh(&"dealers_visor")).is_false()
	assert_bool(profile.loyalty.is_fresh(&"chip_trail")).is_true()


## A press while they are shown shows the rest at once, the cursor at the last.
func test_a_press_shows_the_rest_at_once() -> void:
	LoyaltyOpening.watched = true
	var profile := Game.settings.profile
	profile.loyalty.win(&"dealers_visor")
	profile.loyalty.win(&"rare_cards")
	var dialog := await _open()
	var reveal := dialog.map_view.reveal
	dialog._input(_press(&"ui_accept"))
	assert_bool(reveal.is_done()).is_true()
	assert_str(String(dialog.cursor.at)).is_equal("rare_cards")
	assert_bool(profile.loyalty.is_fresh(&"dealers_visor")).is_false()
	assert_bool(dialog.map_view.profile == profile).is_true()


## Opened on the list, nothing is shown being won: the bets keep their NEW tags.
func test_the_list_shows_nothing_being_won() -> void:
	LoyaltyOpening.watched = true
	LoyaltyDialog.listed = true
	var profile := Game.settings.profile
	profile.loyalty.win(&"dealers_visor")
	var dialog := await _open()
	assert_object(dialog.map_view.reveal).is_null()
	assert_bool(profile.loyalty.is_fresh(&"dealers_visor")).is_true()
	assert_bool(dialog.map_view.profile == profile).is_true()


## The tour comes as the welcome opens the map, and once for a profile welcomed before it came that
## has won nothing past the slip road; never once it has been, nor for one that has won more.
func test_when_the_tour_comes() -> void:
	var profile := Game.settings.profile
	assert_bool(LoyaltyTour.due(profile, false)).is_true()
	profile.loyalty.win(&"dealers_visor")
	assert_bool(LoyaltyTour.due(profile, false)).is_false()
	assert_bool(LoyaltyTour.due(profile, true)).is_true()
	profile.loyalty.toured = true
	assert_bool(LoyaltyTour.due(profile, true)).is_false()
	profile.loyalty.toured = false
	profile.loyalty.welcomed = false
	assert_bool(LoyaltyTour.due(profile, true)).is_false()


## Kept in the profile once it has been shown.
func test_toured_is_kept() -> void:
	Game.settings.profile.loyalty.toured = true
	Game.settings.save_to_disk()
	var again := Settings.new()
	again.path = PATH
	again.load_from_disk()
	assert_bool(again.profile.loyalty.toured).is_true()


## The four steps: the slip road shown being won and said, a press bringing it at once; the kart
## driven to the nearest open bet and its slip's parts named; pinning it, Pin it pinning it; the
## map drawn back to all of it; and Let's play putting the map away, the tour kept as shown.
func test_the_four_steps() -> void:
	LoyaltyOpening.watched = true
	var profile := Game.settings.profile
	profile.stats[&"banks"] = 3.0
	var dialog := await _open()
	var tour := dialog.tour
	assert_object(tour).is_not_null()
	assert_int(tour.step).is_equal(LoyaltyTour.Step.HERE)
	assert_str(String(dialog.cursor.at)).is_equal("slip_road")
	assert_object(dialog.map_view.reveal).is_not_null()
	# Nothing of the map hears a key while it is up.
	dialog._input(_press(&"ui_right"))
	assert_str(String(dialog.cursor.at)).is_equal("slip_road")
	tour._input(_press(&"ui_accept"))
	assert_bool(tour._tag_up).is_true()
	assert_str(tour._tag.heading.text).is_equal("You are here")
	assert_str(tour._tag.chip.text).is_equal("1/4")
	assert_bool(dialog.map_view.reveal == null or dialog.map_view.reveal.is_done()).is_true()
	tour._on()
	assert_int(tour.step).is_equal(LoyaltyTour.Step.COUNTS)
	Engine.time_scale = 20.0
	assert_bool(await _until(func() -> bool: return tour._tag_up)).is_true()
	Engine.time_scale = 1.0
	assert_str(String(dialog.cursor.at)).is_equal("dealers_visor")
	assert_str(String(dialog.pane.shown)).is_equal("dealers_visor")
	assert_str(tour._tag.line.text).contains("every open bet at once")
	tour._on()
	assert_int(tour.step).is_equal(LoyaltyTour.Step.PIN)
	assert_object(tour._picture).is_not_null()
	# It waits for one of its buttons.
	tour._on()
	assert_int(tour.step).is_equal(LoyaltyTour.Step.PIN)
	(
		assert_array(tour._tag.goes.map(func(b: Button) -> String: return b.text))
		. contains_exactly([LoyaltyTour.NOT_NOW, LoyaltyTour.PIN_IT])
	)
	tour._on_pressed(LoyaltyTour.PIN_IT)
	assert_str(String(profile.loyalty.pinned)).is_equal("dealers_visor")
	assert_int(tour.step).is_equal(LoyaltyTour.Step.JACKPOT)
	var ended: Array[bool] = []
	tour.ended.connect(func(played: bool) -> void: ended.append(played))
	tour._on_pressed(LoyaltyTour.PLAY)
	assert_array(ended).contains_exactly([true])
	assert_bool(profile.loyalty.toured).is_true()
	assert_bool(dialog.to_play).is_true()
	assert_bool(dialog.is_closing()).is_true()


## Not now pins nothing, and Back skips the rest, kept as shown, the map left open to the cursor.
func test_not_now_and_back() -> void:
	LoyaltyOpening.watched = true
	var profile := Game.settings.profile
	var dialog := await _open()
	var tour := dialog.tour
	tour._hurry()
	tour._go(LoyaltyTour.Step.COUNTS)
	dialog.cursor.finish()
	tour._at_bet()
	tour._go(LoyaltyTour.Step.PIN)
	tour._on_pressed(LoyaltyTour.NOT_NOW)
	assert_str(String(profile.loyalty.pinned)).is_equal("")
	assert_int(tour.step).is_equal(LoyaltyTour.Step.JACKPOT)
	tour._input(_press(&"ui_cancel"))
	assert_object(dialog.tour).is_null()
	assert_bool(profile.loyalty.toured).is_true()
	assert_bool(dialog.is_closing()).is_false()
	assert_bool(dialog.to_play).is_false()


## At the third step a click on the slip's own Pin goes through to it.
func test_the_slips_pin_takes_a_click() -> void:
	LoyaltyOpening.watched = true
	var dialog := await _open()
	var tour := dialog.tour
	tour._hurry()
	tour._go(LoyaltyTour.Step.COUNTS)
	dialog.cursor.finish()
	tour._at_bet()
	var pin := tour._global(dialog.pane.pin)
	assert_bool(tour._has_point(pin.get_center())).is_true()
	tour._go(LoyaltyTour.Step.PIN)
	assert_bool(tour._has_point(pin.get_center())).is_false()
	assert_bool(tour._has_point(Vector2(4.0, 4.0))).is_true()
	dialog.pane.pin.pressed.emit()
	assert_str(String(Game.settings.profile.loyalty.pinned)).is_equal(String(dialog.pane.shown))
	assert_int(tour.step).is_equal(LoyaltyTour.Step.JACKPOT)


## Shown round once, How it works and its bind show it again from its first step.
func test_how_it_works_shows_it_again() -> void:
	Game.settings.profile.loyalty.toured = true
	LoyaltyOpening.watched = true
	var dialog := await _open()
	assert_object(dialog.tour).is_null()
	dialog._input(_press(InputActions.MENU_HELP))
	assert_object(dialog.tour).is_not_null()
	assert_int(dialog.tour.step).is_equal(LoyaltyTour.Step.HERE)
	dialog.tour._end(false)
	assert_object(dialog.tour).is_null()
	dialog.how_ticket.pressed.emit()
	assert_object(dialog.tour).is_not_null()


## A pin's picture is the strip by the clock where a screen has room for it, and the pause menu's
## note otherwise, each saying the bet as a pin says it.
func test_the_pins_picture() -> void:
	var profile := Game.settings.profile
	profile.stats[&"banks"] = 5.0
	var wide: PinPicture = auto_free(PinPicture.of(profile, &"dealers_visor", 1920.0))
	assert_bool(wide.strip).is_true()
	assert_array(wide.words).contains_exactly(["The Cashier's Cage", "5 / 25"])
	var narrow: PinPicture = auto_free(PinPicture.of(profile, &"dealers_visor", 900.0))
	assert_bool(narrow.strip).is_false()
	assert_str(narrow.bet).is_equal(Loyalty.bet_of(Loyalty.map().landmark(&"dealers_visor")))
