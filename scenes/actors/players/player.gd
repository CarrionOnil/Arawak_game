extends CharacterBody2D

@export var speed := 60.0 #how fast player moves

func get_input():
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	
func _physics_process(delta):
	get_input()
	move_and_slide()
	
	if velocity.x != 0:                        # NEW: set flip once, for side AND diagonals
		$AnimatedSprite2D.flip_h = velocity.x < 0

	if velocity.x != 0 and velocity.y > 0:     # CHANGED: clearer condition
		$AnimatedSprite2D.play("walk_down_side")
	elif velocity.x != 0 and velocity.y < 0:   # NEW: the up-diagonal
		$AnimatedSprite2D.play("walk_up_side")
	elif velocity.x != 0:
		$AnimatedSprite2D.play("walk_side")    # flip line moved up
	elif velocity.y > 0:
		$AnimatedSprite2D.play("walk_down")
	elif velocity.y < 0:
		$AnimatedSprite2D.play("walk_up")
	else:
		$AnimatedSprite2D.stop()
