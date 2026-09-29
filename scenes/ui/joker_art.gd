class_name JokerArt
extends RefCounted
## A picture for every joker, GAME.md 8.3a, drawn rather than loaded.
##
## One flat pictogram per card, in the kind's own color on the dark of the card, built from the
## shared vocabulary of [IconShapes]. Keeping them all to that vocabulary is what makes thirty of
## them look like one set rather than thirty drawings, and the whole thing weighs nothing and
## scales to any size, which a folder of PNGs cut for one card size would not.


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


## Draws [param id]'s picture into [param box] on [param on], in [param ink]. An id with no
## picture of its own gets the wild card's star, which is the house's own mark.
static func draw_into(on: CanvasItem, box: Rect2, id: StringName, ink: Color) -> void:
	var dim := IconShapes.behind(ink)
	match id:
		&"aimbot":
			IconShapes.ring(on, box, 0.5, 0.5, 0.3, ink)
			IconShapes.line(on, box, 0.5, 0.06, 0.5, 0.3, ink)
			IconShapes.line(on, box, 0.5, 0.7, 0.5, 0.94, ink)
			IconShapes.line(on, box, 0.06, 0.5, 0.3, 0.5, ink)
			IconShapes.line(on, box, 0.7, 0.5, 0.94, 0.5, ink)
			IconShapes.disc(on, box, 0.5, 0.5, 0.07, ink)
		&"backfire":
			IconShapes.bar(on, box, 0.54, 0.38, 0.36, 0.24, dim)
			IconShapes.flame(on, box, 0.56, 0.5, 0.44, -90.0, ink)
		&"big_tank":
			IconShapes.bar(on, box, 0.26, 0.38, 0.48, 0.46, dim)
			for at: float in [0.36, 0.5, 0.64]:
				IconShapes.bar(on, box, at - 0.05, 0.24, 0.1, 0.2, ink)
				IconShapes.tri(on, box, at, 0.18, 0.14, 0.0, ink)
		&"comeback":
			IconShapes.arc(on, box, 0.5, 0.56, 0.3, 160.0, 380.0, ink)
			IconShapes.tri(on, box, 0.5, 0.1, 0.22, 0.0, ink)
		&"curve_ball":
			IconShapes.arc(on, box, 0.86, 0.5, 0.56, 130.0, 230.0, dim)
			IconShapes.disc(on, box, 0.32, 0.26, 0.11, ink)
			IconShapes.disc(on, box, 0.3, 0.74, 0.11, ink)
		&"deep_pockets":
			IconShapes.bar(on, box, 0.18, 0.4, 0.64, 0.46, dim)
			IconShapes.disc(on, box, 0.36, 0.6, 0.12, ink)
			IconShapes.disc(on, box, 0.64, 0.6, 0.12, ink)
		&"direct_debit":
			IconShapes.bar(on, box, 0.16, 0.66, 0.68, 0.2, dim)
			IconShapes.line(on, box, 0.5, 0.12, 0.5, 0.48, ink)
			IconShapes.tri(on, box, 0.5, 0.62, 0.24, 180.0, ink)
		&"getaway_driver":
			IconShapes.bar(on, box, 0.1, 0.24, 0.5, 0.08, dim)
			IconShapes.bar(on, box, 0.1, 0.46, 0.66, 0.08, dim)
			IconShapes.bar(on, box, 0.1, 0.68, 0.4, 0.08, dim)
			IconShapes.tri(on, box, 0.82, 0.46, 0.34, 90.0, ink)
		&"glass_jackpot":
			IconShapes.disc(on, box, 0.5, 0.5, 0.36, dim)
			IconShapes.ring(on, box, 0.5, 0.5, 0.36, ink)
			IconShapes.line(on, box, 0.46, 0.16, 0.58, 0.42, ink)
			IconShapes.line(on, box, 0.58, 0.42, 0.4, 0.56, ink)
			IconShapes.line(on, box, 0.4, 0.56, 0.54, 0.84, ink)
		&"green_light":
			IconShapes.bar(on, box, 0.32, 0.08, 0.36, 0.84, dim)
			IconShapes.disc(on, box, 0.5, 0.26, 0.09, dim)
			IconShapes.disc(on, box, 0.5, 0.5, 0.09, dim)
			IconShapes.disc(on, box, 0.5, 0.74, 0.11, ink)
		&"hair_trigger":
			IconShapes.bolt(on, box, 0.5, 0.5, 0.42, ink)
		&"high_roller":
			IconShapes.bar(on, box, 0.16, 0.16, 0.68, 0.68, dim)
			for spot: Vector2 in [Vector2(0.32, 0.32), Vector2(0.5, 0.5), Vector2(0.68, 0.68)]:
				IconShapes.disc(on, box, spot.x, spot.y, IconShapes.PIP * 1.6, ink)
		&"hot_streak":
			IconShapes.flame(on, box, 0.28, 0.86, 0.3, 0.0, dim)
			IconShapes.flame(on, box, 0.72, 0.86, 0.3, 0.0, dim)
			IconShapes.flame(on, box, 0.5, 0.9, 0.46, 0.0, ink)
		&"insurance_policy":
			IconShapes.shield(on, box, 0.5, 0.5, 0.36, ink)
		&"jerry_can":
			IconShapes.bar(on, box, 0.22, 0.28, 0.5, 0.58, ink)
			IconShapes.bar(on, box, 0.3, 0.16, 0.3, 0.09, ink)
			IconShapes.bar(on, box, 0.66, 0.36, 0.16, 0.1, ink)
			IconShapes.line(on, box, 0.34, 0.4, 0.34, 0.76, dim)
		&"loaded_dice":
			IconShapes.bar(on, box, 0.2, 0.2, 0.6, 0.6, dim)
			for spot: Vector2 in [
				Vector2(0.34, 0.34),
				Vector2(0.66, 0.34),
				Vector2(0.5, 0.5),
				Vector2(0.34, 0.66),
				Vector2(0.66, 0.66)
			]:
				IconShapes.disc(on, box, spot.x, spot.y, IconShapes.PIP * 1.5, ink)
		&"lucky_seven":
			IconShapes.line(on, box, 0.24, 0.18, 0.76, 0.18, ink)
			IconShapes.line(on, box, 0.76, 0.18, 0.44, 0.86, ink)
			IconShapes.line(on, box, 0.34, 0.52, 0.62, 0.52, dim)
		&"magnet_hubcaps":
			IconShapes.arc(on, box, 0.5, 0.56, 0.3, 180.0, 360.0, ink)
			IconShapes.line(on, box, 0.2, 0.56, 0.2, 0.84, ink)
			IconShapes.line(on, box, 0.8, 0.56, 0.8, 0.84, ink)
			IconShapes.bar(on, box, 0.14, 0.78, 0.12, 0.1, dim)
			IconShapes.bar(on, box, 0.74, 0.78, 0.12, 0.1, dim)
		&"nitro_habit":
			IconShapes.bar(on, box, 0.34, 0.24, 0.32, 0.6, dim)
			IconShapes.bar(on, box, 0.42, 0.12, 0.16, 0.14, dim)
			IconShapes.flame(on, box, 0.5, 0.8, 0.3, 0.0, ink)
		&"odometer":
			IconShapes.arc(on, box, 0.5, 0.64, 0.34, 180.0, 360.0, dim)
			IconShapes.line(on, box, 0.5, 0.64, 0.72, 0.4, ink)
			IconShapes.disc(on, box, 0.5, 0.64, 0.07, ink)
		&"payday":
			IconShapes.disc(on, box, 0.5, 0.3, 0.2, ink)
			IconShapes.bar(on, box, 0.24, 0.56, 0.52, 0.12, dim)
			IconShapes.bar(on, box, 0.28, 0.74, 0.44, 0.12, dim)
		&"pickpocket":
			IconShapes.bar(on, box, 0.14, 0.54, 0.44, 0.34, dim)
			IconShapes.arc(on, box, 0.62, 0.62, 0.3, 200.0, 290.0, ink)
			IconShapes.disc(on, box, 0.74, 0.26, 0.15, ink)
		&"road_rage":
			IconShapes.burst(on, box, 0.5, 0.5, 0.4, ink)
		&"rubber_bumpers":
			IconShapes.arc(on, box, 0.5, 0.5, 0.36, 210.0, 330.0, ink)
			IconShapes.arc(on, box, 0.5, 0.5, 0.36, 30.0, 150.0, ink)
			IconShapes.disc(on, box, 0.5, 0.5, 0.12, dim)
		&"slipstream":
			IconShapes.bar(on, box, 0.1, 0.26, 0.58, 0.08, dim)
			IconShapes.bar(on, box, 0.22, 0.46, 0.58, 0.08, ink)
			IconShapes.bar(on, box, 0.1, 0.66, 0.44, 0.08, dim)
		&"snake_eyes":
			IconShapes.bar(on, box, 0.2, 0.2, 0.6, 0.6, dim)
			IconShapes.disc(on, box, 0.36, 0.36, IconShapes.PIP * 1.8, ink)
			IconShapes.disc(on, box, 0.64, 0.64, IconShapes.PIP * 1.8, ink)
		&"tailslide":
			IconShapes.arc(on, box, 0.72, 0.28, 0.5, 90.0, 190.0, dim)
			IconShapes.arc(on, box, 0.72, 0.28, 0.34, 90.0, 190.0, ink)
		&"tight_grip":
			IconShapes.disc(on, box, 0.5, 0.5, 0.3, dim)
			IconShapes.ring(on, box, 0.5, 0.5, 0.3, ink)
			IconShapes.bar(on, box, 0.12, 0.44, 0.76, 0.12, ink)
		&"toll_booth":
			IconShapes.bar(on, box, 0.14, 0.2, 0.12, 0.66, dim)
			IconShapes.bar(on, box, 0.3, 0.42, 0.58, 0.12, ink)
			IconShapes.disc(on, box, 0.2, 0.34, 0.08, ink)
		&"vulture":
			IconShapes.arc(on, box, 0.2, 0.16, 0.36, 10.0, 80.0, ink)
			IconShapes.arc(on, box, 0.8, 0.16, 0.36, 100.0, 170.0, ink)
			IconShapes.disc(on, box, 0.5, 0.5, 0.1, ink)
			IconShapes.tri(on, box, 0.5, 0.68, 0.16, 180.0, ink)
		_:
			IconShapes.star(on, box, 0.5, 0.5, 0.4, ink)


## Every id this knows a picture for, so a test can hold the set to the catalog.
static func known() -> Array[StringName]:
	var ids: Array[StringName] = [
		&"aimbot",
		&"backfire",
		&"big_tank",
		&"comeback",
		&"curve_ball",
		&"deep_pockets",
		&"direct_debit",
		&"getaway_driver",
		&"glass_jackpot",
		&"green_light",
		&"hair_trigger",
		&"high_roller",
		&"hot_streak",
		&"insurance_policy",
		&"jerry_can",
		&"loaded_dice",
		&"lucky_seven",
		&"magnet_hubcaps",
		&"nitro_habit",
		&"odometer",
		&"payday",
		&"pickpocket",
		&"road_rage",
		&"rubber_bumpers",
		&"slipstream",
		&"snake_eyes",
		&"tailslide",
		&"tight_grip",
		&"toll_booth",
		&"vulture",
		&"wild_card"
	]
	return ids
