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
