extends GdUnitTestSuite
## What is a hello of the game's and what is garbage, GAME.md 10.3, see [NetGuard]: looked at
## before it is read.


func test_a_hello_of_the_game_is_one() -> void:
	var game := NetDoor.knock("0.11.0", false, "Ann", "")
	assert_dict(NetGuard.knock_of(var_to_bytes(game))).is_equal(game)
	assert_str(str(game[NetGuard.MAGIC_KEY])).is_equal("jackpot-junction")
	var hall := NetGuard.marked({"version": "0.11.0", "name": "Ann", ServerLink.LISTING: true})
	assert_dict(NetGuard.knock_of(var_to_bytes(hall))).is_equal(hall)
	# Another version that says what it is still says hello, and is turned away for its version.
	var other := NetGuard.marked({"version": "0.7.2", "name": "Bo"})
	assert_dict(NetGuard.knock_of(var_to_bytes(other))).is_equal(other)


## A hello without the marker, whatever version it says it is, or with another game's name in it, is
## not the game's.
func test_a_hello_without_the_marker_is_not_one() -> void:
	var bare := {"version": "0.11.0", "name": "Ann"}
	assert_dict(NetGuard.knock_of(var_to_bytes(bare))).is_empty()
	var old := {"version": "0.10.1", "name": "Bo"}
	assert_dict(NetGuard.knock_of(var_to_bytes(old))).is_empty()
	var other := {"version": "0.11.0", "name": "Ann", NetGuard.MAGIC_KEY: "some-other-game"}
	assert_dict(NetGuard.knock_of(var_to_bytes(other))).is_empty()


func test_garbage_is_not_a_hello() -> void:
	var junk := PackedByteArray()
	for i: int in 64:
		junk.append((i * 37 + 11) % 256)
	assert_dict(NetGuard.knock_of(junk)).is_empty()
	assert_dict(NetGuard.knock_of(PackedByteArray())).is_empty()
	assert_dict(NetGuard.knock_of("GET / HTTP/1.1\r\n\r\n".to_utf8_buffer())).is_empty()
	assert_dict(NetGuard.knock_of(var_to_bytes("hello"))).is_empty()
	assert_dict(NetGuard.knock_of(var_to_bytes(["version", "0.11.0"]))).is_empty()
	assert_dict(NetGuard.knock_of(var_to_bytes({"name": "Ann"}))).is_empty()
	assert_dict(NetGuard.knock_of(var_to_bytes({"version": 11}))).is_empty()
	assert_dict(NetGuard.knock_of(var_to_bytes({"version": "0.11.0", "name": [1, 2]}))).is_empty()
	var long := {"version": "0.11.0", "name": "x".repeat(NetGuard.KNOCK_BYTES)}
	assert_dict(NetGuard.knock_of(var_to_bytes(long))).is_empty()
