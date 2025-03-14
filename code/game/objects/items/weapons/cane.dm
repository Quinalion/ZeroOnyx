/obj/item/cane
	name = "cane"
	desc = "A cane used by a true gentlemen. Or a clown."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "cane"
	item_state = "stick"
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	force = 8.5
	throwforce = 7.0
	mod_reach = 1.5
	mod_weight = 1.0
	mod_handy = 1.15
	w_class = ITEM_SIZE_NORMAL
	matter = list(MATERIAL_STEEL = 50)
	attack_verb = list("bludgeoned", "whacked", "disciplined", "thrashed")

/obj/item/cane/concealed
	var/concealed_blade

/obj/item/cane/concealed/New()
	..()
	var/obj/item/material/butterfly/switchblade/temp_blade = new(src)
	concealed_blade = temp_blade
	temp_blade.attack_self()

/obj/item/cane/concealed/attack_self(mob/user)
	if(concealed_blade)
		user.visible_message(SPAN("warning", "[user] has unsheathed \a [concealed_blade] from [src]!"), "You unsheathe \the [concealed_blade] from [src].")
		// Calling drop/put in hands to properly call item drop/pickup procs
		playsound(user.loc, 'sound/weapons/flipblade.ogg', 50, 1)
		user.replace_item(src, concealed_blade, force = TRUE)
		user.pick_or_drop(src)
		concealed_blade = null
		update_icon()
		user.update_inv_l_hand()
		user.update_inv_r_hand()
	else
		..()

/obj/item/cane/concealed/attackby(obj/item/material/butterfly/W, mob/user)
	if(!src.concealed_blade && istype(W))
		user.visible_message(SPAN("warning", "[user] has sheathed \a [W] into [src]!"), "You sheathe \the [W] into [src].")
		user.drop(W, src, TRUE)
		concealed_blade = W
		update_icon()
		user.update_inv_l_hand()
		user.update_inv_r_hand()
	else
		..()

/obj/item/cane/concealed/update_icon()
	if(concealed_blade)
		SetName(initial(name))
		icon_state = initial(icon_state)
		item_state = initial(item_state)
	else
		SetName("cane shaft")
		icon_state = "nullrod"
		item_state = "foldcane"
