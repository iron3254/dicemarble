class_name MapView
extends Control

## 갈림길 지도를 그린다. 아래에서 위로(↑) 진행하며, 지금 갈 수 있는 칸만 누를 수 있다

signal node_chosen(index: int)

@export var row_spacing: float = 64.0
@export var column_spacing: float = 120.0
@export var margin: float = 46.0
@export var node_size: Vector2 = Vector2(82, 40)

@export_group("칸 색상")
@export var battle_color: Color = Color(0.75, 0.32, 0.28)
@export var event_color: Color = Color(0.3, 0.62, 0.38)
@export var shop_color: Color = Color(0.78, 0.6, 0.22)
@export var boss_color: Color = Color(0.55, 0.22, 0.7)
@export var line_color: Color = Color(0.45, 0.45, 0.5)
@export var visited_line_color: Color = Color(1.0, 0.85, 0.35)

var _map: MapData
var _visited: Array = []

func type_color(type: MapData.NodeType) -> Color:
	match type:
		MapData.NodeType.EVENT: return event_color
		MapData.NodeType.SHOP: return shop_color
		MapData.NodeType.BOSS: return boss_color
	return battle_color

## 지도를 다시 그린다. available: 지금 고를 수 있는 칸, visited: 이미 지나온 칸
func show_map(map: MapData, available: Array, visited: Array) -> void:
	_map = map
	_visited = visited
	for child in get_children():
		remove_child(child)
		child.queue_free()

	custom_minimum_size = Vector2(margin * 2 + column_spacing * (MapData.COLUMNS - 1), margin * 2 + row_spacing * map.rows)
	size = custom_minimum_size

	for i in range(map.nodes.size()):
		var node: Dictionary = map.nodes[i]
		var is_boss: bool = node["type"] == MapData.NodeType.BOSS
		var button_size := node_size * (1.4 if is_boss else 1.0)
		var b := UiKit.button(MapData.type_name(node["type"]), 20 if is_boss else 16)
		b.size = button_size
		b.position = node_center(i) - button_size * 0.5
		var color := type_color(node["type"])
		if visited.has(i):
			b.add_theme_stylebox_override("disabled", UiKit.box(color.darkened(0.2), 8, visited_line_color, 3))
			b.add_theme_stylebox_override("normal", UiKit.box(color, 8, visited_line_color, 3))
		else:
			UiKit.color_button(b, color)
		b.disabled = not available.has(i)
		if available.has(i):
			## 갈 수 있는 칸은 깜빡여서 눈에 띄게 한다
			var tween := b.create_tween().set_loops()
			tween.tween_property(b, "modulate", Color(1.35, 1.35, 1.35), 0.5)
			tween.tween_property(b, "modulate", Color.WHITE, 0.5)
		b.pressed.connect(_on_node_pressed.bind(i))
		add_child(b)
	queue_redraw()

func node_center(index: int) -> Vector2:
	var node: Dictionary = _map.nodes[index]
	var x: float
	if node["type"] == MapData.NodeType.BOSS:
		x = margin + column_spacing * (MapData.COLUMNS - 1) * 0.5
	else:
		x = margin + node["col"] * column_spacing
	var y: float = custom_minimum_size.y - margin - node["row"] * row_spacing
	return Vector2(x, y)

func _draw() -> void:
	if _map == null:
		return
	for i in range(_map.nodes.size()):
		for n in _map.nodes[i]["next"]:
			var walked: bool = _visited.has(i) and _visited.has(n)
			draw_line(node_center(i), node_center(n), visited_line_color if walked else line_color, 4.0 if walked else 2.5, true)

func _on_node_pressed(index: int) -> void:
	node_chosen.emit.call_deferred(index)
