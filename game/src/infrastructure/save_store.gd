extends RefCounted
var path := "user://odyssey_v1.json"
var error := ""

func valid(p: Variant) -> bool:
	if not p is Dictionary: return false
	for key in ["schema", "gold", "level", "xp", "attributes", "skill", "skills", "gems", "supports", "items", "equipment", "shards", "pity", "cleared", "intro_seen", "voyages"]:
		if not p.has(key): return false
	return p.schema == 1 and p.gold >= 0 and p.level >= 1 and p.level <= int(preload("res://src/domain/game_rules.gd").new().data.level_cap) and p.attributes is Array and p.attributes.size() == 3 and p.equipment is Array and p.equipment.size() in [3,9,12] and p.items is Array and p.gems is Array

func read_file(file: String) -> Variant:
	if not FileAccess.file_exists(file): return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(file)) != OK: return null
	return parser.data

func load_profile() -> Dictionary:
	error = ""
	for file in [path, path + ".bak"]:
		var p: Variant = read_file(file)
		if valid(p):
			preload("res://src/domain/storage_rules.gd").ensure(p)
			if file.ends_with(".bak"): error = "백업에서 저장을 복구했습니다."
			return p
	if FileAccess.file_exists(path): error = "저장 파일을 읽을 수 없습니다. 원본은 보존됩니다."
	return {}

func save_profile(p: Dictionary) -> bool:
	error = ""
	if not valid(p):
		error = "저장 데이터 검증 실패"
		return false
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		error = "저장 파일을 쓸 수 없습니다."
		return false
	f.store_string(JSON.stringify(p))
	f.flush()
	f.close()
	if not valid(read_file(path + ".tmp")):
		error = "임시 저장 검증 실패"
		return false
	if valid(read_file(path)):
		if DirAccess.copy_absolute(path, path + ".bak") != OK:
			error = "백업 저장 실패"
			return false
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		error = "저장 교체 실패"
		return false
	return true
