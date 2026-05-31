extends Node2D
# main.gd — Root of the gameplay scene

var _province_id: String = "quickplay"
var _ai_level: int = 1

@onready var _result: Node = null   # ResultScreen (instantiated at runtime)

func _ready() -> void:
	# Allow external callers to set province before scene loads
	if GameManager.state != null:
		_province_id = GameManager.state.province_id
		_ai_level    = GameManager.ai.level if GameManager.ai else 1
	else:
		GameManager.start_new_game("ha_noi", 1, GameEnums.Direction.CLOCKWISE)
		_province_id = "ha_noi"

	GameManager.game_over.connect(_on_game_over)
	SaveSystem.record_game_played()

	# Instantiate result screen
	var rs_scene := preload("res://oanquan_coche/scenes/result_screen.tscn")
	_result       = rs_scene.instantiate()
	add_child(_result)
	_result.visible = false
	_result.replay_pressed.connect(_on_replay)
	_result.next_province_pressed.connect(_on_next_province)
	_result.menu_pressed.connect(_on_menu)

func _on_game_over(winner: int, scores: Array) -> void:
	var pid    := _province_id
	var lore   := ""
	if winner == 0:
		lore = ProvinceManager.get_lore_win(pid)
		SaveSystem.complete_province(pid, scores[0])
		var next := ProvinceManager.get_next_province(pid)
		if next != "":
			SaveSystem.unlock_province(next)
	else:
		lore = ProvinceManager.get_lore_lose(pid)

	var prov:  Dictionary = ProvinceManager.get_province(pid)
	var pname: String     = str(prov.get("name", pid))
	_result.show_result(winner, scores, lore, pname)

func _on_replay() -> void:
	_result.hide_result()
	await get_tree().create_timer(0.35).timeout
	GameManager.start_new_game(_province_id, _ai_level, GameEnums.Direction.CLOCKWISE)

func _on_next_province() -> void:
	var next := ProvinceManager.get_next_province(_province_id)
	if next == "":
		get_tree().change_scene_to_file("res://oanquan_coche/scenes/main_menu.tscn")
		return
	_province_id = next
	_ai_level    = ProvinceManager.get_ai_level(next)
	_result.hide_result()
	await get_tree().create_timer(0.35).timeout
	GameManager.start_new_game(_province_id, _ai_level, GameEnums.Direction.CLOCKWISE)

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://oanquan_coche/scenes/main_menu.tscn")
