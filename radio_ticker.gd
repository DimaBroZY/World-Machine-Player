extends Control
class_name ScrollText

@export var label_path: NodePath = ^"CurrentTrackName"
@export_range(10.0, 300.0, 1.0) var speed: float = 45.0
@export_range(0.0, 3.0, 0.1) var start_delay: float = 0.7
@export_range(0.0, 3.0, 0.1) var restart_delay: float = 0.25
@export_range(8.0, 200.0, 1.0) var gap: float = 64.0
@export var center_when_short: bool = true

@onready var _label: Label = get_node(label_path) as Label

var _copy: Label
var _source_text: String = ""
var _text_width: float = 0.0
var _offset: float = 0.0
var _delay_left: float = 0.0
var _scrolling: bool = false


func _ready() -> void:
	clip_contents = true

	_source_text = _label.text
	_setup_label(_label)

	var duplicated_node: Node = _label.duplicate()
	_copy = duplicated_node as Label
	_copy.name = "MarqueeCopy"
	_copy.visible = false
	add_child(_copy)
	_setup_label(_copy)

	resized.connect(_rebuild)
	call_deferred("_rebuild")


func set_track_name(text: String) -> void:
	if _source_text == text:
		return

	_source_text = text
	call_deferred("_rebuild")


func _process(delta: float) -> void:
	if not _scrolling:
		return

	if _delay_left > 0.0:
		_delay_left -= delta
		return

	var cycle_width: float = _text_width + gap
	_offset += speed * delta

	if _offset >= cycle_width:
		_offset = fmod(_offset, cycle_width)
		_delay_left = restart_delay

	var rounded_offset: float = round(_offset)

	_label.position = Vector2(-rounded_offset, 0.0)
	_copy.position = Vector2(round(cycle_width - _offset), 0.0)


func _setup_label(label: Label) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = false
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)


func _rebuild() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		set_process(false)
		return

	_label.text = _source_text
	_copy.text = _source_text

	_text_width = ceil(_measure_text(_source_text))
	_offset = 0.0
	_delay_left = start_delay

	if _text_width <= size.x:
		_scrolling = false
		_copy.visible = false

		if center_when_short:
			_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

		_label.position = Vector2.ZERO
		_label.size = size

		set_process(false)
		return

	_scrolling = true
	_copy.visible = true

	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	_label.size = Vector2(_text_width, size.y)
	_copy.size = Vector2(_text_width, size.y)

	_label.position = Vector2.ZERO
	_copy.position = Vector2(_text_width + gap, 0.0)

	set_process(true)


func _measure_text(text: String) -> float:
	if text.is_empty():
		return 0.0

	var font: Font = _label.get_theme_font("font")
	var font_size: int = _label.get_theme_font_size("font_size")

	if _label.label_settings != null:
		if _label.label_settings.font != null:
			font = _label.label_settings.font
		font_size = _label.label_settings.font_size

	return font.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size
	).x
