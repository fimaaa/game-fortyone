extends ColorRect

signal bg_color_changed(color: Color)
signal bg_image_changed(path: String)
signal card_style_pressed()
signal close_pressed()
signal main_menu_pressed()
signal exit_pressed()

const BG_FOLDER = "res://backgrounds/"
const SETTINGS_CONFIG_PATH = "user://settings.cfg"
const BG_UNLOCK_WINS = {
	"img24.jpg": 0, "img25.jpg": 1, "img26.jpg": 3, "img27.jpg": 5,
	"img28.jpg": 8, "img29.jpg": 12, "img30.jpg": 16, "img31.jpg": 20,
	"img32.jpg": 25, "img33.jpg": 30, "img34.jpg": 40, "img35.jpg": 50,
}
const BG_COLORS = {
	"Dark": Color(0.08, 0.08, 0.12), "Green": Color(0.05, 0.15, 0.05),
	"Blue": Color(0.05, 0.05, 0.15), "Red": Color(0.15, 0.05, 0.05),
	"Purple": Color(0.12, 0.05, 0.15), "Brown": Color(0.12, 0.08, 0.05),
	"Teal": Color(0.05, 0.12, 0.12), "White": Color(0.85, 0.85, 0.85),
}
const RESOLUTIONS = [
	Vector2i(1920, 1080), Vector2i(1366, 768),
	Vector2i(1280, 720), Vector2i(1024, 576),
]

@onready var volume_slider : HSlider = $VolumeSlider
@onready var mute_btn : Button = $MuteButton
@onready var res_option : OptionButton = $ResolutionOption
@onready var color_container : GridContainer = $ColorContainer
@onready var img_grid : GridContainer = $ImgGrid
@onready var card_style_label : Label = $CardStyleLabel
@onready var card_style_button : Button = $CardStyleButton
@onready var close_button : Button = $CloseButton
@onready var main_menu_button : Button = $MainMenuButton
@onready var exit_button : Button = $ExitButton

var total_wins := 0

func _ready():
	for r in RESOLUTIONS:
		res_option.add_item("%d x %d" % [r.x, r.y])
	res_option.selected = 1

	volume_slider.value_changed.connect(func(val):
		AudioServer.set_bus_volume_db(0, linear_to_db(val))
	)
	mute_btn.pressed.connect(func():
		AudioServer.set_bus_mute(0, mute_btn.button_pressed)
	)
	res_option.item_selected.connect(func(idx):
		DisplayServer.window_set_size(RESOLUTIONS[idx])
	)
	close_button.pressed.connect(func(): close_pressed.emit())
	card_style_button.pressed.connect(func(): card_style_pressed.emit())
	main_menu_button.pressed.connect(func(): main_menu_pressed.emit())
	exit_button.pressed.connect(func(): exit_pressed.emit())

	_populate_colors()
	_populate_images()
	_load_settings()

func set_total_wins(wins: int):
	total_wins = wins

func set_card_style_summary(text: String):
	card_style_label.text = "Card Style: %s" % text

func show_game_buttons(show: bool):
	main_menu_button.visible = show
	exit_button.visible = show

func set_initial_volume(val: float):
	volume_slider.value = val

func set_initial_mute(val: bool):
	mute_btn.button_pressed = val

func _populate_colors():
	for cname in BG_COLORS:
		var swatch = Button.new()
		swatch.custom_minimum_size = Vector2(28, 28)
		swatch.modulate = BG_COLORS[cname]
		swatch.tooltip_text = cname
		var captured_color = BG_COLORS[cname]
		swatch.pressed.connect(func(): bg_color_changed.emit(captured_color))
		color_container.add_child(swatch)

func _populate_images():
	var dir = DirAccess.open(BG_FOLDER)
	if dir:
		dir.list_dir_begin()
		var fname = dir.get_next()
		while fname != "":
			if not dir.current_is_dir():
				var ext = fname.get_extension().to_lower()
				if ext in ["png", "jpg", "jpeg", "webp"]:
					var is_unlocked = _is_bg_unlocked(fname)
					var thumb = Button.new()
					thumb.custom_minimum_size = Vector2(50, 50)
					thumb.expand_icon = true
					var full_path = BG_FOLDER + fname
					if is_unlocked:
						thumb.tooltip_text = fname
						var tex = load(full_path)
						if tex:
							thumb.icon = tex
					else:
						thumb.tooltip_text = "%s (Win %d+)" % [fname.get_basename(), BG_UNLOCK_WINS.get(fname, 999)]
						thumb.text = "🔒"
						thumb.add_theme_font_size_override("font_size", 20)
						thumb.disabled = true
					var captured_path = full_path
					var captured_unlocked = is_unlocked
					thumb.pressed.connect(func():
						if captured_unlocked:
							bg_image_changed.emit(captured_path)
					)
					img_grid.add_child(thumb)
			fname = dir.get_next()

func _is_bg_unlocked(fname: String) -> bool:
	var needed = BG_UNLOCK_WINS.get(fname, 999)
	return total_wins >= needed

func _load_settings():
	var cfg = ConfigFile.new()
	if cfg.load(SETTINGS_CONFIG_PATH) == OK:
		var vol = cfg.get_value("settings", "volume", 1.0)
		var muted = cfg.get_value("settings", "muted", false)
		volume_slider.value = vol
		AudioServer.set_bus_volume_db(0, linear_to_db(vol))
		mute_btn.button_pressed = muted
		AudioServer.set_bus_mute(0, muted)
