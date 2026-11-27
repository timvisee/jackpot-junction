class_name PowerUpArt
extends RefCounted
## A picture for every power-up, GAME.md 8.3a: an SVG drawing of its own in
## assets/icons/powerups, printed by [IconPress] the same way the jokers' are, so the two sets read
## as one hand's work.
##
## Each is printed in the item's own color, which the item carries, so the picture never names a
## color itself. An item is picked up, held and played in a second or two, and a name read off
## the HUD in that time is a name read instead of a corner taken.


## A control that draws one power-up's picture, square and centered in whatever room it is given.
class Picture:
	extends Control

	# Redrawn on a change and not on every frame it is told the same thing, GAME.md 10.7.
	var id: StringName:
		set(value):
			if value == id:
				return
			id = value
			queue_redraw()
	var ink := Color.WHITE:
		set(value):
			if value == ink:
				return
			ink = value
			queue_redraw()
	## Whether Guardian Angel will spend it by itself, which hangs the joker's halo over it, see
	## [method PowerUpArt.halo].
	var halo := false:
		set(value):
			if value == halo:
				return
			halo = value
			queue_redraw()

	func _draw() -> void:
		var side := minf(size.x, size.y)
		var box := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
		PowerUpArt.draw_into(self, box, id, ink)
		if halo:
			PowerUpArt.halo(self, Vector2(box.get_center().x, box.position.y), side * 0.6)


## One power-up's picture as a node, sized by whatever it is put in.
static func picture(id: StringName, ink: Color) -> Picture:
	var art := Picture.new()
	art.id = id
	art.ink = ink
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art


## Draws [param id]'s picture into [param box], in [param ink]; [param paper] for a light ground,
## where the ink is dark and the picture goes unshaded. An id with no drawing of its own gets a
## plain ring, which is what an unknown item is, and which the tests keep from shipping.
static func draw_into(
	on: CanvasItem, box: Rect2, id: StringName, ink: Color, paper := false
) -> void:
	var ground := IconPress.Ground.PAPER if paper else IconPress.Ground.CARD
	if not IconPress.draw(on, box, id, ink, ground):
		IconShapes.ring(on, box, 0.5, 0.5, 0.32, ink)


## Every id this knows a picture for, so a test can hold the set to the item list.
static func known() -> Array[StringName]:
	var ids: Array[StringName] = [
		&"bomb",
		&"boomerang",
		&"boost",
		&"bullet_wipe",
		&"chain_lightning",
		&"coin_magnet",
		&"decoy_kart",
		&"flak_cannon",
		&"grenade",
		&"oil_stain",
		&"proximity_mine",
		&"railgun",
		&"ricochet_cannon",
		&"rocket",
		&"scrambler",
		&"shield",
		&"spread_cannon",
		&"sticky_bomb",
		&"swivel_cannon",
		&"turret",
		&"windfall"
	]
	return ids


## Guardian Angel's halo, GAME.md 7.3: a flat ring of gold, as on the joker's card, [param wide]
## across round [param middle] on [param on], hung over an item the joker will spend by itself.
static func halo(on: CanvasItem, middle: Vector2, wide: float, ink := HouseTheme.FOIL) -> void:
	var reach := Vector2(wide * 0.5, wide * 0.15)
	var ring := PackedVector2Array()
	for i: int in 33:
		var at := TAU * float(i) / 32.0
		ring.append(middle + Vector2(cos(at) * reach.x, sin(at) * reach.y))
	on.draw_polyline(ring, ink, maxf(wide * 0.12, 1.5), true)
