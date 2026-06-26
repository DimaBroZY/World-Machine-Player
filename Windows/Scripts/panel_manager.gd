extends MarginContainer

var panels: Array[PanelContainer] = []

@onready var general_button: Button = %GeneralButton
@onready var visual_button: Button = %VisualButton
@onready var system_button: Button = %SystemButton

func _ready() -> void:
	panels = [%GeneralPanel, %VisualPanel, %SystemPanel]

	general_button.pressed.connect(show_panel.bind(panels[0]))
	visual_button.pressed.connect(show_panel.bind(panels[1]))
	system_button.pressed.connect(show_panel.bind(panels[2]))
	
	show_panel(panels[0])
	
func show_panel(panel_to_show: PanelContainer) -> void:
	for panel in panels:
		panel.hide()
		
	panel_to_show.show()
