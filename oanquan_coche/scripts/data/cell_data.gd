class_name CellData
extends RefCounted

var index: int
var stones: Array[StoneData] = []
var cell_type: String   # "normal" | "quan"
var owner: int          # 0, 1, or -1 (quan)
var trap_active: bool   = false
var province_effect: String = ""
var empty_turns: int    = 0    # for Loc Troi Cho
var auto_spawned: bool  = false

func _init(p_index: int, p_owner: int) -> void:
	index     = p_index
	owner     = p_owner
	cell_type = "quan" if p_owner == -1 else "normal"

func stone_count() -> int:
	return stones.size()

func is_empty() -> bool:
	return stones.is_empty()

func add_stone(s: StoneData) -> void:
	stones.append(s)

func remove_all_stones() -> Array[StoneData]:
	var result: Array[StoneData] = stones.duplicate()
	stones.clear()
	trap_active = false
	return result
