extends Node

var pendant_collected: bool = false
var eclipse_shard_collected: bool = false

func reset_demo_state() -> void:
	pendant_collected = false
	eclipse_shard_collected = false

func collect_item(item_id: String) -> void:
	if item_id == "pendant_of_malaya":
		pendant_collected = true
		print("DemoState: Pendant collected")

	if item_id == "eclipse_shard_hunger":
		eclipse_shard_collected = true
		print("DemoState: Eclipse Shard collected")
