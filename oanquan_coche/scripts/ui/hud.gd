extends CanvasLayer
# HUD.gd — Score display, timer bar, game over overlay

# Node refs (set in _ready via $)
@onready var lbl_score_p0: Label       = $ScoreContainer/LblP0
@onready var lbl_score_p1: Label       = $ScoreContainer/LblP1
@onready var lbl_turn: Label           = $LblTurn
@onready var timer_bar: ProgressBar    = $TimerBar
@onready var overlay_gameover: Control = $GameOverOverlay
@onready var lbl_result: Label         = $GameOverOverlay/LblResult
@onready var lbl_scores: Label         = $GameOverOverlay/LblScores
@onready var btn_restart: Button       = $GameOverOverlay/BtnRestart

const TIMER_MAX := 15.0
var _timer_max: float = TIMER_MAX

func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.timer_updated.connect(_on_timer_updated)
	GameManager.turn_ended.connect(_on_turn_ended)
	GameManager.game_over.connect(_on_game_over)
	GameManager.phase_changed.connect(_on_phase_changed)
	overlay_gameover.visible = false
	btn_restart.pressed.connect(_on_restart)
	_refresh_scores()

func _refresh_scores() -> void:
	if GameManager.state == null:
		return
	lbl_score_p0.text = "AI: %d"  % GameManager.state.players[0].score
	lbl_score_p1.text = "Bạn: %d" % GameManager.state.players[1].score

func _on_score_changed(_pid: int, _score: int, _delta: int) -> void:
	_refresh_scores()

func _on_timer_updated(secs: float) -> void:
	timer_bar.value = secs
	if secs <= 5.0:
		timer_bar.modulate = Color(1, 0.2, 0.2)
		if fmod(secs, 1.0) < 0.12:
			SoundManager.play_timer_tick()
	else:
		timer_bar.modulate = Color(1, 1, 1)

func _on_turn_ended(next_player: int) -> void:
	lbl_turn.text = "Lượt: %s" % ("Bạn" if next_player == 1 else "AI")

func _on_phase_changed(phase: GameEnums.Phase) -> void:
	match phase:
		GameEnums.Phase.WAITING:
			var pid := GameManager.state.current_player
			lbl_turn.text = "Lượt: %s — Chọn ô" % ("Bạn" if pid == 1 else "AI")
		GameEnums.Phase.CAPTURE_CONFIRM:
			lbl_turn.text = "👆 Nhấn ô cam để ăn quân!"
		GameEnums.Phase.SPREADING:
			lbl_turn.text = "Đang rải..."
		GameEnums.Phase.CAPTURING:
			lbl_turn.text = "Ăn quân!"
		GameEnums.Phase.GAME_OVER:
			pass

func _on_game_over(winner: int, scores: Array) -> void:
	overlay_gameover.visible = true
	match winner:
		1: lbl_result.text = "🎉 Bạn thắng!"
		0: lbl_result.text = "😞 AI thắng!"
		_: lbl_result.text = "🤝 Hòa!"
	lbl_scores.text = "AI %d — Bạn %d" % [scores[0], scores[1]]
	if winner == 1:
		SoundManager.play_win()
	else:
		SoundManager.play_lose()

func _on_restart() -> void:
	overlay_gameover.visible = false
	GameManager.start_new_game()
	_refresh_scores()
	lbl_turn.text = "Lượt: Bạn — Chọn ô"
	timer_bar.modulate = Color(1, 1, 1)
