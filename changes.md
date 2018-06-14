# Change history

* `1.2`:
	* Updated the LTTP Randomizer mode to work with the most recent LTTP randomizer (synchronizing the flute and other objects had broken due to a change in memory addresses some months ago.)
	* Improved "Sync Everything" mode for Zelda 1
	* Major improvements to mode API, including a "tick" function (called every frame), the ability for mode files to send and receive entirely custom messages which the mode file handles internally, and the option for conds to be functions.
* `1.1`:
	* Added a MODDING.md file that describes the mode file format.
	* Changes to core Lua script: Fixed a bug with using "mask" and kind high, which was somehow messing up heart containers in Zelda 1.
	* Changes to core Lua script: Added a "delta" kind, which makes it possible to sync quantities that go up and down.
	* Changes to Legend of Zelda 1 "sync everything" mode: New version from megmacAttack syncs keys and boss-defeat state.
* `1.0.2`:
	* Changes to snes9x-coop: Made bilinear filtering off by default. Made frame count display off by default. Added "Enable Background Input (Gamepad only)" mode in Input menu.
	* Fixes for FCEUX: Fix problem where pressing "tab" in the login dialog would cause login to fail
	* Changes to LTTP mode: Fix breakage with dwarf rescue quest and bomb shop
	* Changes to Super Metroid mode: Sync "Zebes awakes" state
	* Changes to core Lua script: Print the mode GUID at first moment of actual play (so that it is obvious from videos what the coop sync rules were).
* `1.0.1`:
	* Fixes for FCEUX: Work around an inexplicable bug with "%o" in IUP
	* Add the Legend of Zelda 1 mode files, which... I forgot. I just completely forgot to include. In the first release.
* `1.0`: Initial release

