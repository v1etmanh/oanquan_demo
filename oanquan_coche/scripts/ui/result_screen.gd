extends CanvasLayer
# result_screen.gd — Shown after game_over signal
# Receives data via show_result(), floats in from below

signal replay_pressed
signal next_province_pressed
signal menu_pressed

@onready var lbl_result:   Label  = $Panel/LblResult
@onready var lbl_scores:   Label  = $Panel/LblScores
@onready var lbl_lore:     Label  = $Panel/LblLore
@onready var btn_replay:   Button = $Panel/Buttons/BtnReplay
@onready var btn_next:     Button = $Panel/Buttons/BtnNext
@onready var btn_menu:     Button = $Panel/Buttons/BtnMenu
@onready var panel:        Control = $Panel

func _ready() -> void:
	visible = false
	btn_replay.pressed.connect(func(): replay_pressed.emit())
	btn_next.pressed.connect(func():   next_province_pressed.emit())
	btn_menu.pressed.connect(func():   menu_pressed.emit())

func show_result(winner: int, scores: Array, lore_text: String, province_name: String) -> void:
	visible = true
	# Slide in from bottom
	panel.position.y = 800
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(panel, "position:y", 180.0, 0.45)

	match winner:
		0:
			lbl_result.text              = "🎉 Bạn thắng!"
			lbl_result.add_theme_color_override("font_color", Color("ffd700"))
			btn_next.visible             = true
		1:
			lbl_result.text              = "😞 AI thắng!"
			lbl_result.add_theme_color_override("font_color", Color("ff6b6b"))
			btn_next.visible             = false
		_:
			lbl_result.text              = "🤝 Hòa!"
			lbl_result.add_theme_color_override("font_color", Color("a8e6a3"))
			btn_next.visible             = false

	lbl_scores.text = "Bạn %d  —  AI %d" % [scores[0], scores[1]]
	lbl_lore.text   = lore_text if lore_text != "" else province_name

func hide_result() -> void:
	var tw := create_tween().set_ease(Tween.EASE_IN)
	tw.tween_property(panel, "position:y", 800.0, 0.3)
	await tw.finished
	visible = false
