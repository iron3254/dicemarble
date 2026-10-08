class_name BuffData
extends RefCounted

## 보스 처치·이벤트 보상으로 나오는 랜덤 버프(3개 중 1개 선택)
const BUFFS := [
	{"name": "힘 +1", "desc": "공격할 때 피해 +1", "stat": PlayerStats.StatType.ATTACK, "amount": 1},
	{"name": "방어 +1", "desc": "방어 카드 보호막 +1", "stat": PlayerStats.StatType.DEFENSE, "amount": 1},
	{"name": "마나 +1", "desc": "전투 시작 마나와 최대 마나 +1", "stat": PlayerStats.StatType.MANA, "amount": 1, "mana_only": true},
	{"name": "마나 회복 +1", "desc": "매 턴 마나 회복량 +1", "mana_regen": 1, "mana_only": true},
	{"name": "최대 HP +6", "desc": "최대 HP와 현재 HP +6", "max_hp": 6},
	{"name": "골드 +60", "desc": "골드 60 획득", "gold": 60},
	{"name": "포션 +1", "desc": "체력 회복 포션 1개", "potion": 1},
	{"name": "완전 회복", "desc": "HP 전부 회복", "heal_full": true},
]

## 이 캐릭터에게 의미 있는 버프 중 서로 다른 3개를 무작위로 고른다
static func pick_three(stats: PlayerStats) -> Array:
	var pool: Array = BUFFS.filter(func(b): return not (b.get("mana_only", false) and stats.hp_instead_of_mana()))
	pool.shuffle()
	return pool.slice(0, 3)

## 버프를 적용하고 결과 문구를 반환한다
static func apply(buff: Dictionary, stats: PlayerStats) -> String:
	if buff.has("stat"):
		stats.add_stat(buff["stat"], buff["amount"])
	if buff.has("mana_regen"):
		stats.mana_regen_bonus += buff["mana_regen"]
	if buff.has("max_hp"):
		stats.max_hp += buff["max_hp"]
		stats.hp += buff["max_hp"]
	if buff.has("gold"):
		stats.gain_gold(buff["gold"])
	if buff.has("potion"):
		stats.potions = min(PlayerStats.MAX_POTIONS, stats.potions + buff["potion"])
	if buff.get("heal_full", false):
		stats.hp = stats.max_hp
	return buff["name"]
