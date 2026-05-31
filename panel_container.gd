extends PanelContainer

@onready var name_label = $VBoxContainer/ItemNameLabel
@onready var desc_label = $VBoxContainer/ItemDescLabel
@onready var back_btn   = $VBoxContainer/BackButton

func _ready():
	visible = false
	back_btn.pressed.connect(func(): visible = false)

func show_info(data: Dictionary):
	name_label.text = data["name"]
	desc_label.text = data["description"]
	visible = true
