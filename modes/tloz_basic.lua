-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: megmacattack
-- Data source: mostly http://datacrystal.romhacking.net/wiki/The_Legend_of_Zelda:RAM_map
-- This file is available under Creative Commons CC0 

return {
	guid = "e7cc9d84-959f-4d72-84bb-99212a30f1bb",
	format = "1.1",
	name = "The Legend of Zelda (sync items only)",
	match = {"stringtest", addr=0xffeb, value="ZELDA"},

	running = {"test", addr = 0x12, gte = 0x4, lte = 0xD}, -- zelda 1 data. Note, doc says nothing about states between 0x7 and 0xe but they appear to be cave/level related.
	sync = {
		-- zelda 1 data http://datacrystal.romhacking.net/wiki/The_Legend_of_Zelda:RAM_map
		-- multi-items
		[0x0657] = {
			nameMap={"Wood Sword","White Sword","Magical Sword"},
			kind="high"
		},
		[0x0659] = {
			nameMap={"Arrow","Silver Arrow"},
			kind="high"
		},
		[0x065B] = {
			nameMap={"Blue Candle", "Red Candle"},
			kind="high"
		},
		-- 0x065E: skip potion, players buy them on their own. Paper is elsewhere.
		[0x0662] = {
			nameMap={"Blue Ring", "Red Ring"},
			kind="high"
		},

		-- singular items (which includes the boomarang for some reason)
		[0x065a] = {name="Bow", kind="high"},
		[0x065c] = {name="Recorder", kind="high"},
--		[0x065d] = {name="Food", kind="high"}, -- should this be included? It's disposable...
		[0x065f] = {name="Magical Rod", kind="high"},
		[0x0660] = {name="Raft", kind="high"},
		[0x0661] = {name="Magic Book", kind="high"},
		[0x0663] = {name="Step Ladder", kind="high"},
		[0x0664] = {name="Magical Key", kind="high"},
		[0x0665] = {name="Power Bracelet", kind="high"},
		[0x0666] = {name="Letter", kind="high"},
		[0x0674] = {name="Boomerang", kind="high"},
		[0x0675] = {name="Magical Boomerang", kind="high"},
		[0x0676] = {name="Magical Shield", kind="high"}, -- note: an be lost
	},
}