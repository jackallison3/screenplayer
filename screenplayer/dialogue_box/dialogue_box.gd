extends Control

@onready var dialogue_label: RichTextLabel = $DialoguePanelContainer/Panel/VBoxContainer/MarginContainer/HBoxContainer/MarginContainer/DialogueLabel
@onready var name_label: RichTextLabel = $NamePanelContainer/MarginContainer/NameLabel
@onready var next_icon: Control = $DialoguePanelContainer/Panel/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/NextIcon
@onready var name_panel_container: PanelContainer = $NamePanelContainer