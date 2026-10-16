extends GdUnitTestSuite
## The F3 overlay, see [DebugOverlay]: the keys it says at its foot.


## F4 is said only where a tuning panel is there for it to open, which only the playground has and
## an export leaves out; F3 always.
func test_f4_is_said_only_with_a_tuning_panel() -> void:
	var overlay: DebugOverlay = auto_free(DebugOverlay.new())
	add_child(overlay)
	assert_str(overlay._keys()).is_equal("F3 overlay")
	var tuning: Node = auto_free(load("res://scenes/dev/tuning_panel.gd").new())
	add_child(tuning)
	assert_str(overlay._keys()).is_equal("F3 overlay  F4 tuning")
	remove_child(tuning)
	assert_str(overlay._keys()).is_equal("F3 overlay")
