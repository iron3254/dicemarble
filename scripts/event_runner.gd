class_name EventRunner
extends RefCounted

## 이벤트 칸에서 일어나는 일들. 선택을 끝내야(이벤트가 남아있지 않아야) 다음 칸으로 갈 수 있다

const BASIC_EVENTS := ["merchant", "dice_altar", "relic", "spring", "forge", "explorer", "bridge"]

## 무작위 이벤트 하나를 진행한다
static func run(gm: GameManager) -> void:
	var pool: Array = BASIC_EVENTS.duplicate()
	## 기획서: 캐릭터 전용 카드는 2막 이후 등장하는 전용 이벤트로 특수강화 가능
	if gm.act >= 2 and not gm.stats.special_upgradable_indices().is_empty():
		pool.append("training_altar")
		pool.append("training_altar")
	match pool.pick_random():
		"merchant": await _merchant(gm)
		"dice_altar": await _dice_altar(gm)
		"relic": await _relic(gm)
		"spring": await _spring(gm)
		"forge": await _forge(gm)
		"explorer": await _explorer(gm)
		"bridge": await _bridge(gm)
		"training_altar": await _training_altar(gm)

static func _merchant(gm: GameManager) -> void:
	const PRICE := 30
	var choice := await gm.dialog.ask("수상한 상인",
		"망토를 뒤집어쓴 상인이 낡은 카드 꾸러미를 내민다.\n\"%d골드면 이 중 하나를 고르게 해주지.\"" % PRICE,
		["%d골드를 내고 카드 1장 고르기" % PRICE, "무시하고 지나간다"],
		[gm.stats.gold < PRICE, false])
	if choice == 0:
		gm.stats.gold -= PRICE
		gm.update_side_panel()
		await gm.offer_card_reward("상인의 카드 중 1장을 고르세요")

## 기획서 '주사위 판정에 따른 버프 획득'
static func _dice_altar(gm: GameManager) -> void:
	var choice := await gm.dialog.ask("주사위 신의 제단",
		"다신교의 신 중 하나인 '주사위의 신'을 모신 제단이다.\n주사위를 바치면 신이 응답한다고 한다.\n\n1~2: 벌을 받는다 (HP -5)\n3~4: 골드 +40\n5~6: 축복 (버프 3개 중 1개 선택)",
		["주사위를 굴린다", "지나간다"])
	if choice != 0:
		return
	var roll := await gm.roll_event_dice()
	if roll <= 2:
		gm.stats.take_damage(5)
		gm.popup("HP -5", gm.loss_color)
		await gm.dialog.ask("신이 노했다", "주사위 %d — 번개가 내리쳤다. HP -5" % roll, ["확인"])
	elif roll <= 4:
		gm.stats.gain_gold(40)
		gm.popup("골드 +40", gm.gold_color)
		await gm.dialog.ask("작은 축복", "주사위 %d — 제단 위에 금화가 놓여 있다. 골드 +40" % roll, ["확인"])
	else:
		await gm.choose_buff("주사위 %d — 신의 축복!" % roll)
	gm.update_side_panel()

static func _relic(gm: GameManager) -> void:
	var choice := await gm.dialog.ask("바다의 유물",
		"해변에서 고대 문명의 유물을 주웠다. 바다의 유물은 비싸게 팔리지만, 불길한 기운이 느껴진다.",
		["상인에게 판다 (골드 +80, 저주 카드 '불운' 획득)", "유물의 힘을 흡수한다 (최대 HP +5)", "그냥 둔다"])
	match choice:
		0:
			gm.stats.gain_gold(80)
			gm.stats.deck.append(CardData.create("misfortune"))
			gm.popup("골드 +80 / 저주 '불운'", gm.gold_color)
		1:
			gm.stats.max_hp += 5
			gm.stats.hp += 5
			gm.popup("최대 HP +5", gm.gain_color)
	gm.update_side_panel()

static func _spring(gm: GameManager) -> void:
	var heal_amount := int(ceil(gm.stats.max_hp * 0.3))
	var choice := await gm.dialog.ask("신비한 샘",
		"숲속에서 맑은 샘을 발견했다.",
		["물을 마신다 (HP %d 회복)" % heal_amount, "몸을 씻는다 (카드 1장 제거)", "지나간다"],
		[false, gm.stats.removable_indices().is_empty(), false])
	match choice:
		0:
			var healed := gm.stats.heal(heal_amount)
			gm.popup("HP +%d" % healed, gm.gain_color)
		1:
			await gm.remove_card_from_deck("샘물에 씻어낼 카드를 고르세요")
	gm.update_side_panel()

static func _forge(gm: GameManager) -> void:
	var choice := await gm.dialog.ask("떠돌이 대장장이",
		"\"좋은 무기는 좋은 손에서 나오지. 카드 하나 손봐줄까? 공짜로.\"",
		["카드 1장 강화", "지나간다"],
		[gm.stats.upgradable_indices().is_empty(), false])
	if choice == 0:
		await gm.upgrade_card_in_deck("강화할 카드를 고르세요", false)
	gm.update_side_panel()

## 기획서: 능력치는 특정 이벤트에서 '선택 분배' 가능
static func _explorer(gm: GameManager) -> void:
	var options: Array = ["힘 +1", "방어 +1"]
	options.append("최대 HP +5" if gm.stats.hp_instead_of_mana() else "마나 +1")
	var choice := await gm.dialog.ask("탐험가의 기록",
		"미지 문명을 조사하던 선배 탐험가의 일지를 발견했다. 무엇을 익힐까?", options)
	match choice:
		0:
			gm.stats.add_stat(PlayerStats.StatType.ATTACK, 1)
		1:
			gm.stats.add_stat(PlayerStats.StatType.DEFENSE, 1)
		2:
			if gm.stats.hp_instead_of_mana():
				gm.stats.max_hp += 5
				gm.stats.hp += 5
			else:
				gm.stats.add_stat(PlayerStats.StatType.MANA, 1)
	gm.popup(options[choice], gm.gain_color)
	gm.update_side_panel()

static func _bridge(gm: GameManager) -> void:
	await gm.dialog.ask("무너지는 다리",
		"낡은 다리가 흔들린다! 주사위를 굴려 4 이상이 나오면 무사히 건넌다.\n실패하면 떨어져서 HP -6.",
		["주사위를 굴린다"])
	var roll := await gm.roll_event_dice()
	if roll >= 4:
		await gm.dialog.ask("성공!", "주사위 %d — 무사히 건넜다. 다리 건너에서 골드 20을 주웠다." % roll, ["확인"])
		gm.stats.gain_gold(20)
		gm.popup("골드 +20", gm.gold_color)
	else:
		gm.stats.take_damage(6)
		gm.popup("HP -6", gm.loss_color)
		await gm.dialog.ask("실패...", "주사위 %d — 다리가 무너졌다. HP -6" % roll, ["확인"])
	gm.update_side_panel()

static func _training_altar(gm: GameManager) -> void:
	var choice := await gm.dialog.ask("수련의 제단 (전용 이벤트)",
		"%s의 힘에 반응하는 제단이다. 전용 카드를 특수 강화할 수 있다." % gm.stats.character["name"],
		["전용 카드 특수 강화", "지나간다"])
	if choice == 0:
		await gm.upgrade_card_in_deck("특수 강화할 전용 카드를 고르세요", true)
	gm.update_side_panel()
