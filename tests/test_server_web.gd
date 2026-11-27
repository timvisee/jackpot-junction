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


## A game's map reads as words: an id made words, a name as it is, and on a Grand Prix which map
## of how many with a slash, as the players are counted.
func test_a_games_map_reads_as_words() -> void:
	assert_str(ServerWeb.map_words("the_yard")).is_equal("The Yard")
	assert_str(ServerWeb.map_words("The Vault")).is_equal("The Vault")
	assert_str(ServerWeb.map_words("The Vault, map 1 of 2")).is_equal("The Vault, Map 1 / 2")
	assert_str(ServerWeb.map_words("")).is_equal("")


## The web port follows the game's port unless set, and 0 turns the page off.
func test_the_web_port_follows_the_game_port_unless_set() -> void:
	assert_int(ServerArgs.read(["--server"]).web()).is_equal(ServerArgs.PORT)
	assert_int(ServerArgs.read(["--port=9000"]).web()).is_equal(9000)
	assert_int(ServerArgs.read(["--port=9000", "--web-port=8080"]).web()).is_equal(8080)
	assert_int(ServerArgs.read(["--web-port=0"]).web()).is_equal(0)
	assert_str(ServerArgs.read(["--web-port=nope"]).problem()).is_not_empty()
	# The environment says it too, the way a container does.
	var from_env := ServerArgs.read([], {"JJ_WEB_PORT": "8080", "JJ_WEB_LINK": "https://play.me"})
	assert_int(from_env.web()).is_equal(8080)
	assert_str(from_env.web_link).is_equal("https://play.me")


## A GET of the page carries how to join — the Servers tab, Add a server or Direct connect, and the
## address a visitor came in by and the game's port each in a field of its own to copy — and the
## games being played.
func test_the_page_carries_how_to_join_and_the_games() -> void:
	var args := ServerArgs.read(["--server", "--name=Friday night", "--port=7777"])
	var web := ServerWeb.new()
	assert_int(web.open(0, args, func() -> Array: return [GAME])).is_equal(OK)
	var response := await _fetch(web, "GET / HTTP/1.1\r\nHost: play.example.com:8080\r\n\r\n")
	web.close()
	assert_str(response).contains("200 OK")
	assert_str(response).contains("text/html")
	assert_str(response).contains("Friday night")
	assert_str(response).contains("Play Online")
	assert_str(response).contains("Servers")
	assert_str(response).contains("Add a server")
	assert_str(response).contains("Direct connect")
	# The address it came in by, and the game's own port, each a field to copy rather than a line.
	assert_str(response).contains('<code id="address">play.example.com</code>')
	assert_str(response).contains('<code id="port">7777</code>')
	assert_str(response).contains('data-copy="address"')
	assert_str(response).contains("store.steampowered.com/app/5652730")
	assert_str(response).contains("itch.io")
	# Each opens in a tab of its own.
	assert_str(response).contains(
		'href="https://store.steampowered.com/app/5652730" target="_blank" rel="noopener"'
	)
	assert_str(response).contains("Big Game")


## The operator's own text sits at the top, its line breaks kept, and the games can be pulled in on
## their own at /games.html for the page's script to refresh without a reload.
func test_the_description_and_the_games_fragment() -> void:
	var args := ServerArgs.read(
		["--server", "--port=7777", "--web-description=Hello there.\nRule two."]
	)
	var web := ServerWeb.new()
	assert_int(web.open(0, args, func() -> Array: return [GAME])).is_equal(OK)
	var page := await _fetch(web, "GET / HTTP/1.1\r\nHost: x\r\n\r\n")
	assert_str(page).contains("Hello there.<br>Rule two.")
	assert_str(page).contains("setInterval")
	var fragment := await _fetch(web, "GET /games.html HTTP/1.1\r\nHost: x\r\n\r\n")
	web.close()
	# The fragment is the games section alone, no page round it.
	assert_str(fragment).contains("Big Game")
	assert_str(fragment).not_contains("<html")
	assert_str(fragment).not_contains("How to join")


## An address of the operator's own is shown in place of the one a visitor came in by.
func test_the_connect_address_can_be_set() -> void:
	var args := ServerArgs.read(["--server", "--port=7777", "--web-address=play.jj.example"])
	var web := ServerWeb.new()
	assert_int(web.open(0, args, func() -> Array: return [])).is_equal(OK)
	var page := await _fetch(web, "GET / HTTP/1.1\r\nHost: 1.2.3.4:8080\r\n\r\n")
	web.close()
	assert_str(page).contains('<code id="address">play.jj.example</code>')
	assert_str(page).not_contains("1.2.3.4")


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


## The footer links the notices the server carries, quietly, beside its line on updating.
func test_the_footer_links_the_licenses() -> void:
	var web := ServerWeb.new()
	assert_int(web.open(0, ServerArgs.read(["--server"]), func() -> Array: return [])).is_equal(OK)
	var page := await _fetch(web, "GET / HTTP/1.1\r\nHost: x\r\n\r\n")
	web.close()
	assert_str(page).contains("<footer>This page updates every")
	assert_str(page).contains('<a href="licenses.html">Licenses</a></footer>')


## The licenses page carries every notice, see [Licenses]: the game's own terms and its source,
## what the server is made with and whose, Godot's license, the pieces inside it with theirs, and
## each license's text folded; everything a name could carry made safe, and a way back.
func test_the_licenses_page_carries_the_notices() -> void:
	var web := ServerWeb.new()
	assert_int(web.open(0, ServerArgs.read(["--server"]), func() -> Array: return [])).is_equal(OK)
	var page := await _fetch(web, "GET /licenses.html HTTP/1.1\r\nHost: x\r\n\r\n")
	web.close()
	assert_str(page).contains("200 OK")
	assert_str(page).contains("text/html")
	assert_str(page).contains("GNU General Public License 3.0")
	assert_str(page).contains('<a href="%s">' % Credits.REPOSITORY)
	assert_str(page).contains("Copyright 2017 The Barlow Project Authors")
	assert_str(page).contains("Nicolae &quot;Xelu&quot; Berbece")
	assert_str(page).contains("Godot Engine contributors")
	for piece: Dictionary in Licenses.pieces():
		# Made safe as the page makes it: an apostrophe as its number.
		var name: String = piece["name"].xml_escape(true).replace("&apos;", "&#39;")
		assert_str(page).contains("<b>%s</b>" % name)
	assert_str(page).contains("Copyright 1996-2025, David Turner")
	for key: String in Licenses.keys(Credits.in_this_build(), Licenses.pieces()):
		assert_str(page).contains("<details><summary>%s</summary>" % Licenses.title(key))
	assert_str(page).contains('<a href="./">Back to the server</a>')


## A browser that takes gzip gets the licenses gzipped, a quarter the size and the same page.
func test_the_licenses_come_gzipped_where_asked() -> void:
	var web := ServerWeb.new()
	assert_int(web.open(0, ServerArgs.read(["--server"]), func() -> Array: return [])).is_equal(OK)
	var plain := await _raw(web, "GET /licenses.html HTTP/1.1\r\nHost: x\r\n\r\n")
	var request := "GET /licenses.html HTTP/1.1\r\nHost: x\r\nAccept-Encoding: gzip, br\r\n\r\n"
	var zipped := await _raw(web, request)
	web.close()
	var head := _head(zipped)
	assert_str(head).contains("Content-Encoding: gzip")
	assert_str(head).contains("Vary: Accept-Encoding")
	assert_str(_head(plain)).not_contains("Content-Encoding")
	var body := _body(zipped)
	assert_int(body[0]).is_equal(0x1f)
	assert_int(body[1]).is_equal(0x8b)
	assert_int(body.size()).is_less(_body(plain).size() / 2)
	assert_array(Array(body.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))).is_equal(
		Array(_body(plain))
	)


## An answer goes out a slice a frame, so no reader holds the hall however slowly it reads, and a
## reader that has not taken it all in time is let go.
func test_a_reader_that_does_not_read_is_let_go() -> void:
	var web := ServerWeb.new()
	assert_int(web.open(0, ServerArgs.read(["--server"]), func() -> Array: return [])).is_equal(OK)
	var client := StreamPeerTCP.new()
	client.connect_to_host("127.0.0.1", web._server.get_local_port())
	for _i: int in 60:
		client.poll()
		web.poll()
		if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			break
		await await_idle_frame()
	client.put_data("GET /licenses.html HTTP/1.1\r\nHost: x\r\n\r\n".to_ascii_buffer())
	for _i: int in 60:
		web.poll()
		if not web._sending.is_empty():
			break
		await await_idle_frame()
	assert_int(web._sending.size()).is_equal(1)
	assert_int(int(web._sending[0]["at"])).is_less_equal(ServerWeb.SLICE)
	var before := int(web._sending[0]["at"])
	web.poll()
	if not web._sending.is_empty():
		assert_int(int(web._sending[0]["at"]) - before).is_less_equal(ServerWeb.SLICE)
		# Long past its time, the reader is let go, the rest unsent.
		web._sending[0]["since"] = Time.get_ticks_msec() - int(ServerWeb.SEND_WAIT * 1000.0) - 1
		web.poll()
	assert_array(web._sending).is_empty()
	client.disconnect_from_host()
	web.close()


## Opens a client to [param web], sends [param request], and returns the whole response, driving
## both ends until the connection the page closes behind its answer has gone.
func _fetch(web: ServerWeb, request: String) -> String:
	return (await _raw(web, request)).get_string_from_utf8()


## The same as bytes, for an answer that is not text, as a gzipped one.
func _raw(web: ServerWeb, request: String) -> PackedByteArray:
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
		# Closed once the page has sent it all, and only once all of it is read.
		if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			if not got.is_empty():
				break
		else:
			var available := client.get_available_bytes()
			if available > 0:
				got.append_array(client.get_partial_data(available)[1])
		await await_idle_frame()
	client.disconnect_from_host()
	return got


## The head of [param response], up to the blank line, as text.
func _head(response: PackedByteArray) -> String:
	return response.get_string_from_ascii().get_slice("\r\n\r\n", 0)


## The body of [param response], after the blank line.
func _body(response: PackedByteArray) -> PackedByteArray:
	return response.slice(_head(response).length() + 4)
