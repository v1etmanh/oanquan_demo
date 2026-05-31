extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

const WALK_SPEED := 90.0

var last_direction := "idle"


func _physics_process(delta):
	var input_vector := Vector2.ZERO

	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	input_vector = input_vector.normalized()

	velocity = input_vector * WALK_SPEED
	move_and_slide()

	update_animation(input_vector)


func update_animation(input_vector: Vector2):
	if input_vector == Vector2.ZERO:
		play_idle_animation()
		return

	if abs(input_vector.x) > abs(input_vector.y):
		if input_vector.x > 0:
			last_direction = "right"
			anim.play("walk_right")
		else:
			last_direction = "left"
			anim.play("walk_left")
	else:
		if input_vector.y > 0:
			last_direction = "front"
			anim.play("walk_front")
		else:
			last_direction = "behind"
			anim.play("walk_behind")


func play_idle_animation():
	if last_direction == "front":
		anim.play("idle")
	elif last_direction == "behind":
		anim.play("behind")
	elif last_direction == "left":
		anim.play("left")
	elif last_direction == "right":
		anim.play("right")
	else:
		anim.play("idle")
