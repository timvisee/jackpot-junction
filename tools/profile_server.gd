extends SceneTree
## The editor's end of Godot's remote debugger, without the editor: listens for a game started
## with `--remote-debug tcp://127.0.0.1:<port>`, switches its profilers on and, once the game
## has gone, prints what they measured. Used by tools/profile; run it by hand as
##
##   tools/godot --headless -s tools/profile_server.gd -- --port=6007 --skip=120 --top=40
##
## What it prints: the frame, process and physics times per frame; the script functions that
## took the most time, by their own time (what they spent themselves, not in what they called),
## with calls and inclusive time per frame; every server function the servers profiler saw; the
## GPU passes of the visual profiler; and the performance monitors, draw calls among them. Times
## are in milliseconds per frame, averaged over the frames after `--skip`. Profiling itself
## slows the scripts down, so the ranking is what to read, not the absolute numbers.

const DEFAULT_PORT := 6007

var _server := TCPServer.new()
var _peer: StreamPeerTCP
var _port := DEFAULT_PORT
var _skip := 120
var _top := 40
var _out := ""
var _buffer := PackedByteArray()
var _started := false
var _seen := 0
var _counted := 0
## Sums over the counted frames.
var _frame_time := 0.0
var _process_time := 0.0
var _physics_time := 0.0
var _physics_frame_time := 0.0
var _script_time := 0.0
## Script function name -> [calls, self, internal, total], summed over the counted frames.
var _functions := {}
## Signature id -> function name, as the game hands them out.
var _signatures := {}
## Server -> function -> time, summed over the counted frames.
var _servers := {}
## Visual profiler area -> [cpu, gpu], summed over the counted frames.
var _areas := {}
var _visual_frames := 0
## Performance monitor name -> [sum, count].
var _monitor_names: PackedStringArray = []
var _monitors := {}
var _messages := {}
var _quiet_for := 0.0
var _debug := false
var _since_status := 0.0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--port="):
			_port = int(arg.get_slice("=", 1))
		elif arg.begins_with("--skip="):
			_skip = int(arg.get_slice("=", 1))
		elif arg.begins_with("--top="):
			_top = int(arg.get_slice("=", 1))
		elif arg.begins_with("--out="):
			_out = arg.get_slice("=", 1)
		elif arg == "--debug":
			_debug = true
	var error := _server.listen(_port, "127.0.0.1")
	if error != OK:
		printerr("profile_server: cannot listen on %d: %s" % [_port, error_string(error)])
		quit(1)
		return
	print("profile_server: listening on 127.0.0.1:%d" % _port)


func _process(delta: float) -> bool:
	if _peer == null:
		_quiet_for += delta
		if _quiet_for > 60.0:
			print("profile_server: no game connected in 60 s, giving up")
			return true
		if _server.is_connection_available():
			_peer = _server.take_connection()
			_peer.set_no_delay(true)
			print("profile_server: the game connected")
			_send("set_skip_breakpoints", [true])
			_send("set_ignore_error_breaks", [true])
			_send("profiler:servers", [true, [1024]])
			_send("profiler:visual", [true, []])
			_send("profiler:performance", [true, []])
			_started = true
		return false
	_peer.poll()
	if _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		print("profile_server: the game went")
		_report()
		return true
	var read := _read_all()
	if _debug:
		_since_status += delta
		if _since_status > 2.0:
			_since_status = 0.0
			print("status: seen %d frames, messages %s" % [_seen, _messages])
	if read == 0:
		_quiet_for += delta
		if _quiet_for > 30.0:
			print("profile_server: nothing heard for 30 s, giving up")
			_report()
			return true
	else:
		_quiet_for = 0.0
	return false


## Every command names the thread it is for, and 1 is the main thread.
func _send(what: String, data: Array) -> void:
	_peer.put_var([what, 1, data])


## Everything off the wire, then every whole message in it: a 4-byte size and then a variant,
## the way the game's RemoteDebuggerPeerTCP writes them. Read in whatever pieces arrive, as a
## profile frame is bigger than the socket holds at once and waiting for all of it stalls both
## ends. Returns how many messages there were.
func _read_all() -> int:
	var available := _peer.get_available_bytes()
	if available > 0:
		var got := _peer.get_partial_data(available)
		if got[0] == OK:
			_buffer.append_array(got[1])
	var read := 0
	var at := 0
	while _buffer.size() - at >= 4:
		var size := _buffer.decode_u32(at)
		if _buffer.size() - at - 4 < size:
			break
		var message: Variant = bytes_to_var(_buffer.slice(at + 4, at + 4 + size))
		at += 4 + size
		read += 1
		if message is Array:
			_handle(message)
	if at > 0:
		_buffer = _buffer.slice(at)
	return read


func _handle(message: Array) -> void:
	# [what, thread, data] since 4.2; [what, data] before that.
	var what := str(message[0])
	var data: Array = message[-1] if message[-1] is Array else []
	_messages[what] = _messages.get(what, 0) + 1
	match what:
		"debug_enter":
			# An error stopped the game for a debugger to look at: nobody is looking.
			_send("continue", [])
		"servers:profile_frame":
			_servers_frame(data)
		"servers:function_signature":
			_signatures[int(data[1])] = str(data[0])
		"visual:profile_frame":
			_visual_frame(data)
		"performance:profile_names":
			_monitor_names = PackedStringArray(data)
		"performance:profile_frame":
			_performance_frame(data)
		"error":
			if _debug:
				print("game error: ", data)


func _servers_frame(data: Array) -> void:
	_seen += 1
	if _seen <= _skip or data.size() < 7:
		return
	_counted += 1
	_frame_time += float(data[1])
	_process_time += float(data[2])
	_physics_time += float(data[3])
	_physics_frame_time += float(data[4])
	_script_time += float(data[5])
	var servers_left := int(data[6])
	var at := 7
	while servers_left > 0 and at + 1 < data.size():
		servers_left -= 1
		var server := str(data[at])
		var pairs := int(data[at + 1]) / 2
		at += 2
		var functions: Dictionary = _servers.get(server, {})
		for i: int in pairs:
			var name := str(data[at])
			functions[name] = functions.get(name, 0.0) + float(data[at + 1])
			at += 2
		_servers[server] = functions
	if at >= data.size():
		return
	# Then every script function: its signature's id, calls, and its own, inclusive and internal
	# times, in seconds.
	var count := int(data[at]) / 5
	at += 1
	for i: int in count:
		var name: String = _signatures.get(int(data[at]), "#%d" % int(data[at]))
		var sums: Array = _functions.get(name, [0, 0.0, 0.0, 0.0])
		sums[0] += int(data[at + 1])
		sums[1] += float(data[at + 2])
		sums[3] += float(data[at + 3])
		sums[2] += float(data[at + 4])
		_functions[name] = sums
		at += 5


func _visual_frame(data: Array) -> void:
	if _seen <= _skip or data.is_empty():
		return
	_visual_frames += 1
	# frame_number, three times the number of areas, then (name, cpu, gpu) per area, in ms.
	var at := 2
	while at + 2 < data.size():
		var name := str(data[at])
		var sums: Array = _areas.get(name, [0.0, 0.0])
		sums[0] += float(data[at + 1])
		sums[1] += float(data[at + 2])
		_areas[name] = sums
		at += 3


func _performance_frame(data: Array) -> void:
	if _seen <= _skip:
		return
	for i: int in mini(data.size(), _monitor_names.size()):
		var name := _monitor_names[i]
		var sums: Array = _monitors.get(name, [0.0, 0])
		sums[0] += float(data[i])
		sums[1] += 1
		_monitors[name] = sums


func _ms(seconds: float) -> String:
	return "%7.3f" % (seconds * 1000.0)


func _msec(msec: float) -> String:
	return "%7.3f" % msec


func _report() -> void:
	var lines: PackedStringArray = []
	if _counted == 0:
		lines.append("profile_server: no frames profiled (%d seen, %d skipped)" % [_seen, _skip])
		lines.append("messages: %s" % _messages)
		_print(lines)
		return
	var n := float(_counted)
	lines.append("profile: %d frames (after %d skipped), ms per frame" % [_counted, _skip])
	(
		lines
		. append(
			(
				"  frame %s  process %s  physics %s  physics-frame %s  scripts %s"
				% [
					_ms(_frame_time / n),
					_ms(_process_time / n),
					_ms(_physics_time / n),
					_ms(_physics_frame_time / n),
					_ms(_script_time / n),
				]
			)
		)
	)
	lines.append("")
	lines.append("script functions by their own time, ms per frame, calls per frame:")
	lines.append("    self   incl.  calls  function")
	var names := _functions.keys()
	names.sort_custom(
		func(a: String, b: String) -> bool: return _functions[a][1] > _functions[b][1]
	)
	for i: int in mini(_top, names.size()):
		var name: String = names[i]
		var sums: Array = _functions[name]
		lines.append(
			"  %s %s %6.1f  %s" % [_ms(sums[1] / n), _ms(sums[3] / n), float(sums[0]) / n, name]
		)
	var self_total := 0.0
	for name: String in names:
		self_total += _functions[name][1]
	lines.append("  %s                 all %d functions" % [_ms(self_total / n), names.size()])
	for server: String in _servers:
		lines.append("")
		lines.append("%s server, ms per frame:" % server)
		var functions: Dictionary = _servers[server]
		for name: String in functions:
			lines.append("  %s  %s" % [_ms(functions[name] / n), name])
	if _visual_frames > 0:
		lines.append("")
		lines.append("GPU passes, ms per frame, over %d frames (cpu / gpu):" % _visual_frames)
		var m := float(_visual_frames)
		for name: String in _areas:
			var sums: Array = _areas[name]
			lines.append("  %s %s  %s" % [_msec(sums[0] / m), _msec(sums[1] / m), name])
	if not _monitors.is_empty():
		lines.append("")
		lines.append("performance monitors, averaged:")
		for name: String in _monitors:
			var sums: Array = _monitors[name]
			lines.append("  %14.1f  %s" % [sums[0] / float(sums[1]), name])
	_print(lines)


func _print(lines: PackedStringArray) -> void:
	var text := "\n".join(lines)
	print(text)
	if not _out.is_empty():
		var file := FileAccess.open(_out, FileAccess.WRITE)
		if file != null:
			file.store_string(text + "\n")
