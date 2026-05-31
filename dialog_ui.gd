## dialog_ui.gd
## Gắn vào node DialogUI (CanvasLayer) trong village.tscn
##
## Node tree cần có trong village.tscn:
##   CanvasLayer  (tên: "DialogUI")  ← gắn script này
##     └── Panel  (tên: "Panel")
##           ├── Label         (tên: "SpeakerLabel")
##           ├── RichTextLabel (tên: "DialogText")   ← bật BBCode Enabled
##           └── Button        (tên: "NextButton",  text: "Tiếp ▶")

extends CanvasLayer

@onready var panel        : Control        = $Panel
@onready var speaker_label: Label          = $Panel/SpeakerLabel
@onready var dialog_text  : RichTextLabel  = $Panel/DialogText
@onready var next_button  : Button         = $Panel/NextButton

func _ready() -> void:
	DialogManager.register_ui(panel, speaker_label, dialog_text, next_button)
	print("DialogUI: register_ui xong — panel=%s" % str(panel))
	next_button.pressed.connect(_on_next_pressed)
	panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not DialogManager.is_open:
		return
	if event.is_action_pressed("ui_accept"):
		DialogManager.next_line()
		get_viewport().set_input_as_handled()
		return
	# Bắt Space / E trực tiếp (phòng trường hợp ui_accept chưa map)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_E:
			DialogManager.next_line()
			get_viewport().set_input_as_handled()

func _on_next_pressed() -> void:
	DialogManager.next_line()
