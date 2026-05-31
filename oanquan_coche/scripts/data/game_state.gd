class_name GameState
extends RefCounted

# Ring order clockwise: QUAN_0(10), 0,1,2,3,4, QUAN_1(11), 5,6,7,8,9
const RING_CW: Array[int] = [10, 0, 1, 2, 3, 4, 11, 5, 6, 7, 8, 9]

var board: Array[CellData]    = []   # size 12
var players: Array[PlayerData]= []   # size 2
var current_player: int       = 0
var phase: GameEnums.Phase    = GameEnums.Phase.WAITING
var turn_count: int           = 0
var hand: Array[StoneData]    = []
var spread_cell: int          = -1
var direction: GameEnums.Direction = GameEnums.Direction.CLOCKWISE
var province_id: String       = "quickplay"
var special_event_active: bool= false

func setup_initial_board() -> void:
	board.clear()
	# Cells 0–4: Player 0 (north/top)
	for i in range(5):
		var cell := CellData.new(i, 0)
		for j in range(5):
			cell.add_stone(StoneData.new("s%d_%d" % [i, j], GameEnums.StoneType.NORMAL, 0))
		board.append(cell)
	# Cells 5–9: Player 1 (south/bottom)
	for i in range(5, 10):
		var cell := CellData.new(i, 1)
		for j in range(5):
			cell.add_stone(StoneData.new("s%d_%d" % [i, j], GameEnums.StoneType.NORMAL, 1))
		board.append(cell)
	# Cell 10: QUAN_0 (left)
	var q0 := CellData.new(10, -1)
	for j in range(10):
		q0.add_stone(StoneData.new("q0_%d" % j, GameEnums.StoneType.QUAN, -1))
	board.append(q0)
	# Cell 11: QUAN_1 (right)
	var q1 := CellData.new(11, -1)
	for j in range(10):
		q1.add_stone(StoneData.new("q1_%d" % j, GameEnums.StoneType.QUAN, -1))
	board.append(q1)

func next_cell_index(from: int, dir: GameEnums.Direction) -> int:
	var pos := RING_CW.find(from)
	if pos == -1:
		return from
	var step := 1 if dir == GameEnums.Direction.CLOCKWISE else -1
	return RING_CW[(pos + step + 12) % 12]

func get_player_cells(pid: int) -> Array[CellData]:
	var out: Array[CellData] = []
	var start := 0 if pid == 0 else 5
	for i in range(start, start + 5):
		out.append(board[i])
	return out

func is_player_side_empty(pid: int) -> bool:
	for c in get_player_cells(pid):
		if not c.is_empty():
			return false
	return true

func are_both_quan_empty() -> bool:
	return board[10].is_empty() and board[11].is_empty()

func get_valid_moves(pid: int) -> Array[int]:
	var moves: Array[int] = []
	var start := 0 if pid == 0 else 5
	for i in range(start, start + 5):
		if not board[i].is_empty():
			moves.append(i)
	return moves
