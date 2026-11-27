class_name TimelineRecord
extends Node
## Hears the moments of a map worth marking on the timeline of Steam's game recording, GAME.md
## 10.8, and marks them as they happen, see [Timeline]: the kills, the cash-outs, the Royal Flushes,
## the sevens and the wins of the seats at this machine, named when the screen is shared, and the
## stretches of the match's own clock for everybody watching it. Every machine hears its own seats
## out of what it hears anyway, a client from its host, as [AchievementRecord] does. Each map is
## tagged on the game phase of its Grand Prix, a map played alone being a phase of its own, and
## the phase is told how it went. Only made with Steam on. Steam shows the words on this machine,
## so they are said in the language spoken here.

## A pull of three of each face of [enum SlotPad.Face], with what it won, each shown through tr().
const SLOT_FACES: Array[String] = [
	"Three sevens · won %d",
	"Three cherries · won %d",
	"Three bells · won %d",
	"Three bars · won %d",
	"Three lemons · won %d",
	"Three chips · won %d",
]
## How long after a cash-out's start a kart may still not show it, a client's picture of the kart
## arriving after the host's word, before it counts as driven off the Junction, in seconds.
const SHOWING := 0.5

## For a test: the moments are heard with no Steam, Steam being the test's own.
static var anywhere := false

var match_node: Match
## Whether each map is tagged on the game phase of its Grand Prix: not at the driving test, which
## is no map of one.
var phases := true
## The room's own clock, which stops while the room is paused: when each cash-out going on began.
var _clock := 0.0
var _cashing_since: Dictionary[int, float] = {}
## By slot, every kart's: whether it is cashing out at match point as last seen, for Payment
## Interrupted, its pot gone by the time its death is heard.
var _closing: Dictionary[int, bool] = {}
## By slot: who it took out last, for an overtake's words; the faces of its last pull; and its
## bounty's stretch, open while the price is on its head.
var _took_out: Dictionary[int, int] = {}
var _faces: Dictionary[int, PackedByteArray] = {}
var _bounties: Dictionary[int, int] = {}
## Who has been emptying the Jackpot's pile, and how much of it, since anybody else last did.
var _jar_slot := -1
var _jar_chips := 0
## The match's own stretches: Last Call, overtime and the Final Hand, while they are open.
var _last_call := 0
var _overtime := 0
var _final_hand := 0
## The state the match was in before the one it is in, for a whistle that ends sudden death.
var _state := -1
## The karts whose hands are heard, see [method _hear_hands].
var _hands: Dictionary[int, Kart] = {}
var _match_points := MatchPoint.new()
var _flagged := false


## A record of the moments of [param in_match], with Steam on, tagging its map on a game phase when
## [param tags_phases]; null with no Steam.
static func add_to(in_match: Match, tags_phases := true) -> TimelineRecord:
	if not Store.on() and not anywhere:
		return null
	var record := TimelineRecord.new()
	record.name = "TimelineRecord"
	record.match_node = in_match
	record.phases = tags_phases
	in_match.add_child(record)
	return record


func _ready() -> void:
	var heard: Array[Array] = [
		[Events.kart_killed, _on_kart_killed],
		[Events.announced, _on_announced],
		[Events.bank_started, _on_bank_started],
		[Events.bank_completed, _on_bank_completed],
		[Events.jackpot_collected, _on_jackpot_collected],
		[Events.jackpot_emptied, _on_jackpot_emptied],
		[Events.flush_completed, _on_flush_completed],
		[Events.bounty_called, _on_bounty_called],
		[Events.bounty_claimed, _on_bounty_claimed],
		[Events.bounty_lapsed, _on_bounty_lapsed],
		[Events.slot_spun, _on_slot_spun],
		[Events.slot_paid, _on_slot_paid],
		[Events.match_state_changed, _on_state],
		[Events.grand_prix_scored, _on_grand_prix_scored],
	]
	for each: Array in heard:
		(each[0] as Signal).connect(each[1])
	var loyalty := match_node.get_node_or_null("LoyaltyRecord") as LoyaltyRecord
	if loyalty != null:
		loyalty.bet_won.connect(_on_bet_won)


func _exit_tree() -> void:
	for handle: int in [_last_call, _overtime, _final_hand] + _bounties.values():
		Timeline.close(handle)


func _physics_process(delta: float) -> void:
	if match_node == null or match_node.rules == null:
		return
	_clock += delta
	if not _flagged and match_node.is_running():
		_flagged = true
		_begin()
	_watch_the_cash_outs()
	_hear_hands()
	for at: int in _match_points.step(match_node, delta):
		var slot := match_node.slots[at]
		if _here(slot):
			var banked := Lang.number(Teams.score_of(match_node.slots, slot))
			var pot := Lang.number(Scoring.pot_value(slot.kart.pot.coins, slot.kart.pot.mult))
			var line := tr("{banked} banked, {pot} in the pot").format(
				{"banked": banked, "pot": pot}
			)
			Timeline.mark(&"match_point", _titled(slot, tr("Match Point")), line)


## The flag dropping: the map tagged on its phase, a showdown said, and the Final Hand's stretch
## begun.
func _begin() -> void:
	var rules := match_node.rules
	if phases:
		Timeline.begin_phase(phase_key(), modes_of(match_node))
		Timeline.phase_map(map_name(rules.map))
	if rules.showdown():
		var fighters: Array[String] = []
		for slot: PlayerSlot in match_node.slots:
			fighters.append(slot.display_name())
		var between := tr("Tie-breaker: %s") % tr(", ", &"list").join(fighters)
		Timeline.mark(&"showdown", tr("Showdown"), between)
	if Story.final_hand_on:
		_final_hand = Timeline.open(&"final_hand", tr("Final Hand"), tr("The House deals"))


## What the game phase of this map is a phase of: its Grand Prix, or the map alone.
func phase_key() -> String:
	var run := Game.grand_prix
	var of: Object = run if run != null else match_node
	return "jj%d" % of.get_instance_id()  # NO_TRANSLATE


## The driving test's lessons, GAME.md 9.4a: each passed as the next begins and the exam as the test
## ends. A lesson skipped from the pause menu, or settled by going straight to the exam, is no pass.
func watch_lessons(run: TutorialRun) -> void:
	run.lesson_started.connect(_on_lesson_started.bind(run))
	run.finished.connect(_on_test_passed.bind(run))


func _on_lesson_started(index: int, run: TutorialRun) -> void:
	if index <= 0 or TutorialRun.express:
		return
	var lesson := run.lessons[index - 1]
	if not lesson.skipped:
		Timeline.mark(&"lesson", tr("Passed: %s") % lesson.title, tr("Driving school"))


func _on_test_passed(run: TutorialRun) -> void:
	var exam: TutorialLesson = run.lessons[-1]
	var passed := tr("Passed the %s") % exam.title.to_lower()
	Timeline.mark(&"lesson", passed, tr("Driving school"))


## The kinds of play a phase of [param in_match] is, for its tags, GAME.md 10.8.
static func modes_of(in_match: Match) -> Array[String]:
	var rules := in_match.rules
	var modes: Array[String] = []
	if Story.final_hand_on:
		modes.append(Lang.t("Final Hand"))
	elif Game.grand_prix != null and rules.rounds > 0:
		modes.append(Lang.t("Grand Prix"))
	elif rules.showdown():
		modes.append(Lang.t("Showdown"))
	else:
		modes.append(Lang.t("Single map"))
	if rules.teams > 0:
		modes.append(Lang.t("Teams"))
	if Net.online():
		modes.append(Lang.t("Online"))
	var here := 0
	for slot: PlayerSlot in in_match.slots:
		if slot.is_local_human() or in_match.is_local_seat(slot.index):
			here += 1
	if here == 0:
		modes.append(Lang.t("Watching"))
	elif here > 1:
		modes.append(Lang.t("Shared screen"))
	return modes


## The name [param map] is shown by, in the language spoken.
static func map_name(map: StringName) -> String:
	var at := ArenaMaps.index_of(map)
	return Lang.t(ArenaMaps.NAMES[at]) if at >= 0 and at < ArenaMaps.NAMES.size() else String(map)


## Whether [param slot] is a seat at this machine.
func _here(slot: PlayerSlot) -> bool:
	return slot != null and (slot.is_local_human() or match_node.is_local_seat(slot.index))


func _slot(index: int) -> PlayerSlot:
	return match_node.slots[index] if index >= 0 and index < match_node.slots.size() else null


## [param words] said of [param slot]: with its name before them when more than one seat here is
## playing, so a shared screen's timeline says whose it was.
func _titled(slot: PlayerSlot, words: String) -> String:
	var here := 0
	for each: PlayerSlot in match_node.slots:
		if _here(each):
			here += 1
	if here <= 1:
		return words
	return tr("{name}: {words}").format({"name": slot.display_name(), "words": words})


func _name_of(index: int) -> String:
	var slot := _slot(index)
	return slot.display_name() if slot != null else tr("somebody")


## Who is cashing out at match point, see [member _closing], on a map with a target to reach.
func _watch_the_cash_outs() -> void:
	var target := match_node.rules.target_score
	var aimed := target > 0 and target < AchievementRecord.NO_TARGET
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		var showing := is_instance_valid(kart) and kart.alive and kart.channel_progress >= 0.0
		var since: float = _cashing_since.get(slot.index, INF)
		if not showing and _clock - since > SHOWING:
			_cashing_since.erase(slot.index)
		var on_junction := showing and _cashing_since.has(slot.index)
		_closing[slot.index] = aimed and on_junction and match_node.would_win(slot)


## Every seat here has its hand heard, a seat taken late as well, for the poker hands it makes.
func _hear_hands() -> void:
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if not _here(slot) or not is_instance_valid(kart) or _hands.get(slot.index) == kart:
			continue
		_hands[slot.index] = kart
		kart.jokers.hands_changed.connect(_on_hands_changed.bind(slot.index))


func _on_hands_changed(gained: Array[int], _lost: Array[int], at: int) -> void:
	var slot := _slot(at)
	if gained.is_empty() or not _here(slot) or not match_node.is_running():
		return
	# One hand made at once is several in the pay table, a Flush its Four of a Kind: the best says it.
	var best: int = gained.min()
	Timeline.mark(&"hand", _titled(slot, JokerHands.NAMES[best]), JokerHands.IS[best])


func _on_kart_killed(victim: int, killer: int, cause: StringName) -> void:
	var closing: bool = _closing.get(victim, false)
	_closing[victim] = false
	_cashing_since.erase(victim)
	var by := _slot(killer)
	var credited := by != null and killer != victim
	if credited:
		_took_out[killer] = victim
	if credited and _here(by):
		if closing:
			var line := tr("%s was cashing out at Match Point") % _name_of(victim)
			Timeline.mark(&"payment_interrupted", _titled(by, tr("Payment Interrupted")), line)
		else:
			Timeline.mark(&"kill", _titled(by, tr("Took out %s") % _name_of(victim)))
	var lost := _slot(victim)
	if not _here(lost):
		return
	var words := tr("Taken out by %s") % _name_of(killer)
	if not credited:
		words = tr("Fell into a pit") if cause == &"pit" else tr("Out")
	Timeline.mark(&"death", _titled(lost, words))


## The announcer's calls, GAME.md 3.12, of a seat here: a run of kills, a streak, a trade and an
## overtake. A call is told apart by its English, and said in the language spoken, in small letters
## after the first as a title is.
func _on_announced(at: int, call: String) -> void:
	var slot := _slot(at)
	if not _here(slot):
		return
	var said := tr(call)
	var words := said.substr(0, 1) + said.substr(1).to_lower()
	if call in Announcer.COMBOS:
		Timeline.mark(&"run_of_kills", _titled(slot, words))
	elif call in Announcer.STREAKS.values():
		var kills: int = Announcer.STREAKS.find_key(call)
		var streak := tr_n("%d kill without dying", "%d kills without dying", kills) % kills
		Timeline.mark(&"streak", _titled(slot, words), streak)
	elif call == Announcer.TRADE_CALL:
		var line := tr("Trade kill: %s") % _name_of(_took_out.get(at, -1))
		Timeline.mark(&"trade_kill", _titled(slot, line))
	elif call == Announcer.LEAD_CALL or call == Announcer.OVERTAKE_CALL:
		var whom := _name_of(_took_out.get(at, -1))
		var line := (
			tr("Took the lead from %s") if call == Announcer.LEAD_CALL else tr("Overtook %s")
		)
		Timeline.mark(&"took_the_lead", _titled(slot, line % whom), tr("In sudden death"))


func _on_bank_started(at: int) -> void:
	_cashing_since[at] = _clock


## A cash-out banked to its last chip: the one that wins the map marked over its seconds on the
## Junction, any other as it ends.
func _on_bank_completed(at: int, coins: int, mult: float, total: int) -> void:
	var began: float = _cashing_since.get(at, _clock)
	_cashing_since.erase(at)
	var slot := _slot(at)
	if not _here(slot):
		return
	var line := tr_n("{coins} chip × {mult}", "{coins} chips × {mult}", coins).format(
		{"coins": coins, "mult": PowerUp.number(mult)}
	)
	var target := match_node.rules.target_score
	var aimed := target > 0 and target < AchievementRecord.NO_TARGET
	if aimed and Teams.score_of(match_node.slots, slot) >= match_node.rules.team_target():
		var title := tr("Cashed out %s for the win") % Lang.number(total)
		Timeline.span(&"winning_cash_out", _titled(slot, title), line, _clock - began)
	else:
		var title := tr("Banked %s") % Lang.number(total)
		Timeline.mark(&"cash_out", _titled(slot, title), line)


func _on_jackpot_collected(at: int, chips: int) -> void:
	if at != _jar_slot:
		_jar_slot = at
		_jar_chips = 0
	_jar_chips += chips


func _on_jackpot_emptied(_zone: int) -> void:
	var slot := _slot(_jar_slot)
	if _here(slot) and _jar_chips > 0:
		var jackpot := tr_n("Jackpot · %d chip", "Jackpot · %d chips", _jar_chips) % _jar_chips
		Timeline.mark(&"jackpot", _titled(slot, jackpot))
	_jar_slot = -1
	_jar_chips = 0


func _on_flush_completed(at: int) -> void:
	var slot := _slot(at)
	if _here(slot):
		var flush := tr("+3 mult and a full tank")
		Timeline.mark(&"royal_flush", _titled(slot, tr("Royal Flush")), flush)


func _on_bounty_called(at: int) -> void:
	var slot := _slot(at)
	if _here(slot) and not _bounties.has(at):
		_bounties[at] = Timeline.open(&"bounty_on_you", _titled(slot, tr("Bounty on your head")))


func _on_bounty_claimed(killer: int, victim: int, amount: int) -> void:
	Timeline.close(_bounties.get(victim, 0))
	_bounties.erase(victim)
	var by := _slot(killer)
	if _here(by):
		var title := tr("Collected the bounty on {name} · +{chips}").format(
			{"name": _name_of(victim), "chips": amount}
		)
		Timeline.mark(&"bounty_collected", _titled(by, title))


func _on_bounty_lapsed(at: int) -> void:
	Timeline.close(_bounties.get(at, 0))
	_bounties.erase(at)


func _on_slot_spun(at: int, _pad: int, _bet: int, faces: PackedByteArray) -> void:
	_faces[at] = faces


## A pull paid: three sevens, or any other three of a kind, GAME.md 3.15. A pair only gives the bet
## back, which is no moment.
func _on_slot_paid(at: int, _pad: int, won: int) -> void:
	var slot := _slot(at)
	var faces: PackedByteArray = _faces.get(at, PackedByteArray())
	_faces.erase(at)
	if not _here(slot) or faces.size() < 3 or faces[0] != faces[1] or faces[1] != faces[2]:
		return
	var three := tr(SLOT_FACES[faces[0]]) % won
	var id := &"three_sevens" if faces[0] == SlotPad.Face.SEVEN else &"slot_win"
	Timeline.mark(id, _titled(slot, three))


func _on_bet_won(at: int, landmark: LoyaltyLandmark) -> void:
	var slot := _slot(at)
	if _here(slot):
		Timeline.mark(&"bet_won", _titled(slot, tr("Bet won: %s") % tr(landmark.title)))


func _on_state(state: int) -> void:
	var was := _state
	_state = state
	match state:
		Match.State.LAST_CALL:
			if _last_call == 0:
				var double := tr("The Junction pays double")
				_last_call = Timeline.open(&"last_call", tr("Last Call"), double)
		Match.State.OVERTIME:
			Timeline.close(_last_call)
			_last_call = 0
			if _overtime == 0:
				_overtime = Timeline.open(&"overtime", tr("Overtime"), tr("Last one standing"))
		Match.State.RESULTS:
			_whistle(was == Match.State.OVERTIME)


## The whistle: every stretch ended, and how the map went for each seat here.
func _whistle(sudden_death: bool) -> void:
	for handle: int in [_last_call, _overtime, _final_hand] + _bounties.values():
		Timeline.close(handle)
	_last_call = 0
	_overtime = 0
	_final_hand = 0
	_bounties.clear()
	var ranked := match_node.standings()
	var sides := Teams.sides_of(ranked)
	var standing := MatchEnd.alive_slots(match_node)
	var map := map_name(match_node.rules.map)
	var best := -1
	for slot: PlayerSlot in match_node.slots:
		if not _here(slot):
			continue
		var place := _place_in(sides, slot)
		if best < 0 or place < best:
			best = place
		var score := Teams.score_of(match_node.slots, slot)
		var line := tr_n(
			"{points} point · {place} of {sides}", "{points} points · {place} of {sides}", score
		)
		line = line.format(
			{"points": Lang.number(score), "place": Timeline.ordinal(place), "sides": sides.size()}
		)
		if place == 1 and sudden_death and _in(standing, slot):
			Timeline.mark(&"last_one_standing", _titled(slot, tr("Last one standing")), line)
		if match_node.rules.showdown():
			if place == 1:
				Timeline.mark(&"won_map", _titled(slot, tr("Won the showdown")))
		elif place == 1:
			Timeline.mark(&"won_map", _titled(slot, tr("Won %s") % map), line)
		else:
			var title := tr("Finished {place} on {map}").format(
				{"place": Timeline.ordinal(place), "map": map}
			)
			Timeline.mark(&"placed", _titled(slot, title), line, Timeline.place_icon(place))
	# A map played alone is its own phase, and done with now; a Grand Prix's is told at its end.
	if phases and Game.grand_prix == null and best > 0:
		var scored := _best_here(ranked)
		var points := Teams.score_of(match_node.slots, scored)
		Timeline.phase_result(
			best, sides.size(), tr_n("%s point", "%s points", points) % Lang.number(points)
		)


## A Grand Prix scored, GAME.md 9.7: at its end, its winner marked if it is a seat here, and its
## phase told how it went.
func _on_grand_prix_scored(_run: Dictionary) -> void:
	var run := Game.grand_prix
	if run == null or not run.is_last() or run.needs_showdown():
		return
	var ranked := run.standings(match_node.slots)
	var sides := Teams.sides_of(ranked)
	var best := _best_here(ranked)
	if best == null:
		return
	var place := _place_in(sides, best)
	var maps := run.playlist.size()
	var total := run.total(best.index)
	var points := tr_n("%d point", "%d points", total) % total
	if place == 1:
		var line := tr_n("{points} over {maps} map", "{points} over {maps} maps", maps).format(
			{"points": points, "maps": maps}
		)
		Timeline.mark(&"won_grand_prix", _titled(best, tr("Won the Grand Prix")), line)
	Timeline.phase_result(place, sides.size(), points)


## The seat here placed best in [param ranked], or null for none.
func _best_here(ranked: Array[PlayerSlot]) -> PlayerSlot:
	for slot: PlayerSlot in ranked:
		if _here(slot):
			return slot
	return null


## [param slot]'s place, from 1, among [param sides], best first: its own, or its team's.
static func _place_in(sides: Array, slot: PlayerSlot) -> int:
	for at: int in sides.size():
		if slot in (sides[at] as Array):
			return at + 1
	return sides.size()


## Whether [param slot] or a teammate of its is among [param standing].
static func _in(standing: Array[PlayerSlot], slot: PlayerSlot) -> bool:
	for other: PlayerSlot in standing:
		if other == slot or Teams.teammates(other, slot):
			return true
	return false
