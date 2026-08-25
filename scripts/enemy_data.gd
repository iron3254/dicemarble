class_name EnemyData
extends RefCounted

## 임시 플레이스홀더 목록. Day4(콘텐츠 채우기)에서 실제 이름/능력치로 교체 예정.
## 고정 패턴: 매번 랜덤 생성하지 않고 칸 인덱스로 정해진 적이 등장한다.
const NORMAL_TEMPLATES := [
	{"name": "들개", "hp": 12, "attack": 3, "icon": "res://assets/icons/enemy_wolf.svg"},
	{"name": "도적", "hp": 14, "attack": 4, "icon": "res://assets/icons/enemy_bandit.svg"},
	{"name": "슬라임", "hp": 10, "attack": 2, "icon": "res://assets/icons/enemy_slime.svg"},
]

const BOSS_TEMPLATE := {"name": "관문 수호자", "hp": 25, "attack": 5, "icon": "res://assets/icons/enemy_boss.svg"}
## 보스는 몇 바퀴째인지에 따라 이 두 범위 사이에서 점점 강해진다(1바퀴째=최소, 마지막 바퀴=최대)
const BOSS_HP_MULTIPLIER_MIN := 1.1
const BOSS_HP_MULTIPLIER_MAX := 2.0
const BOSS_ATTACK_MULTIPLIER_MIN := 0.9
const BOSS_ATTACK_MULTIPLIER_MAX := 1.5

var enemy_name: String
var hp: int
var max_hp: int
var attack: int
var icon: String

func _init(p_name: String, p_hp: int, p_attack: int, p_icon: String) -> void:
	enemy_name = p_name
	hp = p_hp
	max_hp = p_hp
	attack = p_attack
	icon = p_icon

## 일반 꼭짓점칸을 지날 때 등장할 적을 칸 인덱스 기준 고정 패턴으로 고른다
static func create_normal(board_index: int) -> EnemyData:
	var template: Dictionary = NORMAL_TEMPLATES[board_index % NORMAL_TEMPLATES.size()]
	return EnemyData.new(template["name"], template["hp"], template["attack"], template["icon"])

## 출발칸을 지날 때 등장하는 강화된 보스. lap은 몇 바퀴째 통과인지(1부터 시작), total_laps는 승리에 필요한 총 바퀴 수
static func create_boss(lap: int, total_laps: int) -> EnemyData:
	var t := float(lap - 1) / float(max(1, total_laps - 1))
	var hp_mult: float = lerp(BOSS_HP_MULTIPLIER_MIN, BOSS_HP_MULTIPLIER_MAX, t)
	var attack_mult: float = lerp(BOSS_ATTACK_MULTIPLIER_MIN, BOSS_ATTACK_MULTIPLIER_MAX, t)
	var hp := int(round(BOSS_TEMPLATE["hp"] * hp_mult))
	var attack := int(round(BOSS_TEMPLATE["attack"] * attack_mult))
	return EnemyData.new(BOSS_TEMPLATE["name"], hp, attack, BOSS_TEMPLATE["icon"])
