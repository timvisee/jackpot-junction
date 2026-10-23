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
## [member ServerArgs.web_link]. Steam is empty until the game is on it, and left out while it is.
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
	elif path == "/games.html":
		# The games section on its own, for the page's script to pull in again as they change.
		_answer(peer, 200, "text/html; charset=utf-8", _games(_listing()))
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


## The games being played right now, as its own section; what [code]/games.html[/code] returns and
## what the page starts with, so the one renderer serves both.
func _listing() -> Array:
	return games.call() if games.is_valid() else []


## The page itself, for a visitor who came in by [param host].
func _html(host: String) -> String:
	var name := args.name if not args.name.is_empty() else "Jackpot Junction"
	var out := PackedStringArray()
	out.append("<!doctype html>")
	out.append('<html lang="en"><head><meta charset="utf-8">')
	out.append('<meta name="viewport" content="width=device-width, initial-scale=1">')
	# Without the script, the page does not refresh itself; this brings it back every so often.
	out.append('<noscript><meta http-equiv="refresh" content="%d"></noscript>' % (REFRESH * 4))
	out.append("<title>%s</title>" % _escape(name))
	out.append("<style>%s</style></head><body><main>" % _style())
	out.append("<h1>%s</h1>" % _escape(name))
	out.append('<p class="sub">Jackpot Junction %s dedicated server</p>' % _escape(_version()))
	out.append(_description())
	# The address the operator set, where they did, or the one the visitor came in by otherwise.
	var address := args.web_address if not args.web_address.is_empty() else _address(host)
	out.append(_join(address))
	out.append('<section class="card" id="games">%s</section>' % _games(_listing()))
	out.append("<footer>This page updates every %d seconds.</footer>" % REFRESH)
	out.append("<script>%s</script></main></body></html>" % _script())
	return "\n".join(out)


## The operator's own line or two at the top, see [member ServerArgs.web_description], its breaks
## kept; nothing where there is none.
func _description() -> String:
	if args.web_description.is_empty():
		return ""
	return (
		'<section class="card note">%s</section>'
		% _escape(args.web_description).replace("\n", "<br>")
	)


## How to join, with the address and port each in a field of its own to click and copy, [param
## address] the one the visitor came in by or empty where the request did not say.
func _join(address: String) -> String:
	var out := PackedStringArray(['<section class="card"><h2>How to join</h2><ol>'])
	out.append("<li>Get the game below, and open it.</li>")
	out.append("<li>Choose <b>Play Online</b>, then the <b>Servers</b> tab.</li>")
	out.append("<li><b>Add a server</b>, to keep it, or <b>Direct connect</b>, and enter:</li>")
	out.append("</ol>")
	out.append('<div class="fields">')
	out.append(_field("Address", address if not address.is_empty() else "this server's address"))
	out.append(_field("Port", str(args.port)))
	out.append("</div>")
	if not args.password.is_empty():
		out.append('<p class="note-line">This server has a password. Enter it when it asks.</p>')
	out.append(_links())
	out.append("</section>")
	return "".join(out)


## A labelled field a click copies, [param label] over [param value] in a code box with a copy
## button; its id is the lowercased label, which the script copies by.
func _field(label: String, value: String) -> String:
	var id := label.to_lower()
	return (
		'<div class="field"><span class="label">%s</span>' % _escape(label)
		+ '<span class="val"><code id="%s">%s</code>' % [id, _escape(value)]
		+ '<button type="button" class="copy" data-copy="%s">Copy</button></span></div>' % id
	)


## The games section, [param list] of them: how many, and a table of each, or a line for none. Both
## the page and [code]/games.html[/code] use it, so the list reads the same either way.
func _games(list: Array) -> String:
	return "<h2>%s</h2>%s" % [_heading(list), _list(list)]


## The links to get the game: the two it always carries, Steam once it is there, and the operator's
## own last, see [member ServerArgs.web_link].
func _links() -> String:
	var links: Array[Array] = [["Get it on itch.io", ITCH], ["Source on GitHub", GITHUB]]
	if not STEAM.is_empty():
		links.append(["Get it on Steam", STEAM])
	if not args.web_link.is_empty():
		links.append([args.web_link, args.web_link])
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
	var list: Array = _listing()
	return (
		JSON
		. stringify(
			{
				"name": args.name,
				"version": _version(),
				"port": args.port,
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


## The page's script: pulls the games in again every few seconds without a reload, and copies the
## address or port to the clipboard at a click, falling back to the old way where the clipboard is
## not offered, as it is not over plain HTTP. Built from short lines so none runs long.
func _script() -> String:
	return (
		"\n"
		. join(
			PackedStringArray(
				[
					"function flash(b){var o=b.textContent;b.textContent='Copied';b.classList.add('ok');",
					"setTimeout(function(){b.textContent=o;b.classList.remove('ok')},1200)}",
					"function fb(t,c){var a=document.createElement('textarea');a.value=t;",
					"a.style.position='fixed';a.style.opacity=0;document.body.appendChild(a);a.select();",
					"try{document.execCommand('copy')}catch(e){}document.body.removeChild(a);c()}",
					"function copy(i,b){var el=document.getElementById(i);if(!el)return;",
					"var t=el.textContent,d=function(){flash(b)};",
					"if(navigator.clipboard&&navigator.clipboard.writeText)",
					"{navigator.clipboard.writeText(t).then(d,function(){fb(t,d)})}else{fb(t,d)}}",
					"document.addEventListener('click',function(e){",
					"var b=e.target.closest&&e.target.closest('.copy');if(b){copy(b.dataset.copy,b)}});",
					"function refresh(){fetch('games.html',{cache:'no-store'})",
					".then(function(r){return r.text()})",
					".then(function(h){document.getElementById('games').innerHTML=h})",
					".catch(function(){})}",
					"setInterval(refresh, %d);" % (REFRESH * 1000),
				]
			)
		)
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
					".note{border-left:3px solid #f2c14e}",
					".note-line{color:#f2c14e;margin:10px 0 0}",
					".links a{display:inline-block;margin:0 14px 0 0;color:#f2c14e}",
					".fields{margin:4px 0 4px;display:flex;flex-wrap:wrap;gap:10px}",
					".field{background:#15131a;border:1px solid #332e40;border-radius:8px;",
					"padding:8px 11px}",
					".field .label{display:block;color:#9b96a6;font-size:12px;margin:0 0 3px}",
					".field .val{display:flex;align-items:center;gap:8px}",
					"code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;color:#fff;",
					"font-size:15px;letter-spacing:.3px}",
					# min-width holds Copied as well as Copy, so the button does not grow when pressed.
					".copy{background:#2a2636;color:#e8e4ee;border:1px solid #403a4f;",
					"border-radius:6px;padding:3px 9px;font-size:12px;cursor:pointer;",
					"min-width:66px;text-align:center}",
					".copy:hover{border-color:#f2c14e}",
					".copy.ok{color:#15131a;background:#f2c14e;border-color:#f2c14e}",
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
