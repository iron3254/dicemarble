class_name EnemyData
extends RefCounted

const ICON_SLIME := "res://assets/icons/enemy_slime.svg"
const ICON_WOLF := "res://assets/icons/enemy_wolf.svg"
const ICON_BANDIT := "res://assets/icons/enemy_bandit.svg"
const ICON_BOSS := "res://assets/icons/enemy_boss.svg"

## 막별 일반 적. 공격력 = dice 주사위 + attack, hits = 한 턴에 공격하는 횟수
## tint: 같은 아이콘을 색으로 구분하기 위한 색조
const NORMAL_BY_ACT := {
	1: [
		{"name": "슬라임", "hp": 14, "dice": "D6", "attack": 0, "icon": ICON_SLIME, "tint": Color(0.6, 1.0, 0.6)},
		{"name": "들개", "hp": 16, "dice": "D6", "attack": 1, "icon": ICON_WOLF, "tint": Color(0.9, 0.75, 0.55)},
		{"name": "도적", "hp": 18, "dice": "D6", "attack": 1, "icon": ICON_BANDIT, "tint": Color(0.85, 0.85, 0.85)},
	],
	2: [
		{"name": "독 슬라임", "hp": 26, "dice": "D6", "attack": 2, "icon": ICON_SLIME, "tint": Color(0.5, 0.9, 0.3)},
		{"name": "굶주린 늑대", "hp": 28, "dice": "D6", "attack": 3, "icon": ICON_WOLF, "tint": Color(0.7, 0.7, 0.75)},
		{"name": "용병", "hp": 32, "dice": "D12", "attack": 1, "icon": ICON_BANDIT, "tint": Color(0.9, 0.6, 0.4)},
		{"name": "유적 파수꾼", "hp": 30, "dice": "D6", "attack": 2, "icon": ICON_BOSS, "tint": Color(0.75, 0.7, 0.6)},
	],
	3: [
		{"name": "심연의 점액", "hp": 38, "dice": "D12", "attack": 2, "icon": ICON_SLIME, "tint": Color(0.65, 0.4, 0.9)},
		{"name": "그림자 늑대", "hp": 36, "dice": "D6", "attack": 2, "hits": 2, "icon": ICON_WOLF, "tint": Color(0.45, 0.45, 0.6)},
		{"name": "광신도", "hp": 42, "dice": "D12", "attack": 3, "icon": ICON_BANDIT, "tint": Color(1.0, 0.45, 0.45)},
		{"name": "하늘섬 경비병", "hp": 44, "dice": "D6", "attack": 5, "icon": ICON_BOSS, "tint": Color(0.7, 0.85, 1.0)},
	],
}

## 막별 보스 후보(기획서: 1막 3마리 중 1, 2막 4마리 중 1, 3막 5마리 중 1, 최종막 최종보스 1)
const BOSS_BY_ACT := {
	1: [
		{"name": "슬라임 왕", "hp": 42, "dice": "D6", "attack": 3, "icon": ICON_SLIME, "tint": Color(1.0, 0.85, 0.3)},
		{"name": "산적 두목", "hp": 38, "dice": "D6", "attack": 4, "icon": ICON_BANDIT, "tint": Color(1.0, 0.6, 0.3)},
		{"name": "늑대 우두머리", "hp": 36, "dice": "D6", "attack": 1, "hits": 2, "icon": ICON_WOLF, "tint": Color(0.95, 0.95, 1.0)},
	],
	2: [
		{"name": "유적 골렘", "hp": 80, "dice": "D12", "attack": 3, "icon": ICON_BOSS, "tint": Color(0.7, 0.65, 0.55)},
		{"name": "타락한 기사", "hp": 72, "dice": "D12", "attack": 4, "icon": ICON_BANDIT, "tint": Color(0.55, 0.35, 0.7)},
		{"name": "심해의 나가", "hp": 68, "dice": "D6", "attack": 3, "hits": 2, "icon": ICON_SLIME, "tint": Color(0.3, 0.7, 0.9)},
		{"name": "폭풍 그리폰", "hp": 64, "dice": "D6", "attack": 2, "hits": 2, "icon": ICON_WOLF, "tint": Color(0.9, 0.8, 0.4)},
	],
	3: [
		{"name": "고대 리치", "hp": 110, "dice": "D20", "attack": 4, "icon": ICON_BOSS, "tint": Color(0.6, 0.9, 0.8)},
		{"name": "화염 드레이크", "hp": 120, "dice": "D12", "attack": 6, "icon": ICON_WOLF, "tint": Color(1.0, 0.4, 0.2)},
		{"name": "하늘섬 수호자", "hp": 130, "dice": "D12", "attack": 5, "icon": ICON_BOSS, "tint": Color(0.85, 0.9, 1.0)},
		{"name": "광신도 대사제", "hp": 100, "dice": "D6", "attack": 5, "hits": 2, "icon": ICON_BANDIT, "tint": Color(0.9, 0.2, 0.3)},
		{"name": "그림자 암살자", "hp": 95, "dice": "D6", "attack": 3, "hits": 3, "icon": ICON_BANDIT, "tint": Color(0.35, 0.35, 0.45)},
	],
	4: [
		{"name": "악신", "hp": 170, "dice": "D20", "attack": 6, "icon": ICON_BOSS, "tint": Color(0.75, 0.2, 0.9)},
	],
}

var enemy_name: String
var hp: int
var max_hp: int
var dice: String
var attack: int
var hits: int
var icon: String
var tint: Color
var is_boss := false
## 뇌문: 공격 카드에 맞을 때 이 수치만큼 추가 피해. 매 턴 끝에 1 감소
var thunder := 0
## 독: 매 턴 끝에 이 수치만큼 피해. 피해 후 1 감소
var poison := 0

static func create_normal(act: int) -> EnemyData:
	var pool: Array = NORMAL_BY_ACT[clampi(act, 1, 3)]
	return _from(pool.pick_random(), false)

static func create_boss(act: int) -> EnemyData:
	var pool: Array = BOSS_BY_ACT[clampi(act, 1, 4)]
	return _from(pool.pick_random(), true)

static func _from(template: Dictionary, boss: bool) -> EnemyData:
	var e := EnemyData.new()
	e.enemy_name = template["name"]
	e.hp = template["hp"]
	e.max_hp = template["hp"]
	e.dice = template["dice"]
	e.attack = template["attack"]
	e.hits = template.get("hits", 1)
	e.icon = template["icon"]
	e.tint = template.get("tint", Color.WHITE)
	e.is_boss = boss
	return e

## "D6+2 ×2" 같은 공격력 표기
func attack_text() -> String:
	var text := Dice.display_name(dice)
	if attack > 0:
		text += "+%d" % attack
	if hits > 1:
		text += " ×%d회" % hits
	return text
