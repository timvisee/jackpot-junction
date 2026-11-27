extends GdUnitTestSuite
## Another player's driver license, GAME.md 10.8: this machine's as it goes over the wire, a
## learner's none, and a linked seat's its own profile's; one that came over it cleaned, whoever
## sent it; and the card made from it, as its holder's own but the story's marks, which are theirs
## to know.

const LINKED := "user://test_license_wire.cfg"

var _kept: Profile


func before_test() -> void:
	_kept = Game.settings.profile
	Game.settings.profile = Profile.new()


func after_test() -> void:
	Game.settings.profile = _kept


func test_a_learner_has_none_to_show() -> void:
	assert_dict(LicenseWire.here()).is_empty()


func test_this_machines_license() -> void:
	Game.settings.license_number = "K-1234"
	Game.settings.license_date = "2026-11-27"
	Game.settings.license_holder = "Ann"
	Game.settings.license_endorsements = PackedStringArray(["KO", "JACKPOT"])
	Game.settings.profile.license_cones = 2
	var mine := LicenseWire.here()
	assert_str(str(mine["name"])).is_equal("Ann")
	assert_str(str(mine["number"])).is_equal("K-1234")
	assert_array(Array(mine["earned"])).contains_exactly(["KO", "JACKPOT"])
	assert_int(int(mine["cones"])).is_equal(2)
	assert_bool(mine.has("approved")).is_false()
	# As it comes back out at the other end, the same.
	assert_dict(LicenseWire.clean(mine)).is_equal(LicenseWire.clean(LicenseWire.clean(mine)))


func test_one_sent_by_anybody_is_cleaned() -> void:
	assert_dict(LicenseWire.clean("not a license")).is_empty()
	assert_dict(LicenseWire.clean({"name": "No number"})).is_empty()
	var words: Array = []
	for i: int in 40:
		words.append("WORD %d %s" % [i, "x".repeat(60)])
	var said := {
		"name": "A name far too long for any seat in this game",
		"number": "9".repeat(100),
		"color": 999,
		"style": "nonsense",
		"earned": words,
		"stamps": words,
		"cones": -5,
		"approved": "2026-01-01",
	}
	var clean := LicenseWire.clean(said)
	assert_int(str(clean["name"]).length()).is_less_equal(PlayerNames.MAX_LENGTH)
	assert_int(str(clean["number"]).length()).is_equal(LicenseWire.WORD)
	assert_int(int(clean["color"])).is_equal(Palette.PLAYER_COLORS.size() - 1)
	assert_int(Array(clean["style"]).size()).is_equal(0)
	assert_int((clean["earned"] as PackedStringArray).size()).is_equal(LicenseWire.MOST)
	assert_int((clean["stamps"] as PackedStringArray)[0].length()).is_equal(LicenseWire.WORD)
	assert_int(int(clean["cones"])).is_equal(0)
	assert_bool(clean.has("approved")).is_false()


## The card made from one: the holder's name, number and endorsements, stamped, and none of the
## story's marks, whatever this machine's own story says.
func test_the_card_of_somebody_else() -> void:
	var said := {
		"name": "Bo",
		"number": "K-77",
		"issued": "2026-11-01",
		"color": 2,
		"earned": ["KO", "NOT AN ENDORSEMENT"],
		"stamps": ["LAP 3"],
	}
	var card: LicenseCard = auto_free(LicenseCard.from_wire(said))
	assert_str(card.holder_name).is_equal("Bo")
	assert_str(card.number).is_equal("K-77")
	assert_int(card.color_index).is_equal(2)
	assert_bool(card.endorsements["KO"]).is_true()
	assert_bool(card.endorsements.has("NOT AN ENDORSEMENT")).is_false()
	assert_array(Array(card.program_stamps)).contains_exactly(["LAP 3"])
	assert_bool(card.stamped).is_true()
	assert_bool(card.scratched).is_false()
	assert_str(card.approved).is_empty()
	assert_str(card.examiner).is_equal(LicenseCard.EXAMINER)


## Another seat at this machine shows the license of the profile linked to it, GAME.md 3.8; a seat
## with none, a guest's, has none to show, whatever the first seat holds.
func test_a_linked_seat_has_its_profiles_own() -> void:
	var settings_were := Game.settings
	Game.settings = Settings.new()
	Game.settings.path = LINKED
	Game.settings.license_number = "K-1"
	assert_dict(LicenseWire.of_seat(1)).is_empty()
	var bob := Game.settings.new_profile()
	bob.license_number = "K-2"
	bob.license_holder = "Bob"
	bob.license_endorsements = PackedStringArray(["KO"])
	bob.save_to_disk()
	Game.settings.link_seat(1, bob.id)
	var his := LicenseWire.of_seat(1)
	assert_str(str(his["name"])).is_equal("Bob")
	assert_str(str(his["number"])).is_equal("K-2")
	assert_array(Array(his["earned"])).contains_exactly(["KO"])
	assert_str(str(LicenseWire.here()["number"])).is_equal("K-1")
	Settings.remove_files(LINKED)
	Game.settings = settings_were
