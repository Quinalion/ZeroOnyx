var/list/floor_light_cache = list()

/obj/machinery/floor_light
	name = "floor light"
	icon = 'icons/obj/machines/floor_light.dmi'
	icon_state = "base"
	desc = "A backlit floor panel."
	layer = ABOVE_TILE_LAYER
	anchored = 0
	use_power = POWER_USE_ACTIVE
	idle_power_usage = 2 WATTS
	active_power_usage = 20 WATTS
	power_channel = STATIC_LIGHT
	matter = list(MATERIAL_STEEL = 250, MATERIAL_GLASS = 250)

	var/on
	var/damaged
	var/default_light_max_bright = 0.75
	var/default_light_inner_range = 1
	var/default_light_outer_range = 3
	var/default_light_colour = "#ffffff"

/obj/machinery/floor_light/prebuilt
	anchored = 1

/obj/machinery/floor_light/attackby(obj/item/W, mob/user)
	if(isScrewdriver(W))
		anchored = !anchored
		visible_message(SPAN("notice", "\The [user] has [anchored ? "attached" : "detached"] \the [src]."))
	else if(isWelder(W) && (damaged || (stat & BROKEN)))
		var/obj/item/weldingtool/WT = W
		if(!WT.remove_fuel(0, user))
			to_chat(user, SPAN("warning", "\The [src] must be on to complete this task."))
			return
		playsound(src.loc, 'sound/items/Welder.ogg', 50, 1)
		if(!do_after(user, 20, src))
			return
		if(!src || !WT.isOn())
			return
		visible_message(SPAN("notice", "\The [user] has repaired \the [src]."))
		set_broken(FALSE)
		damaged = null
		update_brightness()
	else if(W.force && user.a_intent == "hurt")
		attack_hand(user)
	return

/obj/machinery/floor_light/attack_hand(mob/user)

	if(user.a_intent == I_HURT && !issmall(user))
		if(!isnull(damaged) && !(stat & BROKEN))
			visible_message(SPAN("danger", "\The [user] smashes \the [src]!"))
			playsound(src, SFX_BREAK_WINDOW, 70, 1)
			set_broken(TRUE)
		else
			visible_message(SPAN("danger", "\The [user] attacks \the [src]!"))
			playsound(src.loc, GET_SFX(SFX_GLASS_HIT), 75, 1)
			if(isnull(damaged)) damaged = 0
		update_brightness()
		return
	else

		if(!anchored)
			to_chat(user, SPAN("warning", "\The [src] must be screwed down first."))
			return

		if(stat & BROKEN)
			to_chat(user, SPAN("warning", "\The [src] is too damaged to be functional."))
			return

		if(stat & NOPOWER)
			to_chat(user, SPAN("warning", "\The [src] is unpowered."))
			return

		on = !on
		if(on)
			update_use_power(POWER_USE_ACTIVE)
		visible_message(SPAN("notice", "\The [user] turns \the [src] [on ? "on" : "off"]."))
		update_brightness()
		return

/obj/machinery/floor_light/Process()
	..()
	var/need_update
	if((!anchored || broken()) && on)
		update_use_power(POWER_USE_OFF)
		on = 0
		need_update = 1
	else if(use_power && !on)
		update_use_power(POWER_USE_OFF)
		need_update = 1
	if(need_update)
		update_brightness()

/obj/machinery/floor_light/proc/update_brightness()
	if(on && use_power == POWER_USE_ACTIVE)
		if(light_outer_range != default_light_outer_range || light_max_bright != default_light_max_bright || light_color != default_light_colour)
			set_light(default_light_max_bright, default_light_inner_range, default_light_outer_range, 2, default_light_colour)
	else
		update_use_power(POWER_USE_OFF)
		if(light_outer_range || light_max_bright)
			set_light(0)

	change_power_consumption((light_outer_range + light_max_bright) * 10, POWER_USE_ACTIVE)
	update_icon()

/obj/machinery/floor_light/update_icon()
	overlays.Cut()
	if(use_power && !broken())
		if(isnull(damaged))
			var/cache_key = "floorlight-[default_light_colour]"
			if(!floor_light_cache[cache_key])
				var/image/I = image("on")
				I.color = default_light_colour
				I.plane = plane
				I.layer = layer+0.001
				floor_light_cache[cache_key] = I
			overlays |= floor_light_cache[cache_key]
		else
			if(damaged == 0) //Needs init.
				damaged = rand(1,4)
			var/cache_key = "floorlight-broken[damaged]-[default_light_colour]"
			if(!floor_light_cache[cache_key])
				var/image/I = image("flicker[damaged]")
				I.color = default_light_colour
				I.plane = plane
				I.layer = layer+0.001
				floor_light_cache[cache_key] = I
			overlays |= floor_light_cache[cache_key]

/obj/machinery/floor_light/proc/broken()
	return (stat & (BROKEN|NOPOWER))

/obj/machinery/floor_light/ex_act(severity)
	switch(severity)
		if(1)
			qdel(src)
		if(2)
			if (prob(50))
				qdel(src)
			else if(prob(20))
				set_broken(TRUE)
			else
				if(isnull(damaged))
					damaged = 0
		if(3)
			if (prob(5))
				qdel(src)
			else if(isnull(damaged))
				damaged = 0
	return

/obj/machinery/floor_light/Destroy()
	var/area/A = get_area(src)
	if(A)
		on = 0
	. = ..()
