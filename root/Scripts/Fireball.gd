extends Node2D
class_name Fireball

const DAMAGE: int = 10
const MAX_SPEED: float = 800.0
const ACCELERATION: float = 1200.0  # Units per second squared
const MAX_DISTANCE: float = 800.0  # Maximum distance the fireball can travel

@onready var particle_effect: GPUParticles2D = $FireParticles
@onready var color_rect: ColorRect = $ColorRect
@onready var collision_area: Area2D = $Area2D

var initial_flip: bool = false
var initial_position: Vector2
var direction: Vector2
var current_speed: float = 0.0
var initial_velocity: Vector2 = Vector2.ZERO

func init(player_velocity: Vector2) -> void:
	initial_velocity = player_velocity

func _ready():
	initial_position = global_position
	# Ensure we have a unique material instance
	if color_rect and color_rect.material:
		color_rect.material = color_rect.material.duplicate()
	set_direction(initial_flip)

func set_direction(flip: bool) -> void:
	initial_flip = flip
	if color_rect:
		color_rect.scale.x = -1 if flip else 1
		# Update shader parameter
		if color_rect.material:
			print("Setting shader flip to: ", flip)  # Debug print
			color_rect.material.set_shader_parameter("flip", flip)
	# When sprite is flipped (facing left), move left; when not flipped (facing right), move right
	direction = Vector2.LEFT if flip else Vector2.RIGHT
	# Set initial speed based on player's velocity in the direction of movement
	current_speed = max(50.0, abs(initial_velocity.dot(direction)))

func _physics_process(delta):
	# Accelerate the fireball
	current_speed = move_toward(current_speed, MAX_SPEED, ACCELERATION * delta)
	
	# Move the fireball
	position += direction * current_speed * delta
	
	# Check if we've traveled too far
	var distance_traveled = global_position.distance_to(initial_position)
	if distance_traveled > MAX_DISTANCE:
		queue_free()
		return

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		queue_free()
	elif body is TileMapLayer or body is StaticBody2D: # Check if it's a wall/ground
		queue_free()
