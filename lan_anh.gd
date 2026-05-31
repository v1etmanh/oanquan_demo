extends CharacterBody2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

const WALK_SPEED := 90.0
const RUN_SPEED := 150.0

var last_direction := "front"


func _physics_process(delta):
	var input_vector := Vector2.ZERO

	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	input_vector = input_vector.normalized()

	var is_running := Input.is_action_pressed("run")
	var speed := RUN_SPEED if is_running else WALK_SPEED

	velocity = input_vector * speed
	move_and_slide()

	update_animation(input_vector, is_running)


func update_animation(input_vector: Vector2, is_running: bool):
	if input_vector == Vector2.ZERO:
		anim.play(last_direction)
		return

	var prefix := "run_" if is_running else "walk_"

	if abs(input_vector.x) > abs(input_vector.y):
		if input_vector.x > 0:
			last_direction = "right"
			anim.play(prefix + "right")
		else:
			last_direction = "left"
			anim.play(prefix + "left")
	else:
		if input_vector.y > 0:
			last_direction = "front"
			anim.play(prefix + "front")
		else:
			last_direction = "behind"
			anim.play(prefix + "behind")
