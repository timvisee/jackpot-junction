extends Control
## Dev harness for the posed UI shots of the README and the Steam page, see tools/screenshots: the
## House's opening invitation, the Your kart dialog, the joker catalog, the loyalty program and the
## driver's license, each mounted on the throwaway profile this runs under with `++ --shot=` and
## its name: invitation, kart, catalog, loyalty or license; and for the Steam supporter pack's store
## page, with `++ --supporter`, its pieces on the hat rack, its card backs, and its thank-you card,
## pack_kart, pack_backs and thanks, the license then wearing its endorsement and its star. The
## Game autoload's `--screenshot` grabs it, oversampled, as the gameplay shots are grabbed through
## the playground. Nothing here ships: it dresses a test profile and shows a screen the game already
## has.

## Every this many jokers in the catalog's order, one is left face down, as a player still finding
## them has it.
const STILL_TO_FIND := 6
## The share of the loyalty program's bets won in its shot, in the map's own order.
const LOYALTY_WON := 0.55
## The license's number drawn from this seed, so every shot carries the same one, and how many of
## the driving test's endorsements it has.
const LICENSE_SEED := 2026
const LICENSE_ENDORSED := 5

## What is held square on to the camera every frame, its tilted cards not turned toward wherever
## the cursor happens to be, see [method _process].
var _square_on: Node


func _process(_delta: float) -> void:
	if not is_instance_valid(_square_on):
		return
	for node: Node in _square_on.find_children("*", "", true, false):
		if node is TiltedCard:
			(node as TiltedCard).calm = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	MenuTheme.background(self)
	if _shot() == "invitation":
		# Shown all at once, as a press brings it, rather than played in from the dark, and leant
		# toward the envelope the way a player tips it with the stick or the mouse.
		var invite := OpeningInvitation.over(self, Game.settings.profile)
		invite.come_on_now()
		invite.pose(Vector2(0.7, -0.25))
	elif _shot() == "lastlines":
		# The story's ending played in from the dark, GAME.md: `--frames` lands on a beat of it.
		LastLines.begin(self)
	elif _shot() == "catalog":
		_catalog()
	elif _shot() == "loyalty":
		_loyalty()
	elif _shot() == "license":
		_license()
	elif _shot() == "thanks":
		_thanks()
	elif _shot() == "pack_backs":
		_kart(KartDialog.CARD_BACK, CardBack.STYLES.find("Beacon"))
	elif _shot() == "pack_kart":
		_kart(KartStyle.PARTS.find(&"hat"), KartStyle.HATS.find("House of cards"), 4)
	else:
		_kart()


## The driver's license, GAME.md 9.4a, held up as the title shows it once the driving test is
## passed: Tail Light Tim's, in blue with a top hat, with most of the test's endorsements.
func _license() -> void:
	var settings := Game.settings
	var rng := RandomNumberGenerator.new()
	rng.seed = LICENSE_SEED
	settings.tutorial_done = true
	settings.set_seat_name(0, "Tail Light Tim")
	settings.set_seat_color(0, 1)
	settings.set_seat_style(0, PackedInt32Array([5, 2, 3, 2, 0, 0, 0]))
	settings.license_holder = "Tail Light Tim"
	settings.license_number = LicenseCard.new_number(rng)
	settings.license_date = LicenseCard.today()
	settings.license_plate = LicensePlate.suggest("Tail Light Tim", settings.license_number)
	if Supporter.owned():
		# The supporter pack's endorsement, and its star on the plate.
		settings.supporter_since = LicenseCard.today()
		settings.license_plate = LicensePlate.clean("TIM*777")
	settings.license_endorsements = PackedStringArray(
		TutorialFight.ENDORSEMENTS.slice(0, LICENSE_ENDORSED)
	)
	# Over the title's own backdrop, where a player holds it up.
	TitleBackground.add_to(self)
	var view := LicenseView.open(self, true)
	# Its buttons built, their tooltips go: the one the cursor starts on would hang in the shot.
	await get_tree().process_frame
	for button: BaseButton in view.find_children("*", "BaseButton", true, false):
		button.tooltip_text = ""
	_square_on = view


## The loyalty program's road atlas, GAME.md 8.9, on a profile some way into it: every bet in the
## first [constant LOYALTY_WON] of the map's won, the rest still to win.
func _loyalty() -> void:
	var profile := Game.settings.profile
	var landmarks := Loyalty.map().landmarks
	for i: int in landmarks.size():
		if i < landmarks.size() * LOYALTY_WON:
			profile.loyalty.win(landmarks[i].id)
	Loyalty.settle(profile)
	LoyaltyDialog.open(self)


## The joker catalog, GAME.md 8.8, on a profile that has taken most of the jokers and used every
## power-up, each looked at already so no card wears NEW.
func _catalog() -> void:
	var catalog := Game.settings.profile.catalog
	var jokers := CatalogDialog.jokers_in_order()
	for i: int in jokers.size():
		if i % STILL_TO_FIND != STILL_TO_FIND - 1:
			catalog.take_joker(jokers[i].id)
			catalog.look_at(jokers[i].id)
	for item: PowerUp in CatalogDialog.items_in_order():
		catalog.use_item(item.id)
		catalog.look_at(item.id)
	CatalogDialog.open(self)


## The `--shot=` asked for, the kart dialog by default.
func _shot() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			return arg.get_slice("=", 1)
	return "kart"


## The supporter pack's thank-you card as it comes on the title, GAME.md 10.8, all at once.
func _thanks() -> void:
	TitleBackground.add_to(self)
	var thanks := SupporterThanks.over(self)
	thanks.start()
	thanks.come_on_now()
	_square_on = thanks


## The Your kart dialog on a profile that has won every piece of dress, GAME.md 8.9, in the set the
## README shows: racing stripes, a top hat, the checkered flag and confetti, on the racer, in blue;
## or with [param rack] the rack of that part out, the cursor on [param on], and in the supporter
## pack's outfit [param outfit] of [SupporterArt], its pieces on the rack, see `--supporter`.
func _kart(rack := -1, on := -1, outfit := -1) -> void:
	var profile := Game.settings.profile
	for landmark: LoyaltyLandmark in Loyalty.map().landmarks:
		profile.loyalty.win(landmark.id)
	Loyalty.settle(profile)
	Game.settings.set_seat_name(0, "Tail Light Tim")
	Game.settings.set_seat_color(0, 1)
	Game.settings.set_seat_style(0, PackedInt32Array([5, 2, 3, 2, 0, 0, 0]))
	if outfit >= 0 or rack >= 0:
		# Every piece seen already, so none wears NEW over the pack's.
		profile.loyalty.dress_fresh.clear()
	if outfit >= 0:
		Game.settings.set_seat_style(0, SupporterArt.dresses(outfit + 1)[outfit])
	var dialog := KartDialog.open(self)
	if rack >= 0:
		dialog.open_tray(rack, on)
		return
	# The hat rack out with the crown under the cursor, so the kart tries it on over its top hat.
	dialog.open_tray(KartStyle.PARTS.find(&"hat"), KartStyle.HATS.find("Crown"))
