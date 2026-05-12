extends Area3D
class_name HazardBody
## Instant-kill zone. Any Player body entering triggers respawn.
## Attach as a child of the hazard geometry (arm, press, pit) so it moves
## with the parent. The CollisionShape3D child defines the kill volume.

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		(body as Player).respawn()
