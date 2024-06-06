extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_despawn_timer_timeout():
	queue_free()


func _on_hit_box_area_2d_body_entered(body:Node2D):
	print(body.name + " touched clone")
	if body.has_method("freeze"):
		body.freeze()


func _on_hit_box_area_2d_area_entered(area:Area2D):
	print(area.name + " touched clone")
	if area.has_method("freeze"):
		area.freeze()
