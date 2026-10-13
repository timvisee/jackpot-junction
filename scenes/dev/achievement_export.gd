extends Node
## Renders every achievement's picture for a store's page, GAME.md 8.10, and quits, which is what
## `make achievement-art` runs: each chip and pin earned and not yet earned, and the hidden scrap,
## on a square of the house's dark stock under a soft light, at [constant MASTER] pixels and cut
## down to each of [constant SIZES]; and beside them a text file and a table of every id, its name
## on a store, its name, what it asks, whether it is hidden and what its bar counts to, for filling
## in a store's page. The pictures live in code, see [AchievementArt], and this is the one place
## they become files. Into `build/achievements/`, which is not kept in the repository.
##
## Windowed rather than headless: reading a viewport back needs a rendering device.

const OUT := "res://build/achievements"
const MASTER := 1024
const SIZES: Array[int] = [256, 64]
## How much of the square the chip takes, and the light behind it.
const FILL := 0.84
const LIGHT := Color(1.0, 0.86, 0.55, 0.018)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	# Pictures for a store, never the game's: the editor is not to import them.
	var ignored := OUT.get_base_dir().path_join(".gdignore")
	if not FileAccess.file_exists(ignored):
		_write(ignored, "")
	for size: int in [MASTER] + SIZES:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_folder(size)))
	for each: Achievement in Achievements.all():
		for look: AchievementArt.Look in [AchievementArt.Look.EARNED, AchievementArt.Look.LOCKED]:
			var image := await _render(each, look)
			var file := String(each.id) + ("" if look == AchievementArt.Look.EARNED else "_locked")
			_save(image, file)
	var hidden := await _render(Achievements.all()[-1], AchievementArt.Look.HIDDEN)
	_save(hidden, "hidden")
	_write_text()
	print("achievement art: %d achievements into %s" % [Achievements.all().size(), OUT])
	get_tree().quit()


func _folder(size: int) -> String:
	return OUT.path_join(str(size))


## [param image] saved as [param file] at the master's size and at each of the smaller ones.
func _save(image: Image, file: String) -> void:
	for size: int in [MASTER] + SIZES:
		var sized := image.duplicate() as Image
		if size != MASTER:
			sized.resize(size, size, Image.INTERPOLATE_LANCZOS)
		var path := _folder(size).path_join(file + ".png")
		if sized.save_png(path) != OK:
			push_error("could not write %s" % path)


## [param achievement] drawn as [param look] on its square, read back.
func _render(achievement: Achievement, look: AchievementArt.Look) -> Image:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(MASTER, MASTER)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var square := Square.new()
	square.achievement = achievement
	square.look = look
	square.size = Vector2(MASTER, MASTER)
	viewport.add_child(square)
	add_child(viewport)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	image.convert(Image.FORMAT_RGB8)
	return image


## Every achievement in words, as a table to read and as comma-separated values to import.
func _write_text() -> void:
	var lines: Array[String] = []
	var rows: Array[String] = ["store_name,id,name,objective,hidden,bar"]
	lines.append("Jackpot Junction achievements, GAME.md 8.10: %d" % Achievements.all().size())
	lines.append("")
	for each: Achievement in Achievements.all():
		var bar := _bar_words(each)
		lines.append("%s  (%s)" % [each.store_name(), each.id])
		lines.append("  Name:       %s" % each.title)
		lines.append("  Objective:  %s" % each.objective)
		lines.append("  Hidden:     %s" % ("yes, until earned" if each.hidden else "no"))
		if not bar.is_empty():
			lines.append("  Bar:        %s" % bar)
		lines.append("")
		(
			rows
			. append(
				(
					","
					. join(
						[
							each.store_name(),
							String(each.id),
							_quoted(each.title),
							_quoted(each.objective),
							"yes" if each.hidden else "no",
							_quoted(bar),
						]
					)
				)
			)
		)
	_write(OUT.path_join("achievements.txt"), "\n".join(lines))
	_write(OUT.path_join("achievements.csv"), "\n".join(rows) + "\n")


## What [param achievement]'s bar counts to, in words, or nothing for one with no bar.
static func _bar_words(achievement: Achievement) -> String:
	if not achievement.bar:
		return ""
	if achievement.id == &"know_every_street":
		var counts := PackedStringArray()
		for district: LoyaltyLandmark.District in Achievements.DISTRICTS:
			counts.append(str(Achievements.landmarks_of([district]).size()))
		return "the landmarks of one district, %s" % " / ".join(counts)
	return str(Achievements.progress(Profile.new(), achievement).y)


static func _quoted(words: String) -> String:
	return '"%s"' % words.replace('"', '""')


static func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("could not write %s" % path)
		return
	file.store_string(text)


## One achievement on its square of the house's stock, a soft light behind it.
class Square:
	extends Control

	var achievement: Achievement
	var look := AchievementArt.Look.EARNED

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), HouseTheme.STOCK)
		var middle := size * 0.5
		var reach := size.x * 0.5
		for i: int in 36:
			draw_circle(middle, reach * (1.0 - i * 0.02), LIGHT, true, -1.0, true)
		AchievementArt.draw(self, middle, reach * FILL, achievement, look)
