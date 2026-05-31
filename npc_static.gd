## npc_static.gd
## Dành cho: ong_gia (ông Nhiêu), ba_gia (bà Tư), minh, hung, oanquanboy
## Đứng idle tại chỗ. Khi Lan Anh đến đủ gần → dialog mở từ assets/dialogs.json
##
## Setup trong Inspector:
##   npc_id        → "ong_nhieu" / "ba_tu" / "minh" / "hung" / "oanquanboy"
##   detect_radius → khoảng cách (px world space) để trigger dialog (default 80)

extends CharacterBody2D

@export var npc_id: String = "ong_nhieu"
@export var detect_radius: float = 80.0   # world-space pixels, không bị ảnh hưởng bởi scale

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _player: Node2D = null
var _triggered: bool = false   # tránh trigger liên tục khi đứng gần

# =============================================================================
func _ready() -> void:
	anim.play("idle")
	# Tìm Lan Anh sau 1 frame để đảm bảo scene đã load xong
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("lan_anh")
	if _player:
		print("npc_static [%s]: found player=%s | my_pos=%s | detect_radius=%.0f" % [
			npc_id, _player.name, global_position, detect_radius
		])
	else:
		push_warning("npc_static [%s]: Không tìm thấy node trong group 'lan_anh'!" % npc_id)

func _physics_process(_delta: float) -> void:
	if _player == null or DialogManager.is_open:
		if _player == null:
			# Thử tìm lại nếu chưa có
			_player = get_tree().get_first_node_in_group("lan_anh")
		return

	var dist := global_position.distance_to(_player.global_position)

	if dist <= detect_radius and not _triggered:
		_triggered = true
		print("npc_static [%s]: ✅ Lan Anh vào vùng — dist=%.1f — opening dialog" % [npc_id, dist])
		DialogManager.show_dialog_for(npc_id)

	elif dist > detect_radius and _triggered:
		_triggered = false   # reset khi player đi ra — cho phép trigger lần sau
