extends GdUnitTestSuite
## The Steam supporter pack, GAME.md 10.8: its pieces worn only where it is owned and offered only
## in a Steam build, a debug build pretending either way; never on a bot nor the booth demo's karts;
## on the kart dialog's rack with the pack's star and night-blue tape, or dimmed and locked with
## "Supporter Pack" on the tape, opening the store page; and the lighthouse, its first piece, whose
## lamp turns, quickens while its kart cashes out and goes dark at a death.

const PATH := "user://test_supporter.cfg"

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	Supporter.dry = true
	Supporter.store_asked = 0
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	_holder = Control.new()
	add_child(_holder)


func after_test() -> void:
	Supporter.dry = false
	Supporter.start(PackedStringArray(), false, false)
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _lighthouse() -> int:
	return KartStyle.HATS.find("Lighthouse")


## A debug build reads `--supporter` as owned and `--supporter=locked` as offered and locked; with
## neither, and no Steam, the pack is neither owned nor offered.
func test_a_debug_build_pretends_either_way() -> void:
	Supporter.start(PackedStringArray(), false, false)
	assert_bool(Supporter.owned()).is_false()
	assert_bool(Supporter.offered()).is_false()
	Supporter.start(PackedStringArray(["--supporter"]), false, false)
	assert_bool(Supporter.owned()).is_true()
	assert_bool(Supporter.offered()).is_true()
	Supporter.start(PackedStringArray(["--supporter=locked"]), true, true)
	assert_bool(Supporter.owned()).is_false()
	assert_bool(Supporter.offered()).is_true()


## Without pretending, it is what Steam said at the start: a Steam build offers the pieces, owned or
## not, and a build from GitHub does not.
func test_otherwise_it_is_steams_word_at_the_start() -> void:
	Supporter.start(PackedStringArray(), true, true)
	assert_bool(Supporter.owned()).is_true()
	assert_bool(Supporter.offered()).is_true()
	Supporter.start(PackedStringArray(), false, true)
	assert_bool(Supporter.owned()).is_false()
	assert_bool(Supporter.offered()).is_true()
	Supporter.set_owned(true)
	assert_bool(Supporter.owned()).is_true()


## The pack's pieces come after the rest of their part, and are worn only where it is owned.
func test_its_pieces_are_worn_only_where_it_is_owned() -> void:
	var lighthouse := _lighthouse()
	assert_int(lighthouse).is_greater(KartStyle.HATS.find("Fez"))
	assert_bool(KartStyle.supporter(1, lighthouse)).is_true()
	assert_bool(KartStyle.supporter(1, KartStyle.HATS.find("Fez"))).is_false()
	var everything := PackedStringArray(["hat:Lighthouse"])
	assert_bool(KartStyle.allowed(1, lighthouse, everything)).is_false()
	Supporter.pretend = Supporter.Pretend.OWNED
	assert_bool(KartStyle.allowed(1, lighthouse, PackedStringArray())).is_true()
	assert_int(KartStyle.next(1, KartStyle.HATS.find("Fez"), PackedStringArray())).is_equal(
		lighthouse
	)
	Supporter.pretend = Supporter.Pretend.LOCKED
	assert_bool(KartStyle.allowed(1, lighthouse, everything)).is_false()
	assert_int(KartStyle.next(1, KartStyle.HATS.find("Fez"), PackedStringArray())).is_not_equal(
		lighthouse
	)


## A bot's dress and the booth demo's never take a piece of the pack, which on a kart always means
## a person who backed the game.
func test_never_a_bots_nor_the_demos() -> void:
	Supporter.pretend = Supporter.Pretend.OWNED
	var rng := RandomNumberGenerator.new()
	for seed_of: int in 300:
		rng.seed = seed_of
		var bot := KartStyle.random(rng)
		var demo := KartStyle.dressed_up(rng)
		for part: int in KartStyle.CHOICES.size():
			assert_bool(KartStyle.supporter(part, bot.to_array()[part])).is_false()
			assert_bool(KartStyle.supporter(part, demo.to_array()[part])).is_false()


## The rack leaves the pack's pieces out where the pack is not offered, hangs them dimmed and
## locked after those worn where it is offered and not owned, and among them where it is owned.
func test_the_rack_offers_them_as_the_pack_is() -> void:
	var lighthouse := _lighthouse()
	assert_bool(lighthouse in PartTray.order_of(1)).is_false()
	assert_int(PartTray.pack_of(1, lighthouse)).is_equal(PartTray.Pack.NONE)
	Supporter.pretend = Supporter.Pretend.LOCKED
	assert_bool(lighthouse in PartTray.order_of(1)).is_true()
	assert_int(PartTray.pack_of(1, lighthouse)).is_equal(PartTray.Pack.LOCKED)
	Supporter.pretend = Supporter.Pretend.OWNED
	assert_int(PartTray.pack_of(1, lighthouse)).is_equal(PartTray.Pack.OWNED)
	assert_int(PartTray.pack_of(1, KartStyle.HATS.find("Fez"))).is_equal(PartTray.Pack.NONE)


## In the kart dialog a locked piece hangs with its picture and "Supporter Pack" on its tape, is
## tried on under the cursor, and is not worn when pressed; owned, it is worn.
func test_the_dialog_tries_a_locked_piece_and_wears_an_owned_one() -> void:
	Supporter.pretend = Supporter.Pretend.LOCKED
	var lighthouse := _lighthouse()
	var dialog := KartDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	dialog.open_tray(1)
	await get_tree().process_frame
	var cell := dialog.tray.cell_at(lighthouse)
	assert_object(cell).is_not_null()
	assert_bool(cell.owned).is_false()
	assert_int(cell.pack).is_equal(PartTray.Pack.LOCKED)
	assert_str(cell.tape_words()).is_equal(PartTray.SUPPORTER_PACK)
	dialog._try(lighthouse)
	assert_int(dialog.stage.shown.hat).is_equal(lighthouse)
	dialog._choose(lighthouse)
	assert_int(dialog.kart_owner().style().hat).is_not_equal(lighthouse)
	assert_int(Supporter.store_asked).is_equal(1)
	dialog.queue_free()
	await get_tree().process_frame
	Supporter.pretend = Supporter.Pretend.OWNED
	dialog = KartDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	dialog.open_tray(1)
	await get_tree().process_frame
	cell = dialog.tray.cell_at(lighthouse)
	assert_bool(cell.owned).is_true()
	assert_int(cell.pack).is_equal(PartTray.Pack.OWNED)
	assert_str(cell.tape_words()).is_equal("Lighthouse")
	dialog._choose(lighthouse)
	assert_int(dialog.kart_owner().style().hat).is_equal(lighthouse)
	dialog.queue_free()


## The lighthouse is built with its lamp, its beam marked as light, which a finish and a picture
## leave out; the roof marker clears its cap.
func test_the_lighthouse_is_built() -> void:
	var hat: Node3D = auto_free(KartDress.hat(_lighthouse(), Color.RED))
	assert_object(hat).is_not_null()
	var lamps := hat.find_children("*", "LighthouseLamp", true, false)
	assert_int(lamps.size()).is_equal(1)
	var lamp := lamps[0] as LighthouseLamp
	assert_bool(SupporterDress.is_light(lamp.beam)).is_true()
	assert_bool(SupporterDress.is_light(lamp.halo)).is_true()
	assert_bool(SupporterDress.is_light(lamp.bulb)).is_false()
	KartDress.wear_finish(hat, 1)
	assert_object((lamp.beam.material_override as BaseMaterial3D).next_pass).is_null()
	assert_object((lamp.bulb.material_override as BaseMaterial3D).next_pass).is_not_null()
	var bounds := DressPicture.bounds_of(hat, false)
	assert_float(bounds.size.z).is_less(1.0)
	assert_float(SupporterDress.hat_lift("Lighthouse")).is_greater_equal(
		bounds.end.y / KartDress.HAT_SCALE - 0.05
	)


## Its lamp turns, quicker while its kart cashes out; goes dark at a death and warms back up, never
## at once; and under fewer flashes holds still, pointing ahead.
func test_the_lamp_turns_and_goes_dark() -> void:
	var hat: Node3D = auto_free(KartDress.hat(_lighthouse(), Color.RED))
	add_child(hat)
	var lamp := hat.find_children("*", "LighthouseLamp", true, false)[0] as LighthouseLamp
	lamp.set_process(false)
	lamp.step(0.1, true, false)
	var slow := lamp.head.rotation.y
	lamp.head.rotation.y = 0.0
	lamp.step(0.1, true, true)
	assert_float(lamp.head.rotation.y).is_greater(slow)
	lamp.step(1.0, false, false)
	assert_float(lamp.light).is_equal(0.0)
	assert_float((lamp.beam.material_override as StandardMaterial3D).albedo_color.a).is_equal(0.0)
	lamp.step(0.3, true, false)
	assert_float(lamp.light).is_between(0.1, 0.9)
	Game.settings.flash_reduction = true
	lamp.step(0.5, true, false)
	assert_float(lamp.head.rotation.y).is_equal(0.0)
	remove_child(hat)


## The halo is a ring of warm white light over the helmet with a faint glow, never gold, which
## brightens a little at a cash-out but not under fewer flashes; the roof marker clears it.
func test_the_halo_is_built_and_brightens() -> void:
	var hat: Node3D = auto_free(KartDress.hat(KartStyle.HATS.find("Halo"), Color.RED))
	add_child(hat)
	var ring := hat.find_child("Halo", true, false) as MeshInstance3D
	assert_object(ring).is_not_null()
	var paint := ring.material_override as StandardMaterial3D
	assert_float(paint.albedo_color.b).is_greater(0.7)
	var shine := hat.find_children("*", "DressLight", true, false)[0] as DressLight
	shine.set_process(false)
	var resting := (ring.material_override as StandardMaterial3D).emission_energy_multiplier
	shine.step(1.0, true, true)
	var flaring := (ring.material_override as StandardMaterial3D).emission_energy_multiplier
	assert_float(flaring).is_greater(resting)
	Game.settings.flash_reduction = true
	shine.step(1.0, true, true)
	var calm := (ring.material_override as StandardMaterial3D).emission_energy_multiplier
	assert_float(calm).is_equal_approx(resting, 0.001)
	# The ring's top: its height, half its tube, and as far as its tip lifts its far edge.
	var tube := (SupporterDress.HALO_OUTER - SupporterDress.HALO_INNER) * 0.5
	var tipped := sin(deg_to_rad(absf(SupporterDress.HALO_TIP.x))) * SupporterDress.HALO_OUTER
	assert_float(KartDress.hat_lift(KartStyle.HATS.find("Halo"))).is_greater(
		(SupporterDress.HALO_HEIGHT + tube + tipped) * KartDress.HAT_SCALE
	)
	remove_child(hat)


## The lantern stands in the kart's back as a flag's pole does, its rod reaching down into the
## kart, and hangs from the rod's tip on a pivot the sway swings as dice on a string; its glow and
## the pool on the felt are light; it goes out at a death.
func test_the_lantern_hangs_from_its_rod_and_goes_out() -> void:
	var flag: Node3D = auto_free(KartDress.flag(KartStyle.FLAGS.find("Lantern"), Color.BLUE))
	add_child(flag)
	var held := flag.get_node("Lantern") as Node3D
	var sway := flag.get_node("Sway") as DressSway
	assert_int(sway.kind).is_equal(DressSway.Kind.DICE)
	assert_array(sway.pivots).contains_exactly([held])
	var rod_foot := INF
	for child: Node in flag.get_children():
		if child is MeshInstance3D and not SupporterDress.is_light(child):
			var rod := child as MeshInstance3D
			rod_foot = minf(rod_foot, rod.position.y - (rod.mesh as CylinderMesh).height * 0.5)
	assert_float(rod_foot).is_less_equal(-KartDress.POLE * 0.5 + 0.01)
	var paper := held.get_node("Paper") as MeshInstance3D
	var pool := flag.get_node("Pool") as MeshInstance3D
	assert_bool(SupporterDress.is_light(pool)).is_true()
	var shine := flag.get_node("Shine") as DressLight
	shine.set_process(false)
	shine.step(1.0, false, false)
	var unlit := (paper.material_override as StandardMaterial3D).emission_energy_multiplier
	assert_float(unlit).is_equal(0.0)
	assert_float((pool.material_override as StandardMaterial3D).albedo_color.a).is_equal(0.0)
	remove_child(flag)


## The pinwheel's wheel turns with the kart's speed, its six vanes there at a crawl and run
## together into the pale disc at speed; still when the kart is.
func test_the_pinwheel_turns_and_blurs_with_speed() -> void:
	var flag: Node3D = auto_free(KartDress.flag(KartStyle.FLAGS.find("Pinwheel"), Color.BLUE))
	add_child(flag)
	var spin := flag.get_node("Spin") as PinwheelSpin
	spin.set_process(false)
	assert_int(spin.vanes.size()).is_equal(6)
	spin.step(0.1, 0.0)
	assert_float(spin.wheel.rotation.z).is_equal(0.0)
	assert_bool(spin.blur.visible).is_false()
	for i: int in 30:
		spin.step(0.1, 2.0)
	assert_float(spin.wheel.rotation.z).is_not_equal(0.0)
	assert_bool(spin.vanes[0].visible).is_true()
	for i: int in 30:
		spin.step(0.1, 9.0)
	assert_bool(spin.blur.visible).is_true()
	assert_bool(spin.vanes[0].visible).is_false()
	remove_child(flag)


## Stardust is twinkles that hang rather than fly, on the particles every trail is; the prism is no
## particles but a ribbon, laid where the exhaust goes, let go after its life, started again after
## a jump, and gone when the trail is another.
func test_the_trails_are_stardust_and_a_ribbon() -> void:
	var stardust := ExhaustSmoke.new()
	stardust.dress(Color.RED, KartStyle.TRAILS.find("Stardust"))
	add_child(stardust)
	assert_bool(stardust.emitting).is_true()
	assert_object(stardust.ribbon).is_null()
	var process := stardust.process_material as ParticleProcessMaterial
	assert_float(process.initial_velocity_max).is_less(0.5)
	var look := (stardust.draw_pass_1 as QuadMesh).material as StandardMaterial3D
	assert_int(look.billboard_mode).is_equal(BaseMaterial3D.BILLBOARD_PARTICLES)
	remove_child(stardust)
	stardust.free()
	var prism := ExhaustSmoke.new()
	prism.dress(Color.RED, KartStyle.TRAILS.find("Prism"))
	add_child(prism)
	assert_bool(prism.emitting).is_false()
	var ribbon := prism.ribbon
	assert_object(ribbon).is_not_null()
	ribbon.set_process(false)
	for i: int in 5:
		ribbon.step(0.05, Vector3(0.3 * i, 0.0, 0.0))
	assert_int(ribbon.length()).is_equal(5)
	ribbon.step(PrismRibbon.LIFE + 0.5, Vector3(1.6, 0.0, 0.0))
	assert_int(ribbon.length()).is_equal(1)
	ribbon.step(0.05, Vector3(20.0, 0.0, 0.0))
	assert_int(ribbon.length()).is_equal(1)
	prism.dress(Color.RED, 0)
	assert_object(prism.ribbon).is_null()
	assert_bool(prism.emitting).is_true()
	remove_child(prism)
	prism.free()


## The house of cards stands three storeys on a kart only to look at, one for a small pot and
## more as it grows; collapses at a death and stands again at the respawn; and folds into a deck
## at a cash-out, then builds again.
func test_the_house_of_cards_answers_to_the_pot() -> void:
	var hat: Node3D = auto_free(KartDress.hat(KartStyle.HATS.find("House of cards"), Color.RED))
	add_child(hat)
	var house := hat.find_children("*", "HouseOfCards", true, false)[0] as HouseOfCards
	house.set_process(false)
	assert_int(house.storeys).is_equal(HouseOfCards.MOST)
	assert_int(house.cards.multimesh.visible_instance_count).is_equal(HouseOfCards.MOST_CARDS)
	house.observe(0.1, true, false, 10.0, 1)
	assert_int(house.storeys).is_equal(1)
	assert_int(house.cards.multimesh.visible_instance_count).is_equal(2)
	house.observe(0.1, true, false, house.worth + 1.0, 30)
	assert_int(house.storeys).is_equal(2)
	house.observe(0.1, false, false, 0.0, 0)
	assert_int(house.state).is_equal(HouseOfCards.State.FALLING)
	house.observe(HouseOfCards.FALL + 0.1, false, false, 0.0, 0)
	assert_int(house.cards.multimesh.visible_instance_count).is_equal(0)
	house.observe(0.1, true, false, 0.0, 0)
	assert_int(house.state).is_equal(HouseOfCards.State.STANDING)
	assert_int(house.cards.multimesh.visible_instance_count).is_equal(2)
	house.observe(0.1, true, false, house.worth + 1.0, 30)
	house.observe(0.1, true, true, house.worth + 1.0, 30)
	house.observe(0.1, true, false, 0.0, 0)
	assert_int(house.state).is_equal(HouseOfCards.State.FOLDING)
	house.observe(HouseOfCards.FOLD + HouseOfCards.HOLD + 0.1, true, false, 0.0, 0)
	assert_int(house.state).is_equal(HouseOfCards.State.STANDING)
	assert_int(house.storeys).is_equal(1)
	remove_child(hat)


## The lucky cat's body is one mesh and its paws two; it waves, quicker after chips, cheers with
## both paws while cashing out and covers its eyes while dead.
func test_the_lucky_cat_waves_cheers_and_hides() -> void:
	var hat: Node3D = auto_free(KartDress.hat(KartStyle.HATS.find("Lucky cat"), Color.BLUE))
	add_child(hat)
	var cat := hat.find_children("*", "LuckyCat", true, false)[0] as LuckyCat
	cat.set_process(false)
	assert_int(cat.cat.find_children("*", "MeshInstance3D", true, false).size()).is_equal(3)
	cat.observe(0.1, true, false, 10.0, 1)
	cat.observe(0.1, true, false, 20.0, 3)
	assert_float(cat._eager).is_greater(0.0)
	for i: int in 30:
		cat.observe(0.1, true, true, 20.0, 3)
	assert_float(cat.waving.rotation.z).is_equal_approx(LuckyCat.CHEER.x, 0.05)
	for i: int in 30:
		cat.observe(0.1, false, false, 0.0, 0)
	assert_float(cat.waving.rotation.x).is_equal_approx(LuckyCat.OVER_EYES.y, 0.05)
	remove_child(hat)


## The tip jar is full on a kart only to look at, holds a few chips for an empty pot and fills as
## it grows; tips its chips out at a cash-out and fills again, and spills them at a death.
func test_the_tip_jar_fills_and_tips() -> void:
	var hat: Node3D = auto_free(KartDress.hat(KartStyle.HATS.find("Tip jar"), Color.BLUE))
	add_child(hat)
	var jar := hat.find_children("*", "TipJar", true, false)[0] as TipJar
	jar.set_process(false)
	assert_int(jar.held).is_equal(TipJar.MOST)
	jar.observe(0.1, true, false, 0.0, 0)
	assert_int(jar.held).is_equal(TipJar.LEAST)
	jar.observe(0.1, true, false, jar.full, 40)
	assert_int(jar.held).is_equal(TipJar.MOST)
	jar.observe(0.1, true, true, jar.full, 40)
	jar.observe(0.1, true, false, 0.0, 0)
	jar.observe(TipJar.FLY + 0.1, true, false, 0.0, 0)
	assert_int(jar.held).is_equal(TipJar.LEAST)
	jar.observe(0.1, false, false, 0.0, 0)
	jar.observe(TipJar.FLY + 0.1, false, false, 0.0, 0)
	assert_int(jar.chips.multimesh.visible_instance_count).is_equal(0)
	jar.observe(0.1, true, false, 0.0, 0)
	assert_int(jar.held).is_equal(TipJar.LEAST)
	remove_child(hat)


## The pack's three card backs are backs like the rest, drawn by [SupporterBacks], each with its
## picture for the table; worn only where the pack is owned, and on the rack as the dress is.
func test_the_card_backs_are_worn_as_the_pack_is() -> void:
	assert_int(Surfaces.CARD_BACKS.size()).is_equal(CardBack.STYLES.size())
	assert_int(Surfaces.CARD_BACK_FILES.size()).is_equal(CardBack.STYLES.size())
	for back: int in CardBack.SUPPORTER:
		assert_str(CardBack.STYLES[back]).is_equal(
			SupporterBacks.NAMES[CardBack.SUPPORTER.find(back)]
		)
		var card: CardBack = auto_free(CardBack.new(back, false))
		assert_int((card.get_node("Face") as CardBack.Face).supporter).is_equal(
			CardBack.SUPPORTER.find(back)
		)
	var beacon := CardBack.STYLES.find("Beacon")
	Game.settings.profile.loyalty.card_back = beacon
	assert_int(CardBack.worn()).is_equal(0)
	assert_int(PartTray.pack_of(KartDialog.CARD_BACK, beacon)).is_equal(PartTray.Pack.NONE)
	Supporter.pretend = Supporter.Pretend.LOCKED
	assert_int(CardBack.worn()).is_equal(0)
	assert_int(PartTray.pack_of(KartDialog.CARD_BACK, beacon)).is_equal(PartTray.Pack.LOCKED)
	assert_bool(beacon in PartTray.order_of(KartDialog.CARD_BACK)).is_true()
	Supporter.pretend = Supporter.Pretend.OWNED
	assert_int(CardBack.worn()).is_equal(beacon)
	assert_int(PartTray.pack_of(KartDialog.CARD_BACK, beacon)).is_equal(PartTray.Pack.OWNED)


## The night sky is the plain paint with the sky's tones on it, never darker than any paint may
## go, and its stars glowing; a finish lies over it as over any paint; on the rack it has its patch.
func test_the_night_sky_paint() -> void:
	var sky := KartStyle.PAINTS.find("Night sky")
	assert_bool(KartStyle.supporter(0, sky)).is_true()
	var style := KartStyle.new()
	style.paint = sky
	style.finishes[0] = 2
	var paint := KartDress.paint(Color.BLUE, style)
	assert_object(paint.albedo_texture).is_same(SupporterPaint.sky())
	assert_bool(paint.emission_enabled).is_true()
	assert_object(paint.emission_texture).is_same(SupporterPaint.stars())
	# Only the stars glow: the color times the texture, not added to it.
	assert_int(paint.emission_operator).is_equal(BaseMaterial3D.EMISSION_OP_MULTIPLY)
	assert_object(paint.next_pass).is_same(KartDress.finish_material(2))
	var tones := SupporterPaint.sky().get_image()
	var darkest := 1.0
	for y: int in range(0, tones.get_height(), 4):
		for x: int in range(0, tones.get_width(), 4):
			darkest = minf(darkest, tones.get_pixel(x, y).r)
	assert_float(darkest).is_greater_equal(KartDress.SHADE)


## Starlight is a finish past the editions', worn on a piece whose switch is on where the pack is
## owned, in place of its edition while it is; it survives the numbers a style is sent as, is kept
## with the profile, and is named on the rack.
func test_starlight_is_a_finish_of_its_own() -> void:
	var profile := Game.settings.profile
	profile.loyalty.editions["hat:Fedora"] = 2
	profile.loyalty.starlit = PackedStringArray(["hat:Fedora"])
	assert_int(Loyalty.worn_finish(profile, "hat:Fedora")).is_equal(2)
	Supporter.pretend = Supporter.Pretend.OWNED
	assert_int(Loyalty.worn_finish(profile, "hat:Fedora")).is_equal(Loyalty.STARLIGHT)
	assert_int(Loyalty.finish_of(profile, "hat:Fedora")).is_equal(2)
	assert_str(Loyalty.finish_name(Loyalty.STARLIGHT)).is_equal("Starlight")
	assert_str(Loyalty.finish_name(1)).is_equal("Foil")
	var style := KartStyle.new()
	style.hat = KartStyle.HATS.find("Fedora")
	style.finishes[1] = Loyalty.STARLIGHT
	assert_int(KartStyle.from_array(style.to_array()).finish(1)).is_equal(Loyalty.STARLIGHT)
	assert_object(KartDress.finish_material(Loyalty.STARLIGHT)).is_not_null()
	var file := ConfigFile.new()
	profile.loyalty.write(file)
	var again := LoyaltyState.new()
	again.read(file)
	assert_array(Array(again.starlit)).contains_exactly(["hat:Fedora"])


## The rack of a part whose worn piece takes a finish has the Starlight switch where the pack is
## owned; turned on, the piece is worn in Starlight, its hook says so, and turned off it is back.
func test_the_starlight_switch_on_the_rack() -> void:
	Game.settings.set_seat_style(0, PackedInt32Array([0, KartStyle.HATS.find("Cap"), 0, 0, 0, 0]))
	var dialog := KartDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	dialog.open_tray(1)
	await get_tree().process_frame
	assert_bool(dialog.tray.starlight.visible).is_false()
	dialog.close_tray()
	dialog.queue_free()
	await get_tree().process_frame
	Supporter.pretend = Supporter.Pretend.OWNED
	dialog = KartDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	dialog.open_tray(1)
	await get_tree().process_frame
	assert_bool(dialog.tray.starlight.visible).is_true()
	assert_bool(dialog.tray.starlight_on).is_false()
	dialog.toggle_starlight()
	await get_tree().process_frame
	assert_bool(dialog.tray.starlight_on).is_true()
	assert_int(dialog.kart_owner().style().finish(1)).is_equal(Loyalty.STARLIGHT)
	assert_str(dialog.hooks[1].finish_word).is_equal("Starlight")
	dialog.toggle_starlight()
	await get_tree().process_frame
	assert_int(dialog.kart_owner().style().finish(1)).is_equal(0)
	dialog.open_tray(6)
	await get_tree().process_frame
	assert_bool(dialog.tray.starlight.visible).is_false()
	dialog.queue_free()


## A plate may hold the supporter's star where the pack is owned, typed as an asterisk or as the
## star itself and kept as the asterisk; one off the wire keeps it whoever owns what.
func test_the_plate_star() -> void:
	assert_str(LicensePlate.clean("tim*7")).is_equal("TIM7")
	assert_str(LicensePlate.valid("TIM*7")).is_equal("TIM*7")
	Supporter.pretend = Supporter.Pretend.OWNED
	assert_str(LicensePlate.clean("tim*7")).is_equal("TIM*7")
	assert_str(LicensePlate.clean("tim★7")).is_equal("TIM*7")
	assert_str(LicensePlate.clean("**********")).is_equal("********")


## The license carries the supporter's endorsement where the pack is owned, dated the day it was
## first seen here, which is kept; and none where it is not.
func test_the_license_endorsement() -> void:
	var card: LicenseCard = auto_free(LicenseCard.from_settings())
	assert_str(card.supporter_since).is_empty()
	assert_str(Game.settings.supporter_since).is_empty()
	Supporter.pretend = Supporter.Pretend.OWNED
	card = auto_free(LicenseCard.from_settings())
	assert_str(card.supporter_since).is_equal(LicenseCard.today())
	assert_str(Game.settings.supporter_since).is_equal(LicenseCard.today())
	Game.settings.supporter_since = "2026-11-21"
	card = auto_free(LicenseCard.from_settings())
	assert_str(card.supporter_since).is_equal("2026-11-21")
