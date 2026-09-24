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
## The two halves of a score, GAME.md 3.2: the chips a lap is worth and the mult they are
## multiplied by. One color each, the same two everywhere either half is shown, so a glance says
## which of the two is moving.
const CHIPS := Color("#3FA9F5")
const MULT := Color("#F2564B")
const NEON_MAGENTA := Color("#FF4FA3")
const NEON_CYAN := Color("#35D0FF")

## Player colors by slot: red, blue, yellow, green, purple, orange, cyan, pink.
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

## The player colors again for each kind of color blindness the settings offer, GAME.md 8.5, in
## the same slots, each as near the hue of the one it stands in for as it can be. Chosen by
## simulating each kind (Machado 2009) and keeping all eight at least 28 apart in CIELAB under it
## and under normal vision alike, and clear of the felt: the palette above keeps blue and purple
## 7 apart for a player without red or green cones, which is the same color.
const VISION_COLORS: Dictionary[String, Array] = {
	"protanopia":
	[
		Color("#D9301B"),
		Color("#3A2BFF"),
		Color("#FFF040"),
		Color("#40F0D0"),
		Color("#B25ED9"),
		Color("#FFC266"),
		Color("#66D1FF"),
		Color("#D91E78"),
	],
	"deuteranopia":
	[
		Color("#D9261B"),
		Color("#6070E0"),
		Color("#B8F030"),
		Color("#60F090"),
		Color("#2020D0"),
		Color("#F2F2F2"),
		Color("#20C8F0"),
		Color("#D9607A"),
	],
	"tritanopia":
	[
		Color("#F03030"),
		Color("#8B5ED9"),
		Color("#E0F030"),
		Color("#30E040"),
		Color("#C830F0"),
		Color("#FFB020"),
		Color("#5E8BD9"),
		Color("#F030B0"),
	],
}

## Which of [constant VISION_COLORS] the karts wear here, or empty for the colors above. The
## player's setting, put here by [method Settings.apply]; each machine shows its own.
static var vision := ""


static func player_color(slot: int) -> Color:
	var colors: Array = VISION_COLORS.get(vision, PLAYER_COLORS)
	return colors[posmod(slot, colors.size())]
