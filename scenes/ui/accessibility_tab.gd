class_name AccessibilityTab
extends ScrollContainer
## The Accessibility page of the settings, GAME.md 8.5, in groups under headings as the Video page
## has, see [SettingsColumns]: how the karts are seen and what moves and flashes down the left,
## aiming and the HUD and its hints down the right. Every change takes effect at once; the settings
## screen saves them on Back. It scrolls, for a phone's short screen under a big UI scale.

## A palette for color blindness was chosen, which the Seats page draws its colors in again.
signal palette_chosen
## Another language was chosen, which every page is built in again, see [Lang].
signal language_chosen
## The aim guide was put back as it was at first, see [AimGuideRows].
signal aim_guide_reset

## The page's groups, GAME.md 8.5, by their headings, each shown through tr(): how the karts are
## seen and what moves and flashes on the left, aiming, the HUD and its hints and the language on
## the right.
const SEEING := "Seeing"
const MOTION := "Motion and light"
const AIMING := "Aiming"
const HUD := "HUD and hints"
const LANGUAGE := "Language"

var _settings: Settings
## Laid over a room, where the language is not changed, see [method _add_language].
var _overlay := false
## The page's groups, and the one rows go into as the page is built.
var _groups: SettingsColumns
var _column: VBoxContainer


static func make(settings: Settings, overlay := false) -> AccessibilityTab:
	var tab := AccessibilityTab.new()
	tab.name = "Accessibility"
	tab._settings = settings
	tab._overlay = overlay
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
	_add_hud()
	_add_language()


## The karts' colors and what marks a player's own, shown on three karts as they are set.
func _add_seeing() -> void:
	_group(SEEING)
	_column.add_child(_vision_row())
	var preview := KartMarksPreview.new()
	preview.name = "KartMarksPreview"
	_column.add_child(MenuTheme.row("", preview))
	# The rings under the karts and the marker over a player's own, both asked for, GAME.md 8.5.
	var rings := MenuTheme.option(
		[tr("Off"), tr("My kart"), tr("All karts")],
		maxi(ViewChoices.RINGS.find(_settings.kart_rings), 0)
	)
	rings.item_selected.connect(
		func(index: int) -> void: _settings.kart_rings = ViewChoices.RINGS[index]
	)
	_add(tr("Kart rings"), rings)
	var mark := func(on: bool) -> void: _settings.kart_marker = on
	_add(tr("Marker over my kart"), _check(_settings.kart_marker, mark))
	# The arrows at a rival out of the picture, GAME.md 8.2; a kart driven here is always pointed at.
	var arrows := MenuTheme.option(
		[tr("Off"), tr("Faint"), tr("Full")],
		maxi(ViewChoices.RIVAL_ARROWS.find(_settings.rival_arrows), 0)
	)
	arrows.name = "RivalArrows"
	arrows.item_selected.connect(
		func(index: int) -> void: _settings.rival_arrows = ViewChoices.RIVAL_ARROWS[index]
	)
	_add(tr("Rival arrows"), arrows)


## What shakes, moves and flashes, for anybody it bothers.
func _add_motion() -> void:
	_group(MOTION)
	var shake := func(on: bool) -> void: _settings.screen_shake = on
	_add(tr("Screen shake"), _check(_settings.screen_shake, shake))
	# Switched on, every pad plugged in gives a knock, so it is felt that it is, see
	# [method DeviceInput.nudge].
	var rumble := func(on: bool) -> void:
		_settings.rumble = on
		if on:
			for pad: int in DeviceInput.pads():
				DeviceInput.nudge(pad)
	_add(tr("Rumble"), _check(_settings.rumble, rumble))
	# The same setting as under Camera on the Video page, see [method VideoTab.fixed_camera_switch].
	_add(tr(VideoTab.FIXED), VideoTab.fixed_camera_switch(_settings))
	var glide := func(on: bool) -> void: _settings.cursor_glide = on
	_add(tr("Cursor glide"), _check(_settings.cursor_glide, glide))
	var flashes := func(on: bool) -> void: _settings.flash_reduction = on
	_add(tr("Reduce flashing"), _check(_settings.flash_reduction, flashes))
	# Full, Few or Off: the rig, three heads of it at most, or none, GAME.md 8.5.
	var rig := MenuTheme.option(
		[tr("Full"), tr("Few"), tr("Off")],
		2 if not _settings.disco_lights else (1 if _settings.disco_few else 0)
	)
	rig.item_selected.connect(
		func(index: int) -> void:
			_settings.disco_lights = index != 2
			if index != 2:
				_settings.disco_few = index == 1
	)
	_add(tr("Disco lights"), rig)
	# The same setting as on the Video page, see [method VideoTab.crowd_box].
	_add(tr("Crowd"), VideoTab.crowd_box(_settings))


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
	_add(tr("Aim assist strength"), assist)
	var guide := func(on: bool) -> void: _settings.aim_guide = on
	_add(tr("Aim guide"), _check(_settings.aim_guide, guide))
	var aim_guide := AimGuideRows.make(_settings)
	aim_guide.reset.connect(aim_guide_reset.emit)
	_column.add_child(aim_guide)


## The HUD over the karts, how its speedometer counts, and what the screen says about driving and
## the buttons that do it.
func _add_hud() -> void:
	_group(HUD)
	# The HUD see-through over a kart rather than the camera dodging it, GAME.md 8.2.
	var see := func(on: bool) -> void: _settings.see_through_hud = on
	_add(tr("See-through HUD"), _check(_settings.see_through_hud, see))
	# How the speedometer counts, GAME.md 8.5: as the system's locale says until one is chosen.
	var units := MenuTheme.option(
		[tr("km/h"), tr("mph")], 1 if _settings.speed_unit() == SpeedUnits.MPH else 0
	)
	units.item_selected.connect(
		func(index: int) -> void:
			_settings.speed_unit_chosen = SpeedUnits.MPH if index == 1 else SpeedUnits.KMH
	)
	_add(tr("Speed in"), units)
	var hints := func(on: bool) -> void: _settings.control_hints = on
	_add(tr("Control hints"), _check(_settings.control_hints, hints))
	# The drive and fire hint at the start of every map, not only a seat's first room, GAME.md 3.8.
	var drive := func(on: bool) -> void: _settings.always_drive_hints = on
	_add(tr("Always show drive hints"), _check(_settings.always_drive_hints, drive))


## The language the game speaks, GAME.md 10.9: Automatic, Steam's or the system's, first, saying
## which that is, then each the game speaks, by its own name. Every page is built again in the one
## chosen. Over a room it is changed from the title screen instead, as profiles are, since the room
## underneath would carry on in the old one.
func _add_language() -> void:
	_group(LANGUAGE)
	var spoken := Lang.spoken()
	var automatic := Lang.resolve("", Store.language(), OS.get_locale())
	var words: Array[String] = [
		tr("Automatic ({language})").format({"language": Lang.name_of(automatic)})
	]
	for locale: String in spoken:
		words.append(Lang.name_of(locale))
	var choice := MenuTheme.option(words, spoken.find(_settings.language) + 1)
	choice.name = "Languages"
	choice.disabled = _overlay
	choice.item_selected.connect(
		func(index: int) -> void:
			_settings.language = "" if index == 0 else spoken[index - 1]
			Game.speak()
			language_chosen.emit()
	)
	_add(tr(LANGUAGE), choice)
	if _overlay:
		var where := tr("Change the language from the title screen.")
		_column.add_child(SettingsScreen.page_line(where))


## A group under the heading [param title], one of the page's groups, which the rows after it go
## into.
func _group(title: String) -> void:
	_column = SettingsColumns.group(tr(title), title)
	_groups.add_child(_column)


func _add(label: String, control: Control) -> void:
	_column.add_child(MenuTheme.row(label, control))


## The player colors for a kind of color blindness, GAME.md 8.5, with the eight they come out as
## beside the choice. The karts already in a room keep theirs, so from over one it says when the
## new ones arrive.
func _vision_row() -> HBoxContainer:
	var words := [
		tr("Off"),
		tr("Protanopia (red-weak)"),
		tr("Deuteranopia (green-weak)"),
		tr("Tritanopia (blue-weak)"),
	]
	var choice := MenuTheme.option(words, Settings.VISIONS.find(_settings.color_vision))
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
	return MenuTheme.row(tr("Color blindness"), both)


func _check(value: bool, setter: Callable) -> CheckButton:
	var box := MenuTheme.toggle(value)
	box.toggled.connect(func(on: bool) -> void: setter.call(on))
	return box
