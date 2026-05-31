extends Node2D
# main_menu.gd — Main Menu screen

func _ready() -> void:
	$UI/BtnCampaign.pressed.connect(_on_campaign)
	$UI/BtnQuickplay.pressed.connect(_on_quickplay)
	$UI/BtnSettings.pressed.connect(_on_settings)

func _on_campaign() -> void:
	get_tree().change_scene_to_file("res://scenes/province_select.tscn")

func _on_quickplay() -> void:
	GameManager.start_new_game("quickplay", 1, GameEnums.Direction.CLOCKWISE)
	get_tree().change_scene_to_file.call_deferred("res://scenes/gameplay.tscn")

func _on_settings() -> void:
	pass  # Phase 3
