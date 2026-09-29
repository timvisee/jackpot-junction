class_name FixedTraits
extends BotTraitTable
## The traits a Grand Prix dealt its bots at the start, handed out in seat order on every map of
## it, GAME.md 9.7. A bot is its way of driving: the Hunter in the second seat on the first map is
## the Hunter in the second seat on the last one, rather than whoever the draw came up with that
## time, and in the same dress. Past the end of what was dealt it draws as any table does.

var dealt: Array[BotTrait] = []
## The dress dealt with each trait, in the same order.
var dressed: Array = []

var _next := 0


## The traits [param traits] handed out in order, drawing from [param table] after that.
static func of(table: BotTraitTable, traits: Array[BotTrait], styles: Array = []) -> FixedTraits:
	var fixed := FixedTraits.new()
	fixed.entries = table.entries
	fixed.dealt = traits
	fixed.dressed = styles
	return fixed


func pick(rng: RandomNumberGenerator) -> BotTrait:
	if _next < dealt.size():
		_next += 1
		return dealt[_next - 1]
	return super.pick(rng)


## The dress dealt with the trait [method pick] handed out last.
func dress(rng: RandomNumberGenerator) -> KartStyle:
	if _next > 0 and _next <= dealt.size() and _next <= dressed.size():
		return KartStyle.from_array(dressed[_next - 1])
	return super.dress(rng)
