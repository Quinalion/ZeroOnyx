/datum/movement_handler/mob/multiz/proc/catwalk_check(turf/location)
	var/obj/structure/catwalk/C = locate() in location
	if(istype(C))
		return C.name
	return location.name

/datum/movement_handler/mob/multiz/DoMove(direction, mob/mover, is_external)
	if(!(direction & (UP|DOWN)))
		return MOVEMENT_PROCEED

	var/turf/destination = (direction == UP) ? GetAbove(mob) : GetBelow(mob)
	if(!destination)
		to_chat(mob, SPAN("notice", "There is nothing of interest in this direction."))
		return MOVEMENT_HANDLED

	var/turf/start = get_turf(mob)
	if(!start.CanZPass(mob, direction))
		var/blocked_message = catwalk_check(start)
		to_chat(mob, SPAN("warning", "\The [blocked_message] is in the way."))
		return MOVEMENT_HANDLED

	if(!destination.CanZPass(mob, direction))
		var/blocked_message = catwalk_check(destination)
		to_chat(mob, SPAN("warning", "You bump against \the [blocked_message]."))
		return MOVEMENT_HANDLED

	var/area/area = get_area(mob)
	if(direction == UP && area.has_gravity() && !mob.can_overcome_gravity())
		to_chat(mob, SPAN("warning", "Gravity stops you from moving upward."))
		return MOVEMENT_HANDLED

	for(var/atom/A in destination)
		if(!A.CanMoveOnto(mob, start, 1.5, direction))
			to_chat(mob, SPAN("warning", "\The [A] blocks you."))
			return MOVEMENT_HANDLED

	if(direction == UP && area.has_gravity() && mob.can_fall(FALSE, destination))
		to_chat(mob, SPAN("warning", "You see nothing to hold on to."))
		return MOVEMENT_HANDLED

	return MOVEMENT_PROCEED

//For ghosts and such
/datum/movement_handler/mob/multiz_connected/DoMove(direction, mob/mover, is_external)
	if(!(direction & (UP|DOWN)))
		return MOVEMENT_PROCEED

	var/turf/destination = (direction == UP) ? GetAbove(mob) : GetBelow(mob)
	if(!destination)
		to_chat(mob, SPAN("notice", "There is nothing of interest in this direction."))
		return MOVEMENT_HANDLED

	return MOVEMENT_PROCEED

/datum/movement_handler/deny_multiz/DoMove(direction, mob/mover, is_external)
	if(direction & (UP|DOWN))
		return MOVEMENT_HANDLED
	return MOVEMENT_PROCEED

/datum/movement_handler/deny_stairs/DoMove(direction, mob/mover, is_external)
	if (direction & (UP | DOWN))
		return MOVEMENT_PROCEED

	var/turf/destination = get_step(mover, direction)

	if (istype(destination, /turf/simulated/open))
		var/turf/below = get_step(destination, DOWN)

		if (locate(/obj/structure/stairs) in below)
			return MOVEMENT_HANDLED

		return MOVEMENT_PROCEED

	if (locate(/obj/structure/stairs) in destination)
		return MOVEMENT_HANDLED

	return MOVEMENT_PROCEED
