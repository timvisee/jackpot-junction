extends GdUnitTestSuite
## Pictures drawn once a run, GAME.md 10.7, see [KeptPictures]: a host that goes before its drawing
## is done takes the drawing with it, and whoever waits on it is told to ask again rather than
## waiting for the rest of the run, as the catalog's NEW tags did once the first of them went.

const GROUP := &"test_kept_pictures_waiting"
const KEY := "test_kept_pictures|8|8"


## A node waiting on a picture, counting how often it is told to ask again.
class Waiting:
	extends Node

	var told := 0

	func ask_again() -> void:
		told += 1


func after_test() -> void:
	KeptPictures._drawing.erase(KEY)
	KeptPictures._told.erase(KEY)
	KeptPictures._drawing.erase(KEY + "b")
	KeptPictures._told.erase(KEY + "b")


## The host goes: its drawings are dropped, and the waiting are told, once each picture, once it
## has gone; a drawing of another host's is left alone.
func test_a_host_going_has_the_waiting_ask_again() -> void:
	var host := auto_free(Node.new()) as Node
	var other := auto_free(Node.new()) as Node
	var waiting := auto_free(Waiting.new()) as Waiting
	waiting.add_to_group(GROUP)
	add_child(waiting)
	add_child(host)
	add_child(other)
	KeptPictures._drawing[KEY] = host
	KeptPictures._told[KEY] = [GROUP, &"ask_again"]
	KeptPictures._drawing[KEY + "b"] = other
	KeptPictures._told[KEY + "b"] = [GROUP, &"ask_again"]
	KeptPictures._host_gone(host)
	assert_bool(KeptPictures._drawing.has(KEY)).is_false()
	assert_bool(KeptPictures._told.has(KEY)).is_false()
	assert_object(KeptPictures._drawing.get(KEY + "b")).is_same(other)
	# Told once it has gone, not while it is still going.
	assert_int(waiting.told).is_equal(0)
	await get_tree().process_frame
	assert_int(waiting.told).is_equal(1)


## A host whose drawings are done is nothing to anyone as it goes.
func test_a_host_with_nothing_drawing_tells_no_one() -> void:
	var host := auto_free(Node.new()) as Node
	var waiting := auto_free(Waiting.new()) as Waiting
	waiting.add_to_group(GROUP)
	add_child(waiting)
	KeptPictures._host_gone(host)
	await get_tree().process_frame
	assert_int(waiting.told).is_equal(0)


## A thing squeezed flat for a moment is drawn for the size it opens to, the larger of its two ways,
## not for a sliver it would keep: the driving school's book swings its pages open from nothing
## across, and the mark on its title page was drawn eight pixels wide and stretched.
func test_a_thing_squeezed_flat_is_drawn_for_its_full_size() -> void:
	var holder: Control = auto_free(Control.new())
	add_child(holder)
	holder.scale = Vector2(0.02, 1.0)
	var mark := Control.new()
	holder.add_child(mark)
	var flat := KeptPictures.scale_of(mark)
	holder.scale = Vector2.ONE
	assert_float(flat).is_equal_approx(KeptPictures.scale_of(mark), 0.0001)
