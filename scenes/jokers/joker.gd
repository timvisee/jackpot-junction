class_name Joker
extends Resource
## A passive rule modifier held for the rest of the match, GAME.md 3.7 and 7.3. Every holder gets
## its own copy, so a joker may keep state. The hooks below do nothing; each joker overrides the
## ones it needs.

enum Rarity { COMMON, UNCOMMON, RARE }
enum Kind { STAT, RULE, CURSED }

const RARITY_WEIGHTS: Dictionary[int, float] = {
	Rarity.COMMON: 60.0, Rarity.UNCOMMON: 30.0, Rarity.RARE: 10.0
}

@export var id: StringName
@export var display_name := ""
@export var description := ""
@export var rarity := Rarity.COMMON
@export var kind := Kind.RULE
## A stackable joker is offered again while held, and taken off the floor again; every copy
## applies its effect once more.
@export var stackable := false


## Offer weight from rarity.
func weight() -> float:
	return RARITY_WEIGHTS[rarity]


## Whether a hand holding [param copies] of this joker has room for one more of it: none held, or
## one that stacks.
func room_for(copies: int) -> bool:
	return copies <= 0 or stackable


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


func on_chip_collected(_kart: Kart, _chip: Chip) -> void:
	pass


func modify_mult_gain(_kart: Kart, amount: float, _reason: StringName) -> float:
	return amount


func modify_graze_mult(_kart: Kart, amount: float) -> float:
	return amount


func on_turbo_pad(_kart: Kart) -> void:
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
