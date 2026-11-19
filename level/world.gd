extends Node3D


func _process(_delta: float) -> void:
	if Server.anti_hearing_active:
		if !$AntiHearing.playing: $AntiHearing.play()
	else: $AntiHearing.stop()
	if Server.notebooks >= 7:
		if !$EscapeMusic.playing: $EscapeMusic.play()
	else: $EscapeMusic.stop()
