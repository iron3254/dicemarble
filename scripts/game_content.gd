class_name GameContent
extends RefCounted

## 임시 플레이스홀더 목록. Day4(콘텐츠 채우기)에서 실제 이름/효과로 교체 예정.

## 스킬카드가 전투에서 공격용인지 방어용인지 구분
enum SkillCategory { ATTACK, DEFENSE }

const EVENT_CARDS := [
	{"name": "이벤트 카드 A", "stat": PlayerStats.StatType.ATTACK, "amount": 1},
	{"name": "이벤트 카드 B", "stat": PlayerStats.StatType.DEFENSE, "amount": 1},
	{"name": "이벤트 카드 C", "stat": PlayerStats.StatType.MANA, "amount": 1},
	{"name": "이벤트 카드 D", "stat": PlayerStats.StatType.ATTACK, "amount": -1},
	{"name": "이벤트 카드 E", "stat": PlayerStats.StatType.DEFENSE, "amount": -1},
]

## 주사위 눈금(1~6)에 1:1로 대응하는 랜덤 버프/디버프 목록
const RANDOM_EFFECTS := [
	{"name": "버프 A", "stat": PlayerStats.StatType.ATTACK, "amount": 1},
	{"name": "버프 B", "stat": PlayerStats.StatType.DEFENSE, "amount": 1},
	{"name": "버프 C", "stat": PlayerStats.StatType.MANA, "amount": 1},
	{"name": "디버프 A", "stat": PlayerStats.StatType.ATTACK, "amount": -1},
	{"name": "디버프 B", "stat": PlayerStats.StatType.DEFENSE, "amount": -1},
	{"name": "디버프 C", "stat": PlayerStats.StatType.MANA, "amount": -1},
]

## cost: 사용에 필요한 마력, power: 주사위+스탯 판정에 더해지는 위력(공격은 데미지, 방어는 경감량)
const SKILL_CARDS := [
	{"name": "강타", "category": SkillCategory.ATTACK, "cost": 2, "power": 2, "icon": "res://assets/icons/skill_heavy_strike.svg"},
	{"name": "연속 베기", "category": SkillCategory.ATTACK, "cost": 1, "power": 1, "icon": "res://assets/icons/skill_multi_slash.svg"},
	{"name": "필살기", "category": SkillCategory.ATTACK, "cost": 3, "power": 3, "icon": "res://assets/icons/skill_finishing_blow.svg"},
	{"name": "방패 올리기", "category": SkillCategory.DEFENSE, "cost": 2, "power": 2, "icon": "res://assets/icons/skill_shield.svg"},
	{"name": "회피", "category": SkillCategory.DEFENSE, "cost": 1, "power": 1, "icon": "res://assets/icons/skill_dodge.svg"},
	{"name": "철벽", "category": SkillCategory.DEFENSE, "cost": 3, "power": 3, "icon": "res://assets/icons/skill_iron_wall.svg"},
]

static func draw_event_card() -> Dictionary:
	return EVENT_CARDS.pick_random()

## 주사위를 굴려 그 눈금에 대응하는 랜덤 효과를 결정한다
static func roll_random_effect() -> Dictionary:
	var index := Dice.roll() - 1
	return RANDOM_EFFECTS[index]

## 이미 가진 스킬카드(owned_names)와 겹치지 않는 카드를 우선 뽑는다.
## 전부 이미 가지고 있으면(4종 다 모으면) 그때는 중복도 허용한다.
static func draw_skill_card(owned_names: Array = []) -> Dictionary:
	var candidates := SKILL_CARDS.filter(func(card): return not owned_names.has(card["name"]))
	if candidates.is_empty():
		candidates = SKILL_CARDS
	return candidates.pick_random()
