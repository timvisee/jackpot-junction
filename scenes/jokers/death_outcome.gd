class_name DeathOutcome
extends RefCounted
## What happens when a kart dies, GAME.md 3.6, filled from the rules and then bent by the
## victim's and the killer's jokers before the match applies it.

var bank_fraction := 0.5
var drop_fraction := 0.3
var drop_max := 10
var joker_drop_chance := 0.2
var joker_drop_count := 1
var item_drop_chance := 0.5
## Share of the victim's coins that go straight into the killer's pot.
var steal_fraction := 0.0


static func from_rules(rules: MatchRules) -> DeathOutcome:
	var outcome := DeathOutcome.new()
	outcome.bank_fraction = rules.death_bank_fraction
	outcome.drop_fraction = rules.death_drop_fraction
	outcome.drop_max = rules.death_drop_max
	outcome.joker_drop_chance = rules.death_joker_drop_chance
	outcome.item_drop_chance = rules.death_item_drop_chance
	return outcome
