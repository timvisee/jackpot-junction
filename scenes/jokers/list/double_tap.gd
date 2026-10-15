extends Joker
## Double Tap: the holder's bullets wait out only half of a wounded kart's moment of grace, GAME.md
## 3.6, before they can hit it again, a quarter with two and an eighth with three, GAME.md 7.3. The
## grace is the wounded kart's, so it is asked where a bullet reaches it, see [method
## KartLives.tapped].

## How much of the grace a stack of none to three waits out, as the card says it: as fractions,
## set as the font sets them.
const SHARES: Array[String] = ["all", "½", "¼", "⅛"]


## How much of the grace [param copies] wait out.
static func share(copies: int) -> float:
	return pow(0.5, copies)


func modify_wound_grace(grace_share: float) -> float:
	var copies := stacked()
	return grace_share * share(copies) if copies > 0 else grace_share


func stack_values(copies: int) -> Dictionary:
	return {"share": SHARES[clampi(copies, 0, SHARES.size() - 1)]}
