class_name SteamSaves
extends RefCounted
## Where a Steam account's saves are kept, GAME.md 10.8: settings and profiles in a folder of the
## account's own, so two accounts on one machine never share profiles and the GitHub build beside
## it keeps its own. Steam's Auto-Cloud takes the profiles from there to the account's other
## machines; the settings stay with the machine. The first time an account plays where it has no
## saves, the GitHub build's are copied in, once and without a word.

## The folder every account's folder is in.
const ROOT := "user://steam"
## What a settings file is called wherever it is: the player's own at the top of the user
## directory, or an account's in its folder.
const SETTINGS_FILE := "settings.cfg"


## The settings file of the Steam account [param account], its SteamID64.
static func settings_path(account: int) -> String:
	return ROOT.path_join(str(account)).path_join(SETTINGS_FILE)


## Copies the settings at [param from], and the profiles beside them, to [param to] and beside it,
## unless there is anything there already: settings, or profiles Steam brought down from its cloud.
## Says whether it copied anything. Copied, not moved: the GitHub build goes on with its own.
static func bring_over(to: String, from := Settings.DEFAULT_PATH) -> bool:
	var into := Settings.new()
	into.path = to
	var source := Settings.new()
	source.path = from
	if SafeFile.exists(to) or _has_files(into.profiles_dir()):
		return false
	if not SafeFile.exists(from) and not _has_files(source.profiles_dir()):
		return false
	DirAccess.make_dir_recursive_absolute(into.profiles_dir())
	for each: String in [from, from + SafeFile.BACKUP]:
		if FileAccess.file_exists(each):
			DirAccess.copy_absolute(each, to + each.trim_prefix(from))
	var folder := source.profiles_dir()
	for file: String in DirAccess.get_files_at(folder) if _has_files(folder) else []:
		if file.ends_with(".cfg") or file.ends_with(".cfg" + SafeFile.BACKUP):
			DirAccess.copy_absolute(folder.path_join(file), into.profiles_dir().path_join(file))
	return true


static func _has_files(folder: String) -> bool:
	return DirAccess.dir_exists_absolute(folder) and not DirAccess.get_files_at(folder).is_empty()
