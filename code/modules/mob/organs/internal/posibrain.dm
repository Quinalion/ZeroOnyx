/obj/item/organ/internal/posibrain
	name = "positronic brain"
	desc = "A cube of shining metal, four inches to a side and covered in shallow grooves."
	icon = 'icons/mob/human_races/organs/cyber.dmi'
	icon_state = "posibrain"
	organ_tag = BP_POSIBRAIN
	parent_organ = BP_CHEST
	vital = 0
	force = 1.0
	w_class = ITEM_SIZE_NORMAL
	throwforce = 1.0
	throw_range = 5
	origin_tech = list(TECH_ENGINEERING = 4, TECH_MATERIAL = 4, TECH_BLUESPACE = 2, TECH_DATA = 4)
	attack_verb = list("attacked", "slapped", "whacked")

	relative_size = 60

	var/mob/living/silicon/sil_brainmob/brainmob = null

	var/searching = 0
	var/askDelay = 10 * 60 * 1
	req_access = list(access_robotics)

	var/list/shackled_verbs = list(
		/obj/item/organ/internal/posibrain/proc/show_laws_brain,
		/obj/item/organ/internal/posibrain/proc/brain_checklaws
		)
	var/shackle = 0

/obj/item/organ/internal/posibrain/New(mob/living/carbon/H)
	..()
	if(!brainmob && H)
		init(H)
	robotize()
	unshackle()
	update_icon()

/obj/item/organ/internal/posibrain/proc/init(mob/living/carbon/H)
	brainmob = new(src)

	if(istype(H))
		brainmob.SetName(H.real_name)
		brainmob.real_name = H.real_name
		brainmob.dna = H.dna.Clone()
		brainmob.add_language("Encoded Audio Language")

/obj/item/organ/internal/posibrain/Destroy()
	if(brainmob)
		QDEL_NULL(brainmob)

	return ..()

/obj/item/organ/internal/posibrain/attack_self(mob/user as mob)
	if(brainmob && !brainmob.key && searching == 0)
		//Start the process of searching for a new user.
		to_chat(user, SPAN("notice", "You carefully locate the manual activation switch and start the positronic brain's boot process."))
		icon_state = "posibrain-searching"
		src.searching = 1
		var/datum/ghosttrap/G = get_ghost_trap("positronic brain")
		G.request_player(brainmob, "Someone is requesting a personality for a positronic brain.", 60 SECONDS)
		spawn(600)
			reset_search()

/obj/item/organ/internal/posibrain/proc/reset_search() //We give the players sixty seconds to decide, then reset the timer.
	if(src.brainmob && src.brainmob.key) return

	src.searching = 0
	icon_state = "posibrain"

	var/turf/T = get_turf_or_move(src.loc)
	for (var/mob/M in viewers(T))
		M.show_message(SPAN("notice", "The positronic brain buzzes quietly, and the golden lights fade away. Perhaps you could try again?"))

/obj/item/organ/internal/posibrain/attack_ghost(mob/observer/ghost/user)
	if(!searching || (src.brainmob && src.brainmob.key))
		return

	var/datum/ghosttrap/G = get_ghost_trap("positronic brain")
	if(!G.assess_candidate(user))
		return
	var/response = alert(user, "Are you sure you wish to possess this [src]?", "Possess [src]", "Yes", "No")
	if(response == "Yes")
		G.transfer_personality(user, brainmob)
	return

/obj/item/organ/internal/posibrain/_examine_text(mob/user)
	. = ..()

	var/msg = "[SPAN("info", "*---------*")]\nThis is \icon[src] \a <EM>[src]</EM>!\n[desc]\n"

	if(shackle)
		msg += SPAN("warning", "It is clamped in a set of metal straps with a complex digital lock.")
		msg += "\n"

	var/extra_info = ""

	if(src.brainmob && src.brainmob.key)
		switch(src.brainmob.stat)
			if(CONSCIOUS)
				if(!src.brainmob.client)
					extra_info += "It appears to be in stand-by mode." //afk
			if(UNCONSCIOUS)
				extra_info += SPAN("warning", "It doesn't seem to be responsive.")
			if(DEAD)
				extra_info += SPAN("deadsay", "It appears to be completely inactive.")
	else
		extra_info += SPAN("deadsay", "It appears to be completely inactive.")
	extra_info += "\n"

	msg += SPAN("warning", "[extra_info]")
	msg += SPAN("info", "*---------*")
	. += "\n[msg]"
	return

/obj/item/organ/internal/posibrain/emp_act(severity)
	if(!src.brainmob)
		return
	else
		switch(severity)
			if(1)
				src.brainmob.emp_damage += rand(20,30)
			if(2)
				src.brainmob.emp_damage += rand(10,20)
			if(3)
				src.brainmob.emp_damage += rand(0,10)
	..()

/obj/item/organ/internal/posibrain/proc/PickName()
	src.brainmob.SetName("[pick(list("PBU","HIU","SINA","ARMA","OSI"))]-[random_id(type,100,999)]")
	src.brainmob.real_name = src.brainmob.name

/obj/item/organ/internal/posibrain/proc/shackle(given_lawset)
	if(given_lawset)
		brainmob.laws = given_lawset
	shackle = 1
	verbs |= shackled_verbs
	update_icon()
	return 1

/obj/item/organ/internal/posibrain/proc/unshackle()
	shackle = 0
	verbs -= shackled_verbs
	update_icon()

/obj/item/organ/internal/posibrain/update_icon()
	if(src.brainmob && src.brainmob.key)
		icon_state = "posibrain-occupied"
	else
		icon_state = "posibrain"

	overlays.Cut()
	if(shackle)
		overlays |= image('icons/obj/assemblies.dmi', "posibrain-shackles")

/obj/item/organ/internal/posibrain/proc/transfer_identity(mob/living/carbon/H)
	if(H && H.mind)
		brainmob.set_stat(CONSCIOUS)
		H.mind.transfer_to(brainmob)
		brainmob.SetName(H.real_name)
		brainmob.real_name = H.real_name
		brainmob.dna = H.dna.Clone()
		brainmob.show_laws(brainmob)

	update_icon()

	to_chat(brainmob, SPAN("notice", "You feel slightly disoriented. That's normal when you're just \a [initial(src.name)]."))
	callHook("debrain", list(brainmob))

/obj/item/organ/internal/posibrain/removed(mob/living/user, drop_organ = TRUE, detach = TRUE)
	if(!istype(owner))
		return ..()

	if(name == initial(name))
		SetName("\the [owner.real_name]'s [initial(name)]")

	transfer_identity(owner)

	..()

/obj/item/organ/internal/posibrain/replaced(mob/living/target)

	if(!..()) return 0

	if(target.key)
		target.ghostize()

	if(brainmob)
		if(brainmob.mind)
			brainmob.mind.transfer_to(target)
		else
			target.key = brainmob.key

	return 1

/*
	This is for law stuff directly. This is how a human mob will be able to communicate with the posi_brainmob in the
	posibrain organ for laws when the posibrain organ is shackled.
*/
/obj/item/organ/internal/posibrain/proc/show_laws_brain()
	set category = "Shackle"
	set name = "Show Laws"
	set src in usr

	brainmob.show_laws(owner)

/obj/item/organ/internal/posibrain/proc/brain_checklaws()
	set category = "Shackle"
	set name = "State Laws"
	set src in usr


	brainmob.open_subsystem(/datum/nano_module/law_manager, usr)
