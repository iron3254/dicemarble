class_name CardData
extends RefCounted

## 카드 원본 목록과 카드 관련 계산(강화·설명문·보상 뽑기)을 모아둔 곳

enum CardType { ATTACK, DEFENSE, CURSE, SPECIAL }
enum CostType { MANA, HP, GOLD }

## 공격 패·방어 패 각각의 기본 장수(턴 종료 시 이 장수가 될 때까지 뽑는다)
const HAND_SIZE := 3
## 카드가 들어가는 패: 공격 패(공격·특수 카드) / 방어 패(방어·저주 카드)
const SIDE_ATTACK := "attack"
const SIDE_DEFENSE := "defense"

## 막별 카드 등장 확률(%) — [3티어, 2티어, 1티어] 순서. 1티어가 가장 강한 카드
const TIER_CHANCE := {
	1: [100, 0, 0],
	2: [60, 30, 10],
	3: [40, 30, 30],
}
## 보유 아이템이 밀어주는 태그(예: 신뢰검 → 전기)의 카드는 이 배수만큼 더 잘 나온다
const FAVORED_TAG_WEIGHT := 3

## 상점 카드 가격(티어별)
const PRICE_BY_TIER := {3: 45, 2: 75, 1: 120}

## 카드 원본. tier 0 = 보상/상점에 나오지 않는 카드(기본·캐릭터 전용·저주)
## 선택 키: cost_type(기본 MANA), dice(없으면 주사위 없음), hits(공격 횟수), thunder(뇌문), poison(독),
##          heal(회복), lifesteal(흡혈), temp_str(이번 전투 힘), draw(카드 뽑기), mana_gain(마나 회복),
##          poison_double(독 2배), unplayable(사용 불가), hp_loss_in_hand(손에 있으면 턴 끝 HP 감소),
##          exclusive(캐릭터 전용), permanent(영구: 제거 불가), up_cost(강화 시 비용 감소)
const CARDS := {
	# ── 기본 카드(모든 캐릭터 시작 덱) ──
	"slash": {"name": "베기", "type": CardType.ATTACK, "tier": 0, "tag": "일반", "cost": 1, "dice": "D6", "value": 0},
	"guard": {"name": "막기", "type": CardType.DEFENSE, "tier": 0, "tag": "일반", "cost": 1, "dice": "D6", "value": 0},

	# ── 캐릭터 전용 카드 ──
	"flash_slash": {"name": "점멸 베기", "type": CardType.ATTACK, "tier": 0, "tag": "전기", "cost": 1, "dice": "D6", "value": 1, "thunder": 1, "exclusive": true, "permanent": true},
	"lightning_guard": {"name": "번개 방패", "type": CardType.DEFENSE, "tier": 0, "tag": "전기", "cost": 1, "dice": "D6", "value": 1, "thunder": 1, "exclusive": true, "permanent": true},
	"poison_needle": {"name": "독침", "type": CardType.ATTACK, "tier": 0, "tag": "독", "cost": 1, "dice": "D4", "value": 0, "poison": 3, "exclusive": true, "permanent": true},
	"poison_mist": {"name": "독안개", "type": CardType.DEFENSE, "tier": 0, "tag": "독", "cost": 1, "dice": "D6", "value": 0, "poison": 2, "exclusive": true, "permanent": true},
	"blood_strike": {"name": "피의 일격", "type": CardType.ATTACK, "tier": 0, "tag": "광폭", "cost": 3, "cost_type": CostType.HP, "dice": "D12", "value": 2, "exclusive": true, "permanent": true},
	"war_cry": {"name": "광기의 포효", "type": CardType.DEFENSE, "tier": 0, "tag": "광폭", "cost": 2, "cost_type": CostType.HP, "dice": "D6", "value": 2, "temp_str": 1, "exclusive": true, "permanent": true},
	"holy_strike": {"name": "신성한 일격", "type": CardType.ATTACK, "tier": 0, "tag": "성", "cost": 2, "dice": "D6", "value": 2, "heal": 2, "exclusive": true, "permanent": true},
	"holy_shield": {"name": "성스러운 방패", "type": CardType.DEFENSE, "tier": 0, "tag": "성", "cost": 1, "dice": "D6", "value": 2, "exclusive": true, "permanent": true},

	# ── 일반 ──
	"stab": {"name": "찌르기", "type": CardType.ATTACK, "tier": 3, "tag": "일반", "cost": 1, "dice": "D4", "value": 2},
	"heavy_strike": {"name": "강타", "type": CardType.ATTACK, "tier": 3, "tag": "일반", "cost": 2, "dice": "D6", "value": 3, "up_cost": true},
	"raise_shield": {"name": "방패 올리기", "type": CardType.DEFENSE, "tier": 3, "tag": "일반", "cost": 1, "dice": "D6", "value": 1},
	"dodge": {"name": "회피", "type": CardType.DEFENSE, "tier": 3, "tag": "일반", "cost": 0, "dice": "D4", "value": 0},
	"double_slash": {"name": "연속 베기", "type": CardType.ATTACK, "tier": 2, "tag": "일반", "cost": 2, "dice": "D6", "value": 0, "hits": 2},
	"iron_wall": {"name": "철벽", "type": CardType.DEFENSE, "tier": 2, "tag": "일반", "cost": 2, "dice": "D12", "value": 2},
	"focus": {"name": "집중", "type": CardType.SPECIAL, "tier": 2, "tag": "일반", "cost": 0, "draw": 2},
	"golden_strike": {"name": "황금 일격", "type": CardType.ATTACK, "tier": 2, "tag": "일반", "cost": 15, "cost_type": CostType.GOLD, "dice": "D12", "value": 4},
	"finishing_blow": {"name": "필살기", "type": CardType.ATTACK, "tier": 1, "tag": "일반", "cost": 3, "dice": "D20", "value": 3, "up_cost": true},
	"indomitable": {"name": "불굴", "type": CardType.DEFENSE, "tier": 1, "tag": "일반", "cost": 3, "dice": "D20", "value": 2, "up_cost": true},
	"meditate": {"name": "명상", "type": CardType.SPECIAL, "tier": 1, "tag": "일반", "cost": 0, "mana_gain": 2},

	# ── 전기 ──
	"spark": {"name": "전격", "type": CardType.ATTACK, "tier": 3, "tag": "전기", "cost": 1, "dice": "D6_16", "value": 0, "thunder": 1},
	"thunderbolt": {"name": "낙뢰", "type": CardType.ATTACK, "tier": 2, "tag": "전기", "cost": 2, "dice": "D6_THUNDER", "value": 2, "thunder": 1},
	"static_field": {"name": "정전기", "type": CardType.DEFENSE, "tier": 2, "tag": "전기", "cost": 1, "dice": "D6", "value": 1, "thunder": 1},
	"thunder_judgment": {"name": "천둥신의 심판", "type": CardType.ATTACK, "tier": 1, "tag": "전기", "cost": 3, "dice": "D20", "value": 0, "thunder": 3},

	# ── 독 ──
	"poison_coat": {"name": "독 바르기", "type": CardType.ATTACK, "tier": 3, "tag": "독", "cost": 1, "dice": "D4", "value": 0, "poison": 2},
	"venom": {"name": "맹독", "type": CardType.ATTACK, "tier": 2, "tag": "독", "cost": 2, "dice": "D6", "value": 0, "poison": 4},
	"smoke_screen": {"name": "독 연막", "type": CardType.DEFENSE, "tier": 2, "tag": "독", "cost": 1, "dice": "D6", "value": 1, "poison": 1},
	"plague": {"name": "역병", "type": CardType.SPECIAL, "tier": 1, "tag": "독", "cost": 1, "poison_double": true, "up_cost": true},

	# ── 성 ──
	"healing_light": {"name": "치유의 빛", "type": CardType.DEFENSE, "tier": 3, "tag": "성", "cost": 1, "dice": "D4", "value": 1, "heal": 2},
	"blessing": {"name": "축복", "type": CardType.DEFENSE, "tier": 2, "tag": "성", "cost": 2, "dice": "D6", "value": 2, "heal": 3},
	"purify_strike": {"name": "정화의 일격", "type": CardType.ATTACK, "tier": 2, "tag": "성", "cost": 2, "dice": "D6", "value": 2, "heal": 2},
	"judgment_light": {"name": "심판의 빛", "type": CardType.ATTACK, "tier": 1, "tag": "성", "cost": 3, "dice": "D12", "value": 4, "heal": 4},

	# ── 광폭(마나 대신 HP를 소모) ──
	"reckless_charge": {"name": "무모한 돌진", "type": CardType.ATTACK, "tier": 3, "tag": "광폭", "cost": 2, "cost_type": CostType.HP, "dice": "D6", "value": 3},
	"blood_thirst": {"name": "피의 갈증", "type": CardType.ATTACK, "tier": 2, "tag": "광폭", "cost": 3, "cost_type": CostType.HP, "dice": "D12", "value": 2, "lifesteal": true},
	"blood_shield": {"name": "피의 방패", "type": CardType.DEFENSE, "tier": 2, "tag": "광폭", "cost": 2, "cost_type": CostType.HP, "dice": "D12", "value": 1},
	"frenzy": {"name": "광란", "type": CardType.ATTACK, "tier": 1, "tag": "광폭", "cost": 5, "cost_type": CostType.HP, "dice": "D20", "value": 5},

	# ── 저주(패널티 카드, 강화 불가) ──
	"wound": {"name": "상처", "type": CardType.CURSE, "tier": 0, "tag": "저주", "cost": 0, "unplayable": true},
	"misfortune": {"name": "불운", "type": CardType.CURSE, "tier": 0, "tag": "저주", "cost": 0, "unplayable": true, "hp_loss_in_hand": 1},
}

## 원본을 복사해 덱에 넣을 카드 한 장을 만든다(강화해도 원본은 바뀌지 않도록 복사)
static func create(id: String) -> Dictionary:
	var card: Dictionary = CARDS[id].duplicate(true)
	card["id"] = id
	card["upgraded"] = false
	card["special_upgraded"] = false
	return card

static func display_name(card: Dictionary) -> String:
	var result: String = card["name"]
	if card.get("special_upgraded", false):
		result += "★"
	if card.get("upgraded", false):
		result += "+"
	return result

static func type_name(type: CardType) -> String:
	match type:
		CardType.ATTACK: return "공격"
		CardType.DEFENSE: return "방어"
		CardType.CURSE: return "저주"
		CardType.SPECIAL: return "특수"
	return "?"

## 이 카드가 공격 덱/패에 들어가는지 방어 덱/패에 들어가는지
static func hand_side(card: Dictionary) -> String:
	if card["type"] == CardType.DEFENSE or card["type"] == CardType.CURSE:
		return SIDE_DEFENSE
	return SIDE_ATTACK

static func tier_text(card: Dictionary) -> String:
	if card["type"] == CardType.CURSE:
		return "저주"
	if card.get("exclusive", false):
		return "전용"
	if card["tier"] == 0:
		return "기본"
	return "%d티어" % card["tier"]

## 광전사처럼 마나 대신 HP를 쓰는 캐릭터면 마나 비용을 HP 비용으로 바꿔서 본다
static func cost_type_of(card: Dictionary, hp_instead_of_mana: bool) -> CostType:
	var cost_type: CostType = card.get("cost_type", CostType.MANA)
	if cost_type == CostType.MANA and hp_instead_of_mana:
		return CostType.HP
	return cost_type

static func cost_text(card: Dictionary, hp_instead_of_mana: bool = false) -> String:
	if card.get("unplayable", false):
		return "사용 불가"
	match cost_type_of(card, hp_instead_of_mana):
		CostType.HP: return "HP %d" % card["cost"]
		CostType.GOLD: return "골드 %d" % card["cost"]
	return "마나 %d" % card["cost"]

## 카드 효과를 사람이 읽을 수 있는 여러 줄 문장으로 만든다
static func description(card: Dictionary) -> String:
	var lines: Array[String] = []
	if card.has("dice"):
		var base := "피해" if card["type"] == CardType.ATTACK else "보호막"
		var text := "%s: %s" % [base, Dice.display_name(card["dice"])]
		if card.get("value", 0) != 0:
			text += " + %d" % card["value"]
		if card.get("hits", 1) > 1:
			text += " ×%d회" % card["hits"]
		lines.append(text)
	if card.get("dice", "") == "D6_THUNDER":
		lines.append("번개 면: 뇌문 +1")
	if card.has("thunder"):
		lines.append("뇌문 +%d" % card["thunder"])
	if card.has("poison"):
		lines.append("독 +%d" % card["poison"])
	if card.has("heal"):
		lines.append("HP %d 회복" % card["heal"])
	if card.get("lifesteal", false):
		lines.append("준 피해의 절반 회복")
	if card.has("temp_str"):
		lines.append("이번 전투 힘 +%d" % card["temp_str"])
	if card.has("draw"):
		lines.append("카드 %d장 뽑기" % card["draw"])
	if card.has("mana_gain"):
		lines.append("마나 %d 회복" % card["mana_gain"])
	if card.get("poison_double", false):
		lines.append("적의 독 2배")
	if card.get("unplayable", false):
		lines.append("사용할 수 없음")
	if card.has("hp_loss_in_hand"):
		lines.append("손에 있으면 턴 끝에 HP -%d" % card["hp_loss_in_hand"])
	if card.get("permanent", false):
		lines.append("[영구] 제거 불가")
	return "\n".join(lines)

static func can_upgrade(card: Dictionary) -> bool:
	return card["type"] != CardType.CURSE and not card.get("upgraded", false)

## 특수강화는 캐릭터 전용 카드만 가능
static func can_special_upgrade(card: Dictionary) -> bool:
	return card.get("exclusive", false) and not card.get("special_upgraded", false)

## 일반강화: 효과가 강해지거나(주사위 카드는 고정값 +2) 비용이 줄어든다
static func upgrade(card: Dictionary) -> void:
	card["upgraded"] = true
	if card.get("up_cost", false):
		card["cost"] = max(0, card["cost"] - 1)
	elif card.has("dice"):
		card["value"] = card.get("value", 0) + 2
	_boost_effects(card)

## 특수강화: 고정값 +3, 비용 -1, 부가 효과 +1
static func special_upgrade(card: Dictionary) -> void:
	card["special_upgraded"] = true
	if card.has("dice"):
		card["value"] = card.get("value", 0) + 3
	card["cost"] = max(0, card["cost"] - 1)
	_boost_effects(card)

static func _boost_effects(card: Dictionary) -> void:
	for key in ["thunder", "poison", "heal", "draw", "mana_gain", "temp_str"]:
		if card.has(key):
			card[key] += 1

static func price(card: Dictionary) -> int:
	return PRICE_BY_TIER.get(card["tier"], 60)

## 막별 티어 확률표에 따라 서로 다른 보상 카드 count장을 뽑는다
static func draw_reward_cards(act: int, count: int, favored_tags: Array) -> Array:
	var result: Array = []
	var used_ids: Array = []
	for i in range(count):
		var tier := _roll_tier(act)
		var pool: Array = []
		var weights: Array = []
		for id in CARDS:
			var template: Dictionary = CARDS[id]
			if template["tier"] != tier or used_ids.has(id):
				continue
			pool.append(id)
			weights.append(FAVORED_TAG_WEIGHT if favored_tags.has(template["tag"]) else 1)
		if pool.is_empty():
			continue
		var picked: String = pool[_weighted_index(weights)]
		used_ids.append(picked)
		result.append(create(picked))
	return result

static func _roll_tier(act: int) -> int:
	var chances: Array = TIER_CHANCE[clampi(act, 1, 3)]
	var r := randi_range(1, 100)
	if r <= chances[0]:
		return 3
	if r <= chances[0] + chances[1]:
		return 2
	return 1

static func _weighted_index(weights: Array) -> int:
	var total := 0
	for w in weights:
		total += w
	var r := randi_range(1, total)
	for i in range(weights.size()):
		r -= weights[i]
		if r <= 0:
			return i
	return weights.size() - 1
