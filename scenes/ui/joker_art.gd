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
		&"brake_check", &"not_today", &"blind_spot", &"loose_change", &"under_the_table":
			KitArt.draw_into(on, box, id, ink)
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
		&"carbon_copy":
			IconShapes.bar(on, box, 0.2, 0.16, 0.42, 0.56, dim)
			IconShapes.bar(on, box, 0.38, 0.28, 0.42, 0.56, ink)
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
		&"pack_rat":
			IconShapes.disc(on, box, 0.5, 0.6, 0.3, dim)
			IconShapes.bar(on, box, 0.38, 0.18, 0.24, 0.14, ink)
			IconShapes.disc(on, box, 0.42, 0.58, 0.08, ink)
			IconShapes.disc(on, box, 0.6, 0.54, 0.08, ink)
			IconShapes.disc(on, box, 0.5, 0.72, 0.08, ink)
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
		&"guardian_angel":
			IconShapes.shield(on, box, 0.5, 0.6, 0.28, ink)
			IconShapes.ring(on, box, 0.5, 0.2, 0.13, dim)
		&"high_roller":
			IconShapes.bar(on, box, 0.16, 0.16, 0.68, 0.68, dim)
			for spot: Vector2 in [Vector2(0.32, 0.32), Vector2(0.5, 0.5), Vector2(0.68, 0.68)]:
				IconShapes.disc(on, box, spot.x, spot.y, IconShapes.PIP * 1.6, ink)
		&"hot_streak":
			IconShapes.flame(on, box, 0.28, 0.86, 0.3, 0.0, dim)
			IconShapes.flame(on, box, 0.72, 0.86, 0.3, 0.0, dim)
			IconShapes.flame(on, box, 0.5, 0.9, 0.46, 0.0, ink)
		&"scar_tissue":
			IconShapes.heart(on, box, 0.5, 0.52, 0.34, ink)
			IconShapes.line(on, box, 0.22, 0.34, 0.74, 0.7, dim)
			for stitch: float in [0.34, 0.48, 0.62]:
				var along := 0.34 + (stitch - 0.22) * 0.69
				IconShapes.line(
					on, box, stitch - 0.05, along + 0.06, stitch + 0.05, along - 0.06, dim
				)
		&"spare_tire":
			IconShapes.ring(on, box, 0.5, 0.5, 0.36, ink)
			IconShapes.ring(on, box, 0.5, 0.5, 0.26, dim)
			IconShapes.heart(on, box, 0.5, 0.5, 0.14, ink)
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
		&"double_tap":
			# Two shots at one mark, the second right behind the first.
			for y: float in [0.36, 0.64]:
				IconShapes.bar(on, box, 0.08, y - 0.04, 0.3, 0.08, dim)
				IconShapes.disc(on, box, 0.48, y, 0.1, ink)
			IconShapes.ring(on, box, 0.8, 0.5, 0.13, ink)
			IconShapes.disc(on, box, 0.8, 0.5, 0.04, ink)
		&"cushion_shot":
			# A shot off the cushion, and the chip it pays.
			IconShapes.bar(on, box, 0.8, 0.1, 0.1, 0.8, dim)
			IconShapes.line(on, box, 0.16, 0.22, 0.76, 0.52, ink)
			IconShapes.line(on, box, 0.76, 0.52, 0.3, 0.84, ink)
			IconShapes.disc(on, box, 0.3, 0.84, 0.07, ink)
			IconShapes.ring(on, box, 0.24, 0.24, 0.1, dim)
		&"snowball":
			IconShapes.disc(on, box, 0.22, 0.74, 0.08, dim)
			IconShapes.disc(on, box, 0.42, 0.62, 0.13, dim)
			IconShapes.disc(on, box, 0.68, 0.44, 0.21, ink)
		&"second_wind":
			IconShapes.ring(on, box, 0.5, 0.52, 0.36, dim)
			IconShapes.flame(on, box, 0.5, 0.8, 0.44, 0.0, ink)
		&"daredevil":
			# A heart, and a shot gone close past it.
			IconShapes.heart(on, box, 0.42, 0.6, 0.3, ink)
			IconShapes.bar(on, box, 0.24, 0.2, 0.44, 0.07, dim)
			IconShapes.disc(on, box, 0.76, 0.235, 0.08, ink)
		&"burnout":
			# A turbo pad's chevrons, swung round on a drift's curve.
			IconShapes.arc(on, box, 0.5, 0.5, 0.4, 120.0, 240.0, dim)
			IconShapes.tri(on, box, 0.44, 0.5, 0.24, 90.0, dim)
			IconShapes.tri(on, box, 0.66, 0.5, 0.24, 90.0, ink)
		&"copy_cat":
			_copy_cat(on, box, ink, dim)
		&"flush_draw":
			# Two of a suit, which is enough.
			var side := box.size * 0.42
			SuitArt.draw_into(on, Rect2(IconShapes.at(box, 0.14, 0.22), side), 0, dim)
			SuitArt.draw_into(on, Rect2(IconShapes.at(box, 0.44, 0.36), side), 0, ink)
		&"royal_court":
			IconShapes.crown(on, Rect2(IconShapes.at(box, 0.22, 0.08), box.size * 0.56), ink)
			# A curse's skull under it, its eyes cut out in the card's own dark.
			var under := Rect2(IconShapes.at(box, 0.3, 0.5), box.size * 0.4)
			IconShapes.skull(on, under, dim, Color(0.11, 0.11, 0.14))
		&"echo":
			# A chip, and its ring going out again and again, fainter each time.
			IconShapes.disc(on, box, 0.26, 0.5, 0.12, ink)
			IconShapes.arc(on, box, 0.26, 0.5, 0.28, -50.0, 50.0, ink)
			IconShapes.arc(on, box, 0.26, 0.5, 0.46, -45.0, 45.0, dim)
			IconShapes.arc(on, box, 0.26, 0.5, 0.64, -40.0, 40.0, IconShapes.behind(dim))
		&"lucky_charm":
			# A four-leaf clover on its stem.
			IconShapes.line(on, box, 0.5, 0.5, 0.64, 0.9, dim)
			for leaf: Vector2 in [
				Vector2(0.37, 0.37), Vector2(0.63, 0.37), Vector2(0.37, 0.63), Vector2(0.63, 0.63)
			]:
				IconShapes.disc(on, box, leaf.x, leaf.y, 0.15, ink)
			IconShapes.disc(on, box, 0.5, 0.5, 0.06, dim)
		&"pit_crew":
			# A wrench over a turbo pad's chevron.
			IconShapes.tri(on, box, 0.3, 0.7, 0.3, 0.0, dim)
			IconShapes.tri(on, box, 0.3, 0.86, 0.3, 0.0, dim)
			IconShapes.line(on, box, 0.3, 0.76, 0.66, 0.36, ink)
			IconShapes.ring(on, box, 0.72, 0.28, 0.12, ink)
			IconShapes.disc(on, box, 0.79, 0.21, 0.07, Color(0.11, 0.11, 0.14))
		_:
			IconShapes.star(on, box, 0.5, 0.5, 0.4, ink)


## Copy Cat: a cat's paw print, and the same print again behind it, fainter, the copy.
static func _copy_cat(on: CanvasItem, box: Rect2, ink: Color, dim: Color) -> void:
	_paw(on, box, Vector2(0.66, 0.36), dim)
	_paw(on, box, Vector2(0.36, 0.6), ink)


## A cat's paw print round [param at]: its pad, and its four toes over it.
static func _paw(on: CanvasItem, box: Rect2, at: Vector2, ink: Color) -> void:
	IconShapes.disc(on, box, at.x, at.y + 0.04, 0.13, ink)
	for toe: int in 4:
		var angle := deg_to_rad(-150.0 + toe * 40.0)
		var p := at + Vector2(cos(angle), sin(angle)) * 0.2
		IconShapes.disc(on, box, p.x, p.y, 0.055, ink)


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
