@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("ScreenPlayer", "Node", preload("nodes/screenplay_maker.gd"), preload("res://icon.svg"))
	pass


func _exit_tree() -> void:
	remove_custom_type("ScriptReader")
	pass
