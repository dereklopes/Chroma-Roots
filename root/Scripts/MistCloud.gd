extends Node2D

@onready var mist_particles_2d: GPUParticles2D = $MistParticles2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready():
	var process_material: ParticleProcessMaterial = mist_particles_2d.process_material
	if collision_shape_2d.shape is RectangleShape2D:
		process_material.emission_box_extents.x = collision_shape_2d.shape.size.x / 2
		process_material.emission_box_extents.y = collision_shape_2d.shape.size.y / 2
		mist_particles_2d.global_position.x = collision_shape_2d.global_position.x
		mist_particles_2d.global_position.y = collision_shape_2d.global_position.y
		mist_particles_2d.visibility_rect = collision_shape_2d.shape.get_rect()
	mist_particles_2d.amount = roundi(process_material.emission_box_extents.x + process_material.emission_box_extents.y)
	# mist_particles_2d.process_material.emission_box_extents = collision_shape_2d.shape.extents



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_lift_area_2d_body_entered(body:Node2D):
	if body.has_method("set_is_in_mist"):
		body.set_is_in_mist(true)


func _on_lift_area_2d_body_exited(body:Node2D):
	if body.has_method("set_is_in_mist"):
		body.set_is_in_mist(false)

