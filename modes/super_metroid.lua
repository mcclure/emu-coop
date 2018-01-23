-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Andi McClure
-- Data source: https://jathys.zophar.net/supermetroid/kejardon/RAMMap.txt
-- This file is available under Creative Commons CC0 

-- When you get a missile, super missile or power bomb, your current count goes up by the size of the expansion
local function makeMissileTrigger(targetAddr) -- 2 byte size
	return function(value, previousValue)
		local current = memory.readword(targetAddr)
		memory.writeword(targetAddr, current + (value - previousValue))
	end
end

local function difference(a, b) -- 1 byte size
	return AND(a, XOR(b, 0xFF))
end

-- When you get an item, any bit that goes high in the "available" byte should also go high in the "equipped" byte
-- (but only if it is ALSO in the mask of bits we're watching)
local function makeItemTrigger(targetAddr, mask) -- 2 byte size
	return function(value, previousValue)
		local current = memory.readbyte(targetAddr)
		memory.writebyte(targetAddr, OR(current, AND(mask, difference(value, previousValue))))
	end
end

return {
	guid = "41c22c5f-7d2b-4e43-9610-e967033e492f",
	format = "1.0",
	name = "Super Metroid",
	match = {"stringtest", addr=0xFFC0, value="Super Metroid"},

	running = {"test", addr = 0x7E0998, gte = 0x8, lte = 0x18}, -- Possibly could go as low as 0x12, not all state values are of known purpose
	sync = {
		[0x7E09C4] = {name="Energy Tank", kind="high", size=2,
			receiveTrigger=function(value, previousValue)
				memory.writeword(0x7E09C2, value) -- Refill health on any memory tank collection
			end
		},
		[0x7E09C8] = {name="Missile Expansion", kind="high", size=2, receiveTrigger=makeMissileTrigger(0x7E09C6)},
		[0x7E09CC] = {name="Super Missiles",    kind="high", size=2, receiveTrigger=makeMissileTrigger(0x7E09CA)}, 
		[0x7E09D0] = {name="Power Bombs",       kind="high", size=2, receiveTrigger=makeMissileTrigger(0x7E09CE)}, 
		[0x7E09D4] = {name="Reserve Tank",      kind="high", size=2, receiveTrigger=makeMissileTrigger(0x7E09C6)}, 

		[0x7E09A4] = {nameBitmap={"Varia Suit", "Spring Ball", "Morph Ball", "Screw Attack", "unknown item", "Gravity Suit"},
			kind="bitOr", mask=0x2F, receiveTrigger=makeItemTrigger(0x7E09A2, 0x2F)
		},

		[0x7E09A5] = {nameBitmap={"Hi-Jump Boots", "Space Jump", "unknown item", "unknown item", "Bomb", "Speed Booster", "Grapple Beam", "X-Ray Scope"},
			kind="bitOr", mask=0xF3, receiveTrigger=makeItemTrigger(0x7E09A3, 0xF3)
		},

		[0x7E09A8] = {nameBitmap={"Wave Beam", "Ice Beam", "Spazer Beam", "Plasma Beam"},
			kind="bitOr", mask=0x0F,

			-- Trigger for beams is same as makeItemTrigger, EXCEPT we must make sure the plasma and spazer beam never go high at once
			receiveTrigger=function(value, previousValue)
				local targetAddr = 0x7E09A6
				local mask = 0x0F
				local current = memory.readbyte(targetAddr)
				local rising = AND(mask, difference(value, previousValue))
				local result = OR(current, rising)

				if 0 ~= AND(rising, 0x08) then
					result = AND(result, XOR(0xFF, 0x04))
				elseif 0 ~= AND(rising, 0x04) then
					result = AND(result, XOR(0xFF, 0x08))
				end
				memory.writebyte(targetAddr, result)
			end
		},

		[0x7E09A9] = {nameBitmap={"unknown beam", "unknown beam", "unknown beam", "unknown beam", "Charge Beam"},
			kind="bitOr", mask=0x10, receiveTrigger=makeItemTrigger(0x7E09A7, 0x10)
		}, 

		[0x7ED829] = {nameBitmap={"Kraid"},    verb="defeated", kind="bitOr", mask=0x1},
		[0x7ED82A] = {nameBitmap={"Ridley"},   verb="defeated", kind="bitOr", mask=0x1},
		[0x7ED82B] = {nameBitmap={"Phantoon"}, verb="defeated", kind="bitOr", mask=0x1},
		[0x7ED82C] = {nameBitmap={"Draygon"},  verb="defeated", kind="bitOr", mask=0x1},
		[0x7ED820] = {kind="bitOr", mask=0x01, nameBitmap={"the planet angry"}} -- "Zebes is awake"
	}
}
