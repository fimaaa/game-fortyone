extends Control

var menu_panel : ColorRect
var options_panel : ColorRect
var settings_panel : ColorRect
var local_mode_panel : ColorRect
var local_mode_overlay : ColorRect

const CARD_ASSET_FOLDER = "res://assets/card/"
const SETTINGS_CONFIG_PATH = "user://settings.cfg"
const GAME_CONFIG_PATH = "user://game_settings.cfg"
const ACHIEVEMENTS_PATH = "user://achievements.cfg"

var cfg_bo := 1
var cfg_joker := false
var cfg_random_suit := false
var cfg_human_count := 1
var cfg_human_delay := 2.0
var cfg_grave_list := true

var cfg_bg_color := Color(0.08, 0.08, 0.12)
var cfg_bg_image := ""
var cfg_card_styles := {"hearts": "default", "diamonds": "default", "spades": "default", "clubs": "default"}
var total_wins := 0
var available_styles : Array = []

var card_style_dialog : ColorRect
var card_style_overlay : ColorRect
var cs_preview_cont : Control
var cs_style_list_cont : Control
var cs_selected_suit := "hearts"

func _ready():
	menu_panel = ColorRect.new()
	menu_panel.position = Vector2(0, 0)
	menu_panel.size = Vector2(1366, 768)
	menu_panel.color = Color(0.08, 0.08, 0.12)
	add_child(menu_panel)

	var title = Label.new()
	title.text = "Four One"
	title.position = Vector2(533, 100)
	title.size = Vector2(300, 60)
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_panel.add_child(title)

	var btn_y = 250.0
	var btn_w = 260.0
	var btn_h = 45.0
	var btn_x = (1366 - btn_w) / 2.0

	var online_btn = Button.new()
	online_btn.text = "Play Online"
	online_btn.position = Vector2(btn_x, btn_y)
	online_btn.size = Vector2(btn_w, btn_h)
	online_btn.disabled = true
	online_btn.tooltip_text = "Coming Soon"
	menu_panel.add_child(online_btn)

	var local_btn = Button.new()
	local_btn.text = "Local Game"
	local_btn.position = Vector2(btn_x, btn_y + 60)
	local_btn.size = Vector2(btn_w, btn_h)
	local_btn.pressed.connect(func(): _show_local_mode())
	menu_panel.add_child(local_btn)

	var opt_btn = Button.new()
	opt_btn.text = "Options"
	opt_btn.position = Vector2(btn_x, btn_y + 120)
	opt_btn.size = Vector2(btn_w, btn_h)
	opt_btn.pressed.connect(func(): options_panel.visible = true)
	menu_panel.add_child(opt_btn)

	var ach_btn = Button.new()
	ach_btn.text = "Achievements"
	ach_btn.position = Vector2(btn_x, btn_y + 180)
	ach_btn.size = Vector2(btn_w, btn_h)
	ach_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://achievements/achievements.tscn"))
	menu_panel.add_child(ach_btn)

	var quit_btn = Button.new()
	quit_btn.text = "Quit"
	quit_btn.position = Vector2(btn_x, btn_y + 240)
	quit_btn.size = Vector2(btn_w, btn_h)
	quit_btn.pressed.connect(func(): get_tree().quit())
	menu_panel.add_child(quit_btn)

	_load_achievements()
	_load_settings()
	_scan_card_styles()
	_create_options_panel()
	_create_settings_panel()
	_create_card_style_dialog()
	_create_local_mode_panel()

	AudioServer.set_bus_volume_db(0, linear_to_db(1.0))

func _scan_card_styles():
	available_styles.clear()
	var dir = DirAccess.open(CARD_ASSET_FOLDER)
	if dir:
		dir.list_dir_begin()
		var dname = dir.get_next()
		while dname != "":
			if dir.current_is_dir() and not dname.begins_with("."):
				available_styles.append(dname)
			dname = dir.get_next()
	available_styles.sort()
	if available_styles.size() == 0:
		available_styles.append("default")

func _create_options_panel():
	var scene = preload("res://ui/options_panel.tscn")
	options_panel = scene.instantiate()
	options_panel.visible = false
	menu_panel.add_child(options_panel)
	options_panel.set_total_wins(total_wins)
	options_panel.set_card_style_summary(_get_card_style_summary())
	options_panel.show_game_buttons(false)
	options_panel.close_pressed.connect(func(): options_panel.visible = false)
	options_panel.bg_color_changed.connect(func(color):
		cfg_bg_color = color
		cfg_bg_image = ""
		_save_settings()
	)
	options_panel.bg_image_changed.connect(func(path):
		cfg_bg_color = Color.BLACK
		cfg_bg_image = path
		_save_settings()
	)
	options_panel.card_style_pressed.connect(func(): _open_card_style_dialog())

func _create_card_style_dialog():
	card_style_overlay = ColorRect.new()
	card_style_overlay.position = Vector2(0, 0)
	card_style_overlay.size = Vector2(1366, 768)
	card_style_overlay.color = Color(0, 0, 0, 0.7)
	card_style_overlay.visible = false
	card_style_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	card_style_overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			_close_card_style_dialog()
	)
	menu_panel.add_child(card_style_overlay)

	card_style_dialog = ColorRect.new()
	card_style_dialog.position = Vector2(1366 / 2 - 220, 768 / 2 - 260)
	card_style_dialog.size = Vector2(440, 520)
	card_style_dialog.color = Color(0.12, 0.12, 0.18)
	card_style_dialog.visible = false
	menu_panel.add_child(card_style_dialog)

	var dlg_title = Label.new()
	dlg_title.text = "Card Style"
	dlg_title.position = Vector2(150, 10)
	dlg_title.size = Vector2(140, 30)
	dlg_title.add_theme_font_size_override("font_size", 18)
	card_style_dialog.add_child(dlg_title)

	var close_x = Button.new()
	close_x.text = "X"
	close_x.position = Vector2(410, 5)
	close_x.size = Vector2(25, 25)
	close_x.pressed.connect(func(): _close_card_style_dialog())
	card_style_dialog.add_child(close_x)

	var suit_y = 50.0
	var suit_names = ["hearts", "diamonds", "spades", "clubs"]
	var suit_labels_text = ["Hearts", "Diamonds", "Spades", "Clubs"]
	var suit_btns = []
	for i in range(4):
		var sb = Button.new()
		sb.text = suit_labels_text[i]
		sb.position = Vector2(20 + i * 105, suit_y)
		sb.size = Vector2(95, 30)
		sb.toggle_mode = true
		var captured_suit = suit_names[i]
		sb.pressed.connect(func():
			cs_selected_suit = captured_suit
			_update_cs_dialog()
			for other in suit_btns:
				other.button_pressed = (other == sb)
		)
		card_style_dialog.add_child(sb)
		suit_btns.append(sb)

	var preview_label = Label.new()
	preview_label.text = "Preview (K Q J A):"
	preview_label.position = Vector2(20, 95)
	preview_label.size = Vector2(200, 25)
	preview_label.add_theme_font_size_override("font_size", 12)
	card_style_dialog.add_child(preview_label)

	cs_preview_cont = Control.new()
	cs_preview_cont.position = Vector2(20, 120)
	cs_preview_cont.size = Vector2(400, 120)
	card_style_dialog.add_child(cs_preview_cont)

	var style_label = Label.new()
	style_label.text = "Available Styles:"
	style_label.position = Vector2(20, 255)
	style_label.size = Vector2(200, 25)
	style_label.add_theme_font_size_override("font_size", 12)
	card_style_dialog.add_child(style_label)

	cs_style_list_cont = Control.new()
	cs_style_list_cont.position = Vector2(20, 280)
	cs_style_list_cont.size = Vector2(400, 200)
	card_style_dialog.add_child(cs_style_list_cont)

	suit_btns[0].button_pressed = true
	_update_cs_dialog()

func _open_card_style_dialog():
	_scan_card_styles()
	_update_cs_dialog()
	card_style_overlay.visible = true
	card_style_dialog.visible = true

func _close_card_style_dialog():
	card_style_overlay.visible = false
	card_style_dialog.visible = false

func _update_cs_dialog():
	for ch in cs_preview_cont.get_children():
		ch.queue_free()
	for ch in cs_style_list_cont.get_children():
		ch.queue_free()

	var style_name = cfg_card_styles.get(cs_selected_suit, "default")
	var preview_ranks = ["K", "Q", "J", "A"]
	var px := 0.0
	for rank in preview_ranks:
		var fname = "card_%s_%s.png" % [cs_selected_suit, rank]
		var full_path = CARD_ASSET_FOLDER + style_name + "/" + fname
		var tex = load(full_path)
		var preview_btn = Button.new()
		preview_btn.position = Vector2(px, 0)
		preview_btn.size = Vector2(88, 122)
		preview_btn.expand_icon = true
		if tex:
			preview_btn.icon = tex
		else:
			preview_btn.text = rank
		preview_btn.tooltip_text = fname
		cs_preview_cont.add_child(preview_btn)
		px += 100.0

	var sy := 0.0
	for sn in available_styles:
		var is_current = (sn == style_name)
		var sbtn = Button.new()
		sbtn.text = sn.capitalize()
		sbtn.position = Vector2(0, sy)
		sbtn.size = Vector2(380, 30)
		if is_current:
			sbtn.text += "  [Current]"
			sbtn.disabled = true
		var captured_style = sn
		sbtn.pressed.connect(func():
			cfg_card_styles[cs_selected_suit] = captured_style
			_save_settings()
			_update_cs_dialog()
		)
		cs_style_list_cont.add_child(sbtn)
		sy += 35.0

func _create_local_mode_panel():
	local_mode_overlay = ColorRect.new()
	local_mode_overlay.position = Vector2(0, 0)
	local_mode_overlay.size = Vector2(1366, 768)
	local_mode_overlay.color = Color(0, 0, 0, 0.7)
	local_mode_overlay.visible = false
	local_mode_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	local_mode_overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			local_mode_panel.visible = false
			local_mode_overlay.visible = false
	)
	menu_panel.add_child(local_mode_overlay)

	local_mode_panel = ColorRect.new()
	local_mode_panel.position = Vector2(1366 / 2 - 160, 768 / 2 - 100)
	local_mode_panel.size = Vector2(320, 200)
	local_mode_panel.color = Color(0.12, 0.12, 0.18)
	local_mode_panel.visible = false
	menu_panel.add_child(local_mode_panel)

	var title = Label.new()
	title.text = "Local Game"
	title.position = Vector2(80, 10)
	title.size = Vector2(160, 30)
	title.add_theme_font_size_override("font_size", 20)
	local_mode_panel.add_child(title)

	var close_x = Button.new()
	close_x.text = "X"
	close_x.position = Vector2(290, 5)
	close_x.size = Vector2(25, 25)
	close_x.pressed.connect(func():
		local_mode_panel.visible = false
		local_mode_overlay.visible = false
	)
	local_mode_panel.add_child(close_x)

	var normal_btn = Button.new()
	normal_btn.text = "Normal"
	normal_btn.position = Vector2(60, 60)
	normal_btn.size = Vector2(200, 40)
	normal_btn.pressed.connect(func():
		local_mode_panel.visible = false
		local_mode_overlay.visible = false
		_show_settings()
	)
	local_mode_panel.add_child(normal_btn)

	var extra_btn = Button.new()
	extra_btn.text = "Extra"
	extra_btn.position = Vector2(60, 115)
	extra_btn.size = Vector2(200, 40)
	extra_btn.disabled = true
	extra_btn.tooltip_text = "Coming Soon"
	local_mode_panel.add_child(extra_btn)

func _show_local_mode():
	local_mode_panel.visible = true
	local_mode_overlay.visible = true

func _show_settings():
	cfg_bo = 1
	cfg_joker = false
	cfg_random_suit = false
	cfg_human_count = 1
	cfg_human_delay = 2.0
	cfg_grave_list = true
	settings_panel.visible = true

func _create_settings_panel():
	var overlay = ColorRect.new()
	overlay.position = Vector2(0, 0)
	overlay.size = Vector2(1366, 768)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			settings_panel.visible = false
			overlay.visible = false
	)
	menu_panel.add_child(overlay)

	settings_panel = ColorRect.new()
	settings_panel.position = Vector2(1366 / 2 - 200, 768 / 2 - 250)
	settings_panel.size = Vector2(400, 500)
	settings_panel.color = Color(0.12, 0.12, 0.18)
	settings_panel.visible = false
	menu_panel.add_child(settings_panel)

	var overlay_ref = overlay

	var title = Label.new()
	title.text = "Game Settings"
	title.position = Vector2(120, 10)
	title.size = Vector2(160, 30)
	title.add_theme_font_size_override("font_size", 20)
	settings_panel.add_child(title)

	var close_x = Button.new()
	close_x.text = "X"
	close_x.position = Vector2(370, 5)
	close_x.size = Vector2(25, 25)
	close_x.pressed.connect(func():
		settings_panel.visible = false
		overlay_ref.visible = false
	)
	settings_panel.add_child(close_x)

	var y = 50.0

	var bo_label = Label.new()
	bo_label.text = "Best Of:"
	bo_label.position = Vector2(20, y)
	bo_label.size = Vector2(120, 30)
	bo_label.add_theme_font_size_override("font_size", 14)
	settings_panel.add_child(bo_label)

	var bo_opt = OptionButton.new()
	bo_opt.position = Vector2(200, y)
	bo_opt.size = Vector2(160, 30)
	bo_opt.add_item("BO1 (1 round)")
	bo_opt.add_item("BO3 (best of 3)")
	bo_opt.add_item("BO5 (best of 5)")
	bo_opt.selected = 0
	bo_opt.item_selected.connect(func(idx): cfg_bo = [1, 3, 5][idx])
	settings_panel.add_child(bo_opt)
	y += 45

	var joker_label = Label.new()
	joker_label.text = "Normal Joker:"
	joker_label.position = Vector2(20, y)
	joker_label.size = Vector2(120, 30)
	joker_label.add_theme_font_size_override("font_size", 14)
	settings_panel.add_child(joker_label)

	var joker_hint = Label.new()
	joker_hint.text = "(adds 4 joker cards to deck)"
	joker_hint.position = Vector2(200, y)
	joker_hint.size = Vector2(160, 30)
	joker_hint.add_theme_font_size_override("font_size", 11)
	joker_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	settings_panel.add_child(joker_hint)
	y += 25

	var joker_btn = Button.new()
	joker_btn.text = "OFF"
	joker_btn.position = Vector2(200, y)
	joker_btn.size = Vector2(80, 28)
	joker_btn.toggle_mode = true
	joker_btn.button_pressed = false
	joker_btn.pressed.connect(func():
		cfg_joker = joker_btn.button_pressed
		joker_btn.text = "ON" if cfg_joker else "OFF"
	)
	settings_panel.add_child(joker_btn)
	y += 50

	var suit_label = Label.new()
	suit_label.text = "Random Suit:"
	suit_label.position = Vector2(20, y)
	suit_label.size = Vector2(120, 30)
	suit_label.add_theme_font_size_override("font_size", 14)
	settings_panel.add_child(suit_label)

	var suit_hint = Label.new()
	suit_hint.text = "(each round random suit assigned)"
	suit_hint.position = Vector2(200, y)
	suit_hint.size = Vector2(180, 30)
	suit_hint.add_theme_font_size_override("font_size", 11)
	suit_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	settings_panel.add_child(suit_hint)
	y += 25

	var suit_btn = Button.new()
	suit_btn.text = "OFF"
	suit_btn.position = Vector2(200, y)
	suit_btn.size = Vector2(80, 28)
	suit_btn.toggle_mode = true
	suit_btn.button_pressed = false
	suit_btn.pressed.connect(func():
		cfg_random_suit = suit_btn.button_pressed
		suit_btn.text = "ON" if cfg_random_suit else "OFF"
	)
	settings_panel.add_child(suit_btn)
	y += 50

	var players_label = Label.new()
	players_label.text = "Human Players:"
	players_label.position = Vector2(20, y)
	players_label.size = Vector2(120, 30)
	players_label.add_theme_font_size_override("font_size", 14)
	settings_panel.add_child(players_label)

	var players_opt = OptionButton.new()
	players_opt.position = Vector2(200, y)
	players_opt.size = Vector2(160, 30)
	players_opt.add_item("1 Human + 3 Bots")
	players_opt.add_item("2 Humans + 2 Bots")
	players_opt.add_item("3 Humans + 1 Bot")
	players_opt.add_item("4 Humans")
	players_opt.selected = 0
	players_opt.item_selected.connect(func(idx): cfg_human_count = idx + 1)
	settings_panel.add_child(players_opt)
	y += 50

	var delay_label = Label.new()
	delay_label.text = "Player Delay:"
	delay_label.position = Vector2(20, y)
	delay_label.size = Vector2(120, 30)
	delay_label.add_theme_font_size_override("font_size", 14)
	settings_panel.add_child(delay_label)

	var delay_val_label = Label.new()
	delay_val_label.text = "2.0s"
	delay_val_label.position = Vector2(330, y)
	delay_val_label.size = Vector2(40, 30)
	delay_val_label.add_theme_font_size_override("font_size", 12)
	settings_panel.add_child(delay_val_label)

	var delay_slider = HSlider.new()
	delay_slider.position = Vector2(200, y)
	delay_slider.size = Vector2(130, 30)
	delay_slider.min_value = 1.0
	delay_slider.max_value = 5.0
	delay_slider.value = 2.0
	delay_slider.step = 0.5
	delay_slider.value_changed.connect(func(val):
		cfg_human_delay = val
		delay_val_label.text = "%.1fs" % val
	)
	settings_panel.add_child(delay_slider)
	y += 50

	var grave_label = Label.new()
	grave_label.text = "Show Grave List:"
	grave_label.position = Vector2(20, y)
	grave_label.size = Vector2(120, 30)
	grave_label.add_theme_font_size_override("font_size", 14)
	settings_panel.add_child(grave_label)

	var grave_btn = Button.new()
	grave_btn.text = "ON"
	grave_btn.position = Vector2(200, y)
	grave_btn.size = Vector2(80, 28)
	grave_btn.toggle_mode = true
	grave_btn.button_pressed = true
	grave_btn.pressed.connect(func():
		cfg_grave_list = grave_btn.button_pressed
		grave_btn.text = "ON" if cfg_grave_list else "OFF"
	)
	settings_panel.add_child(grave_btn)
	y += 50

	var sep = HSeparator.new()
	sep.position = Vector2(20, y)
	sep.size = Vector2(360, 2)
	settings_panel.add_child(sep)
	y += 15

	var start_game_btn = Button.new()
	start_game_btn.text = "Start Game"
	start_game_btn.position = Vector2(120, y)
	start_game_btn.size = Vector2(160, 40)
	start_game_btn.pressed.connect(func():
		_save_game_config()
		settings_panel.visible = false
		overlay_ref.visible = false
		get_tree().change_scene_to_file("res://main_scene/main_scene.tscn")
	)
	settings_panel.add_child(start_game_btn)

func _save_game_config():
	var cfg = ConfigFile.new()
	cfg.set_value("game", "best_of", cfg_bo)
	cfg.set_value("game", "joker", cfg_joker)
	cfg.set_value("game", "random_suit", cfg_random_suit)
	cfg.set_value("game", "human_count", cfg_human_count)
	cfg.set_value("game", "human_delay", cfg_human_delay)
	cfg.set_value("game", "grave_list", cfg_grave_list)
	cfg.save(GAME_CONFIG_PATH)

func _save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("background", "color", cfg_bg_color)
	cfg.set_value("background", "image", cfg_bg_image)
	for suit in cfg_card_styles:
		cfg.set_value("card_styles", suit, cfg_card_styles[suit])
	cfg.save(SETTINGS_CONFIG_PATH)

func _load_settings():
	var cfg = ConfigFile.new()
	if cfg.load(SETTINGS_CONFIG_PATH) == OK:
		cfg_bg_color = cfg.get_value("background", "color", Color(0.08, 0.08, 0.12))
		cfg_bg_image = cfg.get_value("background", "image", "")
		for suit in ["hearts", "diamonds", "spades", "clubs"]:
			cfg_card_styles[suit] = cfg.get_value("card_styles", suit, "default")

func _load_achievements():
	var cfg = ConfigFile.new()
	if cfg.load(ACHIEVEMENTS_PATH) == OK:
		total_wins = cfg.get_value("stats", "total_wins", 0)
	else:
		total_wins = 0

func _get_card_style_summary() -> String:
	var styles = []
	for suit in ["hearts", "diamonds", "spades", "clubs"]:
		styles.append(cfg_card_styles.get(suit, "default"))
	if styles[0] == styles[1] and styles[1] == styles[2] and styles[2] == styles[3]:
		return styles[0].capitalize()
	return "%s/%s/%s/%s" % [styles[0].capitalize(), styles[1].capitalize(), styles[2].capitalize(), styles[3].capitalize()]
