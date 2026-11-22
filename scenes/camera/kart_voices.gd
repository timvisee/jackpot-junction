class_name KartVoices
extends RefCounted
## Where [CameraRig] puts each kart's voice, GAME.md 8.4. With two or more karts driven here the
## ears sit between them, and each player would hear their own kart from halfway across the room.
## So every kart's voice is put where it would be if the ears were over whichever kart driven here
## is nearest it: each player hears their own at the level it is written for, and the others as
## they sound from where that player is.

## Whether the voices have been moved off their karts, so they are put back once there is one
## player here again.
var _moved := false


## Puts the voices of [param karts] for the ears at [param center], over [param here], the karts
## driven here.
func place(center: Vector3, here: Array[Node3D], karts: Array[Node3D]) -> void:
	var moved := here.size() > 1
	if not moved and not _moved:
		return
	_moved = moved
	for target: Node3D in karts:
		var kart := target as Kart
		if kart == null or kart.sound == null:
			continue
		kart.sound.top_level = moved
		if not moved:
			kart.sound.position = Vector3.ZERO
			continue
		var nearest := here[0]
		var gap := nearest.global_position.distance_squared_to(kart.global_position)
		for each: Node3D in here:
			var this_gap := each.global_position.distance_squared_to(kart.global_position)
			if this_gap < gap:
				nearest = each
				gap = this_gap
		var offset := kart.global_position - nearest.global_position
		kart.sound.global_position = Vector3(center.x, 0.0, center.z) + offset
