@tool
extends Node2D
class_name MeterProgressBar
## A 2D Node used for visual representation of a percentage.


## Emitted when [member min_value], [member max_value] or [member overflow_max] change.
signal changed
## Emitted when [member value] changes.
## Note: Unlike signals such as [member LineEdit.text_changed], [signal value_changed] is also emitted when value is set directly via code.
signal value_changed(value: float)


## Range's current value. Changing this property (even via code) will trigger [signal value_changed] signal.
@export var value: float = 1.0 :
	set(v):
		value = clampf(v, min_value, overflow_max)
		value_changed.emit(value)
## Minimum value. Range is clamped if [member value] is less than [member min_value].
@export var min_value: float = 0.0 :
	set(v):
		min_value = v
		changed.emit()
## Maximum value. Range is clamped if [member value] is greater than [member max_value].
@export var max_value: float = 1.0 :
	set(v):
		max_value = v
		changed.emit()
## Overflow maximum value. Range is clamped if [member value] is greater than [member overflow_value].
@export var overflow_max: float = 2.0 :
	set(v):
		overflow_max = v
		changed.emit()

@export_group("Smooth Needle Movement")
## Smooth needle movement. If enabled, needle will try to catch up to it's target position at [member needle_speed] pixels per second.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var smooth_needle: bool = false
## Needle speed. Needle will try to catch up to it's target position at [member needle_speed] pixels per second.
## Note: Only works if [member smooth_needle] is enabled.
@export var needle_speed: float = 600.0

@export_category("Meter Textures")
## Background bar texture. Sets the background of the meter.
## Note: Leaving this empty will use the default texture.
@export var bg_texture: Texture2D = preload("res://characters/base/MeterProgressBar/tex/bg.png") :
	set(v):
		bg_texture = v
		if !is_node_ready(): return
		$BG.texture = v
## Needle texture. Sets the needle of the meter.
## Note: Leaving this empty will use the default texture.
@export var needle_texture: Texture2D = preload("res://characters/base/MeterProgressBar/tex/needle.png") :
	set(v):
		needle_texture = v
		if !is_node_ready(): return
		$Needle.texture = v
## Foreground texture. Sets the texture of the meter itself.
## Note: Leaving this empty will use the default texture.
@export var fg_texture: Texture2D = preload("res://characters/base/MeterProgressBar/tex/fg.png") :
	set(v):
		fg_texture = v
		if !is_node_ready(): return
		$FG.texture = v

@onready var needle_pos: float = $Needle.position.x
@onready var min_pos: float = $Min.position.x
@onready var max_pos: float = $Max.position.x
@onready var overflow_pos: float = $Overflow.position.x

func _ready() -> void:
	$BG.texture = bg_texture
	$Needle.texture = needle_texture
	$FG.texture = fg_texture

func _process(delta: float) -> void:
	var target_pos: float = -1.0
	if value > max_value:
		target_pos = remap(value, max_value, overflow_max, max_pos, overflow_pos)
	else:
		target_pos = remap(value, min_value, max_value, min_pos, max_pos)
	
	if smooth_needle:
		needle_pos = move_toward(needle_pos, target_pos, needle_speed * delta)
	else:
		needle_pos = target_pos
	$Needle.position.x = snappedi(needle_pos, 1)
