extends Control



func _on_character_item_selected(index: int) -> void:
	$StudentSkin.visible = index == 2
	$Deselect.disabled = false


func _on_deselect_pressed() -> void:
	$Deselect.disabled = true
	$Character.deselect_all()
	$StudentSkin.hide()
