//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:32

/obj/item/implantpad
	name = "implant pad"
	desc = "Used to reprogramm implants."
	icon = 'icons/obj/items.dmi'
	icon_state = "implantpad-0"
	item_state = "electronic"
	w_class = ITEM_SIZE_SMALL
	var/obj/item/implant/imp

/obj/item/implantpad/update_icon()
	if (imp)
		icon_state = "implantpad-1"
	else
		icon_state = "implantpad-0"

/obj/item/implantpad/attack_hand(mob/user)
	if ((imp && (user.l_hand == src || user.r_hand == src)))
		user.pick_or_drop(imp)
		imp.add_fingerprint(user)
		add_fingerprint(user)

		imp = null
		update_icon()
	else
		return ..()

/obj/item/implantpad/attackby(obj/item/I, mob/user)
	..()
	if(istype(I, /obj/item/implantcase))
		var/obj/item/implantcase/C = I
		if(!imp && C.imp)
			C.imp.forceMove(src)
			imp = C.imp
			C.imp = null
		else if (imp && !C.imp)
			imp.forceMove(C)
			C.imp = imp
			imp = null
		C.update_icon()
	else if(istype(I, /obj/item/implanter))
		var/obj/item/implanter/C = I
		if(!imp && C.imp)
			C.imp.forceMove(src)
			imp = C.imp
			C.imp = null
		else if (imp && !C.imp)
			imp.forceMove(C)
			C.imp = imp
			imp = null
		C.update_icon()
	else if(istype(I, /obj/item/implant) && user.drop(I, src))
		imp = I
	update_icon()

/obj/item/implantpad/attack_self(mob/user)
	if (imp)
		imp.interact(user)
	else
		to_chat(user,SPAN("warning", "There's no implant loaded in \the [src]."))
