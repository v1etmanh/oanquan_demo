## oanquanboy.gd
## Vào vùng → hiện label thách đấu → nhấn E để chuyển scene gameplay

extends CharacterBody2D

@export var detect_radius: float = 80.0
@export var gameplay_scene: String = "res://oanquan_coche/scenes/gameplay.tscn"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _label: Label = $ChallengeLabel

var _player: Node2D = null
var _in_range: bool = false

func _ready() -> void:
	anim.play("idle")
	_label.visible = false
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("lan_anh")

func _physics_process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("lan_anh")
		return

	var dist := global_position.distance_to(_player.global_position)

	if dist <= detect_radius and not _in_range:
		_in_range = true
		_label.text = "Mày dám thách đấu tao không?\n[E] Chấp nhận"
		_label.visible = true

	elif dist > detect_radius and _in_range:
		_in_range = false
		_label.visible = false

func _input(event: InputEvent) -> void:
	if not _in_range:
		return
	if event.is_action_pressed("ui_interact"):
		get_tree().change_scene_to_file(gameplay_scene)
