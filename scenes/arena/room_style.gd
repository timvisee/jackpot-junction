class_name RoomStyle
extends RefCounted
## What makes one room look like no other, GAME.md 8.1c: a script a room names, [member
## RoomLook.style], that builds its walls, its boxes, its pits, the face of its Junction, its
## floor, the room round the table and the emblem the pause menu shows for it. Every hook answers
## whether it built the thing: one that answers no, as all of these do, leaves it to the room's
## kit as it always was, so a style says only what it changes.
##
## What a style does not decide is the same in every room, and is what makes them one game: the
## shapes the play is in (a wall is the block it was, a box the cube, a pad the disc), the House's
## rail round the arena, the Junction's neon ring, the House's layout on the floor in the room's
## inks, the paper crowd in the room's wardrobe, and the colors' jobs of 8.1a.
##
## A style is made once a room is built, with the room, its surfaces and a generator seeded off
## the room, so a room is furnished the same way every time.

var room: RoomLook
var surfaces: Surfaces
var rng := RandomNumberGenerator.new()


func _init(for_room: RoomLook, for_surfaces: Surfaces) -> void:
	room = for_room
	surfaces = for_surfaces
	rng.seed = hash(room.id) + 7


## An inner wall of [param size], the collider's box, built under [param holder] with its foot at
## -size.y / 2; [param index] counts the walls, for dressing every few. Whether it was built.
func wall(_holder: Node3D, _size: Vector3, _index: int) -> bool:
	return false


## The breakable box of [param size], built under [param holder] round its middle and inside its
## cube. Whether it was built.
func crate(_holder: Node3D, _size: Vector3) -> bool:
	return false


## What waits at the bottom of a pit of [param size] across, under [param into], below the floor.
## Whether it was built.
func pit(_into: Node3D, _size: Vector2) -> bool:
	return false


## The face of the cash-out pad out to [param radius], flat on the floor under [param into]. The
## neon ring round it is not the style's: every room has the same one. Whether it was built.
func junction(_into: Node3D, _radius: float) -> bool:
	return false


## Whatever stands on a Jackpot's tile of [param size], under [param into]. Whether it was built.
func jackpot(_into: Node3D, _size: Vector2) -> bool:
	return false


## Whatever lies over a turbo pad's cell at [param at], [param cell] across, under [param into].
## Whether it was built.
func turbo(_into: Node3D, _at: Vector3, _cell: float) -> bool:
	return false


## The material of the floor the karts drive on, or null for the room's felt or concrete.
func floor_top() -> StandardMaterial3D:
	return null


## The material of the table round the arena, where the crowd stands, or null for the room's own.
func surround() -> StandardMaterial3D:
	return null


## The room round the table, built through [param props] and its [member RoomProps.shell]: the
## walls of the room, what hangs on them and what lies about. Whether it was built; a style that
## builds none leaves the room the Workbench's.
func room_round(_props: RoomProps) -> bool:
	return false


## The inks the House's layout is printed in on this floor, GAME.md 8.1b, as [lines, words], or
## an empty array for the room's trim and marking.
func layout_inks() -> Array[Color]:
	return []


## The room's emblem, GAME.md 8.1c: one small thing from it, about a meter across and standing on
## its own origin, which the pause menu turns in its corner. Null for the House's chip.
func emblem() -> Node3D:
	return null
