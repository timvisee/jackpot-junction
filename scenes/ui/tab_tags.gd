class_name TabTags
extends Node
## The NEW tags a row of tabs wears, GAME.md 8.8: a tab wears one while something new on its page
## has not been looked at yet, hung over the tab's top right corner as a card's is over the card's,
## so that something new on another page is seen without turning to it. The catalog's pages' tabs
## wear them, and the loyalty program's sheets', see [SheetTabs]. Kept on the bar it tags.

var bar: TabBar
## Each tab's tag while it wears one, by the tab's index.
var _tags: Dictionary[int, Control] = {}


## The NEW tags of [param tabs], none worn yet.
static func on(tabs: TabBar) -> TabTags:
	var made := TabTags.new()
	made.name = "TabTags"
	made.bar = tabs
	tabs.add_child(made)
	tabs.resized.connect(made.place)
	return made


## The tag the tab [param index] wears, or null while it wears none.
func of(index: int) -> Control:
	return _tags.get(index)


## Each tab wears its tag while [param fresh] says so of it, by the tab's index, and takes it off
## once not.
func wear(fresh: Array[bool]) -> void:
	for index: int in fresh.size():
		var worn := of(index)
		if fresh[index] == (worn != null):
			continue
		if worn != null:
			_tags.erase(index)
			worn.queue_free()
			continue
		var tag := CatalogCell.new_tag()
		tag.name = "New%d" % index
		tag.set_anchors_preset(Control.PRESET_TOP_LEFT)
		tag.resized.connect(place)
		bar.add_child(tag)
		_tags[index] = tag
	# The tabs may have changed their words, and with them where their corners are.
	place.call_deferred()


## Each tag hung over its tab's top right corner, as a card's is over the card's.
func place() -> void:
	for index: int in _tags:
		var tag := _tags[index]
		if not is_instance_valid(tag) or index >= bar.tab_count:
			continue
		var tab := bar.get_tab_rect(index)
		tag.position = Vector2(
			tab.end.x + CatalogCell.NEW_OUT.x - tag.size.x, tab.position.y + CatalogCell.NEW_OUT.y
		)
