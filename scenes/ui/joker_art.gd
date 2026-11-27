class_name JokerArt
extends RefCounted
## A picture for every joker, GAME.md 8.3a: an SVG drawing of its own in assets/icons/jokers,
## printed by [IconPress] in the kind's color on the dark of the card. Every drawing keeps the same
## grid, corners, gaps and light, which is what makes fifty of them one set rather than fifty
## drawings; the printing is the house's, flat inks with the shadow side in a halftone screen.
## Kit's five cards, the House's painted over and drawn on again, print flat in his pencil instead,
## as his signs on the loyalty map do.

## Kit's cards, STORY.md 6.3, which print flat in his pencil.
const KIT: Array[StringName] = [
	&"brake_check", &"not_today", &"blind_spot", &"loose_change", &"under_the_table"
]


## A control that draws one joker's picture, to drop into a card. It keeps the picture square
## and centered in whatever room it is given, so a tall slot does not stretch the drawing.
class Picture:
	extends Control

	var id: StringName
	var ink := Color.WHITE

	func _draw() -> void:
		var side := minf(size.x, size.y)
		var box := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
		JokerArt.draw_into(self, box, id, ink)


## One joker's picture as a node, sized by whatever it is put in.
static func picture(id: StringName, ink: Color) -> Control:
	var art := Picture.new()
	art.id = id
	art.ink = ink
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art


## Draws [param id]'s picture into [param box] on [param on], in [param ink]; [param paper] for a
## light ground, where the ink is dark and the picture goes unshaded. An id with no drawing of its
## own gets Wild Card's, the house's own mark, which the tests keep from shipping.
static func draw_into(
	on: CanvasItem, box: Rect2, id: StringName, ink: Color, paper := false
) -> void:
	var ground := IconPress.Ground.PAPER if paper or id in KIT else IconPress.Ground.CARD
	if not IconPress.draw(on, box, id, ink, ground):
		IconPress.draw(on, box, &"wild_card", ink, ground)


## Every id this knows a picture for, so a test can hold the set to the catalog.
static func known() -> Array[StringName]:
	var ids: Array[StringName] = [
		&"aimbot",
		&"backfire",
		&"big_tank",
		&"burnout",
		&"carbon_copy",
		&"comeback",
		&"curve_ball",
		&"cushion_shot",
		&"daredevil",
		&"deep_pockets",
		&"direct_debit",
		&"double_tap",
		&"echo",
		&"flush_draw",
		&"getaway_driver",
		&"glass_jackpot",
		&"green_light",
		&"guardian_angel",
		&"hair_trigger",
		&"high_roller",
		&"hot_streak",
		&"insurance_policy",
		&"jerry_can",
		&"loaded_dice",
		&"lucky_charm",
		&"lucky_seven",
		&"magnet_hubcaps",
		&"nitro_habit",
		&"odometer",
		&"pack_rat",
		&"payday",
		&"pickpocket",
		&"pit_crew",
		&"road_rage",
		&"royal_court",
		&"rubber_bumpers",
		&"scar_tissue",
		&"second_wind",
		&"slipstream",
		&"snake_eyes",
		&"snowball",
		&"spare_tire",
		&"tailslide",
		&"tight_grip",
		&"toll_booth",
		&"copy_cat",
		&"vulture",
		&"wild_card",
		&"brake_check",
		&"not_today",
		&"blind_spot",
		&"loose_change",
		&"under_the_table",
	]
	return ids
