class_name ItemData
extends RefCounted

## 아이템 목록(기획서 '아이템 종류'). tag: 이 태그 카드가 보상에 더 잘 나온다
const ITEMS := {
	"trust_sword": {
		"name": "신뢰검", "kind": "무기(검)", "tag": "전기",
		"desc": "전기 카드가 나올 확률 증가. 뇌문이 있는 적을 공격하면 피해 +1",
	},
	"poison_gland": {
		"name": "독샘", "kind": "무기(독샘)", "tag": "독",
		"desc": "독 카드가 나올 확률 증가. 독을 부여할 때 +1",
	},
	"holy_necklace": {
		"name": "목걸이", "kind": "장신구", "tag": "성",
		"desc": "성 카드가 나올 확률 증가. HP가 0이 되면 한 번 최대 HP의 50%로 부활하고 부서진 목걸이가 된다",
	},
	"broken_necklace": {
		"name": "부서진 목걸이", "kind": "장신구", "tag": "성",
		"desc": "성 카드가 나올 확률 증가",
	},
}

## 체력 회복 포션: 최대 HP의 20% 회복(광전사는 +10%)
const POTION_HEAL_RATIO := 0.2
const POTION_PRICE := 30

static func item_name(id: String) -> String:
	return ITEMS[id]["name"]
