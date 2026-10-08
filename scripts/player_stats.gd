class_name PlayerStats
extends RefCounted

## ATTACK = 힘(기획서 용어). 이전 버전 스크립트와 이름을 맞추려고 ATTACK을 그대로 쓴다
enum StatType { ATTACK, DEFENSE, MANA }
const ALL_STATS: Array[StatType] = [StatType.ATTACK, StatType.DEFENSE, StatType.MANA]
const MAX_POTIONS := 3
## 목걸이 부활 시 회복 비율
const REVIVE_RATIO := 0.5

var character: Dictionary = {}
## 공격 시 값만큼 피해 추가
var strength := 0
## 방어 카드 사용 시 값만큼 보호막 추가
var defense := 0
## 마나 스탯 = 전투 시작 마나이자 최대 마나
var mana_stat := 2
## 매 턴 마나 회복량에 더해지는 보너스(기본 회복량 2 + @)
var mana_regen_bonus := 0
var max_hp := 20
var hp := 20
var gold := 0
## 이번 모험에서 번 골드 총합(게임이 끝나면 명성으로 바뀜)
var gold_earned := 0
var deck: Array = []
var items: Array = []
var potions := 1

func setup(p_character: Dictionary) -> void:
	character = p_character
	strength = CharacterData.BASE_STRENGTH + character["strength"]
	defense = CharacterData.BASE_DEFENSE + character["defense"]
	mana_stat = max(0, CharacterData.BASE_MANA + character["mana"])
	max_hp = CharacterData.BASE_HP + character["hp"]
	hp = max_hp
	deck.clear()
	for i in range(4):
		deck.append(CardData.create("slash"))
		deck.append(CardData.create("guard"))
	for id in character["cards"]:
		deck.append(CardData.create(id))
	items.clear()
	if character["item"] != "":
		items.append(character["item"])

## 스탯을 amount만큼 증감시킨다(0 밑으로는 내려가지 않음)
func add_stat(type: StatType, amount: int) -> void:
	match type:
		StatType.ATTACK:
			strength = max(0, strength + amount)
		StatType.DEFENSE:
			defense = max(0, defense + amount)
		StatType.MANA:
			mana_stat = max(0, mana_stat + amount)

func stat_name(type: StatType) -> String:
	match type:
		StatType.ATTACK: return "힘"
		StatType.DEFENSE: return "방어"
		StatType.MANA: return "마나"
	return "?"

func hp_instead_of_mana() -> bool:
	return character.get("hp_cost", false)

func has_item(id: String) -> bool:
	return items.has(id)

## 보유 아이템이 밀어주는 카드 태그 목록
func favored_tags() -> Array:
	var tags: Array = []
	for id in items:
		tags.append(ItemData.ITEMS[id]["tag"])
	return tags

## 실제로 회복된 양을 반환한다
func heal(amount: int) -> int:
	var before := hp
	hp = min(max_hp, hp + amount)
	return hp - before

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)

func gain_gold(amount: int) -> void:
	gold += amount
	gold_earned += amount

func potion_heal_amount() -> int:
	var ratio: float = ItemData.POTION_HEAL_RATIO + character.get("potion_bonus", 0.0)
	return int(ceil(max_hp * ratio))

## 포션을 마시고 회복량을 반환한다(포션이 없으면 0)
func use_potion() -> int:
	if potions <= 0:
		return 0
	potions -= 1
	return heal(potion_heal_amount())

## HP가 0이 됐을 때 목걸이가 있으면 부서지면서 부활한다. 부활했으면 true
func try_revive() -> bool:
	if not has_item("holy_necklace"):
		return false
	items.erase("holy_necklace")
	items.append("broken_necklace")
	hp = int(ceil(max_hp * REVIVE_RATIO))
	return true

## 제거할 수 있는 카드(영구 카드 제외)의 덱 인덱스 목록
func removable_indices() -> Array:
	var result: Array = []
	for i in range(deck.size()):
		if not deck[i].get("permanent", false):
			result.append(i)
	return result

func upgradable_indices() -> Array:
	var result: Array = []
	for i in range(deck.size()):
		if CardData.can_upgrade(deck[i]):
			result.append(i)
	return result

func special_upgradable_indices() -> Array:
	var result: Array = []
	for i in range(deck.size()):
		if CardData.can_special_upgrade(deck[i]):
			result.append(i)
	return result
