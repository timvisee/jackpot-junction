class_name QualityPresets
extends RefCounted
## The graphics presets of the Video page, GAME.md 8.5: Low, Medium, High and Ultra, each the six
## settings under it on the page set at once, shadows, texture detail, ambient occlusion, bloom,
## MSAA and screen smoothing. Bloom's and ambient occlusion's levels change how strong each is
## rather than what it costs the card, so a preset has each at the room's own strength or off. High
## is where a desktop starts, and a phone's own start reads as Low.

## Each preset's name, shown through tr().
const NAMES: Array[String] = ["Low", "Medium", "High", "Ultra"]
## What a box of them says while the six are set as none of them, shown through tr().
const CUSTOM := "Custom"
## Each preset's six settings, by their names on [Settings].
const SETS: Array[Dictionary] = [
	{
		&"shadows": Settings.SHADOWS_LOW,
		&"texture_detail": Settings.TEXTURES_LOW,
		&"occlusion": 0.0,
		&"bloom": 0.0,
		&"msaa": 0,
		&"screen_smoothing": Settings.SMOOTH_FXAA,
	},
	{
		&"shadows": Settings.SHADOWS_LOW,
		&"texture_detail": Settings.TEXTURES_AUTO,
		&"occlusion": 0.0,
		&"bloom": 1.0,
		&"msaa": 0,
		&"screen_smoothing": Settings.SMOOTH_SMAA,
	},
	{
		&"shadows": Settings.SHADOWS_HIGH,
		&"texture_detail": Settings.TEXTURES_AUTO,
		&"occlusion": 1.0,
		&"bloom": 1.0,
		&"msaa": 2,
		&"screen_smoothing": Settings.SMOOTH_OFF,
	},
	{
		&"shadows": Settings.SHADOWS_HIGH,
		&"texture_detail": Settings.TEXTURES_ULTRA,
		&"occlusion": 1.0,
		&"bloom": 1.0,
		&"msaa": 4,
		&"screen_smoothing": Settings.SMOOTH_OFF,
	},
]


## How many of them a renderer offers, the first so many: Ultra's texture detail only the desktop's
## renderer has, [param full_renderer].
static func offered(full_renderer: bool) -> int:
	return SETS.size() if full_renderer else SETS.size() - 1


## Which of them [param settings] are set as, or -1 for none. Texture detail is compared as it is
## drawn, Auto as [param auto_detail], what it comes out as on this screen, so a phone's own start,
## Auto at the print's own size, reads as Low.
static func of(settings: Settings, auto_detail: String, full_renderer: bool) -> int:
	for i: int in offered(full_renderer):
		var same := true
		for key: StringName in SETS[i]:
			var want: Variant = SETS[i][key]
			var have: Variant = settings.get(key)
			if key == &"texture_detail":
				want = _drawn(want, auto_detail)
				have = _drawn(have, auto_detail)
			if have != want:
				same = false
				break
		if same:
			return i
	return -1


## [param settings] set as preset [param index].
static func use(settings: Settings, index: int) -> void:
	for key: StringName in SETS[index]:
		settings.set(key, SETS[index][key])


static func _drawn(detail: String, auto_detail: String) -> String:
	return auto_detail if detail == Settings.TEXTURES_AUTO else detail
