# Settings.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var back_btn: Button               = $SafeArea/ContentHost/TopBar/TopBarLayout/BackBtn
@onready var title_label: Label             = $SafeArea/ContentHost/TopBar/TopBarLayout/TitleLabel
@onready var content_area: MarginContainer  = $SafeArea/ContentHost/ContentArea
@onready var general_panel: ScrollContainer = $SafeArea/ContentHost/ContentArea/GeneralPanel
@onready var general_content: VBoxContainer = $SafeArea/ContentHost/ContentArea/GeneralPanel/GeneralContent

# ─── STATE ─────────────────────────────────────────────
var _last_device: String = ""
var _cmd_panel: Control = null
var _cmd_output: RichTextLabel = null
var _cmd_input: LineEdit = null
var _cmd_history: Array[String] = []
var _cmd_history_idx: int = -1
var _cmd_suggestions_bar: HBoxContainer = null
var _cmd_suggestions: Array[String] = []
var _cmd_suggestion_idx: int = -1

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_setup_buttons()
	_apply_styles()
	_build_general()
	_apply_responsive_layout()
	ScreenManager.make_scroll_touch_friendly(general_panel)
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	_maybe_show_tutorial()

# ─── BUTTON SETUP ──────────────────────────────────────
func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	GameManager.go_to("main_menu")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _cmd_panel and is_instance_valid(_cmd_panel):
			_close_command_panel()
			get_viewport().set_input_as_handled()
			return
		GameManager.go_to("main_menu")

# ─── GENERAL TAB ───────────────────────────────────────
func _build_general() -> void:
	for child in general_content.get_children():
		child.queue_free()

	# Compute fluid font sizes once per rebuild
	var vp := get_viewport().get_visible_rect().size
	var min_dim := minf(maxf(vp.x, 320.0), maxf(vp.y, 240.0))
	var section_font := int(clampf(min_dim * 0.022, 16.0, 18.0))
	var label_font   := int(clampf(min_dim * 0.020, 16.0, 20.0))
	var desc_font    := int(clampf(min_dim * 0.015, 16.0, 16.0))
	var value_font   := int(clampf(min_dim * 0.020, 16.0, 20.0))
	var pct_font     := int(clampf(min_dim * 0.020, 16.0, 20.0))
	var card_pad     := int(clampf(min_dim * 0.012, 8.0, 16.0))
	var row_sep      := clampf(min_dim * 0.010, 8.0, 14.0)

	general_content.add_child(_make_section_label("AUDIO", section_font))
	general_content.add_child(
		_make_slider_row(
			"Effects Volume",
			"Adjust sound effects volume",
			SoundManager.get_effects_volume(),
			_on_effects_volume_changed,
			label_font, desc_font, pct_font, card_pad, row_sep
		)
	)
	general_content.add_child(
		_make_slider_row(
			"Music Volume",
			"Adjust background music volume",
			SoundManager.get_music_volume(),
			_on_music_volume_changed,
			label_font, desc_font, pct_font, card_pad, row_sep
		)
	)

	general_content.add_child(_make_divider())
	general_content.add_child(_make_section_label("ABOUT", section_font))
	general_content.add_child(_make_info_row("Version",   "v0.1.0", label_font, value_font, card_pad))
	general_content.add_child(_make_info_row("Engine",    "Godot 4", label_font, value_font, card_pad))
	general_content.add_child(_make_info_row("Backend",   "Supabase", label_font, value_font, card_pad))
	general_content.add_child(_make_info_row("Developer", "Packet Surge Team", label_font, value_font, card_pad))

	general_content.add_child(_make_divider())
	general_content.add_child(_make_section_label("DEBUG", section_font))
	general_content.add_child(_make_command_panel_button(label_font, card_pad, row_sep))

# ─── GENERAL TOGGLE HANDLERS ───────────────────────────
func _on_effects_volume_changed(val: float) -> void:
	SoundManager.set_effects_volume(val)

func _on_music_volume_changed(val: float) -> void:
	SoundManager.set_music_volume(val)

# ─── COMMAND PANEL ──────────────────────────────────────
func _make_command_panel_button(label_font: int, card_pad: int, row_sep: float) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#FF3366")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left    = card_pad
	style.content_margin_right   = card_pad
	style.content_margin_top     = card_pad
	style.content_margin_bottom  = card_pad
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", row_sep)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)

	var lbl := Label.new()
	lbl.text = "Command Panel"
	lbl.add_theme_font_size_override("font_size", label_font)
	lbl.add_theme_color_override("font_color", Color("#FF3366"))
	text_col.add_child(lbl)

	var desc := Label.new()
	desc.text = "Debug commands — unlock towers, levels, and more"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", int(label_font * 0.8))
	desc.add_theme_color_override("font_color", Color("#4A7FA5"))
	text_col.add_child(desc)
	row.add_child(text_col)

	var btn := Button.new()
	btn.text = "OPEN >"
	btn.custom_minimum_size = Vector2(_fs(0.18, 70.0, 100.0), _fs(0.10, 38.0, 48.0))
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color               = Color("#FF3366")
	btn_style.corner_radius_top_left     = 4
	btn_style.corner_radius_top_right    = 4
	btn_style.corner_radius_bottom_left  = 4
	btn_style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_color_override("font_color", Color("#050D1A"))
	btn.add_theme_font_size_override("font_size", label_font)
	btn.pressed.connect(_open_command_panel)
	row.add_child(btn)

	card.add_child(row)
	return card

func _open_command_panel() -> void:
	if _cmd_panel and is_instance_valid(_cmd_panel):
		_cmd_panel.queue_free()
		_cmd_panel = null
		return
	_build_command_panel()
	add_child(_cmd_panel)
	_cmd_input.grab_focus()
	_print_cmd_output("[color=#00D4FF]> Command Panel opened.[/color]")
	_print_cmd_output("[color=#4A7FA5]Type [color=#FFB800]help[/color] to see available commands.[/color]")

func _build_command_panel() -> void:
	var vp := get_viewport().get_visible_rect().size
	var min_dim := minf(maxf(vp.x, 320.0), maxf(vp.y, 240.0))

	_cmd_panel = Control.new()
	_cmd_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cmd_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	# Dimmed background
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	bg.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			_close_command_panel()
	)
	_cmd_panel.add_child(bg)

	# Panel container
	var panel_w := minf(vp.x * 0.9, 700.0)
	var panel_h := minf(vp.y * 0.85, 550.0)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(panel_w, panel_h)
	panel.size = Vector2(panel_w, panel_h)
	panel.position = Vector2((vp.x - panel_w) / 2.0, (vp.y - panel_h) / 2.0)
	panel.z_index = 10

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color               = Color("#0D1B2A")
	panel_style.border_color           = Color("#FF3366")
	panel_style.border_width_left      = 2
	panel_style.border_width_right     = 2
	panel_style.border_width_top       = 2
	panel_style.border_width_bottom    = 2
	panel_style.corner_radius_top_left     = 8
	panel_style.corner_radius_top_right    = 8
	panel_style.corner_radius_bottom_left  = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left    = 16
	panel_style.content_margin_right   = 16
	panel_style.content_margin_top     = 12
	panel_style.content_margin_bottom  = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	_cmd_panel.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10
	)
	panel.add_child(vbox)

	# ── Top bar: title + close ──
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	vbox.add_child(top_row)

	var title := Label.new()
	title.text = "CMD PANEL"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", int(min_dim * 0.028))
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
	close_btn.add_theme_font_size_override("font_size", int(min_dim * 0.022))
	close_btn.pressed.connect(_close_command_panel)
	top_row.add_child(close_btn)

	# ── Divider ──
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color("#1A3A5A"))
	vbox.add_child(sep)

	# ── Output area ──
	_cmd_output = RichTextLabel.new()
	_cmd_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cmd_output.bbcode_enabled = true
	_cmd_output.fit_content = false
	_cmd_output.scroll_following = true
	_cmd_output.selection_enabled = true
	_cmd_output.mouse_filter = Control.MOUSE_FILTER_STOP
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
	_cmd_output.add_theme_stylebox_override("normal", out_style)
	_cmd_output.add_theme_font_size_override("normal_font_size", int(min_dim * 0.018))
	vbox.add_child(_cmd_output)

	# ── Autocomplete suggestion bar ──
	_cmd_suggestions_bar = HBoxContainer.new()
	_cmd_suggestions_bar.add_theme_constant_override("separation", 6)
	_cmd_suggestions_bar.visible = false
	vbox.add_child(_cmd_suggestions_bar)

	# ── Input row ──
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
	_cmd_input.add_theme_font_size_override("font_size", int(min_dim * 0.020))
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
	run_btn.add_theme_font_size_override("font_size", int(min_dim * 0.020))
	run_btn.pressed.connect(func(): _on_cmd_submitted(_cmd_input.text))
	input_row.add_child(run_btn)

func _close_command_panel() -> void:
	if _cmd_panel and is_instance_valid(_cmd_panel):
		_cmd_panel.queue_free()
		_cmd_panel = null
		_cmd_output = null
		_cmd_input = null
		_cmd_suggestions_bar = null

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
	var cmd := text.strip_edges()
	if cmd == "":
		return
	_cmd_history.append(cmd)
	_cmd_history_idx = -1
	_cmd_input.text = ""
	_clear_suggestions()
	_print_cmd_output("[color=#E8F4FD]> " + cmd + "[/color]")
	_execute_command(cmd)

# ─── AUTOCOMPLETE ──────────────────────────────────────
const _ALL_COMMANDS = [
	"help", "list_towers", "list_levels", "status", "clear",
	"unlock_tower", "unlock_all_towers", "unlock_level", "unlock_all_levels", "unlock_all",
	"master_lesson", "master_all", "set_stars", "reset_progress",
	"god_mode", "set_ram", "kill_all", "skip_wave",
	"set_volume", "set_music", "goto", "reset_tutorials", "save", "fps",
]

func _on_cmd_text_changed(new_text: String) -> void:
	_update_suggestions()

func _update_suggestions() -> void:
	_clear_suggestions()
	var typed := _cmd_input.text.strip_edges().to_lower()
	if typed == "":
		return
	# Find matching commands
	_cmd_suggestions.clear()
	for cmd in _ALL_COMMANDS:
		if cmd.begins_with(typed) and cmd != typed:
			_cmd_suggestions.append(cmd)
	if _cmd_suggestions.size() == 0:
		return
	_cmd_suggestion_idx = -1
	_cmd_suggestions_bar.visible = true
	# Build suggestion chips
	var vp := get_viewport().get_visible_rect().size
	var min_dim := minf(maxf(vp.x, 320.0), maxf(vp.y, 240.0))
	var chip_font := int(min_dim * 0.016)
	for i in range(mini(_cmd_suggestions.size(), 6)):
		var suggestion := _cmd_suggestions[i]
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
	# On first Tab, select first suggestion. On subsequent Tabs, cycle.
	_cmd_suggestion_idx += 1
	if _cmd_suggestion_idx >= _cmd_suggestions.size():
		_cmd_suggestion_idx = 0
	_apply_suggestion_idx(_cmd_suggestion_idx)

func _apply_suggestion_idx(idx: int) -> void:
	if idx < 0 or idx >= _cmd_suggestions.size():
		return
	var suggestion := _cmd_suggestions[idx]
	# Check if command takes args — if so, keep a space
	var needs_arg := suggestion in ["unlock_tower", "unlock_level", "master_lesson", "set_stars", "set_ram", "set_volume", "set_music", "goto"]
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

func _execute_command(cmd: String) -> void:
	var parts := cmd.split(" ", false)
	var command := parts[0].to_lower()
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

# ─── COMMAND IMPLEMENTATIONS ────────────────────────────
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
		_print_cmd_output("[color=#4A7FA5]Type 'list_levels' to see all available levels.[/color]")
		return
	var level_num := int(args[0]) if args[0].is_valid_int() else -1
	if level_num < 1 or level_num > DataRegistry.get_level_count():
		_print_cmd_output("[color=#FF3366]Invalid level number: " + str(args[0]) + "[/color]")
		_print_cmd_output("[color=#4A7FA5]Valid range: 1 - " + str(DataRegistry.get_level_count()) + "[/color]")
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

func _print_cmd_output(bbcode: String) -> void:
	if _cmd_output:
		_cmd_output.append_text(bbcode + "\n")

# ─── GOD MODE ──────────────────────────────────────────
var _god_mode: bool = false

func _cmd_god_mode() -> void:
	_god_mode = not _god_mode
	var level = _get_active_level()
	if level == null:
		_print_cmd_output("[color=#FFB800]god_mode[/color] set to [color=#00FF88]" + str(_god_mode) + "[/color] (will apply when you enter a level)")
		return
	if _god_mode:
		level.ram_manager.current_ram = 99999
		level.ram_manager.max_ram = 99999
		level.ram_manager.ram_changed.emit(level.ram_manager.current_ram, level.ram_manager.max_ram)
		_print_cmd_output("[color=#00FF88]god_mode ON[/color] — Infinite RAM activated!")
	else:
		var cfg = GameManager.LEVEL_CONFIGS.get(level.level_number, {})
		var start_ram = cfg.get("start_ram", 150)
		level.ram_manager.max_ram = start_ram
		level.ram_manager.current_ram = start_ram
		level.ram_manager.ram_changed.emit(level.ram_manager.current_ram, level.ram_manager.max_ram)
		_print_cmd_output("[color=#FF3366]god_mode OFF[/color] — RAM restored to " + str(start_ram))

func _cmd_set_ram(args: Array) -> void:
	if args.size() < 1:
		_print_cmd_output("[color=#FFB800]Usage:[/color] set_ram <amount>")
		return
	var level = _get_active_level()
	if level == null:
		_print_cmd_output("[color=#FF3366]Not in a level.[/color] Use this during gameplay.")
		return
	var amount: int = int(str(args[0])) if str(args[0]).is_valid_int() else -1
	if amount < 0:
		_print_cmd_output("[color=#FF3366]Invalid amount: " + str(args[0]) + "[/color]")
		return
	level.ram_manager.current_ram = amount
	level.ram_manager.ram_changed.emit(level.ram_manager.current_ram, level.ram_manager.max_ram)
	_print_cmd_output("[color=#00FF88]RAM set to " + str(amount) + "[/color]")

# ─── KILL ALL ──────────────────────────────────────────
func _cmd_kill_all() -> void:
	var level = _get_active_level()
	if level == null:
		_print_cmd_output("[color=#FF3366]Not in a level.[/color] Use this during gameplay.")
		return
	var count = 0
	for child in level.enemy_layer.get_children():
		if child is Enemy and not child.is_dead:
			child.current_health = 0
			child._die()
			count += 1
	_print_cmd_output("[color=#00FF88]Killed " + str(count) + " enemy(s).[/color]")

# ─── SKIP WAVE ─────────────────────────────────────────
func _cmd_skip_wave() -> void:
	var level = _get_active_level()
	if level == null:
		_print_cmd_output("[color=#FF3366]Not in a level.[/color] Use this during gameplay.")
		return
	if level.wave_manager.wave_in_progress:
		_print_cmd_output("[color=#FFB800]Wave already in progress. Wait for it to finish.[/color]")
		return
	if level.wave_manager.level_completed:
		_print_cmd_output("[color=#FFB800]Level already completed.[/color]")
		return
	if level.wave_manager.current_wave >= level.wave_manager.total_waves:
		_print_cmd_output("[color=#FFB800]All waves already completed.[/color]")
		return
	level.wave_countdown = 0.0
	level.countdown_active = false
	level._trigger_wave_start()
	_print_cmd_output("[color=#00FF88]Wave skipped![/color]")

# ─── MASTER LESSON ─────────────────────────────────────
func _cmd_master_lesson(args: Array) -> void:
	if args.size() < 1:
		_print_cmd_output("[color=#FFB800]Usage:[/color] master_lesson <lesson_id>")
		_print_cmd_output("[color=#4A7FA5]Example: master_lesson ds_arrays[/color]")
		return
	var lesson_id: String = str(args[0])
	if lesson_id not in ProgressManager.ALL_LESSONS:
		_print_cmd_output("[color=#FF3366]Invalid lesson ID: '" + lesson_id + "'[/color]")
		_print_cmd_output("[color=#4A7FA5]Use 'status' to see valid lesson IDs.[/color]")
		return
	ProgressManager.master_lesson(lesson_id)
	_print_cmd_output("[color=#00FF88]Mastered lesson:[/color] " + lesson_id)

func _cmd_master_all() -> void:
	var mastered = ProgressManager.master_all_lessons()
	if mastered.size() == 0:
		_print_cmd_output("[color=#FFB800]All lessons are already mastered.[/color]")
		return
	_print_cmd_output("[color=#00FF88]Mastered " + str(mastered.size()) + " lesson(s):[/color]")
	for lid in mastered:
		_print_cmd_output("  • " + lid)

# ─── SET STARS ─────────────────────────────────────────
func _cmd_set_stars(args: Array) -> void:
	if args.size() < 2:
		_print_cmd_output("[color=#FFB800]Usage:[/color] set_stars <level_number> <0-3>")
		return
	var level_num: int = int(str(args[0])) if str(args[0]).is_valid_int() else -1
	var stars: int = int(str(args[1])) if str(args[1]).is_valid_int() else -1
	if level_num < 1 or level_num > DataRegistry.get_level_count():
		_print_cmd_output("[color=#FF3366]Invalid level number: " + str(args[0]) + "[/color]")
		return
	if stars < 0 or stars > 3:
		_print_cmd_output("[color=#FF3366]Stars must be 0-3.[/color]")
		return
	ProgressManager.set_level_stars(level_num, stars)
	_print_cmd_output("[color=#00FF88]Level " + str(level_num) + " set to " + str(stars) + " star(s).[/color]")

# ─── AUDIO ─────────────────────────────────────────────
func _cmd_set_volume(args: Array) -> void:
	if args.size() < 1:
		_print_cmd_output("[color=#FFB800]Usage:[/color] set_volume <0-100>")
		return
	var val: float = float(str(args[0])) if str(args[0]).is_valid_float() else -1.0
	if val < 0.0 or val > 100.0:
		_print_cmd_output("[color=#FF3366]Volume must be 0-100.[/color]")
		return
	SoundManager.set_effects_volume(val / 100.0)
	_print_cmd_output("[color=#00FF88]Effects volume set to " + str(int(val)) + "%[/color]")

func _cmd_set_music(args: Array) -> void:
	if args.size() < 1:
		_print_cmd_output("[color=#FFB800]Usage:[/color] set_music <0-100>")
		return
	var val: float = float(str(args[0])) if str(args[0]).is_valid_float() else -1.0
	if val < 0.0 or val > 100.0:
		_print_cmd_output("[color=#FF3366]Volume must be 0-100.[/color]")
		return
	SoundManager.set_music_volume(val / 100.0)
	_print_cmd_output("[color=#00FF88]Music volume set to " + str(int(val)) + "%[/color]")

# ─── GOTO ──────────────────────────────────────────────
func _cmd_goto(args: Array) -> void:
	if args.size() < 1:
		_print_cmd_output("[color=#FFB800]Usage:[/color] goto <scene>")
		_print_cmd_output("[color=#4A7FA5]Scenes: campaign, academy, main_menu, settings, index, tower_select, leaderboard, analytics, profile[/color]")
		return
	var scene_key: String = str(args[0]).to_lower()
	if not GameManager.SCENES.has(scene_key):
		_print_cmd_output("[color=#FF3366]Unknown scene: '" + scene_key + "'[/color]")
		_print_cmd_output("[color=#4A7FA5]Available: campaign, academy, main_menu, settings, index, tower_select, leaderboard, analytics, profile[/color]")
		return
	_close_command_panel()
	Engine.time_scale = 1.0
	GameManager.go_to(scene_key)

# ─── RESET TUTORIALS ──────────────────────────────────
func _cmd_reset_tutorials() -> void:
	ProgressManager.tutorials_seen.clear()
	ProgressManager.save_progress()
	_print_cmd_output("[color=#00FF88]All tutorials reset.[/color] They will appear again on next visit.")

# ─── FORCE SAVE ────────────────────────────────────────
func _cmd_save() -> void:
	ProgressManager.save_progress()
	_print_cmd_output("[color=#00FF88]Progress saved.[/color]")

# ─── FPS COUNTER ───────────────────────────────────────
func _cmd_fps() -> void:
	var node = get_tree().root.get_node_or_null("FPSCounter")
	if node:
		node.queue_free()
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
	# Update via process
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.timeout.connect(func():
		if is_instance_valid(label):
			label.text = "FPS: " + str(Engine.get_frames_per_second())
	)
	get_tree().root.add_child(timer)
	_print_cmd_output("[color=#00FF88]FPS counter: ON[/color]")

# ─── HELPER: GET ACTIVE LEVEL ──────────────────────────
func _get_active_level():
	if get_tree().current_scene and get_tree().current_scene.name == "Level":
		return get_tree().current_scene
	return null

# ─── TOGGLE ROW ────────────────────────────────────────
func _make_toggle_row(
		label: String,
		description: String,
		current_value: bool,
		on_toggle: Callable,
		label_font: int,
		desc_font: int,
		card_pad: int,
		row_sep: float) -> PanelContainer:

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#1A3A5A")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left    = card_pad
	style.content_margin_right   = card_pad
	style.content_margin_top     = card_pad
	style.content_margin_bottom  = card_pad
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", row_sep)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", label_font)
	lbl.add_theme_color_override("font_color", Color("#E8F4FD"))
	text_col.add_child(lbl)

	var desc := Label.new()
	desc.text          = description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", desc_font)
	desc.add_theme_color_override("font_color", Color("#4A7FA5"))
	text_col.add_child(desc)
	row.add_child(text_col)

	var toggle := Button.new()
	toggle.custom_minimum_size = Vector2(_fs(0.22, 80.0, 120.0), _fs(0.12, 44.0, 52.0))
	toggle.text = "ON" if current_value else "OFF"
	_style_toggle_button(toggle, current_value, label_font)
	toggle.pressed.connect(_on_toggle_pressed.bind(toggle, on_toggle))
	row.add_child(toggle)

	card.add_child(row)
	return card

func _on_toggle_pressed(toggle: Button, on_toggle: Callable) -> void:
	var new_val = toggle.text == "OFF"
	toggle.text = "ON" if new_val else "OFF"
	_style_toggle_button(toggle, new_val, _fs(0.045, 16.0, 20.0))  # fallback size
	on_toggle.call(new_val)

# ─── SLIDER ROW ────────────────────────────────────────
func _make_slider_row(
		label: String,
		description: String,
		current_value: float,
		on_changed: Callable,
		label_font: int,
		desc_font: int,
		pct_font: int,
		card_pad: int,
		row_sep: float) -> PanelContainer:

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#1A3A5A")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left    = card_pad
	style.content_margin_right   = card_pad
	style.content_margin_top     = card_pad
	style.content_margin_bottom  = card_pad
	card.add_theme_stylebox_override("panel", style)

	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", label_font)
	lbl.add_theme_color_override("font_color", Color("#E8F4FD"))
	row.add_child(lbl)

	var desc := Label.new()
	desc.text          = description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", desc_font)
	desc.add_theme_color_override("font_color", Color("#4A7FA5"))
	row.add_child(desc)

	var slider_box := HBoxContainer.new()
	slider_box.add_theme_constant_override("separation", 12)

	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(_fs(0.22, 80.0, 120.0), 0)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = current_value
	slider.add_theme_color_override("grabber_color", Color("#00D4FF"))
	slider.add_theme_color_override("fill_color", Color("#00D4FF"))
	slider.add_theme_color_override("background_color", Color("#1A3A5A"))
	slider_box.add_child(slider)

	var pct_label := Label.new()
	pct_label.custom_minimum_size = Vector2(_fs(0.14, 44.0, 56.0), 0)
	pct_label.text = str(int(current_value * 100)) + "%"
	pct_label.add_theme_font_size_override("font_size", pct_font)
	pct_label.add_theme_color_override("font_color", Color("#00D4FF"))
	pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slider_box.add_child(pct_label)

	row.add_child(slider_box)
	card.add_child(row)

	slider.value_changed.connect(func(val: float):
		pct_label.text = str(int(val * 100)) + "%"
		on_changed.call(val)
	)

	return card

func _make_info_row(label: String, value: String, label_font: int, value_font: int, card_pad: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#1A3A5A")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left    = card_pad
	style.content_margin_right   = card_pad
	style.content_margin_top     = card_pad
	style.content_margin_bottom  = card_pad
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()

	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(_fs(0.31, 100.0, 140.0), 0)
	lbl.add_theme_font_size_override("font_size", label_font)
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	row.add_child(lbl)

	var val := Label.new()
	val.text = value if value != "" else "—"
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.add_theme_font_size_override("font_size", value_font)
	val.add_theme_color_override("font_color", Color("#E8F4FD"))
	row.add_child(val)

	card.add_child(row)
	return card

# ─── HELPERS ───────────────────────────────────────────
func _make_section_label(text: String, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color("#00D4FF"))
	return lbl

func _make_divider() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color("#1A3A5A"))
	return sep

# ─── STYLES ────────────────────────────────────────────
func _min_dim() -> float:
	var vp := get_viewport().get_visible_rect().size
	return minf(maxf(vp.x, 320.0), maxf(vp.y, 240.0))

func _fs(ratio: float, floor_v: float, cap_v: float) -> int:
	return int(clampf(_min_dim() * ratio, floor_v, cap_v))

func _apply_styles() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color            = Color("#0A1628")
	top_style.border_color        = Color("#00D4FF")
	top_style.border_width_bottom = 1
	$SafeArea/ContentHost/TopBar.add_theme_stylebox_override("panel", top_style)

	var back_style := StyleBoxFlat.new()
	back_style.bg_color               = Color("#0A1628")
	back_style.border_color           = Color("#00D4FF")
	back_style.border_width_left      = 1
	back_style.border_width_right     = 1
	back_style.border_width_top       = 1
	back_style.border_width_bottom    = 1
	back_style.corner_radius_top_left     = 4
	back_style.corner_radius_top_right    = 4
	back_style.corner_radius_bottom_left  = 4
	back_style.corner_radius_bottom_right = 4
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_color_override("font_color", Color("#00D4FF"))
	# font_size set dynamically in _apply_responsive_layout()

func _style_toggle_button(btn: Button, is_on: bool, font_size: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#00D4FF") if is_on else Color("#0A1628")
	style.border_color           = Color("#00D4FF") if is_on else Color("#2A3A4A")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override(
		"font_color",
		Color("#050D1A") if is_on else Color("#4A7FA5")
	)
	btn.add_theme_font_size_override("font_size", font_size)

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	# Read canvas size directly — works under stretch mode for any window/screen
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var w := maxf(vp.x, 320.0)
	var h := maxf(vp.y, 240.0)
	var min_dim := minf(w, h)

	# Continuous typography with readable floors/caps
	title_label.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.035, 20.0, 28.0)))
	back_btn.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.020, 16.0, 20.0)))
	back_btn.custom_minimum_size = Vector2(clampf(w * 0.12, 80.0, 120.0), clampf(h * 0.07, 44.0, 56.0))

	# Content area margins — fluid inset
	var inset := clampf(min_dim * 0.020, 16.0, 28.0)
	content_area.add_theme_constant_override("margin_left", inset)
	content_area.add_theme_constant_override("margin_right", inset)
	content_area.add_theme_constant_override("margin_top", inset)
	content_area.add_theme_constant_override("margin_bottom", inset)

	# Rebuild if device class changed (for widget sizing)
	var current := "mobile" if ScreenManager.is_mobile() else "tablet" if ScreenManager.is_tablet() else "desktop"
	if current != _last_device:
		_last_device = current
		_build_general()

# ─── TUTORIAL ──────────────────────────────────────────
const TutorialOverlay = preload("res://scenes/core/TutorialOverlay.gd")

func _maybe_show_tutorial() -> void:
	if ProgressManager.has_seen_tutorial("settings"):
		return
	await get_tree().process_frame
	var tut = TutorialOverlay.new()
	add_child(tut)
	tut.tutorial_finished.connect(func(): ProgressManager.mark_tutorial_seen("settings"))
	tut.start(_get_settings_tutorial_steps())

func _get_settings_tutorial_steps() -> Array:
	var steps: Array = []
	steps.append({
		"title": "Settings",
		"body": "Tweak audio, configure your account, and learn about the game from here.\n\nLet's take a quick tour.",
		"force_center": true,
	})
	steps.append({
		"title": "Audio Settings",
		"body": "Drag the sliders to adjust effects volume and background music.\nChanges apply instantly.",
		"highlight": general_content.get_path(),
	})
	steps.append({
		"title": "About",
		"body": "Scroll down to see the version info, engine, and developer credits.",
		"highlight": content_area.get_path(),
	})
	steps.append({
		"title": "Back Button",
		"body": "Tap here anytime to return to the main menu.",
		"highlight": back_btn.get_path(),
	})
	steps.append({
		"title": "All Set!",
		"body": "Settings auto-save — no need to confirm. Have fun, operator!",
		"force_center": true,
	})
	return steps
