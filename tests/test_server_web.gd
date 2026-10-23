extends GdUnitTestSuite
## The dedicated server's web page, GAME.md 9.3a: a browser pointed at the server gets a page with
## how to join and the games being played, over a TCP port the hall serves by hand, see [ServerWeb].

const GAME := {
	"name": "Big Game",
	"map": "the_yard",
	"players": 3,
	"most": 8,
	"password": false,
	"lobby": true,
}


## The web port follows the game's port unless set, and 0 turns the page off.
func test_the_web_port_follows_the_game_port_unless_set() -> void:
	assert_int(ServerArgs.read(["--server"]).web()).is_equal(ServerArgs.PORT)
	assert_int(ServerArgs.read(["--port=9000"]).web()).is_equal(9000)
	assert_int(ServerArgs.read(["--port=9000", "--web-port=8080"]).web()).is_equal(8080)
	assert_int(ServerArgs.read(["--web-port=0"]).web()).is_equal(0)
	assert_str(ServerArgs.read(["--web-port=nope"]).problem()).is_not_empty()
	# The environment says it too, the way a container does.
	var from_env := ServerArgs.read([], {"JJ_WEB_PORT": "8080", "JJ_SITE": "https://play.me"})
	assert_int(from_env.web()).is_equal(8080)
	assert_str(from_env.site).is_equal("https://play.me")


## A GET of the page carries how to join, the address a visitor came in by with the game's port, and
## the games being played.
func test_the_page_carries_how_to_join_and_the_games() -> void:
	var args := ServerArgs.read(["--server", "--name=Friday night", "--port=7777"])
	var web := ServerWeb.new()
	assert_int(web.open(0, args, func() -> Array: return [GAME])).is_equal(OK)
	var response := await _fetch(web, "GET / HTTP/1.1\r\nHost: play.example:7777\r\n\r\n")
	web.close()
	assert_str(response).contains("200 OK")
	assert_str(response).contains("text/html")
	assert_str(response).contains("Friday night")
	assert_str(response).contains("Play Online")
	assert_str(response).contains("play.example port 7777")
	assert_str(response).contains("itch.io")
	assert_str(response).contains("Big Game")


## The same list is served as JSON for tools, at /status.json.
func test_the_status_json_lists_the_games() -> void:
	var args := ServerArgs.read(["--server", "--port=7777"])
	var web := ServerWeb.new()
	assert_int(web.open(0, args, func() -> Array: return [GAME])).is_equal(OK)
	var response := await _fetch(web, "GET /status.json HTTP/1.1\r\nHost: x\r\n\r\n")
	web.close()
	assert_str(response).contains("application/json")
	var body := response.substr(response.find("\r\n\r\n") + 4)
	var parsed: Variant = JSON.parse_string(body)
	assert_object(parsed).is_not_null()
	assert_int(int((parsed as Dictionary)["games_playing"])).is_equal(1)
	assert_int(((parsed as Dictionary)["games"] as Array).size()).is_equal(1)


## Anything but a GET, or a path the page does not know, is turned away rather than served.
func test_unknown_paths_and_methods_are_turned_away() -> void:
	var args := ServerArgs.read(["--server", "--port=7777"])
	var web := ServerWeb.new()
	assert_int(web.open(0, args, func() -> Array: return [])).is_equal(OK)
	assert_str(await _fetch(web, "GET /secret HTTP/1.1\r\nHost: x\r\n\r\n")).contains("404")
	assert_str(await _fetch(web, "POST / HTTP/1.1\r\nHost: x\r\n\r\n")).contains("405")
	web.close()


## Opens a client to [param web], sends [param request], and returns the whole response, driving
## both ends until the connection the page closes behind its answer has gone.
func _fetch(web: ServerWeb, request: String) -> String:
	var client := StreamPeerTCP.new()
	client.connect_to_host("127.0.0.1", web._server.get_local_port())
	for _i: int in 60:
		client.poll()
		web.poll()
		if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			break
		await await_idle_frame()
	client.put_data(request.to_ascii_buffer())
	var got := PackedByteArray()
	for _i: int in 180:
		web.poll()
		client.poll()
		var available := client.get_available_bytes()
		if available > 0:
			got.append_array(client.get_partial_data(available)[1])
		if (
			got.get_string_from_utf8().contains("</html>")
			or got.get_string_from_utf8().ends_with("\n")
		):
			if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
				break
		await await_idle_frame()
	client.disconnect_from_host()
	return got.get_string_from_utf8()
