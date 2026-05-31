## lan_anh.gd
## Lan Anh — nhân vật player điều khiển (4 hướng + run)
## Thêm vào group "lan_anh" để Tính tự tìm

extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

const WALK_SPEED := 90.0
const RUN_SPEED  := 150.0

var last_direction := "front"

func _ready() -> void:
	add_to_group("lan_anh")   # để tinh.gd tìm được bằng get_first_node_in_group

func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")
	).normalized()

	var is_running := Input.is_action_pressed("run")
	var speed      := RUN_SPEED if is_running else WALK_SPEED

	velocity = input_vector * speed
	move_and_slide()
	_update_animation(input_vector, is_running)

func _update_animation(dir: Vector2, running: bool) -> void:
	if dir == Vector2.ZERO:
		anim.play(last_direction)   # giữ idle theo hướng cuối
		return

	var prefix := "run_" if running else "walk_"

	if abs(dir.x) >= abs(dir.y):
		if dir.x > 0:
			last_direction = "right"
			anim.play(prefix + "right")
		else:
			last_direction = "left"
			anim.play(prefix + "left")
	else:
		if dir.y > 0:
			last_direction = "front"
			anim.play(prefix + "front")
		else:
			last_direction = "behind"
			anim.play(prefix + "behind")
