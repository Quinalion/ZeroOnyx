/obj/machinery/recharge_station
	name = "cyborg recharging station"
	desc = "A heavy duty rapid charging system, designed to quickly recharge cyborg power reserves."
	icon = 'icons/obj/objects.dmi'
	icon_state = "borgcharger0"
	density = 1
	anchored = 1
	idle_power_usage = 50 WATTS
	var/mob/living/occupant = null
	var/obj/item/cell/cell = null
	var/icon_update_tick = 0	// Used to rebuild the overlay only once every 10 ticks
	var/charging = 0

	var/charging_power			// W. Power rating used for charging the cyborg. 120 kW if un-upgraded
	var/restore_power_active	// W. Power drawn from APC when an occupant is charging. 40 kW if un-upgraded
	var/restore_power_passive	// W. Power drawn from APC when idle. 7 kW if un-upgraded
	var/weld_rate = 0			// How much brute damage is repaired per tick
	var/wire_rate = 0			// How much burn damage is repaired per tick

	var/weld_power_use = 2300	// power used per point of brute damage repaired. 2.3 kW ~ about the same power usage of a handheld arc welder
	var/wire_power_use = 500	// power used per point of burn damage repaired.

	component_types = list(
		/obj/item/circuitboard/recharge_station,
		/obj/item/stock_parts/manipulator = 2,
		/obj/item/stock_parts/capacitor = 2,
		/obj/item/cell/high,
		/obj/item/stack/cable_coil{amount = 5}
	)

/obj/machinery/recharge_station/Initialize()
	. = ..()
	update_icon()

/obj/machinery/recharge_station/proc/has_cell_power()
	return cell && cell.percent() > 0

/obj/machinery/recharge_station/Process()
	if(stat & (BROKEN))
		return
	if(!cell) // Shouldn't be possible, but sanity check
		return

	if((stat & NOPOWER) && !has_cell_power()) // No power and cell is dead.
		if(icon_update_tick)
			icon_update_tick = 0 //just rebuild the overlay once more only
			update_icon()
		return

	//First, draw from the internal power cell to recharge/repair/etc the occupant
	if(occupant)
		process_occupant()

	//Then, if external power is available, recharge the internal cell
	var/recharge_amount = 0
	if(!(stat & NOPOWER))
		// Calculating amount of power to draw
		recharge_amount = (occupant ? restore_power_active : restore_power_passive) * CELLRATE

		recharge_amount = cell.give(recharge_amount)
		use_power_oneoff(recharge_amount / CELLRATE)
	else
		cell.use(get_power_usage() * CELLRATE) //since the recharge station can still be on even with NOPOWER. Instead it draws from the internal cell.

	if(icon_update_tick >= 10)
		icon_update_tick = 0
	else
		icon_update_tick++

	if(occupant || recharge_amount)
		update_icon()

//Processes the occupant, drawing from the internal power cell if needed.
/obj/machinery/recharge_station/proc/process_occupant()
	// Check whether the mob is compatible
	if(!isrobot(occupant) && !ishuman(occupant))
		return

	// If we have repair capabilities, repair any damage.
	if(weld_rate && occupant.getBruteLoss() && cell.checked_use(weld_power_use * weld_rate * CELLRATE))
		occupant.adjustBruteLoss(-weld_rate)
	if(wire_rate && occupant.getFireLoss() && cell.checked_use(wire_power_use * wire_rate * CELLRATE))
		occupant.adjustFireLoss(-wire_rate)

	var/obj/item/cell/target
	if(isrobot(occupant))
		var/mob/living/silicon/robot/R = occupant
		target = R.cell
		if(R.module)
			R.module.respawn_consumable(R, charging_power * CELLRATE / 250) //consumables are magical, apparently
		// If we are capable of repairing damage, reboot destroyed components and allow them to be repaired for very large power spike.
		var/list/damaged = R.get_damaged_components(1,1,1)
		if(damaged.len && wire_rate && weld_rate)
			for(var/datum/robot_component/C in damaged)
				if((C.installed == -1) && cell.checked_use(100 KILO WATTS * CELLRATE))
					C.repair()

	if(ishuman(occupant))
		var/mob/living/carbon/human/H = occupant
		var/obj/item/organ/internal/cell/potato = H.internal_organs_by_name[BP_CELL]
		if(potato)
			target = potato.cell

		if((!target || target.percent() > 95) && istype(H.back,/obj/item/rig))
			var/obj/item/rig/R = H.back
			if(R.cell && !R.cell.fully_charged())
				target = R.cell

	if(target && !target.fully_charged())
		var/diff = min(target.maxcharge - target.charge, charging_power * CELLRATE) // Capped by charging_power / tick
		var/charge_used = cell.use(diff)
		target.give(charge_used)


/obj/machinery/recharge_station/_examine_text(mob/user)
	. = ..()
	. += "\nThe charge meter reads: [round(chargepercentage())]%"

/obj/machinery/recharge_station/proc/chargepercentage()
	if(!cell)
		return 0
	return cell.percent()

/obj/machinery/recharge_station/relaymove(mob/user as mob)
	if(user.stat)
		return
	go_out()
	return

/obj/machinery/recharge_station/emp_act(severity)
	if(occupant)
		occupant.emp_act(severity)
		go_out()
	if(cell)
		cell.emp_act(severity)
	..(severity)

/obj/machinery/recharge_station/attackby(obj/item/O as obj, mob/user as mob)
	if(!occupant)
		if(default_deconstruction_screwdriver(user, O))
			return
		if(default_deconstruction_crowbar(user, O))
			return
		if(default_part_replacement(user, O))
			return

	..()

/obj/machinery/recharge_station/RefreshParts()
	..()
	var/man_rating = 0
	var/cap_rating = 0

	for(var/obj/item/stock_parts/P in component_parts)
		if(iscapacitor(P))
			cap_rating += P.rating
		else if(ismanipulator(P))
			man_rating += P.rating
	cell = locate(/obj/item/cell) in component_parts

	charging_power = 40000 + 40000 * cap_rating
	restore_power_active = 10000 + 15000 * cap_rating
	restore_power_passive = 5000 + 1000 * cap_rating
	weld_rate = max(0, man_rating - 3)
	wire_rate = max(0, man_rating - 5)

	desc = initial(desc)
	desc += " Uses a dedicated internal power cell to deliver [charging_power]W when in use."
	if(weld_rate)
		desc += "<br>It is capable of repairing structural damage."
	if(wire_rate)
		desc += "<br>It is capable of repairing burn damage."

/obj/machinery/recharge_station/proc/build_overlays()
	overlays.Cut()
	switch(round(chargepercentage()))
		if(1 to 20)
			overlays += image('icons/obj/objects.dmi', "statn_c0")
		if(21 to 40)
			overlays += image('icons/obj/objects.dmi', "statn_c20")
		if(41 to 60)
			overlays += image('icons/obj/objects.dmi', "statn_c40")
		if(61 to 80)
			overlays += image('icons/obj/objects.dmi', "statn_c60")
		if(81 to 98)
			overlays += image('icons/obj/objects.dmi', "statn_c80")
		if(99 to 110)
			overlays += image('icons/obj/objects.dmi', "statn_c100")

/obj/machinery/recharge_station/update_icon()
	..()
	if(stat & BROKEN)
		icon_state = "borgcharger0"
		return

	if(occupant)
		if((stat & NOPOWER) && !has_cell_power())
			icon_state = "borgcharger2"
		else
			icon_state = "borgcharger1"
	else
		icon_state = "borgcharger0"

	if(icon_update_tick == 0)
		build_overlays()

/obj/machinery/recharge_station/Bumped(mob/living/silicon/robot/R)
	go_in(R)

/obj/machinery/recharge_station/proc/go_in(mob/M)


	if(occupant)
		return

	if(!hascell(M))
		return

	add_fingerprint(M)
	M.reset_view(src)
	M.forceMove(src)
	occupant = M
	update_icon()
	return 1

/obj/machinery/recharge_station/proc/hascell(mob/M)
	if(isrobot(M))
		var/mob/living/silicon/robot/R = M
		return (R.cell)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.isSynthetic()) // FBPs and IPCs
			return 1
		if(istype(H.back,/obj/item/rig))
			var/obj/item/rig/R = H.back
			return R.cell
		return H.internal_organs_by_name["cell"]
	return 0

/obj/machinery/recharge_station/proc/go_out()
	if(!occupant)
		return

	occupant.forceMove(loc)
	occupant.reset_view()
	occupant = null
	update_icon()

/obj/machinery/recharge_station/verb/move_eject()
	set category = "Object"
	set name = "Eject Recharger"
	set src in oview(1)

	if(usr.incapacitated())
		return

	go_out()
	add_fingerprint(usr)
	return

/obj/machinery/recharge_station/verb/move_inside()
	set category = "Object"
	set name = "Enter Recharger"
	set src in oview(1)

	go_in(usr)

/obj/machinery/recharge_station/MouseDrop_T(mob/target, mob/user)
	if(!CanMouseDrop(target, user))
		return
	if(!istype(target,/mob/living/silicon))
		return
	if(target.buckled)
		to_chat(user, SPAN("warning", "Unbuckle the subject before attempting to move them."))
		return
	go_in(target, user)
