class_name GameContent
extends RefCounted

## 임시 플레이스홀더 목록. Day4(콘텐츠 채우기)에서 실제 이름/효과로 교체 예정.

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

const SKILL_CARDS := [
	"스킬 카드 A", "스킬 카드 B", "스킬 카드 C", "스킬 카드 D",
]

static func draw_event_card() -> Dictionary:
	return EVENT_CARDS.pick_random()

## 주사위를 굴려 그 눈금에 대응하는 랜덤 효과를 결정한다
static func roll_random_effect() -> Dictionary:
	var index := Dice.roll() - 1
	return RANDOM_EFFECTS[index]

static func draw_skill_card() -> String:
	return SKILL_CARDS.pick_random()
