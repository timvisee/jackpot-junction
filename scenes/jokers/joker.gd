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


## Offer weight from rarity.
func weight() -> float:
	return RARITY_WEIGHTS[rarity]


## Two letters for compact HUD slots.
func initials() -> String:
	var parts := display_name.split(" ")
	if parts.size() >= 2:
		return parts[0].left(1) + parts[1].left(1)
	return display_name.left(2)


func on_attach(_kart: Kart) -> void:
	pass


func on_detach(_kart: Kart) -> void:
	pass


## Permanent stat changes, applied to the kart's own stat copies whenever its jokers change.
func modify_kart_stats(_stats: KartStats) -> void:
	pass


func modify_cannon_stats(_stats: CannonStats) -> void:
	pass


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
