extends Node2D

const WIN_SCORE := 41
const NUM_PLAYERS := 4
const INITIAL_HAND_SIZE := 4
const BOT_WAIT := 2.0
const CARD_SCENE = preload("res://main_scene/card.tscn")
const CARD_DB_PATH = "res://main_scene/card_database.json"
const CARD_ASSET_FOLDER = "res://assets/card/"
const CONFIG_PATH = "user://settings.cfg"
const GAME_CONFIG_PATH = "user://game_settings.cfg"
const ACHIEVEMENTS_PATH = "user://achievements.cfg"
const CW := 1366.0
const CH := 768.0

const BG_COLORS = {
	"Dark": Color(0.08, 0.08, 0.12),
	"Green": Color(0.05, 0.15, 0.05),
	"Blue": Color(0.05, 0.05, 0.15),
	"Red": Color(0.15, 0.05, 0.05),
	"Purple": Color(0.12, 0.05, 0.15),
	"Brown": Color(0.12, 0.08, 0.05),
	"Teal": Color(0.05, 0.12, 0.12),
	"White": Color(0.85, 0.85, 0.85),
}

const CARD_STYLES = {
	"Default": {"modulate": Color.WHITE, "unlock_wins": 0},
	"Golden": {"modulate": Color(1.0, 0.85, 0.4), "unlock_wins": 1},
	"Crimson": {"modulate": Color(1.0, 0.4, 0.4), "unlock_wins": 3},
	"Emerald": {"modulate": Color(0.4, 1.0, 0.5), "unlock_wins": 5},
	"Royal": {"modulate": Color(0.5, 0.4, 1.0), "unlock_wins": 10},
}

var card_database : Array = []
var draw_pile : Array = []
var players : Array = []
var current_player := 0
var game_state := "idle"
var clickable_cards : Array = []
var bot_types : Array = []
var bot_preferred_suit : Array = []
var bot_names : Array = []

var game_best_of := 1
var game_joker := false
var game_random_suit := false
var game_human_count := 1
var game_human_delay := 2.0
var human_players : Array = []
var round_wins : Array = [0, 0, 0, 0]
var current_round := 0
var assigned_suits : Array = []
var card_styles := {"hearts": "default", "diamonds": "default", "spades": "default", "clubs": "default"}
var total_wins := 0
var available_styles : Array = []

func _is_human(pi : int) -> bool:
	return pi in human_players

const BOT_NAME_MAP = {
	"A": "Randy",
	"B": "Vince",
	"C": "Cleo",
	"D": "Dexter",
	"E": "Elara"
}

@onready var status_label : Label = $UILayer/StatusLabel
@onready var action_button : Button = $UILayer/ActionButton
@onready var choice_button : Button = $UILayer/ChoiceButton
@onready var pile_label : Label = $UILayer/PileLabel
@onready var discard_button : Button = $UILayer/DiscardButton
@onready var finish_button : Button = $UILayer/FinishButton
@onready var options_button : Button = $UILayer/OptionsButton
@onready var play_again_button : Button = $UILayer/PlayAgainButton

@onready var hand_pos : Array = [
	$Positions/Hand0, $Positions/Hand1, $Positions/Hand2, $Positions/Hand3
]
@onready var grave_pos : Array = [
	$Positions/Grave0, $Positions/Grave1, $Positions/Grave2, $Positions/Grave3
]
@onready var pile_pos : Node2D = $Positions/Pile
var round_no_takes := 0
var pile_bg : ColorRect
var grave_bgs : Array = []
var grave_panel : Panel
var grave_list_label : Label
var grave_close_btn : Button
var game_options_panel : ColorRect
var game_options_overlay : ColorRect
var game_options_visible := false
var card_style_dialog : Panel
var card_style_overlay : ColorRect
var cs_preview_cont : Control
var cs_style_list_cont : Control
var cs_selected_suit := "hearts"
var bg_rect : ColorRect
var bg_texture : TextureRect
var current_bg_color := Color(0.08, 0.08, 0.12)
var current_bg_image := ""

func _ready():
	bg_rect = ColorRect.new()
	bg_rect.position = Vector2(0, 0)
	bg_rect.size = Vector2(CW, CH)
	bg_rect.color = Color(0.08, 0.08, 0.12)
	bg_rect.z_index = -100
	add_child(bg_rect)

	bg_texture = TextureRect.new()
	bg_texture.position = Vector2(0, 0)
	bg_texture.size = Vector2(CW, CH)
	bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_texture.z_index = -99
	bg_texture.visible = false
	add_child(bg_texture)

	_load_config()
	_load_achievements()
	_scan_card_styles()
	_apply_background()

	action_button.visible = false
	choice_button.visible = false
	discard_button.visible = false
	action_button.pressed.connect(func(): _on_action())
	choice_button.pressed.connect(func(): _on_choice())
	discard_button.pressed.connect(func(): _on_discard())
	finish_button.pressed.connect(func(): _on_finish())
	finish_button.visible = false
	play_again_button.visible = false
	play_again_button.pressed.connect(func():
		if play_again_button.text == "Next Round":
			_start_next_round()
		else:
			get_tree().reload_current_scene()
	)

	grave_panel = Panel.new()
	grave_panel.position = Vector2(CW / 2 - 120, CH / 2 - 120)
	grave_panel.size = Vector2(240, 240)
	grave_panel.visible = false
	$UILayer.add_child(grave_panel)

	grave_list_label = Label.new()
	grave_list_label.position = Vector2(10, 10)
	grave_list_label.size = Vector2(220, 200)
	grave_list_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	grave_list_label.add_theme_font_size_override("font_size", 13)
	grave_panel.add_child(grave_list_label)

	grave_close_btn = Button.new()
	grave_close_btn.position = Vector2(75, 210)
	grave_close_btn.size = Vector2(90, 25)
	grave_close_btn.text = "Close"
	grave_close_btn.pressed.connect(func(): grave_panel.visible = false)
	grave_panel.add_child(grave_close_btn)

	options_button.pressed.connect(_on_options_pressed)
	_create_game_options_panel()
	_create_card_style_dialog()

	_load_db()
	_create_areas()
	_start()

func _load_db():
	var f = FileAccess.open(CARD_DB_PATH, FileAccess.READ)
	if f:
		var j = JSON.new()
		if j.parse(f.get_as_text()) == OK:
			card_database = j.data

func _make_card(cd : Dictionary) -> Control:
	var c = CARD_SCENE.instantiate()
	var suit = cd.get("suit", "")
	var style_name = card_styles.get(suit, "default")
	var tex_filename = cd.get("texture", "")
	var face_path = CARD_ASSET_FOLDER + style_name + "/" + tex_filename
	var back_path = cd.get("backface_texture_path", "res://assets/card_back.png")
	if not ResourceLoader.exists(face_path):
		face_path = CARD_ASSET_FOLDER + "default/" + tex_filename
	c.set_textures(face_path, back_path)
	c.scale = Vector2(0.45, 0.45)
	c.card_data = load(cd.resource_script_path).new()
	for k in cd.keys():
		if k != "texture" and k != "backface_texture_path" and k != "resource_script_path":
			c.card_data[k] = cd[k]
	c.set_face_up(false)
	return c

func _create_areas():
	for i in range(NUM_PLAYERS):
		var pd = {
			"hand": [], "grave": [], "score": 0,
			"hand_node": null, "grave_node": null, "label_node": null
		}
		var h = Node2D.new()
		h.position = hand_pos[i].position
		h.name = "H%d" % i
		add_child(h)
		pd.hand_node = h

		var g = Node2D.new()
		g.position = grave_pos[i].position
		g.name = "G%d" % i
		add_child(g)
		pd.grave_node = g

		var bg = ColorRect.new()
		if (i == 0 || i == 2):
			bg.position = Vector2(-55, -40)
			bg.size = Vector2(110, 80)
		else:
			bg.position = Vector2(-40, -55)
			bg.size = Vector2(80, 110)
		bg.color = Color(0.15, 0.15, 0.15, 0.5)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		g.add_child(bg)
		grave_bgs.append(bg)

		var lbl = Label.new()
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.position = Vector2(-40, -72)
		lbl.z_index = 2
		g.add_child(lbl)
		pd.label_node = lbl

		players.append(pd)

	pile_bg = ColorRect.new()
	pile_bg.position = pile_pos.position
	pile_bg.color = Color(0.15, 0.15, 0.15, 0.5)
	pile_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pile_bg)

func _start():
	_load_game_config()
	human_players.clear()
	for i in range(game_human_count):
		human_players.append(i)
	game_state = "dealing"
	status_label.text = "Dealing..."
	bot_types.clear()
	bot_preferred_suit.clear()
	bot_names.clear()
	var types = ["A", "B", "C", "D", "E"]
	types.shuffle()
	var bot_idx := 0
	var human_num := 0
	for i in range(NUM_PLAYERS):
		if _is_human(i):
			human_num += 1
			bot_types.append("HUMAN")
			bot_preferred_suit.append("")
			bot_names.append("Player %d" % human_num)
		else:
			var bt = types[bot_idx]
			bot_idx += 1
			bot_types.append(bt)
			bot_preferred_suit.append("")
			bot_names.append(BOT_NAME_MAP[bt])
	await get_tree().create_timer(0.3).timeout
	current_round += 1
	assigned_suits.clear()
	if game_random_suit:
		var suits = ["hearts", "diamonds", "spades", "clubs"]
		for i in range(NUM_PLAYERS):
			assigned_suits.append(suits[randi() % suits.size()])
	_create_pile()
	await _deal()
	for i in range(NUM_PLAYERS):
		if !_is_human(i) and players[i].hand.size() > 0:
			bot_preferred_suit[i] = _best_suit(i)
	current_player = 0
	_begin_turn()

func _start_next_round():
	for pi in range(NUM_PLAYERS):
		for c in players[pi].hand:
			if c.get_parent():
				c.get_parent().remove_child(c)
		for c in players[pi].grave:
			if c.get_parent():
				c.get_parent().remove_child(c)
		players[pi].hand.clear()
		players[pi].grave.clear()
		players[pi].score = 0
	round_no_takes = 0
	draw_pile.clear()
	for ch in get_children():
		if ch is Control and ch != pile_bg and ch is not ColorRect and ch.z_index == 50:
			if ch.card_clicked.is_connected(_on_pile_card_click):
				ch.card_clicked.disconnect(_on_pile_card_click)
			remove_child(ch)
		_kill_clicks()
	game_state = "dealing"
	status_label.text = "Dealing..."
	play_again_button.visible = false
	current_round += 1
	assigned_suits.clear()
	if game_random_suit:
		var suits = ["hearts", "diamonds", "spades", "clubs"]
		for i in range(NUM_PLAYERS):
			assigned_suits.append(suits[randi() % suits.size()])
	_create_pile()
	await _deal()
	for i in range(NUM_PLAYERS):
		if !_is_human(i) and players[i].hand.size() > 0:
			bot_preferred_suit[i] = _best_suit(i)
	current_player = 0
	_begin_turn()

func _create_pile():
	for cd in card_database:
		if not game_joker and cd.suit.begins_with("joker"):
			continue
		var c = _make_card(cd)
		draw_pile.append(c)
	_layout_pile()
	_pile_lbl()

func _layout_pile():
	for ch in get_children():
		if ch is Control and ch != pile_bg and ch is not ColorRect and ch.z_index == 50:
			if ch.card_clicked.is_connected(_on_pile_card_click):
				ch.card_clicked.disconnect(_on_pile_card_click)
			remove_child(ch)
	_pile_lbl()
	if draw_pile.size() > 0:
		pile_bg.color = Color(0.15, 0.15, 0.15, 0.5)
		var top = draw_pile[-1]
		if top.get_parent():
			top.get_parent().remove_child(top)
		add_child(top)
		top.position = pile_bg.position - Vector2(87, 122)
		top.z_index = 50
		top.set_face_up(false)
		top.scale = Vector2(0.45, 0.45)
		top.mouse_filter = Control.MOUSE_FILTER_STOP
		top.can_click = true
		top.can_drag = false
		if not top.card_clicked.is_connected(_on_pile_card_click):
			top.card_clicked.connect(_on_pile_card_click)
	else:
		pile_bg.color = Color(0.3, 0.1, 0.1, 0.3)

func _deal():
	draw_pile.shuffle()
	for i in range(INITIAL_HAND_SIZE):
		for p in range(NUM_PLAYERS):
			if draw_pile.size() > 0:
				players[p].hand.append(draw_pile.pop_back())
				_layout_hand(p)
				_upd_lbl(p)
				_layout_pile()
				_pile_lbl()
			await get_tree().create_timer(0.02).timeout

func _begin_turn():
	_kill_clicks()
	_update_hovers()
	for pi in range(NUM_PLAYERS):
		_upd_lbl(pi)
	_layout_all_hands()
	choice_button.position = Vector2(1040, 740)
	choice_button.size = Vector2(156, 26)
	var cd = draw_pile.size() > 0
	var ct = _top_grave(current_player) != null
	if not cd:
		if not ct:
			if round_no_takes >= NUM_PLAYERS:
				_game_end()
				return
			round_no_takes += 1
			current_player = (current_player + 1) % 4
			_begin_turn()
			return
		if _is_human(current_player):
			game_state = "pick_source"
			action_button.visible = false
			choice_button.visible = true
			choice_button.text = "Take from Grave"
			finish_button.visible = true
			discard_button.visible = false
			status_label.text = "%s: Take from Grave or Finish" % bot_names[current_player]
		else:
			status_label.text = "%s is thinking..." % bot_names[current_player]
			await get_tree().create_timer(BOT_WAIT).timeout
			_bot_play_source("grave")
		return
	if not ct:
		if _is_human(current_player):
			game_state = "pick_source"
			action_button.visible = true
			action_button.text = "Draw from Pile"
			choice_button.visible = false
			finish_button.visible = false
			discard_button.visible = false
			status_label.text = "%s: Draw from Pile" % bot_names[current_player]
		else:
			status_label.text = "%s is thinking..." % bot_names[current_player]
			await get_tree().create_timer(BOT_WAIT).timeout
			_bot_play_source("pile")
		return
	if _is_human(current_player):
		game_state = "pick_source"
		action_button.visible = true
		action_button.text = "Draw from Pile"
		choice_button.visible = true
		choice_button.text = "Take from Grave"
		finish_button.visible = false
		discard_button.visible = false
		status_label.text = "%s: Draw or take grave card" % bot_names[current_player]
	else:
		status_label.text = "%s is thinking..." % bot_names[current_player]
		await get_tree().create_timer(BOT_WAIT).timeout
		_bot_decide_source()

func _top_grave(pi : int) -> Control:
	var g = players[pi].grave
	return g[-1] if g.size() > 0 else null

func _best_suit(pi : int) -> String:
	var ss := {}
	for c in players[pi].hand:
		var s = c.card_data.suit
		ss[s] = ss.get(s, 0) + c.card_data.value
	var best_suit := ""
	var best_val := -1
	for s in ss:
		if ss[s] > best_val:
			best_val = ss[s]
			best_suit = s
	return best_suit

func _score_with_card(pi : int, card : Control) -> int:
	var temp = players[pi].hand.duplicate()
	temp.append(card)
	return _score(temp, pi)

func _score_without_card(pi : int, card : Control) -> int:
	var temp = players[pi].hand.duplicate()
	temp.erase(card)
	return _score(temp, pi)

func _bot_decide_source():
	var pi = current_player
	var has_pile = draw_pile.size() > 0
	var has_grave = _top_grave(pi) != null
	var bot = bot_types[pi]

	if has_pile and has_grave:
		match bot:
			"A": _bot_play_source("random")
			"B": _bot_play_source(_bot_b_source(pi))
			"C": _bot_play_source(_bot_c_source(pi))
			"D": _bot_play_source(_bot_d_source(pi))
			"E": _bot_play_source(_bot_e_source(pi))
			_: _bot_play_source("pile")
	elif has_pile:
		_bot_play_source("pile")
	elif has_grave:
		_bot_play_source("grave")
	else:
		current_player = (current_player + 1) % 4
		_begin_turn()

func _bot_play_source(choice : String):
	var pi = current_player
	var src = choice
	if src == "random":
		src = "pile" if randf() > 0.5 else "grave"
	elif src == "pile" and draw_pile.size() == 0:
		src = "grave"
	elif src == "grave" and _top_grave(pi) == null:
		src = "pile"

	if src == "pile" and draw_pile.size() > 0:
		var c = draw_pile.pop_back()
		players[pi].hand.append(c)
		_layout_hand(pi)
		_layout_pile()
		_upd_lbl(pi)
		_pile_lbl()
	elif src == "grave" and _top_grave(pi) != null:
		var c = _top_grave(pi)
		round_no_takes = 0
		players[pi].grave.erase(c)
		if c.get_parent():
			c.get_parent().remove_child(c)
		players[pi].hand.append(c)
		_layout_hand(pi)
		_layout_grave(pi)
		_upd_lbl(pi)

	status_label.text = "%s is discarding..." % bot_names[pi]
	await get_tree().create_timer(BOT_WAIT).timeout
	_bot_discard(pi)

func _bot_discard(pi : int):
	var hand = players[pi].hand
	if hand.size() == 0:
		current_player = (current_player + 1) % 4
		_begin_turn()
		return
	var bot = bot_types[pi]
	var card_to_discard = hand[0]
	match bot:
		"A": card_to_discard = hand[randi() % hand.size()]
		"B": card_to_discard = _bot_b_discard_from(pi, hand)
		"C": card_to_discard = _bot_c_discard_from(pi, hand)
		"D": card_to_discard = _bot_d_discard_from(pi, hand)
		"E": card_to_discard = _bot_e_discard_from(pi, hand)
		_: card_to_discard = hand[0]
	_do_discard_for_bot(card_to_discard)

func _do_discard_for_bot(card : Control):
	var pi = current_player
	players[pi].hand.erase(card)
	var np = (pi + 1) % 4
	_to_grave(card, np)
	_layout_hand(pi)
	_upd_lbl(pi)
	_upd_lbl(np)
	current_player = np
	for p in range(4):
		if players[p].score >= WIN_SCORE:
			_game_end()
			return
	if _is_human(pi) and _is_human(np):
		await get_tree().create_timer(game_human_delay).timeout
	_begin_turn()

func _bot_b_source(pi : int) -> String:
	var grave_top = _top_grave(pi)
	if grave_top:
		var r = grave_top.card_data.rank
		if r in ["10", "J", "Q", "K", "A"]:
			return "grave"
	return "pile"

func _bot_c_source(pi : int) -> String:
	var target = bot_preferred_suit[pi]
	var grave_top = _top_grave(pi)
	if grave_top and grave_top.card_data.suit == target:
		return "grave"
	return "pile"

func _bot_d_source(pi : int) -> String:
	var pile_score = -999
	var grave_score = -999
	var cur = _score(players[pi].hand, pi)
	if draw_pile.size() > 0:
		pile_score = _score_with_card(pi, draw_pile[-1]) - cur
	if _top_grave(pi):
		grave_score = _score_with_card(pi, _top_grave(pi)) - cur
	if pile_score >= grave_score:
		return "pile"
	return "grave"

func _bot_e_source(pi : int) -> String:
	var target = bot_preferred_suit[pi]
	var grave_top = _top_grave(pi)
	if grave_top:
		var r = grave_top.card_data.rank
		if r in ["10", "J", "Q", "K", "A"] and grave_top.card_data.suit == target:
			return "grave"
		if r in ["10", "J", "Q", "K", "A"]:
			return "grave"
	if draw_pile.size() > 0:
		var peek = draw_pile[-1]
		if peek.card_data.suit == target:
			return "pile"
	return "pile"

func _bot_b_discard_from(pi : int, pool : Array) -> Control:
	return pool[randi() % pool.size()]

func _bot_c_discard_from(pi : int, pool : Array) -> Control:
	var target = bot_preferred_suit[pi]
	var worst = pool[0]
	var worst_val = 999
	for c in pool:
		if c.card_data.suit == target:
			continue
		if c.card_data.value < worst_val:
			worst_val = c.card_data.value
			worst = c
	if worst_val == 999:
		return pool[randi() % pool.size()]
	return worst

func _bot_d_discard_from(pi : int, pool : Array) -> Control:
	var cur = _score(players[pi].hand, pi)
	var best_card = pool[0]
	var best_diff = -9999
	for c in pool:
		var temp = players[pi].hand.duplicate()
		temp.erase(c)
		var sc = _score(temp, pi)
		var diff = sc - cur
		if diff > best_diff:
			best_diff = diff
			best_card = c
	return best_card

func _bot_e_discard_from(pi : int, pool : Array) -> Control:
	var target = bot_preferred_suit[pi]
	var non_target = []
	for c in pool:
		if c.card_data.suit != target:
			non_target.append(c)
	if non_target.size() > 0:
		return non_target[randi() % non_target.size()]
	return pool[randi() % pool.size()]

func _update_hovers():
	pile_bg.color = Color(0.15, 0.15, 0.15, 0.5)
	_layout_pile()
	for i in range(NUM_PLAYERS):
		grave_bgs[i].color = Color(0.15, 0.15, 0.15, 0.5)

func _layout_all_hands():
	for pi in range(NUM_PLAYERS):
		_layout_hand(pi)

func _on_action():
	if game_state == "pick_source" and draw_pile.size() > 0:
		var c = draw_pile.pop_back()
		players[current_player].hand.append(c)
		_layout_hand(current_player)
		_layout_pile()
		_upd_lbl(current_player)
		_pile_lbl()
		_to_discard()

func _on_choice():
	if game_state == "pick_source":
		var c = _top_grave(current_player)
		if c:
			round_no_takes = 0
			players[current_player].grave.erase(c)
			if c.get_parent():
				c.get_parent().remove_child(c)
			players[current_player].hand.append(c)
			_layout_hand(current_player)
			_layout_grave(current_player)
			_upd_lbl(current_player)
			_to_discard()

func _on_finish():
	_game_end()

func _on_options_pressed():
	game_options_visible = !game_options_visible
	game_options_panel.visible = game_options_visible
	game_options_overlay.visible = game_options_visible

func _create_game_options_panel():
	game_options_overlay = ColorRect.new()
	game_options_overlay.position = Vector2(0, 0)
	game_options_overlay.size = Vector2(CW, CH)
	game_options_overlay.color = Color(0, 0, 0, 0.7)
	game_options_overlay.visible = false
	game_options_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	$UILayer.add_child(game_options_overlay)

	var scene = preload("res://ui/options_panel.tscn")
	game_options_panel = scene.instantiate()
	game_options_panel.visible = false
	$UILayer.add_child(game_options_panel)
	game_options_panel.set_total_wins(total_wins)
	game_options_panel.set_card_style_summary(_get_card_style_summary())
	game_options_panel.show_game_buttons(true)
	game_options_panel.set_initial_volume(db_to_linear(AudioServer.get_bus_volume_db(0)))
	game_options_panel.set_initial_mute(AudioServer.is_bus_mute(0))
	game_options_panel.close_pressed.connect(func(): _close_options())
	game_options_panel.bg_color_changed.connect(func(color):
		current_bg_color = color
		current_bg_image = ""
		_apply_background()
		_save_config()
	)
	game_options_panel.bg_image_changed.connect(func(path):
		current_bg_color = Color.BLACK
		current_bg_image = path
		_apply_background()
		_save_config()
	)
	game_options_panel.card_style_pressed.connect(func(): _open_card_style_dialog())
	game_options_panel.main_menu_pressed.connect(func():
		get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")
	)
	game_options_panel.exit_pressed.connect(func(): get_tree().quit())
	game_options_overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			_close_options()
	)

func _apply_background():
	if current_bg_image != "":
		var tex = load(current_bg_image)
		if tex:
			bg_texture.texture = tex
			bg_texture.visible = true
			bg_rect.visible = false
			return
	bg_texture.visible = false
	bg_rect.visible = true
	bg_rect.color = current_bg_color

func _save_config():
	var cfg = ConfigFile.new()
	cfg.set_value("background", "color", current_bg_color)
	cfg.set_value("background", "image", current_bg_image)
	for suit in card_styles:
		cfg.set_value("card_styles", suit, card_styles[suit])
	cfg.save(CONFIG_PATH)

func _get_card_style_summary() -> String:
	var styles = []
	for suit in ["hearts", "diamonds", "spades", "clubs"]:
		styles.append(card_styles.get(suit, "default"))
	if styles[0] == styles[1] and styles[1] == styles[2] and styles[2] == styles[3]:
		return styles[0].capitalize()
	return "%s/%s/%s/%s" % [styles[0].capitalize(), styles[1].capitalize(), styles[2].capitalize(), styles[3].capitalize()]

func _load_config():
	var cfg = ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		current_bg_color = cfg.get_value("background", "color", Color(0.08, 0.08, 0.12))
		current_bg_image = cfg.get_value("background", "image", "")
		for suit in ["hearts", "diamonds", "spades", "clubs"]:
			card_styles[suit] = cfg.get_value("card_styles", suit, "default")

func _load_achievements():
	var cfg = ConfigFile.new()
	if cfg.load(ACHIEVEMENTS_PATH) == OK:
		total_wins = cfg.get_value("stats", "total_wins", 0)
	else:
		total_wins = 0

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

func _save_achievements():
	var cfg = ConfigFile.new()
	cfg.load(ACHIEVEMENTS_PATH)
	cfg.set_value("stats", "total_wins", total_wins)
	cfg.save(ACHIEVEMENTS_PATH)

func _award_achievements(winner_is_human : bool):
	if not winner_is_human:
		return
	total_wins += 1
	_save_achievements()

func _load_game_config():
	var cfg = ConfigFile.new()
	if cfg.load(GAME_CONFIG_PATH) == OK:
		game_best_of = cfg.get_value("game", "best_of", 1)
		game_joker = cfg.get_value("game", "joker", false)
		game_random_suit = cfg.get_value("game", "random_suit", false)
		game_human_count = cfg.get_value("game", "human_count", 1)
		game_human_delay = cfg.get_value("game", "human_delay", 2.0)

func _close_options():
	game_options_visible = false
	game_options_panel.visible = false
	game_options_overlay.visible = false

func _create_card_style_dialog():
	card_style_overlay = ColorRect.new()
	card_style_overlay.position = Vector2(0, 0)
	card_style_overlay.size = Vector2(CW, CH)
	card_style_overlay.color = Color(0, 0, 0, 0.7)
	card_style_overlay.visible = false
	card_style_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	card_style_overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			_close_card_style_dialog()
	)
	$UILayer.add_child(card_style_overlay)

	card_style_dialog = Panel.new()
	card_style_dialog.position = Vector2(CW / 2 - 220, CH / 2 - 260)
	card_style_dialog.size = Vector2(440, 520)
	card_style_dialog.visible = false
	$UILayer.add_child(card_style_dialog)

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

	var style_name = card_styles.get(cs_selected_suit, "default")
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
			card_styles[cs_selected_suit] = captured_style
			_save_config()
			_update_cs_dialog()
		)
		cs_style_list_cont.add_child(sbtn)
		sy += 35.0

func _on_pile_card_click(card : Control):
	if game_state == "pick_source" and draw_pile.size() > 0 and draw_pile[-1] == card:
		_on_action()

func _on_grave_card_click(card : Control):
	for pi in range(NUM_PLAYERS):
		if players[pi].grave.size() > 0 and players[pi].grave[-1] == card:
			if game_state == "pick_source" and pi == current_player:
				_on_choice()
			else:
				_show_grave_list(pi)
			return

func _show_grave_list(pi : int):
	var g = players[pi].grave
	var text = "%s Grave (%d cards):\n" % [bot_names[pi], g.size()]
	for c in g:
		var cd = c.card_data
		text += "%s %s\n" % [cd.rank, cd.suit]
	grave_list_label.text = text
	grave_panel.visible = true

func _on_hand_card_drag(card : Control, drop_global : Vector2):
	var owner_pi := -1
	for pi in range(NUM_PLAYERS):
		if card in players[pi].hand:
			owner_pi = pi
			break
	if owner_pi < 0:
		return
	var hand = players[owner_pi].hand
	for c in hand:
		if c == card:
			continue
		var rect = Rect2(c.global_position - c.pivot_offset * c.scale, Vector2(175, 245) * c.scale)
		if rect.has_point(drop_global):
			var ai = hand.find(card)
			var bi = hand.find(c)
			var tmp = hand[ai]
			hand[ai] = hand[bi]
			hand[bi] = tmp
			_layout_hand(owner_pi)
			return
	_layout_hand(owner_pi)

func _to_discard():
	game_state = "pick_discard"
	action_button.visible = false
	choice_button.visible = false
	discard_button.visible = true
	discard_button.text = "Discard Last Card"
	status_label.text = "%s: Click card to discard (%d in hand)" % [bot_names[current_player], players[current_player].hand.size()]
	_enable_clicks(current_player)

func _on_discard():
	if game_state == "pick_discard":
		var h = players[current_player].hand
		if h.size() > 0:
			_do_discard(h[-1])

func _enable_clicks(pi : int):
	_kill_clicks()
	for c in players[pi].hand:
		if not c.card_clicked.is_connected(_card_click):
			c.card_clicked.connect(_card_click)
		clickable_cards.append(c)

func _kill_clicks():
	for c in clickable_cards:
		if c.card_clicked.is_connected(_card_click):
			c.card_clicked.disconnect(_card_click)
	clickable_cards.clear()

func _card_click(card : Control):
	if game_state == "pick_discard":
		_do_discard(card)

func _do_discard(card : Control):
	_kill_clicks()
	players[current_player].hand.erase(card)
	var pp = current_player
	var np = (current_player + 1) % 4
	_to_grave(card, np)
	_layout_hand(pp)
	_upd_lbl(pp)
	_upd_lbl(np)
	discard_button.visible = false
	current_player = np
	for p in range(4):
		if players[p].score >= WIN_SCORE:
			_game_end()
			return
	if _is_human(pp) and _is_human(np):
		await get_tree().create_timer(game_human_delay).timeout
	_begin_turn()

func _to_grave(card : Control, pi : int):
	if card.get_parent():
		card.get_parent().remove_child(card)
	players[pi].grave_node.add_child(card)
	card.set_face_up(true)
	players[pi].grave.append(card)
	_layout_grave(pi)

func _layout_grave(pi : int):
	var g = players[pi].grave
	var node = players[pi].grave_node
	for ch in node.get_children():
		if ch is Control and ch is not ColorRect and ch is not Label:
			if ch.card_clicked.is_connected(_on_grave_card_click):
				ch.card_clicked.disconnect(_on_grave_card_click)
			node.remove_child(ch)
	if g.size() > 0:
		var top = g[-1]
		if top.get_parent():
			top.get_parent().remove_child(top)
		node.add_child(top)
		top.position = Vector2(-87, -122)
		top.z_index = 1
		if pi == 0 or pi == 2:
			top.rotation = PI / 2
		else:
			top.rotation = 0
		top.set_face_up(true)
		top.mouse_filter = Control.MOUSE_FILTER_STOP
		top.can_click = true
		top.can_drag = false
		if top.card_clicked.is_connected(_on_grave_card_click):
			top.card_clicked.disconnect(_on_grave_card_click)
		top.card_clicked.connect(_on_grave_card_click)

func _layout_hand(pi : int):
	var node = players[pi].hand_node
	var hand = players[pi].hand
	for ch in node.get_children():
		if ch is Control:
			node.remove_child(ch)
	var n = hand.size()
	if n == 0:
		return

	var horiz = (pi == 0 or pi == 2)
	var card_w = 175.0 * 0.45
	var sp = minf(card_w * 0.8, 320.0 / maxf(n, 1))
	var total = sp * (n - 1)

	for i in range(n):
		var c = hand[i]
		if c.get_parent():
			c.get_parent().remove_child(c)
		node.add_child(c)
		c.set_face_up((_is_human(pi) and (game_human_count == 1 or pi == current_player)) or game_state == "game_over")
		c.z_index = i
		c.can_click = (_is_human(pi) and pi == current_player)
		c.can_drag = (_is_human(pi) and pi == current_player and game_state != "game_over")
		if _is_human(pi) and pi == current_player:
			if not c.card_drag_ended.is_connected(_on_hand_card_drag):
				c.card_drag_ended.connect(_on_hand_card_drag)
		else:
			if c.card_drag_ended.is_connected(_on_hand_card_drag):
				c.card_drag_ended.disconnect(_on_hand_card_drag)

		var ratio = 0.0
		if n > 1:
			ratio = float(i) / float(n - 1)

		var tilt = deg_to_rad(lerpf(-8.0, 8.0, ratio))
		var off = Vector2.ZERO

		if horiz:
			off.x = lerpf(-total / 2.0, total / 2.0, ratio)
			off.y = -absf(tilt) * 80.0
			if pi == 2:
				off.y = absf(tilt) * 80.0
		else:
			off.y = lerpf(-total / 2.0, total / 2.0, ratio)
			off.x = absf(tilt) * 80.0
			if pi == 3:
				off.x = -absf(tilt) * 80.0
			tilt = deg_to_rad(lerpf(-8.0, 8.0, ratio) + 90.0)

		c.position = off
		c.rotation = tilt

func _score(hand : Array, pi : int = -1) -> int:
	var ss := {}
	var red_jokers := 0
	var black_jokers := 0
	for c in hand:
		var s = c.card_data.suit
		if s == "joker_red":
			red_jokers += 1
		elif s == "joker_black":
			black_jokers += 1
		else:
			ss[s] = ss.get(s, 0) + c.card_data.value
	for i in range(red_jokers):
		var best_suit := ""
		var best_val := -1
		for s in ["hearts", "diamonds"]:
			if ss.get(s, 0) > best_val:
				best_val = ss.get(s, 0)
				best_suit = s
		if best_suit != "":
			ss[best_suit] = ss.get(best_suit, 0) + 10
		else:
			ss["hearts"] = ss.get("hearts", 0) + 10
	for i in range(black_jokers):
		var best_suit := ""
		var best_val := -1
		for s in ["spades", "clubs"]:
			if ss.get(s, 0) > best_val:
				best_val = ss.get(s, 0)
				best_suit = s
		if best_suit != "":
			ss[best_suit] = ss.get(best_suit, 0) + 10
		else:
			ss["spades"] = ss.get("spades", 0) + 10
	if ss.is_empty():
		return 0
	if game_random_suit and pi >= 0 and assigned_suits.size() > pi:
		var forced = assigned_suits[pi]
		var match_val = ss.get(forced, 0)
		var rest := 0
		for s in ss:
			if s != forced:
				rest += ss[s]
		return match_val - rest
	var best := 0
	for s in ss:
		if ss[s] > best:
			best = ss[s]
	var tot := 0
	for s in ss:
		tot += ss[s]
	return best - (tot - best)

func _upd_lbl(pi : int):
	var sc = _score(players[pi].hand, pi)
	players[pi].score = sc
	var nm = bot_names[pi] if pi < bot_names.size() else "P%d" % (pi + 1)
	var suit_info = ""
	if game_random_suit and assigned_suits.size() > pi:
		suit_info = " [%s]" % assigned_suits[pi]
	if game_state == "game_over" or (_is_human(pi)):
		players[pi].label_node.text = "%s: %dpts (%d)%s" % [nm, sc, players[pi].hand.size(), suit_info]
		players[pi].label_node.visible = true
	else:
		players[pi].label_node.text = "%s: ???" % nm
		players[pi].label_node.visible = true

func _pile_lbl():
	pile_label.text = "Pile: %d" % draw_pile.size()

func _game_end():
	game_state = "game_over"
	_kill_clicks()
	for pi in range(NUM_PLAYERS):
		_layout_hand(pi)
		_upd_lbl(pi)
	var best := -999
	var w := 0
	for i in range(4):
		if players[i].score > best:
			best = players[i].score
			w = i
	round_wins[w] += 1
	_award_achievements(_is_human(w))
	var wn = bot_names[w] if w < bot_names.size() else "P%d" % (w + 1)
	var needed = (game_best_of / 2) + 1
	var match_over = round_wins[w] >= needed
	var status = "Round %d: %s wins with %d pts! (Wins: %d/%d)" % [current_round, wn, best, round_wins[w], needed]
	if match_over:
		status = "MATCH OVER! %s wins the series! (%d rounds)" % [wn, round_wins[w]]
	status_label.text = status
	action_button.visible = false
	choice_button.visible = false
	discard_button.visible = false
	finish_button.visible = false
	play_again_button.visible = true
	if match_over or game_best_of == 1:
		play_again_button.text = "Play Again"
	else:
		play_again_button.text = "Next Round"
