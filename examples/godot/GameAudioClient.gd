# Godot 4.x OSC client for Game Audio Engine
# Sends OSC/UDP to JUCE gateway at 127.0.0.1:9000.

extends Node

@export var host: String = "127.0.0.1"
@export var port: int = 9000

var udp := PacketPeerUDP.new()
var scene_id := 1
var event_counter := 0

func _ready() -> void:
	udp.connect_to_host(host, port)
	_create_scene("godot_scene", 1234)

func spawn_hit(pos: Vector3, gain: float = 0.7, seed: int = -1) -> String:
	event_counter += 1
	var event_id = "godot_evt_%d" % event_counter
	if seed < 0:
		seed = randi()

	_send_osc("/event/spawn", [
		scene_id,
		"proc_hit",
		event_id,
		clampf(pos.x, -1.0, 1.0),
		clampf(pos.y, -1.0, 1.0),
		clampf(pos.z, -1.0, 1.0),
		clampf(gain, 0.0, 1.0),
		seed
	])
	return event_id

func stop_event(event_id: String, release_ms: int = 80) -> void:
	_send_osc("/event/stop", [event_id, release_ms])

func set_event_param(event_id: String, key: String, value: float, ramp_ms: int = 0) -> void:
	_send_osc("/event/param", [event_id, key, value, ramp_ms])

func set_bus_db(bus_name: String, gain_db: float, ramp_ms: int = 50) -> void:
	_send_osc("/mix/bus", [bus_name, gain_db, ramp_ms])

func _create_scene(name: String, seed: int) -> void:
	# Engine auto-generates scene ids; for lightweight clients we use a fixed id flow.
	# If you need strict id sync, add a small OSC receiver in Godot for /scene/created.
	scene_id = 1
	_send_osc("/scene/create", [name, seed])

# ------- OSC encoding -------
func _send_osc(address: String, args: Array) -> void:
	var packet = PackedByteArray()
	packet.append_array(_osc_string(address))

	var tags = ","
	for a in args:
		tags += _osc_type_tag(a)
	packet.append_array(_osc_string(tags))

	for a in args:
		packet.append_array(_osc_arg(a))

	udp.put_packet(packet)

func _osc_type_tag(value) -> String:
	if value is int:
		return "i"
	if value is float:
		return "f"
	if value is String:
		return "s"
	return "s"

func _osc_arg(value) -> PackedByteArray:
	if value is int:
		return _osc_int32(value)
	if value is float:
		return _osc_float32(value)
	return _osc_string(str(value))

func _osc_string(s: String) -> PackedByteArray:
	var b = s.to_utf8_buffer()
	var out = PackedByteArray()
	out.append_array(b)
	out.append(0)
	while (out.size() % 4) != 0:
		out.append(0)
	return out

func _osc_int32(v: int) -> PackedByteArray:
	var out = PackedByteArray()
	out.resize(4)
	out[0] = (v >> 24) & 0xFF
	out[1] = (v >> 16) & 0xFF
	out[2] = (v >> 8) & 0xFF
	out[3] = v & 0xFF
	return out

func _osc_float32(v: float) -> PackedByteArray:
	var bytes = PackedByteArray()
	bytes.resize(4)
	bytes.encode_float(0, v)
	# Godot encodes float in native endian; convert to big-endian for OSC.
	bytes.reverse()
	return bytes
