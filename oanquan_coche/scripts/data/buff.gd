class_name Buff
extends RefCounted

var type: GameEnums.BuffType
var turns_left: int
var value: float
var source: String

func _init(p_type: GameEnums.BuffType, p_turns: int, p_value: float, p_source: String = "") -> void:
	type       = p_type
	turns_left = p_turns
	value      = p_value
	source     = p_source
