/mob/living/Initialize()
	. = ..()
	if(stat == DEAD)
		add_to_dead_mob_list()
	else
		add_to_living_mob_list()

	if(give_ghost_proc_at_initialize)
		verbs |= /mob/living/proc/ghost

	if(controllable)
		GLOB.available_mobs_for_possess += src

	update_transform() // Some mobs may start bigger or smaller than normal.

//mob verbs are faster than object verbs. See mob/verb/examine.
/mob/living/verb/pulled(atom/movable/AM as mob|obj in oview(1))
	set name = "Pull"
	set category = "Object"

	if(AM.Adjacent(src))
		src.start_pulling(AM)

	return

//mob verbs are faster than object verbs. See above.
/mob/living/pointed(atom/A as mob|obj|turf in view())
	if(incapacitated())
		return 0
	if(status_flags & FAKEDEATH)
		return 0
	if(!..())
		return 0

	//Borgs and AI have their own message
	if(!issilicon(src))
		usr.visible_message("<b>[src]</b> points to [A]")
	return 1

// Check if current mob can push other mob or swap with it
// - other - the other mob to be pushed/swapped with
// - are_swaping - TRUE if current mob is intenting to swap, FALSE for pushing
// - passive - TRUE if current mob isn't initiator of swap/push
// Returns TRUE/FALSE
/mob/living/proc/can_move_mob(mob/living/other, are_swapping, passive)
	ASSERT(other)
	ASSERT(src != other)

	if(!passive)
		return other.can_move_mob(src, are_swapping, TRUE)

	var/context_flags = 0
	if(are_swapping)
		context_flags = other.mob_swap_flags
	else
		context_flags = other.mob_push_flags

	if(!mob_bump_flag) //nothing defined, go wild
		return TRUE

	if(mob_bump_flag & context_flags)
		return TRUE

	return a_intent == I_HELP && other.a_intent == I_HELP

/mob/living/canface()
	if(stat)
		return 0
	return ..()

/mob/living/Bump(atom/movable/AM, yes)
	spawn(0)
		if ((!( yes ) || now_pushing) || !loc)
			return
		if(!istype(AM, /mob/living/bot/mulebot))
			now_pushing = 1
		if (istype(AM, /mob/living))
			var/mob/living/tmob = AM

			for(var/mob/living/M in range(tmob, 1))
				if(tmob.pinned.len ||  ((M.pulling == tmob && ( tmob.restrained() && !( M.restrained() ) && M.stat == 0)) || locate(/obj/item/grab, tmob.grabbed_by.len)) )
					if ( !(world.time % 5) )
						to_chat(src, SPAN("warning", "[tmob] is restrained, you cannot push past"))
					now_pushing = 0
					return
				if( tmob.pulling == M && ( M.restrained() && !( tmob.restrained() ) && tmob.stat == 0) )
					if ( !(world.time % 5) )
						to_chat(src, SPAN("warning", "[tmob] is restraining [M], you cannot push past"))
					now_pushing = 0
					return

			//Leaping mobs just land on the tile, no pushing, no anything.
			if(status_flags & LEAPING)
				loc = tmob.loc
				status_flags &= ~LEAPING
				now_pushing = 0
				return

			if(can_swap_with(tmob)) // mutual brohugs all around!
				var/turf/oldloc = loc
				forceMove(tmob.loc)
				tmob.forceMove(oldloc)
				now_pushing = 0
				for(var/mob/living/carbon/metroid/metroid in view(1,tmob))
					if(metroid.Victim == tmob)
						metroid.UpdateFeed()
				return

			if(!can_move_mob(tmob, 0, 0))
				now_pushing = 0
				return
			if(src.restrained())
				now_pushing = 0
				return
			if(tmob.a_intent != I_HELP)
				if(istype(tmob, /mob/living/carbon/human) && (MUTATION_FAT in tmob.mutations))
					if(prob(40) && !(MUTATION_FAT in src.mutations))
						to_chat(src, SPAN("danger", "You fail to push [tmob]'s fat ass out of the way."))
						now_pushing = 0
						return
				if(tmob.r_hand && istype(tmob.r_hand, /obj/item/shield/riot))
					if(prob(99))
						now_pushing = 0
						return
				if(tmob.l_hand && istype(tmob.l_hand, /obj/item/shield/riot))
					if(prob(99))
						now_pushing = 0
						return
			if(!(tmob.status_flags & CANPUSH))
				now_pushing = 0
				return
			tmob.LAssailant = weakref(src)
		if(isobj(AM) && !AM.anchored)
			var/obj/I = AM
			if(!can_pull_size || can_pull_size < I.w_class)
				to_chat(src, SPAN("warning", "It won't budge!"))
				now_pushing = 0
				return

		now_pushing = 0
		spawn(0)
			..()
			var/saved_dir = AM.dir
			if (!istype(AM, /atom/movable) || AM.anchored)
				if(confused && prob(50) && m_intent == M_RUN && !lying)
					var/obj/machinery/disposal/D = AM
					if(istype(D) && !(D.stat & BROKEN))
						Weaken(6)
						playsound(AM, 'sound/effects/clang.ogg', 75)
						visible_message(SPAN_WARNING("[src] falls into \the [AM]!"), SPAN_WARNING("You fall into \the [AM]!"))
						if (client)
							client.perspective = EYE_PERSPECTIVE
							client.eye = src
						forceMove(AM)
					else
						Weaken(2)
						playsound(loc, SFX_FIGHTING_PUNCH, rand(80, 100), 1, -1)
						visible_message(SPAN_WARNING("[src] [pick("ran", "slammed")] into \the [AM]!"))
					src.apply_damage(5, BRUTE)
				return
			if (!now_pushing)
				now_pushing = 1

				var/t = get_dir(src, AM)
				if (istype(AM, /obj/structure/window))
					for(var/obj/structure/window/win in get_step(AM,t))
						now_pushing = 0
						return
				step(AM, t)
				if (istype(AM, /mob/living))
					var/mob/living/tmob = AM
					if(istype(tmob.buckled, /obj/structure/bed))
						if(!tmob.buckled.anchored)
							step(tmob.buckled, t)
				if(ishuman(AM))
					var/mob/living/carbon/human/M = AM
					for(var/obj/item/grab/G in M.grabbed_by)
						step(G.assailant, get_dir(G.assailant, AM))
						G.adjust_position()
				if(saved_dir)
					AM.set_dir(saved_dir)
				now_pushing = 0

/proc/swap_density_check(mob/swapper, mob/swapee)
	var/turf/T = get_turf(swapper)
	if(T)
		if(T.density)
			return 1
		for(var/atom/movable/A in T)
			if(A == swapper)
				continue
			if(!A.CanPass(swapee, T, 1))
				return 1

/mob/living/proc/can_swap_with(mob/living/tmob)
	if(!tmob)
		return 0
	if(tmob.buckled || buckled || tmob.anchored)
		return 0
	//BubbleWrap: people in handcuffs are always switched around as if they were on 'help' intent to prevent a person being pulled from being seperated from their puller
	if(!(tmob.mob_always_swap || (tmob.a_intent == I_HELP || tmob.restrained()) && (a_intent == I_HELP || src.restrained())))
		return 0
	if(!tmob.MayMove(src) || incapacitated())
		return 0

	if(swap_density_check(src, tmob))
		return 0

	if(swap_density_check(tmob, src))
		return 0

	return can_move_mob(tmob, 1, 0)

/mob/living/proc/updatehealth()
	if(status_flags & GODMODE)
		health = 100
		set_stat(CONSCIOUS)
	else
		health = maxHealth - getOxyLoss() - getToxLoss() - getFireLoss() - getBruteLoss() - getCloneLoss() - getHalLoss()


//This proc is used for mobs which are affected by pressure to calculate the amount of pressure that actually
//affects them once clothing is factored in. ~Errorage
/mob/living/proc/calculate_affecting_pressure(pressure)
	return


//sort of a legacy burn method for /electrocute, /shock, and the e_chair
/mob/living/proc/burn_skin(burn_amount)
	take_overall_damage(0, burn_amount)

/mob/living/proc/adjustBodyTemp(actual, desired, incrementboost)
	var/temperature = actual
	var/difference = abs(actual-desired)	//get difference
	var/increments = difference/10 //find how many increments apart they are
	var/change = increments*incrementboost	// Get the amount to change by (x per increment)

	// Too cold
	if(actual < desired)
		temperature += change
		if(actual > desired)
			temperature = desired
	// Too hot
	if(actual > desired)
		temperature -= change
		if(actual < desired)
			temperature = desired
//	if(istype(src, /mob/living/carbon/human))
//		log_debug("[src] ~ [src.bodytemperature] ~ [temperature]")

	return temperature


// ++++ROCKDTBEN++++ MOB PROCS -- Ask me before touching.
// Stop! ... Hammertime! ~Carn
// I touched them without asking... I'm soooo edgy ~Erro (added nodamage checks)

/mob/living/proc/getBruteLoss()
	return maxHealth - health

/mob/living/proc/adjustBruteLoss(amount)
	if(status_flags & GODMODE)
		return 0
	health = Clamp(health-amount, 0, maxHealth)

/mob/living/proc/getOxyLoss()
	return 0

/mob/living/proc/adjustOxyLoss(amount)
	return

/mob/living/proc/setOxyLoss(amount)
	return

/mob/living/proc/getToxLoss()
	return 0

/mob/living/proc/adjustToxLoss(amount)
	if(status_flags & GODMODE)
		return 0
	adjustBruteLoss(amount * 0.5)

/mob/living/proc/setToxLoss(amount)
	adjustBruteLoss((amount * 0.5)-getBruteLoss())

/mob/living/proc/getFireLoss()
	return

/mob/living/proc/adjustFireLoss(amount)
	if(status_flags & GODMODE)
		return 0
	adjustBruteLoss(amount * 0.5)

/mob/living/proc/setFireLoss(amount)
	adjustBruteLoss((amount * 0.5)-getBruteLoss())

/mob/living/proc/getHalLoss()
	return 0

/mob/living/proc/adjustHalLoss(amount)
	if(status_flags & GODMODE)
		return 0
	adjustBruteLoss(amount * 0.5)

/mob/living/proc/setHalLoss(amount)
	adjustBruteLoss((amount * 0.5)-getBruteLoss())

/mob/living/proc/getBrainLoss()
	return 0

/mob/living/proc/adjustBrainLoss(amount)
	return

/mob/living/proc/setBrainLoss(amount)
	return

/mob/living/proc/getCloneLoss()
	return 0

/mob/living/proc/setCloneLoss(amount)
	return

/mob/living/proc/adjustCloneLoss(amount)
	return

/mob/living/proc/getMaxHealth()
	var/result = maxHealth
	for(var/datum/modifier/M in modifiers)
		if(!isnull(M.max_health_flat))
			result += M.max_health_flat
	// Second loop is so we can get all the flat adjustments first before multiplying, otherwise the result will be different.
	for(var/datum/modifier/M in modifiers)
		if(!isnull(M.max_health_percent))
			result *= M.max_health_percent
	return result

/mob/living/proc/setMaxHealth(newMaxHealth)
	maxHealth = newMaxHealth

// ++++ROCKDTBEN++++ MOB PROCS //END

/mob/proc/get_contents()
	return

//Recursive function to find everything a mob is holding.
// TODO(rufus): refactor this function, storage param doesn't make sense as storage implements its own content return,
//   commented code is redundant, and gift storage handling is actually duplicated with return_inv().
/mob/living/get_contents(obj/item/storage/Storage = null)
	var/list/L = list()

	if(Storage) //If it called itself
		L += Storage.return_inv()

		//Leave this commented out, it will cause storage items to exponentially add duplicate to the list
		//for(var/obj/item/storage/S in Storage.return_inv()) //Check for storage items
		//	L += get_contents(S)

		for(var/obj/item/gift/G in Storage.return_inv()) //Check for gift-wrapped items
			L += G.gift
			if(istype(G.gift, /obj/item/storage))
				L += get_contents(G.gift)

		for(var/obj/item/smallDelivery/D in Storage.return_inv()) //Check for package wrapped items
			L += D.wrapped
			if(istype(D.wrapped, /obj/item/storage)) //this should never happen
				L += get_contents(D.wrapped)
		return L

	else

		L += src.contents
		for(var/obj/item/storage/S in src.contents)	//Check for storage items
			L += get_contents(S)

		for(var/obj/item/gift/G in src.contents) //Check for gift-wrapped items
			L += G.gift
			if(istype(G.gift, /obj/item/storage))
				L += get_contents(G.gift)

		for(var/obj/item/smallDelivery/D in src.contents) //Check for package wrapped items
			L += D.wrapped
			if(istype(D.wrapped, /obj/item/storage)) //this should never happen
				L += get_contents(D.wrapped)
		return L

/mob/living/proc/check_contents_for(A)
	var/list/L = src.get_contents()

	for(var/obj/B in L)
		if(B.type == A)
			return 1
	return 0

/mob/living/proc/can_inject(mob/user, target_zone)
	return 1

/mob/living/proc/get_organ_target()
	var/mob/shooter = src
	var/t = shooter:zone_sel.selecting
	if ((t in list( BP_EYES, BP_MOUTH )))
		t = BP_HEAD
	var/obj/item/organ/external/def_zone = ran_zone(t)
	return def_zone


// heal ONE external organ, organ gets randomly selected from damaged ones.
/mob/living/proc/heal_organ_damage(brute, burn)
	adjustBruteLoss(-brute)
	adjustFireLoss(-burn)
	src.updatehealth()

// damage ONE external organ, organ gets randomly selected from damaged ones.
/mob/living/proc/take_organ_damage(brute, burn, emp=0)
	adjustBruteLoss(brute)
	adjustFireLoss(burn)
	src.updatehealth()

// heal MANY external organs, in random order
/mob/living/proc/heal_overall_damage(brute, burn)
	adjustBruteLoss(-brute)
	adjustFireLoss(-burn)
	src.updatehealth()

// damage MANY external organs, in random order
/mob/living/proc/take_overall_damage(brute, burn, used_weapon = null)
	adjustBruteLoss(brute)
	adjustFireLoss(burn)
	src.updatehealth()

/mob/living/proc/restore_all_organs(ignore_prosthetic_prefs = FALSE)
	return

/mob/living/update_gravity(has_gravity)
	if(has_gravity)
		stop_floating()
	else
		start_floating()

/mob/living/proc/revive(ignore_prosthetic_prefs = FALSE)
	rejuvenate(ignore_prosthetic_prefs)
	if(buckled)
		buckled.unbuckle_mob()
	if(iscarbon(src))
		var/mob/living/carbon/C = src

		if(C.handcuffed && !initial(C.handcuffed))
			C.drop(C.handcuffed, force = TRUE)
		C.handcuffed = initial(C.handcuffed)
	BITSET(hud_updateflag, HEALTH_HUD)
	BITSET(hud_updateflag, STATUS_HUD)
	BITSET(hud_updateflag, LIFE_HUD)
	ExtinguishMob()
	fire_stacks = 0

/mob/living/proc/rejuvenate(ignore_prosthetic_prefs = FALSE)
	if(reagents)
		reagents.clear_reagents()

	// shut down various types of badness
	setToxLoss(0)
	setOxyLoss(0)
	setCloneLoss(0)
	setBrainLoss(0)
	SetParalysis(0)
	SetStunned(0)
	SetWeakened(0)

	// shut down ongoing problems
	radiation = SPACE_RADIATION
	bodytemperature = 20 CELSIUS
	sdisabilities = 0
	disabilities = 0

	// fix blindness and deafness
	blinded = 0
	eye_blind = 0
	eye_blurry = 0
	ear_deaf = 0
	ear_damage = 0
	heal_overall_damage(getBruteLoss(), getFireLoss())

	// fix all of our organs
	restore_all_organs(ignore_prosthetic_prefs)

	// remove the character from the list of the dead
	if(stat == DEAD)
		switch_from_dead_to_living_mob_list()
		timeofdeath = 0

	// restore us to conciousness
	set_stat(CONSCIOUS)

	// finally update health to make everything work correctly
	updatehealth()

	// make the icons look correct
	regenerate_icons()

	BITSET(hud_updateflag, HEALTH_HUD)
	BITSET(hud_updateflag, STATUS_HUD)
	BITSET(hud_updateflag, LIFE_HUD)

	failed_last_breath = 0 //So mobs that died of oxyloss don't revive and have perpetual out of breath.
	reload_fullscreen()
	return

/mob/living/proc/UpdateDamageIcon()
	return


/mob/living/proc/Examine_OOC()
	set name = "Examine Meta-Info (OOC)"
	set category = "OOC"
	set src in view()

	if(config.character_setup.allow_metadata)
		if(client)
			to_chat(usr, "[src]'s Metainfo:<br>[client.prefs.metadata]")
		else
			to_chat(usr, "[src] does not have any stored infomation!")
	else
		to_chat(usr, "OOC Metadata is not supported by this server!")

	return

/mob/living/Move(a, b, flag)
	if(buckled)
		return

	if(get_dist(src, pulling) > 1)
		stop_pulling()

	var/turf/old_loc = get_turf(src)

	if(lying)
		pull_sound = SFX_PULL_BODY
	else
		pull_sound = null

	. = ..()

	if(. && pulling)
		handle_pulling_after_move(old_loc)

	if(s_active && !(s_active in contents) && get_turf(s_active) != get_turf(src))
		s_active.close(src)

	if(update_metroids)
		for(var/mob/living/carbon/metroid/M in view(1, src))
			M.UpdateFeed()

/mob/living/proc/can_pull()
	if(!moving)
		return FALSE
	if(pulling.anchored)
		return FALSE
	if(!isturf(pulling.loc))
		return FALSE
	if(restrained())
		return FALSE

	if(get_dist(src, pulling) > 2)
		return FALSE

	if(pulling.z != z)
		if(pulling.z < z)
			return FALSE
		var/turf/T = GetAbove(src)
		if(!isopenspace(T))
			return FALSE
	return TRUE

/mob/living/proc/handle_pulling_after_move(turf/old_loc)
	if(!pulling)
		return

	if(!can_pull())
		stop_pulling()
		return

	if(pulling.loc == loc || pulling.loc == old_loc)
		return

	if(!isliving(pulling))
		step_glide(pulling, get_dir(pulling.loc, old_loc), glide_size)
	else
		var/mob/living/M = pulling
		if(M.grabbed_by.len)
			if(prob(75))
				var/obj/item/grab/G = pick(M.grabbed_by)
				if(istype(G))
					M.visible_message(SPAN_WARNING("[G.affecting] has been pulled from [G.assailant]'s grip by [src]!"), SPAN_WARNING("[G.affecting] has been pulled from your grip by [src]!"))
					qdel(G)
		if(!M.grabbed_by.len)
			M.handle_pull_damage(src)

			var/atom/movable/t = M.pulling
			M.stop_pulling()
			step_glide(M, get_dir(pulling.loc, old_loc), glide_size)
			if(t)
				M.start_pulling(t)

	handle_dir_after_pull()

	if(m_intent == M_RUN && pulling.pull_sound && (world.time - last_pull_sound) > 1 SECOND)
		last_pull_sound = world.time
		playsound(pulling, pulling.pull_sound, rand(50, 75), TRUE)

/mob/living/proc/handle_dir_after_pull()
	if(!pulling)
		return
	if(isobj(pulling))
		var/obj/O = pulling
		// Hacky check to know if you can pass through the closet
		if(istype(O, /obj/structure/closet) && !O.density)
			return set_dir(get_dir(src, pulling))
		if(O.pull_slowdown >= PULL_SLOWDOWN_MEDIUM)
			return set_dir(get_dir(src, pulling))
		else if(O.pull_slowdown == PULL_SLOWDOWN_WEIGHT && O.w_class >= ITEM_SIZE_HUGE)
			return set_dir(get_dir(src, pulling))
	if(isliving(pulling))
		var/mob/living/L = pulling
		// If pulled mob was bigger than us, we morelike will turn
		// I made additional check in case if someone want a hand walk
		if(L.mob_size > mob_size || L.lying)
			return set_dir(get_dir(src, pulling))

/mob/living/proc/handle_pull_damage(mob/living/puller)
	var/area/A = get_area(src)
	if(!A.has_gravity)
		return
	var/turf/location = get_turf(src)
	if(lying && prob(getBruteLoss() / 6))
		location.add_blood(src)
		if(prob(25))
			adjustBruteLoss(1)
			visible_message(SPAN("danger", "\The [src]'s [src.isSynthetic() ? "state worsens": "wounds open more"] from being dragged!"))
			. = TRUE
	if(pull_damage())
		if(prob(25))
			adjustBruteLoss(2)
			visible_message(SPAN("danger", "\The [src]'s [src.isSynthetic() ? "state worsens" : "wounds worsen"] terribly from being dragged!"))
			location.add_blood(src)
			if(ishuman(src))
				var/mob/living/carbon/human/H = src
				if(round(H.vessel.get_reagent_amount(/datum/reagent/blood)) > 0)
					H.vessel.remove_reagent(/datum/reagent/blood, 1)
			. = TRUE

/mob/living/verb/resist()
	set name = "Resist"
	set category = "IC"

	if(!incapacitated(INCAPACITATION_KNOCKOUT) && canClick())
		setClickCooldown(20)
		resist_grab()
		if(!weakened)
			process_resist()

/mob/living/proc/process_resist()
	//Getting out of someone's inventory.
	if(istype(src.loc, /obj/item/holder))
		escape_inventory(src.loc)
		return

	//unbuckling yourself
	if(buckled)
		spawn() escape_buckle()
		return TRUE

	//Breaking out of a locker?
	if(src.loc && (istype(src.loc, /obj/structure/closet)) )
		var/obj/structure/closet/closet = loc
		spawn() closet.mob_breakout(src)
		return TRUE

	//Trying to escape from abductors?
	if(src.loc && (istype(src.loc, /obj/machinery/abductor/experiment)))
		var/obj/machinery/abductor/experiment/experiment = loc
		spawn() experiment.mob_breakout(src)
		return TRUE

	//Trying to escape from Spider?
	if(src.loc && (istype(src.loc, /obj/structure/spider/cocoon)))
		var/obj/structure/spider/cocoon/cocoon = loc
		spawn() cocoon.mob_breakout(src)
		return TRUE

/mob/living/proc/escape_inventory(obj/item/holder/H)
	if(H != src.loc) return

	var/mob/M = H.loc //Get our mob holder (if any).

	if(istype(M))
		M.drop(H)
		to_chat(M, SPAN("warning", "\The [H] wriggles out of your grip!"))
		to_chat(src, SPAN("warning", "You wriggle out of \the [M]'s grip!"))

		// Update whether or not this mob needs to pass emotes to contents.
		for(var/atom/A in M.contents)
			if(istype(A,/mob/living/simple_animal/borer) || istype(A,/obj/item/holder))
				return
		M.status_flags &= ~PASSEMOTES
	else if(istype(H.loc,/obj/item/clothing/accessory/holster))
		var/obj/item/clothing/accessory/holster/holster = H.loc
		if(holster.holstered == H)
			holster.clear_holster()
		to_chat(src, SPAN("warning", "You extricate yourself from \the [holster]."))
		H.forceMove(get_turf(H))
	else if(istype(H.loc,/obj))
		to_chat(src, SPAN("warning", "You struggle free of \the [H.loc]."))
		H.forceMove(get_turf(H))

	if(loc != H)
		qdel(H)

/mob/living/proc/escape_buckle()
	if(buckled)
		if(buckled.can_buckle)
			buckled.user_unbuckle_mob(src)
		else
			to_chat(usr, SPAN("warning", "You can't seem to escape from \the [buckled]!"))
			return

/mob/living/proc/resist_grab()
	var/resisting = 0
	for(var/obj/item/grab/G in grabbed_by)
		resisting++
		G.handle_resist()
	if(resisting)
		visible_message(SPAN("danger", "[src] resists!"))

/mob/living/verb/lay_down()
	set name = "Rest"
	set category = "IC"

	if(!incapacitated(INCAPACITATION_KNOCKOUT) && canClick())
		setClickCooldown(3)
		resting = !resting
		update_canmove()
		to_chat(src, SPAN("notice", "You are now [resting ? "resting" : "getting up"]."))

//called when the mob receives a bright flash
/mob/living/flash_eyes(intensity = FLASH_PROTECTION_MODERATE, override_blindness_check = FALSE, affect_silicon = FALSE, visual = FALSE, type = /obj/screen/fullscreen/flash, effect_duration = 25)
	if(override_blindness_check || !(disabilities & BLIND))
		overlay_fullscreen("flash", type)
		spawn(effect_duration)
			if(src)
				clear_fullscreen("flash", 25)
		return 1

/mob/living/proc/cannot_use_vents()
	if(mob_size > MOB_SMALL)
		return "You can't fit into that vent."
	return null

/mob/living/proc/has_brain()
	return 1

/mob/living/proc/has_eyes()
	return 1

/mob/living/proc/slip(slipped_on, stun_duration = 8)
	return 0

/mob/living/proc/slip_on_obj(/obj/slipped_on, stun_duration = 8, slip_dist = 0)
	return 0

/mob/living/carbon/drop(obj/item/W, atom/Target = null, force = null)
	if(W in internal_organs)
		return
	. = ..()

//damage/heal the mob ears and adjust the deaf amount
/mob/living/adjustEarDamage(damage, deaf)
	ear_damage = max(0, ear_damage + damage)
	ear_deaf = max(0, ear_deaf + deaf)

//pass a negative argument to skip one of the variable
/mob/living/setEarDamage(damage = null, deaf = null)
	if(!isnull(damage))
		ear_damage = damage
	if(!isnull(deaf))
		ear_deaf = deaf

/mob/proc/can_be_possessed_by(mob/observer/ghost/possessor)
	return istype(possessor) && possessor.client

/mob/living/can_be_possessed_by(mob/observer/ghost/possessor)
	if(!..())
		return 0
	if(!possession_candidate)
		to_chat(possessor, SPAN("warning", "That animal cannot be possessed."))
		return 0
	if(jobban_isbanned(possessor, "Animal"))
		to_chat(possessor, SPAN("warning", "You are banned from animal roles."))
		return 0
	if(!possessor.MayRespawn(1,ANIMAL_SPAWN_DELAY))
		return 0
	return 1

/mob/living/proc/do_possession(mob/observer/ghost/possessor)

	if(!(istype(possessor) && possessor.ckey))
		return 0

	if(src.ckey || src.client)
		to_chat(possessor, SPAN("warning", "\The [src] already has a player."))
		return 0

	message_admins(SPAN("danger", "[key_name_admin(possessor)] has taken control of \the [src]."))
	log_admin("[key_name(possessor)] took control of \the [src].")
	src.ckey = possessor.ckey
	qdel(possessor)

	if(round_is_spooky(6)) // Six or more active cultists.
		to_chat(src, SPAN("notice", "You reach out with tendrils of ectoplasm and invade the mind of \the [src]..."))
		to_chat(src, "<b>You have assumed direct control of \the [src].</b>")
		to_chat(src, SPAN("notice", "Due to the spookiness of the round, you have taken control of the poor animal as an invading, possessing spirit - roleplay accordingly."))
		src.universal_speak = 1
		src.universal_understand = 1
		//src.cultify() // Maybe another time.
		return

	to_chat(src, "<b>You are now \the [src]!</b>")
	to_chat(src, SPAN("notice", "Remember to stay in character for a mob of this type!"))
	return 1

/mob/living/reset_layer()
	if(hiding)
		layer = HIDING_MOB_LAYER
	else
		..()

/mob/living/update_icons()
	if(auras)
		overlays |= auras

/mob/living/proc/add_aura(obj/aura/aura)
	LAZYDISTINCTADD(auras,aura)
	update_icons()
	return 1

/mob/living/proc/remove_aura(obj/aura/aura)
	LAZYREMOVE(auras,aura)
	update_icons()
	return 1

/mob/living/Destroy()
	if(auras)
		for(var/a in auras)
			remove_aura(a)
	if(mind)
		mind.set_current(null)
	QDEL_NULL(aiming)
	if(controllable)
		controllable = FALSE
		GLOB.available_mobs_for_possess -= src
	return ..()

/mob/living/proc/set_m_intent(intent)
	if(intent != M_WALK && intent != M_RUN)
		return 0
	m_intent = intent
	if(hud_used)
		if(hud_used.move_intent)
			hud_used.move_intent.icon_state = (intent == M_WALK ? "walking" : "running")

/mob/living/proc/melee_accuracy_mods()
	. = 0
	if(eye_blind)
		. += 75
	if(eye_blurry)
		. += 15
	if(confused)
		. += 30
	if(MUTATION_CLUMSY in mutations)
		. += 40

/mob/living/proc/ranged_accuracy_mods()
	. = 0
	if(jitteriness)
		. -= 2
	if(confused)
		. -= 2
	if(eye_blind)
		. -= 5
	if(eye_blurry)
		. -= 1
	if(MUTATION_CLUMSY in mutations)
		. -= 3

/mob/living/proc/nervous_system_failure()
	return FALSE

/mob/living/proc/needs_wheelchair()
	return FALSE

/mob/living/proc/seizure()
	set waitfor = 0
	sleep(rand(5,10))
	if(!paralysis && stat == CONSCIOUS)
		visible_message(SPAN("warning", "\The [src] starts having a seizure!"))
		Paralyse(rand(8,16))
		make_jittery(rand(150,200))
		adjustHalLoss(rand(50,60))

/mob/living/proc/on_ghost_possess()
	return

/mob/living/set_stat(new_stat)
	var/old_stat = stat
	. = ..()
	if(stat != old_stat)
		SEND_SIGNAL(src, SIGNAL_STAT_SET, src, old_stat, new_stat)
