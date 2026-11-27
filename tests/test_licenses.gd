extends GdUnitTestSuite
## The notices a build carries, GAME.md 8.5 and 9.3a, see [Licenses]: Godot's pieces less what no
## build of the game carries, the game's own third-party pieces, and each license's text once.


## Every piece left out by name is one the engine names, so an upgrade that renames or drops one
## fails here rather than quietly listing what no build carries.
func test_every_name_left_out_is_in_the_engines_list() -> void:
	var names := PackedStringArray()
	for piece: Dictionary in Engine.get_copyright_info():
		names.append(piece["name"])
	for name: String in Licenses.NOT_SHIPPED.keys() + Licenses.PLATFORMS.keys():
		assert_bool(names.has(name)).override_failure_message("%s is not Godot's" % name).is_true()


func test_nothing_left_out_is_listed_on_any_platform() -> void:
	for os: String in ["Linux", "Windows", "macOS", "Android"]:
		for name: String in _names(os):
			assert_bool(Licenses.NOT_SHIPPED.has(name)).is_false()
			assert_str(name).is_not_equal("Godot Engine")


## A Linux build, the game's and the dedicated server's, lists what Linux builds carry, the pieces
## whose licenses ask most for a notice among them, and no other platform's.
func test_a_linux_build_lists_what_it_carries() -> void:
	var names := _names("Linux")
	for name: String in [
		"The FreeType Project",
		"ENet",
		"OggVorbis",
		"Mbed TLS",
		"SDL",
		"AccessKit",
		"Wayland core protocol",
	]:
		assert_bool(names.has(name)).override_failure_message("%s is missing" % name).is_true()
	for name: String in ["D3D12 Memory Allocator", "ANGLE", "metal-cpp", "Swappy", "libjingle"]:
		assert_bool(names.has(name)).override_failure_message("%s is listed" % name).is_false()


func test_other_platforms_list_their_own() -> void:
	var windows := _names("Windows")
	for name: String in ["D3D12 Memory Allocator", "ANGLE", "mingw-std-threads", "SDL"]:
		assert_bool(windows.has(name)).is_true()
	assert_bool(windows.has("Wayland core protocol")).is_false()
	var android := _names("Android")
	for name: String in ["Swappy", "libjingle", "ProcessPhoenix"]:
		assert_bool(android.has(name)).is_true()
	for name: String in ["SDL", "AccessKit", "Wayland core protocol"]:
		assert_bool(android.has(name)).is_false()
	var mac := _names("macOS")
	for name: String in ["metal-cpp", "SPIRV-Cross", "ANGLE"]:
		assert_bool(mac.has(name)).is_true()


## Every license shown has its text, the keys of one license each count, and a key with no text,
## "public-domain", is not shown.
func test_every_license_shown_has_its_text() -> void:
	var texts := Engine.get_license_info()
	var keys := Licenses.keys(Credits.THINGS, Licenses.pieces("Linux"))
	for key: String in keys:
		assert_bool(texts.has(key)).is_true()
	for key: String in ["FTL", "BSD-3-clause", "Apache-2.0", "OFL-1.1", "Expat", "CC0-1.0"]:
		assert_bool(keys.has(key)).override_failure_message("%s is missing" % key).is_true()
	assert_array(Array(Licenses.keys_in("public-domain or Unlicense or Expat"))).is_equal(
		["public-domain", "Unlicense", "Expat"]
	)
	assert_bool(keys.has("public-domain")).is_false()
	assert_str(Licenses.title("Expat")).is_equal("MIT (Expat)")
	assert_str(Licenses.title("FTL")).is_equal("FTL")
	assert_str(Licenses.title("Apache-2.0 or Expat")).is_equal("Apache-2.0 or MIT (Expat)")


## The text `--licenses` prints carries every notice: the game's own terms and source, Godot's
## license, each piece with its copyright, the game's pieces with theirs, and each license's text.
func test_the_text_carries_every_notice() -> void:
	var things := Credits.in_this_build()
	var text := Licenses.text(things)
	assert_str(text).contains(Licenses.own_terms())
	assert_str(text).contains(Credits.REPOSITORY)
	assert_str(text).contains(Engine.get_license_text())
	for piece: Dictionary in Licenses.pieces():
		assert_str(text).contains(piece["name"])
		for part: Dictionary in piece["parts"]:
			for line: String in Licenses.copyright(part["copyright"]):
				assert_str(text).contains(line)
	for thing: Dictionary in things:
		if thing["what"] != "Godot Engine":
			assert_str(text).contains(thing["what"])
		for line: String in Licenses.copyright(thing.get("copyright", [])):
			assert_str(text).contains(line)
	var texts := Engine.get_license_info()
	for key: String in Licenses.keys(things, Licenses.pieces()):
		assert_str(text).contains(texts[key])


func _names(os: String) -> PackedStringArray:
	var names := PackedStringArray()
	for piece: Dictionary in Licenses.pieces(os):
		names.append(piece["name"])
	return names
