class_name AIPlayer
extends RefCounted
# AIPlayer — levels 0-3
# 0 = random, 1 = most stones, 2 = 1-step lookahead, 3 = 2-step + defensive

var level: int = 1

func choose_move(state: GameState) -> int:
	var moves := state.get_valid_moves(state.current_player)
	if moves.is_empty():
		return -1
	match level:
		0: return _random(moves)
		1: return _most_stones(moves, state)
		2: return _lookahead_1(moves, state)
		3: return _lookahead_2(moves, state)
		_: return _random(moves)

# ── Level 0 ───────────────────────────────────────────────────────────────────
func _random(moves: Array[int]) -> int:
	moves.shuffle()
	return moves[0]

# ── Level 1 ───────────────────────────────────────────────────────────────────
func _most_stones(moves: Array[int], state: GameState) -> int:
	var best := moves[0]
	var best_count := 0
	for idx in moves:
		var cnt := state.board[idx].stone_count()
		if cnt > best_count:
			best_count = cnt
			best       = idx
	return best

# ── Level 2 — 1-step lookahead ────────────────────────────────────────────────
func _lookahead_1(moves: Array[int], state: GameState) -> int:
	var best      := moves[0]
	var best_score := -INF
	for idx in moves:
		var score := _score_move(idx, state, state.current_player)
		if score > best_score:
			best_score = score
			best       = idx
	return best

# ── Level 3 — 2-step lookahead + defensive ────────────────────────────────────
func _lookahead_2(moves: Array[int], state: GameState) -> int:
	var best      := moves[0]
	var best_score := -INF
	var ai_pid    := state.current_player
	var opp_pid   := 1 - ai_pid

	for idx in moves:
		var my_gain    := _simulate_capture_points(idx, state, ai_pid)
		# Simulate board after this move (lightweight)
		var sim        := _apply_move_simple(idx, state)
		# Opponent's best response from simulated state
		var opp_moves  := sim.get_valid_moves(opp_pid)
		var opp_best   := 0
		for om in opp_moves:
			var og := _simulate_capture_points(om, sim, opp_pid)
			if og > opp_best:
				opp_best = og
		# Avoid DARK trap penalty
		var trap_penalty := 0
		if sim.board[idx].trap_active:
			trap_penalty = 10
		var total := my_gain * 2.0 - opp_best * 1.5 - trap_penalty
		if total > best_score:
			best_score = total
			best       = idx
	return best

# ── Helpers ───────────────────────────────────────────────────────────────────

# Score a single move heuristically (no simulation)
func _score_move(cell_idx: int, state: GameState, pid: int) -> float:
	var pts  := float(_simulate_capture_points(cell_idx, state, pid))
	var trap := -10.0 if state.board[cell_idx].trap_active else 0.0
	return pts * 2.0 + trap

# Simulate how many points this move would capture (read-only walk)
func _simulate_capture_points(cell_idx: int, state: GameState, _pid: int) -> int:
	var hand_size := state.board[cell_idx].stone_count()
	if hand_size == 0:
		return 0
	var dir     := state.direction
	var current := cell_idx
	# Walk the ring for hand_size steps
	for _i in range(hand_size):
		current = state.next_cell_index(current, dir)
	# Check if we land on empty and next has stones
	var after := state.next_cell_index(current, dir)
	if state.board[current].is_empty() and not state.board[after].is_empty() \
			and state.board[after].cell_type != "quan":
		return _count_capture_chain(current, state, dir)
	elif not state.board[current].is_empty():
		# Would keep spreading — rough estimate: average capture later
		return int(float(state.board[current].stone_count()) / 2.0)
	return 0

func _count_capture_chain(empty_idx: int, state: GameState, dir: GameEnums.Direction) -> int:
	var total   := 0
	var cursor  := empty_idx
	while true:
		var target := state.next_cell_index(cursor, dir)
		if state.board[target].is_empty() or state.board[target].cell_type == "quan":
			break
		for s in state.board[target].stones:
			total += s.value
		cursor = state.next_cell_index(target, dir)
		if not state.board[cursor].is_empty():
			break
	return total

# Lightweight board clone after removing stones from cell_idx
func _apply_move_simple(cell_idx: int, state: GameState) -> GameState:
	var sim         := GameState.new()
	sim.direction   = state.direction
	sim.turn_count  = state.turn_count
	sim.province_id = state.province_id
	sim.board       = []
	for c in state.board:
		var nc          := CellData.new(c.index, c.owner)
		nc.cell_type    = c.cell_type
		nc.trap_active  = c.trap_active
		for s in c.stones:
			nc.add_stone(s)
		sim.board.append(nc)
	# Empty the chosen cell
	sim.board[cell_idx].remove_all_stones()
	sim.players         = state.players
	sim.current_player  = 1 - state.current_player
	return sim
