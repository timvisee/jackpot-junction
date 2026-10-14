class_name SafeFile
extends RefCounted
## The settings and the profiles written so that a crash or a power cut part way through never
## leaves one half written, GAME.md 8.5: each is written whole beside itself first and only then
## put in its place, the one it replaces kept as its backup. Read back, one that is missing, broken
## or empty is read from its backup instead, the broken one set aside rather than written over, so
## a profile's progress is never lost to a bad write and the next save.

## Beside the file: the one being written, the one it replaced, and one that would not read.
const TEMP := ".tmp"
const BACKUP := ".bak"
const BROKEN := ".broken"


## Writes [param file] to [param path] whole: beside it first, then in its place, what was there
## kept as its backup. Anything but OK leaves what was there as it was.
static func save(file: ConfigFile, path: String) -> Error:
	var temp := path + TEMP
	var error := file.save(temp)
	if error != OK:
		DirAccess.remove_absolute(temp)
		return error
	if FileAccess.file_exists(path):
		error = DirAccess.rename_absolute(path, path + BACKUP)
		if error != OK:
			DirAccess.remove_absolute(temp)
			return error
	return DirAccess.rename_absolute(temp, path)


## Reads [param path] into [param file], or its backup where it is missing, broken or empty, the
## broken one set aside beside it; OK if either was read, and [param file] empty if neither was.
static func read(file: ConfigFile, path: String) -> Error:
	if _reads(file, path):
		return OK
	if FileAccess.file_exists(path):
		push_warning("%s would not read; reading its backup, and keeping it as %s" % [path, BROKEN])
		DirAccess.rename_absolute(path, path + BROKEN)
	if _reads(file, path + BACKUP):
		return OK
	file.clear()
	return ERR_FILE_NOT_FOUND


## Whether there is anything to read at [param path]: the file or its backup.
static func exists(path: String) -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + BACKUP)


## The file at [param path] gone, its backup, a broken one and one left half written with it.
static func remove(path: String) -> Error:
	var error := ERR_FILE_NOT_FOUND
	for each: String in [path, path + BACKUP, path + BROKEN, path + TEMP]:
		if FileAccess.file_exists(each) and DirAccess.remove_absolute(each) == OK:
			error = OK
	return error


## [param path] read into [param file], and something in it: a file cut off before its first
## section reads as nothing.
static func _reads(file: ConfigFile, path: String) -> bool:
	file.clear()
	if not FileAccess.file_exists(path) or file.load(path) != OK:
		file.clear()
		return false
	return not file.get_sections().is_empty()
