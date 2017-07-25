-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Andi McClure
-- Data source: http://alttp.run/hacking/index.php?title=SRAM_Map
-- Thanks to the Zelda randomizer team, especially Mike Trethewey, Zarby89 and Karkat
-- This file is available under Creative Commons CC0 

return {
	guid = "d1186ea1-f60d-4eb5-b0b9-92de35c92f8e",
	format = "1.0"
	name = "Super Metroid",
	match = {"stringtest", addr=0xFFC0, value="Super Metroid"},

	--running = {"test", addr = 0x7E0010, gte = 0x6, lte = 0x13},
	sync = {
	}
}
