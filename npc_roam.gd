## npc_roam.gd
## Dành cho: young_boy, young_girl, npc_nu
## Tự đi qua lại trong phạm vi, thỉnh thoảng dừng idle rồi đi tiếp
## Export vars để config per-NPC trong Inspector

extends CharacterBody2D

@export var walk_speed: float = 60.0
@export var roam_radius: float = 120.0   # pixel, tính từ spawn point
@export var idle_min: float = 1.5        # giây idle tối thiểu
@export var idle_max: float = 3.5        # giây idle tối đa
@export var walk_min: float = 2.0        # giây đi tối thiểu
@export var walk_max: float = 4.5        # giây đi tối đa

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

enum State { WALKING, IDLE }
var state: State = State.IDLE

var _spawn_pos: Vector2
var _direction: Vector2 = Vector2.RIGHT
var _timer: float = 0.0

func _ready() -> void:
	_spawn_pos = global_position
	_start_idle()

func _physics_process(delta: float) -> void:
	_timer -= delta

	match state:
		State.IDLE:
			if _timer <= 0.0:
				_start_walk()

		State.WALKING:
			# Kiểm tra nếu ra khỏi vùng roam → quay đầu về spawn
			var to_spawn := _spawn_pos - global_position
			if to_spawn.length() > roam_radius:
				_direction = to_spawn.normalized()
				_update_flip()

			velocity = _direction * walk_speed
			move_and_slide()

			if _timer <= 0.0:
				_start_idle()

func _start_idle() -> void:
	state = State.IDLE
	velocity = Vector2.ZERO
	anim.play("idle")
	_timer = randf_range(idle_min, idle_max)

func _start_walk() -> void:
	state = State.WALKING
	# Chọn hướng ngẫu nhiên, ưu tiên horizontal (side-view sprite)
	var angle := randf_range(-PI * 0.35, PI * 0.35)
	# 70% đi ngang, 30% đi chéo
	if randf() < 0.7:
		_direction = Vector2(sign(randf() - 0.5), 0.0)
	else:
		_direction = Vector2(cos(angle), sin(angle) * 0.4).normalized()
	_update_flip()
	anim.play("moving")
	_timer = randf_range(walk_min, walk_max)

func _update_flip() -> void:
	# flip sprite theo hướng đi, moving sprite mặc định quay phải
	if _direction.x < -0.1:
		anim.flip_h = true
	elif _direction.x > 0.1:
		anim.flip_h = false
