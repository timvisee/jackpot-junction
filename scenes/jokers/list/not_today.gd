extends Joker
## Not Today, one of Kit's cards, STORY.md 6.3: a pick skipped adds 2 mult for the life it comes
## back to, and each of the House's cards taken takes 1 off it. "Say no to one of theirs."

const SKIPPED := 2.0
const TAKEN := -1.0

var _kart: Kart
var _owed := 0.0


func on_attach(kart: Kart) -> void:
	_kart = kart
	if not Events.joker_answered.is_connected(_on_answered):
		Events.joker_answered.connect(_on_answered)


func on_detach(_kart_left: Kart) -> void:
	if Events.joker_answered.is_connected(_on_answered):
		Events.joker_answered.disconnect(_on_answered)
	_kart = null


## The holder's pick answered where it was answered: skipped, or a card of the House's taken. Owed
## to the life it comes back to, since a pick is answered while the kart is down.
func _on_answered(slot: int, joker: StringName) -> void:
	if _kart == null or not is_instance_valid(_kart) or _kart.slot != slot or _kart.puppet:
		return
	if joker == &"":
		_owed += SKIPPED
	elif joker not in KitCards.IDS:
		_owed += TAKEN


func on_respawn(kart: Kart) -> void:
	if _owed == 0.0 or kart.puppet:
		return
	var owed := _owed
	_owed = 0.0
	# Never under the pot's own 1.
	var given := maxf(owed, 1.0 - kart.pot.mult)
	kart.jokers.pay_mult(self, given, &"not_today")
	went_off(kart, ("+%s MULT" if given > 0.0 else "%s MULT") % figure(given))
