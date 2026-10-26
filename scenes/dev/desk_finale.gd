extends Node3D
## Dev harness to render the oversight-desk ending on its own, a still at a time through
## tools/screenshots of res://scenes/dev/desk_finale.tscn; the real ending mounts [OversightDesk] in
## the match through [LastLines]. It dresses a representative player so the statue has paint and a
## plate to wear, then plays the film, with no match to hide and no last line of its own.


func _ready() -> void:
	var settings := Game.settings
	settings.set_seat_name(0, "Tail Light Tim")
	settings.set_seat_color(0, 1)
	settings.set_seat_style(0, PackedInt32Array([5, 2, 3, 2, 0, 0, 0]))
	var desk := OversightDesk.new()
	add_child(desk)
	desk.play()
