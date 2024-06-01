extends Projectile
class_name Grapple

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

var can_hook: bool = false
var is_hooked: bool = false
var hook_point: Vector2 = Vector2()
var chain_length: int = 0

var static_body_2d: StaticBody2D
var rigid_body_2d: RigidBody2D
var pin_joint_2d: PinJoint2D

var grapple_line: Line2D

func _ready():
	super._ready()
	grapple_line = collision_path.get_node("GrappleLine")
	grapple_line.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super._process(delta)
	if !is_hooked:
		if collision_path.is_colliding() and collision_path.get_collider() is TileMap:
			hook_point = collision_path.get_collision_point()
			can_hook = true
		else:
			can_hook = false
	else:
		collision_path.target_position = to_local(static_body_2d.global_position)
		chain_length = global_position.distance_to(static_body_2d.global_position)
		grapple_line.points = [position, collision_path.target_position]
		can_hook = false


func set_hook():
	is_hooked = true
	grapple_line.visible = true
	# Create and add StaticBody2D at hook point
	static_body_2d = StaticBody2D.new()
	var collision_shape_2d = CollisionShape2D.new()
	var rectangle_shape_2d = RectangleShape2D.new()
	rectangle_shape_2d.size = Vector2(10, 10)
	collision_shape_2d.shape = rectangle_shape_2d
	static_body_2d.add_child(collision_shape_2d)
	static_body_2d.global_position = hook_point
	get_parent().get_parent().add_child(static_body_2d)
	# Create and add RigidBody2D at player position
	rigid_body_2d = RigidBody2D.new()
	rigid_body_2d.collision_mask = 2
	var rigid_collision_shape_2d = CollisionShape2D.new()
	var circle_shape_2d = CircleShape2D.new()
	collision_shape_2d.debug_color = Color(1, 1, 0)
	rigid_collision_shape_2d.shape = circle_shape_2d
	rigid_collision_shape_2d.shape.radius = 1
	rigid_body_2d.add_child(rigid_collision_shape_2d)
	rigid_body_2d.global_position = global_position
	rigid_body_2d.linear_velocity = get_parent().velocity
	get_parent().get_parent().add_child(rigid_body_2d)
	# Connect RigidBody2D to StaticBody2D
	pin_joint_2d = PinJoint2D.new()
	get_parent().get_parent().add_child(pin_joint_2d)
	pin_joint_2d.global_position = static_body_2d.global_position
	pin_joint_2d.node_a = static_body_2d.get_path()
	pin_joint_2d.node_b = rigid_body_2d.get_path()


func unhook():
	is_hooked = false
	grapple_line.visible = false
	get_parent().get_parent().remove_child(static_body_2d)
	get_parent().get_parent().remove_child(rigid_body_2d)
	get_parent().get_parent().remove_child(pin_joint_2d)
