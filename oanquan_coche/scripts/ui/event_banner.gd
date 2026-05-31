extends CanvasLayer
# EventBanner.gd — Hàng đợi thông báo sự kiện đặc biệt
# Mỗi thông báo trượt vào từ trên, hiện 1.8s, rồi trượt ra
# Hỗ trợ queue: tối đa 3 thông báo xếp chồng nhau

const SLIDE_IN_TIME  := 0.28
const HOLD_TIME      := 1.8
const SLIDE_OUT_TIME := 0.22
const BANNER_H       := 72.0
const BANNER_W       := 560.0
const BANNER_Y_START := 115.0   # dưới timer bar
const STACK_GAP      := 80.0

# Mỗi item trong queue: { text, color, icon, cell_index }
var _queue: Array       = []
var _active: Array      = []   # các banner đang hiển thị (tối đa 3)
var _is_processing: bool = false

func _ready() -> void:
	layer = 8   # trên HUD (default 0), dưới ScreenEffects (10)
	add_to_group("event_banner")   # để Board.gd tìm được qua get_first_node_in_group
	# Kết nối signals từ GameManager
	GameManager.auto_spawn_triggered.connect(_on_auto_spawn)
	GameManager.special_stone_spawned.connect(_on_special_spawn)
	GameManager.trap_triggered.connect(_on_trap)

# ── Public: thêm thông báo vào queue ─────────────────────────────────────────
func push(text: String, color: Color, icon: String = "", cell_index: int = -1) -> void:
	_queue.append({ "text": text, "color": color, "icon": icon, "cell": cell_index })
	if not _is_processing:
		_process_queue()

# ── Xử lý queue ──────────────────────────────────────────────────────────────
func _process_queue() -> void:
	if _queue.is_empty():
		_is_processing = false
		return
	_is_processing = true
	var item := _queue.pop_front() as Dictionary
	_show_banner(item)

func _show_banner(item: Dictionary) -> void:
	# --- Tạo panel container ---
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(BANNER_W, BANNER_H)

	var style := StyleBoxFlat.new()
	style.bg_color             = item["color"].darkened(0.35)
	style.border_color         = item["color"]
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color         = Color(0, 0, 0, 0.5)
	style.shadow_size          = 6
	panel.add_theme_stylebox_override("panel", style)

	# --- Label bên trong ---
	var lbl := Label.new()
	var full_text: String = (item["icon"] + "  " if item["icon"] != "" else "") + item["text"]
	lbl.text = full_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	panel.add_child(lbl)

	# --- Vị trí ban đầu (ngoài màn hình, bên trên) ---
	var vp_w  := get_viewport().get_visible_rect().size.x
	var x_pos := (vp_w - BANNER_W) * 0.5
	var y_pos := BANNER_Y_START + _active.size() * STACK_GAP
	panel.position = Vector2(x_pos, y_pos - BANNER_H - 20.0)
	panel.modulate = Color(1, 1, 1, 0.0)
	add_child(panel)
	_active.append(panel)

	# --- Hiệu ứng ô nhấp nháy nếu có cell_index ---
	if item["cell"] >= 0:
		_pulse_cell(item["cell"], item["color"])

	# --- Animation: trượt vào ---
	var tw_in := create_tween()
	tw_in.set_parallel(true)
	tw_in.tween_property(panel, "position:y", y_pos, SLIDE_IN_TIME)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw_in.tween_property(panel, "modulate:a", 1.0, SLIDE_IN_TIME)\
		.set_ease(Tween.EASE_OUT)
	await tw_in.finished

	# --- Giữ ---
	await get_tree().create_timer(HOLD_TIME).timeout

	# --- Animation: trượt ra ---
	var tw_out := create_tween()
	tw_out.set_parallel(true)
	tw_out.tween_property(panel, "position:y", y_pos - BANNER_H - 20.0, SLIDE_OUT_TIME)\
		.set_ease(Tween.EASE_IN)
	tw_out.tween_property(panel, "modulate:a", 0.0, SLIDE_OUT_TIME)\
		.set_ease(Tween.EASE_IN)
	await tw_out.finished

	_active.erase(panel)
	panel.queue_free()

	# --- Tiếp tục queue ---
	await get_tree().create_timer(0.08).timeout
	_process_queue()

# ── Nhấp nháy ô bị ảnh hưởng (gọi vào Board qua signal riêng) ────────────────
signal cell_pulse_requested(cell_index: int, color: Color)

func _pulse_cell(cell_index: int, color: Color) -> void:
	cell_pulse_requested.emit(cell_index, color)

# ── Signal handlers ───────────────────────────────────────────────────────────
func _on_auto_spawn(cell_index: int) -> void:
	push(
		"Lộc Trời Cho! Ô %d sinh quân mới" % cell_index,
		Color("4caf50"),   # xanh lá
		"🌱",
		cell_index
	)

func _on_special_spawn(cell_index: int, stone_type: GameEnums.StoneType) -> void:
	match stone_type:
		GameEnums.StoneType.GOLD:
			push(
				"Quân Vàng xuất hiện tại ô %d!" % cell_index,
				Color("ffd700"),   # vàng
				"⭐",
				cell_index
			)
		GameEnums.StoneType.DARK:
			push(
				"Một quân bí ẩn đang ẩn mình...",
				Color("7b2d8b"),   # tím tối — không tiết lộ ô
				"🌑",
				-1   # -1 = không highlight ô (vì DARK ẩn danh)
			)

func _on_trap(cell_index: int, victim_player: int) -> void:
	var who: String = "Bạn" if victim_player == 1 else "AI"
	push(
		"Bẫy kích hoạt! %s mất 3 điểm + lượt" % who,
		Color("e53935"),   # đỏ
		"💀",
		cell_index
	)
