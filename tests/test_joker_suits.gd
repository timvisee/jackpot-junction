extends GdUnitTestSuite
## The jokers' suits, GAME.md 7.3, Suits: every joker's, what a hand is Suited in, and how a card
## and the pane that describes it show them.

const JOKERS: JokerCatalog = preload("res://data/jokers/catalog.tres")


func _hand(ids: Array[StringName]) -> Array[Joker]:
	var hand: Array[Joker] = []
	for id: StringName in ids:
		hand.append(JOKERS.by_id(id))
	return hand


## Every joker has its suit, as many of each as GAME.md 7.3's table has.
func test_every_joker_has_its_suit() -> void:
	var counted := {}
	for joker: Joker in JOKERS.jokers:
		counted[joker.suit] = counted.get(joker.suit, 0) + 1
	assert_int(counted.get(Joker.Suit.SPADES, 0)).is_equal(6)
	assert_int(counted.get(Joker.Suit.HEARTS, 0)).is_equal(6)
	assert_int(counted.get(Joker.Suit.DIAMONDS, 0)).is_equal(10)
	assert_int(counted.get(Joker.Suit.CLUBS, 0)).is_equal(10)
	assert_int(counted.get(Joker.Suit.WILD, 0)).is_equal(3)
	assert_int(JOKERS.by_id(&"hair_trigger").suit).is_equal(Joker.Suit.SPADES)
	assert_int(JOKERS.by_id(&"payday").suit).is_equal(Joker.Suit.DIAMONDS)


## Three of a suit is Suited in it; two are not; a wild card joins the suit held most of, the first
## in order where two are level, and counts once rather than in every suit.
func test_three_of_a_suit_is_suited_and_a_wild_card_joins_the_lead() -> void:
	assert_array(JokerSuits.suited(_hand([&"hair_trigger", &"big_tank"]))).is_empty()
	var three := _hand([&"hair_trigger", &"big_tank", &"aimbot", &"payday"])
	assert_array(JokerSuits.suited(three)).contains_exactly([Joker.Suit.SPADES])
	var level := _hand([&"payday", &"odometer", &"spare_tire", &"comeback", &"deep_pockets"])
	assert_array(JokerSuits.suited(level)).contains_exactly([Joker.Suit.HEARTS])
	assert_int(JokerSuits.leading(level)).is_equal(Joker.Suit.HEARTS)
	assert_int(JokerSuits.leading(_hand([&"deep_pockets"]))).is_equal(-1)
	# Two cards of a stack are two cards.
	var stacked := _hand([&"payday", &"payday", &"vulture"])
	assert_array(JokerSuits.suited(stacked)).contains_exactly([Joker.Suit.DIAMONDS])


## A card wears its suit in the corner across from its kind, and the pane says what three of it pay.
func test_a_card_and_its_pane_show_the_suit() -> void:
	var joker := JOKERS.by_id(&"vulture")
	var card: JokerCard = auto_free(JokerCard.create(joker))
	var mark := card.get_node("Suit") as JokerSuits.Mark
	assert_int(mark.suit).is_equal(Joker.Suit.DIAMONDS)
	assert_float(mark.position.x).is_greater(JokerCard.SIZE.x * 0.5)
	assert_str(JokerSuits.words(joker.suit)).is_equal(
		"Three Diamonds: every chip you pick up is worth one more."
	)
	assert_str(JokerSuits.words(Joker.Suit.WILD)).contains("Wild")
	var pane: JokerDetail = auto_free(JokerDetail.new())
	pane.show_joker(joker)
	assert_str(pane._suit_words.text).contains("Three Diamonds")
	pane.show_unknown("A card", "Not taken yet")
	assert_bool(pane._suit_row.visible).is_false()
