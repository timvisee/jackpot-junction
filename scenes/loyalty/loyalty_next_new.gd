class_name LoyaltyNextNew
extends RefCounted
## Next new on the loyalty program's map, GAME.md 8.9, see [NextNew]: the landmarks won and drawn on
## the map that the cursor has not been on yet, in the map's own order, the House's sheet's and then
## Kit's, the order the list puts two bets as near done in. Pressed, the cursor is set down at the
## next of them rather than driven there, so a press never waits on the kart, and the pane says it,
## which takes its NEW tag off. Kept out of [LoyaltyDialog] the way [MatchEnd] is out of [Match].


## Next new in [param dialog]'s [param head], for [param profile]'s map: a ticket on the cover as
## Back is and the first of what is at the head's right, before the List switch; the head fitted
## again to the room as it comes and goes, see [method LoyaltyDialog._fit_head].
static func add_to(dialog: LoyaltyDialog, head: HBoxContainer, profile: Profile) -> NextNew:
	var made := NextNew.around(AtlasTicketStyle.ticket(NextNew.WORDS, 0.0))
	made.asked.connect(jump.bind(dialog))
	made.visibility_changed.connect(dialog._fit_head, CONNECT_DEFERRED)
	made.show_left(left(profile))
	head.add_child(made)
	return made


## Every landmark drawn on [param profile]'s map, the House's sheet's and then Kit's, each in the
## map's own order.
static func order(profile: Profile) -> Array[StringName]:
	var ids: Array[StringName] = []
	for sheet: int in [LoyaltyMapLayout.Sheet.HOUSE, LoyaltyMapLayout.Sheet.KIT]:
		for each: LoyaltyLandmark in Loyalty.map().landmarks:
			if LoyaltyMapLayout.sheet_of(each) == sheet and Loyalty.is_drawn(profile, each):
				ids.append(each.id)
	return ids


## How many landmarks drawn on [param profile]'s map are new, see [method Loyalty.has_fresh].
static func left(profile: Profile) -> int:
	return order(profile).filter(profile.loyalty.is_fresh).size()


## [param dialog]'s cursor at once at the next landmark wearing NEW after the one its pane says, as
## a row of the list pressed sets it down: the list put away for the map, the map turned to its
## sheet and round it, and the pane saying it. Nothing while the editions, the card in full or the
## word on what the program is are up over the map.
static func jump(dialog: LoyaltyDialog) -> void:
	if dialog.is_closing() or dialog.card_view != null or dialog.intro != null:
		return
	if dialog._editions != null:
		return
	var profile := dialog.map_view.profile
	var at := StringName(dialog.pane.shown)
	var next: Variant = NextNew.after(order(profile), at, profile.loyalty.is_fresh)
	if next == null:
		return
	if LoyaltyDialog.listed:
		dialog.set_listed(false)
	dialog.map_view.stand_at(next)
	dialog._describe(next)
