# EnemyTooltip.gd
# Displays enemy info on hover/tap: title, tagline, threat, special mechanic,
# and which towers counter it. Uses plain Control so it sizes to content.
extends Control

var _title_label: Label
var _tagline_label: Label
var _threat_badge: Label
var _special_label: Label
var _lesson_label: Label
var _counters_label: Label
var _vbox: VBoxContainer

const BG_COLOR := Color("#0A1628")
const BORDER_COLOR := Color("#FF3366")
const BORDER_WIDTH := 1
const MARGIN := 8

func _ready() -> void:
	_build_ui()
	visible = false

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)
	draw_rect(Rect2(Vector2.ZERO, size), BORDER_COLOR, false, BORDER_WIDTH)

func _build_ui() -> void:
	_vbox = VBoxContainer.new()
	_vbox.position = Vector2(MARGIN, MARGIN)
	_vbox.add_theme_constant_override("separation", 2)
	add_child(_vbox)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 13)
	_title_label.add_theme_color_override("font_color", Color("#FF3366"))
	_vbox.add_child(_title_label)

	_tagline_label = Label.new()
	_tagline_label.add_theme_font_size_override("font_size", 10)
	_tagline_label.add_theme_color_override("font_color", Color("#C0D8E8"))
	_tagline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vbox.add_child(_tagline_label)

	_threat_badge = Label.new()
	_threat_badge.add_theme_font_size_override("font_size", 10)
	_vbox.add_child(_threat_badge)

	_special_label = Label.new()
	_special_label.add_theme_font_size_override("font_size", 10)
	_special_label.add_theme_color_override("font_color", Color("#E8F4FD"))
	_special_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vbox.add_child(_special_label)

	_lesson_label = Label.new()
	_lesson_label.add_theme_font_size_override("font_size", 10)
	_lesson_label.add_theme_color_override("font_color", Color("#80B0D0"))
	_vbox.add_child(_lesson_label)

	_counters_label = Label.new()
	_counters_label.add_theme_font_size_override("font_size", 10)
	_counters_label.add_theme_color_override("font_color", Color("#00FF88"))
	_counters_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vbox.add_child(_counters_label)

func show_for_enemy(enemy_id: String) -> void:
	var edata: EnemyData = DataRegistry.get_enemy(enemy_id)
	if edata == null:
		visible = false
		return

	_title_label.text = edata.title if edata.title != "" else enemy_id.replace("_", " ").capitalize()
	_tagline_label.text = edata.tagline
	_special_label.text = edata.special

	var threat_color = Color("#FFD700")
	match edata.threat.to_lower():
		"low": threat_color = Color("#00FF88")
		"medium": threat_color = Color("#FFD700")
		"high": threat_color = Color("#FF8800")
		"boss": threat_color = Color("#FF3366")
	_threat_badge.text = "  " + edata.threat + "  "
	_threat_badge.add_theme_color_override("font_color", threat_color)

	if edata.lesson != "":
		_lesson_label.text = edata.lesson
		_lesson_label.visible = true
	else:
		_lesson_label.visible = false

	var counters: Array[String] = []
	for tower_id in DataRegistry.towers:
		var td: TowerData = DataRegistry.towers[tower_id]
		if enemy_id in td.strong_against:
			counters.append(td.tower_name)
	if counters.size() > 0:
		var shown = counters.slice(0, 3)
		var label_text = "Weak to: " + ", ".join(shown)
		if counters.size() > 3:
			label_text += " +" + str(counters.size() - 3) + " more"
		_counters_label.text = label_text
		_counters_label.visible = true
	else:
		_counters_label.visible = false

	# Compute size from VBox content, then size this Control to fit
	var content_size = _vbox.get_combined_minimum_size()
	size = content_size + Vector2(MARGIN * 2, MARGIN * 2)
	visible = true
	queue_redraw()

func hide_tooltip() -> void:
	visible = false
