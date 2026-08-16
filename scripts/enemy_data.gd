class_name EnemyData
extends RefCounted

## 임시 플레이스홀더 목록. Day4(콘텐츠 채우기)에서 실제 이름/능력치로 교체 예정.
## 고정 패턴: 매번 랜덤 생성하지 않고 칸 인덱스로 정해진 적이 등장한다.
const NORMAL_TEMPLATES := [
	{"name": "들개", "hp": 12, "attack": 3},
	{"name": "도적", "hp": 14, "attack": 4},
	{"name": "슬라임", "hp": 10, "attack": 2},
]

const BOSS_TEMPLATE := {"name": "관문 수호자", "hp": 25, "attack": 5}
const BOSS_HP_MULTIPLIER := 2.0
const BOSS_ATTACK_MULTIPLIER := 1.5

var enemy_name: String
var hp: int
var max_hp: int
var attack: int

func _init(p_name: String, p_hp: int, p_attack: int) -> void:
	enemy_name = p_name
	hp = p_hp
	max_hp = p_hp
	attack = p_attack

## 일반 꼭짓점칸을 지날 때 등장할 적을 칸 인덱스 기준 고정 패턴으로 고른다
static func create_normal(board_index: int) -> EnemyData:
	var template: Dictionary = NORMAL_TEMPLATES[board_index % NORMAL_TEMPLATES.size()]
	return EnemyData.new(template["name"], template["hp"], template["attack"])

## 출발칸을 지날 때 등장하는 강화된 보스
static func create_boss() -> EnemyData:
	var hp := int(round(BOSS_TEMPLATE["hp"] * BOSS_HP_MULTIPLIER))
	var attack := int(round(BOSS_TEMPLATE["attack"] * BOSS_ATTACK_MULTIPLIER))
	return EnemyData.new(BOSS_TEMPLATE["name"], hp, attack)
