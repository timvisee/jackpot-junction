extends GdUnitTestSuite
## Kit's line scratched into the license's stripe, STORY.md 6.7: a layer of its own over the stripe,
## shown with the back, cut rather than written, its lip catching the light as the card is turned.


## There with the back and gone with the front, drawn only where the story marks the card, and told
## where the card is turned toward.
func test_the_scratch_comes_with_the_back() -> void:
	var earned: Dictionary[String, bool] = {}
	var card: LicenseCard = auto_free(
		LicenseCard.create("Ann", "JJ-212212", "2026-10-16", 0, KartStyle.new(), earned)
	)
	card.scratched = true
	add_child(card)
	await await_idle_frame()
	var lip := card.find_child("ScratchLip", false, false) as Control
	assert_object(lip).is_not_null()
	assert_bool(lip.visible).is_false()
	card.other_side()
	assert_bool(lip.visible).is_true()
	card.tilt = Vector2(0.4, -0.2)
	var shine := lip.material as ShaderMaterial
	assert_vector(shine.get_shader_parameter("tilt") as Vector2).is_equal(Vector2(0.4, -0.2))
	assert_vector(lip.position).is_equal(LicenseCard.STRIPE.position)
	card.other_side()
	assert_bool(lip.visible).is_false()
