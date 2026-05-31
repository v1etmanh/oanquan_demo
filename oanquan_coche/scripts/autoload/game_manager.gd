extends Node
# GameManager — Autoload singleton
# Handles all game logic phases, signals, timer, AI

# ── Signals ──────────────────────────────────────────────────────────────────
signal stone_placed(cell_index: int, stone: StoneData)
signal stones_captured(cell_indices: Array, total_points: int)
signal turn_ended(next_player_id: int)
signal game_over(winner: int, scores: Array)
signal special_stone_spawned(cell_index: int, stone_type: GameEnums.StoneType)
signal trap_triggered(cell_index: int, victim_player: int)
@warning_ignore("unused_signal")
signal province_unlocked(province_id: String)
signal phase_changed(new_phase: GameEnums.Phase)
signal hand_stone_dropped(cell_index: int, stone: StoneData)
signal score_changed(player_id: int, new_score: int, delta: int)
signal timer_updated(seconds_left: float)
signal auto_spawn_triggered(cell_index: int)
signal board_changed()
signal capture_confirm_needed(empty_cell_idx: int)
signal capture_confirmed()

# ── State ─────────────────────────────────────────────────────────────────────
var state: GameState
var ai: AIPlayer

var timer_seconds: float = 15.0
var _timer: float        = 0.0
var _timer_active: bool  = false

# Special stone counters
var _turns_since_gold: int = 0
var _turns_since_dark: int = 0
var _gold_on_board: int    = 0
var _dark_on_board: int    = 0

# Trap / effect tracking
var _skip_victim: int      = -1   # player who loses next turn due to DARK trap
var _combo_count: int      = 0    # chain capture count (for audio escalation)

const STAGGER: float = 0.18  # giây giữa mỗi hòn rải
const AI_THINK: float = 0.4  # giây AI "suy nghĩ"

# ── _process (timer) ──────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not _timer_active or state == null:
		return
	_timer -= delta
	timer_updated.emit(_timer)
	if _timer <= 0.0:
		_timer_active = false
		_on_timer_expired()

# ── Public API ────────────────────────────────────────────────────────────────
func start_new_game(
		province: String = "quickplay",
		ai_level: int = 1,
		dir: GameEnums.Direction = GameEnums.Direction.CLOCKWISE
) -> void:
	state                    = GameState.new()
	state.province_id        = province
	state.direction          = dir
	state.players            = [PlayerData.new(0), PlayerData.new(1)]
	state.players[0].direction = dir
	state.players[1].direction = dir
	state.setup_initial_board()
	state.current_player     = 1   # human (player 1) goes first
	state.phase              = GameEnums.Phase.WAITING
	state.turn_count         = 0

	_turns_since_gold = 0
	_turns_since_dark = 0
	_gold_on_board    = 0
	_dark_on_board    = 0
	_skip_victim      = -1
	_combo_count      = 0

	ai       = AIPlayer.new()
	ai.level = ai_level

	board_changed.emit()
	_start_turn()

func player_confirm_capture(_empty_cell_idx: int) -> void:
	if state == null or state.phase != GameEnums.Phase.CAPTURE_CONFIRM:
		return
	capture_confirmed.emit()

func player_select_cell(cell_index: int) -> void:
	if state == null or state.phase != GameEnums.Phase.WAITING:
		return
	if cell_index not in state.get_valid_moves(state.current_player):
		return
	_timer_active = false
	_begin_spread(cell_index)

func player_select_cell_with_direction(cell_index: int, dir: GameEnums.Direction) -> void:
	if state == null or state.phase != GameEnums.Phase.WAITING:
		return
	if cell_index not in state.get_valid_moves(state.current_player):
		return
	_timer_active   = false
	state.direction = dir
	_begin_spread(cell_index)

# ── Turn start ────────────────────────────────────────────────────────────────
func _start_turn() -> void:
	# DARK trap: victim skips this turn
	if _skip_victim == state.current_player:
		_skip_victim = -1
		await _end_turn()
		return

	_set_phase(GameEnums.Phase.WAITING)
	_timer        = timer_seconds
	_timer_active = true

	if state.current_player == 0:
		# AI turn: disable player timer, schedule AI move
		_timer_active = false
		await get_tree().create_timer(AI_THINK).timeout
		var move := ai.choose_move(state)
		if move >= 0:
			player_select_cell(move)

# ── Spreading ─────────────────────────────────────────────────────────────────
func _begin_spread(cell_index: int) -> void:
	_set_phase(GameEnums.Phase.SPREADING)
	_combo_count              = 0
	state.hand                = state.board[cell_index].remove_all_stones()
	state.spread_cell         = cell_index
	board_changed.emit()
	await _spread_loop()

func _spread_loop() -> void:
	while not state.hand.is_empty():
		var next_idx := state.next_cell_index(state.spread_cell, state.direction)
		var stone    := state.hand.pop_front() as StoneData
		state.board[next_idx].add_stone(stone)
		state.spread_cell = next_idx

		if stone.type == GameEnums.StoneType.DARK:
			state.board[next_idx].trap_active = true

		hand_stone_dropped.emit(next_idx, stone)
		stone_placed.emit(next_idx, stone)
		board_changed.emit()
		SoundManager.play_stone_drop(stone.type, state.board[next_idx].stone_count())

		await get_tree().create_timer(STAGGER).timeout

	await _check_after_spread()

# ── Post-spread check ─────────────────────────────────────────────────────────
func _check_after_spread() -> void:
	var next_idx  := state.next_cell_index(state.spread_cell, state.direction)
	var next_cell := state.board[next_idx]

	if not next_cell.is_empty():
		# Rule 1: next has stones → pick up and continue
		state.hand        = next_cell.remove_all_stones()
		state.spread_cell = next_idx
		board_changed.emit()
		await _spread_loop()

	elif next_cell.cell_type == "quan":
		# Rule 3: empty quan → stop
		await _on_spread_done()

	else:
		# next is empty normal cell
		var nn_idx  := state.next_cell_index(next_idx, state.direction)
		var nn_cell := state.board[nn_idx]
		if not nn_cell.is_empty():
			# Rule 2: potential capture — human must click the empty cell first
			if state.current_player == 1:
				_set_phase(GameEnums.Phase.CAPTURE_CONFIRM)
				capture_confirm_needed.emit(next_idx)
				await capture_confirmed
			await _capture(nn_idx)
		else:
			await _on_spread_done()

# ── Capture ───────────────────────────────────────────────────────────────────
func _capture(cap_idx: int) -> void:
	_set_phase(GameEnums.Phase.CAPTURING)
	_combo_count += 1

	var cell     := state.board[cap_idx]
	var captured := cell.remove_all_stones()
	var trap_hit := cell.trap_active
	cell.trap_active = false
	board_changed.emit()

	# Calculate raw points
	var points   := 0
	var has_gold := false
	for s in captured:
		match s.type:
			GameEnums.StoneType.NORMAL: points += 1
			GameEnums.StoneType.GOLD:
				has_gold       = true
				points        += 2
				_gold_on_board = maxi(0, _gold_on_board - 1)
			GameEnums.StoneType.QUAN:   points += 10
			GameEnums.StoneType.DARK:
				_dark_on_board = maxi(0, _dark_on_board - 1)

	if has_gold:
		points *= 2   # GOLD doubles the whole capture

	# Buff: score multiplier
	var player := state.players[state.current_player]
	var mult   := player.get_buff(GameEnums.BuffType.SCORE_MULTIPLIER)
	if mult != null:
		points = int(points * mult.value)

	# Apply
	player.add_score(points)
	score_changed.emit(state.current_player, player.score, points)
	stones_captured.emit([cap_idx], points)
	SoundManager.play_capture(captured.size())

	# Trap trigger
	if trap_hit:
		trap_triggered.emit(cap_idx, state.current_player)
		player.score    -= 3
		score_changed.emit(state.current_player, player.score, -3)
		_skip_victim     = state.current_player
		SoundManager.play_trap_trigger()

	await get_tree().create_timer(0.18).timeout   # capture animation time

	# Chain capture check
	var n1_idx := state.next_cell_index(cap_idx, state.direction)
	var n2_idx := state.next_cell_index(n1_idx, state.direction)
	var n1     := state.board[n1_idx]
	var n2     := state.board[n2_idx]

	if n1.is_empty() and n1.cell_type != "quan" and not n2.is_empty():
		if state.current_player == 1:
			_set_phase(GameEnums.Phase.CAPTURE_CONFIRM)
			capture_confirm_needed.emit(n1_idx)
			await capture_confirmed
		await _capture(n2_idx)
	else:
		await _on_spread_done()

# ── Post-spread finalize ──────────────────────────────────────────────────────
func _on_spread_done() -> void:
	_set_phase(GameEnums.Phase.EFFECT_TRIGGER)
	for p in state.players:
		p.tick_buffs()
	await _end_turn()

# ── Turn end ──────────────────────────────────────────────────────────────────
func _end_turn() -> void:
	_set_phase(GameEnums.Phase.TURN_END)
	state.turn_count      += 1
	_turns_since_gold     += 1
	_turns_since_dark     += 1

	_check_auto_spawn()
	_check_special_spawn()

	if state.are_both_quan_empty():
		_do_game_over()
		return

	# Buyback if a side is empty
	for pid in range(2):
		if state.is_player_side_empty(pid):
			_do_buyback(pid)

	state.current_player = 1 - state.current_player
	turn_ended.emit(state.current_player)
	board_changed.emit()

	# Longer pause when handing over to AI so the player can see the board
	var delay := 1.5 if state.current_player == 0 else 0.25
	await get_tree().create_timer(delay).timeout
	_start_turn()

# ── Lộc Trời Cho ──────────────────────────────────────────────────────────────
func _check_auto_spawn() -> void:
	for cell in state.board:
		if cell.cell_type != "normal":
			continue
		if cell.is_empty() and not cell.auto_spawned:
			cell.empty_turns += 1
			if cell.empty_turns >= 3:
				var s := StoneData.new("auto_%d_%d" % [cell.index, state.turn_count],
						GameEnums.StoneType.NORMAL, cell.owner)
				cell.add_stone(s)
				cell.auto_spawned = true
				cell.empty_turns  = 0
				auto_spawn_triggered.emit(cell.index)
		elif not cell.is_empty():
			cell.empty_turns = 0

# ── Special stone spawn (every 5 / 7 turns) ───────────────────────────────────
func _check_special_spawn() -> void:
	if _turns_since_gold >= 5 and _gold_on_board < 2:
		_spawn_special(GameEnums.StoneType.GOLD)
		_turns_since_gold  = 0
		_gold_on_board    += 1
	if _turns_since_dark >= 7 and _dark_on_board < 1:
		_spawn_special(GameEnums.StoneType.DARK)
		_turns_since_dark  = 0
		_dark_on_board    += 1

func _spawn_special(stype: GameEnums.StoneType) -> void:
	var eligible: Array[int] = []
	for i in range(10):
		if not state.board[i].is_empty():
			eligible.append(i)
	if eligible.is_empty():
		return
	eligible.shuffle()
	var target := eligible[0]
	var cell   := state.board[target]
	for i in range(cell.stones.size()):
		if cell.stones[i].type == GameEnums.StoneType.NORMAL:
			cell.stones[i] = StoneData.new(
					"sp_%d_%d" % [target, state.turn_count], stype, cell.owner)
			special_stone_spawned.emit(target, stype)
			board_changed.emit()
			return

# ── Buyback ───────────────────────────────────────────────────────────────────
func _do_buyback(pid: int) -> void:
	var player := state.players[pid]
	var start  := 0 if pid == 0 else 5
	for i in range(5):
		if player.score_reserve <= 0:
			break
		var s := StoneData.new("buy_%d_%d" % [start + i, state.turn_count],
				GameEnums.StoneType.NORMAL, pid)
		state.board[start + i].add_stone(s)
		player.score_reserve -= 1
		stone_placed.emit(start + i, s)

# ── Game over ─────────────────────────────────────────────────────────────────
func _do_game_over() -> void:
	_set_phase(GameEnums.Phase.GAME_OVER)
	for pid in range(2):
		for cell in state.get_player_cells(pid):
			for s in cell.stones:
				state.players[pid].score += s.value
	var scores := [state.players[0].score, state.players[1].score]
	var winner := -1
	if scores[0] > scores[1]:
		winner = 0
	elif scores[1] > scores[0]:
		winner = 1
	game_over.emit(winner, scores)

# ── Timer expired ─────────────────────────────────────────────────────────────
func _on_timer_expired() -> void:
	var valid := state.get_valid_moves(state.current_player)
	if not valid.is_empty():
		player_select_cell(valid[0])

# ── Helper ────────────────────────────────────────────────────────────────────
func _set_phase(p: GameEnums.Phase) -> void:
	state.phase = p
	phase_changed.emit(p)
