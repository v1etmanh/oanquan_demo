## npc_roam.gd
## Dành cho: young_boy, young_girl, npc_nu
## Tự đi qua lại. Khi Lan Anh vào Area2D → dialog mở, NPC dừng lại.
##
## Setup trong Inspector:
##   npc_id  → "young_boy" / "young_girl" / "npc_nu"
##
## Cần trong .tscn:
##   - AnimatedSprite2D
##   - Area2D  (tên node: "DetectArea")
##     └── CollisionShape2D  (CircleShape2D, r≈80)
##
## Dialog data không còn hardcode ở đây — lấy từ assets/dialogs.json
## qua DialogManager.show_dialog_for(npc_id)

extends CharacterBody2D

@export var npc_id: String = "young_boy"
@export var walk_speed: float = 60.0
@export var roam_radius: float = 120.0
@export var idle_min: float = 1.5
@export var idle_max: float = 3.5
@export var walk_min: float = 2.0
@export var walk_max: float = 4.5

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detect_area: Area2D    = $DetectArea

enum State { WALKING, IDLE, TALKING }
var state: State = State.IDLE

var _spawn_pos: Vector2
var _direction: Vector2 = Vector2.RIGHT
var _timer: float = 0.0

# =============================================================================
func _ready() -> void:
	_spawn_pos = global_position
	_start_idle()
	if detect_area:
		detect_area.body_entered.connect(_on_body_entered)
		detect_area.body_exited.connect(_on_body_exited)
	# Lắng nghe khi dialog đóng → tiếp tục đi
	DialogManager.dialog_closed.connect(_on_dialog_closed)

func _physics_process(delta: float) -> void:
	if state == State.TALKING:
		return

	_timer -= delta
	match state:
		State.IDLE:
			if _timer <= 0.0:
				_start_walk()
		State.WALKING:
			var to_spawn := _spawn_pos - global_position
			if to_spawn.length() > roam_radius:
				_direction = to_spawn.normalized()
				_update_flip()
			velocity = _direction * walk_speed
			move_and_slide()
			if _timer <= 0.0:
				_start_idle()

# ── Roam helpers ──────────────────────────────────────────────────────────────
func _start_idle() -> void:
	state = State.IDLE
	velocity = Vector2.ZERO
	anim.play("idle")
	_timer = randf_range(idle_min, idle_max)

func _start_walk() -> void:
	state = State.WALKING
	if randf() < 0.7:
		_direction = Vector2(sign(randf() - 0.5), 0.0)
	else:
		var angle := randf_range(-PI * 0.35, PI * 0.35)
		_direction = Vector2(cos(angle), sin(angle) * 0.4).normalized()
	_update_flip()
	anim.play("moving")
	_timer = randf_range(walk_min, walk_max)

func _update_flip() -> void:
	if _direction.x < -0.1:
		anim.flip_h = true
	elif _direction.x > 0.1:
		anim.flip_h = false

# ── Dialog trigger ────────────────────────────────────────────────────────────
func _on_body_entered(body: Node) -> void:
	var is_player := (
		body.is_in_group("lan_anh")
		or body.name == "lan_anh"
		or (body.get_script() != null and (body.get_script() as Script).resource_path.ends_with("lan_anh.gd"))
	)
	if not is_player:
		return
	if DialogManager.is_open:
		return
	state = State.TALKING
	velocity = Vector2.ZERO
	anim.play("idle")
	DialogManager.show_dialog_for(npc_id)

func _on_body_exited(_body: Node) -> void:
	pass  # Không cần xử lý gì khi player đi ra

func _on_dialog_closed(closed_id: String) -> void:
	# Chỉ resume nếu dialog vừa đóng là của NPC này
	if closed_id == npc_id:
		_start_idle()
