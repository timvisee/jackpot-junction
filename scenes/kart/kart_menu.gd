class_name KartMenu
extends RefCounted
## The joker menu a kart carries, GAME.md 3.7. Kept apart from the kart itself so that file stays
## about what a kart is and does, the same way [KartAim] keeps aiming out of it.

## How far the steering has to be pushed to walk the cursor one card, GAME.md 3.7.
const STEER_STEP := 0.6


## Held open while driving; cycle, pick, drop or destroy. With [param can_change] false the cards
## may only be looked through, which is what a dead kart's hand is.
##
## A kart played at a client drops and destroys nothing here: which card its player meant is the
## one under the cursor on their own screen, and it arrives by name, see [JokerWire]. The cursor
## here is only the host's guess at theirs.
static func step(kart: Kart, can_change: bool = true) -> void:
	var input := kart.input
	if not browse(kart, input):
		return
	if can_change and not input is NetInput:
		if input.joker_drop_pressed:
			kart.drop_joker(kart.menu_index)
		elif input.joker_destroy_pressed:
			kart.destroy_joker(kart.menu_index)
	kart.menu_index = clampi(kart.menu_index, 0, maxi(kart.jokers.count() - 1, 0))


## The menu opened or shut, and its cursor walked, off [param input], without dropping or
## destroying anything: all a client does with its own kart's hand, GAME.md 10.3, before saying
## which card it dropped or destroyed. Whether it is open.
static func browse(kart: Kart, input: KartInput) -> bool:
	var looking := input.joker_inspect
	kart.menu_open = (input.joker_menu or looking >= 0) and kart.jokers.count() > 0
	if not kart.menu_open:
		kart.menu_index = 0
		kart.menu_steer = 0
		return false
	var count := kart.jokers.count()
	# A card held open on a touch screen, GAME.md 4.2, keeps the hand on that card: the other thumb
	# is on the stick, and there the stick drives rather than walking the cursor off it.
	if looking >= 0:
		kart.menu_index = clampi(looking, 0, count - 1)
		kart.menu_steer = 0
	else:
		var steered := _steer_step(kart, input)
		if input.joker_next_pressed or steered > 0:
			kart.menu_index = (kart.menu_index + 1) % count
		if input.joker_prev_pressed or steered < 0:
			kart.menu_index = posmod(kart.menu_index - 1, count)
		if input.joker_select >= 0 and input.joker_select < count:
			kart.menu_index = input.joker_select
	return true


## Which way the steering wants to walk the cursor, one card per push. Whatever the player
## steers with picks cards too, so the arrow keys work on a keyboard and the stick or the
## D-pad works on a pad, with no second set of keys to learn. Holding a direction moves one
## card and then waits, so a card is never skipped past while the wheel is held over. It is the
## push that walks it rather than the wheel, which simple driving turns on its own, GAME.md 4.2.
static func _steer_step(kart: Kart, input: KartInput) -> int:
	var pushed := 0
	if absf(input.cursor) > STEER_STEP:
		pushed = signi(roundi(input.cursor))
	var stepped := pushed if pushed != kart.menu_steer else 0
	kart.menu_steer = pushed
	return stepped
