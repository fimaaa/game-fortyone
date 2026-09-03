extends Control

const SAVE_PATH = "user://story_progress.cfg"

const EVENTS = [
	{"titleAge": "01", "date": "1/1", "day": 1, "month": "January", "eventName": "New Year", "eventDesc": "A fresh start.", "eventId": "jan_01", "image": ""},
	{"titleAge": "02", "date": "1/2", "day": 2, "month": "January", "eventName": "First Step", "eventDesc": "The journey begins.", "eventId": "jan_02", "image": ""},
	{"titleAge": "03", "date": "1/3", "day": 3, "month": "January", "eventName": "Cold Morning", "eventDesc": "Winter bites hard.", "eventId": "jan_03", "image": ""},
	{"titleAge": "04", "date": "1/4", "day": 4, "month": "January", "eventName": "Meeting", "eventDesc": "A stranger appears.", "eventId": "jan_04", "image": ""},
	{"titleAge": "05", "date": "1/5", "day": 5, "month": "January", "eventName": "The Card", "eventDesc": "You receive a mysterious card.", "eventId": "jan_05", "image": ""},
	{"titleAge": "06", "date": "1/6", "day": 6, "month": "January", "eventName": "Challenge", "eventDesc": "The rules are explained.", "eventId": "jan_06", "image": ""},
	{"titleAge": "07", "date": "1/7", "day": 7, "month": "January", "eventName": "First Match", "eventDesc": "Your first battle.", "eventId": "jan_07", "image": ""},
	{"titleAge": "08", "date": "1/8", "day": 8, "month": "January", "eventName": "Defeat", "eventDesc": "A harsh lesson.", "eventId": "jan_08", "image": ""},
	{"titleAge": "09", "date": "1/9", "day": 9, "month": "January", "eventName": "Training", "eventDesc": "Practice daily.", "eventId": "jan_09", "image": ""},
	{"titleAge": "10", "date": "1/10", "day": 10, "month": "January", "eventName": "Strategy", "eventDesc": "Learn the meta.", "eventId": "jan_10", "image": ""},
	{"titleAge": "11", "date": "1/11", "day": 11, "month": "January", "eventName": "Rival", "eventDesc": "A worthy opponent.", "eventId": "jan_11", "image": ""},
	{"titleAge": "12", "date": "1/12", "day": 12, "month": "January", "eventName": "Bet", "eventDesc": "Wager everything.", "eventId": "jan_12", "image": ""},
	{"titleAge": "13", "date": "1/13", "day": 13, "month": "January", "eventName": "Win", "eventDesc": "First victory.", "eventId": "jan_13", "image": ""},
	{"titleAge": "14", "date": "1/14", "day": 14, "month": "January", "eventName": "Fame", "eventDesc": "Word spreads.", "eventId": "jan_14", "image": ""},
	{"titleAge": "15", "date": "1/15", "day": 15, "month": "January", "eventName": "Tournament", "eventDesc": "Enter the bracket.", "eventId": "jan_15", "image": ""},
	{"titleAge": "16", "date": "1/16", "day": 16, "month": "January", "eventName": "Round 1", "eventDesc": "Easy start.", "eventId": "jan_16", "image": ""},
	{"titleAge": "17", "date": "1/17", "day": 17, "month": "January", "eventName": "Round 2", "eventDesc": "Gets harder.", "eventId": "jan_17", "image": ""},
	{"titleAge": "18", "date": "1/18", "day": 18, "month": "January", "eventName": "Semifinal", "eventDesc": "Four remain.", "eventId": "jan_18", "image": ""},
	{"titleAge": "19", "date": "1/19", "day": 19, "month": "January", "eventName": "Clash", "eventDesc": "Head to head.", "eventId": "jan_19", "image": ""},
	{"titleAge": "20", "date": "1/20", "day": 20, "month": "January", "eventName": "Final", "eventDesc": "The ultimate match.", "eventId": "jan_20", "image": ""},
	{"titleAge": "21", "date": "1/21", "day": 21, "month": "January", "eventName": "Champion", "eventDesc": "You win it all.", "eventId": "jan_21", "image": ""},
	{"titleAge": "22", "date": "1/22", "day": 22, "month": "January", "eventName": "Celebration", "eventDesc": "Party time.", "eventId": "jan_22", "image": ""},
	{"titleAge": "23", "date": "1/23", "day": 23, "month": "January", "eventName": "New Rival", "eventDesc": "Someone stronger appears.", "eventId": "jan_23", "image": ""},
	{"titleAge": "24", "date": "1/24", "day": 24, "month": "January", "eventName": "Rematch", "eventDesc": "Revenge match.", "eventId": "jan_24", "image": ""},
	{"titleAge": "25", "date": "1/25", "day": 25, "month": "January", "eventName": "Loss", "eventDesc": "Defeated again.", "eventId": "jan_25", "image": ""},
	{"titleAge": "26", "date": "1/26", "day": 26, "month": "January", "eventName": "Training Arc", "eventDesc": "Train harder.", "eventId": "jan_26", "image": ""},
	{"titleAge": "27", "date": "1/27", "day": 27, "month": "January", "eventName": "Team Up", "eventDesc": "Find allies.", "eventId": "jan_27", "image": ""},
	{"titleAge": "28", "date": "1/28", "day": 28, "month": "January", "eventName": "Strategy", "eventDesc": "New plan.", "eventId": "jan_28", "image": ""},
	{"titleAge": "29", "date": "1/29", "day": 29, "month": "January", "eventName": "Rematch 2", "eventDesc": "The grudge match.", "eventId": "jan_29", "image": ""},
	{"titleAge": "30", "date": "1/30", "day": 30, "month": "January", "eventName": "Victory", "eventDesc": "Sweet revenge.", "eventId": "jan_30", "image": ""},
	{"titleAge": "31", "date": "1/31", "day": 31, "month": "January", "eventName": "Rank Up", "eventDesc": "You climb the ranks.", "eventId": "jan_31", "image": ""},
	{"titleAge": "32", "date": "2/1", "day": 1, "month": "February", "eventName": "New Month", "eventDesc": "February begins.", "eventId": "feb_01", "image": ""},
	{"titleAge": "33", "date": "2/2", "day": 2, "month": "February", "eventName": "Snow", "eventDesc": "A quiet day.", "eventId": "feb_02", "image": ""},
	{"titleAge": "34", "date": "2/3", "day": 3, "month": "February", "eventName": "Letter", "eventDesc": "A letter arrives.", "eventId": "feb_03", "image": ""},
	{"titleAge": "35", "date": "2/4", "day": 4, "month": "February", "eventName": "Journey", "eventDesc": "Travel to a new city.", "eventId": "feb_04", "image": ""},
	{"titleAge": "36", "date": "2/5", "day": 5, "month": "February", "eventName": "New Arena", "eventDesc": "A bigger stage.", "eventId": "feb_05", "image": ""},
	{"titleAge": "37", "date": "2/6", "day": 6, "month": "February", "eventName": "Qualifiers", "eventDesc": "Prove yourself.", "eventId": "feb_06", "image": ""},
	{"titleAge": "38", "date": "2/7", "day": 7, "month": "February", "eventName": "Pressure", "eventDesc": "The stakes rise.", "eventId": "feb_07", "image": ""},
	{"titleAge": "39", "date": "2/8", "day": 8, "month": "February", "eventName": "Blunder", "eventDesc": "A costly mistake.", "eventId": "feb_08", "image": ""},
	{"titleAge": "40", "date": "2/9", "day": 9, "month": "February", "eventName": "Recovery", "eventDesc": "Get back up.", "eventId": "feb_09", "image": ""},
	{"titleAge": "41", "date": "2/10", "day": 10, "month": "February", "eventName": "Secret", "eventDesc": "Discover the truth.", "eventId": "feb_10", "image": ""},
	{"titleAge": "42", "date": "2/11", "day": 11, "month": "February", "eventName": "Confrontation", "eventDesc": "Face the enemy.", "eventId": "feb_11", "image": ""},
	{"titleAge": "43", "date": "2/12", "day": 12, "month": "February", "eventName": "Betrayal", "eventDesc": "A friend turns.", "eventId": "feb_12", "image": ""},
	{"titleAge": "44", "date": "2/13", "day": 13, "month": "February", "eventName": "Aftermath", "eventDesc": "Pick up the pieces.", "eventId": "feb_13", "image": ""},
	{"titleAge": "45", "date": "2/14", "day": 14, "month": "February", "eventName": "Valentine", "eventDesc": "A moment of warmth.", "eventId": "feb_14", "image": ""},
	{"titleAge": "46", "date": "2/15", "day": 15, "month": "February", "eventName": "Resolve", "eventDesc": "Steel your will.", "eventId": "feb_15", "image": ""},
	{"titleAge": "47", "date": "2/16", "day": 16, "month": "February", "eventName": "Preparation", "eventDesc": "Get ready.", "eventId": "feb_16", "image": ""},
	{"titleAge": "48", "date": "2/17", "day": 17, "month": "February", "eventName": "Finals", "eventDesc": "The last tournament.", "eventId": "feb_17", "image": ""},
	{"titleAge": "49", "date": "2/18", "day": 18, "month": "February", "eventName": "Clash", "eventDesc": "Everything on the line.", "eventId": "feb_18", "image": ""},
	{"titleAge": "50", "date": "2/19", "day": 19, "month": "February", "eventName": "Climax", "eventDesc": "The final move.", "eventId": "feb_19", "image": ""},
	{"titleAge": "51", "date": "2/20", "day": 20, "month": "February", "eventName": "Winner", "eventDesc": "Champion of champions.", "eventId": "feb_20", "image": ""},
	{"titleAge": "52", "date": "2/21", "day": 21, "month": "February", "eventName": "Reunion", "eventDesc": "Old friends return.", "eventId": "feb_21", "image": ""},
	{"titleAge": "53", "date": "2/22", "day": 22, "month": "February", "eventName": "Legacy", "eventDesc": "Your story lives on.", "eventId": "feb_22", "image": ""},
	{"titleAge": "54", "date": "2/23", "day": 23, "month": "February", "eventName": "Finale", "eventDesc": "The grand finale.", "eventId": "feb_23", "image": ""},
	{"titleAge": "55", "date": "2/24", "day": 24, "month": "February", "eventName": "The End", "eventDesc": "Thank you for playing.", "eventId": "feb_24", "image": ""},
]

func _get_event(index : int) -> Dictionary:
	if index >= 0 and index < EVENTS.size():
		return EVENTS[index]
	return {}

var completed_days : Array = []
var current_index := 0
var animating := false
var strip_base_x := 0.0
var lock_texture : Texture2D

@onready var title_age_label : Label = $TitleLabel/TitleAgeLabel
@onready var event_name_label : Label = $EventNameLabel
@onready var event_desc_label : Label = $EventDescLabel
@onready var bg_texture : TextureRect = $BgTexture
@onready var bg_color : ColorRect = $BgColor
@onready var date_clip : Control = $DateClip
@onready var date_strip : HBoxContainer = $DateClip/DateStrip
@onready var play_button : Button = $PlayButton
@onready var status_icon : TextureRect = $StatusIcon
@onready var status_label : Label = $StatusLabel
@onready var anim_overlay : ColorRect = $AnimOverlay
@onready var anim_day_label : Label = $AnimOverlay/AnimDay
@onready var anim_weekday_label : Label = $AnimOverlay/AnimWeekday
@onready var anim_event_label : Label = $AnimOverlay/AnimEvent

const LOCK_ICON = "res://story/images/lock_icon.svg"

func _ready():
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://main_menu/main_menu.tscn"))
	$NavPrev.pressed.connect(func(): _go_prev())
	$NavNext.pressed.connect(func(): _go_next())
	play_button.pressed.connect(func(): _on_play_pressed())
	_load_progress()
	lock_texture = load(LOCK_ICON)
	_setup_strip()
	_go_to_index(_max_unlocked())
	_center_strip()
	date_strip.position.x = strip_base_x

func _load_progress():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		var arr = cfg.get_value("progress", "completed_days", [])
		for d in arr:
			completed_days.append(int(d))

func _save_progress():
	var cfg = ConfigFile.new()
	cfg.set_value("progress", "completed_days", completed_days)
	cfg.save(SAVE_PATH)

func _max_unlocked() -> int:
	var m = 0
	if completed_days.size() > 0:
		m = completed_days.max() + 1 if completed_days.max() < EVENTS.size() - 1 else EVENTS.size() - 1
	return m

func _is_done(index : int) -> bool:
	return index in completed_days

func _is_unlocked(index : int) -> bool:
	return index <= _max_unlocked()

func _go_prev():
	if current_index > 0 and not animating:
		_slide_to(current_index - 1)

func _go_next():
	if current_index < EVENTS.size() - 1 and not animating:
		_slide_to(current_index + 1)

func _update_all():
	_update_bg()
	_update_title()
	_update_strip()
	_update_status()
	_update_nav()

func _slide_to(target : int):
	if target == current_index or animating:
		return
	if target < 0 or target >= EVENTS.size():
		return

	animating = true
	_update_nav()

	var dirn = signi(target - current_index)
	var steps = absi(target - current_index)
	var pitch = 134.0
	var base_x = strip_base_x

	var tw = create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	for step in range(steps):
		var from_x = date_strip.position.x
		var to_x = from_x - dirn * pitch
		tw.tween_property(date_strip, "position:x", to_x, 0.18)
		tw.tween_callback(func():
			current_index += dirn
			_refresh_strip()
			date_strip.position.x = base_x
		)

	tw.tween_callback(func():
		animating = false
		_update_title()
		_update_status()
		_update_nav()
	)

func _go_to_index(index : int):
	current_index = index
	_update_all()

func _center_strip():
	var total = 0.0
	var sep = 8.0
	for ch in date_strip.get_children():
		if ch.visible:
			total += ch.custom_minimum_size.x + sep
	total -= sep
	strip_base_x = (date_clip.size.x - total) / 2.0
	date_strip.position.x = strip_base_x

func _update_status():
	var ev = _get_event(current_index)
	var done = _is_done(current_index)
	var unlocked = _is_unlocked(current_index)

	if not unlocked:
		status_icon.visible = true
		status_icon.texture = lock_texture
		status_label.text = "LOCKED"
		status_label.add_theme_color_override("font_color", Color(0.65, 0.4, 0.4))
	elif done:
		status_icon.visible = false
		status_label.text = "COMPLETED"
		status_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.45))
	else:
		status_icon.visible = false
		status_label.text = "AVAILABLE"
		status_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))

func _update_bg():
	var ev = _get_event(current_index)
	var img_path = ev.get("image", "")
	if img_path != "":
		var tex = load(img_path)
		if tex:
			bg_texture.texture = tex
			bg_texture.visible = true
			bg_texture.modulate = Color.WHITE
			bg_color.visible = false
			return
	bg_texture.visible = false
	bg_color.visible = true
	bg_color.modulate = Color.WHITE

func _update_title():
	var ev = _get_event(current_index)
	title_age_label.text = ev.get("titleAge", "")
	event_name_label.text = ev.get("eventName", "")
	event_desc_label.text = ev.get("eventDesc", "")
	play_button.disabled = not _is_unlocked(current_index)
	play_button.text = "Play"

func _setup_strip():
	for ch in date_strip.get_children():
		ch.free()

	var sizes = {0: 1.0, 1: 0.8, 2: 0.6, 3: 0.4}
	for offset in range(-3, 4):
		var btn = Button.new()
		btn.text = ""
		var ratio = sizes[abs(offset)]
		btn.custom_minimum_size = Vector2(140 * ratio, 70 * ratio)
		btn.add_theme_font_size_override("font_size", int(22 * ratio))
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var off = offset
		btn.pressed.connect(func():
			var target = current_index + off
			if target >= 0 and target < EVENTS.size() and target != current_index and not animating:
				_slide_to(target)
		)
		btn.set_meta("offset", offset)
		date_strip.add_child(btn)

func _refresh_strip():
	for ch in date_strip.get_children():
		var off : int = ch.get_meta("offset")
		var idx = current_index + off
		ch.visible = true
		if idx < 0 or idx >= EVENTS.size():
			ch.text = ""
			ch.disabled = true
			ch.set_meta("blank", true)
			continue
		ch.disabled = false
		ch.set_meta("blank", false)
		ch.text = EVENTS[idx].titleAge

		var base_color : Color
		if _is_done(idx):
			base_color = Color(0.55, 1.0, 0.65) if off == 0 else Color(0.3, 0.9, 0.45)
		elif _is_unlocked(idx):
			base_color = Color(0.9, 0.85, 0.6)
		else:
			base_color = Color(1.0, 0.35, 0.35) if off == 0 else Color(0.4, 0.4, 0.44)

		ch.set_meta("base_color", base_color)
		ch.add_theme_color_override("font_color", base_color)
		ch.add_theme_color_override("font_hover_color", base_color.lightened(0.35))
		ch.add_theme_color_override("font_hover_pressed_color", base_color.lightened(0.35))
		ch.add_theme_color_override("font_focus_color", base_color)

func _update_strip():
	_refresh_strip()

func _update_nav():
	$NavPrev.disabled = current_index <= 0 or animating
	$NavNext.disabled = current_index >= EVENTS.size() - 1 or animating

func _on_play_pressed():
	if not _is_unlocked(current_index):
		return
	if current_index not in completed_days:
		completed_days.append(current_index)
		_save_progress()
	_play_animation()

func _play_animation():
	animating = true
	var ev = _get_event(current_index)
	var weekday = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"][current_index % 7]
	anim_day_label.text = ev.get("titleAge", "")
	anim_weekday_label.text = weekday
	anim_event_label.text = ev.get("eventName", "")
	anim_day_label.modulate = Color.WHITE
	anim_day_label.scale = Vector2(1, 1)
	anim_overlay.visible = true

	var tw = create_tween()
	tw.tween_property(anim_day_label, "scale", Vector2(1.6, 1.6), 1.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(anim_day_label, "modulate:a", 0.0, 0.4).set_delay(0.9)
	tw.tween_callback(func():
		anim_overlay.visible = false
		animating = false
		_update_all()
	)

func is_all_complete() -> bool:
	return completed_days.size() >= EVENTS.size()
