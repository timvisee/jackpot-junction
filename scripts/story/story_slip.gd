class_name StorySlip
extends RefCounted
## What the story prints on the payout slip, STORY.md 6.2: its small print, the House's bulletin
## under it, the line under each of this machine's players saying how the House classified them,
## and the slip's heading. The places, scores, awards and stamps on it never change.

## The traits a match is classified into, in capitals as the House prints them, and the leanings
## that point at each, STORY.md 6.2: what a player did per minute of the match, and how much of it
## counts as a full lean. Nothing leaning past a full one is Balanced.
const BALANCED := "BALANCED"
const LEANS := {
	"HUNTER": [&"kills", 1.2],
	"BUMPER": [&"rams", 1.5],
	"GRAZER": [&"grazes", 6.0],
	"GREEDY": [&"jackpot_chips", 18.0],
}
## A Greedy player banks big, and a Cautious one banks often and small and seldom dies.
const GREEDY_BANK := 400.0
const CAUTIOUS_BANKS := 1.2
const CAUTIOUS_BANK := 180.0
const CAUTIOUS_DEATHS := 0.35

## The bulletin printed last, so two slips in a row never say the same thing.
static var _last_bulletin := ""


## The heading over the slip: Payslip once the stamp has come down, Payout slip before.
static func heading(stage: int) -> String:
	return StoryLines.PAYSLIP if stage >= Story.Stage.OPERATOR else StoryLines.SLIP


## The small print by the barcode, filled in for [param profile].
static func small_print(stage: int, profile: Profile) -> String:
	return StoryFill.fill(StoryLines.at(StoryLines.SMALL_PRINT, stage), profile)


## A bulletin of the House's for this slip, from the second stage, or empty: one of the stage
## reached's own, filled in with the player's numbers, never the one printed last, and one naming a
## trait only when a bot of that trait sat at [param slots]' table.
static func bulletin(
	stage: int, profile: Profile, slots: Array[PlayerSlot], rng: RandomNumberGenerator
) -> String:
	var lines: Array = StoryLines.at(StoryLines.BULLETINS, stage, [])
	var dealt := traits_at(slots)
	var fit: Array[String] = []
	for line: String in lines:
		if line.contains("{trait}") and dealt.is_empty():
			continue
		if line == _last_bulletin and lines.size() > 1:
			continue
		fit.append(line)
	if fit.is_empty():
		return ""
	var line := fit[rng.randi_range(0, fit.size() - 1)]
	_last_bulletin = line
	var table := {}
	if not dealt.is_empty():
		table["trait"] = dealt[rng.randi_range(0, dealt.size() - 1)]
	return StoryFill.fill(line, profile, table)


## The traits of the bots at [param slots]' table, in capitals, each once.
static func traits_at(slots: Array[PlayerSlot]) -> Array[String]:
	var found: Array[String] = []
	for slot: PlayerSlot in slots:
		if slot.bot_trait == null:
			continue
		var named := slot.bot_trait.display_name.to_upper()
		if named not in found:
			found.append(named)
	return found


## The line under a player's own line on the slip from the third stage, or empty before it.
static func classified(stage: int, slot: PlayerSlot, seconds: float) -> String:
	if stage < StoryLines.CLASSIFIED_FROM:
		return ""
	return StoryLines.CLASSIFIED.replace("{trait}", classify(slot.stats, slot.kills, seconds))


## The trait a match's numbers come closest to, STORY.md 6.2: kills to a Hunter, rams to a Bumper,
## grazes to a Grazer, big cash-outs and the Jackpot to a Greedy player, small cash-outs and few
## deaths to a Cautious one, and nothing much more than anything else to Balanced.
static func classify(stats: PlayerStats, kills: int, seconds: float) -> String:
	var minutes := maxf(seconds, 30.0) / 60.0
	var leans := {}
	for kind: String in LEANS:
		var key: StringName = LEANS[kind][0]
		var count := float(kills) if key == &"kills" else stats.value(key)
		leans[kind] = count / minutes / float(LEANS[kind][1])
	leans["GREEDY"] = maxf(float(leans["GREEDY"]), stats.value(&"biggest_bank") / GREEDY_BANK)
	var often := stats.value(&"banks") / minutes / CAUTIOUS_BANKS
	var small := stats.value(&"biggest_bank") < CAUTIOUS_BANK
	var careful := stats.value(&"deaths") / minutes < CAUTIOUS_DEATHS
	leans["CAUTIOUS"] = often if small and careful else 0.0
	var best := BALANCED
	var most := 1.0
	for kind: String in leans:
		if float(leans[kind]) >= most:
			most = float(leans[kind])
			best = kind
	return best
