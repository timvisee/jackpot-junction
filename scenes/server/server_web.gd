class_name ServerWeb
extends RefCounted
## A dedicated server's web page, GAME.md 9.3a: a plain HTML page a browser reaches over HTTP, so
## anybody pointed at the server sees what it is, how to join, and the games being played on it
## now. Served from the hall's own process on its own TCP port, see [member ServerArgs.web_port]. It
## is UDP that the game is on, so one number serves both. The hall polls it every frame, see
## [method poll].
##
## No framework and no files: a [TCPServer] takes the connections and the HTTP is written out by
## hand, one small GET answered per connection and the connection closed, nothing read off the disk
## and no path followed, since this is open to the whole internet. A request that floods or dawdles
## is dropped.

## The links the page always carries to get the game, beside whatever the operator adds with
## [member ServerArgs.site]. Steam is empty until the game is on it, and left out while it is.
const ITCH := "https://timvisee.itch.io/jackpot-junction"
const GITHUB := "https://github.com/timvisee/jackpot-junction"
const STEAM := ""
## How often the page refreshes itself, in seconds, so a list left open keeps up with the games.
const REFRESH := 5
## The most connections waited on at once, the most bytes a request may run to before it is dropped,
## and how long it has to arrive in full, in seconds: a slow or a flooding client is let go.
const MOST_WAITING := 24
const REQUEST_CAP := 8192
const REQUEST_WAIT := 3.0

## How the server was started, for what the page says, and what the games list returns, see
## [method ServerHall.listing].
var args: ServerArgs
var games: Callable

var _server := TCPServer.new()
## Each connection waited on: its peer, what has come in so far, and when it knocked, in msec.
var _waiting: Array[Dictionary] = []


## Opens the page on [param port], saying what [param of] holds and listing what [param listing]
## returns, on every address of the machine as the games are.
func open(port: int, of: ServerArgs, listing: Callable) -> Error:
	args = of
	games = listing
	return _server.listen(port)


func close() -> void:
	for waiting: Dictionary in _waiting:
		(waiting["peer"] as StreamPeerTCP).disconnect_from_host()
	_waiting.clear()
	if _server.is_listening():
		_server.stop()


## Takes the new connections and reads what has come in on the old, answering a request once its
## head is whole and dropping one that floods or dawdles. Called every frame by the hall.
func poll() -> void:
	var now := Time.get_ticks_msec()
	while _server.is_connection_available():
		var peer := _server.take_connection()
		if _waiting.size() >= MOST_WAITING:
			peer.disconnect_from_host()
		else:
			_waiting.append({"peer": peer, "in": PackedByteArray(), "since": now})
	var still: Array[Dictionary] = []
	for waiting: Dictionary in _waiting:
		if not _served(waiting, now):
			still.append(waiting)
	_waiting = still


## Whether [param waiting] is done with — its request answered, or the connection dropped. Reads
## what has arrived and answers once the request's head, up to the blank line, is whole.
func _served(waiting: Dictionary, now: int) -> bool:
	var peer: StreamPeerTCP = waiting["peer"]
	peer.poll()
	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return true
	var coming: PackedByteArray = waiting["in"]
	var available := peer.get_available_bytes()
	if available > 0:
		var got := peer.get_partial_data(available)
		if got[0] == OK:
			coming.append_array(got[1])
	if coming.size() > REQUEST_CAP:
		_answer(peer, 400, "text/plain", "The request is too long.\n")
		return true
	var text := coming.get_string_from_ascii()
	if text.contains("\r\n\r\n"):
		_handle(peer, text)
		return true
	if now - int(waiting["since"]) > int(REQUEST_WAIT * 1000.0):
		peer.disconnect_from_host()
		return true
	return false


## Answers the request in [param text] on [param peer]: a GET of a path the page knows, or 404, and
## nothing but GET at all.
func _handle(peer: StreamPeerTCP, text: String) -> void:
	var lines := text.split("\r\n")
	var request := lines[0].split(" ")
	if request.size() < 3 or request[0] != "GET":
		_answer(peer, 405, "text/plain", "Only GET is served here.\n")
		return
	var path := request[1].get_slice("?", 0)
	var host := ""
	for i: int in range(1, lines.size()):
		if lines[i].to_lower().begins_with("host:"):
			host = lines[i].substr(5).strip_edges()
			break
	if path == "/" or path == "/index.html":
		_answer(peer, 200, "text/html; charset=utf-8", _html(host))
	elif path == "/status.json":
		_answer(peer, 200, "application/json", _json())
	elif path == "/health":
		_answer(peer, 200, "text/plain", "ok\n")
	else:
		_answer(peer, 404, "text/plain", "Not found.\n")


## Writes the HTTP response on [param peer] and closes it: one GET, one answer, connection done.
func _answer(peer: StreamPeerTCP, code: int, kind: String, body: String) -> void:
	var said := {200: "OK", 400: "Bad Request", 404: "Not Found", 405: "Method Not Allowed"}
	var payload := body.to_utf8_buffer()
	var head := PackedStringArray(
		[
			"HTTP/1.1 %d %s" % [code, str(said.get(code, "OK"))],
			"Content-Type: %s" % kind,
			"Content-Length: %d" % payload.size(),
			"Connection: close",
			"Cache-Control: no-store",
			"\r\n",
		]
	)
	peer.put_data("\r\n".join(head).to_ascii_buffer())
	peer.put_data(payload)
	peer.disconnect_from_host()


## The hostname a visitor came in by, from the request's Host header, without the web page's port,
## or empty where there was none: the address to tell them to enter, the game's port being another.
func _address(host: String) -> String:
	if host.is_empty():
		return ""
	if host.begins_with("["):
		var close := host.find("]")
		return host.substr(0, close + 1) if close > 0 else host
	return host.get_slice(":", 0)


## The page itself, for a visitor who came in by [param host].
func _html(host: String) -> String:
	var name := args.name if not args.name.is_empty() else "Jackpot Junction"
	var address := _address(host)
	var where := (
		"%s port %d" % [address, args.port]
		if not address.is_empty()
		else "this server's address, port %d" % args.port
	)
	var list: Array = games.call() if games.is_valid() else []
	var out := PackedStringArray()
	out.append("<!doctype html>")
	out.append('<html lang="en"><head><meta charset="utf-8">')
	out.append('<meta name="viewport" content="width=device-width, initial-scale=1">')
	out.append('<meta http-equiv="refresh" content="%d">' % REFRESH)
	out.append("<title>%s</title>" % _escape(name))
	out.append("<style>%s</style></head><body><main>" % _style())
	out.append("<h1>%s</h1>" % _escape(name))
	out.append('<p class="sub">Jackpot Junction %s dedicated server</p>' % _escape(_version()))
	out.append('<section class="card"><h2>How to join</h2><ol>')
	out.append("<li>Get the game below, and open it.</li>")
	out.append("<li>Choose <b>Play Online</b>.</li>")
	out.append("<li>Enter <b>%s</b>.</li>" % _escape(where))
	if not args.password.is_empty():
		out.append("<li>Give the server's password when it asks.</li>")
	out.append("</ol>%s</section>" % _links())
	out.append('<section class="card"><h2>%s</h2>%s</section>' % [_heading(list), _list(list)])
	out.append("<footer>This page refreshes every %d seconds.</footer>" % REFRESH)
	out.append("</main></body></html>")
	return "\n".join(out)


## The links to get the game: the two it always carries, Steam once it is there, and the operator's
## own last, see [member ServerArgs.site].
func _links() -> String:
	var links: Array[Array] = [["Get it on itch.io", ITCH], ["Source on GitHub", GITHUB]]
	if not STEAM.is_empty():
		links.append(["Get it on Steam", STEAM])
	if not args.site.is_empty():
		links.append([args.site, args.site])
	var out := PackedStringArray(['<p class="links">'])
	for link: Array in links:
		out.append('<a href="%s">%s</a>' % [_escape(str(link[1])), _escape(str(link[0]))])
	out.append("</p>")
	return "".join(out)


## What the games section is headed, by how many are being played.
func _heading(list: Array) -> String:
	if list.is_empty():
		return "No games yet"
	return "1 game" if list.size() == 1 else "%d games" % list.size()


## The games being played, as a table, or a line saying there are none.
func _list(list: Array) -> String:
	if list.is_empty():
		return '<p class="empty">Nobody is playing right now. Be the first.</p>'
	var out := PackedStringArray(["<table><thead><tr>"])
	for head: String in ["Game", "Map", "Players", ""]:
		out.append("<th>%s</th>" % head)
	out.append("</tr></thead><tbody>")
	for game: Dictionary in list:
		out.append(_row(game))
	out.append("</tbody></table>")
	return "".join(out)


## One game's row: its name, its map, how many are in it of how many it holds, and whether it is in
## the lobby or being played, with a lock where it needs a password of its own.
func _row(game: Dictionary) -> String:
	# A padlock as its HTML number, so no odd character has to survive the source to the page.
	var lock := " &#128274;" if bool(game.get("password", false)) else ""
	var who := "%d / %d" % [int(game.get("players", 0)), int(game.get("most", 0))]
	var state := "In the lobby" if bool(game.get("lobby", false)) else "Playing"
	var cells := PackedStringArray()
	cells.append("<td>%s%s</td>" % [_escape(str(game.get("name", "Host"))), lock])
	cells.append("<td>%s</td>" % _escape(str(game.get("map", "")).capitalize()))
	cells.append("<td>%s</td>" % who)
	cells.append('<td class="state">%s</td>' % state)
	return "<tr>%s</tr>" % "".join(cells)


## The same, for tools rather than eyes: what the page shows, as JSON at [code]/status.json[/code].
func _json() -> String:
	var list: Array = games.call() if games.is_valid() else []
	return (
		JSON
		. stringify(
			{
				"name": args.name,
				"version": _version(),
				"password": not args.password.is_empty(),
				"games_playing": list.size(),
				"games_max": args.games,
				"games": list,
			}
		)
	)


## The server's version, as the hall says it, see [method GameVersion.current].
func _version() -> String:
	return GameVersion.current()


## [param text] with the five characters that mean something in HTML made safe, so a game named with
## a bracket is drawn and not run.
func _escape(text: String) -> String:
	return (
		text
		. replace("&", "&amp;")
		. replace("<", "&lt;")
		. replace(">", "&gt;")
		. replace('"', "&quot;")
		. replace("'", "&#39;")
	)


## The page's style, the house's gold on a dark ground, built from short lines so none runs long.
func _style() -> String:
	return (
		""
		. join(
			PackedStringArray(
				[
					"*{box-sizing:border-box}",
					"body{margin:0;background:#15131a;color:#e8e4ee;line-height:1.5;",
					"font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif}",
					"main{max-width:640px;margin:0 auto;padding:30px 18px}",
					"h1{margin:0;color:#f2c14e;font-size:28px}",
					".sub{margin:4px 0 24px;color:#9b96a6}",
					".card{background:#1e1b26;border:1px solid #332e40;border-radius:12px;",
					"padding:18px 20px;margin:0 0 18px}",
					"h2{margin:0 0 10px;font-size:18px;color:#f2c14e}",
					"ol{margin:0 0 14px;padding-left:20px}",
					"b{color:#fff}",
					".links a{display:inline-block;margin:0 14px 0 0;color:#f2c14e}",
					"table{width:100%;border-collapse:collapse}",
					"th{text-align:left;color:#9b96a6;font-weight:600;font-size:13px;",
					"border-bottom:1px solid #332e40;padding:6px 8px}",
					"td{padding:7px 8px;border-bottom:1px solid #26222f}",
					".state{color:#9b96a6}",
					".empty{color:#9b96a6;margin:0}",
					"footer{color:#6c6678;font-size:13px;text-align:center;margin:8px 0 20px}",
				]
			)
		)
	)
