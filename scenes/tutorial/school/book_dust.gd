class_name BookDust
extends Control
## The dust the driving school's theory book throws up as it shuts, GAME.md 9.4a: motes drifting out
## from its edges, growing and fading. See [SchoolTheory].

var motes: Array[Dictionary] = []
var age := 0.0


func _process(delta: float) -> void:
	age += delta
	if age >= SchoolTheory.DUST_FOR:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var share := age / SchoolTheory.DUST_FOR
	for mote: Dictionary in motes:
		var at: Vector2 = mote["from"] + (mote["way"] as Vector2) * (1.0 - pow(1.0 - share, 2.0))
		at.y -= share * share * 20.0
		var radius: float = mote["radius"] * (1.0 + share * 1.6)
		draw_circle(at, radius, Color(SchoolTheory.DUST, (1.0 - share) * 0.55))


## The dust off a book shut over [param closed], thrown the same way every time by
## [param from_seed]: off the fore-edge, the foot and the head, away from the book.
static func thrown_off(closed: Rect2, from_seed: int) -> BookDust:
	var rng := RandomNumberGenerator.new()
	rng.seed = from_seed
	var dust := BookDust.new()
	dust.name = "Dust"
	dust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i: int in SchoolTheory.MOTES:
		var mote := {}
		var along := rng.randf()
		var way: Vector2
		match i % 3:
			0:
				mote["from"] = Vector2(
					closed.position.x + rng.randf_range(-2.0, 4.0),
					closed.position.y + along * closed.size.y
				)
				way = Vector2(-1.0, rng.randf_range(-0.3, 0.3))
			1:
				mote["from"] = Vector2(
					closed.position.x + along * closed.size.x,
					closed.end.y + rng.randf_range(-4.0, 2.0)
				)
				way = Vector2(rng.randf_range(-0.3, 0.3), 1.0)
			_:
				mote["from"] = Vector2(
					closed.position.x + along * closed.size.x,
					closed.position.y + rng.randf_range(-2.0, 4.0)
				)
				way = Vector2(rng.randf_range(-0.3, 0.3), -1.0)
		mote["way"] = way.normalized() * SchoolTheory.DUST_SPEED * rng.randf_range(0.3, 1.0)
		mote["radius"] = rng.randf_range(2.0, 5.0)
		dust.motes.append(mote)
	return dust
