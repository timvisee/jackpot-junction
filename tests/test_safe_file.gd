extends GdUnitTestSuite
## The settings and the profiles written whole and read back from their backup when they will not
## read, GAME.md 8.5, see [SafeFile].

const PATH := "user://test_safe_file.cfg"
const SETTINGS := "user://test_safe_file_settings.cfg"


func after_test() -> void:
	SafeFile.remove(PATH)
	Settings.remove_files(SETTINGS)


## A save is written beside the file and put in its place, what was there kept as its backup, and
## nothing is left half written beside it.
func test_a_save_keeps_the_last_one_as_its_backup() -> void:
	assert_int(SafeFile.save(_saying("first"), PATH)).is_equal(OK)
	assert_bool(FileAccess.file_exists(PATH + SafeFile.BACKUP)).is_false()
	assert_int(SafeFile.save(_saying("second"), PATH)).is_equal(OK)
	assert_str(_said(PATH)).is_equal("second")
	assert_str(_said(PATH + SafeFile.BACKUP)).is_equal("first")
	assert_bool(FileAccess.file_exists(PATH + SafeFile.TEMP)).is_false()
	var file := ConfigFile.new()
	assert_int(SafeFile.read(file, PATH)).is_equal(OK)
	assert_str(str(file.get_value("test", "said"))).is_equal("second")


## A file that will not read, or reads as nothing, is read from its backup, and set aside beside it
## rather than written over by the next save; so is one lost between the two steps of a save.
func test_a_broken_file_is_read_from_its_backup_and_set_aside() -> void:
	SafeFile.save(_saying("first"), PATH)
	SafeFile.save(_saying("second"), PATH)
	for broken: String in ['[test]\nsaid="half', ""]:
		var writing := FileAccess.open(PATH, FileAccess.WRITE)
		writing.store_string(broken)
		writing.close()
		var file := ConfigFile.new()
		assert_int(SafeFile.read(file, PATH)).is_equal(OK)
		assert_str(str(file.get_value("test", "said"))).is_equal("first")
		assert_bool(FileAccess.file_exists(PATH)).is_false()
		assert_bool(FileAccess.file_exists(PATH + SafeFile.BROKEN)).is_true()
	# The next save leaves the good backup be, there being nothing in the file's place to keep.
	SafeFile.save(_saying("third"), PATH)
	assert_str(_said(PATH)).is_equal("third")
	assert_str(_said(PATH + SafeFile.BACKUP)).is_equal("first")
	# Nothing at all to read: nothing read.
	SafeFile.remove(PATH)
	var none := ConfigFile.new()
	assert_int(SafeFile.read(none, PATH)).is_not_equal(OK)
	assert_bool(none.get_sections().is_empty()).is_true()
	assert_bool(SafeFile.exists(PATH)).is_false()


## A profile whose file will not read keeps its progress from its backup, and one whose file was
## lost between the two steps of a save is still listed and played as itself.
func test_a_profile_comes_back_from_its_backup() -> void:
	var settings := Settings.new()
	settings.path = SETTINGS
	settings.load_from_disk()
	settings.profile.player_names[0] = "Ann"
	settings.save_to_disk()
	settings.profile.player_names[0] = "Anne"
	settings.save_to_disk()
	var made := settings.new_profile()
	made.player_names[0] = "Bob"
	made.save_to_disk()
	made.save_to_disk()
	var ann := settings.profile.path
	var writing := FileAccess.open(ann, FileAccess.WRITE)
	writing.store_string('[players]\nnames=["Anne')
	writing.close()
	DirAccess.rename_absolute(made.path, made.path + SafeFile.BACKUP)
	var read := Settings.new()
	read.path = SETTINGS
	read.load_from_disk()
	assert_str(read.profile.player_names[0]).is_equal("Ann")
	var names: Array[String] = []
	for each: Profile in read.profiles():
		names.append(each.player_names[0])
	assert_array(names).is_equal(["Ann", "Bob"])
	# Thrown away, it goes with its backup and all.
	assert_bool(read.delete_profile(made.id)).is_true()
	assert_bool(SafeFile.exists(made.path)).is_false()


func _saying(words: String) -> ConfigFile:
	var file := ConfigFile.new()
	file.set_value("test", "said", words)
	return file


func _said(path: String) -> String:
	var file := ConfigFile.new()
	file.load(path)
	return str(file.get_value("test", "said", ""))
