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

## The Monitor box, there only with more than one screen to pick from, and what it says to the
## mouse and a screen reader.
const MONITOR := "Monitor"
const MONITOR_TIP := "Which screen the game plays on, with more than one plugged in."
## The Quality box over the Graphics group, GAME.md 8.5, and what it says to the mouse and a screen
## reader.
const QUALITY := "Quality"
const QUALITY_TIP := (
	"Sets the six below at once: Low asks least of your graphics card, Ultra is the sharpest."
	+ " Change one of them yourself and it says Custom."
)
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
## The Quality box, and how each box it sets shows what it is set to again once it has.
var _quality_box: OptionButton
var _shown_again: Array[Callable] = []
## Whether this is a phone or a tablet, and whether the renderer is the desktop's, for the tests to
## build the page as another platform would.
var _handheld := false
var _full_renderer := true
## How big each screen is that the game can be put on, see [method Settings.pickable_screens].
var _screens: Array[Vector2i] = []


static func make(
	settings: Settings,
	handheld := OS.has_feature("mobile"),
	full_renderer := Settings.full_renderer(),
	screens := Settings.pickable_screens()
) -> VideoTab:
	var tab := VideoTab.new()
	tab.name = "Video"
	tab._settings = settings
	tab._handheld = handheld
	tab._full_renderer = full_renderer
	tab._screens = screens
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


## What a room pays for on the card, GAME.md 8.5, under a preset that sets all six at once, see
## [QualityPresets]: each the room's own strength the player keeps a share of, relit at once, since
## the room is standing.
func _add_graphics() -> void:
	_group(GRAPHICS)
	var names: Array = QualityPresets.NAMES.slice(0, QualityPresets.offered(_full_renderer))
	names.append(QualityPresets.CUSTOM)
	_quality_box = MenuTheme.option(names, 0)
	_quality_box.name = "Quality"
	# Custom is what the box says, not a preset to pick.
	_quality_box.set_item_disabled(names.size() - 1, true)
	_quality_box.tooltip_text = QUALITY_TIP
	ScreenReader.name(_quality_box, QUALITY, QUALITY_TIP)
	_quality_box.item_selected.connect(_use_preset)
	_add(QUALITY, _quality_box)
	var relight := func() -> void: ArenaEnvironment.relight(get_tree())
	var shadows := ["Off", "Low", "High"]
	var lit := func() -> void:
		_apply()
		relight.call()
	_add_option("Shadows", shadows, Settings.SHADOW_LEVELS, &"shadows", lit)
	var detail := texture_box(_settings, _full_renderer)
	detail.item_selected.connect(func(_index: int) -> void: _say_quality())
	_shown_again.append(
		func() -> void: detail.select(maxi(_textures_offered().find(_shown_texture()), 0))
	)
	_add(TEXTURES, detail)
	_add_option("Ambient occlusion", OCCLUSION_NAMES, OCCLUSION_LEVELS, &"occlusion", relight)
	_add_option("Bloom", BLOOM_NAMES, BLOOM_LEVELS, &"bloom", relight)
	_add_option("MSAA", ["Off", "2x", "4x", "8x"], Settings.MSAA_SAMPLES, &"msaa", _apply)
	var smoothings := ["Off", "FXAA", "SMAA"]
	_add_option("Screen smoothing", smoothings, Settings.SMOOTHINGS, &"screen_smoothing", _apply)
	_say_quality()


## A box of [param names] for the setting [param key], each one of [param values], calling
## [param changed] once it is set; shown again as it is set when a preset sets it.
func _add_option(
	label: String, names: Array, values: Array, key: StringName, changed: Callable
) -> void:
	var box := MenuTheme.option(names, maxi(values.find(_settings.get(key)), 0))
	box.item_selected.connect(
		func(index: int) -> void:
			_settings.set(key, values[index])
			changed.call()
			_say_quality()
	)
	_shown_again.append(func() -> void: box.select(maxi(values.find(_settings.get(key)), 0)))
	_add(label, box)


## The six under the Quality box set as preset [param index] has them, the boxes showing it and
## the room drawn again at once, the floor too where its texture detail changed.
func _use_preset(index: int) -> void:
	if index >= QualityPresets.offered(_full_renderer):
		return
	var detail_was := _settings.texture_detail
	QualityPresets.use(_settings, index)
	for shown: Callable in _shown_again:
		shown.call()
	_apply()
	ArenaEnvironment.relight(get_tree())
	if _settings.texture_detail != detail_was:
		ScreenPrint.redraw(get_tree())
	_say_quality()


## The Quality box showing the preset the six under it are set as, or Custom.
func _say_quality() -> void:
	var auto := LayoutPrint.auto_detail(_full_renderer)
	var at := QualityPresets.of(_settings, auto, _full_renderer)
	_quality_box.select(at if at >= 0 else _quality_box.item_count - 1)


## The texture details the Texture detail box lists, and the one it shows, see [method texture_box].
func _textures_offered() -> Array[String]:
	var offered: Array[String] = Settings.TEXTURE_DETAILS.duplicate()
	if not _full_renderer:
		offered.erase(Settings.TEXTURES_ULTRA)
	return offered


func _shown_texture() -> String:
	var shown := _settings.texture_detail
	return shown if shown in _textures_offered() else Settings.TEXTURES_HIGH


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


## The window, which a desktop has and a phone does not: full screen, or a window of a size, and
## with more than one screen to put it on, which.
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
	if _screens.size() > 1:
		_add(MONITOR, _monitor_box())


## Which screen the game plays on, GAME.md 8.5: each by its number and size, the one it is on now
## shown until one is picked, or while the one picked is not plugged in.
func _monitor_box() -> OptionButton:
	var names: Array = []
	for i: int in _screens.size():
		names.append("Screen %d (%d × %d)" % [i + 1, _screens[i].x, _screens[i].y])
	var at := _settings.monitor
	if at < 0 or at >= _screens.size():
		at = clampi(DisplayServer.window_get_current_screen(), 0, _screens.size() - 1)
	var box := MenuTheme.option(names, at)
	box.name = "Monitor"
	box.tooltip_text = MONITOR_TIP
	ScreenReader.name(box, MONITOR, MONITOR_TIP)
	box.item_selected.connect(
		func(index: int) -> void:
			_settings.monitor = index
			_apply()
	)
	return box


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
