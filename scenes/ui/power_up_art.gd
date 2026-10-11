class_name PowerUpArt
extends RefCounted
## A picture for every power-up, GAME.md 8.3a, drawn from the same vocabulary as the joker
## pictures so the two sets read as one hand's work.
##
## Each is drawn in the item's own color, which the item carries, so the picture never names a
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


## Draws [param id]'s picture into [param box]. An id with no picture of its own gets a question
## mark's worth of nothing: a plain disc, which is what an unknown item is.
static func draw_into(on: CanvasItem, box: Rect2, id: StringName, ink: Color) -> void:
	var dim := IconShapes.behind(ink)
	match id:
		&"bomb":
			IconShapes.disc(on, box, 0.46, 0.62, 0.3, ink)
			IconShapes.line(on, box, 0.62, 0.36, 0.76, 0.18, ink)
			IconShapes.flame(on, box, 0.78, 0.22, 0.22, 20.0, dim)
		&"boost":
			for at: float in [0.28, 0.54]:
				IconShapes.tri(on, box, at, 0.5, 0.42, 90.0, dim)
			IconShapes.tri(on, box, 0.78, 0.5, 0.42, 90.0, ink)
		&"bullet_wipe":
			IconShapes.disc(on, box, 0.5, 0.5, 0.12, dim)
			IconShapes.ring(on, box, 0.5, 0.5, 0.34, ink)
			IconShapes.line(on, box, 0.26, 0.74, 0.74, 0.26, ink)
		&"coin_magnet":
			IconShapes.arc(on, box, 0.4, 0.6, 0.28, 180.0, 360.0, ink)
			IconShapes.line(on, box, 0.12, 0.6, 0.12, 0.86, ink)
			IconShapes.line(on, box, 0.68, 0.6, 0.68, 0.86, ink)
			IconShapes.disc(on, box, 0.78, 0.26, 0.16, dim)
		&"decoy_kart":
			IconShapes.bar(on, box, 0.14, 0.3, 0.42, 0.4, dim)
			IconShapes.bar(on, box, 0.44, 0.3, 0.42, 0.4, ink)
		&"oil_stain":
			IconShapes.bar(on, box, 0.12, 0.6, 0.76, 0.26, dim)
			IconShapes.disc(on, box, 0.3, 0.72, 0.16, dim)
			IconShapes.disc(on, box, 0.72, 0.72, 0.13, dim)
			IconShapes.flame(on, box, 0.5, 0.48, 0.34, 180.0, ink)
		&"ricochet_cannon":
			IconShapes.bar(on, box, 0.78, 0.1, 0.12, 0.8, dim)
			IconShapes.line(on, box, 0.12, 0.2, 0.74, 0.48, ink)
			IconShapes.line(on, box, 0.74, 0.48, 0.16, 0.82, ink)
		&"shield":
			IconShapes.shield(on, box, 0.5, 0.5, 0.36, ink)
		&"spread_cannon":
			IconShapes.bar(on, box, 0.42, 0.66, 0.16, 0.26, dim)
			IconShapes.tri(on, box, 0.24, 0.34, 0.28, -26.0, ink)
			IconShapes.tri(on, box, 0.5, 0.26, 0.28, 0.0, ink)
			IconShapes.tri(on, box, 0.76, 0.34, 0.28, 26.0, ink)
		&"swivel_cannon":
			IconShapes.arc(on, box, 0.5, 0.62, 0.34, 190.0, 350.0, dim)
			IconShapes.bar(on, box, 0.42, 0.24, 0.16, 0.44, ink)
			IconShapes.disc(on, box, 0.5, 0.68, 0.12, ink)
		&"turret":
			IconShapes.bar(on, box, 0.24, 0.6, 0.52, 0.26, dim)
			IconShapes.disc(on, box, 0.5, 0.48, 0.18, ink)
			IconShapes.bar(on, box, 0.44, 0.1, 0.12, 0.34, ink)
		_:
			IconShapes.ring(on, box, 0.5, 0.5, 0.32, ink)


## Every id this knows a picture for, so a test can hold the set to the item list.
static func known() -> Array[StringName]:
	var ids: Array[StringName] = [
		&"bomb",
		&"boost",
		&"bullet_wipe",
		&"coin_magnet",
		&"decoy_kart",
		&"oil_stain",
		&"ricochet_cannon",
		&"shield",
		&"spread_cannon",
		&"swivel_cannon",
		&"turret"
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
