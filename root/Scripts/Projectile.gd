extends Node2D
class_name Projectile

@onready var collision_path: RayCast2D = $RayCast2D
@onready var body: RigidBody2D = $RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	collision_path.target_position = to_local(get_global_mouse_position())
