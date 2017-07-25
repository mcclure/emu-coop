-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Andi McClure
-- Data source: http://alttp.run/hacking/index.php?title=SRAM_Map , https://github.com/mmxbass/z3randomizer/blob/master
-- Thanks to the Zelda randomizer team, especially Mike Trethewey, Zarby89 and Karkat
-- This file is available under Creative Commons CC0 

local function UNSET(x, bit) -- 0 index
	return AND(x, XOR(0xFF, BIT(bit)))
end

local function zeroRising(value, previousValue) -- "Allow if replacing 'no item', but not if replacing another item"
	return (value ~= 0 and previousValue == 0), (value)
end

local function zeroRisingOrUpgradeFlute(value, previousValue)
	return ( (value ~= 0 and previousValue == 0) or (value == 2 and previousValue == 1) ), (value)
end

local mushroomByte = 0x7EF344

return {
	guid = "5aa171c4-0e3f-4919-8578-870cea6dbe91",
	format = "1.0",
	name = "Link to the Past Randomizer",
	match = {"stringtest", addr=0xFFC0, value="VT"},

	running = {"test", addr = 0x7E0010, gte = 0x6, lte = 0x13},
	sync = {
		-- INVENTORY_SWAP
		[0x7EF412] = {
			nameBitmap={"Bird", "Flute", "Shovel", "unknown item", "Magic Powder", "Mushroom", "Magic Boomerang", "Boomerang"},
			kind=function(value, previousValue)
				local result = OR(value, previousValue)
				if 0 ~= AND(result, BIT(0)) then result = UNSET(result, 1) end -- If acquired bird, clear flute
				-- FIXME: Do not re-set mushroom bit if mushroom is already given to witch
				return (result ~= previousValue), (result) 
			end,
			receiveTrigger=function(value, previousValue) -- Mushroom/powder byte is a disaster so set it indirectly when this mask changes
				-- If powder bit went high and no mushroom type item is being held, place powder in inventory
				if 0 ~= AND(value, BIT(4)) and 0 == AND(previousValue, BIT(4)) and 0 == memory.readbyte(mushroomByte) then
					memory.writebyte(mushroomByte, 2)
				end
				-- If mushroom bit went high and no mushroom type item is being held, place mushroom in inventory
				if 0 ~= AND(value, BIT(5)) and 0 == AND(previousValue, BIT(5)) and 0 == memory.readbyte(mushroomByte) then
					memory.writebyte(mushroomByte, 1)
				end
			end
		},

		-- INVENTORY_SWAP_2
		[0x7EF414] = {
			nameBitmap={"unknown item", "unknown item", "unknown item", "unknown item", "unknown item", "unknown item", "Silver Arrows", "Bow"},
			kind="bitOr"
		},

		-- NPC_FLAGS
		[0x7EF410] = {
			nameBitmap={"an old man home"},
			mask=0x1, -- Only sync old man
			kind="bitOr"
		},

		-- PROGRESSIVE_SHIELD 
		[0x7EF416] = { -- TODO: Add a 0xC0 mask? Currently mask is not supported with "high"
			kind="high" -- Sync silently-- this is a backup in case your shield gets eaten
		},

		[0x7EF340] = {kind=zeroRising},                     -- Bows, tracked in INVENTORY_SWAP_2 but must be nonzero to appear in inventory
		[0x7EF341] = {kind=zeroRising},                     -- Boomerangs, tracked in INVENTORY_SWAP
		[0x7EF342] = {name="Hookshot", kind="high"},
		[0x7EF345] = {name="Fire Rod", kind="high"},
		[0x7EF346] = {name="Ice Rod", kind="high"},
		[0x7EF347] = {name="Bombos", kind="high"},
		[0x7EF348] = {name="Ether", kind="high"},
		[0x7EF349] = {name="Quake", kind="high"},
		[0x7EF34A] = {name="Lantern", kind="high"},
		[0x7EF34B] = {name="Hammer", kind="high"},
		-- Note this doesn't need to happen in INVENTORY_SWAP receiveTrigger bc you can only upgrade the flute while holding it
		[0x7EF34C] = {kind=zeroRisingOrUpgradeFlute},       -- Shovel flute etc, tracked in INVENTORY_SWAP
		[0x7EF34D] = {name="Net", kind="high"},
		[0x7EF34E] = {name="Book", kind="high"},
		[0x7EF34F] = {kind="high"}, -- Bottle count
		[0x7EF350] = {name="Red Cane", kind="high"},
		[0x7EF351] = {name="Blue Cane", kind="high"},
		[0x7EF352] = {name="Cape", kind="high"},
		[0x7EF353] = {name="Mirror", kind="high"},
		[0x7EF354] = {name="Gloves", kind="high"},
		[0x7EF355] = {name="Boots", kind="high"},
		[0x7EF356] = {name="Flippers", kind="high"},
		[0x7EF357] = {name="Pearl", kind="high"},
		[0x7EF359] = {nameMap={"Fighter's Sword", "Master Sword", "Tempered Sword", "Golden Sword"}, kind="high",
			cond={"test", gte = 0x1, lte = 0x4} -- Avoid 0xFF trap during dwarf quest
		},
		[0x7EF35A] = {nameMap={"Shield", "Fire Shield", "Mirror Shield"}, kind="high"},
		[0x7EF35B] = {nameMap={"Blue Armor", "Red Armor"}, kind="high"},
		[0x7EF35C] = {name="Bottle", kind=zeroRising}, -- Only change contents when acquiring new *empty* bottle
		[0x7EF35D] = {name="Bottle", kind=zeroRising},
		[0x7EF35E] = {name="Bottle", kind=zeroRising},
		[0x7EF35F] = {name="Bottle", kind=zeroRising},
		[0x7EF366] = {name="a Big Key", kind="bitOr"}, -- FIXME: Hyrule Castle big key does not seem to be in either of these masks, which could affect open seeds?
		[0x7EF367] = {name="a Big Key", kind="bitOr"},
		[0x7EF379] = {kind="bitOr"}, -- Abilities
		[0x7EF374] = {name="a Pendant", kind="bitOr"},
		[0x7EF37A] = {name="a Crystal", kind="bitOr"},
		[0x7EF37B] = {name="Half Magic", kind="high"}
	}
}
