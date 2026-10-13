extends Control
## Every achievement at once, `make achievements`: each chip and pin as earned, with its name under
## it, then all of them not earned yet and the hidden scrap, and the lot again at the size a row of
## the list draws them, so the pictures of GAME.md 8.10 can be judged as the one set they are meant
## to be.

## How many to a row, how big each is on the sheet and in a row of the list, and the air between.
const COLUMNS := 10
const BIG := 132.0
const SMALL := 52.0
const GAP := 12


func _ready() -> void:
	var background := ColorRect.new()
	background.color = HouseTheme.STOCK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, GAP * 2)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", GAP * 2)
	margin.add_child(column)
	var earned := _grid(COLUMNS)
	column.add_child(earned)
	for achievement: Achievement in Achievements.all():
		earned.add_child(_named(achievement, AchievementArt.Look.EARNED))
	var small := _grid(COLUMNS * 2)
	column.add_child(small)
	for look: AchievementArt.Look in [AchievementArt.Look.EARNED, AchievementArt.Look.LOCKED]:
		for achievement: Achievement in Achievements.all():
			small.add_child(AchievementArt.picture(achievement, look, SMALL))
	small.add_child(
		AchievementArt.picture(Achievements.all()[-1], AchievementArt.Look.HIDDEN, SMALL)
	)
	var locked := HBoxContainer.new()
	locked.add_theme_constant_override("separation", GAP)
	column.add_child(locked)
	for id: StringName in [&"bank_shot", &"beat_the_house", &"terms_accepted", &"off_the_books"]:
		locked.add_child(
			AchievementArt.picture(Achievements.find(id), AchievementArt.Look.LOCKED, BIG)
		)
	locked.add_child(
		AchievementArt.picture(Achievements.all()[-1], AchievementArt.Look.HIDDEN, BIG)
	)


func _grid(columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	return grid


func _named(achievement: Achievement, look: AchievementArt.Look) -> Control:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 4)
	var drawn := AchievementArt.picture(achievement, look, BIG)
	drawn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.add_child(drawn)
	var name := Type.text(Label.new(), Type.SMALL, HouseTheme.WORDS)
	name.text = achievement.title
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.custom_minimum_size.x = BIG
	cell.add_child(name)
	return cell
