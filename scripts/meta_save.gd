class_name MetaSave
extends RefCounted

## 모험이 끝나도 남는 정보(명성, 보유/구매 가능 캐릭터)를 파일에 저장한다

const SAVE_PATH := "user://dicemarble_save.cfg"

## 모험에서 번 골드가 쌓이는 재화. 메인 메뉴에서 캐릭터 구매에 쓴다
var fame := 0
var owned: Array = ["thunder_sword"]
## 모험 중 고른 길에 따라 구매할 수 있게 된 캐릭터
var purchasable: Array = []

func load_data() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	fame = config.get_value("meta", "fame", 0)
	owned = config.get_value("meta", "owned", ["thunder_sword"])
	purchasable = config.get_value("meta", "purchasable", [])

func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "fame", fame)
	config.set_value("meta", "owned", owned)
	config.set_value("meta", "purchasable", purchasable)
	config.save(SAVE_PATH)

func is_owned(id: String) -> bool:
	return owned.has(id)

func can_buy(character: Dictionary) -> bool:
	return purchasable.has(character["id"]) and not is_owned(character["id"]) and fame >= character["price"]

func buy(character: Dictionary) -> bool:
	if not can_buy(character):
		return false
	fame -= character["price"]
	owned.append(character["id"])
	save_data()
	return true

## 막을 클리어할 때 가장 많이 지나간 칸 종류에 맞는 캐릭터를 구매 가능하게 만든다
## route_counts 예: {"battle": 4, "event": 2, "shop": 1}. 새로 해금된 캐릭터를 반환(없으면 빈 Dictionary)
func unlock_by_route(route_counts: Dictionary) -> Dictionary:
	var routes := route_counts.keys()
	routes.sort_custom(func(a, b): return route_counts[a] > route_counts[b])
	for route in routes:
		for c in CharacterData.CHARACTERS:
			if c["unlock_route"] == route and not purchasable.has(c["id"]) and not is_owned(c["id"]):
				purchasable.append(c["id"])
				save_data()
				return c
	return {}
