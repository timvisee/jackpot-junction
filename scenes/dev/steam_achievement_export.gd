extends "res://scenes/dev/achievement_export.gd"
## What Steamworks' Bulk Import/Export takes for the achievements, GAME.md 10.8, which is what
## `make steam-achievement-art` runs. It writes each achievement's icon, earned and not yet earned,
## at Steam's [constant ICON] pixels. Each icon is named the way Steam pairs it with its
## achievement, `STREET_LEGAL_ACHIEVED.png` and `STREET_LEGAL_UNACHIEVED.png`. Beside the icons go
## the definitions and the words in every language the game speaks, written as Steam's own export
## writes them and named
## after the app, [code]--app=<id>[/code]. Last comes the list of statistics, which the importer
## does not take, to make by hand first. Into `build/steam-achievements/`, emptied first, so that
## everything in it can be dropped on the upload box at once; `docs/STEAM.md` says the steps.

const STEAM_OUT := "res://build/steam-achievements"
const ICON := 256
## The suffixes Steam pairs an icon with its achievement by.
const ACHIEVED := "_ACHIEVED"
const UNACHIEVED := "_UNACHIEVED"
## The columns of Steam's definitions, with the notes its own export carries: it skips what is in
## brackets when reading one back.
const DEFINITIONS: Array[String] = [
	"api_name (required, unique; the name your game passes to the API)",
	"setid (optional; the id of a set that already exists)",
	"permission (one of Client, GameServer, OfficialGameServer)",
	"spoiler (true or false)",
	"archived (true or false)",
	(
		"progress_stat_name (optional; the name of a stat that already exists, blank for no"
		+ " progress bar)"
	),
	"progress_stat_min (number, no lower than the stat's own min)",
	"progress_stat_max (number, above min and no higher than the stat's own max)",
]
## The localization's first columns, then a column of words for each language the game speaks, by
## the name Steam gives it.
const LOCALIZATION: Array[String] = ["api_name", "field"]
## Steam's own export is UTF-8 with a byte order mark, and has Windows line ends.
const BOM := "﻿"
const END := "\r\n"

## The app the tables are named after, as Steam names its own: Spacewar's unless told.
var _app := Store.SPACEWAR


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--app="):
			_app = int(arg.get_slice("=", 1))
	_make_folder(STEAM_OUT)
	_empty()
	for each: Achievement in Achievements.all():
		for look: AchievementArt.Look in [AchievementArt.Look.EARNED, AchievementArt.Look.LOCKED]:
			var image := await _render(each, look)
			image.resize(ICON, ICON, Image.INTERPOLATE_LANCZOS)
			var path := STEAM_OUT.path_join(icon_name(each, look))
			if image.save_png(path) != OK:
				push_error("could not write %s" % path)
	_write(STEAM_OUT.path_join("%d-achievements-definitions.csv" % _app), definitions_csv())
	_write(STEAM_OUT.path_join("%d-achievements-localization.csv" % _app), localization_csv())
	_write(STEAM_OUT.path_join("stats.txt"), stats_text())
	print(
		(
			"steam achievement art: %d achievements for app %d into %s"
			% [Achievements.all().size(), _app, STEAM_OUT]
		)
	)
	if _app == Store.SPACEWAR:
		push_warning("named for Spacewar's 480: give the game's own, STEAM_APP_ID=<id>")
	get_tree().quit()


## The file of [param achievement]'s icon when it looks [param look]: its name on Steam and
## whether it is earned, which is how Steam pairs the two.
static func icon_name(achievement: Achievement, look: AchievementArt.Look) -> String:
	var earned := look == AchievementArt.Look.EARNED
	return achievement.store_name() + (ACHIEVED if earned else UNACHIEVED) + ".png"


## Every achievement on Steam, a row each: set by the game, a spoiler when hidden, and the
## statistic its bar is drawn from, if any, from nothing to the bar's target; Steam's own export
## writes 0 to 0 for a row with no bar.
static func definitions_csv() -> String:
	var rows: Array[Array] = [DEFINITIONS]
	for each: Achievement in Achievements.all():
		var stat := _steam_stat(each)
		var target := 0
		if not stat.is_empty():
			target = Achievements.progress(Profile.new(), each).y
		rows.append(
			[each.store_name(), "", "Client", _truth(each.hidden), "false", stat, "0", str(target)]
		)
	return _table(rows)


## Every achievement's name and description, two rows each, in English and every other language the
## game speaks, from its translations, as the game shows them.
static func localization_csv() -> String:
	var steam := Lang.on_steam()
	var head: Array[String] = LOCALIZATION.duplicate()
	head.append_array(steam.keys())
	var rows: Array[Array] = [head]
	for each: Achievement in Achievements.all():
		for field: String in ["name", "description"]:
			var row: Array[String] = [each.store_name(), field]
			for language: String in steam:
				var english := each.title if field == "name" else each.objective
				row.append(Lang.t_in(steam[language], english))
			rows.append(row)
	return _table(rows)


## The statistics the bars are drawn from, which the importer does not make, so they are made by
## hand before the definitions are imported.
static func stats_text() -> String:
	var lines: Array[String] = []
	for each: Achievement in Achievements.all():
		var stat := _steam_stat(each)
		if not stat.is_empty():
			var target := Achievements.progress(Profile.new(), each).y
			lines.append("%-30s Max %-4d %s" % [stat, target, each.title])
	var head: Array[String] = [
		"Jackpot Junction's statistics on Steam, GAME.md 10.8: %d" % lines.size(),
		"",
		"Make these under Stats before importing the achievements, whose progress bars are drawn",
		"from them. Each is type INT, Set By Client, Increment Only, Min 0, and Max as given.",
		"",
	]
	return "\n".join(head + lines) + "\n"


## [param rows] as Steam writes a table: UTF-8 with a byte order mark, Windows line ends, and a
## field in quotes only when it holds a comma, a quote or a line end.
static func _table(rows: Array[Array]) -> String:
	var lines := PackedStringArray()
	for row: Array in rows:
		var fields := PackedStringArray()
		for field: String in row:
			fields.append(_field(field))
		lines.append(",".join(fields))
	return BOM + END.join(lines) + END


static func _field(words: String) -> String:
	for mark: String in [",", '"', "\r", "\n"]:
		if mark in words:
			return _quoted(words)
	return words


static func _truth(yes: bool) -> String:
	return "true" if yes else "false"


## Takes out what an earlier run left, an achievement since renamed or another app's tables, so
## the folder holds this run's alone.
func _empty() -> void:
	for file: String in DirAccess.get_files_at(STEAM_OUT):
		if file.get_extension() in ["png", "csv", "txt"]:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(STEAM_OUT.path_join(file)))
