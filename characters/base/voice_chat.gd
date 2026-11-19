extends Node3D

var effect: AudioEffectRecord
var recording: AudioStreamWAV
@onready var player: BaseController = get_parent()

func _ready() -> void:
	if multiplayer.get_unique_id() != player.id: return
	var bus_index = AudioServer.get_bus_index(&"Record")
	effect = AudioServer.get_bus_effect(bus_index, 0)
	effect.set_recording_active(true)
	$SendRecordingTimer.start()


@rpc("any_peer", "call_remote", "reliable")
func send_rec_data(rec_data: PackedByteArray):
	var sample = AudioStreamWAV.new()
	sample.data = rec_data
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = AudioServer.get_mix_rate() * 2
	$Voice.stream = sample
	$Voice.play()


func _on_send_recording_timer_timeout() -> void:
	if !multiplayer.has_multiplayer_peer(): return
	recording = effect.get_recording()
	if !recording or recording.data.is_empty():
		$UI/Wait.modulate = Color.TRANSPARENT
		$UI/AnimationPlayer.play("show_warning")
		$SendRecordingTimer.stop()
		return
	effect.set_recording_active(false)
	send_rec_data.rpc(recording.data)
	effect.set_recording_active(true)

func _input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_F12) and $SendRecordingTimer.is_stopped():
		$UI/Warning.modulate = Color.TRANSPARENT
		$UI/AnimationPlayer.play("wait")
		$SendRecordingTimer.start()
		
