This version of emu-coop comes pre-built 
with the Zelda 3: A Link to the Past + Metroid 3: Super Metroid 
(henceforth referred to as Z3M3) co-op randomizer.

Contact txcrnr#9668 on Discord if you run into any issues or have feedback on the co-op script.

What it does:
-Syncs upgrades and expansions to maximum health, equipment, and weaponry for both games
-Shares consumables (bombs, bottles, arrows) in Zelda
-Automatically equips upgrades in Super Metroid (with the exception of certain beam upgrades)
-Syncs defeat of Super Metroid bosses and all world events that change as part of this (wrecked ship power)
-Syncs defeat of Zelda bosses and all world events that change as part of this (dungeon bosses, Aga1, Aga2)
-Syncs collection of crystals and pendants in Zelda
-Syncs roomstates (key/colored doors opened, opened chests)

What it does NOT do:
-Current health is not shared in either game
-Current ammo in Super Metroid is not shared
-Boomerang/M.Boomerang and Flute/Shovel are not progressive, so you can acquire the Magic Boomerang before the normal one
-Mother Brain and Ganon are not synced, both players must still beat both game's end bosses

***Known Issues and their fixes (or planned fixes):
-Due to the fact that opposite-game roomstates can only be synced after the game has finished changing, the item in Lower Norfair
	transition room (normally where the Screw Attack is) will not be synced if the player uses this room to enter Super Metroid
	after having received the roomstate sync for this location for the first time while in Zelda.  Due to this, the item in the
	room can be duplicated a single time.  A fix to make this item always be a non-progressive item (I.E. not gloves or swords)
	is being tested.
-Because active rooms work differently than saved roomstates, if a roomstate change is received while the player is in that room,
	it will not sync until the room is reloaded.  To prevent using this to duplicate items, if the player enters a room currently
	occupied by their partner, they will stop sending values to their partner, and any values received from their partner
	will be queued up until they leave the room.  Additionally, a backup will be created upon entering the same room, and
	loaded upon leaving.  Obtaining any keys will have them be removed immediately so that the player cannot use this feature
	to go through a key door in a room containing a key and have their partner take the key again, which would duplicate said key.
-The code still has debug info instead of the ideal "partner received x item" messages; this is because this build, while near
	completion, is still in a beta phase.  If you run into any issues where the script crashes or items fail to sync in
	some way, please save the latest few messages in the Lua GUI to send the debug info to txcrnr#9668 on Discord.