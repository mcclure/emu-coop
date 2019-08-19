This version of emu-coop comes pre-built 
with the Zelda 3: A Link to the Past + Metroid 3: Super Metroid 
(henceforth referred to as Z3M3) co-op randomizer.

What it does:
-Syncs upgrades to health, equipment, and weaponry for both games
-Syncs ammunition upgrades for Metroid (missiles, power bombs, etc) but NOT for Zelda (arrow and bomb expansions)
-Automatically equips upgrades in Super Metroid (with the exception of certain beam upgrades)
-***(1)Syncs defeat of Super Metroid bosses and all world events that change as part of this (wrecked ship power)
-Syncs collection of crystals and pendants in Zelda

What it does NOT do:
-Does not sync defeat of Agahnim in Zelda
-***(2)Does not sync defeat of dungeon bosses (however, they do not need to be defeated by both players as the game only cares that the player has the crystal)
-Does not open chests or collect items on the other player's game (for example, both players can open the chest in Link's house and both recieve the item)
-***(3)Boomerang/M.Boomerang and Flute/Shovel are not progressive, so you can acquire the Magic Boomerang before the normal one
-Mother Brain and Ganon are not synced, both players must still beat both game's end bosses
-Keys, Compasses, and Maps for dungeons are not shared

***Known Issues and their fixes (or planned fixes):
(1) -Sometimes, bosses in Super Metroid will resurrect when switching between games.
	-To fix this, use one of the included debug scripts for killing bosses from anywhere on the map.  Only use these in Super Metroid!
(2) -Fighting a boss in Link to the Past that you already have the crystal for causes you to get trapped in the boss room once it is defeated.
	-This only happens in certain boss rooms.  For example, Eastern Palace you can just walk out to fix it.
	-However, in the other boss rooms, menus are locked which prevents the player from leaving using save&quit or the Magic Mirror.
	-This is because the game locks menus while the crystal falls from the ceiling, but since you already have it, no crystal falls but menus are still locked.
	-Currently, the only fix is to have the emulator reset the game which places you back in Super Metroid.
	-This should work fine as the game saves progress through the synchronization system but is not ideal for races.
	-Another fix is in the works that should prevent the menu from ever becoming locked, allowing players to save and quit even when the player is trapped in a boss room.
(3) -Boomerang/M.Boomerang are initially synced, but for some reason after acquiring both you may not be able to switch on one game while being able to switch on the other
	-Flute and Shovel have same issue as above
	-Unfortunately, there is not currently a fix for this issue, but one is in the works

Misc:
-Another version is planned to release that allows both players to use different seeds.  
	-However, certain items would become unobtainable if they are in an 'event' location, since one player completing the event prevents the other player from doing so.
	-For example:  P1's Old Man has S.Arrows, P2's Purple Chest has S.Arrows.  If P1 completes Purple Chest and P2 completes Old Man,
	-As such, this version needs to remove the following events from the synced memory addresses:
	-Old Man cave escort
	-Dwarf rescue
	-Purple Chest
	