extends Node

signal tracker_data_received(euler_angles)

## Optional node to have it's global rotation mirroring the tracker
@export var TargetNode: Node3D

const HALF_PI = PI*0.5

var server := UDPServer.new()
var peers = []

func _ready():
	server.listen(5678)

func _process(_delta):
	server.poll() # Important!
	if server.is_connection_available():
		var peer: PacketPeerUDP = server.take_connection()
		peers.append(peer)
		
		var packet = peer.get_packet()
		_decode_packet_and_emit(packet.get_string_from_utf8())
		#print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
		#print("Received data: %s" % [packet.get_string_from_utf8()])
		# Keep a reference so we can keep contacting the remote peer.

	for i in range(0, peers.size()):
		var peer = peers[i]
		while (peer.get_available_packet_count() > 0):
			var packet = peer.get_packet()
			_decode_packet_and_emit(packet.get_string_from_utf8())
			#print("Received data: %s" % [packet.get_string_from_utf8()])


func _decode_packet_and_emit(packet: String) -> bool:
	# Returns true if decoding was successful
	
	var str_array = packet.strip_edges().split(" ")
	if str_array.size() == 3:
		if (str_array[0].is_valid_float() and str_array[1].is_valid_float() and str_array[2].is_valid_float()):
			var angles = Vector3.ZERO
			angles.x = float(str_array[0]) + HALF_PI
			angles.y = float(str_array[1])
			angles.z = -float(str_array[2])
			emit_signal("tracker_data_received", angles)
			
			if TargetNode:
				TargetNode.rotation = angles
			
			return true
	return false
