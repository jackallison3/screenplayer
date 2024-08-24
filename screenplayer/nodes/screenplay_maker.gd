@tool
extends Node

func _enter_tree() -> void:
	if get_node_or_null("ScreenplayReader") == null and get_node_or_null("ScenePlayer") == null:
		var script_reader_node = load("addons/screenplayer/nodes/screenplay_reader.gd").new() as Node
		script_reader_node.name = "ScreenplayReader"
		add_child(script_reader_node)
		script_reader_node.owner = get_tree().edited_scene_root