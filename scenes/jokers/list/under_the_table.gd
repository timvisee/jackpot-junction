extends Joker
## Under the Table, one of Kit's cards, STORY.md 6.3: the kart's banked score is off the standings
## until the whistle, so there is no bounty and no match point on it, see [KitCards]; and Last Call
## pays it single, the Junction's doubling taken back off its payouts. "Keep it off their board."


func modify_bank_payout(kart: Kart, multiplier: float) -> float:
	var match_node: Match = null
	if kart.is_inside_tree():
		match_node = kart.get_tree().get_first_node_in_group(&"match") as Match
	if match_node != null and match_node.state == Match.State.LAST_CALL:
		return multiplier / maxf(match_node.rules.last_call_payout, 1.0)
	return multiplier
