class_name BayWays
extends RefCounted
## The kart dialog's cursor ways, GAME.md 4.4a, worked out on its own things, see [KartDialog]:
## between the hooks up and down either board and across the kart, up to Back, along the bench, and
## onto the rack while it is out.


## The cursor's ways between the hooks up and down either board, across the kart between them to
## the hook on the same row or the nearest above it, see [method BoardArt.across], and up to Back
## from the top hooks; the ways onto the bench are its own, see [method bench].
static func boards(on: KartDialog) -> void:
	for part: int in KartDialog.LEFT_HOOKS:
		way(on.hooks[part], SIDE_RIGHT, on.hooks[BoardArt.across(part, KartDialog.RIGHT_HOOKS)])
		way(on.hooks[part], SIDE_LEFT, on.hooks[part])
	for part: int in KartDialog.RIGHT_HOOKS:
		way(on.hooks[part], SIDE_LEFT, on.hooks[BoardArt.across(part, KartDialog.LEFT_HOOKS)])
		way(on.hooks[part], SIDE_RIGHT, on.hooks[part])
	for column: Array[int] in [KartDialog.LEFT_HOOKS, KartDialog.RIGHT_HOOKS]:
		for i: int in column.size():
			way(on.hooks[column[i]], SIDE_TOP, on.hooks[column[i - 1]] if i > 0 else on.back)
			if i + 1 < column.size():
				way(on.hooks[column[i]], SIDE_BOTTOM, on.hooks[column[i + 1]])
	way(on.back, SIDE_BOTTOM, on.hooks[KartDialog.RIGHT_HOOKS[0]])
	way(on.back, SIDE_LEFT, on.hooks[KartDialog.LEFT_HOOKS[0]])
	way(on.back, SIDE_RIGHT, on.back)
	way(on.back, SIDE_TOP, on.back)


## The bench's ways, as it is now: two rows of it, the cans over the name, its die and the plate
## where it can be typed into. Along each row, the cans on out to the bottom hooks either side;
## down from every can to the name, up from the name to the first can and from the die to the
## last; down to the cans from the bottom of the left board, the card back's hook or the trail's
## where there is no card back here, and between the shuffle's plate and the plate, or the last
## can where there is no plate to type.
static func bench(on: KartDialog) -> void:
	var card_back := on.hooks[KartDialog.CARD_BACK]
	var trail := on.hooks[KartDialog.LEFT_HOOKS[-2]]
	var shuffle := on.hooks[KartDialog.SHUFFLE]
	var bottom_left := card_back if card_back.visible else trail
	var typed := on.plate_field.visible
	for i: int in on.cans.size():
		way(on.cans[i], SIDE_LEFT, on.cans[i - 1] if i > 0 else bottom_left)
		way(on.cans[i], SIDE_RIGHT, on.cans[i + 1] if i + 1 < on.cans.size() else shuffle)
		way(on.cans[i], SIDE_TOP, bottom_left if i * 2 < on.cans.size() else shuffle)
		way(on.cans[i], SIDE_BOTTOM, on.name_box)
	way(on.name_box, SIDE_LEFT, on.name_box)
	way(on.name_box, SIDE_RIGHT, on.die)
	way(on.name_box, SIDE_TOP, on.cans[0])
	way(on.name_box, SIDE_BOTTOM, on.name_box)
	way(on.die, SIDE_LEFT, on.name_box)
	way(on.die, SIDE_RIGHT, on.plate_field if typed else shuffle)
	way(on.die, SIDE_TOP, on.cans[-1])
	way(on.die, SIDE_BOTTOM, on.die)
	way(on.plate_field, SIDE_LEFT, on.die)
	way(on.plate_field, SIDE_RIGHT, on.plate_field)
	way(on.plate_field, SIDE_TOP, shuffle)
	way(on.plate_field, SIDE_BOTTOM, on.plate_field)
	way(trail, SIDE_BOTTOM, card_back if card_back.visible else on.cans[0])
	way(card_back, SIDE_BOTTOM, on.cans[0])
	way(shuffle, SIDE_LEFT, bottom_left)
	way(shuffle, SIDE_BOTTOM, on.plate_field if typed else on.cans[-1])


## The ways of the rack [param on] has out, its part's, landing on [param landing], the worn piece's
## cell or null: up from every cell to its part's hook, along the row and no further at either end,
## and down off the bottom of either board onto it, while it is out over the bench.
static func rack(on: KartDialog, landing: Control) -> void:
	var cells := on.tray.cells
	for cell: PartTray.TrayCell in cells:
		way(cell, SIDE_TOP, on.hooks[on.open_part])
		way(cell, SIDE_BOTTOM, cell)
	if cells.is_empty():
		return
	way(cells[0], SIDE_LEFT, cells[0])
	way(cells[-1], SIDE_RIGHT, cells[-1])
	var onto: Control = landing if landing != null else cells[0]
	var card_back := on.hooks[KartDialog.CARD_BACK]
	var bottom := card_back if card_back.visible else on.hooks[KartDialog.LEFT_HOOKS[-2]]
	way(bottom, SIDE_BOTTOM, onto)
	way(on.hooks[KartDialog.SHUFFLE], SIDE_BOTTOM, onto)


## [param from]'s way to [param side] leads to [param to].
static func way(from: Control, side: Side, to: Control) -> void:
	from.set_focus_neighbor(side, from.get_path_to(to))
