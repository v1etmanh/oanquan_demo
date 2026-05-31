## tinh.gd
## Tính tự di chuyển xung quanh Lan Anh
## Không dùng input — AI-controlled companion/protagonist

extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

const WALK_SPEED     := 80.0
const ORBIT_RADIUS   := 90.0   # khoảng cách Tính giữ với Lan Anh
const ORBIT_SPEED    := 0.6    # tốc độ xoay quanh (radian/giây)
const WANDER_INTERVAL_MIN := 3.0
const WANDER_INTERVAL_MAX := 6.0
const APPROACH_THRESHOLD  := 20.0  # pixel, dừng lại khi đủ gần target

# --- refs ---
var _lan_anh: CharacterBody2D   # set bởi village.tscn hoặc tự tìm

# --- state ---
enum State { ORBITING, WANDERING, IDLE }
var _state: State = State.ORBITING

var _orbit_angle: float = 0.0
var _wander_target: Vector2
var _wander_timer: float = 0.0
var _idle_timer: float = 0.0
var _last_dir: Vector2 = Vector2.DOWN  # dùng cho idle animation

func _ready() -> void:
	# Tự tìm Lan Anh trong scene nếu chưa được assign
	await get_tree().process_frame
	if not _lan_anh:
		_lan_anh = get_tree().get_first_node_in_group("lan_anh")
	_orbit_angle = randf() * TAU
	_pick_wander_timer()

func _physics_process(delta: float) -> void:
	if not _lan_anh:
		anim.play("idle")
		return

	_wander_timer -= delta

	match _state:
		State.ORBITING:
			_do_orbit(delta)
			if _wander_timer <= 0.0:
				_start_wander()

		State.WANDERING:
			_do_wander(delta)

		State.IDLE:
			_idle_timer -= delta
			_play_idle_anim()
			if _idle_timer <= 0.0:
				_state = State.ORBITING
				_pick_wander_timer()

# ─── ORBIT ──────────────────────────────────────────────────────────────────

func _do_orbit(delta: float) -> void:
	_orbit_angle += ORBIT_SPEED * delta
	if _orbit_angle > TAU:
		_orbit_angle -= TAU

	var target_pos: Vector2 = _lan_anh.global_position + Vector2(
		cos(_orbit_angle) * ORBIT_RADIUS,
		sin(_orbit_angle) * ORBIT_RADIUS * 0.5   # flatten theo trục Y (top-down perspective)
	)

	var diff := target_pos - global_position
	if diff.length() < APPROACH_THRESHOLD:
		velocity = Vector2.ZERO
		_play_idle_anim()
	else:
		velocity = diff.normalized() * WALK_SPEED
		_last_dir = diff.normalized()
		_play_walk_anim(velocity)

	move_and_slide()

# ─── WANDER ─────────────────────────────────────────────────────────────────

func _start_wander() -> void:
	# Chọn điểm ngẫu nhiên quanh Lan Anh trong bán kính lớn hơn
	var angle := randf() * TAU
	var dist  := randf_range(ORBIT_RADIUS * 0.5, ORBIT_RADIUS * 1.6)
	_wander_target = _lan_anh.global_position + Vector2(cos(angle) * dist, sin(angle) * dist * 0.5)
	_state = State.WANDERING

func _do_wander(_delta: float) -> void:
	var diff := _wander_target - global_position
	if diff.length() < APPROACH_THRESHOLD:
		# Đến nơi → đứng idle ngắn rồi quay orbit
		_state = State.IDLE
		_idle_timer = randf_range(1.0, 2.5)
		velocity = Vector2.ZERO
		_play_idle_anim()
	else:
		velocity = diff.normalized() * WALK_SPEED
		_last_dir = diff.normalized()
		_play_walk_anim(velocity)

	move_and_slide()

# ─── ANIMATION ──────────────────────────────────────────────────────────────

func _play_walk_anim(vel: Vector2) -> void:
	if abs(vel.x) >= abs(vel.y):
		if vel.x > 0:
			anim.play("walk_right")
		else:
			anim.play("walk_left")
	else:
		if vel.y > 0:
			anim.play("walk_front")
		else:
			anim.play("walk_behind")

func _play_idle_anim() -> void:
	if abs(_last_dir.x) >= abs(_last_dir.y):
		anim.play("right" if _last_dir.x > 0 else "left")
	else:
		anim.play("idle" if _last_dir.y > 0 else "behind")

# ─── PUBLIC API (gọi từ village.tscn hoặc dialog manager sau này) ────────────

func set_lan_anh(node: CharacterBody2D) -> void:
	_lan_anh = node

func _pick_wander_timer() -> void:
	_wander_timer = randf_range(WANDER_INTERVAL_MIN, WANDER_INTERVAL_MAX)
