extends RefCounted
const Store = preload("res://src/infrastructure/save_store.gd")
var directory := "user://characters"
var legacy := "user://odyssey_v1.json"
var error := ""

func entries() -> Array:
	var result: Array = []
	var paths: Array = []
	if FileAccess.file_exists(legacy) or FileAccess.file_exists(legacy + ".bak"): paths.append(legacy)
	if DirAccess.dir_exists_absolute(directory):
		for file in DirAccess.get_files_at(directory):
			if file.ends_with(".json"): paths.append(directory + "/" + file)
	paths.sort()
	for path in paths:
		var store := Store.new()
		store.path = path
		var p := store.load_profile()
		result.append({"path": path, "name": p.get("character_name", "기존 오디세우스"), "level": p.get("level", 0), "valid": not p.is_empty()})
	return result

func create_character(character_name: String, profile: Dictionary) -> String:
	error = ""
	if character_name.strip_edges().is_empty(): error = "이름을 입력하세요."; return ""
	if DirAccess.make_dir_recursive_absolute(directory) != OK: error = "캐릭터 폴더를 만들 수 없습니다."; return ""
	var store := Store.new()
	store.path = directory + "/" + str(Time.get_unix_time_from_system()).replace(".", "_") + "_" + str(Time.get_ticks_usec()) + ".json"
	profile.character_name = character_name.strip_edges().left(20)
	if not store.save_profile(profile): error = store.error; return ""
	return store.path

func delete_character(path: String) -> bool:
	error = ""
	var known := false
	for entry in entries():
		if entry.path == path: known = true
	if not known: error = "캐릭터를 찾을 수 없습니다."; return false
	# Remove only this exact character and its recovery files after UI confirmation.
	for suffix in [".bak", ".tmp", ""]:
		if FileAccess.file_exists(path + suffix) and DirAccess.remove_absolute(path + suffix) != OK:
			error = "캐릭터 삭제 실패"; return false
	return true
