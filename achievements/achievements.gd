extends Control

const ACHIEVEMENTS_PATH = "user://achievements.cfg"
const BG_FOLDER = "res://backgrounds/"

const ACHIEVEMENTS = [
	{"id": "win_1", "title": "First Victory", "desc": "Win 1 game", "wins_needed": 1, "reward": "img25.jpg"},
	{"id": "win_3", "title": "Getting Started", "desc": "Win 3 games", "wins_needed": 3, "reward": "img26.jpg"},
	{"id": "win_5", "title": "On a Roll", "desc": "Win 5 games", "wins_needed": 5, "reward": "img27.jpg"},
	{"id": "win_8", "title": "Skilled Player", "desc": "Win 8 games", "wins_needed": 8, "reward": "img28.jpg"},
	{"id": "win_12", "title": "Experienced", "desc": "Win 12 games", "wins_needed": 12, "reward": "img29.jpg"},
	{"id": "win_16", "title": "Veteran", "desc": "Win 16 games", "wins_needed": 16, "reward": "img30.jpg"},
	{"id": "win_20", "title": "Expert", "desc": "Win 20 games", "wins_needed": 20, "reward": "img31.jpg"},
	{"id": "win_25", "title": "Master", "desc": "Win 25 games", "wins_needed": 25, "reward": "img32.jpg"},
	{"id": "win_30", "title": "Champion", "desc": "Win 30 games", "wins_needed": 30, "reward": "img33.jpg"},
	{"id": "win_40", "title": "Legendary", "desc": "Win 40 games", "wins_needed": 40, "reward": "img34.jpg"},
	{"id": "win_50", "title": "Immortal", "desc": "Win 50 games", "wins_needed": 50, "reward": "img35.jpg"},
]

var total_wins := 0

@onready var progress_label : Label = $ProgressLabel
@onready var achievement_list : VBoxContainer = $ScrollContainer/AchievementList

func _ready():
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://main_menu/main_menu.tscn"))
	_load_achievements()
	_populate_list()

func _load_achievements():
	var cfg = ConfigFile.new()
	if cfg.load(ACHIEVEMENTS_PATH) == OK:
		total_wins = cfg.get_value("stats", "total_wins", 0)
	else:
		total_wins = 0

func _count_unlocked() -> int:
	var count := 0
	for ach in ACHIEVEMENTS:
		if total_wins >= ach.wins_needed:
			count += 1
	return count

func _populate_list():
	progress_label.text = "Total Wins: %d / %d achievements unlocked" % [total_wins, _count_unlocked()]

	for ach in ACHIEVEMENTS:
		var is_unlocked = total_wins >= ach.wins_needed
		var row = PanelContainer.new()
		row.custom_minimum_size = Vector2(960, 70)
		achievement_list.add_child(row)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 15)
		row.add_child(hbox)

		var icon_label = Label.new()
		icon_label.text = "✓" if is_unlocked else "○"
		icon_label.add_theme_font_size_override("font_size", 28)
		icon_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3) if is_unlocked else Color(0.4, 0.4, 0.4))
		icon_label.custom_minimum_size = Vector2(40, 0)
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(icon_label)

		var info_box = VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_box)

		var title_lbl = Label.new()
		title_lbl.text = ach.title
		title_lbl.add_theme_font_size_override("font_size", 16)
		title_lbl.add_theme_color_override("font_color", Color.WHITE if is_unlocked else Color(0.5, 0.5, 0.5))
		info_box.add_child(title_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = ach.desc
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6) if is_unlocked else Color(0.4, 0.4, 0.4))
		info_box.add_child(desc_lbl)

		if not is_unlocked:
			var prog_bar = ProgressBar.new()
			prog_bar.custom_minimum_size = Vector2(200, 12)
			prog_bar.max_value = ach.wins_needed
			prog_bar.value = minf(total_wins, ach.wins_needed)
			prog_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_box.add_child(prog_bar)

			var prog_text = Label.new()
			prog_text.text = "%d / %d wins" % [total_wins, ach.wins_needed]
			prog_text.add_theme_font_size_override("font_size", 10)
			prog_text.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			info_box.add_child(prog_text)

		var reward_box = VBoxContainer.new()
		reward_box.custom_minimum_size = Vector2(120, 0)
		reward_box.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(reward_box)

		var reward_title = Label.new()
		reward_title.text = "Reward"
		reward_title.add_theme_font_size_override("font_size", 10)
		reward_title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_box.add_child(reward_title)

		var reward_thumb = TextureRect.new()
		reward_thumb.custom_minimum_size = Vector2(60, 40)
		reward_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		reward_thumb.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		var full_path = BG_FOLDER + ach.reward
		var tex = load(full_path)
		if tex:
			reward_thumb.texture = tex
		else:
			var placeholder = Label.new()
			placeholder.text = ach.reward
			placeholder.add_theme_font_size_override("font_size", 10)
			placeholder.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			reward_box.add_child(placeholder)
		reward_box.add_child(reward_thumb)
