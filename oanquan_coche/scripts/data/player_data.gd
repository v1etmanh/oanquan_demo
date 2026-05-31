class_name PlayerData
extends RefCounted

var id: int
var score: int          = 0
var score_reserve: int  = 0
var side: String
var direction: GameEnums.Direction = GameEnums.Direction.CLOCKWISE
var buffs: Array[Buff]  = []
var time_bank: float    = 15.0

func _init(p_id: int) -> void:
	id        = p_id
	side      = "north" if p_id == 0 else "south"
	direction = GameEnums.Direction.CLOCKWISE

func add_score(points: int) -> void:
	score += points

func get_buff(buff_type: GameEnums.BuffType) -> Buff:
	for b in buffs:
		if b.type == buff_type:
			return b
	return null

func has_buff(buff_type: GameEnums.BuffType) -> bool:
	return get_buff(buff_type) != null

func tick_buffs() -> void:
	var to_remove: Array[Buff] = []
	for b in buffs:
		b.turns_left -= 1
		if b.turns_left <= 0:
			to_remove.append(b)
	for b in to_remove:
		buffs.erase(b)
