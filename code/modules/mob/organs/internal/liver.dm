
/obj/item/organ/internal/liver
	name = "liver"
	icon_state = "liver"
	w_class = ITEM_SIZE_SMALL
	organ_tag = BP_LIVER
	parent_organ = BP_CHEST
	min_bruised_damage = 25
	min_broken_damage = 45 // Also the amount of toxic damage it can store
	max_damage = 70
	relative_size = 60
	var/tox_filtering = 0

/obj/item/organ/internal/liver/robotize()
	. = ..()
	SetName("hepatic filter")
	icon_state = "liver-prosthetic"
	dead_icon = "liver-prosthetic-br"

/obj/item/organ/internal/liver/proc/store_tox(amount) // Store toxins up to min_broken_damage, return excessive toxins
	var/cap_toxins = max(0, min_broken_damage - tox_filtering)
	. = max(0, amount - cap_toxins)
	tox_filtering += amount - .

/obj/item/organ/internal/liver/think()

	..()
	if(!owner)
		return
	if(isundead(owner))
		return

	if (germ_level > INFECTION_LEVEL_ONE)
		if(prob(1))
			to_chat(owner, SPAN("danger", "Your skin itches."))
	if (germ_level > INFECTION_LEVEL_TWO)
		if(prob(1))
			spawn owner.vomit()

	//Detox can heal small amounts of damage
	if (damage < max_damage && !owner.chem_effects[CE_TOXIN])
		heal_damage(0.2 * owner.chem_effects[CE_ANTITOX])

	// Get the effectiveness of the liver.
	var/filter_effect = 3
	if(is_bruised())
		filter_effect -= 1
	if(is_broken())
		filter_effect -= 2
	// Robotic organs filter better but don't get benefits from dylovene for filtering.
	if(BP_IS_ROBOTIC(src))
		filter_effect += 1
	else if(owner.chem_effects[CE_ANTITOX])
		filter_effect += 1
	// If you're not filtering well, you're going to take damage. Even more if you have alcohol in you.
	if(filter_effect < 2)
		owner.adjustToxLoss(0.5 * max(2 - filter_effect, 0) * (1 + owner.chem_effects[CE_ALCOHOL_TOXIC] + 0.5 * owner.chem_effects[CE_ALCOHOL]))
	else
		// Get rid of some stored toxins.
		tox_filtering = max(damage, (tox_filtering - filter_effect * 0.1))

	if((tox_filtering > (min_broken_damage * 0.5)) && prob(tox_filtering * 0.1))
		to_chat(src, SPAN("warning", "You feel nauseous..."))

	if(owner.chem_effects[CE_ALCOHOL_TOXIC])
		take_internal_damage(store_tox(owner.chem_effects[CE_ALCOHOL_TOXIC]/2), prob(90)) // Chance to warn them

	// Heal a bit if needed and we're not busy. This allows recovery from low amounts of toxloss.
	if(!owner.chem_effects[CE_ALCOHOL] && !owner.chem_effects[CE_TOXIN] && owner.radiation <= SAFE_RADIATION_DOSE && damage > 0)
		if(damage < min_broken_damage)
			heal_damage(0.2)
		if(damage < min_bruised_damage)
			heal_damage(0.3)

	//Blood regeneration if there is some space
	owner.regenerate_blood(0.1 + owner.chem_effects[CE_BLOODRESTORE])

	// Blood loss or liver damage make you lose nutriments
	var/blood_volume = owner.get_blood_volume()
	if(blood_volume < BLOOD_VOLUME_SAFE || is_bruised())
		if(owner.nutrition >= 300)
			owner.nutrition -= 10
		else if(owner.nutrition >= 200)
			owner.nutrition -= 3
