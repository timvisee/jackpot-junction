class_name Surfaces
extends RefCounted
## What a room is made of, GAME.md 8.1. One of these per arena: it holds the room's colors and
## hands out the materials everything in it is built from, so a slab of felt and a crate are the
## same felt and the same paint wherever they are made.
##
## The textures are grayscale detail maps around white, multiplied by the room's own color: one
## felt serves a green table and a slate one, and a room is a palette rather than a set of
## pictures. They are mapped in world space rather than by UV, because the meshes here are built
## in code and a slab the size of a table has no unwrap worth the name -- and because two crates
## side by side should not show the same knot in the same place.

const FELT_ALBEDO := preload("res://assets/textures/felt_albedo.png")
const FELT_NORMAL := preload("res://assets/textures/felt_normal.png")
const WOOD_ALBEDO := preload("res://assets/textures/wood_albedo.png")
const WOOD_NORMAL := preload("res://assets/textures/wood_normal.png")
const PAINT_ALBEDO := preload("res://assets/textures/paint_albedo.png")
const PAINT_NORMAL := preload("res://assets/textures/paint_normal.png")
const STONE_ALBEDO := preload("res://assets/textures/stone_albedo.png")
const STONE_NORMAL := preload("res://assets/textures/stone_normal.png")
## The pictures a card room is made of, GAME.md 8.1. Pictures rather than materials: they have a
## right way up and are mapped off a mesh's own UVs. Four suits, because a hand of four identical
## cards is not a hand.
const CARD_FACES: Array[Texture2D] = [
	preload("res://assets/textures/card_hearts.png"),
	preload("res://assets/textures/card_diamonds.png"),
	preload("res://assets/textures/card_spades.png"),
	preload("res://assets/textures/card_clubs.png"),
]
## The rooms' cards face down in each of [constant CardBack.STYLES]: the house's the deck's red
## lattice, which reads as a deck of cards from over the table where the house's dark back reads as
## a dark block, and each back won in the loyalty program the picture of it written out by
## scenes/dev/card_back_export.gd to the file here, none for the house's.
const CARD_BACK_FILES: Array[String] = [
	"",
	"res://assets/textures/card_back_gilt.png",
	"res://assets/textures/card_back_hand_drawn.png",
	"res://assets/textures/card_back_doodled.png",
]
const CARD_BACKS: Array[Texture2D] = [
	preload("res://assets/textures/card_back.png"),
	preload("res://assets/textures/card_back_gilt.png"),
	preload("res://assets/textures/card_back_hand_drawn.png"),
	preload("res://assets/textures/card_back_doodled.png"),
]
## The notches round a chip, grayscale so that a chip takes the color of the stack it is in.
const CHIP_FACE := preload("res://assets/textures/chip_face.png")

## How many meters one tile of each texture covers. Set by what the thing is rather than by the
## texture: a table is boards a meter and a half wide, a yard is slabs two meters across, and the
## worn patches in a felt are about as wide as a kart is long.
const FELT_TILE := 3.0
const WOOD_TILE := 6.4
const PAINT_TILE := 1.6
const STONE_TILE := 6.0

var room: RoomLook

## Materials already built, by what they are and what color: a room is a few hundred meshes
## sharing a dozen materials.
var _cache: Dictionary[String, StandardMaterial3D] = {}


func _init(for_room: RoomLook) -> void:
	room = for_room if for_room != null else RoomLook.fallback()


## The play floor: felt, or poured concrete in a room that has no felt in it.
func floor_top() -> StandardMaterial3D:
	if room.floor_stone:
		return _keep("floor", room.felt, _stone(room.felt, 0.86, true))
	var felt := _dressed(room.felt, FELT_ALBEDO, FELT_NORMAL, FELT_TILE, 0.12, true)
	felt.roughness = 0.94
	felt.metallic_specular = 0.15
	return _keep("floor", room.felt, felt)


## The table the arena stands on: wood, or more concrete.
func surround() -> StandardMaterial3D:
	if room.surround_stone:
		return _keep("surround", room.table, _stone(room.table, 0.82, true))
	var wood := _dressed(room.table, WOOD_ALBEDO, WOOD_NORMAL, WOOD_TILE, 0.25, true)
	wood.roughness = 0.55
	wood.metallic_specular = 0.4
	return _keep("surround", room.table, wood)


## Anything painted: walls, crates, the blocks a room is furnished with.
func painted(color: Color) -> StandardMaterial3D:
	if _cache.has(_key("paint", color)):
		return _cache[_key("paint", color)]
	var paint := _dressed(color, PAINT_ALBEDO, PAINT_NORMAL, PAINT_TILE, 0.12)
	paint.roughness = 0.72
	paint.metallic_specular = 0.35
	return _keep("paint", color, paint)


## Paint on the floor: pad faces, lines, the markings of 6.3. Flat, because a marking is paint
## rather than a thing.
func marking(color: Color) -> StandardMaterial3D:
	if _cache.has(_key("mark", color)):
		return _cache[_key("mark", color)]
	var flat := StandardMaterial3D.new()
	flat.albedo_color = color
	flat.roughness = 0.85
	flat.metallic_specular = 0.2
	return _keep("mark", color, flat)


## Metal: the trim on the pads, the fittings on the tanks, the posts the lights hang from.
func metal(color: Color) -> StandardMaterial3D:
	if _cache.has(_key("metal", color)):
		return _cache[_key("metal", color)]
	var steel := StandardMaterial3D.new()
	steel.albedo_color = color
	steel.metallic = 0.85
	steel.metallic_specular = 0.6
	steel.roughness = 0.32
	return _keep("metal", color, steel)


## The back the cards of the rooms wear face down, GAME.md 8.9: the profile playing's, see
## [method CardBack.worn], as everything this machine draws face down does. Asked of [CardBack]
## as the room is built rather than named here: naming it would have this script, which the
## power-ups' build on, wait on the loyalty program's, which wait on the power-ups' tables, and
## none of them would compile.
static func card_back() -> Texture2D:
	var worn: int = load("res://scenes/ui/card_back.gd").call(&"worn")
	return CARD_BACKS[clampi(worn, 0, CARD_BACKS.size() - 1)]


## Something that carries its own picture: the face of a card, the notches round a chip, the pips
## on a die. Mapped off the mesh's own UVs rather than triplanar, because a picture has a right
## way up and a wrong one, and tinted, so that one picture of a chip serves a rack of them.
func printed(image: Texture2D, tint := Color.WHITE) -> StandardMaterial3D:
	var key := "print:%s:%s" % [image.resource_path, tint.to_html()]
	if _cache.has(key):
		return _cache[key]
	var card := StandardMaterial3D.new()
	card.albedo_texture = image
	card.albedo_color = tint
	card.roughness = 0.78
	card.metallic_specular = 0.3
	_cache[key] = card
	return card


## Neon: lit from inside, so it blooms in a dark room and still reads in a bright one.
func neon(color: Color, strength := 1.0) -> StandardMaterial3D:
	var key := _key("neon%.2f" % strength, color)
	if _cache.has(key):
		return _cache[key]
	var lit := StandardMaterial3D.new()
	lit.albedo_color = color
	lit.emission_enabled = true
	lit.emission = color
	lit.emission_energy_multiplier = strength * room.neon
	lit.roughness = 0.4
	_cache[key] = lit
	return lit


## A material dressed in one of the detail maps.
##
## [param flat] surfaces carry their own world-space UVs, see [method Arena._quad], and are
## mapped straight off them: one texture read rather than the three a triplanar costs, on the
## two meshes that cover most of the screen. Everything else is triplanar, which is what lets a
## crate and a wall of any size wear the same paint at the same scale.
func _dressed(
	color: Color, albedo: Texture2D, normal: Texture2D, tile: float, relief: float, flat := false
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if room.grain <= 0.0:
		return material
	material.albedo_texture = albedo
	if relief > 0.0:
		material.normal_enabled = true
		material.normal_texture = normal
		material.normal_scale = relief * room.grain
	material.uv1_triplanar = not flat
	material.uv1_world_triplanar = not flat
	material.uv1_scale = Vector3.ONE / tile
	return material


func _stone(color: Color, roughness: float, flat := false) -> StandardMaterial3D:
	var stone := _dressed(color, STONE_ALBEDO, STONE_NORMAL, STONE_TILE, 0.28, flat)
	stone.roughness = roughness
	stone.metallic_specular = 0.3
	return stone


func _keep(kind: String, color: Color, material: StandardMaterial3D) -> StandardMaterial3D:
	_cache[_key(kind, color)] = material
	return material


func _key(kind: String, color: Color) -> String:
	return "%s:%s" % [kind, color.to_html(false)]
