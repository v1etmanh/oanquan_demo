class_name StoneData
extends RefCounted

var id: String
var type: GameEnums.StoneType
var value: int
var owner: int        # 0, 1, or -1
var is_special: bool

func _init(p_id: String, p_type: GameEnums.StoneType, p_owner: int = -1) -> void:
	id       = p_id
	type     = p_type
	owner    = p_owner
	is_special = p_type != GameEnums.StoneType.NORMAL
	match p_type:
		GameEnums.StoneType.NORMAL: value = 1
		GameEnums.StoneType.GOLD:   value = 2
		GameEnums.StoneType.DARK:   value = 0
		GameEnums.StoneType.QUAN:   value = 10
		GameEnums.StoneType.SPIRIT: value = 1
