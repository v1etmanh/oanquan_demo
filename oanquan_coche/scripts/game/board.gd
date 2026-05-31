extends Node2D
# Board.gd — draws the 12 cells, handles tap input, spawns floating scores

# ── Layout constants (relative, recomputed in _ready) ────────────────────────
const CELL_W  := 88.0
const CELL_H  := 88.0
const QUAN_W  := 110.0
const QUAN_H  := 200.0

# Colors (board background removed — now using room_bg.png TextureRect)
const C_BOARD_BG   := Color("3d1f0a")
const C_CELL_NORM  := Color("8b5e3c")
const C_CELL_QUAN  := Color("5c2d00")
const C_CELL_SEL   := Color("f0a500")
const C_CELL_VALID := Color("a0c878")
const C_STONE_NRM  := Color("b0c4b1")
const C_STONE_GOLD := Color("ffd700")
const C_STONE_DARK := Color("2a0a0a")
const C_STONE_QUAN := Color("8b3a3a")
const C_TEXT       := Color("ffffff")
const C_TRAP_GLOW  := Color(1, 0.1, 0.1, 0.35)

# ── Hand sprite ───────────────────────────────────────────────────────────────
const HAND_SIZE        := Vector2(160, 160)   # display size của sprite tay
const HAND_HIDE_Y      := 1400.0              # vị trí ẩn bên dưới màn hình
const HAND_DROP_OFFSET := Vector2(0, -30.0)   # offset tay so với tâm ô khi thả
const HAND_DURATION    := 0.12               # thời gian tween di chuyển tay (giây)

var _hand_sprite: Sprite2D       = null
var _hand_tex_hold:    Texture2D = null   # hand_hold.png    — đang cầm sỏi
var _hand_tex_release: Texture2D = null   # hand_release.png — thả sỏi
var _hand_tex_lift:    Texture2D = null   # hand_lift.png    — rút tay lên
var _hand_tween: Tween           = null
var _hand_pos: Vector2           = Vector2(360, HAND_HIDE_Y)

# Computed at runtime
var CELL_POS: Dictionary = {}
var _board_rect: Rect2 = Rect2()

# Runtime state
var _highlighted_cells: Array[int] = []
var _last_spread_cell: int         = -1
var _flash_timer: float            = 0.0
var _captured_cells: Array[int]    = []
var _cap_flash_timer: float        = 0.0
var _special_glow: Dictionary      = {}
var _zoom_tween: Tween             = null
var _score_layer: CanvasLayer      = null
var _pending_cell: int             = -1
var _dir_btn_left: Rect2           = Rect2()
var _dir_btn_right: Rect2          = Rect2()
var _capture_empty_cell: int       = -1
var _capture_pulse: float          = 0.0

# Cell pulse từ EventBanner: { cell_index(int): { "phase": float, "color": Color } }
var _event_pulses: Dictionary      = {}
const EVENT_PULSE_DURATION := 2.2

func _ready() -> void:
	# Connect signals FIRST before any await
	GameManager.board_changed.connect(_on_board_changed)
	GameManager.hand_stone_dropped.connect(_on_stone_dropped)
	GameManager.stones_captured.connect(_on_captured)
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.capture_confirm_needed.connect(_on_capture_confirm_needed)
	_score_layer        = CanvasLayer.new()
	_score_layer.layer  = 5
	get_tree().root.add_child.call_deferred(_score_layer)
	_setup_hand()
	# Wait one frame for viewport to finalise, then build positions + redraw
	await get_tree().process_frame
	_build_cell_positions()
	_refresh_highlights()
	queue_redraw()
	# Kết nối EventBanner (đã ready cùng frame vì cùng scene)
	var banner := get_tree().get_first_node_in_group("event_banner")
	if banner and banner.has_signal("cell_pulse_requested"):
		banner.cell_pulse_requested.connect(_on_cell_pulse_requested)

func _setup_hand() -> void:
	_hand_sprite          = Sprite2D.new()
	_hand_sprite.centered = true
	_hand_sprite.position = Vector2(360, HAND_HIDE_Y)
	_hand_sprite.z_index  = 10   # nằm trên board, dưới HUD
	# Load texture — fallback gracefully nếu file chưa có
	var path_hold    := "res://assets/hand/hand_hold.png"
	var path_release := "res://assets/hand/hand_release.png"
	var path_lift    := "res://assets/hand/hand_lift.png"
	if ResourceLoader.exists(path_hold):
		_hand_tex_hold    = load(path_hold)
	if ResourceLoader.exists(path_release):
		_hand_tex_release = load(path_release)
	if ResourceLoader.exists(path_lift):
		_hand_tex_lift    = load(path_lift)
	if _hand_tex_hold:
		_hand_sprite.texture = _hand_tex_hold
		# Scale sprite về đúng HAND_SIZE bất kể kích thước ảnh gốc
		var tex_size := _hand_tex_hold.get_size()
		_hand_sprite.scale = Vector2(
			HAND_SIZE.x / tex_size.x,
			HAND_SIZE.y / tex_size.y
		)
	add_child(_hand_sprite)

func _on_cell_pulse_requested(cell_index: int, color: Color) -> void:
	if cell_index < 0:
		return
	_event_pulses[cell_index] = { "phase": 0.0, "color": color, "elapsed": 0.0 }
	queue_redraw()

func _build_cell_positions() -> void:
	var vp := get_viewport().get_visible_rect().size
	if vp.x < 100 or vp.y < 100:
		vp = Vector2(720, 1280)

	# ── Tính vùng khả dụng ───────────────────────────────────────────────────
	var HUD_H   := 110.0   # chiều cao HUD trên đầu (score + timer bar)
	var PAD_H   := 16.0    # padding dưới cùng
	var PAD_W   := 20.0    # padding 2 bên trái/phải
	var avail_w := vp.x - PAD_W * 2.0
	var avail_h := vp.y - HUD_H - PAD_H

	# Board content width  = QUAN_W * 2 + CELL_W * 5 + gap * 6  ≈ 700 (ở scale 1)
	# Board content height = QUAN_H                               ≈ 200 (ở scale 1)
	# Lấy scale nhỏ hơn để board luôn nằm gọn trong viewport
	var scale := minf(avail_w / 700.0, avail_h / 200.0)

	var cw  := CELL_W * scale
	var ch  := CELL_H * scale
	var qw  := QUAN_W * scale
	var qh  := QUAN_H * scale
	var gap := 6.0 * scale

	var cx      := vp.x * 0.5
	var cy      := HUD_H + avail_h * 0.5   # tâm dọc của vùng khả dụng

	var row_w   := 5.0 * cw + 4.0 * gap
	var x0      := cx - row_w * 0.5
	var row_top := cy - ch * 0.5 - gap * 0.5
	var row_bot := cy + ch * 0.5 + gap * 0.5
	var qx0     := x0 - qw - gap
	var qx1     := x0 + row_w + gap

	CELL_POS = {
		10: Vector2(qx0 + qw * 0.5,  cy),
		0:  Vector2(x0 + cw * 0.5,               row_top),
		1:  Vector2(x0 + cw * 1.5 + gap,         row_top),
		2:  Vector2(x0 + cw * 2.5 + gap * 2,     row_top),
		3:  Vector2(x0 + cw * 3.5 + gap * 3,     row_top),
		4:  Vector2(x0 + cw * 4.5 + gap * 4,     row_top),
		11: Vector2(qx1 + qw * 0.5,  cy),
		5:  Vector2(x0 + cw * 4.5 + gap * 4,     row_bot),
		6:  Vector2(x0 + cw * 3.5 + gap * 3,     row_bot),
		7:  Vector2(x0 + cw * 2.5 + gap * 2,     row_bot),
		8:  Vector2(x0 + cw * 1.5 + gap,         row_bot),
		9:  Vector2(x0 + cw * 0.5,               row_bot),
	}
	_board_rect = Rect2(qx0, cy - qh * 0.5 - 8, qx1 + qw - qx0, qh + 16)

func _on_board_changed() -> void:
	_refresh_highlights()
	queue_redraw()

func _on_stone_dropped(cell_index: int, _stone: StoneData) -> void:
	_last_spread_cell = cell_index
	_flash_timer      = 0.22
	queue_redraw()
	_animate_hand_to(cell_index)

func _animate_hand_to(cell_index: int) -> void:
	if _hand_sprite == null:
		return
	var target_pos := (CELL_POS.get(cell_index, Vector2(360, 640)) as Vector2) + HAND_DROP_OFFSET
	if _hand_tween:
		_hand_tween.kill()
	_hand_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	# 1. Đặt texture hold, tween đến ô mới
	if _hand_tex_hold:
		_hand_sprite.texture = _hand_tex_hold
	_hand_tween.tween_property(_hand_sprite, "position", target_pos, HAND_DURATION)
	# 2. Đổi sang texture release (thả sỏi)
	_hand_tween.tween_callback(func():
		if _hand_tex_release:
			_hand_sprite.texture = _hand_tex_release
	)
	_hand_tween.tween_interval(0.08)
	# 3. Đổi sang texture lift (rút tay lên) rồi ẩn xuống dưới
	_hand_tween.tween_callback(func():
		if _hand_tex_lift:
			_hand_sprite.texture = _hand_tex_lift
	)
	_hand_tween.tween_interval(0.06)
	_hand_tween.tween_property(_hand_sprite, "position",
		Vector2(target_pos.x, HAND_HIDE_Y), HAND_DURATION * 0.8)
	# 4. Reset texture về hold cho lượt tiếp theo
	_hand_tween.tween_callback(func():
		if _hand_tex_hold:
			_hand_sprite.texture = _hand_tex_hold
	)

func _on_captured(cell_indices: Array, pts: int) -> void:
	_captured_cells.clear()
	for idx in cell_indices:
		_captured_cells.append(int(idx))
	_cap_flash_timer  = 0.35
	queue_redraw()
	if pts > 0 and not cell_indices.is_empty():
		_spawn_floating_score(pts, cell_indices[0])

func _on_phase_changed(phase: GameEnums.Phase) -> void:
	if phase == GameEnums.Phase.WAITING:
		_refresh_highlights()
		_capture_empty_cell = -1
	elif phase == GameEnums.Phase.CAPTURE_CONFIRM:
		pass  # handled by _on_capture_confirm_needed signal
	else:
		_highlighted_cells.clear()
		_pending_cell       = -1
		_capture_empty_cell = -1
	queue_redraw()

func _on_capture_confirm_needed(empty_cell_idx: int) -> void:
	_capture_empty_cell = empty_cell_idx
	_highlighted_cells  = [empty_cell_idx]
	_capture_pulse      = 0.0
	queue_redraw()

func _refresh_highlights() -> void:
	if GameManager.state == null or \
			GameManager.state.current_player != 1:
		_highlighted_cells.clear()
		return
	_highlighted_cells = GameManager.state.get_valid_moves(1)

func _process(delta: float) -> void:
	var needs_redraw := false
	if _flash_timer > 0.0:
		_flash_timer -= delta
		needs_redraw  = true
	if _cap_flash_timer > 0.0:
		_cap_flash_timer -= delta
		needs_redraw       = true
	if _capture_empty_cell >= 0:
		_capture_pulse = fmod(_capture_pulse + delta * 4.0, TAU)
		needs_redraw   = true
	# Shimmer pulse for GOLD/DARK stones
	for key in _special_glow.keys():
		_special_glow[key] = fmod(_special_glow[key] + delta * 2.5, TAU)
	if not _special_glow.is_empty():
		needs_redraw = true
	# Event pulse (Lộc Trời Cho / GOLD spawn / trap)
	var to_remove_pulse: Array = []
	for cell_idx in _event_pulses.keys():
		var ep := _event_pulses[cell_idx] as Dictionary
		ep["elapsed"] += delta
		ep["phase"]    = fmod(ep["phase"] + delta * 5.0, TAU)
		if ep["elapsed"] >= EVENT_PULSE_DURATION:
			to_remove_pulse.append(cell_idx)
		needs_redraw = true
	for key in to_remove_pulse:
		_event_pulses.erase(key)
	if needs_redraw:
		queue_redraw()

func _draw() -> void:
	if GameManager.state == null or CELL_POS.is_empty():
		return
	# Board background giờ là room_bg.png TextureRect trong scene
	# Chỉ vẽ overlay tối mờ lên vùng board để ô nổi rõ hơn trên nền ảnh
	draw_rect(_board_rect, Color(0, 0, 0, 0.35), true)
	for idx in CELL_POS.keys():
		_draw_cell(idx)
	if _pending_cell >= 0:
		_draw_direction_buttons()

func _get_cell_size(is_quan: bool) -> Vector2:
	var vp    := get_viewport().get_visible_rect().size
	var scale := minf((vp.x - 40.0) / 700.0, 1.0)
	if is_quan:
		return Vector2(QUAN_W * scale, QUAN_H * scale)
	return Vector2(CELL_W * scale, CELL_H * scale)

func _draw_cell(idx: int) -> void:
	var state   := GameManager.state
	var cell    := state.board[idx]
	var center  := CELL_POS[idx] as Vector2
	var is_quan := cell.cell_type == "quan"
	var sz      := _get_cell_size(is_quan)
	var cw      := sz.x
	var ch      := sz.y
	var rect    := Rect2(center.x - cw * 0.5, center.y - ch * 0.5, cw, ch)

	# ── Cell background ───────────────────────────────────────────────────────
	var bg := C_CELL_QUAN if is_quan else C_CELL_NORM
	if idx in _highlighted_cells:
		bg = C_CELL_VALID
	# Capture-confirm pulse: bright orange-red pulsing on the target empty cell
	if idx == _capture_empty_cell:
		var pulse := (sin(_capture_pulse) * 0.5 + 0.5)
		bg = Color(0.95, 0.35 + pulse * 0.2, 0.05, 1.0)
	if _cap_flash_timer > 0.0 and idx in _captured_cells:
		bg = bg.lerp(Color.WHITE, _cap_flash_timer * 2.0)
	draw_rect(rect, bg, true, -1, true)
	draw_rect(rect, Color(0, 0, 0, 0.4), false, 2.0, true)

	# ── Spread flash ──────────────────────────────────────────────────────────
	if _flash_timer > 0.0 and idx == _last_spread_cell:
		draw_rect(rect, Color(1, 1, 0.5, _flash_timer * 2.5), true, -1, true)

	# ── Trap glow ─────────────────────────────────────────────────────────────
	if cell.trap_active:
		draw_rect(rect, C_TRAP_GLOW, true, -1, true)

	# ── Event pulse (Lộc Trời Cho / GOLD spawn / trap notify) ────────────────
	if idx in _event_pulses:
		var ep       := _event_pulses[idx] as Dictionary
		var ep_color := ep["color"] as Color
		var fade     : float = 1.0 - (float(ep["elapsed"]) / EVENT_PULSE_DURATION)
		var pulse_a  : float = (sin(ep["phase"]) * 0.5 + 0.5) * fade * 0.65
		# Vẽ viền nhấp nháy màu theo loại sự kiện
		var border_rect := Rect2(rect.position.x - 3, rect.position.y - 3, rect.size.x + 6, rect.size.y + 6)
		draw_rect(border_rect, Color(ep_color.r, ep_color.g, ep_color.b, pulse_a + 0.15), false, 3.5, true)
		# Phủ màu nhẹ bên trong
		draw_rect(rect, Color(ep_color.r, ep_color.g, ep_color.b, pulse_a * 0.4), true, -1, true)

	# ── Draw stones ───────────────────────────────────────────────────────────
	var count := cell.stone_count()
	if count == 0:
		return

	if is_quan or count > 9:
		# Just show count number
		_draw_label(center, str(count), 22)
	else:
		_draw_stone_dots(cell, center, cw, ch)

func _draw_stone_dots(cell: CellData, center: Vector2, cw: float, ch: float) -> void:
	var count   := cell.stone_count()
	var radius  := clampf(14.0 - count * 0.5, 7.0, 14.0)
	var cols    := mini(count, 3)
	var rows    := ceili(float(count) / float(cols))
	var pad_x   := (cw - cols * radius * 2.2) * 0.5
	var pad_y   := (ch - rows * radius * 2.2) * 0.5

	for i in range(count):
		var col     := i % cols
		var row     := int(i / float(cols))
		var sx      := center.x - cw * 0.5 + pad_x + col * radius * 2.2 + radius
		var sy      := center.y - ch * 0.5 + pad_y + row * radius * 2.2 + radius
		var stype   := cell.stones[i].type
		var sc      := _stone_color(stype)

		# Special glow for GOLD
		if stype == GameEnums.StoneType.GOLD:
			var glow_r := radius * (1.0 + 0.15 * sin(_special_glow.get(cell.index, 0.0)))
			draw_circle(Vector2(sx, sy), glow_r + 3, Color(1, 0.9, 0, 0.4))

		draw_circle(Vector2(sx, sy), radius, sc)
		draw_circle(Vector2(sx, sy), radius, Color(0, 0, 0, 0.2), false, 1.0)

func _stone_color(stype: GameEnums.StoneType) -> Color:
	match stype:
		GameEnums.StoneType.GOLD:   return C_STONE_GOLD
		GameEnums.StoneType.DARK:   return C_STONE_NRM   # disguised as normal!
		GameEnums.StoneType.QUAN:   return C_STONE_QUAN
		_:                          return C_STONE_NRM

func _draw_label(pos: Vector2, text: String, size: int) -> void:
	draw_string(ThemeDB.fallback_font, pos + Vector2(-size * 0.3, size * 0.4),
			text, HORIZONTAL_ALIGNMENT_CENTER, -1, size, C_TEXT)

func _draw_direction_buttons() -> void:
	var vp    := get_viewport().get_visible_rect().size
	var btn_w := 140.0
	var btn_h := 54.0
	var gap   := 24.0
	var cx    := vp.x * 0.5
	var cy    := _board_rect.end.y + 48.0

	_dir_btn_left  = Rect2(cx - btn_w - gap * 0.5, cy, btn_w, btn_h)
	_dir_btn_right = Rect2(cx + gap * 0.5,          cy, btn_w, btn_h)

	# Highlight selected cell with bright outline
	if _pending_cell in CELL_POS:
		var ctr := CELL_POS[_pending_cell] as Vector2
		var sz  := _get_cell_size(false)
		var r   := Rect2(ctr.x - sz.x * 0.5 - 3, ctr.y - sz.y * 0.5 - 3, sz.x + 6, sz.y + 6)
		draw_rect(r, Color(1, 0.9, 0.1, 0.9), false, 3.0, true)

	# Left button (← Trái = CLOCKWISE)
	draw_rect(_dir_btn_left,  Color(0.15, 0.45, 0.85, 0.92), true,  -1,  true)
	draw_rect(_dir_btn_left,  Color(1, 1, 1, 0.6),            false, 2.5, true)
	_draw_label(_dir_btn_left.get_center(),  "← Trái",  22)

	# Right button (Phải → = COUNTER_CLOCKWISE)
	draw_rect(_dir_btn_right, Color(0.75, 0.28, 0.05, 0.92), true,  -1,  true)
	draw_rect(_dir_btn_right, Color(1, 1, 1, 0.6),            false, 2.5, true)
	_draw_label(_dir_btn_right.get_center(), "Phải →", 22)

# ── Input handling ────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if GameManager.state == null:
		return
	if GameManager.state.current_player != 1:
		return   # only player 1 (human) taps

	var tap_pos: Vector2 = Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		tap_pos = event.position
	elif event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		tap_pos = event.position
	else:
		return

	# Capture confirmation: player must click the pulsing empty cell
	if GameManager.state.phase == GameEnums.Phase.CAPTURE_CONFIRM:
		if _capture_empty_cell >= 0 and _capture_empty_cell in CELL_POS:
			var ctr := CELL_POS[_capture_empty_cell] as Vector2
			var sz  := _get_cell_size(false)
			if abs(tap_pos.x - ctr.x) <= sz.x * 0.5 and \
					abs(tap_pos.y - ctr.y) <= sz.y * 0.5:
				var confirmed_cell := _capture_empty_cell
				_capture_empty_cell = -1
				GameManager.player_confirm_capture(confirmed_cell)
		return

	if GameManager.state.phase != GameEnums.Phase.WAITING:
		return

	# Direction button handling
	if _pending_cell >= 0:
		if _dir_btn_left.has_point(tap_pos):
			var c := _pending_cell
			_pending_cell = -1
			_do_zoom_effect()
			GameManager.player_select_cell_with_direction(c, GameEnums.Direction.CLOCKWISE)
		elif _dir_btn_right.has_point(tap_pos):
			var c := _pending_cell
			_pending_cell = -1
			_do_zoom_effect()
			GameManager.player_select_cell_with_direction(c, GameEnums.Direction.COUNTER_CLOCKWISE)
		else:
			# Tap elsewhere: cancel selection
			_pending_cell = -1
			queue_redraw()
		return

	var hit := _cell_at(tap_pos)
	if hit >= 0 and hit in _highlighted_cells:
		_pending_cell = hit
		queue_redraw()

func _cell_at(pos: Vector2) -> int:
	for idx in CELL_POS.keys():
		var center  := CELL_POS[idx] as Vector2
		var is_quan := GameManager.state.board[idx].cell_type == "quan"
		var sz      := _get_cell_size(is_quan)
		if abs(pos.x - center.x) <= sz.x * 0.5 and abs(pos.y - center.y) <= sz.y * 0.5:
			return idx
	return -1

# ── Special glow tracking ─────────────────────────────────────────────────────
func _update_special_glow() -> void:
	if GameManager.state == null:
		return
	_special_glow.clear()
	for i in range(10):
		for s in GameManager.state.board[i].stones:
			if s.type in [GameEnums.StoneType.GOLD, GameEnums.StoneType.DARK]:
				_special_glow[i] = _special_glow.get(i, 0.0)

# ── Floating score popup ──────────────────────────────────────────────────────
func _spawn_floating_score(pts: int, cell_index: int) -> void:
	if _score_layer == null:
		return
	var world_pos: Vector2 = CELL_POS.get(cell_index, Vector2(360, 540))
	var lbl := FloatingScore.new()
	var color := Color("ffd700") if pts >= 10 else \
				 Color("a8e6a3") if pts >= 4  else Color("ffffff")
	lbl._init_popup("+%d" % pts, color, world_pos)
	_score_layer.add_child(lbl)

# ── Camera zoom on cell select ────────────────────────────────────────────────
func _do_zoom_effect() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	if _zoom_tween:
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(cam, "zoom", Vector2(1.05, 1.05), 0.15)\
		.set_ease(Tween.EASE_OUT)
	_zoom_tween.tween_property(cam, "zoom", Vector2(1.0, 1.0), 0.15)\
		.set_ease(Tween.EASE_IN)
