/datum/phenomena
	var/name = "Phenomena"
	var/cost = 0
	var/mob/living/deity/linked
	var/flags = 0
	var/cooldown = 0
	var/refresh_time = 0
	var/expected_type

/datum/phenomena/New(master)
	linked = master
	..()

/datum/phenomena/Destroy()
	linked.remove_phenomena(src)
	return ..()

/datum/phenomena/proc/Click(atom/target)
	if(can_activate(target))
		linked.take_cost(cost)
		refresh_time = world.time + cooldown
		activate(target)

/datum/phenomena/proc/can_activate(atom/target)
	if(!linked)
		return 0
	if(refresh_time > world.time)
		to_chat(linked, SPAN("warning", "\The [src] is still on cooldown for [round((refresh_time - world.time)/10)] more seconds!"))
		return 0

	if(!linked.form)
		to_chat(linked, SPAN("warning", "You must choose your form first!"))
		return 0

	if(expected_type && !istype(target,expected_type))
		return 0

	if(flags & PHENOMENA_NEAR_STRUCTURE)
		if(!linked.near_structure(target, 1))
			to_chat(linked, SPAN("warning", "\The [target] needs to be near a holy structure for your powers to work!"))
			return 0

	if(isliving(target))
		var/mob/living/L = target
		if(!L.mind || !L.client)
			if(!(flags & PHENOMENA_MUNDANE))
				to_chat(linked, SPAN("warning", "\The [L]'s mind is too mundane for you to influence."))
				return 0
		else
			if(linked.is_follower(target, silent = 1))
				if(!(flags & PHENOMENA_FOLLOWER))
					to_chat(linked, SPAN("warning", "You can't use [name] on the flock!"))
					return 0
			else if(!(flags & PHENOMENA_NONFOLLOWER))
				to_chat(linked, SPAN("warning", "You can't use [name] on non-believers."))
				return 0

	if(cost > linked.mob_uplink.uses)
		to_chat(linked, SPAN("warning", "You need more power to use [name] (Need [cost] power, have [linked.mob_uplink.uses])!"))
		return 0

	return 1

/datum/phenomena/proc/activate(target)
	to_chat(linked, SPAN("notice", "You use the phenomena [name] on \the [target]"))
	return
