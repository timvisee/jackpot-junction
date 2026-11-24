class_name AccessibilityTab
extends ScrollContainer
## The Accessibility page of the settings, GAME.md 8.5, in groups under headings as the Video page
## has, see [SettingsColumns]: how the karts are seen and what moves and flashes down the left,
## aiming and the hints down the right. Every change takes effect at once; the settings screen
## saves them on Back. It scrolls, for a phone's short screen under a big UI scale.

## A palette for color blindness was chosen, which the Seats page draws its colors in again.
signal palette_chosen
## The aim guide was put back as it was at first, see [AimGuideRows].
signal aim_guide_reset

## The page's groups, GAME.md 8.5, by their headings: how the karts are seen and what moves and
## flashes on the left, aiming and the hints on the right.
const SEEING := "Seeing"
const MOTION := "Motion and light"
const AIMING := "Aiming"
const HINTS := "Hints"

var _settings: Settings
## The page's groups, and the one rows go into as the page is built.
var _groups: SettingsColumns
var _column: VBoxContainer


static func make(settings: Settings) -> AccessibilityTab:
	var tab := AccessibilityTab.new()
	tab.name = "Accessibility"
	tab._settings = settings
	return tab


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_groups = SettingsColumns.new()
	_groups.name = "Groups"
	_groups.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_groups)
	_add_seeing()
	_add_motion()
	_groups.split = _groups.get_child_count()
	_add_aiming()
	_add_hints()


## The karts' colors, what marks a player's own, the HUD over them, and the speedometer.
func _add_seeing() -> void:
	_group(SEEING)
	_column.add_child(_vision_row())
	# The rings under the karts and the marker over a player's own, both asked for, and the HUD
	# see-through over a kart rather than the camera dodging it, GAME.md 8.2 and 8.5.
	var rings := MenuTheme.option(
		["Off", "My kart", "All karts"], maxi(ViewChoices.RINGS.find(_settings.kart_rings), 0)
	)
	rings.item_selected.connect(
		func(index: int) -> void: _settings.kart_rings = ViewChoices.RINGS[index]
	)
	_add("Kart rings", rings)
	var mark := func(on: bool) -> void: _settings.kart_marker = on
	_add("Marker over my kart", _check(_settings.kart_marker, mark))
	var see := func(on: bool) -> void: _settings.see_through_hud = on
	_add("See-through HUD", _check(_settings.see_through_hud, see))
	# How the speedometer counts, GAME.md 8.5: as the system's locale says until one is chosen.
	var units := MenuTheme.option(
		["km/h", "mph"], 1 if _settings.speed_unit() == SpeedUnits.MPH else 0
	)
	units.item_selected.connect(
		func(index: int) -> void:
			_settings.speed_unit_chosen = SpeedUnits.MPH if index == 1 else SpeedUnits.KMH
	)
	_add("Speed in", units)


## What shakes, moves and flashes, for anybody it bothers.
func _add_motion() -> void:
	_group(MOTION)
	var shake := func(on: bool) -> void: _settings.screen_shake = on
	_add("Screen shake", _check(_settings.screen_shake, shake))
	_add("Rumble", _check(_settings.rumble, func(on: bool) -> void: _settings.rumble = on))
	var still := func(on: bool) -> void: _settings.fixed_camera = on
	_add("Fixed camera", _check(_settings.fixed_camera, still))
	var glide := func(on: bool) -> void: _settings.cursor_glide = on
	_add("Cursor glide", _check(_settings.cursor_glide, glide))
	var flashes := func(on: bool) -> void: _settings.flash_reduction = on
	_add("Reduce flashing", _check(_settings.flash_reduction, flashes))
	# Full, Few or Off: the rig, three heads of it at most, or none, GAME.md 8.5.
	var rig := MenuTheme.option(
		["Full", "Few", "Off"],
		2 if not _settings.disco_lights else (1 if _settings.disco_few else 0)
	)
	rig.item_selected.connect(
		func(index: int) -> void:
			_settings.disco_lights = index != 2
			if index != 2:
				_settings.disco_few = index == 1
	)
	_add("Disco lights", rig)
	# The same setting as on the Video page, see [method VideoTab.crowd_box].
	_add("Crowd", VideoTab.crowd_box(_settings))


## How much help a cannon is given, and the guide drawn ahead of it, see [AimGuideRows].
func _add_aiming() -> void:
	_group(AIMING)
	var assist := HSlider.new()
	assist.min_value = 0.0
	assist.max_value = 1.0
	assist.step = 0.05
	assist.value = _settings.aim_assist
	assist.custom_minimum_size = Vector2(320.0, 0.0)
	assist.value_changed.connect(func(v: float) -> void: _settings.aim_assist = v)
	_add("Aim assist strength", assist)
	var guide := func(on: bool) -> void: _settings.aim_guide = on
	_add("Aim guide", _check(_settings.aim_guide, guide))
	var aim_guide := AimGuideRows.make(_settings)
	aim_guide.reset.connect(aim_guide_reset.emit)
	_column.add_child(aim_guide)


## What the screen says about driving and the buttons that do it.
func _add_hints() -> void:
	_group(HINTS)
	var hints := func(on: bool) -> void: _settings.control_hints = on
	_add("Control hints", _check(_settings.control_hints, hints))
	# The drive and fire hint at the start of every map, not only a seat's first room, GAME.md 3.8.
	var drive := func(on: bool) -> void: _settings.always_drive_hints = on
	_add("Always show drive hints", _check(_settings.always_drive_hints, drive))


## A group under the heading [param title], which the rows after it go into.
func _group(title: String) -> void:
	_column = SettingsColumns.group(title)
	_groups.add_child(_column)


func _add(label: String, control: Control) -> void:
	_column.add_child(MenuTheme.row(label, control))


## The player colors for a kind of color blindness, GAME.md 8.5, with the eight they come out as
## beside the choice. The karts already in a room keep theirs, so from over one it says when the
## new ones arrive.
func _vision_row() -> HBoxContainer:
	var words := [
		"Off", "Protanopia (red-weak)", "Deuteranopia (green-weak)", "Tritanopia (blue-weak)"
	]
	var choice := MenuTheme.option(words, Settings.VISIONS.find(_settings.color_vision))
	choice.custom_minimum_size = Vector2(0.0, 44.0)
	var swatches := HBoxContainer.new()
	swatches.add_theme_constant_override("separation", 6)
	for slot: int in Palette.PLAYER_COLORS.size():
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(20.0, 20.0)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		swatches.add_child(swatch)
	var paint := func() -> void:
		for slot: int in swatches.get_child_count():
			(swatches.get_child(slot) as ColorRect).color = Palette.player_color(slot)
	paint.call()
	choice.item_selected.connect(
		func(index: int) -> void:
			_settings.color_vision = Settings.VISIONS[index]
			Palette.vision = _settings.color_vision
			paint.call()
			palette_chosen.emit()
			# Over a room, the karts in it change there and then, under the settings.
			var room := get_tree().get_first_node_in_group(&"match") as Match
			if room != null:
				KartVisuals.repaint_all(room)
	)
	var both := HBoxContainer.new()
	both.add_theme_constant_override("separation", 16)
	both.add_child(choice)
	both.add_child(swatches)
	return MenuTheme.row("Color blindness", both)


func _check(value: bool, setter: Callable) -> CheckButton:
	var box := MenuTheme.toggle(value)
	box.toggled.connect(func(on: bool) -> void: setter.call(on))
	return box
