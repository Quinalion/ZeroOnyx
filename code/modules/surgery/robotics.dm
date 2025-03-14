//Procedures in this file: Robotic surgery steps, organ removal, replacement. MMI insertion, synthetic organ repair.
//////////////////////////////////////////////////////////////////
//						ROBOTIC SURGERY							//
//////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////
//	generic robotic surgery step datum
//////////////////////////////////////////////////////////////////
/datum/surgery_step/robotics/
	can_infect = 0
/datum/surgery_step/robotics/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!istype(target))
		return 0
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if (affected == null)
		return 0
	if (affected.status & ORGAN_CUT_AWAY)
		return 0
	if (!BP_IS_ROBOTIC(affected))
		return 0
	return 1

//////////////////////////////////////////////////////////////////
//	 unscrew robotic limb hatch surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/robotics/unscrew_hatch
	allowed_tools = list(
		/obj/item/screwdriver = 100,
		/obj/item/material/coin = 50,
		/obj/item/material/kitchen/utensil/knife = 50
	)

	duration = CUT_DURATION

/datum/surgery_step/robotics/unscrew_hatch/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(..())
		var/obj/item/organ/external/affected = target.get_organ(target_zone)
		return affected && affected.hatch_state == HATCH_CLOSED && target_zone != BP_MOUTH

/datum/surgery_step/robotics/unscrew_hatch/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message("[user] starts to unscrew the maintenance hatch on [target]'s [affected.name] with \the [tool].", \
	"You start to unscrew the maintenance hatch on [target]'s [affected.name] with \the [tool].")
	..()

/datum/surgery_step/robotics/unscrew_hatch/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("notice", "[user] has opened the maintenance hatch on [target]'s [affected.name] with \the [tool]."), \
	SPAN("notice", "You have opened the maintenance hatch on [target]'s [affected.name] with \the [tool]."),)
	affected.hatch_state = HATCH_UNSCREWED

/datum/surgery_step/robotics/unscrew_hatch/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("warning", "[user]'s [tool.name] slips, failing to unscrew [target]'s [affected.name]."), \
	SPAN("warning", "Your [tool] slips, failing to unscrew [target]'s [affected.name]."))

//////////////////////////////////////////////////////////////////
//	 screw robotic limb hatch surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/robotics/screw_hatch
	allowed_tools = list(
		/obj/item/screwdriver = 100,
		/obj/item/material/coin = 50,
		/obj/item/material/kitchen/utensil/knife = 50
	)

	duration = CUT_DURATION

/datum/surgery_step/robotics/screw_hatch/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(..())
		var/obj/item/organ/external/affected = target.get_organ(target_zone)
		return affected && affected.hatch_state == HATCH_UNSCREWED && target_zone != BP_MOUTH

/datum/surgery_step/robotics/screw_hatch/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message("[user] starts to screw down the maintenance hatch on [target]'s [affected.name] with \the [tool].", \
	"You start to screw down the maintenance hatch on [target]'s [affected.name] with \the [tool].")
	..()

/datum/surgery_step/robotics/screw_hatch/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("notice", "[user] has screwed down the maintenance hatch on [target]'s [affected.name] with \the [tool]."), \
	SPAN("notice", "You have screwed down the maintenance hatch on [target]'s [affected.name] with \the [tool]."),)
	affected.hatch_state = HATCH_CLOSED

/datum/surgery_step/robotics/screw_hatch/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("warning", "[user]'s [tool.name] slips, failing to screw down [target]'s [affected.name]."), \
	SPAN("warning", "Your [tool] slips, failing to screw down [target]'s [affected.name]."))

//////////////////////////////////////////////////////////////////
//	open robotic limb surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/robotics/open_hatch
	allowed_tools = list(
		/obj/item/retractor = 100,
		/obj/item/crowbar = 100,
		/obj/item/material/kitchen/utensil = 50
	)

	duration = RETRACT_DURATION

/datum/surgery_step/robotics/open_hatch/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(..())
		var/obj/item/organ/external/affected = target.get_organ(target_zone)
		return affected && affected.hatch_state == HATCH_UNSCREWED

/datum/surgery_step/robotics/open_hatch/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message("[user] starts to pry open the maintenance hatch on [target]'s [affected.name] with \the [tool].",
	"You start to pry open the maintenance hatch on [target]'s [affected.name] with \the [tool].")
	..()

/datum/surgery_step/robotics/open_hatch/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("notice", "[user] opens the maintenance hatch on [target]'s [affected.name] with \the [tool]."), \
	 SPAN("notice", "You open the maintenance hatch on [target]'s [affected.name] with \the [tool]."))
	affected.hatch_state = HATCH_OPENED

/datum/surgery_step/robotics/open_hatch/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("warning", "[user]'s [tool.name] slips, failing to open the hatch on [target]'s [affected.name]."),
	SPAN("warning", "Your [tool] slips, failing to open the hatch on [target]'s [affected.name]."))

//////////////////////////////////////////////////////////////////
//	close robotic limb surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/robotics/close_hatch
	allowed_tools = list(
		/obj/item/retractor = 100,
		/obj/item/crowbar = 100,
		/obj/item/material/kitchen/utensil = 50
	)

	duration = RETRACT_DURATION

/datum/surgery_step/robotics/close_hatch/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(..())
		var/obj/item/organ/external/affected = target.get_organ(target_zone)
		return affected && affected.hatch_state == HATCH_OPENED && target_zone != BP_MOUTH

/datum/surgery_step/robotics/close_hatch/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message("[user] begins to close the hatch on [target]'s [affected.name] with \the [tool]." , \
	"You begin to close the hatch on [target]'s [affected.name] with \the [tool].")
	..()

/datum/surgery_step/robotics/close_hatch/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("notice", "[user] closes the hatch on [target]'s [affected.name] with \the [tool]."), \
	SPAN("notice", "You close the hatch on [target]'s [affected.name] with \the [tool]."))
	affected.hatch_state = HATCH_UNSCREWED
	affected.germ_level = 0

/datum/surgery_step/robotics/close_hatch/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("warning", "[user]'s [tool.name] slips, failing to close the hatch on [target]'s [affected.name]."),
	SPAN("warning", "Your [tool.name] slips, failing to close the hatch on [target]'s [affected.name]."))

//////////////////////////////////////////////////////////////////
//	robotic limb brute damage repair surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/robotics/repair_brute
	allowed_tools = list(
		/obj/item/weldingtool = 100,
		/obj/item/gun/energy/plasmacutter = 50
	)

	duration = ORGAN_FIX_DURATION

/datum/surgery_step/robotics/repair_brute/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(..())
		var/obj/item/organ/external/affected = target.get_organ(target_zone)
		if(isWelder(tool))
			var/obj/item/weldingtool/welder = tool
			if(!welder.isOn() || !welder.remove_fuel(1,user))
				return 0
		return affected && affected.hatch_state == HATCH_OPENED && ((affected.status & ORGAN_DISFIGURED) || affected.brute_dam > 0) && target_zone != BP_MOUTH

/datum/surgery_step/robotics/repair_brute/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message("[user] begins to patch damage to [target]'s [affected.name]'s support structure with \the [tool]." , \
	"You begin to patch damage to [target]'s [affected.name]'s support structure with \the [tool].")
	..()

/datum/surgery_step/robotics/repair_brute/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("notice", "[user] finishes patching damage to [target]'s [affected.name] with \the [tool]."), \
	SPAN("notice", "You finish patching damage to [target]'s [affected.name] with \the [tool]."))
	affected.heal_damage(rand(30,50),0,1,1)
	affected.status &= ~ORGAN_DISFIGURED

/datum/surgery_step/robotics/repair_brute/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("warning", "[user]'s [tool.name] slips, damaging the internal structure of [target]'s [affected.name]."),
	SPAN("warning", "Your [tool.name] slips, damaging the internal structure of [target]'s [affected.name]."))
	affected.take_external_damage(0, rand(5,10), 0, used_weapon = tool)
	//target.apply_damage(rand(5,10), BURN, affected)

//////////////////////////////////////////////////////////////////
//	robotic limb burn damage repair surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/robotics/repair_burn
	allowed_tools = list(
		/obj/item/stack/cable_coil = 100
	)

	duration = CONNECT_DURATION

/datum/surgery_step/robotics/repair_burn/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(..())
		var/obj/item/stack/cable_coil/C = tool
		var/obj/item/organ/external/affected = target.get_organ(target_zone)
		var/limb_can_operate = ((affected && affected.hatch_state == HATCH_OPENED) && ((affected.status & ORGAN_DISFIGURED) || affected.burn_dam > 0) && target_zone != BP_MOUTH)
		if(limb_can_operate)
			if(istype(C))
				if(!C.get_amount() >= 3)
					to_chat(user, SPAN("danger", "You need three or more cable pieces to repair this damage."))
					return SURGERY_FAILURE
				C.use(3)
				return 1
		return SURGERY_FAILURE

/datum/surgery_step/robotics/repair_burn/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message("[user] begins to splice new cabling into [target]'s [affected.name]." , \
	"You begin to splice new cabling into [target]'s [affected.name].")
	..()

/datum/surgery_step/robotics/repair_burn/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("notice", "[user] finishes splicing cable into [target]'s [affected.name]."), \
	SPAN("notice", "You finishes splicing new cable into [target]'s [affected.name]."))
	affected.heal_damage(0,rand(30,50),1,1)
	affected.status &= ~ORGAN_DISFIGURED

/datum/surgery_step/robotics/repair_burn/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("warning", "[user] causes a short circuit in [target]'s [affected.name]!"),
	SPAN("warning", "You cause a short circuit in [target]'s [affected.name]!"))
	target.apply_damage(rand(5,10), BURN, affected)

//////////////////////////////////////////////////////////////////
//	 artificial organ repair surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/robotics/fix_organ_robotic //For artificial organs
	allowed_tools = list(
	/obj/item/stack/nanopaste = 100,		\
	/obj/item/bonegel = 30, 		\
	/obj/item/screwdriver = 70,	\
	)

	duration = ORGAN_FIX_DURATION

/datum/surgery_step/robotics/fix_organ_robotic/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(!affected) return

	for(var/obj/item/organ/internal/I in affected.internal_organs)
		if(BP_IS_ROBOTIC(I) && I.damage > 0)
			if(I.surface_accessible)
				return TRUE
			if(affected.open() >= (affected.encased ? SURGERY_ENCASED : SURGERY_RETRACTED) || affected.hatch_state == HATCH_OPENED)
				return TRUE

/datum/surgery_step/robotics/fix_organ_robotic/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return
	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	for(var/obj/item/organ/I in affected.internal_organs)
		if(I && I.damage > 0)
			if(BP_IS_ROBOTIC(I))
				user.visible_message("[user] starts mending the damage to [target]'s [I.name]'s mechanisms.", \
				"You start mending the damage to [target]'s [I.name]'s mechanisms." )
	..()

/datum/surgery_step/robotics/fix_organ_robotic/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return
	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	for(var/obj/item/organ/I in affected.internal_organs)

		if(I && I.damage > 0)
			if(BP_IS_ROBOTIC(I))
				user.visible_message(SPAN("notice", "[user] repairs [target]'s [I.name] with [tool]."), \
				SPAN("notice", "You repair [target]'s [I.name] with [tool].") )
				I.damage = 0

/datum/surgery_step/robotics/fix_organ_robotic/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return
	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	user.visible_message(SPAN("warning", "[user]'s hand slips, gumming up the mechanisms inside of [target]'s [affected.name] with \the [tool]!"), \
	SPAN("warning", "Your hand slips, gumming up the mechanisms inside of [target]'s [affected.name] with \the [tool]!"))

	target.adjustToxLoss(5)
	affected.createwound(CUT, 5)

	for(var/obj/item/organ/internal/I in affected.internal_organs)
		if(I)
			I.take_internal_damage(rand(3,5), 0)

//////////////////////////////////////////////////////////////////
//	robotic organ detachment surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/robotics/detatch_organ_robotic

	allowed_tools = list(
	/obj/item/device/multitool = 100
	)

	duration = CUT_DURATION * 1.75

/datum/surgery_step/robotics/detatch_organ_robotic/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)

	if(!..())
		return 0

	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(affected.hatch_state != HATCH_OPENED)
		return 0

	target.op_stage.current_organ = null

	var/list/attached_organs = list()
	for(var/organ in target.internal_organs_by_name)
		var/obj/item/organ/I = target.internal_organs_by_name[organ]
		if(I && !(I.status & ORGAN_CUT_AWAY) && I.parent_organ == target_zone)
			attached_organs |= organ

	var/organ_to_remove = input(user, "Which organ do you want to prepare for removal?") as null|anything in attached_organs
	if(!organ_to_remove)
		return 0

	target.op_stage.current_organ = organ_to_remove

	return 1

/datum/surgery_step/robotics/detatch_organ_robotic/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message("[user] starts to decouple [target]'s [target.op_stage.current_organ] with \the [tool].", \
	"You start to decouple [target]'s [target.op_stage.current_organ] with \the [tool]." )
	..()

/datum/surgery_step/robotics/detatch_organ_robotic/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(SPAN("notice", "[user] has decoupled [target]'s [target.op_stage.current_organ] with \the [tool].") , \
	SPAN("notice", "You have decoupled [target]'s [target.op_stage.current_organ] with \the [tool]."))

	var/obj/item/organ/internal/I = target.internal_organs_by_name[target.op_stage.current_organ]
	if(I && istype(I))
		I.cut_away(user)

/datum/surgery_step/robotics/detatch_organ_robotic/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(SPAN("warning", "[user]'s hand slips, disconnecting \the [tool]."), \
	SPAN("warning", "Your hand slips, disconnecting \the [tool]."))

//////////////////////////////////////////////////////////////////
//	robotic organ transplant finalization surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/robotics/attach_organ_robotic
	allowed_tools = list(
		/obj/item/screwdriver = 100,
	)

	duration = CONNECT_DURATION

/datum/surgery_step/robotics/attach_organ_robotic/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(!(affected && (BP_IS_ROBOTIC(affected))))
		return 0
	if(affected.hatch_state != HATCH_OPENED)
		return 0

	target.op_stage.current_organ = null

	var/list/removable_organs = list()
	for(var/obj/item/organ/I in affected.implants)
		if ((I.status & ORGAN_CUT_AWAY) && (BP_IS_ROBOTIC(I)) && (I.parent_organ == target_zone))
			removable_organs |= I.organ_tag

	var/organ_to_replace = input(user, "Which organ do you want to reattach?") as null|anything in removable_organs
	if(!organ_to_replace)
		return 0

	target.op_stage.current_organ = organ_to_replace
	return ..()

/datum/surgery_step/robotics/attach_organ_robotic/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message("[user] begins reattaching [target]'s [target.op_stage.current_organ] with \the [tool].", \
	"You start reattaching [target]'s [target.op_stage.current_organ] with \the [tool].")
	..()

/datum/surgery_step/robotics/attach_organ_robotic/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(SPAN("notice", "[user] has reattached [target]'s [target.op_stage.current_organ] with \the [tool].") , \
	SPAN("notice", "You have reattached [target]'s [target.op_stage.current_organ] with \the [tool]."))

	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	for (var/obj/item/organ/I in affected.implants)
		if (I.organ_tag == target.op_stage.current_organ)
			I.status &= ~ORGAN_CUT_AWAY
			affected.implants -= I
			I.replaced(target, affected)
			break

/datum/surgery_step/robotics/attach_organ_robotic/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(SPAN("warning", "[user]'s hand slips, disconnecting \the [tool]."), \
	SPAN("warning", "Your hand slips, disconnecting \the [tool]."))

//////////////////////////////////////////////////////////////////
//	mmi installation surgery step
//////////////////////////////////////////////////////////////////
/datum/surgery_step/robotics/install_mmi
	allowed_tools = list(
	/obj/item/device/mmi = 100,
	)

	duration = ATTACH_DURATION

/datum/surgery_step/robotics/install_mmi/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)

	if(target_zone != BP_HEAD)
		return

	var/obj/item/device/mmi/M = tool
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(!(affected && affected.hatch_state == HATCH_OPENED))
		return 0

	if(!istype(M))
		return 0

	if(!M.brainmob || !M.brainmob.client || !M.brainmob.ckey || M.brainmob.stat >= DEAD)
		to_chat(user, SPAN("danger", "That brain is not usable."))
		return SURGERY_FAILURE

	if(!BP_IS_ROBOTIC(affected))
		to_chat(user, SPAN("danger", "You cannot install a computer brain into a meat body."))
		return SURGERY_FAILURE

	if(!target.should_have_organ(BP_BRAIN))
		to_chat(user, SPAN("danger", "You're pretty sure [target.species.name_plural] don't normally have a brain."))
		return SURGERY_FAILURE

	if(!isnull(target.internal_organs[BP_BRAIN]))
		to_chat(user, SPAN("danger", "Your subject already has a brain."))
		return SURGERY_FAILURE

	return 1

/datum/surgery_step/robotics/install_mmi/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message("[user] starts installing \the [tool] into [target]'s [affected.name].", \
	"You start installing \the [tool] into [target]'s [affected.name].")
	..()

/datum/surgery_step/robotics/install_mmi/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN("notice", "[user] has installed \the [tool] into [target]'s [affected.name]."), \
	SPAN("notice", "You have installed \the [tool] into [target]'s [affected.name]."))

	var/obj/item/device/mmi/M = tool
	var/obj/item/organ/internal/mmi_holder/holder = new(target, 1)
	target.internal_organs_by_name[BP_BRAIN] = holder
	user.drop(tool, holder)
	holder.stored_mmi = tool
	holder.update_from_mmi()

	if(M.brainmob && M.brainmob.mind)
		M.brainmob.mind.transfer_to(target)

/datum/surgery_step/robotics/install_mmi/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(SPAN("warning", "[user]'s hand slips."), \
	SPAN("warning", "Your hand slips."))
