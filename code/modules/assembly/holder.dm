/obj/item/device/assembly_holder
	name = "Assembly"
	icon = 'icons/obj/assemblies/new_assemblies.dmi'
	icon_state = "holder"
	item_state = "assembly"
	movable_flags = MOVABLE_FLAG_PROXMOVE
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	throwforce = 5
	w_class = ITEM_SIZE_SMALL
	throw_speed = 3
	throw_range = 10

	var/secured = 0
	var/obj/item/device/assembly/a_left = null
	var/obj/item/device/assembly/a_right = null
	var/obj/special_assembly = null

/obj/item/device/assembly_holder/Destroy()
	QDEL_NULL(a_left)
	QDEL_NULL(a_right)
	QDEL_NULL(special_assembly)
	. = ..()

/obj/item/device/assembly_holder/proc/detached()
	return

/obj/item/device/assembly_holder/IsAssemblyHolder()
	return 1

/obj/item/device/assembly_holder/proc/attach(var/obj/item/device/assembly/D, var/obj/item/device/assembly/D2, var/mob/user)
	if(!isassembly(D) || !isassembly(D2))
		return FALSE
	if(D.secured || D2.secured)
		return FALSE
	if(user)
		user.u_equip(D)
		if(D2.loc == user)
			user.u_equip(D2)
		else if(istype(D2.loc, /obj/item/storage))
			var/obj/item/storage/S = D2.loc
			S.remove_from_storage(D2)

	D.holder = src
	D2.holder = src
	D.forceMove(src)
	D2.forceMove(src)
	a_left = D
	a_right = D2
	name = "[D.name]-[D2.name] assembly"
	update_icon()
	usr.put_in_hands(src)
	return TRUE

/obj/item/device/assembly_holder/proc/attach_special(var/obj/O, var/mob/user)
	if(!(O?.IsSpecialAssembly()))
		return 0

/obj/item/device/assembly_holder/update_icon()
	overlays.Cut()
	if(a_left)
		overlays += "[a_left.icon_state]_left"
		for(var/O in a_left.attached_overlays)
			overlays += "[O]_l"
	if(a_right)
		src.overlays += "[a_right.icon_state]_right"
		for(var/O in a_right.attached_overlays)
			overlays += "[O]_r"
	if(master)
		master.update_icon()

/obj/item/device/assembly_holder/examine(mob/user)
	..()
	if (in_range(src, user) || loc == user)
		if (secured)
			to_chat(user, "[src] is ready!")
		else
			to_chat(user, "[src] can be attached!")

/obj/item/device/assembly_holder/HasProximity(atom/movable/AM as mob|obj)
	if(a_left)
		a_left.HasProximity(AM)
	if(a_right)
		a_right.HasProximity(AM)
	if(special_assembly)
		special_assembly.HasProximity(AM)

/obj/item/device/assembly_holder/Crossed(atom/movable/AM as mob|obj)
	if(a_left)
		a_left.Crossed(AM)
	if(a_right)
		a_right.Crossed(AM)
	if(special_assembly)
		special_assembly.Crossed(AM)

/obj/item/device/assembly_holder/on_found(mob/finder as mob)
	if(a_left)
		a_left.on_found(finder)
	if(a_right)
		a_right.on_found(finder)
	if(special_assembly)
		if(istype(special_assembly, /obj/item))
			var/obj/item/S = special_assembly
			S.on_found(finder)

/obj/item/device/assembly_holder/Move()
	. = ..()
	if(a_left && a_right)
		a_left.holder_movement()
		a_right.holder_movement()

/obj/item/device/assembly_holder/attack_hand()//Perhapse this should be a holder_pickup proc instead, can add if needbe I guess
	if(a_left && a_right)
		a_left.holder_movement()
		a_right.holder_movement()
	..()

/obj/item/device/assembly_holder/attackby(obj/item/W as obj, mob/user as mob)
	if(W.isscrewdriver())
		if(!a_left || !a_right)
			to_chat(user, SPAN_DANGER("BUG:Assembly part missing, please report this!"))
			return
		a_left.toggle_secure()
		a_right.toggle_secure()
		secured = !secured
		if(secured)
			to_chat(user, SPAN_NOTICE("\The [src] is ready!"))
		else
			to_chat(user, SPAN_NOTICE("\The [src] can now be taken apart!"))
		update_icon()
		return
	else if(W.IsSpecialAssembly())
		attach_special(W, user)
	else
		..()
	return

/obj/item/device/assembly_holder/attack_self(mob/user)
	..()
	src.add_fingerprint(user)
	if(src.secured)
		if(!a_left || !a_right)
			to_chat(user, SPAN_DANGER("Assembly part missing!"))
			return
		if(istype(a_left,a_right.type))//If they are the same type it causes issues due to window code
			switch(alert("Which side would you like to use?",,"Left","Right"))
				if("Left")	a_left.attack_self(user)
				if("Right")	a_right.attack_self(user)
			return
		else
			if(!istype(a_left,/obj/item/device/assembly/igniter))
				a_left.attack_self(user)
			if(!istype(a_right,/obj/item/device/assembly/igniter))
				a_right.attack_self(user)
	else
		var/turf/T = get_turf(src)
		if(!T)
			return
		if(a_left)
			a_left.holder = null
			a_left.forceMove(T)
			a_left = null
		if(a_right)
			a_right.holder = null
			a_right.forceMove(T)
			a_right = null
		qdel(src)

/obj/item/device/assembly_holder/proc/process_activation(var/obj/D, var/normal = 1, var/special = 1)
	if(!D)
		return 0
	if(!secured)
		visible_message("[icon2html(src, hearers(src))] *beep* *beep*", "*beep* *beep*")
	if((normal) && (a_right) && (a_left))
		if(a_right != D)
			a_right.pulsed(0)
		if(a_left && a_left != D) //check a_left again, a_right.pulsed() might've qdel'd the assembly
			a_left.pulsed(0)
	if(master)
		master.receive_signal()
	return 1

/obj/item/device/assembly_holder/hear_talk(mob/living/M as mob, msg)
	if(a_right)
		a_right.hear_talk(M,msg)
	if(a_left)
		a_left.hear_talk(M,msg)

/obj/item/device/assembly_holder/timer_igniter
	name = "timer-igniter assembly"

/obj/item/device/assembly_holder/timer_igniter/Initialize(mapload, timer_time)
	. = ..()

	var/obj/item/device/assembly/igniter/ign = new(src)
	ign.secured = 1
	ign.holder = src
	var/obj/item/device/assembly/timer/tmr = new(src)
	if(timer_time)
		tmr.time = timer_time
	else
		tmr.time = 5 SECONDS
	tmr.secured = 1
	tmr.holder = src
	a_left = tmr
	a_right = ign
	secured = 1
	update_icon()
	name = initial(name) + " (timer: [tmr.time])"

	loc.verbs += /obj/item/device/assembly_holder/timer_igniter/verb/configure

/obj/item/device/assembly_holder/timer_igniter/detached()
	loc.verbs -= /obj/item/device/assembly_holder/timer_igniter/verb/configure
	..()

/obj/item/device/assembly_holder/timer_igniter/verb/configure()
	set name = "Set Timer"
	set category = "Object"
	set src in usr

	if(!(usr.stat || usr.restrained()))
		var/obj/item/device/assembly_holder/holder
		if(istype(src,/obj/item/grenade/chem_grenade))
			var/obj/item/grenade/chem_grenade/gren = src
			holder=gren.detonator
		var/obj/item/device/assembly/timer/tmr = holder.a_left
		if(!istype(tmr,/obj/item/device/assembly/timer))
			tmr = holder.a_right
		if(!istype(tmr,/obj/item/device/assembly/timer))
			to_chat(usr, SPAN_NOTICE("This detonator has no timer."))
			return

		if(tmr.timing)
			to_chat(usr, SPAN_NOTICE("Clock is ticking already."))
		else
			var/ntime = input("Enter desired time in seconds", "Time", "5") as num
			if (ntime>0 && ntime<1000)
				tmr.time = ntime
				name = initial(name) + "([tmr.time] secs)"
				to_chat(usr, SPAN_NOTICE("Timer set to [tmr.time] seconds."))
			else
				to_chat(usr, SPAN_NOTICE("Timer can't be [ntime<=0?"negative":"more than 1000 seconds"]."))
	else
		to_chat(usr, SPAN_NOTICE("You cannot do this while [usr.stat?"unconscious/dead":"restrained"]."))
