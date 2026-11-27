extends GdUnitTestSuite
## The fine print on a joker's and a power-up's card, GAME.md 8.3: printed in three levels by the
## size the card shows at, kept once printed, and the card's outline bitten at its stub.


## A card sheds its fine lines in steps as it gets small.
func test_a_smaller_card_is_printed_plainer() -> void:
	assert_int(CardPrint.level_of(180.0)).is_equal(CardPrint.Level.FULL)
	assert_int(CardPrint.level_of(CardPrint.FULL_FROM)).is_equal(CardPrint.Level.FULL)
	assert_int(CardPrint.level_of(80.0)).is_equal(CardPrint.Level.PLAIN)
	assert_int(CardPrint.level_of(40.0)).is_equal(CardPrint.Level.FLAT)
	var ink := Palette.CHIP_GOLD
	var full := CardPrint.svg_of(ink, CardPrint.Level.FULL, false, false, false)
	var flat := CardPrint.svg_of(ink, CardPrint.Level.FLAT, false, false, false)
	# The rosette and the screen's dots are fine lines; flat, there are none, only shapes.
	assert_bool(full.contains('stroke-width="0.45"')).is_true()
	assert_bool(flat.contains('stroke-width="0.45"')).is_false()
	assert_int(full.count("<circle")).is_greater(flat.count("<circle") + 100)


## A rare card's screen drifts into the fountain's inks, a cursed one's has a crimson plate under
## it, and a power-up's stub is solid in its color.
func test_rare_cursed_and_items_print_their_own() -> void:
	var ink := Palette.CHIP_GOLD
	var plain := CardPrint.svg_of(ink, CardPrint.Level.FULL, false, false, false)
	var rare := CardPrint.svg_of(ink, CardPrint.Level.FULL, false, true, false)
	var cursed := CardPrint.svg_of(ink, CardPrint.Level.FULL, false, false, true)
	var item := CardPrint.svg_of(ink, CardPrint.Level.FULL, true, false, false)
	assert_str(rare).is_not_equal(plain)
	assert_bool(cursed.contains(CardPrint.CRIMSON.to_html(false))).is_true()
	assert_bool(plain.contains(CardPrint.CRIMSON.to_html(false))).is_false()
	assert_bool(plain.contains('fill-opacity="0.07"')).is_true()
	assert_bool(item.contains('fill-opacity="0.07"')).is_false()


## A print is drawn once for a look and a size, and kept.
func test_a_print_is_kept() -> void:
	var first := CardPrint.texture(Palette.CHIP_GOLD, 168.0)
	assert_object(first).is_not_null()
	assert_object(CardPrint.texture(Palette.CHIP_GOLD, 168.0)).is_same(first)
	assert_object(CardPrint.texture(Palette.CHIP_GOLD, 60.0)).is_not_same(first)


## The card's outline has a bite out of either side at its stub: no point of it lies further out
## there than the bite lets it.
func test_the_outline_is_bitten_at_the_stub() -> void:
	var shape := CardPrint.outline(0.0, 10.0)
	var left := CardPrint.WIDE
	var right := 0.0
	for point: Vector2 in shape:
		if absf(point.y - CardPrint.STUB) < 0.5:
			left = minf(left, point.x)
			right = maxf(right, point.x)
	assert_float(left).is_equal_approx(CardPrint.BITE, 0.01)
	assert_float(right).is_equal_approx(CardPrint.WIDE - CardPrint.BITE, 0.01)
	assert_bool(Geometry2D.is_point_in_polygon(Vector2(3.0, CardPrint.STUB), shape)).is_false()
	assert_bool(Geometry2D.is_point_in_polygon(Vector2(3.0, 60.0), shape)).is_true()


## A card's picture stands in the middle of the rosette printed round it, and clear of the gems
## of its rarity over the tear.
func test_the_picture_stands_in_the_rosette() -> void:
	assert_object(JokerCard.PICTURE_AT.get_center()).is_equal(CardPrint.ROSETTE)
	var gems := CardPrint.STUB - JokerCard.GEM_ABOVE - JokerCard.GEM.y
	assert_float(JokerCard.PICTURE_AT.end.y).is_less(gems)


## A card's shadow, and its glow when it is lit, has the card's own shape: the nearest of its layers
## leaves the bite out of the card's side, as a box's shadow would not, and covers the card.
func test_the_shadow_has_the_bites() -> void:
	for spread: int in [6, 18]:
		var layers := JokerCard.Body.shadow_layers(spread)
		assert_int(layers.size()).is_greater_equal(3)
		var nearest: PackedVector2Array = layers[layers.size() - 1]
		var bite := Vector2(1.5, CardPrint.STUB)
		assert_bool(Geometry2D.is_point_in_polygon(bite, nearest)).is_false()
		assert_bool(Geometry2D.is_point_in_polygon(Vector2(60.0, 60.0), nearest)).is_true()
		var farthest: PackedVector2Array = layers[0]
		var out := Vector2(-spread + 0.5, 60.0)
		assert_bool(Geometry2D.is_point_in_polygon(out, farthest)).is_true()


## The frame, drawn in from the card's edge, runs straight down its sides into the bites: every
## point of it away from the bites and the corners' rounds lies on the side, and where it meets a
## bite it is still on the side rather than out on the card's edge.
func test_the_frame_runs_straight_into_the_bites() -> void:
	var inset := 1.5
	var frame := CardPrint.outline(inset, 10.0 - inset)
	var reach := CardPrint.BITE + inset
	for point: Vector2 in frame:
		var by_bite := absf(point.y - CardPrint.STUB) < reach + 0.01
		if point.y > 10.0 and point.y < CardPrint.TALL - 10.0 and not by_bite:
			var on_left := is_equal_approx(point.x, inset)
			var on_right := is_equal_approx(point.x, CardPrint.WIDE - inset)
			assert_bool(on_left or on_right).override_failure_message(str(point)).is_true()
	for point: Vector2 in frame:
		assert_float(point.x).is_between(inset - 0.01, CardPrint.WIDE - inset + 0.01)
