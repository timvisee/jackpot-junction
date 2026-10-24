extends GdUnitTestSuite
## The developer's F5 cheat menu, [DebugGrantMenu]: it lists every printed joker and every item,
## and a press hands the chosen one to the human playing here. It is built only in a debug run, and
## the test runs in one.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const CATALOG: JokerCatalog = preload("res://data/jokers/catalog.tres")
const ITEMS: PowerUpTable = preload("res://data/powerups/all.tres")

var _runner: GdUnitSceneRunner


func _start_match(inputs: Array[KartInput], seed: int = 21) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, seed)
	return match_node


## Hung on the match, so the match freeing takes it too; building its UI needs it in the tree.
func _menu(match_node: Match) -> DebugGrantMenu:
	return DebugGrantMenu.add_to(match_node, match_node)


## The menu draws a button for each printed joker and each item, so there is one to press for all
## of them and no more.
func test_the_menu_lists_every_joker_and_item() -> void:
	var match_node := _start_match([KartInput.new()] as Array[KartInput])
	var menu := _menu(match_node)
	assert_object(menu).is_not_null()
	var jokers := _column_buttons(menu, 0)
	var items := _column_buttons(menu, 1)
	assert_int(jokers.size()).is_equal(CATALOG.printed().size())
	assert_int(items.size()).is_equal(ITEMS.entries.size())


## Pressing a joker's button attaches a copy of it to the local human's hand.
func test_granting_a_joker_attaches_it() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	var kart := match_node.kart_of(0)
	var before := kart.jokers.jokers.size()
	_menu(match_node)._give_joker(CATALOG.by_id(&"aimbot"))
	assert_int(kart.jokers.jokers.size()).is_equal(before + 1)
	assert_bool(kart.jokers.has(&"aimbot")).is_true()


## Pressing an item's button puts it in the local human's hand, revealed and ready to use.
func test_granting_an_item_holds_it() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	var kart := match_node.kart_of(0)
	assert_object(kart.held_item).is_null()
	_menu(match_node)._give_item(ITEMS.entries[0])
	assert_object(kart.held_item).is_same(ITEMS.entries[0])
	assert_float(kart.item_reveal_left).is_equal(0.0)


## With nobody local at the wheel the grant has no one to land on and is simply refused.
func test_a_grant_needs_a_local_player() -> void:
	var match_node := _start_match([KartInput.new()] as Array[KartInput])
	var kart := match_node.kart_of(0)
	_menu(match_node)._give_item(ITEMS.entries[0])
	assert_object(kart.held_item).is_null()


func _column_buttons(menu: DebugGrantMenu, column: int) -> Array[Node]:
	var columns := menu.find_children("", "HBoxContainer", true, false)
	if columns.is_empty() or column >= columns[0].get_child_count():
		return []
	return columns[0].get_child(column).find_children("", "Button", true, false)
