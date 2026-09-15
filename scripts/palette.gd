class_name Palette
extends RefCounted
## Starting palette from GAME.md section 8.1.

const FELT := Color("#2F5D45")
const ASPHALT := Color("#3A3A40")
const MARKING_CREAM := Color("#E8D8A0")
const MARKING_YELLOW := Color("#E3B341")
const BLOCK := Color("#E6D2B5")
const BLOCK_EDGE := Color("#C9AE86")
const TABLE := Color("#8A5A3C")
const CHIP_GOLD := Color("#F2C14E")
const CHIP_WHITE := Color("#F7F3EA")
const CHIP_RED := Color("#C4453C")
const NEON_MAGENTA := Color("#FF4FA3")
const NEON_CYAN := Color("#35D0FF")

## Player colours by slot: red, blue, yellow, green, purple, orange, cyan, pink.
const PLAYER_COLORS: Array[Color] = [
	Color("#E23D3D"),
	Color("#3D6FE2"),
	Color("#F2D23D"),
	Color("#43C463"),
	Color("#9B4FE2"),
	Color("#F28C3D"),
	Color("#3DD9E2"),
	Color("#F26BB8"),
]


static func player_color(slot: int) -> Color:
	return PLAYER_COLORS[posmod(slot, PLAYER_COLORS.size())]
