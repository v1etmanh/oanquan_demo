class_name SaveSystem
extends RefCounted
# SaveSystem — static helpers, no scene needed

const SAVE_PATH := "user://save_data.json"

static func load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return _default()
	var txt  := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK:
		return _default()
	return json.get_data()

static func save_data(data: Dictionary) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

static func unlock_province(province_id: String) -> void:
	var d := load_data()
	if province_id not in d["provinces_unlocked"]:
		d["provinces_unlocked"].append(province_id)
	save_data(d)

static func complete_province(province_id: String, score: int) -> void:
	var d := load_data()
	if province_id not in d["provinces_completed"]:
		d["provinces_completed"].append(province_id)
	var old_hs: int = d["high_scores"].get(province_id, 0)
	if score > old_hs:
		d["high_scores"][province_id] = score
	d["total_wins"] += 1
	save_data(d)

static func record_game_played() -> void:
	var d := load_data()
	d["total_games_played"] += 1
	save_data(d)

static func is_province_unlocked(province_id: String) -> bool:
	var d := load_data()
	return province_id in d["provinces_unlocked"]

static func _default() -> Dictionary:
	return {
		"provinces_unlocked":  ["ha_noi"],
		"provinces_completed": [],
		"high_scores":         {},
		"spirits_unlocked":    [],
		"stone_skins_unlocked":["default"],
		"board_skins_unlocked":["default"],
		"total_games_played":  0,
		"total_wins":          0,
		"last_played_province":"ha_noi",
	}
