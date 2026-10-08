class_name CharacterData
extends RefCounted

## 기본 능력치(기획서 '기본 능력치' 표). 캐릭터별 보정치는 여기에 더해진다
const BASE_STRENGTH := 0
const BASE_DEFENSE := 0
const BASE_MANA := 2
const BASE_HP := 20

## 캐릭터별 추가 스탯(기획서 '캐릭터별 스테이터스 비교 표')
## price: 메인 메뉴에서 명성으로 구매하는 가격(0이면 처음부터 보유)
## unlock_route: 이 종류의 칸을 가장 많이 지나 막을 클리어하면 구매 가능해짐
const CHARACTERS := [
	{
		"id": "thunder_sword", "name": "뇌검사", "age": "21세",
		"desc": "전기 공격을 쓴다. 적에게 뇌문을 새겨 추가 피해를 준다.",
		"strength": 1, "defense": 0, "mana": 2, "hp": 5,
		"item": "trust_sword", "cards": ["flash_slash", "lightning_guard"],
		"price": 0, "unlock_route": "", "hp_cost": false, "potion_bonus": 0.0,
		"color": Color(0.35, 0.6, 1.0),
	},
	{
		"id": "poisoner", "name": "독술사", "age": "",
		"desc": "독을 쌓아 매 턴 적의 체력을 깎는다. 마나가 넉넉하다.",
		"strength": 0, "defense": 0, "mana": 3, "hp": 0,
		"item": "poison_gland", "cards": ["poison_needle", "poison_mist"],
		"price": 150, "unlock_route": "event", "hp_cost": false, "potion_bonus": 0.0,
		"color": Color(0.4, 0.75, 0.35),
	},
	{
		"id": "berserker", "name": "광전사", "age": "",
		"desc": "마나 대신 HP를 소모해 카드를 쓴다. 체력이 매우 높다.",
		"strength": 1, "defense": 0, "mana": -2, "hp": 30,
		"item": "", "cards": ["blood_strike", "war_cry"],
		"price": 200, "unlock_route": "battle", "hp_cost": true, "potion_bonus": 0.1,
		"color": Color(0.85, 0.3, 0.25),
	},
	{
		"id": "paladin", "name": "성기사", "age": "",
		"desc": "공격과 방어가 고르고, 회복 카드와 부활 목걸이를 가졌다.",
		"strength": 1, "defense": 1, "mana": 1, "hp": 5,
		"item": "holy_necklace", "cards": ["holy_strike", "holy_shield"],
		"price": 250, "unlock_route": "shop", "hp_cost": false, "potion_bonus": 0.0,
		"color": Color(0.9, 0.82, 0.5),
	},
]

static func find(id: String) -> Dictionary:
	for c in CHARACTERS:
		if c["id"] == id:
			return c
	return {}

## 캐릭터 소개 화면용 능력치 요약
static func stat_text(c: Dictionary) -> String:
	return "힘 %d · 방어 %d · 마나 %d · HP %d" % [
		BASE_STRENGTH + c["strength"], BASE_DEFENSE + c["defense"],
		max(0, BASE_MANA + c["mana"]), BASE_HP + c["hp"],
	]
