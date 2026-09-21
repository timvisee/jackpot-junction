class_name Surfaces
extends RefCounted
## What a room is made of, GAME.md 8.1. One of these per arena: it holds the room's colours and
## hands out the materials everything in it is built from, so a slab of felt and a crate are the
## same felt and the same paint wherever they are made.
##
## The textures are greyscale detail maps around white, multiplied by the room's own colour: one
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

## How many metres one tile of each texture covers. Set by what the thing is rather than by the
## texture: a table is boards a metre and a half wide, a yard is slabs two metres across, and the
## worn patches in a felt are about as wide as a kart is long.
const FELT_TILE := 3.0
const WOOD_TILE := 6.4
const PAINT_TILE := 1.6
const STONE_TILE := 6.0

var room: RoomLook

## Materials already built, by what they are and what colour: a room is a few hundred meshes
## sharing a dozen materials.
var _cache: Dictionary[String, StandardMaterial3D] = {}


func _init(for_room: RoomLook) -> void:
	room = for_room if for_room != null else RoomLook.fallback()


## The play floor: felt, or poured concrete in a room that has no felt in it.
func floor_top() -> StandardMaterial3D:
	if room.floor_stone:
		return _keep("floor", room.felt, _stone(room.felt, 0.86, true))
	var felt := _dressed(room.felt, FELT_ALBEDO, FELT_NORMAL, FELT_TILE, 0.3, true)
	felt.roughness = 0.94
	felt.metallic_specular = 0.15
	return _keep("floor", room.felt, felt)


## The table the arena stands on: wood, or more concrete.
func surround() -> StandardMaterial3D:
	if room.surround_stone:
		return _keep("surround", room.table, _stone(room.table, 0.82, true))
	var wood := _dressed(room.table, WOOD_ALBEDO, WOOD_NORMAL, WOOD_TILE, 0.45, true)
	wood.roughness = 0.55
	wood.metallic_specular = 0.4
	return _keep("surround", room.table, wood)


## Anything painted: walls, crates, the blocks a room is furnished with.
func painted(color: Color) -> StandardMaterial3D:
	if _cache.has(_key("paint", color)):
		return _cache[_key("paint", color)]
	var paint := _dressed(color, PAINT_ALBEDO, PAINT_NORMAL, PAINT_TILE, 0.25)
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
	var stone := _dressed(color, STONE_ALBEDO, STONE_NORMAL, STONE_TILE, 0.5, flat)
	stone.roughness = roughness
	stone.metallic_specular = 0.3
	return stone


func _keep(kind: String, color: Color, material: StandardMaterial3D) -> StandardMaterial3D:
	_cache[_key(kind, color)] = material
	return material


func _key(kind: String, color: Color) -> String:
	return "%s:%s" % [kind, color.to_html(false)]
