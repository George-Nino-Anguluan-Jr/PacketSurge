# CommandPanel.gd
# Reusable command panel overlay. Add as a child to any scene to open.
# Usage from any script:
#   var panel = preload("res://scenes/core/CommandPanel.gd").new()
#   add_child(panel)
extends CanvasLayer

var _cmd_output: RichTextLabel = null
var _cmd_output_scroll: ScrollContainer = null
var _cmd_input: LineEdit = null
var _cmd_history: Array = []
var _cmd_history_idx: int = -1
var _cmd_suggestions_bar: HBoxContainer = null
var _cmd_suggestions: Array = []
var _cmd_suggestion_idx: int = -1

const ALL_COMMANDS = [
	"help", "list_towers", "list_levels", "status", "clear",
	"unlock_tower", "unlock_all_towers", "unlock_level", "unlock_all_levels", "unlock_all",
	"master_lesson", "master_all", "set_stars", "reset_progress",
	"god_mode", "set_ram", "kill_all", "skip_wave",
	"set_volume", "set_music", "goto", "reset_tutorials", "save", "fps",
]

func _ready() -> void:
	layer = 100
	_build_command_panel()

func _build_command_panel() -> void:
	var vp := get_viewport().get_visible_rect().size
	var min_dim := minf(maxf(vp.x, 320.0), maxf(vp.y, 240.0))

	var panel_root := Control.new()
	panel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_root.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_root.name = "CommandPanelRoot"

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	bg.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			queue_free()
	)
	panel_root.add_child(bg)

	var panel_w := minf(vp.x * 0.9, 700.0)
	var panel_h := minf(vp.y * 0.85, 550.0)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(panel_w, panel_h)
	panel.size = Vector2(panel_w, panel_h)
	panel.position = Vector2((vp.x - panel_w) / 2.0, (vp.y - panel_h) / 2.0)
	panel.z_index = 10

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0D1B2A")
	panel_style.border_color = Color("#FF3366")
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	panel_root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Top bar
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	vbox.add_child(top_row)

	var title := Label.new()
	title.text = "CMD PANEL"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", int(min_dim * 0.038))
	title.add_theme_color_override("font_color", Color("#FF3366"))
	top_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(36, 36)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color("#1A3A5A")
	close_style.corner_radius_top_left = 4
	close_style.corner_radius_top_right = 4
	close_style.corner_radius_bottom_left = 4
	close_style.corner_radius_bottom_right = 4
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_color_override("font_color", Color("#FF3366"))
	close_btn.add_theme_font_size_override("font_size", int(min_dim * 0.028))
	close_btn.pressed.connect(func(): queue_free())
	top_row.add_child(close_btn)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color("#1A3A5A"))
	vbox.add_child(sep)

	# Output
	_cmd_output_scroll = ScrollContainer.new()
	_cmd_output_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cmd_output_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_cmd_output_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_cmd_output_scroll.follow_focus = true
	_cmd_output_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	var out_style := StyleBoxFlat.new()
	out_style.bg_color = Color("#050D1A")
	out_style.corner_radius_top_left = 4
	out_style.corner_radius_top_right = 4
	out_style.corner_radius_bottom_left = 4
	out_style.corner_radius_bottom_right = 4
	out_style.content_margin_left = 10
	out_style.content_margin_right = 10
	out_style.content_margin_top = 8
	out_style.content_margin_bottom = 8
	_cmd_output_scroll.add_theme_stylebox_override("panel", out_style)
	vbox.add_child(_cmd_output_scroll)

	_cmd_output = RichTextLabel.new()
	_cmd_output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cmd_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cmd_output.bbcode_enabled = true
	_cmd_output.fit_content = false
	_cmd_output.scroll_following = true
	_cmd_output.selection_enabled = true
	_cmd_output.mouse_filter = Control.MOUSE_FILTER_STOP
	_cmd_output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cmd_output.add_theme_font_size_override("normal_font_size", int(min_dim * 0.022))
	_cmd_output_scroll.add_child(_cmd_output)

	# Suggestion bar
	_cmd_suggestions_bar = HBoxContainer.new()
	_cmd_suggestions_bar.add_theme_constant_override("separation", 6)
	_cmd_suggestions_bar.visible = false
	vbox.add_child(_cmd_suggestions_bar)

	# Input row
	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 8)
	vbox.add_child(input_row)

	_cmd_input = LineEdit.new()
	_cmd_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cmd_input.placeholder_text = "Type a command..."
	var inp_style := StyleBoxFlat.new()
	inp_style.bg_color = Color("#0A1628")
	inp_style.border_color = Color("#1A3A5A")
	inp_style.border_width_left = 1
	inp_style.border_width_right = 1
	inp_style.border_width_top = 1
	inp_style.border_width_bottom = 1
	inp_style.corner_radius_top_left = 4
	inp_style.corner_radius_top_right = 4
	inp_style.corner_radius_bottom_left = 4
	inp_style.corner_radius_bottom_right = 4
	inp_style.content_margin_left = 10
	inp_style.content_margin_right = 10
	_cmd_input.add_theme_stylebox_override("normal", inp_style)
	_cmd_input.add_theme_color_override("font_color", Color("#E8F4FD"))
	_cmd_input.add_theme_color_override("font_placeholder_color", Color("#4A7FA5"))
	_cmd_input.add_theme_font_size_override("font_size", int(min_dim * 0.026))
	_cmd_input.text_submitted.connect(_on_cmd_submitted)
	_cmd_input.text_changed.connect(_on_cmd_text_changed)
	_cmd_input.gui_input.connect(_on_cmd_input_gui)
	input_row.add_child(_cmd_input)

	var run_btn := Button.new()
	run_btn.text = "RUN"
	run_btn.custom_minimum_size = Vector2(70, 0)
	var run_style := StyleBoxFlat.new()
	run_style.bg_color = Color("#FF3366")
	run_style.corner_radius_top_left = 4
	run_style.corner_radius_top_right = 4
	run_style.corner_radius_bottom_left = 4
	run_style.corner_radius_bottom_right = 4
	run_btn.add_theme_stylebox_override("normal", run_style)
	run_btn.add_theme_color_override("font_color", Color("#050D1A"))
	run_btn.add_theme_font_size_override("font_size", int(min_dim * 0.026))
	run_btn.pressed.connect(func(): _on_cmd_submitted(_cmd_input.text))
	input_row.add_child(run_btn)

	add_child(panel_root)
	_print_cmd_output("[color=#00D4FF]> Command Panel opened.[/color]")
	_print_cmd_output("[color=#4A7FA5]Type [color=#FFB800]help[/color] to see available commands.[/color]")

# ─── INPUT HANDLING ────────────────────────────────────
func _on_cmd_input_gui(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB:
			_apply_suggestion()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_UP:
			if _cmd_history.size() > 0:
				_cmd_history_idx = mini(_cmd_history_idx + 1, _cmd_history.size() - 1)
				_cmd_input.text = _cmd_history[_cmd_history.size() - 1 - _cmd_history_idx]
				_cmd_input.caret_column = _cmd_input.text.length()
				_update_suggestions()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			if _cmd_history_idx > 0:
				_cmd_history_idx -= 1
				_cmd_input.text = _cmd_history[_cmd_history.size() - 1 - _cmd_history_idx]
			else:
				_cmd_history_idx = -1
				_cmd_input.text = ""
			_cmd_input.caret_column = _cmd_input.text.length()
			_update_suggestions()
			get_viewport().set_input_as_handled()

func _on_cmd_submitted(text: String) -> void:
	var cmd = text.strip_edges()
	if cmd == "":
		return
	_cmd_history.append(cmd)
	_cmd_history_idx = -1
	_cmd_input.text = ""
	_clear_suggestions()
	_print_cmd_output("[color=#E8F4FD]> " + cmd + "[/color]")
	_execute_command(cmd)

# ─── AUTOCOMPLETE ──────────────────────────────────────
func _on_cmd_text_changed(_new_text: String) -> void:
	_update_suggestions()

func _update_suggestions() -> void:
	_clear_suggestions()
	var typed = _cmd_input.text.strip_edges().to_lower()
	if typed == "":
		return
	_cmd_suggestions.clear()
	for cmd in ALL_COMMANDS:
		if cmd.begins_with(typed) and cmd != typed:
			_cmd_suggestions.append(cmd)
	if _cmd_suggestions.size() == 0:
		return
	_cmd_suggestion_idx = -1
	_cmd_suggestions_bar.visible = true
	var vp := get_viewport().get_visible_rect().size
	var min_dim := minf(maxf(vp.x, 320.0), maxf(vp.y, 240.0))
	var chip_font := int(min_dim * 0.016)
	for i in range(mini(_cmd_suggestions.size(), 6)):
		var suggestion = _cmd_suggestions[i]
		var chip := Button.new()
		chip.text = suggestion
		chip.add_theme_font_size_override("font_size", chip_font)
		var chip_style := StyleBoxFlat.new()
		chip_style.bg_color = Color("#1A3A5A")
		chip_style.corner_radius_top_left = 4
		chip_style.corner_radius_top_right = 4
		chip_style.corner_radius_bottom_left = 4
		chip_style.corner_radius_bottom_right = 4
		chip_style.content_margin_left = 8
		chip_style.content_margin_right = 8
		chip_style.content_margin_top = 2
		chip_style.content_margin_bottom = 2
		chip.add_theme_stylebox_override("normal", chip_style)
		chip.add_theme_color_override("font_color", Color("#00D4FF"))
		var idx := i
		chip.pressed.connect(func(): _apply_suggestion_idx(idx))
		_cmd_suggestions_bar.add_child(chip)

func _apply_suggestion() -> void:
	if _cmd_suggestions.size() == 0:
		return
	_cmd_suggestion_idx += 1
	if _cmd_suggestion_idx >= _cmd_suggestions.size():
		_cmd_suggestion_idx = 0
	_apply_suggestion_idx(_cmd_suggestion_idx)

func _apply_suggestion_idx(idx: int) -> void:
	if idx < 0 or idx >= _cmd_suggestions.size():
		return
	var suggestion = _cmd_suggestions[idx]
	var needs_arg = suggestion in ["unlock_tower", "unlock_level", "master_lesson", "set_stars", "set_ram", "set_volume", "set_music", "goto"]
	_cmd_input.text = suggestion + (" " if needs_arg else "")
	_cmd_input.caret_column = _cmd_input.text.length()
	_clear_suggestions()
	_cmd_input.grab_focus()

func _clear_suggestions() -> void:
	_cmd_suggestions.clear()
	_cmd_suggestion_idx = -1
	if _cmd_suggestions_bar:
		_cmd_suggestions_bar.visible = false
		for child in _cmd_suggestions_bar.get_children():
			child.queue_free()

# ─── COMMAND EXECUTION ─────────────────────────────────
func _execute_command(cmd: String) -> void:
	var parts = cmd.split(" ", false)
	var command = parts[0].to_lower()
	var args: Array = []
	for i in range(1, parts.size()):
		args.append(parts[i])

	match command:
		"help":
			_cmd_help()
		"unlock_tower":
			_cmd_unlock_tower(args)
		"unlock_all_towers":
			_cmd_unlock_all_towers()
		"unlock_level":
			_cmd_unlock_level(args)
		"unlock_all_levels":
			_cmd_unlock_all_levels()
		"unlock_all":
			_cmd_unlock_all()
		"list_towers":
			_cmd_list_towers()
		"list_levels":
			_cmd_list_levels()
		"status":
			_cmd_status()
		"reset_progress":
			_cmd_reset_progress()
		"clear":
			_cmd_clear()
		"god_mode":
			_cmd_god_mode()
		"set_ram":
			_cmd_set_ram(args)
		"kill_all":
			_cmd_kill_all()
		"skip_wave":
			_cmd_skip_wave()
		"master_lesson":
			_cmd_master_lesson(args)
		"master_all":
			_cmd_master_all()
		"set_stars":
			_cmd_set_stars(args)
		"set_volume":
			_cmd_set_volume(args)
		"set_music":
			_cmd_set_music(args)
		"goto":
			_cmd_goto(args)
		"reset_tutorials":
			_cmd_reset_tutorials()
		"save":
			_cmd_save()
		"fps":
			_cmd_fps()
		_:
			_print_cmd_output("[color=#FF3366]Unknown command: '" + command + "'. Type [color=#FFB800]help[/color] to see available commands.[/color]")

# ─── COMMANDS ──────────────────────────────────────────
func _cmd_help() -> void:
	_print_cmd_output("")
	_print_cmd_output("[color=#FFB800]═══ AVAILABLE COMMANDS ═══[/color]")
	_print_cmd_output("")
	_print_cmd_output("[color=#00D4FF]help[/color]                     — Show this list")
	_print_cmd_output("[color=#00D4FF]list_towers[/color]              — List all tower IDs")
	_print_cmd_output("[color=#00D4FF]list_levels[/color]              — List all level numbers")
	_print_cmd_output("[color=#00D4FF]status[/color]                   — Show current progress")
	_print_cmd_output("[color=#00D4FF]clear[/color]                   — Clear the output")
	_print_cmd_output("")
	_print_cmd_output("[color=#FFB800]── UNLOCK COMMANDS ──[/color]")
	_print_cmd_output("[color=#00D4FF]unlock_tower[/color] [id]        — Unlock a specific tower")
	_print_cmd_output("  [color=#4A7FA5]Example: unlock_tower tower_array[/color]")
	_print_cmd_output("[color=#00D4FF]unlock_all_towers[/color]         — Unlock every tower")
	_print_cmd_output("[color=#00D4FF]unlock_level[/color] [number]     — Unlock a specific level")
	_print_cmd_output("  [color=#4A7FA5]Example: unlock_level 5[/color]")
	_print_cmd_output("[color=#00D4FF]unlock_all_levels[/color]         — Unlock every level")
	_print_cmd_output("[color=#00D4FF]unlock_all[/color]               — Unlock everything")
	_print_cmd_output("")
	_print_cmd_output("[color=#FFB800]── LESSON / PROGRESS ──[/color]")
	_print_cmd_output("[color=#00D4FF]master_lesson[/color] [id]        — Master a specific lesson")
	_print_cmd_output("  [color=#4A7FA5]Example: master_lesson ds_arrays[/color]")
	_print_cmd_output("[color=#00D4FF]master_all[/color]               — Master all lessons")
	_print_cmd_output("[color=#00D4FF]set_stars[/color] [level] [0-3]   — Set star rating")
	_print_cmd_output("  [color=#4A7FA5]Example: set_stars 3 2[/color]")
	_print_cmd_output("[color=#00D4FF]reset_progress[/color]           — Reset all save data")
	_print_cmd_output("")
	_print_cmd_output("[color=#FFB800]── GAMEPLAY (in-level only) ──[/color]")
	_print_cmd_output("[color=#00D4FF]god_mode[/color]                 — Toggle infinite RAM")
	_print_cmd_output("[color=#00D4FF]set_ram[/color] [amount]         — Set RAM to a value")
	_print_cmd_output("[color=#00D4FF]kill_all[/color]                 — Kill all enemies on screen")
	_print_cmd_output("[color=#00D4FF]skip_wave[/color]                — Skip the current wave")
	_print_cmd_output("")
	_print_cmd_output("[color=#FFB800]── AUDIO / UI ──[/color]")
	_print_cmd_output("[color=#00D4FF]set_volume[/color] [0-100]       — Set effects volume")
	_print_cmd_output("[color=#00D4FF]set_music[/color] [0-100]        — Set music volume")
	_print_cmd_output("[color=#00D4FF]goto[/color] [scene]             — Navigate to a scene")
	_print_cmd_output("  [color=#4A7FA5]Scenes: campaign, academy, main_menu, settings, index[/color]")
	_print_cmd_output("[color=#00D4FF]fps[/color]                      — Toggle FPS counter")
	_print_cmd_output("[color=#00D4FF]save[/color]                     — Force save progress")
	_print_cmd_output("[color=#00D4FF]reset_tutorials[/color]          — Reset all tutorial popups")
	_print_cmd_output("")

func _cmd_unlock_tower(args: Array) -> void:
	if args.size() < 1:
		_print_cmd_output("[color=#FFB800]Usage:[/color] unlock_tower <tower_id>")
		_print_cmd_output("[color=#4A7FA5]Type 'list_towers' to see all available IDs.[/color]")
		return
	var tower_id: String = str(args[0])
	if not GameManager.TOWER_DEFINITIONS.has(tower_id):
		_print_cmd_output("[color=#FF3366]Invalid tower ID: '" + tower_id + "'[/color]")
		_print_cmd_output("[color=#4A7FA5]Type 'list_towers' to see all available IDs.[/color]")
		return
	if ProgressManager.is_tower_unlocked(tower_id):
		_print_cmd_output("[color=#FFB800]" + tower_id + "[/color] is already unlocked.")
		return
	ProgressManager.unlock_tower(tower_id)
	SignalBus.tower_unlocked.emit(tower_id)
	var tower_name = GameManager.TOWER_DEFINITIONS[tower_id].get("tower_name", tower_id)
	_print_cmd_output("[color=#00FF88]Unlocked tower:[/color] " + tower_name + " (" + tower_id + ")")

func _cmd_unlock_all_towers() -> void:
	var unlocked = ProgressManager.unlock_all_towers()
	if unlocked.size() == 0:
		_print_cmd_output("[color=#FFB800]All towers are already unlocked.[/color]")
		return
	for tower_id in unlocked:
		SignalBus.tower_unlocked.emit(tower_id)
	_print_cmd_output("[color=#00FF88]Unlocked " + str(unlocked.size()) + " tower(s):[/color]")
	for tower_id in unlocked:
		var tower_name = GameManager.TOWER_DEFINITIONS.get(tower_id, {}).get("tower_name", tower_id)
		_print_cmd_output("  • " + tower_name + " (" + tower_id + ")")

func _cmd_unlock_level(args: Array) -> void:
	if args.size() < 1:
		_print_cmd_output("[color=#FFB800]Usage:[/color] unlock_level <number>")
		return
	var level_num = int(str(args[0])) if str(args[0]).is_valid_int() else -1
	if level_num < 1 or level_num > DataRegistry.get_level_count():
		_print_cmd_output("[color=#FF3366]Invalid level number: " + str(args[0]) + "[/color]")
		return
	if ProgressManager.is_level_unlocked(level_num):
		_print_cmd_output("[color=#FFB800]Level " + str(level_num) + "[/color] is already unlocked.")
		return
	ProgressManager.unlock_campaign_level(level_num)
	_print_cmd_output("[color=#00FF88]Unlocked level " + str(level_num) + ".[/color]")

func _cmd_unlock_all_levels() -> void:
	var unlocked = ProgressManager.unlock_all_levels()
	if unlocked.size() == 0:
		_print_cmd_output("[color=#FFB800]All levels are already unlocked.[/color]")
		return
	_print_cmd_output("[color=#00FF88]Unlocked " + str(unlocked.size()) + " level(s):[/color]")
	for num in unlocked:
		var ld = DataRegistry.get_level(num)
		var lname = ld.level_name if ld else "Level " + str(num)
		_print_cmd_output("  • " + lname + " (Level " + str(num) + ")")

func _cmd_unlock_all() -> void:
	var result = ProgressManager.unlock_everything()
	var tower_count = result.get("towers", []).size()
	var level_count = result.get("levels", []).size()
	_print_cmd_output("[color=#00FF88]Everything unlocked![/color]")
	_print_cmd_output("  Towers: " + str(tower_count) + " newly unlocked")
	_print_cmd_output("  Levels: " + str(level_count) + " newly unlocked")
	_print_cmd_output("  Lessons: all unlocked")
	for tower_id in result.get("towers", []):
		SignalBus.tower_unlocked.emit(tower_id)

func _cmd_list_towers() -> void:
	_print_cmd_output("")
	_print_cmd_output("[color=#FFB800]═══ TOWERS ═══[/color]")
	var ids = DataRegistry.get_tower_ids_ordered()
	for tower_id in ids:
		var unlocked = ProgressManager.is_tower_unlocked(tower_id)
		var status = "[color=#00FF88]UNLOCKED[/color]" if unlocked else "[color=#FF3366]LOCKED[/color]"
		var tower_name = GameManager.TOWER_DEFINITIONS.get(tower_id, {}).get("tower_name", tower_id)
		_print_cmd_output("  " + status + "  " + tower_name + "  [color=#4A7FA5](" + tower_id + ")[/color]")
	_print_cmd_output("")

func _cmd_list_levels() -> void:
	_print_cmd_output("")
	_print_cmd_output("[color=#FFB800]═══ LEVELS ═══[/color]")
	var nums = DataRegistry.get_level_numbers()
	for num in nums:
		var unlocked = ProgressManager.is_level_unlocked(num)
		var status = "[color=#00FF88]UNLOCKED[/color]" if unlocked else "[color=#FF3366]LOCKED[/color]"
		var ld = DataRegistry.get_level(num)
		var lname = ld.level_name if ld else "Level " + str(num)
		_print_cmd_output("  " + status + "  Level " + str(num) + " — " + lname)
	_print_cmd_output("")

func _cmd_status() -> void:
	_print_cmd_output("")
	_print_cmd_output("[color=#FFB800]═══ PROGRESS STATUS ═══[/color]")
	var total_towers = DataRegistry.get_tower_count()
	var unlocked_count = ProgressManager.unlocked_towers.size()
	_print_cmd_output("  Towers:  " + str(unlocked_count) + " / " + str(total_towers) + " unlocked")
	var total_levels = DataRegistry.get_level_count()
	var max_level = ProgressManager.campaign_progress.get("max_level_unlocked", 0)
	_print_cmd_output("  Levels:  " + str(max_level) + " / " + str(total_levels) + " unlocked")
	var total_lessons = DataRegistry.get_lesson_count()
	var mastered = 0
	for lesson_id in ProgressManager.ALL_LESSONS:
		if ProgressManager.get_topic_state(lesson_id) == "mastered":
			mastered += 1
	_print_cmd_output("  Lessons: " + str(mastered) + " / " + str(total_lessons) + " mastered")
	var waves = ProgressManager.campaign_progress.get("waves_completed", 0)
	_print_cmd_output("  Waves completed: " + str(waves))
	var stars_total = 0
	var star_map = ProgressManager.campaign_progress.get("level_stars", {})
	for key in star_map:
		stars_total += int(star_map[key])
	_print_cmd_output("  Stars: " + str(stars_total) + " / " + str(total_levels * 3))
	_print_cmd_output("")

func _cmd_reset_progress() -> void:
	ProgressManager.reset_all_progress()
	_print_cmd_output("[color=#FF3366]All progress has been reset.[/color]")

func _cmd_clear() -> void:
	if _cmd_output:
		_cmd_output.clear()

# ─── GAMEPLAY COMMANDS ─────────────────────────────────
func _cmd_god_mode() -> void:
	var level = _get_active_level()
	if level == null:
		_print_cmd_output("[color=#FFB800]god_mode[/color] set for next level entry.")
		return
	if level.ram_manager.current_ram >= 99999:
		var cfg = GameManager.LEVEL_CONFIGS.get(level.level_number, {})
		var start_ram = cfg.get("start_ram", 150)
		level.ram_manager.max_ram = start_ram
		level.ram_manager.current_ram = start_ram
		level.ram_manager.ram_changed.emit(level.ram_manager.current_ram, level.ram_manager.max_ram)
		_print_cmd_output("[color=#FF3366]god_mode OFF[/color] — RAM restored to " + str(start_ram))
	else:
		level.ram_manager.current_ram = 99999
		level.ram_manager.max_ram = 99999
		level.ram_manager.ram_changed.emit(level.ram_manager.current_ram, level.ram_manager.max_ram)
		_print_cmd_output("[color=#00FF88]god_mode ON[/color] — Infinite RAM!")

func _cmd_set_ram(args: Array) -> void:
	if args.size() < 1:
		_print_cmd_output("[color=#FFB800]Usage:[/color] set_ram <amount>")
		return
	var level = _get_active_level()
	if level == null:
		_print_cmd_output("[color=#FF3366]Not in a level.[/color] Use during gameplay.")
		return
	var amount = int(str(args[0])) if str(args[0]).is_valid_int() else -1
	if amount < 0:
		_print_cmd_output("[color=#FF3366]Invalid amount: " + str(args[0]) + "[/color]")
		return
	level.ram_manager.max_ram = maxi(level.ram_manager.max_ram, amount)
	level.ram_manager.current_ram = amount
	level.ram_manager.ram_changed.emit(level.ram_manager.current_ram, level.ram_manager.max_ram)
	_print_cmd_output("[color=#00FF88]RAM set to " + str(amount) + "[/color]")

func _cmd_kill_all() -> void:
	var level = _get_active_level()
	if level == null:
		_print_cmd_output("[color=#FF3366]Not in a level.[/color] Use during gameplay.")
		return
	var count = 0
	for child in level.enemy_layer.get_children():
		if child is Enemy and not child.is_dead:
			child.current_health = 0
			child._die()
			count += 1
	_print_cmd_output("[color=#00FF88]Killed " + str(count) + " enemy(s).[/color]")

func _cmd_skip_wave() -> void:
	var level = _get_active_level()
	if level == null:
		_print_cmd_output("[color=#FF3366]Not in a level.[/color] Use during gameplay.")
		return
	if level.wave_manager.wave_in_progress:
		_print_cmd_output("[color=#FFB800]Wave already in progress.[/color]")
		return
	if level.wave_manager.level_completed:
		_print_cmd_output("[color=#FFB800]Level already completed.[/color]")
		return
	if level.wave_manager.current_wave >= level.wave_manager.total_waves:
		_print_cmd_output("[color=#FFB800]All waves already done.[/color]")
		return
	level.wave_countdown = 0.0
	level.countdown_active = false
	level._trigger_wave_start()
	_print_cmd_output("[color=#00FF88]Wave skipped![/color]")

# ─── LESSON / PROGRESS COMMANDS ────────────────────────
func _cmd_master_lesson(args: Array) -> void:
	if args.size() < 1:
		_print_cmd_output("[color=#FFB800]Usage:[/color] master_lesson <lesson_id>")
		return
	var lesson_id = str(args[0])
	if lesson_id not in ProgressManager.ALL_LESSONS:
		_print_cmd_output("[color=#FF3366]Invalid lesson ID: '" + lesson_id + "'[/color]")
		return
	ProgressManager.master_lesson(lesson_id)
	_print_cmd_output("[color=#00FF88]Mastered:[/color] " + lesson_id)

func _cmd_master_all() -> void:
	var mastered = ProgressManager.master_all_lessons()
	if mastered.size() == 0:
		_print_cmd_output("[color=#FFB800]All lessons already mastered.[/color]")
		return
	_print_cmd_output("[color=#00FF88]Mastered " + str(mastered.size()) + " lesson(s):[/color]")
	for lid in mastered:
		_print_cmd_output("  • " + lid)

func _cmd_set_stars(args: Array) -> void:
	if args.size() < 2:
		_print_cmd_output("[color=#FFB800]Usage:[/color] set_stars <level> <0-3>")
		return
	var level_num = int(str(args[0])) if str(args[0]).is_valid_int() else -1
	var stars = int(str(args[1])) if str(args[1]).is_valid_int() else -1
	if level_num < 1 or level_num > DataRegistry.get_level_count():
		_print_cmd_output("[color=#FF3366]Invalid level: " + str(args[0]) + "[/color]")
		return
	if stars < 0 or stars > 3:
		_print_cmd_output("[color=#FF3366]Stars must be 0-3.[/color]")
		return
	ProgressManager.set_level_stars(level_num, stars)
	_print_cmd_output("[color=#00FF88]Level " + str(level_num) + " set to " + str(stars) + " star(s).[/color]")

# ─── AUDIO / UI COMMANDS ───────────────────────────────
func _cmd_set_volume(args: Array) -> void:
	if args.size() < 1:
		_print_cmd_output("[color=#FFB800]Usage:[/color] set_volume <0-100>")
		return
	var val = float(str(args[0])) if str(args[0]).is_valid_float() else -1.0
	if val < 0.0 or val > 100.0:
		_print_cmd_output("[color=#FF3366]Must be 0-100.[/color]")
		return
	SoundManager.set_effects_volume(val / 100.0)
	_print_cmd_output("[color=#00FF88]Effects volume: " + str(int(val)) + "%[/color]")

func _cmd_set_music(args: Array) -> void:
	if args.size() < 1:
		_print_cmd_output("[color=#FFB800]Usage:[/color] set_music <0-100>")
		return
	var val = float(str(args[0])) if str(args[0]).is_valid_float() else -1.0
	if val < 0.0 or val > 100.0:
		_print_cmd_output("[color=#FF3366]Must be 0-100.[/color]")
		return
	SoundManager.set_music_volume(val / 100.0)
	_print_cmd_output("[color=#00FF88]Music volume: " + str(int(val)) + "%[/color]")

func _cmd_goto(args: Array) -> void:
	if args.size() < 1:
		_print_cmd_output("[color=#FFB800]Usage:[/color] goto <scene>")
		_print_cmd_output("[color=#4A7FA5]campaign, academy, main_menu, settings, index[/color]")
		return
	var scene_key = str(args[0]).to_lower()
	if not GameManager.SCENES.has(scene_key):
		_print_cmd_output("[color=#FF3366]Unknown scene: '" + scene_key + "'[/color]")
		return
	queue_free()
	Engine.time_scale = 1.0
	GameManager.go_to(scene_key)

func _cmd_reset_tutorials() -> void:
	ProgressManager.tutorials_seen.clear()
	ProgressManager.save_progress()
	_print_cmd_output("[color=#00FF88]All tutorials reset.[/color]")

func _cmd_save() -> void:
	ProgressManager.save_progress()
	_print_cmd_output("[color=#00FF88]Progress saved.[/color]")

func _cmd_fps() -> void:
	var existing = get_tree().root.get_node_or_null("FPSCounter")
	if existing:
		existing.queue_free()
		_print_cmd_output("[color=#FF3366]FPS counter: OFF[/color]")
		return
	var label := Label.new()
	label.name = "FPSCounter"
	label.text = "FPS: 0"
	label.z_index = 9999
	label.offset_left = 10
	label.offset_top = 10
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("#00FF88"))
	get_tree().root.add_child(label)
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.timeout.connect(func():
		if is_instance_valid(label):
			label.text = "FPS: " + str(Engine.get_frames_per_second())
	)
	get_tree().root.add_child(timer)
	_print_cmd_output("[color=#00FF88]FPS counter: ON[/color]")

# ─── HELPERS ───────────────────────────────────────────
func _get_active_level():
	if GameManager.active_level and is_instance_valid(GameManager.active_level):
		return GameManager.active_level
	return null

func _print_cmd_output(bbcode: String) -> void:
	if _cmd_output:
		_cmd_output.append_text(bbcode + "\n")
		call_deferred("_scroll_output_to_end")

func _scroll_output_to_end() -> void:
	if not _cmd_output_scroll or not _cmd_output:
		return
	var max_scroll := maxf(0.0, _cmd_output.get_content_height() - _cmd_output_scroll.size.y)
	var tween := create_tween()
	tween.tween_property(_cmd_output_scroll, "scroll_vertical", max_scroll, 0.18)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
