class_name VideoTab
extends ScrollContainer
## The Video page of the settings, GAME.md 8.5, in groups under headings: what it is played on and
## the window, the camera and the table down the left; how often and how sharp a frame is drawn and
## what a room pays for on the card down the right; one under the other on a screen too narrow for
## both, see [SettingsColumns]. Every change takes effect at once; the settings screen saves them on
## Back. It scrolls, as the Accessibility page does, for a phone's short screen under a big UI
## scale.
##
## What a platform has no use for is not there, GAME.md 8.5: a phone or a tablet plays full screen
## and in step with its own screen whatever it is told, so it has no Fullscreen and no V-sync, and
## a renderer without FSR 2 is not offered it.

## The window sizes the Window size box offers in windowed mode, GAME.md 8.5: the common 16:9 and
## the Steam Deck's 16:10, biggest last. Fullscreen fills the screen whatever is picked.
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1280, 800),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]
## The camera distances the Camera distance box offers besides Auto, GAME.md 8.5, nearest first: a
## share of the fit, see [member Settings.camera_distance], Auto suiting the screen itself.
const CAMERA_STEPS: Array[float] = [0.55, 0.7, 0.85, 1.0, 1.25]
## The bloom amounts the Bloom box offers, GAME.md 8.5, none first: a share of the room's own glow,
## see [member Settings.bloom].
const BLOOM_LEVELS: Array[float] = [0.0, 0.5, 1.0, 1.5]
const BLOOM_NAMES: Array[String] = ["Off", "Subtle", "Normal", "Intense"]
## The ambient occlusion amounts the box offers, none first, a share of the room's own; off on a
## phone by default, see [member Settings.occlusion].
const OCCLUSION_LEVELS: Array[float] = [0.0, 0.6, 1.0]
const OCCLUSION_NAMES: Array[String] = ["Off", "Low", "High"]
## The upscalers the Upscaler box offers, see [constant Settings.UPSCALERS], by name.
const UPSCALER_NAMES: Array[String] = ["Bilinear", "FSR 1", "FSR 2"]
## The Texture detail box, GAME.md 8.5, and what it says to the mouse and a screen reader.
const TEXTURES := "Texture detail"
const TEXTURES_TIP := (
	"How finely the floor's print is drawn. Auto suits your screen, Low saves video memory, High"
	+ " is sharper up close and Ultra sharpest, for the most memory. It changes at once."
)
## The Screen type and Camera follows boxes, GAME.md 8.5, and what they say to the mouse and a
## screen reader; and the names the camera's own choices go by after Auto.
const SCREEN := "Screen type"
const SCREEN_TIP := (
	"What you play on. A TV across the room or a handheld brings the camera in closer and keeps"
	+ " only your own kart in the picture on Auto; picking one also sets the UI scale it suits."
)
const FOLLOWS := "Camera follows"
const FOLLOWS_TIP := (
	"Who the camera keeps in the picture: every kart, your kart and the rivals near it, or only"
	+ " your kart, rivals off the screen pointed at from its edge. Auto suits your screen."
)
const FOLLOW_NAMES: Array[String] = ["Everyone", "Nearby rivals", "My kart"]
## The fixed camera's switch, the same on this page and in Accessibility.
const FIXED := "Fixed camera"
const DISTANCE_NAMES: Array[String] = ["Closest", "Close", "Medium", "Far", "Farthest"]

## The page's groups, GAME.md 8.5, by their headings: what is seen and how it is played on the left,
## what it costs the card on the right.
const DISPLAY := "Display"
const CAMERA := "Camera"
const TABLE := "Table"
const PERFORMANCE := "Performance"
const GRAPHICS := "Graphics"

var _settings: Settings
## The page's groups, and the one rows go into as the page is built.
var _groups: SettingsColumns
var _column: VBoxContainer
## The boxes whose Auto says what it comes to on this screen, and the UI scale box, which picking a
## screen moves.
var _distance_box: OptionButton
var _follows_box: OptionButton
var _ui_box: OptionButton
## Whether this is a phone or a tablet, and whether the renderer is the desktop's, for the tests to
## build the page as another platform would.
var _handheld := false
var _full_renderer := true


static func make(
	settings: Settings,
	handheld := OS.has_feature("mobile"),
	full_renderer := Settings.full_renderer()
) -> VideoTab:
	var tab := VideoTab.new()
	tab.name = "Video"
	tab._settings = settings
	tab._handheld = handheld
	tab._full_renderer = full_renderer
	return tab


## The upscalers this renderer can offer, in the order the box lists them.
func upscalers() -> Array[String]:
	var offered: Array[String] = Settings.UPSCALERS.duplicate()
	if not _full_renderer:
		offered.erase(Settings.UPSCALE_FSR2)
	return offered


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_groups = SettingsColumns.new()
	_groups.name = "Groups"
	_groups.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_groups)
	_add_display()
	_add_camera()
	_add_table()
	_groups.split = _groups.get_child_count()
	_add_performance()
	_add_graphics()
	_say_autos()


## What it is played on, the window, and how big the menus and how bright the room are drawn.
func _add_display() -> void:
	_group(DISPLAY)
	_add_screen()
	if not _handheld:
		_add_window()
	# Picked from a list rather than slid: a slider would grow and shrink the screen it is on under
	# the pointer dragging it, GAME.md 8.5.
	var sizes: Array = []
	for size: float in Settings.UI_SCALES:
		sizes.append("%d%%" % roundi(size * 100.0))
	_ui_box = MenuTheme.option(sizes, ui_scale_index(_settings.ui_scale))
	_ui_box.item_selected.connect(
		func(index: int) -> void:
			_settings.ui_scale = Settings.UI_SCALES[index]
			_apply()
			_say_autos()
	)
	_add("UI scale", _ui_box)
	# Over the room's own exposure, relit at once, since the room is standing.
	var bright := func(v: float) -> void:
		_settings.brightness = v
		ArenaEnvironment.relight(get_tree())
	_add("Brightness", share_slider(0.5, 2.0, _settings.brightness, bright))


## How far the camera sits from the karts, whom it keeps in the picture, and whether it moves at
## all, GAME.md 8.2.
func _add_camera() -> void:
	_group(CAMERA)
	# Picked from a list, not slid, so the frame does not pump in and out under the pointer dragging
	# it; Auto comes in closer on a small or a high-DPI screen, where the karts are hardest to see.
	var at := 0
	if _settings.camera_distance > 0.0:
		at = maxi(CAMERA_STEPS.find(_settings.camera_distance), 0) + 1
	_distance_box = MenuTheme.option((["Auto"] as Array) + DISTANCE_NAMES, at)
	_distance_box.item_selected.connect(
		func(index: int) -> void:
			_settings.camera_distance = 0.0 if index == 0 else CAMERA_STEPS[index - 1]
	)
	_add("Camera distance", _distance_box)
	var follows := ViewChoices.FOLLOWS.find(_settings.camera_follows)
	_follows_box = MenuTheme.option((["Auto"] as Array) + FOLLOW_NAMES, maxi(follows, 0))
	_follows_box.tooltip_text = FOLLOWS_TIP
	ScreenReader.name(_follows_box, FOLLOWS, FOLLOWS_TIP)
	_follows_box.item_selected.connect(
		func(index: int) -> void: _settings.camera_follows = ViewChoices.FOLLOWS[index]
	)
	_add(FOLLOWS, _follows_box)
	_add(FIXED, fixed_camera_switch(_settings))


## How the room is drawn and what lies about the table besides the match, GAME.md 8.1b and 4.3.
func _add_table() -> void:
	_group(TABLE)
	# How the room is drawn, GAME.md 8.1b: a pass over the frame, the toon light, or both.
	var looks := MenuTheme.option(
		RenderLook.names(), maxi(RenderLook.ids().find(_settings.look), 0)
	)
	looks.item_selected.connect(
		func(index: int) -> void:
			_settings.look = RenderLook.ids()[index]
			_apply()
	)
	_add("Look", looks)
	# The bar at the foot of the screen that steps through the looks, to play with.
	var bar := MenuTheme.toggle(_settings.show_looks)
	bar.toggled.connect(func(on: bool) -> void: _settings.show_looks = on)
	_add("Looks bar", bar)
	var marks := MenuTheme.option(Settings.MARKS_NAMES, _settings.tire_marks)
	marks.item_selected.connect(func(index: int) -> void: _settings.tire_marks = index)
	_add("Tire marks", marks)
	_add("Crowd", crowd_box(_settings))


## How often and how sharp a frame is drawn, and the count of them.
func _add_performance() -> void:
	_group(PERFORMANCE)
	if not _handheld:
		var vsync := MenuTheme.toggle(_settings.vsync)
		vsync.toggled.connect(
			func(on: bool) -> void:
				_settings.vsync = on
				_apply()
		)
		_add("V-sync", vsync)
	var limits: Array = []
	for limit: int in Settings.FRAME_LIMITS:
		limits.append("Unlimited" if limit == 0 else str(limit))
	var limit := MenuTheme.option(
		limits, maxi(Settings.FRAME_LIMITS.find(_settings.frame_limit), 0)
	)
	limit.item_selected.connect(
		func(index: int) -> void:
			_settings.frame_limit = Settings.FRAME_LIMITS[index]
			_apply()
	)
	_add("Frame rate limit", limit)
	var scale := func(v: float) -> void:
		_settings.render_scale = v
		_apply()
	_add("Render scale", share_slider(0.5, 1.0, _settings.render_scale, scale))
	var offered := upscalers()
	var names: Array = []
	for each: String in offered:
		names.append(UPSCALER_NAMES[Settings.UPSCALERS.find(each)])
	# FSR 2 kept from another renderer is drawn as FSR 1 here, see [method Settings.scaling_mode].
	var shown := _settings.upscaler
	if not shown in offered:
		shown = Settings.UPSCALE_FSR
	var upscaling := MenuTheme.option(names, maxi(offered.find(shown), 0))
	upscaling.item_selected.connect(
		func(index: int) -> void:
			_settings.upscaler = offered[index]
			_apply()
	)
	_add("Upscaler", upscaling)
	var counter := MenuTheme.toggle(_settings.show_fps)
	counter.toggled.connect(func(on: bool) -> void: _settings.show_fps = on)
	_add("Show FPS", counter)


## What a room pays for on the card, GAME.md 8.5, each the room's own strength the player keeps a
## share of; relit at once, since the room is standing.
func _add_graphics() -> void:
	_group(GRAPHICS)
	var shadows := MenuTheme.option(
		["Off", "Low", "High"], maxi(Settings.SHADOW_LEVELS.find(_settings.shadows), 0)
	)
	shadows.item_selected.connect(
		func(index: int) -> void:
			_settings.shadows = Settings.SHADOW_LEVELS[index]
			_apply()
			ArenaEnvironment.relight(get_tree())
	)
	_add("Shadows", shadows)
	_add(TEXTURES, texture_box(_settings, _full_renderer))
	var ao := MenuTheme.option(OCCLUSION_NAMES, maxi(OCCLUSION_LEVELS.find(_settings.occlusion), 0))
	ao.item_selected.connect(
		func(index: int) -> void:
			_settings.occlusion = OCCLUSION_LEVELS[index]
			ArenaEnvironment.relight(get_tree())
	)
	_add("Ambient occlusion", ao)
	var bloom := MenuTheme.option(BLOOM_NAMES, maxi(BLOOM_LEVELS.find(_settings.bloom), 0))
	bloom.item_selected.connect(
		func(index: int) -> void:
			_settings.bloom = BLOOM_LEVELS[index]
			ArenaEnvironment.relight(get_tree())
	)
	_add("Bloom", bloom)
	var samples := MenuTheme.option(
		["Off", "2x", "4x", "8x"], maxi(Settings.MSAA_SAMPLES.find(_settings.msaa), 0)
	)
	samples.item_selected.connect(
		func(index: int) -> void:
			_settings.msaa = Settings.MSAA_SAMPLES[index]
			_apply()
	)
	_add("MSAA", samples)
	var smoothing := MenuTheme.option(
		["Off", "FXAA", "SMAA"], maxi(Settings.SMOOTHINGS.find(_settings.screen_smoothing), 0)
	)
	smoothing.item_selected.connect(
		func(index: int) -> void:
			_settings.screen_smoothing = Settings.SMOOTHINGS[index]
			_apply()
	)
	_add("Screen smoothing", smoothing)


## Full, Half or Off for the crowd, GAME.md 8.5: one setting, offered here and in Accessibility, so
## the box reads the setting again whenever its page comes up and shows what the other page set.
## The house stands up again at a new size a moment later, see [Crowd].
static func crowd_box(settings: Settings) -> OptionButton:
	var house := MenuTheme.option(
		Settings.CROWD_NAMES, maxi(Settings.CROWD_SIZES.find(settings.crowd_size), 0)
	)
	house.item_selected.connect(
		func(index: int) -> void: settings.crowd_size = Settings.CROWD_SIZES[index]
	)
	house.visibility_changed.connect(
		func() -> void:
			if house.is_visible_in_tree():
				house.select(maxi(Settings.CROWD_SIZES.find(settings.crowd_size), 0))
	)
	return house


## A slider from [param low] to [param high] in steps of 5%, at [param value], with how much it is
## set to written beside it, "80%", as the Intense music slider has, see [SwellSlider]: a share of
## the screen's size or of the room's own exposure says nothing from where its knob is alone.
## [param changed] is called with each new value.
static func share_slider(low: float, high: float, value: float, changed: Callable) -> HBoxContainer:
	var both := HBoxContainer.new()
	both.add_theme_constant_override("separation", 12)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(SwellSlider.WIDTH, 0.0)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	both.add_child(slider)
	var said := Label.new()
	said.name = "Value"
	said.custom_minimum_size = Vector2(72.0, 0.0)
	Type.text(said, Type.BODY, Color(0.86, 0.86, 0.9))
	said.text = "%d%%" % roundi(value * 100.0)
	both.add_child(said)
	slider.value_changed.connect(
		func(v: float) -> void:
			said.text = "%d%%" % roundi(v * 100.0)
			changed.call(v)
	)
	return both


## The fixed camera on or off, GAME.md 8.2: one setting, offered under Camera here and in
## Accessibility, so the switch reads the setting again whenever its page comes up, as the crowd's
## box does.
static func fixed_camera_switch(settings: Settings) -> CheckButton:
	var still := MenuTheme.toggle(settings.fixed_camera)
	still.toggled.connect(func(on: bool) -> void: settings.fixed_camera = on)
	still.visibility_changed.connect(
		func() -> void:
			if still.is_visible_in_tree():
				still.set_pressed_no_signal(settings.fixed_camera)
	)
	return still


## Auto, Low, High or Ultra for how finely the prints a table wears are drawn, GAME.md 8.1b: the
## floor's drawn again at once at its new size, a match on behind the page or not, see
## [ScreenPrint]. Ultra only where the renderer is the desktop's, [param full_renderer]: kept from
## a desktop's settings on another, it shows as the High it is drawn at there.
static func texture_box(
	settings: Settings, full_renderer := Settings.full_renderer()
) -> OptionButton:
	var offered: Array[String] = Settings.TEXTURE_DETAILS.duplicate()
	if not full_renderer:
		offered.erase(Settings.TEXTURES_ULTRA)
	var names: Array = []
	for each: String in offered:
		var label := Settings.TEXTURE_NAMES[Settings.TEXTURE_DETAILS.find(each)]
		# Auto says in brackets which of Low or High it comes out as on this screen, GAME.md 8.5.
		if each == Settings.TEXTURES_AUTO:
			var mode := LayoutPrint.auto_detail(full_renderer)
			label = "%s (%s)" % [label, Settings.TEXTURE_NAMES[Settings.TEXTURE_DETAILS.find(mode)]]
		names.append(label)
	var shown := settings.texture_detail
	if not shown in offered:
		shown = Settings.TEXTURES_HIGH
	var detail := MenuTheme.option(names, maxi(offered.find(shown), 0))
	detail.name = "TextureDetail"
	detail.tooltip_text = TEXTURES_TIP
	ScreenReader.name(detail, TEXTURES, TEXTURES_TIP)
	detail.item_selected.connect(
		func(index: int) -> void:
			settings.texture_detail = offered[index]
			if detail.is_inside_tree():
				ScreenPrint.redraw(detail.get_tree())
	)
	return detail


## The window, which a desktop has and a phone does not: full screen, or a window of a size.
func _add_window() -> void:
	var fullscreen := MenuTheme.toggle(_settings.fullscreen)
	fullscreen.toggled.connect(
		func(on: bool) -> void:
			_settings.fullscreen = on
			_apply()
	)
	_add("Fullscreen", fullscreen)
	var sizes: Array[String] = []
	for size: Vector2i in RESOLUTIONS:
		sizes.append("%d × %d" % [size.x, size.y])
	var window := MenuTheme.option(sizes, maxi(RESOLUTIONS.find(_settings.window_size), 0))
	window.item_selected.connect(
		func(index: int) -> void:
			_settings.window_size = RESOLUTIONS[index]
			_apply()
	)
	_add("Window size", window)


## What the game is played on, GAME.md 8.5. Picking one puts the UI at the size it suits, which the
## UI scale box then shows, and Auto's distance and framing come out as they suit it.
func _add_screen() -> void:
	var at := maxi(ViewChoices.SCREENS.find(_settings.screen), 0)
	var screen := MenuTheme.option(ViewChoices.SCREEN_NAMES, at)
	screen.tooltip_text = SCREEN_TIP
	ScreenReader.name(screen, SCREEN, SCREEN_TIP)
	screen.item_selected.connect(
		func(index: int) -> void:
			_settings.screen = ViewChoices.SCREENS[index]
			_settings.ui_scale = ViewChoices.ui_scale_of(_settings.screen)
			if _ui_box != null:
				_ui_box.select(ui_scale_index(_settings.ui_scale))
			_apply()
			_say_autos()
	)
	_add(SCREEN, screen)


## Auto in the Camera distance and Camera follows boxes says in brackets what it comes to on this
## screen, GAME.md 8.5: the nearest of the distances to the share of the fit Auto works out, see
## [method ViewChoices.auto_distance], and whom it follows, see [method ViewChoices.follows].
func _say_autos() -> void:
	var screen := ViewChoices.screen_now()
	var auto := ViewChoices.auto_distance(screen)
	var near := 0
	for j: int in CAMERA_STEPS.size():
		if absf(CAMERA_STEPS[j] - auto) < absf(CAMERA_STEPS[near] - auto):
			near = j
	if _distance_box != null:
		_distance_box.set_item_text(0, "Auto (%s)" % DISTANCE_NAMES[near])
	if _follows_box != null:
		var way := ViewChoices.FOLLOWS.find(ViewChoices.follows_auto(screen)) - 1
		_follows_box.set_item_text(0, "Auto (%s)" % FOLLOW_NAMES[way])


## The entry of [constant Settings.UI_SCALES] nearest [param size].
static func ui_scale_index(size: float) -> int:
	var best := 0
	for i: int in Settings.UI_SCALES.size():
		if absf(Settings.UI_SCALES[i] - size) < absf(Settings.UI_SCALES[best] - size):
			best = i
	return best


## A group under the heading [param title], which the rows after it go into.
func _group(title: String) -> void:
	_column = SettingsColumns.group(title)
	_groups.add_child(_column)


func _add(label: String, control: Control) -> void:
	_column.add_child(MenuTheme.row(label, control))


func _apply() -> void:
	_settings.apply_video(get_tree())
