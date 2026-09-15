extends Node
## Global game wiring. Autoloaded as `Game`.
##
## Registers the input map before any scene runs and offers a few process-wide helpers.

const VERSION := "0.0.0-dev"


func _init() -> void:
	InputActions.register_defaults()


## True when running without a display, as in tests and CI.
static func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"
