class_name RoomLook
extends Resource
## How one room looks, GAME.md 8.1: the light in it, what its surfaces are made of, and how the
## crowd round it is dressed. Every map names one, so a map is a place rather than a floor plan
## with the same lamps over it.
##
## Everything here is read at build time and nothing here decides anything about play: two rooms
## differ in what a player sees and in nothing else, which is why the room can be data.

## How the crowd in this room is dressed, GAME.md 8.1: a carnival of color, a dark band with a
## rim of light on it, or a working crowd in a few muted colors. Named Dress rather than Crowd
## because [Crowd] is the band of people itself.
enum Dress { CARNIVAL, SILHOUETTE, WORKWEAR }

@export var id: StringName = &"room"
@export var display_name := "Room"

@export_group("Light")
## The key: where the room's own light comes from, and how hard.
@export var key_color := Color(1.0, 0.94, 0.85)
@export var key_energy := 2.2
@export var key_angle := Vector3(-52.0, 38.0, 0.0)
## The fill from the other side, which keeps a shadow from being a hole.
@export var fill_color := Color(0.55, 0.68, 1.0)
@export var fill_energy := 0.55
@export var fill_angle := Vector3(-26.0, -140.0, 0.0)
## The lamp over the table, which is what makes a room a room rather than a field: a sun lights
## everything it can see, and a lamp lights what is under it and lets the rest fall away. Energy
## 0 for a room lit by daylight alone.
@export var lamp_color := Color(1.0, 0.91, 0.77)
@export var lamp_energy := 0.0
@export var lamp_height := 26.0
@export var lamp_angle := 44.0
@export var lamp_fade := 0.5
@export var lamp_reach := 70.0
@export var lamp_shadow := false
## How dark the shadows go and how soft their edges are. A toy on a table is lit by a room as
## much as by a lamp, so a shadow here is a dark side rather than a hole cut in the floor.
@export_range(0.0, 1.0) var shadow_depth := 0.62
@export var shadow_softness := 2.2
@export var ambient_color := Color(0.42, 0.40, 0.44)
@export var ambient_energy := 0.35
## What is beyond everything, and the haze between here and there.
@export var background := Color(0.05, 0.035, 0.03)
@export var fog_color := Color(0.09, 0.06, 0.05)
@export var fog_density := 0.012

@export_group("Film")
## How far past whatever the camera is looking at the room starts going soft, in meters, and how
## soft it goes. A table reads as a model when what is behind it is out of focus, and the margin
## follows the camera so the table stays sharp however close the rig comes in, GAME.md 8.2.
@export var focus_from := 12.0
@export var focus_blur := 0.14
@export var glow := 0.9
@export var occlusion := 1.6
@export var white := 6.0
@export var exposure := 1.0
@export var saturation := 1.08
@export var contrast := 1.06

@export_group("Surfaces")
@export var felt := Color("#2F5D45")
@export var felt_edge := Color("#24402F")
@export var table := Color("#8A5A3C")
@export var wall := Color("#E6D2B5")
@export var wall_edge := Color("#C9AE86")
@export var lane := Color("#3A3A40")
@export var marking := Color("#E8D8A0")
## The metal in the room: pad trim, tank fittings, the gantry.
@export var trim := Color("#F2C14E")
## How much the surface texture shows, 0 for none.
@export var grain := 1.0
## Whether the floor and the surround are concrete rather than felt and wood. A yard is not a
## card table, and the same meshes read as either depending on what they are made of.
@export var floor_stone := false
@export var surround_stone := false
## How hard the neon in this room is driven. A dark room wants its signs to bloom; a bright one
## wants them to read as paint that happens to glow.
@export var neon := 1.0

@export_group("Crowd")
@export var crowd_dress: Dress = Dress.CARNIVAL
@export var crowd_colors: PackedColorArray = PackedColorArray()
@export var crowd_rim := Color(1.0, 0.8, 0.5)
## How brightly the crowd is lit compared with the table.
@export var crowd_light := 1.0
@export var stand := Color("#E6D2B5")


## The room a map falls back to when it names none, so an arena always has one.
static func fallback() -> RoomLook:
	return load("res://data/rooms/workbench.tres")
