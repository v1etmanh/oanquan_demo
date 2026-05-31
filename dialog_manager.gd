## dialog_manager.gd
## Autoload singleton — quản lý toàn bộ hệ thống dialog
## Thêm vào Project > Project Settings > Autoload với tên "DialogManager"
##
## Cách dùng:
##   DialogManager.show_dialog_for("ong_nhieu")   ← load từ JSON tự động
##   DialogManager.dialog_closed.connect(_on_dialog_closed)
##
## Cấu trúc dialogs.json:
##   { "npc_id": { "sessions": [ { "lines": [ {"speaker":"...", "text":"..."} ] } ] } }
##   speaker = npc_id | "lan_anh" | "action"
##   "action" → hiển thị in nghiêng, không có tên nhân vật

extends Node

# ── Signals ──────────────────────────────────────────────────────────────────
signal dialog_opened(npc_id: String)
signal dialog_closed(npc_id: String)
signal line_advanced(line_index: int)

# ── JSON data (load từ assets/dialogs.json lúc _ready) ───────────────────────
var _dialog_data: Dictionary = {}   # toàn bộ JSON

# ── State ─────────────────────────────────────────────────────────────────────
var is_open: bool = false
var _current_npc_id: String = ""
## Mỗi phần tử là Dictionary { "speaker": String, "text": String }
var _lines: Array = []
var _line_index: int = 0

# ── Typewriter ────────────────────────────────────────────────────────────────
const TYPEWRITER_SPEED := 0.03   # giây mỗi ký tự
var _typewriter_timer: float = 0.0
var _char_index: int = 0
var _full_text: String = ""      # text thuần (không có BBCode wrapper)
var _bbcode_prefix: String = ""  # ví dụ "[i]" cho action line
var _bbcode_suffix: String = ""  # ví dụ "[/i]" cho action line
var _typing: bool = false

# ── UI refs (set bởi DialogUI.gd khi scene ready) ────────────────────────────
var _ui_panel: Control        = null
var _ui_speaker: Label        = null
var _ui_text: RichTextLabel   = null
var _ui_next_btn: Button      = null

# ── Speaker display names ─────────────────────────────────────────────────────
const SPEAKER_NAMES := {
	"ong_nhieu"   : "Ông Nhiêu",
	"ba_tu"       : "Bà Tư",
	"minh"        : "Minh",
	"hung"        : "Hùng",
	"young_boy"   : "Bé trai",
	"young_girl"  : "Bé gái",
	"npc_nu"      : "Người làng",
	"oanquanboy"  : "Thằng Bi",
	"lan_anh"     : "Lan Anh",
	"action"      : "",   # dòng mô tả — không hiện tên
}

# ── Game state: đã nói chuyện lần nào chưa ────────────────────────────────────
var talked_to: Dictionary = {}   # { "ong_nhieu": 0 }  → số lần đã nói

# =============================================================================
func _ready() -> void:
	_load_dialogs()

## Load file dialogs.json từ res://assets/dialogs.json
func _load_dialogs() -> void:
	const PATH := "res://assets/dialogs.json"
	if not FileAccess.file_exists(PATH):
		push_error("DialogManager: Không tìm thấy %s" % PATH)
		return
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_error("DialogManager: Không mở được %s" % PATH)
		return
	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_error("DialogManager: Lỗi parse JSON tại dòng %d — %s" % [json.get_error_line(), json.get_error_message()])
		return
	_dialog_data = json.get_data()
	print("DialogManager: Loaded dialogs.json — %d NPCs" % _dialog_data.size())

# =============================================================================
func _process(delta: float) -> void:
	if not _typing:
		return
	_typewriter_timer -= delta
	if _typewriter_timer <= 0.0:
		_typewriter_timer = TYPEWRITER_SPEED
		_char_index += 1
		if _char_index >= _full_text.length():
			_char_index = _full_text.length()
			_typing = false
			if _ui_next_btn:
				_ui_next_btn.visible = true
		if _ui_text:
			# Godot 4: dùng .text — RichTextLabel tự parse BBCode khi bbcode_enabled=true
			_ui_text.text = _bbcode_prefix + _full_text.substr(0, _char_index) + _bbcode_suffix

# =============================================================================
## API chính: NPC gọi hàm này, dialog_manager tự tra JSON
func show_dialog_for(npc_id: String) -> void:
	if is_open:
		return
	if _ui_panel == null:
		push_warning("DialogManager: UI chưa register — DialogUI chưa ready? npc=%s" % npc_id)
		return
	var lines := get_dialog_lines(npc_id)
	if lines.is_empty():
		push_warning("DialogManager: Không có dialog cho '%s' (session %d)" % [npc_id, talk_count(npc_id)])
		return
	_open_dialog(npc_id, lines)

## Lấy array lines cho session hiện tại của NPC (dùng nội bộ hoặc debug)
## Trả về Array of Dictionary {"speaker": String, "text": String}
func get_dialog_lines(npc_id: String) -> Array:
	if not _dialog_data.has(npc_id):
		push_warning("DialogManager: NPC '%s' không có trong dialogs.json" % npc_id)
		return []
	var npc_entry: Dictionary = _dialog_data[npc_id]
	var sessions: Array = npc_entry.get("sessions", [])
	if sessions.is_empty():
		return []
	# Clamp session index — session cuối lặp lại mãi
	var session_idx := mini(talk_count(npc_id), sessions.size() - 1)
	var session: Dictionary = sessions[session_idx]
	return session.get("lines", [])

## API cũ (backward-compat): nhận Array[String] thuần — chuyển sang structured
func show_dialog(npc_id: String, lines: Array[String]) -> void:
	if is_open or lines.is_empty():
		return
	var structured: Array = []
	for text in lines:
		structured.append({ "speaker": npc_id, "text": text })
	_open_dialog(npc_id, structured)

## Internal — mở dialog với structured lines
func _open_dialog(npc_id: String, lines: Array) -> void:
	is_open = true
	_current_npc_id = npc_id
	_lines = lines
	_line_index = 0

	# Đếm lần nói chuyện
	if npc_id not in talked_to:
		talked_to[npc_id] = 0
	talked_to[npc_id] += 1

	_show_ui()
	_display_line(_line_index)
	emit_signal("dialog_opened", npc_id)

## Gọi khi player bấm Space / tap nút Tiếp
func next_line() -> void:
	if not is_open:
		return

	# Nếu đang gõ → skip → hiện full ngay
	if _typing:
		_typing = false
		_char_index = _full_text.length()
		if _ui_text:
			_ui_text.text = _bbcode_prefix + _full_text + _bbcode_suffix
		if _ui_next_btn:
			_ui_next_btn.visible = true
		return

	_line_index += 1
	if _line_index >= _lines.size():
		close_dialog()
	else:
		_display_line(_line_index)
		emit_signal("line_advanced", _line_index)

func close_dialog() -> void:
	if not is_open:
		return
	is_open = false
	var closed_id := _current_npc_id
	_current_npc_id = ""
	_lines = []
	_line_index = 0
	_typing = false
	_hide_ui()
	emit_signal("dialog_closed", closed_id)

# =============================================================================
func _display_line(idx: int) -> void:
	var line_dict: Dictionary = _lines[idx]
	var speaker: String = line_dict.get("speaker", _current_npc_id)
	_full_text = line_dict.get("text", "")

	print("_display_line: idx=%d | speaker='%s' | text='%s' | text_len=%d" % [
		idx, speaker, _full_text, _full_text.length()
	])

	_char_index = 0
	_typewriter_timer = 0.0   # fire ngay frame đầu để hiện ký tự 1 liền

	if _full_text.length() == 0:
		_typing = false
		if _ui_next_btn:
			_ui_next_btn.visible = true
	else:
		_typing = true

	# Cập nhật tên người nói
	if _ui_speaker:
		if speaker == "action":
			_ui_speaker.text = ""          # dòng mô tả hành động — không tên
		else:
			_ui_speaker.text = SPEAKER_NAMES.get(speaker, speaker)

	# Dòng "action" → hiển thị in nghiêng bằng BBCode
	if _ui_text:
		_ui_text.text = ""
		_ui_text.bbcode_enabled = true
	if speaker == "action":
		_bbcode_prefix = "[i]"
		_bbcode_suffix = "[/i]"
	else:
		_bbcode_prefix = ""
		_bbcode_suffix = ""

	if _ui_next_btn:
		_ui_next_btn.visible = false

func _show_ui() -> void:
	if _ui_panel:
		_ui_panel.visible = true

func _hide_ui() -> void:
	if _ui_panel:
		_ui_panel.visible = false

## DialogUI.gd gọi hàm này để đăng ký các node UI
func register_ui(panel: Control, speaker: Label, text: RichTextLabel, btn: Button) -> void:
	_ui_panel   = panel
	_ui_speaker = speaker
	_ui_text    = text
	_ui_next_btn = btn
	_hide_ui()

## Tiện ích: đã nói chuyện với NPC này mấy lần?
func talk_count(npc_id: String) -> int:
	return talked_to.get(npc_id, 0)

## Debug: reload JSON lúc runtime (dùng trong editor)
func reload_dialogs() -> void:
	_dialog_data.clear()
	_load_dialogs()
