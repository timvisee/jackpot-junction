class_name FixedTraits
extends BotTraitTable
## The traits a Grand Prix dealt its bots at the start, handed out in seat order on every map of
## it, GAME.md 9.7. A bot is its way of driving: the Hunter in the second seat on the first map is
## the Hunter in the second seat on the last one, rather than whoever the draw came up with that
## time. Past the end of what was dealt it draws as any table does.

var dealt: Array[BotTrait] = []

var _next := 0


## The traits [param traits] handed out in order, drawing from [param table] after that.
static func of(table: BotTraitTable, traits: Array[BotTrait]) -> FixedTraits:
	var fixed := FixedTraits.new()
	fixed.entries = table.entries
	fixed.dealt = traits
	return fixed


func pick(rng: RandomNumberGenerator) -> BotTrait:
	if _next < dealt.size():
		_next += 1
		return dealt[_next - 1]
	return super.pick(rng)
