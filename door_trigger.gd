extends Area2D

# Đường dẫn đến scene phòng cần chuyển sang
@export var target_scene: String = "res://village_house.tscn"

@onready var prompt_label = $PromptLabel

var lan_anh_inside = false

func _ready():
	prompt_label.visible = false
	# Kết nối signal va chạm
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Kiểm tra đúng là lan_anh mới hiện prompt
	if body.is_in_group("lan_anh"):
		lan_anh_inside = true
		prompt_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("lan_anh"):
		lan_anh_inside = false
		prompt_label.visible = false

func _unhandled_input(event):
	if not lan_anh_inside:
		return
	# Nhấn E thì đổi scene
	if event.is_action_pressed("ui_interact"):
		get_tree().change_scene_to_file(target_scene)
