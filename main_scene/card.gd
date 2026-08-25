extends Control

signal card_clicked(card)
signal card_drag_ended(card, global_pos)

@onready var face_rect : TextureRect = $Face
@onready var back_rect : TextureRect = $Back

var face_texture_path : String = ""
var back_texture_path : String = ""
var card_data : Resource = null
var can_click := true
var can_drag := false
var _dragging := false
var _drag_start := Vector2.ZERO

func _ready():
	pivot_offset = Vector2(87, 122)
	if face_texture_path:
		_apply_textures()
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(func(): if not _dragging: modulate = Color(1.2, 1.2, 1.0))
	mouse_exited.connect(func(): if not _dragging: modulate = Color.WHITE)

func set_textures(face_path : String, back_path : String):
	face_texture_path = face_path
	back_texture_path = back_path
	if face_rect and back_rect:
		_apply_textures()

func _apply_textures():
	if face_texture_path:
		face_rect.texture = load(face_texture_path)
	if back_texture_path:
		back_rect.texture = load(back_texture_path)

func set_face_up(val : bool):
	if face_rect and back_rect:
		face_rect.visible = val
		back_rect.visible = not val

func _on_gui_input(event : InputEvent):
	if not can_click:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if can_drag:
				_dragging = true
				_drag_start = event.global_position
				z_index = 1000
			else:
				card_clicked.emit(self)
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if _dragging:
				_dragging = false
				z_index = 0
				modulate = Color.WHITE
				var dist = event.global_position.distance_to(_drag_start)
				if dist < 5.0:
					card_clicked.emit(self)
				else:
					card_drag_ended.emit(self, event.global_position)
	elif event is InputEventMouseMotion and _dragging:
		global_position += event.relative
