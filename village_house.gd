extends Node2D

@onready var info_panel = $CanvasLayer/InfoPanel



func _unhandled_input(event):
	if not (event is InputEventMouseButton and event.pressed):
		return

	var space  = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position           = get_global_mouse_position()
	params.collide_with_areas = true
	params.collide_with_bodies = false

	var results = space.intersect_point(params)
	if results.is_empty():
		return

	var hit = results[0].collider
	if "item_name" in hit:
		info_panel.show_info({
			"name": hit.item_name,
			"description": hit.item_description
		})
