extends Node
# ProvinceManager — Autoload, loads province JSON and provides lookup

var _provinces: Array = []
var _by_id: Dictionary = {}

func _ready() -> void:
	_load_json()

func _load_json() -> void:
	var f := FileAccess.open("res://oanquan_coche/scripts/data/provinces.json", FileAccess.READ)
	if f == null:
		push_error("ProvinceManager: cannot open provinces.json")
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		push_error("ProvinceManager: JSON parse error")
		return
	f.close()
	_provinces = json.get_data()
	for p in _provinces:
		_by_id[p["province_id"]] = p

func get_province(id: String) -> Dictionary:
	return _by_id.get(id, {})

func get_all() -> Array:
	return _provinces

func get_lore_win(id: String) -> String:
	return _by_id.get(id, {}).get("lore_win", "")

func get_lore_lose(id: String) -> String:
	return _by_id.get(id, {}).get("lore_lose", "")

func get_ai_level(id: String) -> int:
	return _by_id.get(id, {}).get("ai_level", 1)

func get_next_province(current_id: String) -> String:
	for i in range(_provinces.size()):
		if _provinces[i]["province_id"] == current_id:
			if i + 1 < _provinces.size():
				return _provinces[i + 1]["province_id"]
	return ""
