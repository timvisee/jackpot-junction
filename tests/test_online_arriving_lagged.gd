extends "res://tests/test_online_arriving.gd"
## Every test of [code]test_online_arriving.gd[/code] again, over a line with the round trip of a
## slow LAN, see [NetLag]: what works with no round trip at all has to work with one.


func before_test() -> void:
	super()
	NetLag.ping = 0.05
	NetLag.jitter = 0.01


func after_test() -> void:
	NetLag.ping = 0.0
	NetLag.jitter = 0.0
	super()
