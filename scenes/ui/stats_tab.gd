class_name StatsTab
extends ScrollContainer
## The Statistics tab of the settings, GAME.md 8.5: the profile playing, over every map it played
## to the end, in four groups, games, driving, fighting and money, see [LifetimeStats]. Read only:
## a profile starts its numbers at nothing, and a new profile is the way to start them again.

const TITLE := "Statistics"
const WHOSE := "%s, over every map played to the end."
const GROUP_INK := Palette.CHIP_GOLD
const NAME_INK := Color(0.78, 0.78, 0.84)
const VALUE_INK := Color(0.96, 0.96, 0.98)

## Each line's value, by the statistic it reads, for the tests.
var values: Dictionary[StringName, Label] = {}

var _settings: Settings


static func make(settings: Settings) -> StatsTab:
	var tab := StatsTab.new()
	tab.name = TITLE
	tab._settings = settings
	return tab


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	column.add_child(MenuTheme.title(TITLE, Type.HEADING))
	column.add_child(MenuTheme.subtitle(WHOSE % _settings.profile.display_name(), Type.LABEL))
	var groups := GridContainer.new()
	groups.columns = 2
	groups.add_theme_constant_override("h_separation", 72)
	groups.add_theme_constant_override("v_separation", 24)
	column.add_child(groups)
	for group: Array in LifetimeStats.GROUPS:
		groups.add_child(_group(group[0], group[1]))


## One group: its title, then a line each, what it is and how much, the numbers lined up.
func _group(title: String, lines: Array) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var heading := Label.new()
	Type.strong(heading, Type.BODY, GROUP_INK)
	heading.text = title
	box.add_child(heading)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	box.add_child(grid)
	for line: Array in lines:
		var named := Label.new()
		named.text = line[0]
		Type.text(named, Type.LABEL, NAME_INK)
		grid.add_child(named)
		var value := Label.new()
		value.text = LifetimeStats.shown(_settings.profile, line[1])
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Type.text(value, Type.LABEL, VALUE_INK)
		grid.add_child(value)
		values[line[1]] = value
	return box
