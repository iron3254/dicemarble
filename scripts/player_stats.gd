class_name PlayerStats
extends RefCounted

enum StatType { ATTACK, DEFENSE, MANA }
const ALL_STATS: Array[StatType] = [StatType.ATTACK, StatType.DEFENSE, StatType.MANA]

var attack: int = 0
var defense: int = 0
## 마력 최대치(=마력 스탯) : 상한 없이 계속 성장 가능
var mana_max: int = 0
var mana: int = 0
var hp: int = 20
var max_hp: int = 20
var skill_cards: Array[Dictionary] = []

## 스탯을 amount만큼 증감시킨다(음수면 디버프, 0 밑으로는 내려가지 않음)
func add_stat(type: StatType, amount: int) -> void:
	match type:
		StatType.ATTACK:
			attack = max(0, attack + amount)
		StatType.DEFENSE:
			defense = max(0, defense + amount)
		StatType.MANA:
			mana_max = max(0, mana_max + amount)
			mana = clamp(mana + amount, 0, mana_max)

func stat_name(type: StatType) -> String:
	match type:
		StatType.ATTACK: return "공격"
		StatType.DEFENSE: return "방어"
		StatType.MANA: return "마력"
	return "?"

func summary() -> String:
	return "공격 %d / 방어 %d / 마력 %d(%d) / HP %d(%d) / 스킬카드 %d장" % [
		attack, defense, mana, mana_max, hp, max_hp, skill_cards.size()
	]
