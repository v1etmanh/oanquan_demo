## npc_static.gd
## Dành cho: ong_gia, ba_gia, minh, hung, oanquanboy
## Chỉ đứng idle tại chỗ, không di chuyển
## Gắn script này vào tscn rồi không cần config gì thêm

extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	anim.play("idle")
