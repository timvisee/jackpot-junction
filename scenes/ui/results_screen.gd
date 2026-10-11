class_name ResultsScreen
extends Control
## The end of a match, GAME.md 3.8: everybody ranked by what they banked, with kills and deaths
## beside it and up to three awards under each name for whatever they did most.
##
## Its own screen rather than part of [MatchHud], which is about the match while it is being
## played. This is about the match once it is over, and it is the last thing anybody looks at.
##
## A payout slip, GAME.md 8.1a: a document rather than a pane, cream paper torn off the house's
## printer with the winner's color in the hairline inside its edge, one long bill run off the
## screen, see [PayoutBill]. Its pages are printed one under another, see [SlipPage]: the map just
## played, then in a Grand Prix how the run stands, and at the Final Hand the House's evaluation.
## Half over its left edge the pages' arrows and dots stand upright, see [ResultsPager], and the
## ways on stand on their own in a row at the foot of the screen under it.

## What the screen is headed. A podium is what is on it and what the last minute of a match is
## about; "Results" is the name of a state machine's last state. The run's page in a Grand Prix is
## headed with the name of what is being won.
const TITLE := "Payout slip"
const GRAND_PRIX_TITLE := "Grand Prix"
const WIDTH := 980.0
## The ink of the small print.
const FAINT := HouseTheme.INK_FAINT
## The small print by the barcode, as the first stage of the story prints it, STORY.md 6.2.
const SMALL_PRINT := "PAID IN CHIPS, NOT CASH  ·  NO REFUNDS ON A BAD LAP"
## The size the story's lines on the slip are printed at, STORY.md 6.2.
const STORY_PRINT := 11
## The least room kept between what is on the screen and its edges, and how much room either side
## of the bill is its own, for its bites and its shadow.
const EDGE := 12.0
const SIDE := 40.0
## How far the pager reaches onto the bill's paper, no further than the margin inside its edge so
## it covers none of what is printed, and how far the row of ways on stands off the foot of the
## screen and off the bill over it.
const PAGER_IN := 12.0
const FOOT_ABOVE := 22.0
const FOOT_GAP := 2.0
## How far the stick is pushed before it turns a page, and let back before it may turn another.
const STICK_PUSH := 0.6
const STICK_BACK := 0.3
## How long a watcher's podium is up before it goes on to how the run stands, in seconds.
const WATCHER_WAIT := 6.0
## How wide the buttons along the foot are at the least.
const WAY_WIDTH := 240.0
## How far a turn of the wheel off the bill moves it, GAME.md 3.8.
const SCROLL_STEP := 64

var match_node: Match
## The bill the pages are printed on, and the pages: the map's, always, and the run's in a Grand
## Prix once its points are in, or once its party is over after the last map.
var bill: PayoutBill
var map_page: SlipPage
var run_page: SlipPage
## The loyalty program's page, GAME.md 8.9, once the map has been written down with something in
## it for a profile at this machine, see [LoyaltyRecord].
var loyalty_page: LoyaltySlipPage

var _style: TicketStyle
## The barcode and the small print at the foot of the bill, numbered for the match it pays out.
var _end: VBoxContainer
var _barcode: Control
var _code := "JJ-0000-0"
## The small print beside the barcode and the House's bulletin under it, STORY.md 6.2, drawn once a
## slip so a page filled in again keeps what it said.
var _small_words: Label
var _bulletin: Label
var _bulletin_drawn := false
var _pager: ResultsPager
## Which of the pager's arrows are up, back and on, as last shown, see [method _update_pager].
var _arrows_shown := Vector2i(-1, -1)
## The row of ways on at the foot of the screen, standing on their own.
var _foot: HBoxContainer
var _next: Button
## The one way on from the last map's podium, on to the party in the room and the final standings;
## at the Final Hand, on to the House's evaluation.
var _continue: Button
var _rematch: Button
var _lobby: Button
var _quit: Button
## Tells a client what happens next and who decides it, since it is not them.
var _host_decides: Label
## Whether the last map's run has been put on the bill, after the party in the room.
var _run_added := false
## Whether the run's page has been in view at all, which a watcher's podium goes on to by itself
## the once: one they went back from is one they are looking at.
var _run_seen := false
## Seconds until a watcher's podium goes on to the run's by itself, see [method _process], and the
## ring beside the host's word that empties as they run out, so it is not a surprise.
var _watcher_left := WATCHER_WAIT
var _watcher_ring: CountdownRing
## The House's evaluation at the Final Hand, a page of its own at the end of the bill, and what
## takes the place of the ways on while it is in view, STORY.md 8.4.
var _house_page: Control
var _house_ways: Control
## Whether the stick has turned a page and not yet been let go back toward the middle.
var _stick_held := false


## The pages and the foot of the bill that never made it onto the bill go with the screen.
func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE:
		return
	for part: Node in [map_page, run_page, _end, _house_page, loyalty_page]:
		if part != null and is_instance_valid(part) and part.get_parent() == null:
			part.free()


## Builds the screen for [param for_match] and hangs it off [param parent], hidden until the
## whistle goes.
static func create(parent: Node, for_match: Match) -> ResultsScreen:
	var screen := ResultsScreen.new()
	screen.name = "Results"
	screen.match_node = for_match
	parent.add_child(screen)
	screen._build()
	# A client hears how a Grand Prix stands a moment after it hears the whistle, so a slip
	# already up is filled in again with the points once they are here.
	Events.grand_prix_scored.connect(screen._on_grand_prix_scored)
	# And the host's say can come to a client of a dedicated server while it is up, GAME.md 9.3a.
	if Net.session != null:
		Net.session.host_controls.granted_changed.connect(screen._on_say_changed)
	return screen


## Fills the screen in and shows it. Called at the whistle, and again on a client every time the
## host says the match is over, so it is built to be filled in more than once.
func fill_in() -> void:
	_watcher_left = WATCHER_WAIT
	var rules := match_node.rules
	var run := _run()
	var grand_prix := rules.rounds > 0
	var more := grand_prix and rules.round < rules.rounds
	var standings := match_node.standings()
	var stage := Story.stage_here()
	var named := ""
	if grand_prix:
		named = ArenaMaps.NAMES[ArenaMaps.index_of(rules.map)]
		named = "%s · map %d of %d" % [named, rules.round, rules.rounds]
	map_page.head(
		StorySlip.heading(stage), named, _keeping_words(rules.keep_jokers) if more else ""
	)
	map_page.short = short_screen()
	map_page.fill_map(standings)
	var pages: Array[Control] = [map_page]
	# How a Grand Prix stands, GAME.md 9.7, is a page of its own: everybody ranked on the points of
	# the run so far rather than on what they banked on the map just played.
	var wears := standings
	if run != null and (more or _run_added):
		if run_page == null:
			run_page = SlipPage.create(match_node)
			run_page.name = "RunPage"
		var ranked := run.standings(match_node.slots)
		var after := "Standings after map %d of %d" % [rules.round, rules.rounds]
		if not more:
			after = "Final standings after %d maps" % rules.rounds
			wears = ranked
		run_page.head(GRAND_PRIX_TITLE, after, "")
		run_page.short = short_screen()
		run_page.fill_run(ranked, run)
		pages.append(run_page)
	_add_loyalty_page(pages)
	if _house_page != null:
		pages.append(_house_page)
	if not wears.is_empty():
		MenuTheme.wear(_style, wears[0].color())
	_story_print(stage)
	var winner_score := standings[0].banked if not standings.is_empty() else 0
	_code = "JJ-%04d-%d" % [absi(hash(rules.map)) % 10000, winner_score]
	_barcode.queue_redraw()
	visible = true
	bill.set_pages(pages, _end)
	_ways_on()
	_fit()
	_point(true)


## The loyalty program's page after the map's and the run's, GAME.md 8.9, from what the map's
## settling reported, which comes a moment after the whistle; and Kit's scrap taped on, over the
## program's page or, with none, the map's.
func _add_loyalty_page(pages: Array[Control]) -> void:
	var record := match_node.get_node_or_null("LoyaltyRecord") as LoyaltyRecord
	if record == null:
		return
	if not record.reported.is_connected(_on_loyalty_reported):
		record.reported.connect(_on_loyalty_reported)
	var report := record.report
	if report.is_empty():
		return
	if loyalty_page == null:
		loyalty_page = LoyaltySlipPage.create()
	var printed := loyalty_page.fill(report)
	if printed:
		pages.append(loyalty_page)
	var kit := LoyaltySlipPage.kit_lines(report)
	LoyaltySlipPage.tape_onto(map_page, PackedStringArray() if printed else kit)
	LoyaltySlipPage.tape_onto(loyalty_page, kit if printed else PackedStringArray(), true)


func _on_loyalty_reported(_report: Array[Dictionary]) -> void:
	if visible:
		fill_in()


## This is the one screen nobody asked for: it arrives on its own at the whistle, so it points at
## what most people want next rather than waiting to be found. While there is a page under the one
## in view, that is the next page, the arrow down; on the last, the way on that carries things on:
## the next map in a run, the party after its last, and after a quick match another go, in the
## lobby for a room of people online, who go back to it together, and a rematch on one machine.
## Moved only from where it put the cursor itself, or from the bill, unless [param anyway].
func _point(anyway := false) -> void:
	var held := get_viewport().gui_get_focus_owner()
	var ours := held == null or held == _pager.on or held == _pager.back or held == _primary()
	if not (anyway or ours or bill.is_ancestor_of(held)):
		return
	if bill.aim() < bill.page_count() - 1 and _can_press(_pager.on):
		_pager.on.grab_focus()
		return
	var first := _primary()
	if first != null:
		first.grab_focus()


## The way on the cursor goes to on the last page, see [method _point], or null for none.
func _primary() -> Button:
	var order: Array[Button] = [_next, _continue]
	order.append_array([_lobby, _rematch] if Net.online() else [_rematch, _lobby])
	order.append(_quit)
	for first: Button in order:
		if _can_press(first):
			return first
	return null


## Brings page [param index] of the bill into view, see [method PayoutBill.turn_to].
func turn_to(index: int) -> void:
	bill.turn_to(index)


## Moves the bill [param step] down by hand. Whether there was anywhere to move.
func scroll_by(step: int) -> bool:
	return bill.scroll_by(step)


## Whether [param button] is up on this screen to be pressed: shown, in a part of the foot that is
## shown, and not dimmed. Asked of the screen rather than the tree, which may be hidden yet.
func _can_press(button: Button) -> bool:
	var node: Node = button
	while node != self and node is CanvasItem:
		if not (node as CanvasItem).visible:
			return false
		node = node.get_parent()
	return not button.disabled


## Which ways on the screen offers. Asked at the whistle rather than when the screen was built,
## which was the start of the match: who is hosting is a question about who is still here at the
## end of it.
##
## In a Grand Prix, GAME.md 9.7, the next map is the way on from a map that is not the last, and
## there is nowhere else -- there is no rematch of a map in the middle of a run, and no leaving
## from it (the pause menu is still the way out). From the last map's podium Continue goes on to
## the party in the room and then the run's final standings, which lead back to the lobby. A client
## decides none of it, and is told who does. At the Final Hand, STORY.md 8.4, the ways on are gone:
## the arrow down goes on to the House's evaluation, and its stamp is the way on from there.
func _ways_on() -> void:
	var rules := match_node.rules
	var decides := not match_node.puppet or _deciding_here()
	var grand_prix := rules.rounds > 0
	var more := grand_prix and rules.round < rules.rounds
	var last := grand_prix and not more
	var run_up := last and _run_added
	var house := _house_page != null
	_next.visible = decides and more
	# A run whose points have not arrived has no standings to go on to yet.
	_continue.visible = last and not _run_added and _run() != null
	_rematch.visible = decides and not grand_prix and not house
	_lobby.visible = decides and (run_up or not grand_prix) and not house
	_quit.visible = (not grand_prix or run_up) and not house
	_host_decides.visible = not decides and Net.online() and (not last or run_up)
	_host_decides.text = (
		"The host starts the next map." if more else "The host takes everybody back to the lobby."
	)
	if _house_ways != null:
		_house_ways.visible = _at_house()
	_pager.show_page(bill.page, bill.page_count())
	_arrows_shown = Vector2i(-1, -1)
	_update_pager()
	# Worked out before it is set: a foot hidden for a moment takes the cursor off its buttons.
	var anything := false
	for part: Control in _foot.get_children():
		anything = anything or part.visible
	_foot.visible = anything


## The pager up while there is somewhere for it to go, and each arrow where there is: a page that
## way, or on a touch screen, see [method _stepping], the rest of a bill that does not fit too, a
## long page of a phone's slip included, so its sections are there to step through.
func _update_pager() -> void:
	var room := bill.scroll_room() if _stepping() else 0
	var shown := bill.page_count() > 1 or room > 0
	if _pager.visible != shown:
		_pager.visible = shown
	var back_there := bill.aim() > 0
	var on_there := bill.aim() < bill.page_count() - 1
	if _stepping():
		back_there = back_there or bill.scrolled() > 0
		on_there = on_there or bill.scrolled() < room
	var wanted := Vector2i(int(back_there), int(on_there))
	if wanted != _arrows_shown:
		_arrows_shown = wanted
		_pager.show_arrows(back_there, on_there)


## Whether the arrows step the bill as the keys do, the rest of a page taller than the screen first
## and then the next page, rather than turn its pages: on a touch screen, where a finger scrolls the
## bill and the arrows go through it a screen at a time, see [method PayoutBill.step].
static func _stepping() -> bool:
	return TouchInput.enabled


## The arrow [param way] pressed: a page that way, or on a touch screen a step, see
## [method _stepping].
func _arrow(way: int) -> void:
	if _stepping():
		bill.step(way)
	else:
		bill.turn_by(way)


## Whether the House's evaluation is the page in view, at the Final Hand.
func _at_house() -> bool:
	return _house_page != null and bill.page == bill.page_count() - 1


## Another page in view: the pager's dots follow it, the cursor goes with it, see [method _point],
## and at the Final Hand the ways under the slip are the evaluation's while it is in view.
func _on_turned(page: int) -> void:
	if page > 0:
		_run_seen = true
	if not visible:
		return
	_ways_on()
	_point()


## Whether the screen is short, a phone's under a big UI scale, 8.5: its slip's lines are compact
## and its podium smaller, see [member SlipPage.short], so more than a couple of lines fit.
func short_screen() -> bool:
	return MenuTheme.is_short(self)


## The bill fitted to the screen: a narrow one has the bill and the pager beside it shrunk about
## the middle to the width there is, and the screen made as much taller as it is shrunk, so the
## bill still runs from the top of the screen to the ways on.
func _fit() -> void:
	var view := get_viewport_rect().size
	var need := WIDTH + (_pager.get_combined_minimum_size().x - PAGER_IN + EDGE) * 2.0
	var shrink := clampf(view.x / need, 0.1, 1.0)
	scale = Vector2.ONE * shrink
	position = Vector2.ZERO
	size = view / shrink
	_lay_out()


## The bill down the middle from the top of the screen to the ways on, the pager half over its left
## edge halfway down, clear of the standings down the right of the screen, and the ways on along
## the foot.
func _lay_out() -> void:
	var foot := _foot.get_combined_minimum_size()
	_foot.size = foot
	_foot.position = Vector2((size.x - foot.x) * 0.5, size.y - FOOT_ABOVE - foot.y)
	var floor_at := _foot.position.y - FOOT_GAP if _foot.visible else size.y
	var wide := WIDTH + SIDE * 2.0
	bill.position = Vector2((size.x - wide) * 0.5, 0.0)
	bill.size = Vector2(wide, floor_at)
	var pager := _pager.get_combined_minimum_size()
	_pager.size = pager
	_pager.position = Vector2(
		bill.position.x + SIDE + PAGER_IN - pager.x, (floor_at - pager.y) * 0.5
	)


## Up and down turn the pages, GAME.md 3.8, on the keys, a pad's cross or its stick, rather than
## move the cursor, which stays where it is pointed, see [method _point]: heard before the cursor
## would be, unless something over the slip has the cursor. The stick turns a page a push.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var held := get_viewport().gui_get_focus_owner()
	if held != null and not is_ancestor_of(held):
		return
	# Kit's folder open over the slip has the keys, though not the cursor, STORY.md 7.2.
	var folder := get_parent().get_node_or_null("SlipFolder") as SlipFolder
	if folder != null and folder.notes != null:
		return
	if _pin_by(event, held):
		get_viewport().set_input_as_handled()
		return
	var way := _up_or_down(event)
	if way == 0:
		return
	get_viewport().set_input_as_handled()
	if way != 2:
		bill.step(way)


## The pins at the ends of the nearest bets on the program's page, GAME.md 8.9, for a pad's cursor:
## reached right from the page's arrows or up from the ways on under the bill while one is in view;
## up and down from one go to the pin over or under it, up past the top one turning the page as
## up does and down past the last going back to the ways on, and left back to the arrows. Whether
## [param event], with [param held] having the cursor, was one of these.
func _pin_by(event: InputEvent, held: Control) -> bool:
	if loyalty_page == null or not loyalty_page.is_visible_in_tree():
		return false
	var pins := loyalty_page.pins()
	var at := pins.find(held)
	if at >= 0:
		return _between_pins(event, pins, at)
	var seen := pins.filter(
		func(pin: Button) -> bool: return bill.get_global_rect().intersects(pin.get_global_rect())
	)
	if seen.is_empty():
		return false
	var from_arrows := held == _pager.on or held == _pager.back
	var from_foot := held in [_next, _continue, _rematch, _lobby, _quit]
	if from_arrows and event.is_action_pressed(&"ui_right"):
		_to_pin(seen[0])
	elif from_foot and event.is_action_pressed(&"ui_up"):
		_to_pin(seen[seen.size() - 1])
	else:
		return false
	return true


## [param event] with the cursor on [param pins]' [param at]: to the pin over or under it, on up
## past the top one, back to the ways on past the last, or left back to the arrows. Whether it was
## one of these.
func _between_pins(event: InputEvent, pins: Array[Button], at: int) -> bool:
	if event.is_action_pressed(&"ui_left"):
		_point(true)
		return true
	var way := _up_or_down(event)
	if way != -1 and way != 1:
		return way == 2
	if at + way >= 0 and at + way < pins.size():
		_to_pin(pins[at + way])
	else:
		_point(true)
		if way < 0:
			bill.step(way)
	return true


## The cursor on [param pin], the bill scrolled to show it.
func _to_pin(pin: Button) -> void:
	pin.grab_focus()
	var shown := bill.get_global_rect()
	var wanted := pin.get_global_rect().grow(PayoutBill.ROOM)
	if wanted.end.y > shown.end.y:
		bill.scroll_by(ceili(wanted.end.y - shown.end.y))
	elif wanted.position.y < shown.position.y:
		bill.scroll_by(-ceili(shown.position.y - wanted.position.y))


## -1 up and 1 down for [param event], 2 for a stick still held over that turns nothing, and 0 for
## anything else.
func _up_or_down(event: InputEvent) -> int:
	var stick := event as InputEventJoypadMotion
	if stick != null:
		return _pushed(stick) if stick.axis == JOY_AXIS_LEFT_Y else 0
	if event.is_action_pressed(&"ui_up", true):
		return -1
	if event.is_action_pressed(&"ui_down", true):
		return 1
	return 0


## A page a push of the stick up or down: it turns once, and again only once it has been let go
## back toward the middle, however long it is held over.
func _pushed(stick: InputEventJoypadMotion) -> int:
	var pushed := absf(stick.axis_value)
	if pushed < STICK_BACK:
		_stick_held = false
	if pushed < STICK_PUSH:
		return 0
	if _stick_held:
		return 2
	_stick_held = true
	return 1 if stick.axis_value > 0.0 else -1


## The shoulders on a pad and Page Up and Page Down turn the pages too, GAME.md 9.7, and a wheel
## turned off the bill moves it by hand, as it does on the bill.
func _unhandled_input(event: InputEvent) -> void:
	if visible and (_pager.turn(event) or _wheeled(event)):
		get_viewport().set_input_as_handled()


func _wheeled(event: InputEvent) -> bool:
	var step := 0
	var wheel := event as InputEventMouseButton
	if wheel != null and wheel.pressed:
		if wheel.button_index == MOUSE_BUTTON_WHEEL_UP:
			step = -SCROLL_STEP
		elif wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			step = SCROLL_STEP
	return step != 0 and bill.scroll_by(step)


## Somebody watching has nothing to press and nobody to press it for them, GAME.md 10.3: a map's
## podium goes on to how the run stands by itself, once it has been up long enough to be read.
func _process(delta: float) -> void:
	if not visible:
		return
	_lay_out()
	_update_pager()
	var going_on := bill.page_count() > 1 or _continue.visible
	var counting := going_on and bill.page == 0 and not _run_seen and _watching()
	_watcher_ring.visible = counting
	if not counting:
		return
	_watcher_left -= delta
	_watcher_ring.value = _watcher_left / WATCHER_WAIT
	if _watcher_left <= 0.0:
		_watcher_left = WATCHER_WAIT
		_run_seen = true
		_on_standings()


static func _watching() -> bool:
	return Net.online() and Net.session != null and Net.session.watching


## Whether the host's say is at this client, as it is at a dedicated server's, GAME.md 9.3a.
static func _deciding_here() -> bool:
	return Net.session != null and not Net.session.is_host and Net.session.host_controls.mine()


func _on_say_changed(_mine: bool) -> void:
	if visible:
		fill_in()


## What happens to everybody's jokers on the way to the next map, said the once under the caption.
func _keeping_words(keep: int) -> String:
	match keep:
		GrandPrix.Keep.NONE:
			return "Nobody takes their jokers on to the next map."
		GrandPrix.Keep.CHOOSE:
			return "As the next map starts, everybody picks which of their jokers to keep."
		GrandPrix.Keep.ALL:
			return "Everybody takes all their jokers on to the next map."
	return "Everybody keeps one of their jokers for the next map, at random."


## On to how the run stands, GAME.md 9.7: the page under the map's, in the middle of a run. The
## last map's podium hands over to the party in the room first, and the run's standings are put on
## the bill once the camera is there.
func _on_standings() -> void:
	var rules := match_node.rules
	var run := _run()
	if rules.round < rules.rounds:
		bill.turn_to(1)
		return
	if run == null or match_node.arena == null:
		_show_run()
		return
	visible = false
	GrandPrixFinale.stage(match_node, run.standings(match_node.slots), _show_run)


## After the last map's party the run's final standings, under its podium. From here on the arena's
## board names the champion, not before: until the run's page is up, what is being looked at is the
## last map.
func _show_run() -> void:
	_run_added = true
	_run_seen = true
	var rules := match_node.rules
	if Game.grand_prix != null and rules.round >= rules.rounds:
		Game.grand_prix.revealed = true
	fill_in()
	bill.turn_to(1)


## The Grand Prix this map belongs to, with this map's result in, or null: a single map, or a
## client that has not been told the points yet.
func _run() -> GrandPrix:
	var rules := match_node.rules
	var run := Game.grand_prix
	if rules.rounds <= 0 or run == null or run.scored_round < rules.round - 1:
		return null
	return run


func _on_grand_prix_scored(_run_now: Dictionary) -> void:
	if visible:
		fill_in()


## The Final Hand's slip, STORY.md 8.4: [param section] a page of its own at the end of the bill,
## and [param ways] in place of the ways on while it is in view.
func take_the_house(section: Control, ways: Control) -> void:
	_house_page = section
	_house_ways = ways
	ways.visible = false
	_foot.add_child(ways)
	if visible:
		fill_in()


func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_style = MenuTheme.slip_style()
	bill = PayoutBill.create(_style, WIDTH)
	bill.turned.connect(_on_turned)
	add_child(bill)
	map_page = SlipPage.create(match_node)
	map_page.name = "MapPage"
	_end = _small_print()
	_pager = ResultsPager.create()
	_pager.visible = false
	_pager.back.pressed.connect(_arrow.bind(-1))
	_pager.on.pressed.connect(_arrow.bind(1))
	add_child(_pager)
	add_child(_build_the_foot())
	get_viewport().size_changed.connect(_fit)


## The foot of the bill: the match's number as a barcode on the left and the small print on the
## right, GAME.md 8.1a, and the House's bulletin on a line of its own under it, STORY.md 6.2.
func _small_print() -> VBoxContainer:
	var foot := VBoxContainer.new()
	foot.name = "End"
	foot.add_theme_constant_override("separation", 2)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 16)
	_barcode = Control.new()
	_barcode.custom_minimum_size = Vector2(Barcode.width_of("JJ-0000-00000") + 8.0, 46.0)
	_barcode.draw.connect(
		func() -> void:
			Barcode.draw(
				_barcode,
				Rect2(Vector2(0.0, 4.0), _barcode.size - Vector2(0.0, 4.0)),
				_code,
				HouseTheme.INK
			)
	)
	line.add_child(_barcode)
	_small_words = Label.new()
	_small_words.name = "SmallPrint"
	_small_words.text = SMALL_PRINT
	Type.strong(_small_words, STORY_PRINT, FAINT)
	_small_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_small_words.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_small_words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(_small_words)
	foot.add_child(line)
	_bulletin = Label.new()
	_bulletin.name = "Bulletin"
	Type.strong(_bulletin, STORY_PRINT, FAINT)
	_bulletin.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_bulletin.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bulletin.visible = false
	foot.add_child(_bulletin)
	return foot


## The story's small print and bulletin for [param stage], STORY.md 6.2, the bulletin drawn once.
func _story_print(stage: int) -> void:
	var profile := Game.settings.profile
	_small_words.text = StorySlip.small_print(stage, profile)
	if not _bulletin_drawn:
		_bulletin_drawn = true
		var draw := RandomNumberGenerator.new()
		draw.randomize()
		_bulletin.text = StorySlip.bulletin(stage, profile, match_node.slots, draw)
	_bulletin.visible = not _bulletin.text.is_empty()


## The row of ways on along the foot of the screen, standing on their own: who decides, with a
## watcher's countdown beside it, then the ways on, all built and shown as they apply, see
## [method _ways_on].
func _build_the_foot() -> HBoxContainer:
	_foot = HBoxContainer.new()
	_foot.name = "Foot"
	_foot.alignment = BoxContainer.ALIGNMENT_CENTER
	_foot.add_theme_constant_override("separation", 20)
	_host_decides = MenuTheme.subtitle("The host takes everybody back to the lobby.", Type.LABEL)
	_host_decides.add_theme_color_override("font_color", HouseTheme.WORDS)
	# On whatever is behind the screen, with nothing under it: the room's own dark round it.
	_host_decides.add_theme_color_override("font_outline_color", HouseTheme.STOCK)
	_host_decides.add_theme_constant_override("outline_size", 8)
	_host_decides.visible = false
	_foot.add_child(_host_decides)
	_watcher_ring = CountdownRing.create()
	_watcher_ring.visible = false
	_foot.add_child(_watcher_ring)
	_buttons()
	return _foot


## The ways on from here, see [method _ways_on]. The host of an online match can take everybody
## back to the waiting room of GAME.md 9.6, where the next one is chosen and whoever wants to leave
## can. The ones that carry the match on are in foil, the rest only ways out.
func _buttons() -> void:
	_next = MenuTheme.button("Next map", 26)
	_next.pressed.connect(func() -> void: Game.next_map(match_node))
	_continue = MenuTheme.button("Continue", 26)
	_continue.pressed.connect(_on_standings)
	_rematch = MenuTheme.button("Rematch", 26)
	_rematch.pressed.connect(func() -> void: Game.rematch(match_node))
	_lobby = MenuTheme.button("Back to lobby", 26)
	_lobby.pressed.connect(_back_to_lobby)
	_quit = MenuTheme.button("Back to title", 26)
	_quit.pressed.connect(func() -> void: Game.go_to_title())
	for way: Button in [_next, _continue, _rematch, _lobby, _quit]:
		way.custom_minimum_size.x = WAY_WIDTH
		way.visible = false
		_foot.add_child(way)
	for onward: Button in [_next, _continue, _rematch]:
		onward.theme_type_variation = HouseTheme.PRIMARY


## Online, back to the waiting room with everybody; on one machine, back to the lobby a Grand
## Prix was set up in, since that is where the next one is.
func _back_to_lobby() -> void:
	if Net.online():
		Game.back_to_the_room()
	else:
		Game.go_to_lobby(match_node)
