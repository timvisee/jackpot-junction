class_name Joker
extends Resource
## A passive rule modifier held for the rest of the match, GAME.md 3.7 and 7.3. Every holder gets
## its own copy, so a joker may keep state. The hooks below do nothing; each joker overrides the
## ones it needs.

enum Rarity { COMMON, UNCOMMON, RARE }
enum Kind { STAT, RULE, CURSED }
## What it feeds, GAME.md 7.3, Suits, in the order of [enum SuitArt.Suit]: Spades shooting, Hearts
## staying alive, Diamonds chips and banking, Clubs driving and mult, and wild for any of them.
enum Suit { SPADES, HEARTS, DIAMONDS, CLUBS, WILD }

## How many times as much, as the cards say it, see [method times].
const TIMES: Array[String] = ["", "once", "twice", "three times", "four times", "five times"]
const RARITY_WEIGHTS: Dictionary[int, float] = {
	Rarity.COMMON: 60.0, Rarity.UNCOMMON: 30.0, Rarity.RARE: 10.0
}

@export var id: StringName
@export var display_name := ""
@export var description := ""
@export var rarity := Rarity.COMMON
@export var kind := Kind.RULE
@export var suit := Suit.WILD
## A stackable joker is offered again while held, and taken off the floor again, up to [member
## most] copies, GAME.md 7.3. Where a stack's copies do more than add up, its first copy applies
## the whole stack and the others nothing, see [method stacked], so every stack's numbers are the
## ones the card says rather than one copy's multiplied by another's.
@export var stackable := false
## The most copies of a stackable joker one hand holds, 0 for any number.
@export var most := 0
## Whether every deck holds it from the start, GAME.md 8.9; the rest are added by the loyalty
## program, a landmark of its map naming each, see [member LoyaltyLandmark.jokers].
@export var starting_deck := false
## Whether it does something in a fight, GAME.md 9.7a: a showdown deals its hand from these alone,
## since there is nothing in its room to bank, collect or cash out.
@export var fights := false

## How many copies of this joker its holder holds, this one among them, and whether this one is
## the first of them, kept by [JokerHolder].
var held := 1
var leads := true


## Says this joker has just done something by itself for [param kart], GAME.md 8.3: its card goes
## off in the hand with [param word] over it. Only where the karts are run, the host online, which
## says it to every client: a puppet's jokers do nothing of their own.
func went_off(kart: Kart, word: String) -> void:
	if kart != null and not kart.puppet:
		Events.joker_went_off.emit(kart.slot, id, word)


## What the catalog says of this joker having gone off by itself [param times] times, GAME.md 8.8,
## in its own words, Collected 12 tolls; nothing for a joker that never goes off, see
## [method went_off].
func went_off_words(_times: int) -> String:
	return ""


## Says this joker has just gone from [param kart]'s hand by itself, used up, GAME.md 8.3: its
## card burns out of the hand with [param word] over it.
func used_up(kart: Kart, word: String) -> void:
	if kart != null and not kart.puppet:
		Events.joker_used_up.emit(kart.slot, id, word)


## Whether this joker banks points every tick of its own accord, Direct Debit: the tutorial holds
## that off until the Junction is in the room, GAME.md 9.4a.
func banks_on_step() -> bool:
	return false


## Offer weight from rarity.
func weight() -> float:
	return RARITY_WEIGHTS[rarity]


## Whether a hand holding [param copies] of this joker has room for one more of it: none held, or
## a stack short of its most.
func room_for(copies: int) -> bool:
	return copies <= 0 or (stackable and (most <= 0 or copies < most))


## How many copies this one applies: the whole stack, up to [member most], for the first copy of
## it, and none for the others. For the jokers whose copies do more than add up.
func stacked() -> int:
	if not leads:
		return 0
	return mini(held, most) if most > 0 else held


## The card's own words for [param copies] held, GAME.md 8.3: [member description] with every
## number in braces filled in from [method stack_values], and each a stack has made other than one
## copy's put through [param mark], a format with a place for the value, to set it apart. With
## [param details], what the card leaves out as well: what one copy says beside each of those, and
## how far it stacks.
func describe(copies := 1, mark := "%s", details := false) -> String:
	var count := 1
	if stackable:
		count = clampi(copies, 1, most if most > 0 else maxi(copies, 1))
	var one := stack_values(1)
	var now := stack_values(count)
	var said := description
	for key: String in now:
		var value := str(now[key])
		var alone := str(one[key])
		var shown := value if value == alone else mark % value
		if details and value != alone:
			shown += " (%s)" % (alone.left(1).to_lower() + alone.substr(1))
		said = said.replace("{%s}" % key, shown)
	if stackable and details:
		said += " Stacks up to ×%d." % most if most > 0 else " Stacks."
	return said


## The numbers of the card's words for [param copies] of the joker, by the names its [member
## description] has them under.
func stack_values(_copies: int) -> Dictionary:
	return {}


## [param count] of a thing as the cards say it: "1 coin", "2 coins".
static func counted(count: int, one: String, many: String) -> String:
	return "%d %s" % [count, one if count == 1 else many]


## How many times as much as the cards say it: "twice", "three times".
static func times(factor: int) -> String:
	return TIMES[factor] if factor < TIMES.size() else "%d times" % factor


## A figure as the cards say it: 2 rather than 2.0, and one decimal at most.
static func figure(value: float) -> String:
	return String.num(value, 1)


func on_attach(_kart: Kart) -> void:
	pass


func on_detach(_kart: Kart) -> void:
	pass


## Permanent stat changes, applied to the kart's own stat copies whenever its jokers change.
func modify_kart_stats(_stats: KartStats) -> void:
	pass


func modify_cannon_stats(_stats: CannonStats) -> void:
	pass


## Where a shot leaves, given where the kart says it is pointing. Aimbot bends the answer toward
## an enemy afterwards, see [KartAim]; this is the direction it starts from.
func modify_aim(_kart: Kart, direction: Vector3) -> Vector3:
	return direction


func modify_pickup_radius(radius: float) -> float:
	return radius


func modify_coin_value(_kart: Kart, _chip: Chip, value: int) -> int:
	return value


## A chip picked up, worth [param worth] coins once the jokers have had their say about it.
func on_chip_collected(_kart: Kart, _chip: Chip, _worth: int) -> void:
	pass


func modify_mult_gain(_kart: Kart, amount: float, _reason: StringName) -> float:
	return amount


func modify_graze_mult(_kart: Kart, amount: float) -> float:
	return amount


func on_turbo_pad(_kart: Kart) -> void:
	pass


## The holder's drift was carried all the way to its exit boost, GAME.md 4.1: where the karts are
## run, the host online.
func on_drift_boost(_kart: Kart) -> void:
	pass


## A tick of the holder's own time, for the jokers that pay rather than react. Returns points to
## bank straight into the holder's score; coins and mult a joker hands out itself.
func on_step(_kart: Kart, _delta: float) -> int:
	return 0


## The seconds in which the Junction drain rate doubles.
func modify_bank_doubling(_kart: Kart, doubling: float) -> float:
	return doubling


## Multiplier on points banked at the Junction.
func modify_bank_payout(_kart: Kart, multiplier: float) -> float:
	return multiplier


## Points this joker's holder banks when another kart completes a cash-out.
func on_other_bank_completed(_kart: Kart, _other_slot: int, _total: int) -> int:
	return 0


## Bends the holder's own death.
func modify_death(_kart: Kart, _death: DeathOutcome) -> void:
	pass


## Bends the death of a kart the holder just killed.
func on_victim_death(_killer: Kart, _victim: Kart, _death: DeathOutcome) -> void:
	pass


## The share of the holder's coins a ram they live through knocks out of their pot, GAME.md 4.1.
func modify_ram_knock(_kart: Kart, fraction: float) -> float:
	return fraction


## Called before the pot resets on death.
func on_death(_kart: Kart) -> void:
	pass


func on_respawn(_kart: Kart) -> void:
	pass


## Whether the holder kills by ramming right now, besides Boost.
func ram_kills(_kart: Kart) -> bool:
	return false


func modify_offer_count(count: int) -> int:
	return count


## How many jokers the holder may hold at once, GAME.md 3.7.
func modify_joker_slots(count: int) -> int:
	return count


## How many cards of one suit make the holder's hand Suited in it, GAME.md 7.3: Flush Draw's two.
func modify_suited(count: int) -> int:
	return count


## Lives the holder has on top of the rules' own, GAME.md 3.6, see [KartLives].
func extra_lives() -> int:
	return 0


## Whether nothing patches the holder up while it lives: neither the Junction nor a kill heals it,
## and only coming back brings its lives back, GAME.md 3.6.
func blocks_healing() -> bool:
	return false


## Whether the holder's death takes this joker with it, gone rather than kept or dropped.
func lost_on_death() -> bool:
	return false


## Whether a death's dropped jokers go on the floor as copies, the holder keeping its own.
func copies_drops() -> bool:
	return false


## Whether a hit about to cost the holder a life, by [param cause], is taken by something else
## instead, see [KartLives]. The joker does whatever takes it.
func spares(_kart: Kart, _cause: StringName) -> bool:
	return false
