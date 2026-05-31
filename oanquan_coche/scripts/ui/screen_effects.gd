class_name ScreenEffects
extends Node2D
# ScreenEffects — flash overlays + confetti
# Must be inside a CanvasLayer (layer=10) in the scene tree

@onready var _flash: ColorRect = get_parent().get_node("FlashRect")

var _confetti: Array = []
var _confetti_active: bool = false
var _confetti_timer: float = 0.0
const CONFETTI_DURATION := 2.5
const CONFETTI_COUNT    := 60
const CONFETTI_COLORS: Array = [
	Color("f6c90e"), Color("e84545"), Color("2ecc71"),
	Color("3498db"), Color("9b59b6"), Color("ff7675"),
]

func _ready() -> void:
	_flash.color        = Color(1, 1, 1, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameManager.stones_captured.connect(_on_captured)
	GameManager.trap_triggered.connect(_on_trap)
	GameManager.game_over.connect(_on_game_over)

# ── Flash helpers ─────────────────────────────────────────────────────────────
func flash_white(strength: float = 0.6, duration: float = 0.3) -> void:
	_flash.color = Color(1, 1, 1, strength)
	var tw := create_tween()
	tw.tween_property(_flash, "color", Color(1, 1, 1, 0.0), duration)

func flash_red(strength: float = 0.35, duration: float = 0.2) -> void:
	_flash.color = Color(1, 0.1, 0.1, strength)
	var tw := create_tween()
	tw.tween_property(_flash, "color", Color(1, 0.1, 0.1, 0.0), duration)

# ── Signal handlers ───────────────────────────────────────────────────────────
func _on_captured(cell_indices: Array, total_points: int) -> void:
	# Check if a quan cell was captured
	var quan_hit := false
	for idx in cell_indices:
		if GameManager.state != null and GameManager.state.board[idx].cell_type == "quan":
			quan_hit = true
	if quan_hit:
		flash_white(0.7, 0.3)
	elif total_points >= 8:
		flash_white(0.35, 0.2)

func _on_trap(_cell_index: int, _victim: int) -> void:
	flash_red(0.4, 0.2)

func _on_game_over(winner: int, _scores: Array) -> void:
	if winner == 0:
		_start_confetti()

# ── Confetti ──────────────────────────────────────────────────────────────────
func _start_confetti() -> void:
	_confetti.clear()
	var vp := get_viewport().get_visible_rect()
	for i in range(CONFETTI_COUNT):
		_confetti.append({
			"pos":   Vector2(randf_range(0, vp.size.x), randf_range(-40, -10)),
			"vel":   Vector2(randf_range(-40, 40), randf_range(120, 260)),
			"rot":   randf_range(0, TAU),
			"rot_v": randf_range(-4, 4),
			"size":  randf_range(6, 12),
			"color": CONFETTI_COLORS[randi() % CONFETTI_COLORS.size()],
			"alive": true,
		})
	_confetti_active = true
	_confetti_timer  = 0.0

func _process(delta: float) -> void:
	if not _confetti_active:
		return
	_confetti_timer += delta
	var vp_h := get_viewport().get_visible_rect().size.y
	for p in _confetti:
		p["pos"] += p["vel"] * delta
		p["rot"] += p["rot_v"] * delta
		if p["pos"].y > vp_h + 20:
			p["alive"] = false
	if _confetti_timer >= CONFETTI_DURATION:
		_confetti_active = false
		_confetti.clear()
	queue_redraw()

func _draw() -> void:
	for p in _confetti:
		if not p["alive"]:
			continue
		var s: float = p["size"]
		draw_set_transform(p["pos"], p["rot"], Vector2.ONE)
		draw_rect(Rect2(-s * 0.5, -s * 0.5, s, s * 0.6), p["color"])
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
