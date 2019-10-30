-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Andi McClure
-- Data source: http://alttp.run/hacking/index.php?title=SRAM_Map
-- Thanks to the Zelda randomizer team, especially Mike Trethewey, Zarby89 and Karkat
--Note: 0x7EF300 to 0x7EF3FF in ALTTP WRAM will be at 0xA17B00 to 0xA17BFF while in SM. Likewise, 0x7E09A2 to 0x7E09E2 in SM WRAM will be at 0xA17900 to 0xA1793F while in ALTTP.
-- This file is available under Creative Commons CC0 





--------------------------------
-----Mod by Trevor Thompson-----
--------------------------------
--Current Revision: Beta 2.2.3--
--------------------------------
-----------10/30/2019-----------
--------------------------------
-----------4:30PM EST-----------
--------------------------------

--Memory Addresses to check:
-- org $f7fd00
-- base $b7fd00
-- sm_check_ending_door:        ; Check if ALTTP has been beaten, and only then activate the escape.
    -- pha
    -- lda #$0001
    -- sta.l !SRAM_SM_COMPLETED      ; Set supermetroid as completed
    -- lda.l !SRAM_ALTTP_COMPLETED
    -- bne .alttp_done
    -- pla
    -- jsl $808212         ; Clear event flag if set
    -- jml $8fc932         ; Jump to "RTS"
-- .alttp_done
    -- pla
    -- jsl $8081fa         ; Call the code we replaced
    -- jml $8fc926         ; Jump to "LDA #$0012"

-- sm_check_ending_mb:
    -- lda #$0001
    -- sta.l !SRAM_SM_COMPLETED      ; Set supermetroid as completed
    -- lda.l !SRAM_ALTTP_COMPLETED
    -- bne .alttp_done
    -- lda #$b2f9
    -- sta $0fa8
    -- lda #$0020
    -- sta $0fb2
    -- rtl

-- .alttp_done    
    -- lda #$0000
    -- sta $7e7808
    -- rtl

-- org $f7fe00
-- base $b7fe00
-- alttp_check_ending:
    -- lda.b #$01
    -- sta.l !SRAM_ALTTP_COMPLETED
    -- lda.l !SRAM_SM_COMPLETED
    -- bne .sm_completed
    -- lda.b #$08 : sta $010c
    -- lda.b #$0f : sta $10
    -- lda.b #$20 : sta $a0
    -- lda.b #$00 : sta $a1



socket = require("socket")

local int ZSTORAGE = 0x228800
local int MSTORAGE = 0x236F5E
local previous = {}
local queuezbit = {}
local queuezhigh = {}
local queuezval = {}
local queuembit = {}
local queuemhigh = {}
local queuemval = {}
local backup = {}
local partnerRoom = 0
local partnerGame = 1
local noSend = false
--metroid = 255
--zelda = 0
for z = 0x7EF340, 0x7EF3C9 do --zelda item range
	previous[z] = 0
end
for m = 0x7E09C4, 0x7ED82C do --metroid item range
	previous[m] = 0
end
-- When you get a missile, super missile or power bomb, your current count goes up by the size of the expansion

local function difference(a, b) -- 1 byte size
	return AND(a, XOR(b, 0xFF))
end

-- When you get an item, any bit that goes high in the "available" byte should also go high in the "equipped" byte
-- (but only if it is ALSO in the mask of bits we're watching)
local function makeItemTrigger(targetAddr, mask, value, previousValue) -- 2 byte size
	local current = memory.readbyte(targetAddr)
	memory.writebyte(targetAddr, OR(current, AND(mask, difference(value, previousValue))))
	--message("equipped at " .. targetAddr .. " old = " .. previousValue .. " new = " .. value)
end

local function zeldaLocalItemTrigger(targetAddr)
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 and noSend == false then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			if value ~= nil and value > previous[targetAddr] then  
				local sendPayload = targetAddr .. value
				send("zsync", sendPayload)
				previous[targetAddr] = value
			end
		end
	end
end

local function zeldaLocalBottleTrigger(targetAddr)
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 and noSend == false then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			if value ~= nil then
				local sendPayload = targetAddr .. value
				if previous[targetAddr] ~= value then
					send("zsync", sendPayload)
				end
				previous[targetAddr] = value
			end
		end
	end
end

local function zeldaLocalBitTrigger(targetAddr)
	return function(value, previousValue, forceSend)
		--message("Equipment Changed")
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 and noSend == false then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			local newBitVal = OR(value, previous[targetAddr])
			local sendPayload = targetAddr .. newBitVal
			if previous[targetAddr] ~= value then
				send("zsyncbit", sendPayload)
			end
			previous[targetAddr] = newBitVal
		end
	end
end

local function zeldaForeignBitTrigger(targetAddr)
	return function(value, previousValue, forceSend)
		--message("Equipment Changed")
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 255 and noSend == false then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			local newBitVal = OR(value, previous[targetAddr])
			local sendPayload = targetAddr .. newBitVal
			if previous[targetAddr] ~= value then
				send("zsyncbit", sendPayload)
			end
			previous[targetAddr] = newBitVal
		end
	end
end

local function zeldaForeignItemTrigger(targetAddr)  
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 255 and noSend == false then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			if value ~= nil and value > previous[targetAddr] then
				local sendPayload = targetAddr .. value
				send("zsync", sendPayload)
				previous[targetAddr] = value
			end
		end
	end
end

local function zeldaForeignBottleTrigger(targetAddr)  
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 255 and noSend == false then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			if value ~= nil then
				local sendPayload = targetAddr .. value
				if previous[targetAddr] ~= value then
					send("zsync", sendPayload)
				end
				previous[targetAddr] = value
			end
		end
	end
end

local function metroidLocalExpTrigger(targetAddr, localFunc)
	return function(value, previousValue, forceSend)
		--message("Expansions Changed")
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 255 and noSend == false then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			if value ~= nil and value > previous[targetAddr] then
				local sendPayload = targetAddr .. value
				if previous[targetAddr] ~= value then
					send(localFunc, sendPayload)
				end
				previous[targetAddr] = value
			end
		end
	end
end

local function metroidLocalBitTrigger(targetAddr, mask) -- check bit to ensure extra value is not being added on second pickup:  Subtract old from new, AND this value with old, if that value is not zero then ignore
	return function(value, previousValue, forceSend)
		--message("Equipment Changed")
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 255 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			local rising = value - previous[targetAddr]
			if AND(rising, previous[targetAddr]) == 0 then
				local newBitVal = OR(value, previous[targetAddr])
				local sendPayload = targetAddr .. mask .. newBitVal
				if previous[targetAddr] ~= value then
					send("msync", sendPayload)
				end
				previous[targetAddr] = newBitVal
			end
		end
	end
end

local function metroidLocalBeamTrigger(targetAddr, mask) -- check bit to ensure extra value is not being added on second pickup
	return function(value, previousValue, forceSend)
		--message("Equipment Changed")
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 255 and value ~= 0 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			local rising = value - previous[targetAddr]
			if value ~= previous[targetAddr] then
				if AND(rising, previous[targetAddr]) == 0 then
					local newBitVal = OR(value, previous[targetAddr])
					local sendPayload = targetAddr .. newBitVal
					if previous[targetAddr] ~= value then
						send("msyncbeam", sendPayload)
						send("msyncbeamequip", sendPayload)
					end
					previous[targetAddr] = value
				end
			end
			previous[targetAddr] = value
		end
	end
end

local function metroidForeignExpTrigger(targetAddr, localFunc)
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 and noSend == false then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			if value ~= nil and value > previous[targetAddr] then
				local sendPayload = targetAddr .. value
				if previous[targetAddr] ~= value then
					send(localFunc, sendPayload)
				end
				previous[targetAddr] = value
			end
		end
	end
end

local function metroidForeignBitTrigger(targetAddr, mask) -- check bit to ensure extra value is not being added on second pickup
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			local rising = value - previous[targetAddr]
			if AND(rising, previous[targetAddr]) == 0 then
				local newBitVal = OR(value, previous[targetAddr])
				local sendPayload = targetAddr .. mask .. newBitVal
				if previous[targetAddr] ~= value then
					send("msync", sendPayload)
				end
				previous[targetAddr] = newBitVal
			end
		end
	end
end

local function metroidForeignBeamTrigger(targetAddr, mask) -- check bit to ensure extra value is not being added on second pickup
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 and value ~= 0 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			local rising = value - previous[targetAddr]
			if value ~= previous[targetAddr] then
				if AND(rising, previous[targetAddr]) == 0 then
					local newBitVal = OR(value, previous[targetAddr])
					local sendPayload = targetAddr .. newBitVal
					if previous[targetAddr] ~= value then
						send("msyncbeam", sendPayload)
						send("msyncbeamequip", sendPayload)
					end
					previous[targetAddr] = value
				end
			end
		end
	end
end

------------------------------
--------Zelda Menu Fix--------
------------------------------
local function zeldaMenuTrigger()
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 then
			memoryWrite(0x7E0FFC, 0)
		end
	end
end
------------------------------
---------Room Syncing---------
------------------------------
local function loadBackup(payload)
	message("backup loaded")
	local currentGame = memoryRead(0xA173FE)
	if payload == "m" then
		if backup[0] == "m" then
			table.remove(backup, 0)
			for k, v in pairs(backup) do
			if v[1] ~= nil then
				memoryWrite(k,v[1],v[4])
				table.remove(backup, k)
			end
			end	
		else
			table.remove(backup, 0)
			for k, v in pairs(backup) do
			if v[1] ~= nil then
				if v[2] == "m" then
					memoryWrite(k-MSTORAGE,v[1],v[4])
					table.remove(backup, k)
				elseif v[3] == 0 then
					memoryWrite(k+ZSTORAGE,v[1],v[4])
					table.remove(backup, k)
				else
					queuezbit[k] = v[1]
				end
			end
			end	
		end
	elseif payload == "z" then
		if backup[0] == "z" then
			table.remove(backup, 0)
			for k, v in pairs(backup) do
			if v[1] ~= nil then
				if v[1] ~= nil and k ~= nil then
					--message(k .. " was changed to " .. v[1])
					memoryWrite(k,v[1],v[4])
					table.remove(backup, k)
				end
			end
			end	
		else
			table.remove(backup, 0)
			for k, v in pairs(backup) do
			if v[1] ~= nil then
				if v[2] == "z" then
					memoryWrite(k-ZSTORAGE,v[1],v[4])
					table.remove(backup, k)
				elseif v[3] == 0 then
					memoryWrite(k+MSTORAGE,v[1],v[4])
					table.remove(backup, k)
				else
					queuembit[k] = v[1]
				end
			end	
			end
		end
	end
end

local function createBackup(payload) --if third arg is 0, it exists in the opposite game's buffer and doesnt need a queue
	message("backup created")
	if payload == "m" then
		backup[0] = "m"
		
		backup[0x7EF38C+ZSTORAGE] = {memoryRead(0x7EF38C+ZSTORAGE),"z",0,1} --Swap Equip
		backup[0x7EF38E +ZSTORAGE] = {memoryRead(0x7EF38E +ZSTORAGE),"z",0,1} --Swap Equip
		backup[0x7EF3C7+ZSTORAGE] = {memoryRead(0x7EF3C7+ZSTORAGE),"z",0,1} --Swap Equip
		backup[0x7EF36C+ZSTORAGE] = {memoryRead(0x7EF36C+ZSTORAGE),"z",0,1} --Heart Containers
		backup[0x7EF36B+ZSTORAGE] = {memoryRead(0x7EF36B+ZSTORAGE),"z",0,1} --Heart Pieces
		backup[0x7EF37B+ZSTORAGE] = {memoryRead(0x7EF37B+ZSTORAGE),"z",0,1} --Half Magic
		backup[0x7EF379+ZSTORAGE] = {memoryRead(0x7EF379+ZSTORAGE),"z",0,1} --Abilities
		backup[0x7E09C4] = {memoryRead(0x7E09C4, 2),"m",0,2} --E-Tank
		backup[0x7E09C8] = {memoryRead(0x7E09C8, 2),"m",0,2} --Missile
		backup[0x7E09CC] = {memoryRead(0x7E09CC, 2),"m",0,2} --Supers
		backup[0x7E09D0] = {memoryRead(0x7E09D0, 2),"m",0,2} --PBs
		backup[0x7E09D4] = {memoryRead(0x7E09D4, 2),"m",0,2} --Reserves
		for a = 0x7ED820, 0x7ED8EF do --Metroid Rooms
			backup[a] = {memoryRead(a),"m",1,1}
		end
		for a = 0x7EF340+ZSTORAGE,0x7EF35F+ZSTORAGE  do --Zelda Items
			backup[a] = {memoryRead(a),"z",0,1}
		end
		--for a = ,  do
		--	backup[a] = memoryRead(a)
		--end
	elseif payload == "z" then
		backup[0] = "z"
		backup[0x7EF374] = {memoryRead(0x7EF374),"z",1,1} --Pendant
		backup[0x7EF37A] = {memoryRead(0x7EF37A),"z",1,1} --Crystal
		backup[0x7EF38C] = {memoryRead(0x7EF38C),"z",0,1} --Swap Equip
		backup[0x7EF38E] = {memoryRead(0x7EF38E),"z",0,1} --Swap Equip
		backup[0x7EF3C7] = {memoryRead(0x7EF3C7),"z",0,1} --Swap Equip
		backup[0x7EF36C] = {memoryRead(0x7EF36C),"z",0,1} --Heart Containers
		backup[0x7EF36B] = {memoryRead(0x7EF36B),"z",0,1} --Heart Pieces
		backup[0x7EF37B] = {memoryRead(0x7EF37B),"z",0,1} --Half Magic
		backup[0x7EF379] = {memoryRead(0x7EF379),"z",0,1} --Abilities
		backup[0x7EF3C5] = {memoryRead(0x7EF3C5),"z",0,1} -- Events
		backup[0x7EF3C6] = {memoryRead(0x7EF3C6),"z",0,1}  -- Events 2
		backup[0x7EF410] = {memoryRead(0x7EF410),"z",0,1} -- Events 3
		backup[0x7EF411] = {memoryRead(0x7EF411),"z",0,1} -- Events 4
		backup[0x7EF3C9] = {memoryRead(0x7EF3C9),"z",0,1} -- Dwarf rescue bit (required for bomb shop)
		backup[0x7E09C4+MSTORAGE] = {memoryRead(0x7E09C4+MSTORAGE, 2),"m",0,2} --E-Tank
		backup[0x7E09C8+MSTORAGE] = {memoryRead(0x7E09C8+MSTORAGE, 2),"m",0,2} --Missile
		backup[0x7E09CC+MSTORAGE] = {memoryRead(0x7E09CC+MSTORAGE, 2),"m",0,2} --Supers
		backup[0x7E09D0+MSTORAGE] = {memoryRead(0x7E09D0+MSTORAGE, 2),"m",0,2} --PBs
		backup[0x7E09D4+MSTORAGE] = {memoryRead(0x7E09D4+MSTORAGE, 2),"m",0,2} --Reserves
		for a = 0x7EF000,0x7EF24F  do --Zelda Rooms 1
			backup[a] = {memoryRead(a),"z",1,1}
		end
		for a = 0x7EF280,0x7EF2FF  do --Zelda Rooms 2
			backup[a] = {memoryRead(a),"z",1,1}
		end
		for a = 0x7EF37C,0x7EF389  do --Zelda Keys
			backup[a] = {memoryRead(a),"z",1,1}
		end
		for a = 0x7EF340,0x7EF35F  do --Zelda Items
			backup[a] = {memoryRead(a),"z",0,1}
		end
		for a = 0x7EF364,0x7EF367  do --Zelda Big keys
			backup[a] = {memoryRead(a),"z",1,1}
		end
		for a = 0x7EF37C, 0x7EF389 do --Zelda key removal
			memoryWrite(a, 0)
		end
	end
end

local function queueUnloadMetroid()
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 255 and noSend == false and value ~= 11 then
			for k, v in pairs(queuembit) do
				message("queue wrote " .. v .. " at " .. string.format("%X", k))
				memoryWrite(k, OR(memoryRead(k),v))
				table.remove(queuembit, k)
			end	
			for k, v in pairs(queuemhigh) do
				if v > memoryRead(k) then
					message("queue wrote " .. v .. " at " .. string.format("%X", k))
					memoryWrite(k, v)
				end
				table.remove(queuemhigh, k)
			end	
			for k, v in pairs(queuemval) do
				message("queue wrote " .. v .. " at " .. string.format("%X", k))
				memoryWrite(k, v)
				table.remove(queuemval, k)
			end	
			queuembit = {}
			queuemhigh = {}
			queuemval = {}
		end
	end
end

local function queueUnloadZelda()
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		local stateCheck = memoryRead(0x7E0010)
		local testVal = false
		if stateCheck == 7 then
			testVal = true
		elseif stateCheck == 9 then
			testVal = true
		end
		if currentGame == 0 and testVal == true and noSend == false then
			for k, v in pairs(queuezbit) do
				message("queue wrote " .. v .. " at " .. string.format("%X", k))
				memoryWrite(k, OR(memoryRead(k),v))
				table.remove(queuezbit, k)
			end	
			for k, v in pairs(queuezhigh) do
				if v > memoryRead(k) then
					message("queue wrote " .. v .. " at " .. string.format("%X", k))
					memoryWrite(k, v)
				end
				table.remove(queuezhigh, k)
			end	
			for k, v in pairs(queuezval) do
				message("queue wrote " .. v .. " at " .. string.format("%X", k))
				memoryWrite(k, v)
				table.remove(queuezval, k)
			end	
			queuezbit = {}
			queuezhigh = {}
			queuezval = {}
		end
	end
end

local function metroidQueueTrigger(targetAddr, syncType)
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		local stateCheck = memoryRead(0x7E0998)
		if previous[targetAddr] == nil then	
			previous[targetAddr] = 0
		end
		if currentGame == 255 and stateCheck ~= 0 and noSend == false and value ~= previous[targetAddr] then
			message("Mqueue active")
			message(targetAddr .. "    " .. value .. "    " .. previous[targetAddr])
			if syncType == "high" then
				local sendPayload = targetAddr .. value
				send("msyncqueuehigh", sendPayload)
				previous[targetAddr] = value
			elseif syncType == "bitOr" then
				local sendPayload = targetAddr .. value
				send("msyncqueuebit", sendPayload)
				previous[targetAddr] = value
			elseif syncType == "either" then
				local sendPayload = targetAddr .. value
				send("msyncqueueval", sendPayload)
				previous[targetAddr] = value
			else
				message("neither")
			end
		end
	end
end

local function zeldaQueueTrigger(targetAddr, syncType)
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		local stateCheck = memoryRead(0x7E0010)
		local testVal = false
		if stateCheck == 7 then
			testVal = true
		elseif stateCheck == 9 then
			testVal = true
		end
		if previous[targetAddr] == nil then	
			previous[targetAddr] = 0
		end
		if currentGame == 0 and testVal == true and noSend == false and value ~= previous[targetAddr] then
			message("Zqueue active")
			message(targetAddr .. "    " .. value .. "    " .. previous[targetAddr])
			if syncType == "high" then
				local sendPayload = targetAddr .. value
				send("zsyncqueuehigh", sendPayload)
				previous[targetAddr] = value
			elseif syncType == "bitOr" then
				local sendPayload = targetAddr .. value
				send("zsyncqueuebit", sendPayload)
				previous[targetAddr] = value
			elseif syncType == "either" then
				local sendPayload = targetAddr .. value
				send("zsyncqueueval", sendPayload)
				previous[targetAddr] = value
			else
				message("neither")
			end
		end
	end
end


local function zeldaKeyQueueTrigger(targetAddr, syncType)
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		local stateCheck = memoryRead(0x7E0010)
		local testVal = false
		if stateCheck == 7 then
			testVal = true
		elseif stateCheck == 9 then
			testVal = true
		end
		if previous[targetAddr] == nil then	
			previous[targetAddr] = 0
		end
		if currentGame == 0 and testVal == true and noSend == false and value ~= previous[targetAddr] then
			message("Zqueue active")
			message(targetAddr .. "    " .. value .. "    " .. previous[targetAddr])
			if syncType == "high" then
				local sendPayload = targetAddr .. value
				send("zsyncqueuehigh", sendPayload)
				previous[targetAddr] = value
			elseif syncType == "bitOr" then
				local sendPayload = targetAddr .. value
				send("zsyncqueuebit", sendPayload)
				previous[targetAddr] = value
			elseif syncType == "either" then
				local sendPayload = targetAddr .. value
				send("zsyncqueueval", sendPayload)
				previous[targetAddr] = value
			else
				message("neither")
			end
		elseif currentGame == 0 and noSend == true then
			memoryWrite(targetAddr, 0)
		end
	end
end

local function roomSwapMetroid(targetAddr) --MAKE SURE THIS CAN TELL IF GAME IS LOADED WHEN COMING FROM ZELDA
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if previous[targetAddr] == nil then	
			previous[targetAddr] = 0
		end
		if currentGame == partnerGame and currentGame == 0 and value == partnerRoom then
			if noSend == false then
				noSend = true
				message("Same Room as Partner")
				if previous[targetAddr] ~= value then
					send("mroomswap",value)
					previous[targetAddr] = value
				end
				createBackup("m")
			else 
				if previous[targetAddr] ~= value then
					send("mroomswap",value)
					previous[targetAddr] = value
				end
				message("Same Room as Partner")
			end
		elseif currentGame == 255 then
			if noSend == true then
				noSend = false
				loadBackup("m")
				if previous[targetAddr] ~= value then
					send("mroomswap",value)
					previous[targetAddr] = value
				end
			else
				if previous[targetAddr] ~= value then
					send("mroomswap",value)
					previous[targetAddr] = value
				end
			end
		end
	end
end

local function roomSwapZeldaO(targetAddr)
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		local state = memoryRead(0x7E0010)
		if state ~= 7 and state ~= 0 and state ~= 23 then
			if currentGame == partnerGame and currentGame == 0 and value == partnerRoom then
				if noSend == false then
					noSend = true
					message("Same Room as Partner")
					if previous[targetAddr] ~= value then
						send("zroomswap",value)
						previous[targetAddr] = value
					end
					createBackup("z")
				else 
					if previous[targetAddr] ~= value then
						send("zroomswap",value)
						previous[targetAddr] = value
					end
					message("Same Room as Partner")
				end
			elseif currentGame == 0 then
				if noSend == true then
					noSend = false
					loadBackup("z")
					if previous[targetAddr] ~= value then
						send("zroomswap",value)
						previous[targetAddr] = value
					end
				else
					if previous[targetAddr] ~= value then
						send("zroomswap",value)
						previous[targetAddr] = value
					end
				end
			end
		end
	end
end

local function roomSwapZeldaD(targetAddr)
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		local state = memoryRead(0x7E0010)
		if previous[targetAddr] == nil then	
			previous[targetAddr] = 0
		end
		if state ~= 9 and state ~= 0 and state ~= 23 and value ~= previous[targetAddr] then
			if currentGame == partnerGame and currentGame == 0 and value == partnerRoom and noSend == false then
				noSend = true
				message("Same Room as Partner")
				createBackup("z")
			elseif currentGame == 0 then
				if noSend == true then
					noSend = false
					loadBackup("z")
				else
					if previous[targetAddr] ~= value then
						send("zroomswap",value)
						previous[targetAddr] = value
					end
				end
			end
		end
	end
end

return {
	guid = "f003df87-0c3b-4b3b-86c8-d0deef93e6ec",
	format = "1.2",
	name = "Z3M3",
	match = {"stringtest", addr=0xFFC0, value="SMALTTP"},  -- This needs to be changed to the name of the file later

	--running = {"test", addr = 0x7E0010, gte = 0x6, lte = 0x13}, --Zelda
	--running = {"test", addr = 0x7E0998, gte = 0x8, lte = 0x18}, -- Super Metroid
	sync = {
		------------------------------
		---------Room Syncing---------
		------------------------------
		[0x7E0010] = {kind="trigger",   writeTrigger=queueUnloadZelda()},
		[0x7E0998] = {kind="trigger",   writeTrigger=queueUnloadMetroid()},
		[0x7E079B] = {kind="trigger",   writeTrigger=roomSwapMetroid("0x7E079B")},
		[0x7E008A] = {kind="trigger",   writeTrigger=roomSwapZeldaO("0x7E008A")},
		[0x7E00A0] = {kind="trigger",   writeTrigger=roomSwapZeldaD("0x7E00A0")},
		
		
		------------------------------
		--Zelda Items while in Zelda--
		------------------------------
		---
		[0x7EF340] = {nameMap={"Bow", "Bow", "Silver Arrows", "Silver Arrows"}, kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF340")},
		[0x7EF341] = {nameMap={"Boomerang", "Magic Boomerang"}, kind="trigger", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF341")},
		[0x7EF342] = {name="Hookshot", kind="trigger",   writeTrigger=zeldaLocalItemTrigger("0x7EF342")},
		[0x7EF344] = {nameMap={"Mushroom", "Magic Powder"}, kind="trigger",   writeTrigger=zeldaLocalItemTrigger("0x7EF344")},
		[0x7EF345] = {name="Fire Rod", kind="trigger",   writeTrigger=zeldaLocalItemTrigger("0x7EF345")},
		[0x7EF346] = {name="Ice Rod", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF346")},
		[0x7EF347] = {name="Bombos", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF347")},
		[0x7EF348] = {name="Ether", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF348")},
		[0x7EF349] = {name="Quake", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF349")},
		[0x7EF34A] = {name="Lantern", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF34A")},
		[0x7EF34B] = {name="Hammer", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF34B")},
		[0x7EF34C] = {nameMap={"Shovel", "Flute", "Bird"}, kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF34C")},
		[0x7EF34D] = {name="Net", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF34D")},
		[0x7EF34E] = {name="Book", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF34E")},
		[0x7EF34F] = {kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF34F")},-- Bottle count
		[0x7EF350] = {name="Red Cane", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF350")},
		[0x7EF351] = {name="Blue Cane", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF351")},
		[0x7EF352] = {name="Cape", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF352")},
		[0x7EF353] = {name="Mirror", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF353")},
		[0x7EF354] = {name="Gloves", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF354")},
		[0x7EF355] = {name="Boots", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF355")},
		[0x7EF356] = {name="Flippers", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF356")},
		[0x7EF357] = {name="Pearl", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF357")},
		[0x7EF359] = {nameMap={"Fighter's Sword", "Master Sword", "Tempered Sword", "Golden Sword"}, kind="trigger", cond={"test", gte = 0x1, lte = 0x4}, writeTrigger=zeldaLocalItemTrigger("0x7EF359")},
		[0x7EF35A] = {nameMap={"Shield", "Fire Shield", "Mirror Shield"}, kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF35A")},
		[0x7EF35B] = {nameMap={"Blue Armor", "Red Armor"}, kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF35B")},
		[0x7EF35C] = {name="Bottle", kind="trigger", writeTrigger=zeldaLocalBottleTrigger("0x7EF35C")},
		[0x7EF35D] = {name="Bottle", kind="trigger", writeTrigger=zeldaLocalBottleTrigger("0x7EF35D")},
		[0x7EF35E] = {name="Bottle", kind="trigger", writeTrigger=zeldaLocalBottleTrigger("0x7EF35E")},
		[0x7EF35F] = {name="Bottle", kind="trigger", writeTrigger=zeldaLocalBottleTrigger("0x7EF35F")},
		---
		[0x7EF379] = {kind="trigger", writeTrigger=zeldaLocalBitTrigger("0x7EF379")}, --Abilities
		[0x7EF374] = {name="a Pendant", kind="trigger", writeTrigger=zeldaLocalBitTrigger("0x7EF374")},
		[0x7EF37A] = {name="a Crystal", kind="trigger", writeTrigger=zeldaLocalBitTrigger("0x7EF37A")},
		[0x7EF37B] = {name="Half Magic", kind="trigger", writeTrigger=zeldaLocalBitTrigger("0x7EF37B")},
		[0x7EF36B] = {kind="trigger", writeTrigger=zeldaLocalBottleTrigger("0x7EF36B")}, --Heart Pieces
		[0x7EF36C] = {name="a Heart Container", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF36C")},
		[0x7EF360] = {kind="trigger", writeTrigger=zeldaLocalBottleTrigger("0x7EF360")}, -- Rupee byte 1
		[0x7EF361] = {kind="trigger", writeTrigger=zeldaLocalBottleTrigger("0x7EF361")}, -- Rupee byte 2
		[0x7EF343] = {kind="trigger", writeTrigger=zeldaLocalBottleTrigger("0x7EF343")}, -- Bombs
		[0x7EF377] = {kind="trigger", writeTrigger=zeldaLocalBottleTrigger("0x7EF377")}, -- Arrows
		---
		[0x7EF364] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF364","bitOr")}, --Big Keys, Compasses
		[0x7EF365] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF365","bitOr")}, --Big Keys, Compasses
		[0x7EF368] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF368","bitOr")}, --Big Keys, Compasses
		[0x7EF369] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF369","bitOr")}, --Big Keys, Compasses
		[0x7EF366] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF366","bitOr")}, --Big Keys, Compasses
		[0x7EF367] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF367","bitOr")}, --Big Keys, Compasses
		---
		[0x7EF38C] = {kind="trigger",   writeTrigger=zeldaLocalBitTrigger("0x7EF38C")}, --Extra swap equip
		[0x7EF38E] = {kind="trigger",   writeTrigger=zeldaLocalBitTrigger("0x7EF38E")}, --Extra swap equip
		[0x7EF3C7] = {kind="trigger",   writeTrigger=zeldaLocalBitTrigger("0x7EF3C7")}, --Extra swap equip
		[0x7EF3C5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF3C5","bitOr")}, -- Events
		[0x7EF3C6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF3C6","bitOr")},  -- Events 2
		[0x7EF410] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF410","bitOr")}, -- Events 3
		[0x7EF411] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF411","bitOr")}, -- Events 4
		[0x7EF3C9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF3C9","bitOr")}, -- Dwarf rescue bit (required for bomb shop)
		
		
		--------------------------------------
		--Zelda Items while in Super Metroid--
		--------------------------------------
		[0x7EF340+ZSTORAGE] = {nameMap={"Bow", "Bow", "Silver Arrows", "Silver Arrows"}, kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF340")},
		[0x7EF341+ZSTORAGE] = {nameMap={"Boomerang", "Magic Boomerang"}, kind="trigger", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF341")},
		[0x7EF342+ZSTORAGE] = {name="Hookshot", kind="trigger",   writeTrigger=zeldaForeignItemTrigger("0x7EF342")},
		[0x7EF344+ZSTORAGE] = {nameMap={"Mushroom", "Magic Powder"}, kind="trigger",   writeTrigger=zeldaForeignItemTrigger("0x7EF344")},
		[0x7EF345+ZSTORAGE] = {name="Fire Rod", kind="trigger",   writeTrigger=zeldaForeignItemTrigger("0x7EF345")},
		[0x7EF346+ZSTORAGE] = {name="Ice Rod", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF346")},
		[0x7EF347+ZSTORAGE] = {name="Bombos", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF347")},
		[0x7EF348+ZSTORAGE] = {name="Ether", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF348")},
		[0x7EF349+ZSTORAGE] = {name="Quake", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF349")},
		[0x7EF34A+ZSTORAGE] = {name="Lantern", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF34A")},
		[0x7EF34B+ZSTORAGE] = {name="Hammer", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF34B")},
		[0x7EF34C+ZSTORAGE] = {nameMap={"Shovel", "Flute", "Bird"}, kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF34C")},
		[0x7EF34D+ZSTORAGE] = {name="Net", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF34D")},
		[0x7EF34E +ZSTORAGE] = {name="Book", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF34E")},
		[0x7EF34F+ZSTORAGE] = {kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF34F")},-- Bottle count
		[0x7EF350+ZSTORAGE] = {name="Red Cane", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF350")},
		[0x7EF351+ZSTORAGE] = {name="Blue Cane", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF351")},
		[0x7EF352+ZSTORAGE] = {name="Cape", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF352")},
		[0x7EF353+ZSTORAGE] = {name="Mirror", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF353")},
		[0x7EF354+ZSTORAGE] = {name="Gloves", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF354")},
		[0x7EF355+ZSTORAGE] = {name="Boots", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF355")},
		[0x7EF356+ZSTORAGE] = {name="Flippers", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF356")},
		[0x7EF357+ZSTORAGE] = {name="Pearl", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF357")},
		[0x7EF359+ZSTORAGE] = {nameMap={"Fighter's Sword", "Master Sword", "Tempered Sword", "Golden Sword"}, kind="trigger", cond={"test", gte = 0x1, lte = 0x4}, writeTrigger=zeldaForeignItemTrigger("0x7EF359")},
		[0x7EF35A+ZSTORAGE] = {nameMap={"Shield", "Fire Shield", "Mirror Shield"}, kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF35A")},
		[0x7EF35B+ZSTORAGE] = {nameMap={"Blue Armor", "Red Armor"}, kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF35B")},
		[0x7EF35C+ZSTORAGE] = {name="Bottle", kind="trigger", writeTrigger=zeldaForeignBottleTrigger("0x7EF35C")},
		[0x7EF35D+ZSTORAGE] = {name="Bottle", kind="trigger", writeTrigger=zeldaForeignBottleTrigger("0x7EF35D")},
		[0x7EF35E +ZSTORAGE] = {name="Bottle", kind="trigger", writeTrigger=zeldaForeignBottleTrigger("0x7EF35E")},
		[0x7EF35F+ZSTORAGE] = {name="Bottle", kind="trigger", writeTrigger=zeldaForeignBottleTrigger("0x7EF35F")},
		[0x7EF379+ZSTORAGE] = {kind="trigger", writeTrigger=zeldaForeignBitTrigger("0x7EF379")}, --Abilities
		[0x7EF37B+ZSTORAGE] = {name="Half Magic", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF37B")},
		[0x7EF36B+ZSTORAGE] = {kind="trigger", writeTrigger=zeldaForeignBottleTrigger("0x7EF36B")}, --Heart Pieces
		[0x7EF36C+ZSTORAGE] = {name="a Heart Container", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF36C")},
		[0x7EF360+ZSTORAGE] = {kind="trigger", writeTrigger=zeldaForeignBottleTrigger("0x7EF360")}, -- Rupee byte 1
		[0x7EF361+ZSTORAGE] = {kind="trigger", writeTrigger=zeldaForeignBottleTrigger("0x7EF361")}, -- Rupee byte 2
		[0x7EF343+ZSTORAGE] = {kind="trigger", writeTrigger=zeldaForeignBottleTrigger("0x7EF343")}, -- Bombs
		[0x7EF377+ZSTORAGE] = {kind="trigger", writeTrigger=zeldaForeignBottleTrigger("0x7EF377")}, -- Arrows
		[0x7EF38C+ZSTORAGE] = {kind="trigger",   writeTrigger=zeldaForeignBitTrigger("0x7EF38C")}, --Extra swap equip
		[0x7EF38E +ZSTORAGE] = {kind="trigger",   writeTrigger=zeldaForeignBitTrigger("0x7EF38E")}, --Extra swap equip
		[0x7EF3C7+ZSTORAGE] = {kind="trigger",   writeTrigger=zeldaForeignBitTrigger("0x7EF3C7")}, --Extra swap equip
		
		
		
		----------------------------------------------
		--Super Metroid Items while in Super Metroid--
		----------------------------------------------
		[0x7E09C4] = {name="Energy Tank", kind="trigger", size=2, writeTrigger=metroidLocalExpTrigger("0x7E09C4","msynctank")},
		[0x7E09C8] = {name="Missile Expansion", kind="trigger", size=2, writeTrigger=metroidLocalExpTrigger("0x7E09C8","msyncexp")},
		[0x7E09CC] = {name="Super Missiles", kind="trigger", size=2, writeTrigger=metroidLocalExpTrigger("0x7E09CC","msyncexp")},
		[0x7E09D0] = {name="Power Bombs", kind="trigger", size=2, writeTrigger=metroidLocalExpTrigger("0x7E09D0","msyncexp")},
		[0x7E09D4] = {name="Reserve Tank", kind="trigger", size=2, writeTrigger=metroidLocalExpTrigger("0x7E09D4","msynctankreserve")},
		[0x7E09A4] = {nameBitmap={"Varia Suit", "Spring Ball", "Morph Ball", "Screw Attack", "unknown item", "Gravity Suit"}, kind="trigger", writeTrigger=metroidLocalBitTrigger("0x7E09A4", "0x2F")},
		[0x7E09A5] = {nameBitmap={"Hi-Jump Boots", "Space Jump", "unknown item", "unknown item", "Bomb", "Speed Booster", "Grapple Beam", "X-Ray Scope"}, kind="trigger", writeTrigger=metroidLocalBitTrigger("0x7E09A5", "0xF3")},
		[0x7E09A8] = {nameBitmap={"Wave Beam", "Ice Beam", "Spazer Beam", "Plasma Beam"}, kind="trigger", writeTrigger=metroidLocalBeamTrigger("0x7E09A8", "0x0F")}, -- Trigger for beams is same as makeItemTrigger, EXCEPT we must make sure the plasma and spazer beam never go high at once
		[0x7E09A9] = {nameBitmap={"unknown beam", "unknown beam", "unknown beam", "unknown beam", "Charge Beam"}, kind="trigger", writeTrigger=metroidLocalBeamTrigger("0x7E09A9", "0x10")},
		
		
		
		--------------------------------------
		--Super Metroid Items while in Zelda--
		--------------------------------------
		[0x7E09C4+MSTORAGE] = {name="Energy Tank", kind="trigger", size=2, writeTrigger=metroidForeignExpTrigger("0x7E09C4","msynctank")},
		[0x7E09C8+MSTORAGE] = {name="Missile Expansion", kind="trigger", size=2, writeTrigger=metroidForeignExpTrigger("0x7E09C8","msyncexp")},
		[0x7E09CC+MSTORAGE] = {name="Super Missiles",    kind="trigger", size=2, writeTrigger=metroidForeignExpTrigger("0x7E09CC","msyncexp")},
		[0x7E09D0+MSTORAGE] = {name="Power Bombs",       kind="trigger", size=2, writeTrigger=metroidForeignExpTrigger("0x7E09D0","msyncexp")},
		[0x7E09D4+MSTORAGE] = {name="Reserve Tank",      kind="trigger", size=2, writeTrigger=metroidForeignExpTrigger("0x7E09D4","msynctankreserve")},
		[0x7E09A4+MSTORAGE] = {nameBitmap={"Varia Suit", "Spring Ball", "Morph Ball", "Screw Attack", "unknown item", "Gravity Suit"},kind="trigger", writeTrigger=metroidForeignBitTrigger("0x7E09A4", "0x2F")},
		[0x7E09A5+MSTORAGE] = {nameBitmap={"Hi-Jump Boots", "Space Jump", "unknown item", "unknown item", "Bomb", "Speed Booster", "Grapple Beam", "X-Ray Scope"},kind="trigger", writeTrigger=metroidForeignBitTrigger("0x7E09A5", "0xF3")}, 
		[0x7E09A8+MSTORAGE] = {nameBitmap={"Wave Beam", "Ice Beam", "Spazer Beam", "Plasma Beam"},kind="trigger",writeTrigger=metroidForeignBeamTrigger("0x7E09A8", "0x0F")}, -- Trigger for beams is same as makeItemTrigger, EXCEPT we must make sure the plasma and spazer beam never go high at once
		[0x7E09A9+MSTORAGE] = {nameBitmap={"unknown beam", "unknown beam", "unknown beam", "unknown beam", "Charge Beam"},kind="trigger", writeTrigger=metroidForeignBeamTrigger("0x7E09A9", "0x10")},
		
		
		------------------------------
		-----------METROID------------
		------------------------------
		--EVENTS--
		[0x7ED820] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED820","bitOr")},
		[0x7ED821] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED821","bitOr")},
		[0x7ED822] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED822","bitOr")},
		[0x7ED823] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED823","bitOr")},
		[0x7ED824] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED824","bitOr")},
		[0x7ED825] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED825","bitOr")},
		[0x7ED826] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED826","bitOr")},
		[0x7ED827] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED827","bitOr")},
		[0x7ED828] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED828","bitOr")},
		[0x7ED829] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED829","bitOr")},
		[0x7ED82A] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED82A","bitOr")},
		[0x7ED82B] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED82B","bitOr")},
		[0x7ED82C] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED82C","bitOr")},
		[0x7ED82D] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED82D","bitOr")},
		[0x7ED82E] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED82E","bitOr")},
		[0x7ED82F] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED82F","bitOr")},
		[0x7ED830] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED830","bitOr")},
		[0x7ED831] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED831","bitOr")},
		[0x7ED832] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED832","bitOr")},
		[0x7ED833] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED833","bitOr")},
		[0x7ED834] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED834","bitOr")},
		[0x7ED835] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED835","bitOr")},
		[0x7ED836] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED836","bitOr")},
		[0x7ED837] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED837","bitOr")},
		[0x7ED838] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED838","bitOr")},
		[0x7ED839] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED839","bitOr")},
		[0x7ED83A] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED83A","bitOr")},
		[0x7ED83B] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED83B","bitOr")},
		[0x7ED83C] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED83C","bitOr")},
		[0x7ED83D] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED83D","bitOr")},
		[0x7ED83E] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED83E","bitOr")},
		[0x7ED83F] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED83F","bitOr")},
		[0x7ED840] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED840","bitOr")},
		[0x7ED841] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED841","bitOr")},
		[0x7ED842] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED842","bitOr")},
		[0x7ED843] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED843","bitOr")},
		[0x7ED844] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED844","bitOr")},
		[0x7ED845] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED845","bitOr")},
		[0x7ED846] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED846","bitOr")},
		[0x7ED847] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED847","bitOr")},
		[0x7ED848] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED848","bitOr")},
		[0x7ED849] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED849","bitOr")},
		[0x7ED84A] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED84A","bitOr")},
		[0x7ED84B] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED84B","bitOr")},
		[0x7ED84C] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED84C","bitOr")},
		[0x7ED84D] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED84D","bitOr")},
		[0x7ED84E] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED84E","bitOr")},
		[0x7ED84F] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED84F","bitOr")},
		[0x7ED850] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED850","bitOr")},
		[0x7ED851] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED851","bitOr")},
		[0x7ED852] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED852","bitOr")},
		[0x7ED853] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED853","bitOr")},
		[0x7ED854] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED854","bitOr")},
		[0x7ED855] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED855","bitOr")},
		[0x7ED856] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED856","bitOr")},
		[0x7ED857] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED857","bitOr")},
		[0x7ED858] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED858","bitOr")},
		[0x7ED859] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED859","bitOr")},
		[0x7ED85A] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED85A","bitOr")},
		[0x7ED85B] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED85B","bitOr")},
		[0x7ED85C] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED85C","bitOr")},
		[0x7ED85D] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED85D","bitOr")},
		[0x7ED85E] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED85E","bitOr")},
		[0x7ED85F] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED85F","bitOr")},
		[0x7ED860] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED860","bitOr")},
		[0x7ED861] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED861","bitOr")},
		[0x7ED862] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED862","bitOr")},
		[0x7ED863] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED863","bitOr")},
		[0x7ED864] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED864","bitOr")},
		[0x7ED865] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED865","bitOr")},
		[0x7ED866] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED866","bitOr")},
		[0x7ED867] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED867","bitOr")},
		[0x7ED868] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED868","bitOr")},
		[0x7ED869] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED869","bitOr")},
		[0x7ED86A] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED86A","bitOr")},
		[0x7ED86B] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED86B","bitOr")},
		[0x7ED86C] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED86C","bitOr")},
		[0x7ED86D] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED86D","bitOr")},
		[0x7ED86E] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED86E","bitOr")},
		[0x7ED86F] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED86F","bitOr")},
		--ITEMS--
		[0x7ED870] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED870","bitOr")},
		[0x7ED871] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED871","bitOr")},
		[0x7ED872] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED872","bitOr")},
		[0x7ED873] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED873","bitOr")},
		[0x7ED874] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED874","bitOr")},
		[0x7ED875] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED875","bitOr")},
		[0x7ED876] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED876","bitOr")},
		[0x7ED877] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED877","bitOr")},
		[0x7ED878] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED878","bitOr")},
		[0x7ED879] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED879","bitOr")},
		[0x7ED87A] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED87A","bitOr")},
		[0x7ED87B] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED87B","bitOr")},
		[0x7ED87C] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED87C","bitOr")},
		[0x7ED87D] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED87D","bitOr")},
		[0x7ED87E] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED87E","bitOr")},
		[0x7ED87F] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED87F","bitOr")},
		[0x7ED880] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED880","bitOr")},
		[0x7ED881] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED881","bitOr")},
		[0x7ED882] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED882","bitOr")},
		[0x7ED883] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED883","bitOr")},
		[0x7ED884] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED884","bitOr")},
		[0x7ED885] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED885","bitOr")},
		[0x7ED886] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED886","bitOr")},
		[0x7ED887] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED887","bitOr")},
		[0x7ED888] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED888","bitOr")},
		[0x7ED889] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED889","bitOr")},
		[0x7ED88A] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED88A","bitOr")},
		[0x7ED88B] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED88B","bitOr")},
		[0x7ED88C] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED88C","bitOr")},
		[0x7ED88D] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED88D","bitOr")},
		[0x7ED88E] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED88E","bitOr")},
		[0x7ED88F] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED88F","bitOr")},
		[0x7ED890] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED890","bitOr")},
		[0x7ED891] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED891","bitOr")},
		[0x7ED892] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED892","bitOr")},
		[0x7ED893] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED893","bitOr")},
		[0x7ED894] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED894","bitOr")},
		[0x7ED895] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED895","bitOr")},
		[0x7ED896] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED896","bitOr")},
		[0x7ED897] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED897","bitOr")},
		[0x7ED898] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED898","bitOr")},
		[0x7ED899] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED899","bitOr")},
		[0x7ED89A] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED89A","bitOr")},
		[0x7ED89B] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED89B","bitOr")},
		[0x7ED89C] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED89C","bitOr")},
		[0x7ED89D] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED89D","bitOr")},
		[0x7ED89E] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED89E","bitOr")},
		[0x7ED89F] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED89F","bitOr")},
		[0x7ED8A0] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8A0","bitOr")},
		[0x7ED8A1] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8A1","bitOr")},
		[0x7ED8A2] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8A2","bitOr")},
		[0x7ED8A3] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8A3","bitOr")},
		[0x7ED8A4] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8A4","bitOr")},
		[0x7ED8A5] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8A5","bitOr")},
		[0x7ED8A6] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8A6","bitOr")},
		[0x7ED8A7] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8A7","bitOr")},
		[0x7ED8A8] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8A8","bitOr")},
		[0x7ED8A9] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8A9","bitOr")},
		[0x7ED8AA] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8AA","bitOr")},
		[0x7ED8AB] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8AB","bitOr")},
		[0x7ED8AC] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8AC","bitOr")},
		[0x7ED8AD] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8AD","bitOr")},
		[0x7ED8AE] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8AE","bitOr")},
		[0x7ED8AF] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8AF","bitOr")},
		--DOORS--
		[0x7ED8B0] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8B0","bitOr")},
		[0x7ED8B1] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8B1","bitOr")},
		[0x7ED8B2] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8B2","bitOr")},
		[0x7ED8B3] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8B3","bitOr")},
		[0x7ED8B4] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8B4","bitOr")},
		[0x7ED8B5] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8B5","bitOr")},
		[0x7ED8B6] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8B6","bitOr")},
		[0x7ED8B7] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8B7","bitOr")},
		[0x7ED8B8] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8B8","bitOr")},
		[0x7ED8B9] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8B9","bitOr")},
		[0x7ED8BA] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8BA","bitOr")},
		[0x7ED8BB] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8BB","bitOr")},
		[0x7ED8BC] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8BC","bitOr")},
		[0x7ED8BD] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8BD","bitOr")},
		[0x7ED8BE] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8BE","bitOr")},
		[0x7ED8BF] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8BF","bitOr")},
		[0x7ED8C0] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8C0","bitOr")},
		[0x7ED8C1] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8C1","bitOr")},
		[0x7ED8C2] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8C2","bitOr")},
		[0x7ED8C3] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8C3","bitOr")},
		[0x7ED8C4] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8C4","bitOr")},
		[0x7ED8C5] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8C5","bitOr")},
		[0x7ED8C6] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8C6","bitOr")},
		[0x7ED8C7] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8C7","bitOr")},
		[0x7ED8C8] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8C8","bitOr")},
		[0x7ED8C9] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8C9","bitOr")},
		[0x7ED8CA] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8CA","bitOr")},
		[0x7ED8CB] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8CB","bitOr")},
		[0x7ED8CC] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8CC","bitOr")},
		[0x7ED8CD] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8CD","bitOr")},
		[0x7ED8CE] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8CE","bitOr")},
		[0x7ED8CF] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8CF","bitOr")},
		[0x7ED8D0] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8D0","bitOr")},
		[0x7ED8D1] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8D1","bitOr")},
		[0x7ED8D2] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8D2","bitOr")},
		[0x7ED8D3] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8D3","bitOr")},
		[0x7ED8D4] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8D4","bitOr")},
		[0x7ED8D5] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8D5","bitOr")},
		[0x7ED8D6] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8D6","bitOr")},
		[0x7ED8D7] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8D7","bitOr")},
		[0x7ED8D8] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8D8","bitOr")},
		[0x7ED8D9] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8D9","bitOr")},
		[0x7ED8DA] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8DA","bitOr")},
		[0x7ED8DB] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8DB","bitOr")},
		[0x7ED8DC] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8DC","bitOr")},
		[0x7ED8DD] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8DD","bitOr")},
		[0x7ED8DE] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8DE","bitOr")},
		[0x7ED8DF] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8DF","bitOr")},
		[0x7ED8E0] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8E0","bitOr")},
		[0x7ED8E1] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8E1","bitOr")},
		[0x7ED8E2] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8E2","bitOr")},
		[0x7ED8E3] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8E3","bitOr")},
		[0x7ED8E4] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8E4","bitOr")},
		[0x7ED8E5] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8E5","bitOr")},
		[0x7ED8E6] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8E6","bitOr")},
		[0x7ED8E7] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8E7","bitOr")},
		[0x7ED8E8] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8E8","bitOr")},
		[0x7ED8E9] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8E9","bitOr")},
		[0x7ED8EA] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8EA","bitOr")},
		[0x7ED8EB] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8EB","bitOr")},
		[0x7ED8EC] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8EC","bitOr")},
		[0x7ED8ED] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8ED","bitOr")},
		[0x7ED8EE] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8EE","bitOr")},
		[0x7ED8EF] = {kind="trigger",   writeTrigger=metroidQueueTrigger("0x7ED8EF","bitOr")},
		
		
		------------------------------
		------------ZELDA-------------
		------------------------------
		--INDOORS--
		[0x7EF000] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF000","bitOr")},
		[0x7EF001] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF001","bitOr")},
		[0x7EF002] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF002","bitOr")},
		[0x7EF003] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF003","bitOr")},
		[0x7EF004] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF004","bitOr")},
		[0x7EF005] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF005","bitOr")},
		[0x7EF006] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF006","bitOr")},
		[0x7EF007] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF007","bitOr")},
		[0x7EF008] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF008","bitOr")},
		[0x7EF009] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF009","bitOr")},
		[0x7EF00A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF00A","bitOr")},
		[0x7EF00B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF00B","bitOr")},
		[0x7EF00C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF00C","bitOr")},
		[0x7EF00D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF00D","bitOr")},
		[0x7EF00E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF00E","bitOr")},
		[0x7EF00F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF00F","bitOr")},
		[0x7EF010] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF010","bitOr")},
		[0x7EF011] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF011","bitOr")},
		[0x7EF012] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF012","bitOr")},
		[0x7EF013] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF013","bitOr")},
		[0x7EF014] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF014","bitOr")},
		[0x7EF015] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF015","bitOr")},
		[0x7EF016] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF016","bitOr")},
		[0x7EF017] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF017","bitOr")},
		[0x7EF018] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF018","bitOr")},
		[0x7EF019] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF019","bitOr")},
		[0x7EF01A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF01A","bitOr")},
		[0x7EF01B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF01B","bitOr")},
		[0x7EF01C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF01C","bitOr")},
		[0x7EF01D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF01D","bitOr")},
		[0x7EF01E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF01E","bitOr")},
		[0x7EF01F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF01F","bitOr")},
		[0x7EF020] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF020","bitOr")},
		[0x7EF021] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF021","bitOr")},
		[0x7EF022] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF022","bitOr")},
		[0x7EF023] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF023","bitOr")},
		[0x7EF024] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF024","bitOr")},
		[0x7EF025] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF025","bitOr")},
		[0x7EF026] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF026","bitOr")},
		[0x7EF027] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF027","bitOr")},
		[0x7EF028] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF028","bitOr")},
		[0x7EF029] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF029","bitOr")},
		[0x7EF02A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF02A","bitOr")},
		[0x7EF02B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF02B","bitOr")},
		[0x7EF02C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF02C","bitOr")},
		[0x7EF02D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF02D","bitOr")},
		[0x7EF02E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF02E","bitOr")},
		[0x7EF02F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF02F","bitOr")},
		[0x7EF030] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF030","bitOr")},
		[0x7EF031] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF031","bitOr")},
		[0x7EF032] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF032","bitOr")},
		[0x7EF033] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF033","bitOr")},
		[0x7EF034] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF034","bitOr")},
		[0x7EF035] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF035","bitOr")},
		[0x7EF036] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF036","bitOr")},
		[0x7EF037] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF037","bitOr")},
		[0x7EF038] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF038","bitOr")},
		[0x7EF039] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF039","bitOr")},
		[0x7EF03A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF03A","bitOr")},
		[0x7EF03B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF03B","bitOr")},
		[0x7EF03C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF03C","bitOr")},
		[0x7EF03D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF03D","bitOr")},
		[0x7EF03E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF03E","bitOr")},
		[0x7EF03F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF03F","bitOr")},
		[0x7EF040] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF040","bitOr")},
		[0x7EF041] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF041","bitOr")},
		[0x7EF042] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF042","bitOr")},
		[0x7EF043] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF043","bitOr")},
		[0x7EF044] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF044","bitOr")},
		[0x7EF045] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF045","bitOr")},
		[0x7EF046] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF046","bitOr")},
		[0x7EF047] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF047","bitOr")},
		[0x7EF048] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF048","bitOr")},
		[0x7EF049] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF049","bitOr")},
		[0x7EF04A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF04A","bitOr")},
		[0x7EF04B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF04B","bitOr")},
		[0x7EF04C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF04C","bitOr")},
		[0x7EF04D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF04D","bitOr")},
		[0x7EF04E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF04E","bitOr")},
		[0x7EF04F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF04F","bitOr")},
		[0x7EF050] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF050","bitOr")},
		[0x7EF051] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF051","bitOr")},
		[0x7EF052] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF052","bitOr")},
		[0x7EF053] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF053","bitOr")},
		[0x7EF054] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF054","bitOr")},
		[0x7EF055] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF055","bitOr")},
		[0x7EF056] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF056","bitOr")},
		[0x7EF057] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF057","bitOr")},
		[0x7EF058] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF058","bitOr")},
		[0x7EF059] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF059","bitOr")},
		[0x7EF05A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF05A","bitOr")},
		[0x7EF05B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF05B","bitOr")},
		[0x7EF05C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF05C","bitOr")},
		[0x7EF05D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF05D","bitOr")},
		[0x7EF05E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF05E","bitOr")},
		[0x7EF05F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF05F","bitOr")},
		[0x7EF060] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF060","bitOr")},
		[0x7EF061] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF061","bitOr")},
		[0x7EF062] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF062","bitOr")},
		[0x7EF063] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF063","bitOr")},
		[0x7EF064] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF064","bitOr")},
		[0x7EF065] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF065","bitOr")},
		[0x7EF066] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF066","bitOr")},
		[0x7EF067] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF067","bitOr")},
		[0x7EF068] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF068","bitOr")},
		[0x7EF069] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF069","bitOr")},
		[0x7EF06A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF06A","bitOr")},
		[0x7EF06B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF06B","bitOr")},
		[0x7EF06C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF06C","bitOr")},
		[0x7EF06D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF06D","bitOr")},
		[0x7EF06E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF06E","bitOr")},
		[0x7EF06F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF06F","bitOr")},
		[0x7EF070] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF070","bitOr")},
		[0x7EF071] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF071","bitOr")},
		[0x7EF072] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF072","bitOr")},
		[0x7EF073] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF073","bitOr")},
		[0x7EF074] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF074","bitOr")},
		[0x7EF075] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF075","bitOr")},
		[0x7EF076] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF076","bitOr")},
		[0x7EF077] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF077","bitOr")},
		[0x7EF078] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF078","bitOr")},
		[0x7EF079] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF079","bitOr")},
		[0x7EF07A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF07A","bitOr")},
		[0x7EF07B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF07B","bitOr")},
		[0x7EF07C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF07C","bitOr")},
		[0x7EF07D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF07D","bitOr")},
		[0x7EF07E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF07E","bitOr")},
		[0x7EF07F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF07F","bitOr")},
		[0x7EF080] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF080","bitOr")},
		[0x7EF081] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF081","bitOr")},
		[0x7EF082] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF082","bitOr")},
		[0x7EF083] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF083","bitOr")},
		[0x7EF084] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF084","bitOr")},
		[0x7EF085] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF085","bitOr")},
		[0x7EF086] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF086","bitOr")},
		[0x7EF087] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF087","bitOr")},
		[0x7EF088] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF088","bitOr")},
		[0x7EF089] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF089","bitOr")},
		[0x7EF08A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF08A","bitOr")},
		[0x7EF08B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF08B","bitOr")},
		[0x7EF08C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF08C","bitOr")},
		[0x7EF08D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF08D","bitOr")},
		[0x7EF08E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF08E","bitOr")},
		[0x7EF08F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF08F","bitOr")},
		[0x7EF090] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF090","bitOr")},
		[0x7EF091] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF091","bitOr")},
		[0x7EF092] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF092","bitOr")},
		[0x7EF093] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF093","bitOr")},
		[0x7EF094] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF094","bitOr")},
		[0x7EF095] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF095","bitOr")},
		[0x7EF096] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF096","bitOr")},
		[0x7EF097] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF097","bitOr")},
		[0x7EF098] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF098","bitOr")},
		[0x7EF099] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF099","bitOr")},
		[0x7EF09A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF09A","bitOr")},
		[0x7EF09B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF09B","bitOr")},
		[0x7EF09C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF09C","bitOr")},
		[0x7EF09D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF09D","bitOr")},
		[0x7EF09E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF09E","bitOr")},
		[0x7EF09F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF09F","bitOr")},
		[0x7EF0A0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0A0","bitOr")},
		[0x7EF0A1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0A1","bitOr")},
		[0x7EF0A2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0A2","bitOr")},
		[0x7EF0A3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0A3","bitOr")},
		[0x7EF0A4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0A4","bitOr")},
		[0x7EF0A5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0A5","bitOr")},
		[0x7EF0A6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0A6","bitOr")},
		[0x7EF0A7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0A7","bitOr")},
		[0x7EF0A8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0A8","bitOr")},
		[0x7EF0A9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0A9","bitOr")},
		[0x7EF0AA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0AA","bitOr")},
		[0x7EF0AB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0AB","bitOr")},
		[0x7EF0AC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0AC","bitOr")},
		[0x7EF0AD] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0AD","bitOr")},
		[0x7EF0AE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0AE","bitOr")},
		[0x7EF0AF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0AF","bitOr")},
		[0x7EF0B0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0B0","bitOr")},
		[0x7EF0B1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0B1","bitOr")},
		[0x7EF0B2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0B2","bitOr")},
		[0x7EF0B3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0B3","bitOr")},
		[0x7EF0B4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0B4","bitOr")},
		[0x7EF0B5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0B5","bitOr")},
		[0x7EF0B6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0B6","bitOr")},
		[0x7EF0B7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0B7","bitOr")},
		[0x7EF0B8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0B8","bitOr")},
		[0x7EF0B9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0B9","bitOr")},
		[0x7EF0BA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0BA","bitOr")},
		[0x7EF0BB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0BB","bitOr")},
		[0x7EF0BC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0BC","bitOr")},
		[0x7EF0BD] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0BD","bitOr")},
		[0x7EF0BE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0BE","bitOr")},
		[0x7EF0BF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0BF","bitOr")},
		[0x7EF0C0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0C0","bitOr")},
		[0x7EF0C1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0C1","bitOr")},
		[0x7EF0C2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0C2","bitOr")},
		[0x7EF0C3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0C3","bitOr")},
		[0x7EF0C4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0C4","bitOr")},
		[0x7EF0C5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0C5","bitOr")},
		[0x7EF0C6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0C6","bitOr")},
		[0x7EF0C7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0C7","bitOr")},
		[0x7EF0C8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0C8","bitOr")},
		[0x7EF0C9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0C9","bitOr")},
		[0x7EF0CA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0CA","bitOr")},
		[0x7EF0CB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0CB","bitOr")},
		[0x7EF0CC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0CC","bitOr")},
		[0x7EF0CD] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0CD","bitOr")},
		[0x7EF0CE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0CE","bitOr")},
		[0x7EF0CF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0CF","bitOr")},
		[0x7EF0D0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0D0","bitOr")},
		[0x7EF0D1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0D1","bitOr")},
		[0x7EF0D2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0D2","bitOr")},
		[0x7EF0D3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0D3","bitOr")},
		[0x7EF0D4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0D4","bitOr")},
		[0x7EF0D5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0D5","bitOr")},
		[0x7EF0D6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0D6","bitOr")},
		[0x7EF0D7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0D7","bitOr")},
		[0x7EF0D8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0D8","bitOr")},
		[0x7EF0D9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0D9","bitOr")},
		[0x7EF0DA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0DA","bitOr")},
		[0x7EF0DB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0DB","bitOr")},
		[0x7EF0DC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0DC","bitOr")},
		[0x7EF0DD] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0DD","bitOr")},
		[0x7EF0DE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0DE","bitOr")},
		[0x7EF0DF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0DF","bitOr")},
		[0x7EF0E0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0E0","bitOr")},
		[0x7EF0E1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0E1","bitOr")},
		[0x7EF0E2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0E2","bitOr")},
		[0x7EF0E3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0E3","bitOr")},
		[0x7EF0E4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0E4","bitOr")},
		[0x7EF0E5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0E5","bitOr")},
		[0x7EF0E6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0E6","bitOr")},
		[0x7EF0E7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0E7","bitOr")},
		[0x7EF0E8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0E8","bitOr")},
		[0x7EF0E9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0E9","bitOr")},
		[0x7EF0EA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0EA","bitOr")},
		[0x7EF0EB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0EB","bitOr")},
		[0x7EF0EC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0EC","bitOr")},
		[0x7EF0ED] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0ED","bitOr")},
		[0x7EF0EE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0EE","bitOr")},
		[0x7EF0EF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0EF","bitOr")},
		[0x7EF0F0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0F0","bitOr")},
		[0x7EF0F1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0F1","bitOr")},
		[0x7EF0F2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0F2","bitOr")},
		[0x7EF0F3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0F3","bitOr")},
		[0x7EF0F4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0F4","bitOr")},
		[0x7EF0F5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0F5","bitOr")},
		[0x7EF0F6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0F6","bitOr")},
		[0x7EF0F7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0F7","bitOr")},
		[0x7EF0F8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0F8","bitOr")},
		[0x7EF0F9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0F9","bitOr")},
		[0x7EF0FA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0FA","bitOr")},
		[0x7EF0FB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0FB","bitOr")},
		[0x7EF0FC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0FC","bitOr")},
		[0x7EF0FD] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0FD","bitOr")},
		[0x7EF0FE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0FE","bitOr")},
		[0x7EF0FF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF0FF","bitOr")},
		[0x7EF100] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF100","bitOr")},
		[0x7EF101] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF101","bitOr")},
		[0x7EF102] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF102","bitOr")},
		[0x7EF103] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF103","bitOr")},
		[0x7EF104] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF104","bitOr")},
		[0x7EF105] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF105","bitOr")},
		[0x7EF106] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF106","bitOr")},
		[0x7EF107] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF107","bitOr")},
		[0x7EF108] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF108","bitOr")},
		[0x7EF109] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF109","bitOr")},
		[0x7EF10A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF10A","bitOr")},
		[0x7EF10B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF10B","bitOr")},
		[0x7EF10C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF10C","bitOr")},
		[0x7EF10D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF10D","bitOr")},
		[0x7EF10E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF10E","bitOr")},
		[0x7EF10F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF10F","bitOr")},
		[0x7EF110] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF110","bitOr")},
		[0x7EF111] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF111","bitOr")},
		[0x7EF112] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF112","bitOr")},
		[0x7EF113] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF113","bitOr")},
		[0x7EF114] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF114","bitOr")},
		[0x7EF115] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF115","bitOr")},
		[0x7EF116] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF116","bitOr")},
		[0x7EF117] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF117","bitOr")},
		[0x7EF118] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF118","bitOr")},
		[0x7EF119] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF119","bitOr")},
		[0x7EF11A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF11A","bitOr")},
		[0x7EF11B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF11B","bitOr")},
		[0x7EF11C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF11C","bitOr")},
		[0x7EF11D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF11D","bitOr")},
		[0x7EF11E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF11E","bitOr")},
		[0x7EF11F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF11F","bitOr")},
		[0x7EF120] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF120","bitOr")},
		[0x7EF121] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF121","bitOr")},
		[0x7EF122] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF122","bitOr")},
		[0x7EF123] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF123","bitOr")},
		[0x7EF124] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF124","bitOr")},
		[0x7EF125] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF125","bitOr")},
		[0x7EF126] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF126","bitOr")},
		[0x7EF127] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF127","bitOr")},
		[0x7EF128] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF128","bitOr")},
		[0x7EF129] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF129","bitOr")},
		[0x7EF12A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF12A","bitOr")},
		[0x7EF12B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF12B","bitOr")},
		[0x7EF12C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF12C","bitOr")},
		[0x7EF12D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF12D","bitOr")},
		[0x7EF12E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF12E","bitOr")},
		[0x7EF12F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF12F","bitOr")},
		[0x7EF130] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF130","bitOr")},
		[0x7EF131] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF131","bitOr")},
		[0x7EF132] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF132","bitOr")},
		[0x7EF133] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF133","bitOr")},
		[0x7EF134] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF134","bitOr")},
		[0x7EF135] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF135","bitOr")},
		[0x7EF136] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF136","bitOr")},
		[0x7EF137] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF137","bitOr")},
		[0x7EF138] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF138","bitOr")},
		[0x7EF139] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF139","bitOr")},
		[0x7EF13A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF13A","bitOr")},
		[0x7EF13B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF13B","bitOr")},
		[0x7EF13C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF13C","bitOr")},
		[0x7EF13D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF13D","bitOr")},
		[0x7EF13E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF13E","bitOr")},
		[0x7EF13F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF13F","bitOr")},
		[0x7EF140] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF140","bitOr")},
		[0x7EF141] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF141","bitOr")},
		[0x7EF142] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF142","bitOr")},
		[0x7EF143] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF143","bitOr")},
		[0x7EF144] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF144","bitOr")},
		[0x7EF145] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF145","bitOr")},
		[0x7EF146] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF146","bitOr")},
		[0x7EF147] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF147","bitOr")},
		[0x7EF148] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF148","bitOr")},
		[0x7EF149] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF149","bitOr")},
		[0x7EF14A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF14A","bitOr")},
		[0x7EF14B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF14B","bitOr")},
		[0x7EF14C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF14C","bitOr")},
		[0x7EF14D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF14D","bitOr")},
		[0x7EF14E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF14E","bitOr")},
		[0x7EF14F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF14F","bitOr")},
		[0x7EF150] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF150","bitOr")},
		[0x7EF151] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF151","bitOr")},
		[0x7EF152] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF152","bitOr")},
		[0x7EF153] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF153","bitOr")},
		[0x7EF154] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF154","bitOr")},
		[0x7EF155] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF155","bitOr")},
		[0x7EF156] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF156","bitOr")},
		[0x7EF157] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF157","bitOr")},
		[0x7EF158] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF158","bitOr")},
		[0x7EF159] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF159","bitOr")},
		[0x7EF15A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF15A","bitOr")},
		[0x7EF15B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF15B","bitOr")},
		[0x7EF15C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF15C","bitOr")},
		[0x7EF15D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF15D","bitOr")},
		[0x7EF15E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF15E","bitOr")},
		[0x7EF15F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF15F","bitOr")},
		[0x7EF160] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF160","bitOr")},
		[0x7EF161] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF161","bitOr")},
		[0x7EF162] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF162","bitOr")},
		[0x7EF163] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF163","bitOr")},
		[0x7EF164] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF164","bitOr")},
		[0x7EF165] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF165","bitOr")},
		[0x7EF166] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF166","bitOr")},
		[0x7EF167] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF167","bitOr")},
		[0x7EF168] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF168","bitOr")},
		[0x7EF169] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF169","bitOr")},
		[0x7EF16A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF16A","bitOr")},
		[0x7EF16B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF16B","bitOr")},
		[0x7EF16C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF16C","bitOr")},
		[0x7EF16D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF16D","bitOr")},
		[0x7EF16E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF16E","bitOr")},
		[0x7EF16F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF16F","bitOr")},
		[0x7EF170] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF170","bitOr")},
		[0x7EF171] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF171","bitOr")},
		[0x7EF172] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF172","bitOr")},
		[0x7EF173] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF173","bitOr")},
		[0x7EF174] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF174","bitOr")},
		[0x7EF175] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF175","bitOr")},
		[0x7EF176] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF176","bitOr")},
		[0x7EF177] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF177","bitOr")},
		[0x7EF178] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF178","bitOr")},
		[0x7EF179] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF179","bitOr")},
		[0x7EF17A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF17A","bitOr")},
		[0x7EF17B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF17B","bitOr")},
		[0x7EF17C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF17C","bitOr")},
		[0x7EF17D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF17D","bitOr")},
		[0x7EF17E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF17E","bitOr")},
		[0x7EF17F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF17F","bitOr")},
		[0x7EF180] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF180","bitOr")},
		[0x7EF181] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF181","bitOr")},
		[0x7EF182] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF182","bitOr")},
		[0x7EF183] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF183","bitOr")},
		[0x7EF184] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF184","bitOr")},
		[0x7EF185] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF185","bitOr")},
		[0x7EF186] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF186","bitOr")},
		[0x7EF187] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF187","bitOr")},
		[0x7EF188] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF188","bitOr")},
		[0x7EF189] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF189","bitOr")},
		[0x7EF18A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF18A","bitOr")},
		[0x7EF18B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF18B","bitOr")},
		[0x7EF18C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF18C","bitOr")},
		[0x7EF18D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF18D","bitOr")},
		[0x7EF18E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF18E","bitOr")},
		[0x7EF18F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF18F","bitOr")},
		[0x7EF190] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF190","bitOr")},
		[0x7EF191] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF191","bitOr")},
		[0x7EF192] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF192","bitOr")},
		[0x7EF193] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF193","bitOr")},
		[0x7EF194] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF194","bitOr")},
		[0x7EF195] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF195","bitOr")},
		[0x7EF196] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF196","bitOr")},
		[0x7EF197] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF197","bitOr")},
		[0x7EF198] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF198","bitOr")},
		[0x7EF199] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF199","bitOr")},
		[0x7EF19A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF19A","bitOr")},
		[0x7EF19B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF19B","bitOr")},
		[0x7EF19C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF19C","bitOr")},
		[0x7EF19D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF19D","bitOr")},
		[0x7EF19E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF19E","bitOr")},
		[0x7EF19F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF19F","bitOr")},
		[0x7EF1A0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1A0","bitOr")},
		[0x7EF1A1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1A1","bitOr")},
		[0x7EF1A2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1A2","bitOr")},
		[0x7EF1A3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1A3","bitOr")},
		[0x7EF1A4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1A4","bitOr")},
		[0x7EF1A5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1A5","bitOr")},
		[0x7EF1A6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1A6","bitOr")},
		[0x7EF1A7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1A7","bitOr")},
		[0x7EF1A8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1A8","bitOr")},
		[0x7EF1A9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1A9","bitOr")},
		[0x7EF1AA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1AA","bitOr")},
		[0x7EF1AB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1AB","bitOr")},
		[0x7EF1AC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1AC","bitOr")},
		[0x7EF1AD] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1AD","bitOr")},
		[0x7EF1AE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1AE","bitOr")},
		[0x7EF1AF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1AF","bitOr")},
		[0x7EF1B0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1B0","bitOr")},
		[0x7EF1B1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1B1","bitOr")},
		[0x7EF1B2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1B2","bitOr")},
		[0x7EF1B3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1B3","bitOr")},
		[0x7EF1B4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1B4","bitOr")},
		[0x7EF1B5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1B5","bitOr")},
		[0x7EF1B6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1B6","bitOr")},
		[0x7EF1B7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1B7","bitOr")},
		[0x7EF1B8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1B8","bitOr")},
		[0x7EF1B9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1B9","bitOr")},
		[0x7EF1BA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1BA","bitOr")},
		[0x7EF1BB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1BB","bitOr")},
		[0x7EF1BC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1BC","bitOr")},
		[0x7EF1BD] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1BD","bitOr")},
		[0x7EF1BE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1BE","bitOr")},
		[0x7EF1BF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1BF","bitOr")},
		[0x7EF1C0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1C0","bitOr")},
		[0x7EF1C1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1C1","bitOr")},
		[0x7EF1C2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1C2","bitOr")},
		[0x7EF1C3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1C3","bitOr")},
		[0x7EF1C4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1C4","bitOr")},
		[0x7EF1C5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1C5","bitOr")},
		[0x7EF1C6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1C6","bitOr")},
		[0x7EF1C7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1C7","bitOr")},
		[0x7EF1C8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1C8","bitOr")},
		[0x7EF1C9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1C9","bitOr")},
		[0x7EF1CA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1CA","bitOr")},
		[0x7EF1CB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1CB","bitOr")},
		[0x7EF1CC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1CC","bitOr")},
		[0x7EF1CD] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1CD","bitOr")},
		[0x7EF1CE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1CE","bitOr")},
		[0x7EF1CF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1CF","bitOr")},
		[0x7EF1D0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1D0","bitOr")},
		[0x7EF1D1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1D1","bitOr")},
		[0x7EF1D2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1D2","bitOr")},
		[0x7EF1D3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1D3","bitOr")},
		[0x7EF1D4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1D4","bitOr")},
		[0x7EF1D5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1D5","bitOr")},
		[0x7EF1D6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1D6","bitOr")},
		[0x7EF1D7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1D7","bitOr")},
		[0x7EF1D8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1D8","bitOr")},
		[0x7EF1D9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1D9","bitOr")},
		[0x7EF1DA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1DA","bitOr")},
		[0x7EF1DB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1DB","bitOr")},
		[0x7EF1DC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1DC","bitOr")},
		[0x7EF1DD] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1DD","bitOr")},
		[0x7EF1DE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1DE","bitOr")},
		[0x7EF1DF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1DF","bitOr")},
		[0x7EF1E0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1E0","bitOr")},
		[0x7EF1E1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1E1","bitOr")},
		[0x7EF1E2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1E2","bitOr")},
		[0x7EF1E3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1E3","bitOr")},
		[0x7EF1E4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1E4","bitOr")},
		[0x7EF1E5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1E5","bitOr")},
		[0x7EF1E6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1E6","bitOr")},
		[0x7EF1E7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1E7","bitOr")},
		[0x7EF1E8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1E8","bitOr")},
		[0x7EF1E9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1E9","bitOr")},
		[0x7EF1EA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1EA","bitOr")},
		[0x7EF1EB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1EB","bitOr")},
		[0x7EF1EC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1EC","bitOr")},
		[0x7EF1ED] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1ED","bitOr")},
		[0x7EF1EE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1EE","bitOr")},
		[0x7EF1EF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1EF","bitOr")},
		[0x7EF1F0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1F0","bitOr")},
		[0x7EF1F1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1F1","bitOr")},
		[0x7EF1F2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1F2","bitOr")},
		[0x7EF1F3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1F3","bitOr")},
		[0x7EF1F4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1F4","bitOr")},
		[0x7EF1F5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1F5","bitOr")},
		[0x7EF1F6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1F6","bitOr")},
		[0x7EF1F7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1F7","bitOr")},
		[0x7EF1F8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1F8","bitOr")},
		[0x7EF1F9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1F9","bitOr")},
		[0x7EF1FA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1FA","bitOr")},
		[0x7EF1FB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1FB","bitOr")},
		[0x7EF1FC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1FC","bitOr")},
		[0x7EF1FD] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1FD","bitOr")},
		[0x7EF1FE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1FE","bitOr")},
		[0x7EF1FF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF1FF","bitOr")},
		[0x7EF200] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF200","bitOr")},
		[0x7EF201] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF201","bitOr")},
		[0x7EF202] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF202","bitOr")},
		[0x7EF203] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF203","bitOr")},
		[0x7EF204] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF204","bitOr")},
		[0x7EF205] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF205","bitOr")},
		[0x7EF206] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF206","bitOr")},
		[0x7EF207] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF207","bitOr")},
		[0x7EF208] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF208","bitOr")}, --Link's House
		[0x7EF209] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF209","bitOr")},
		[0x7EF20A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF20A","bitOr")},
		[0x7EF20B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF20B","bitOr")},
		[0x7EF20C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF20C","bitOr")},
		[0x7EF20D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF20D","bitOr")},
		[0x7EF20E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF20E","bitOr")},
		[0x7EF20F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF20F","bitOr")},
		[0x7EF210] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF210","bitOr")},
		[0x7EF211] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF211","bitOr")},
		[0x7EF212] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF212","bitOr")},
		[0x7EF213] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF213","bitOr")},
		[0x7EF214] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF214","bitOr")},
		[0x7EF215] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF215","bitOr")},
		[0x7EF216] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF216","bitOr")},
		[0x7EF217] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF217","bitOr")},
		[0x7EF218] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF218","bitOr")},
		[0x7EF219] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF219","bitOr")},
		[0x7EF21A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF21A","bitOr")},
		[0x7EF21B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF21B","bitOr")},
		[0x7EF21C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF21C","bitOr")},
		[0x7EF21D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF21D","bitOr")},
		[0x7EF21E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF21E","bitOr")},
		[0x7EF21F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF21F","bitOr")},
		[0x7EF220] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF220","bitOr")},
		[0x7EF221] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF221","bitOr")},
		[0x7EF222] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF222","bitOr")},
		[0x7EF223] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF223","bitOr")},
		[0x7EF224] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF224","bitOr")},
		[0x7EF225] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF225","bitOr")},
		[0x7EF226] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF226","bitOr")},
		[0x7EF227] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF227","bitOr")},
		[0x7EF228] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF228","bitOr")},
		[0x7EF229] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF229","bitOr")},
		[0x7EF22A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF22A","bitOr")},
		[0x7EF22B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF22B","bitOr")},
		[0x7EF22C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF22C","bitOr")},
		[0x7EF22D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF22D","bitOr")},
		[0x7EF22E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF22E","bitOr")},
		[0x7EF22F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF22F","bitOr")},
		[0x7EF230] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF230","bitOr")},
		[0x7EF231] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF231","bitOr")},
		[0x7EF232] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF232","bitOr")},
		[0x7EF233] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF233","bitOr")},
		[0x7EF234] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF234","bitOr")},
		[0x7EF235] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF235","bitOr")},
		[0x7EF236] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF236","bitOr")},
		[0x7EF237] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF237","bitOr")},
		[0x7EF238] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF238","bitOr")},
		[0x7EF239] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF239","bitOr")},
		[0x7EF23A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF23A","bitOr")},
		[0x7EF23B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF23B","bitOr")},
		[0x7EF23C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF23C","bitOr")},
		[0x7EF23D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF23D","bitOr")},
		[0x7EF23E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF23E","bitOr")},
		[0x7EF23F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF23F","bitOr")},
		[0x7EF240] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF240","bitOr")},
		[0x7EF241] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF241","bitOr")},
		[0x7EF242] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF242","bitOr")},
		[0x7EF243] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF243","bitOr")},
		[0x7EF244] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF244","bitOr")},
		[0x7EF245] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF245","bitOr")},
		[0x7EF246] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF246","bitOr")},
		[0x7EF247] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF247","bitOr")},
		[0x7EF248] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF248","bitOr")},
		[0x7EF249] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF249","bitOr")},
		[0x7EF24A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF24A","bitOr")},
		[0x7EF24B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF24B","bitOr")},
		[0x7EF24C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF24C","bitOr")},
		[0x7EF24D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF24D","bitOr")},
		[0x7EF24E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF24E","bitOr")},
		[0x7EF24F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF24F","bitOr")},
		--OVERWORLD--
		[0x7EF280] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF280","bitOr")},
		[0x7EF281] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF281","bitOr")},
		[0x7EF282] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF282","bitOr")},
		[0x7EF283] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF283","bitOr")},
		[0x7EF284] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF284","bitOr")},
		[0x7EF285] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF285","bitOr")},
		[0x7EF286] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF286","bitOr")},
		[0x7EF287] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF287","bitOr")},
		[0x7EF288] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF288","bitOr")},
		[0x7EF289] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF289","bitOr")},
		[0x7EF28A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF28A","bitOr")},
		[0x7EF28B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF28B","bitOr")},
		[0x7EF28C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF28C","bitOr")},
		[0x7EF28D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF28D","bitOr")},
		[0x7EF28E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF28E","bitOr")},
		[0x7EF28F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF28F","bitOr")},
		[0x7EF290] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF290","bitOr")},
		[0x7EF291] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF291","bitOr")},
		[0x7EF292] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF292","bitOr")},
		[0x7EF293] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF293","bitOr")},
		[0x7EF294] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF294","bitOr")},
		[0x7EF295] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF295","bitOr")},
		[0x7EF296] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF296","bitOr")},
		[0x7EF297] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF297","bitOr")},
		[0x7EF298] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF298","bitOr")},
		[0x7EF299] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF299","bitOr")},
		[0x7EF29A] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF29A","bitOr")},
		[0x7EF29B] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF29B","bitOr")},
		[0x7EF29C] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF29C","bitOr")},
		[0x7EF29D] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF29D","bitOr")},
		[0x7EF29E] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF29E","bitOr")},
		[0x7EF29F] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF29F","bitOr")},
		[0x7EF2A0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2A0","bitOr")},
		[0x7EF2A1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2A1","bitOr")},
		[0x7EF2A2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2A2","bitOr")},
		[0x7EF2A3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2A3","bitOr")},
		[0x7EF2A4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2A4","bitOr")},
		[0x7EF2A5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2A5","bitOr")},
		[0x7EF2A6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2A6","bitOr")},
		[0x7EF2A7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2A7","bitOr")},
		[0x7EF2A8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2A8","bitOr")},
		[0x7EF2A9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2A9","bitOr")},
		[0x7EF2AA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2AA","bitOr")},
		[0x7EF2AB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2AB","bitOr")},
		[0x7EF2AC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2AC","bitOr")},
		[0x7EF2AD] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2AD","bitOr")},
		[0x7EF2AE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2AE","bitOr")},
		[0x7EF2AF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2AF","bitOr")},
		[0x7EF2B0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2B0","bitOr")},
		[0x7EF2B1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2B1","bitOr")},
		[0x7EF2B2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2B2","bitOr")},
		[0x7EF2B3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2B3","bitOr")},
		[0x7EF2B4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2B4","bitOr")},
		[0x7EF2B5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2B5","bitOr")},
		[0x7EF2B6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2B6","bitOr")},
		[0x7EF2B7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2B7","bitOr")},
		[0x7EF2B8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2B8","bitOr")},
		[0x7EF2B9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2B9","bitOr")},
		[0x7EF2BA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2BA","bitOr")},
		[0x7EF2BB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2BB","bitOr")},
		[0x7EF2BC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2BC","bitOr")},
		[0x7EF2BD] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2BD","bitOr")},
		[0x7EF2BE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2BE","bitOr")},
		[0x7EF2BF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2BF","bitOr")},
		[0x7EF2C0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2C0","bitOr")},
		[0x7EF2C1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2C1","bitOr")},
		[0x7EF2C2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2C2","bitOr")},
		[0x7EF2C3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2C3","bitOr")},
		[0x7EF2C4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2C4","bitOr")},
		[0x7EF2C5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2C5","bitOr")},
		[0x7EF2C6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2C6","bitOr")},
		[0x7EF2C7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2C7","bitOr")},
		[0x7EF2C8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2C8","bitOr")},
		[0x7EF2C9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2C9","bitOr")},
		[0x7EF2CA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2CA","bitOr")},
		[0x7EF2CB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2CB","bitOr")},
		[0x7EF2CC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2CC","bitOr")},
		[0x7EF2CD] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2CD","bitOr")},
		[0x7EF2CE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2CE","bitOr")},
		[0x7EF2CF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2CF","bitOr")},
		[0x7EF2D0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2D0","bitOr")},
		[0x7EF2D1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2D1","bitOr")},
		[0x7EF2D2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2D2","bitOr")},
		[0x7EF2D3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2D3","bitOr")},
		[0x7EF2D4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2D4","bitOr")},
		[0x7EF2D5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2D5","bitOr")},
		[0x7EF2D6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2D6","bitOr")},
		[0x7EF2D7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2D7","bitOr")},
		[0x7EF2D8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2D8","bitOr")},
		[0x7EF2D9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2D9","bitOr")},
		[0x7EF2DA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2DA","bitOr")},
		[0x7EF2DB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2DB","bitOr")},
		[0x7EF2DC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2DC","bitOr")},
		[0x7EF2DD] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2DD","bitOr")},
		[0x7EF2DE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2DE","bitOr")},
		[0x7EF2DF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2DF","bitOr")},
		[0x7EF2E0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2E0","bitOr")},
		[0x7EF2E1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2E1","bitOr")},
		[0x7EF2E2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2E2","bitOr")},
		[0x7EF2E3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2E3","bitOr")},
		[0x7EF2E4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2E4","bitOr")},
		[0x7EF2E5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2E5","bitOr")},
		[0x7EF2E6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2E6","bitOr")},
		[0x7EF2E7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2E7","bitOr")},
		[0x7EF2E8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2E8","bitOr")},
		[0x7EF2E9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2E9","bitOr")},
		[0x7EF2EA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2EA","bitOr")},
		[0x7EF2EB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2EB","bitOr")},
		[0x7EF2EC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2EC","bitOr")},
		[0x7EF2ED] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2ED","bitOr")},
		[0x7EF2EE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2EE","bitOr")},
		[0x7EF2EF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2EF","bitOr")},
		[0x7EF2F0] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2F0","bitOr")},
		[0x7EF2F1] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2F1","bitOr")},
		[0x7EF2F2] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2F2","bitOr")},
		[0x7EF2F3] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2F3","bitOr")},
		[0x7EF2F4] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2F4","bitOr")},
		[0x7EF2F5] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2F5","bitOr")},
		[0x7EF2F6] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2F6","bitOr")},
		[0x7EF2F7] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2F7","bitOr")},
		[0x7EF2F8] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2F8","bitOr")},
		[0x7EF2F9] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2F9","bitOr")},
		[0x7EF2FA] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2FA","bitOr")},
		[0x7EF2FB] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2FB","bitOr")},
		[0x7EF2FC] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2FC","bitOr")},
		[0x7EF2FD] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2FD","bitOr")},
		[0x7EF2FE] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2FE","bitOr")},
		[0x7EF2FF] = {kind="trigger",   writeTrigger=zeldaQueueTrigger("0x7EF2FF","bitOr")},		
		
		
		------------------------------
		--------Zelda Menu Fix--------
		------------------------------
		[0x7E0FFC] = {nameMap={"Menu"}, kind="trigger", writeTrigger=zeldaMenuTrigger("0x7E0FFC")},
		
		
		
		------------------------------
		-------------Keys-------------
		------------------------------
		[0x7EF37C] = {kind="trigger",    writeTrigger=zeldaKeyQueueTrigger("0x7EF37C")},
		[0x7EF37D] = {kind="trigger",    writeTrigger=zeldaKeyQueueTrigger("0x7EF37D")},
		[0x7EF37E] = {kind="trigger",    writeTrigger=zeldaKeyQueueTrigger("0x7EF37E")},
		[0x7EF37F] = {kind="trigger",    writeTrigger=zeldaKeyQueueTrigger("0x7EF37F")},
		[0x7EF380] = {kind="trigger",    writeTrigger=zeldaKeyQueueTrigger("0x7EF380")},
		[0x7EF381] = {kind="trigger",    writeTrigger=zeldaKeyQueueTrigger("0x7EF381")},
		[0x7EF382] = {kind="trigger",    writeTrigger=zeldaKeyQueueTrigger("0x7EF382")},
		[0x7EF383] = {kind="trigger",    writeTrigger=zeldaKeyQueueTrigger("0x7EF383")},
		[0x7EF384] = {kind="trigger",    writeTrigger=zeldaKeyQueueTrigger("0x7EF384")},
		[0x7EF385] = {kind="trigger",    writeTrigger=zeldaKeyQueueTrigger("0x7EF385")},
		[0x7EF386] = {kind="trigger",    writeTrigger=zeldaKeyQueueTrigger("0x7EF386")},
		[0x7EF387] = {kind="trigger",    writeTrigger=zeldaKeyQueueTrigger("0x7EF387")},
		[0x7EF388] = {kind="trigger",    writeTrigger=zeldaKeyQueueTrigger("0x7EF388")},
		[0x7EF389] = {kind="trigger",    writeTrigger=zeldaKeyQueueTrigger("0x7EF389")},
	},
	custom = { -- sync high and bit values to take only high or OR'ed values, and set previous for target address
		
		zsync = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = tonumber(string.sub(payload, 9), 10)
			local currentGame = memoryRead(0xA173FE)
			if noSend == true and backup[address] ~= nil then
				if currentGame == 0 then
					backup[address] = {value, "z",0,1}
				else 
					backup[address+ZSTORAGE] = {value, "z",0,1}
				end
			else
				if currentGame == 0 then
					memoryWrite(address, value)
					previous[address] = value 
					--message("wrote val to Zelda while in Zelda")
				else
					local addressHex = address + ZSTORAGE
					memoryWrite(addressHex, value)
					previous[address] = value
					--message("wrote val to Zelda while in Metroid")
				end
			end
		end,
		
		zsyncqueueval = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = tonumber(string.sub(payload, 9),10)
			local currentGame = memoryRead(0xA173FE)
			if currentGame == 0 then
				if noSend == true and backup[address] ~= nil then
					message("wrote " .. value .. " at " .. address .. ";  previous was " .. memoryRead(address))
					backup[address] = {value, backup[address][2], backup[address][3], backup[address][4]}
					memoryWrite(address, value)
					previous[address] = value
				else
					message("valSync")
					memoryWrite(address, value)
					previous[address] = value
				end
			else 
				message("hiQ")
				queuezval[address] = value
			end
		end,
		
		zsyncqueuebit = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = tonumber(string.sub(payload, 9),10)
			local currentGame = memoryRead(0xA173FE)
			if currentGame == 0 then
				if noSend == true and backup[address] ~= nil then
					message("wrote " .. value .. " at " .. address .. ";  previous was " .. memoryRead(address))
					backup[address] = {value, backup[address][2], backup[address][3], backup[address][4]}
					memoryWrite(address, value)
					previous[address] = value
				else
					message("bitSync")
					if previous[address] == nil then	
						previous[address] = memoryRead(address)
					end
					memoryWrite(address, OR(value, previous[address]))
					previous[address] = OR(value, previous[address])
				end
			else 
				message("bitQ")
				queuezbit[address] = value
			end
		end,
		
		zsyncqueuehigh = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = tonumber(string.sub(payload, 9),10)
			local currentGame = memoryRead(0xA173FE)
			if currentGame == 0 then
				if noSend == true and backup[address] ~= nil then
					message("wrote " .. value .. " at " .. address .. ";  previous was " .. memoryRead(address))
					backup[address] = {value, backup[address][2], backup[address][3], backup[address][4]}
					memoryWrite(address, value)
					previous[address] = value
				else
					message("hiSync")
					if previous[address] == nil then	
						previous[address] = memoryRead(address)
					end
					if value > previous[address] then
						memoryWrite(address, value)
					end
				end
			else 
				message("hiQ")
				queuezhigh[address] = value
				previous[address] = value
			end
		end,
		
		zsyncbit = function(payload)
		if payload ~= nil then
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = tonumber(string.sub(payload, 9), 10)
			local currentGame = memoryRead(0xA173FE)
			if noSend == true and backup[address] ~= nil then
				if currentGame == 0 then
					backup[address] = {value, "z",0,1}
				else 
					backup[address+ZSTORAGE] = {value, "z",0,1}
				end
			else
				if currentGame == 0 then
					local previousValue = memoryRead(address)
					if previousValue == nil then
						previousValue = 0
					end
					memoryWrite(address, OR(value, previousValue))
				else
					local addressHex = address + ZSTORAGE
					local previousValue = memoryRead(addressHex)
					if previousValue == nil then
						previousValue = 0
					end
					memoryWrite(addressHex, OR(value, previousValue))
				end
			end
		end
		end,
		
		msync = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local mask = tonumber(string.sub(payload, 9, 12), 16)
			local value = tonumber(string.sub(payload, 13),10)
			local currentGame = memoryRead(0xA173FE)
			--message(string.sub(payload, 1, 8))
			--message(string.sub(payload, 9, 12))
			--message(string.sub(payload, 13))
			if currentGame == 0 then
				local addressHex = address + MSTORAGE
				local previousValue = memoryRead(addressHex)
				if previousValue == nil then
					previousValue = 0
				end
				memoryWrite(addressHex, OR(value, previousValue))
				makeItemTrigger(addressHex-2, mask, value, previousValue)
			else
				local previousValue = memoryRead(address)
				if previousValue == nil then
					previousValue = 0
				end
				memoryWrite(address, OR(value, previousValue))
				makeItemTrigger(address-2, mask, value, previousValue)
			end
		end,
		
		msyncqueueval = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = tonumber(string.sub(payload, 9),10)
			local currentGame = memoryRead(0xA173FE)
			if currentGame == 255 then
				if noSend == true and backup[address] ~= nil then
					backup[address] = {value, backup[address][2], backup[address][3], backup[address][4]}
					memoryWrite(address, value)
					previous[address] = value
				else
					message("valSync")
					memoryWrite(address, value)
					previous[address] = value
				end
			else 
				message("hiQ")
				queuemval[address] = value
				previous[address] = value
			end
		end,
		
		msyncqueuebit = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = tonumber(string.sub(payload, 9),10)
			local currentGame = memoryRead(0xA173FE)
			if currentGame == 255 then
				if noSend == true and backup[address] ~= nil then
					backup[address] = {value, backup[address][2], backup[address][3], backup[address][4]}
					memoryWrite(address, value)
					previous[address] = value
				else
					message("bitSync")
					if previous[address] == nil then
						previous[address] = memoryRead(address)
					end
					memoryWrite(address, OR(value, previous[address]))
					previous[address] = OR(value, previous[address])
				end
			else 
				message("bitQ")
				queuembit[address] = value
			end
		end,
		
		msyncqueuehigh = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = tonumber(string.sub(payload, 9),10)
			local currentGame = memoryRead(0xA173FE)
			if currentGame == 255 then
				if noSend == true and backup[address] ~= nil then
					backup[address] = {value, backup[address][2], backup[address][3], backup[address][4]}
					memoryWrite(address, value)
					previous[address] = value
				else
					message("hiSync")
					if previous[address] == nil then
						previous[address] = memoryRead(address)
					end
					if value > previous[address] then
						memoryWrite(address, value)
						previous[address] = value
					end
				end
			else 
				message("hiQ")
				queuemhigh[address] = value
			end
		end,
		
		msyncbit = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = tonumber(string.sub(payload, 9), 10)
			local currentGame = memoryRead(0xA173FE)
			if noSend == true and backup[address] ~= nil then
				if currentGame == 255 then
					backup[address] = {value, backup[address][2], backup[address][3], backup[address][4]}
				else 
					backup[address+MSTORAGE] = {value, backup[address+MSTORAGE][2], backup[address+MSTORAGE][3]}
				end
			else
				if currentGame == 0 then
					local addressHex = address + MSTORAGE
					local previousValue = memoryRead(addressHex)
					if previousValue == nil then
						previousValue = 0
					end
					memoryWrite(addressHex, OR(value, previousValue), 2)
				else
					local previousValue = memoryRead(address)
					if previousValue == nil then
						previousValue = 0
					end
					memoryWrite(address, OR(value, previousValue), 2)
				end
			end
		end,
		
		msyncbeam = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = tonumber(string.sub(payload, 9),10)
			--message("recieved value " .. value .. "for beam sync")
			local currentGame = memoryRead(0xA173FE)
			if currentGame == 0 then
				local addressHex = address + MSTORAGE
				memoryWrite(addressHex, value)
			else
				memoryWrite(address, value)
			end
		end,
		
		msyncbeamequip = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = tonumber(string.sub(payload, 9),10)
			--message("recieved value " .. value .. "for beam equip")
			if currentGame == 0 then
				local current = memory.readbyte(address + MSTORAGE)
				local currentEquip = memory.readbyte(address-2 + MSTORAGE)
				if current == nil then
					current = 0
				end
				if currentEquip == nil then
					currentEquip = 0
				end
				newItem = value
				newVal = OR(currentEquip, newItem)
				--message(newVal)
				if newVal >= 12 and address == 0x7E09A8 then
					newVal = newVal - 4
				end
				memory.writebyte(address - 2 + MSTORAGE, newVal)
				--message("wrote beamequip to Metroid while in Metroid")
			else
				local current = memory.readbyte(address)
				local currentEquip = memory.readbyte(address - 2)
				if current == nil then
					current = 0
				end
				if currentEquip == nil then
					currentEquip = 0
				end
				--message(value)
				newItem = value
				newVal = OR(currentEquip, newItem)
				--message(newVal)
				if newVal >= 12 and address == 0x7E09A8 then
					newVal = newVal - 4
				end
				memory.writebyte(address - 2, newVal)
				--message("wrote beamequip to Metroid while in Metroid")
			end
		end,
		
		msyncexp = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = string.sub(payload, 9)
			local newVal = tonumber(value, 10)
			local currentGame = memoryRead(0xA173FE)
			if noSend == true and backup[address] ~= nil then
				if currentGame == 255 then
					backup[address] = {value, backup[address][2], backup[address][3], backup[address][4]}
				else 
					backup[address+MSTORAGE] = {value, backup[address+MSTORAGE][2], backup[address+MSTORAGE][3]}
				end
			else
				if currentGame == 0 then
					local addressHex = address + MSTORAGE
					local ammoCount = memory.readword(addressHex-2)
					local oldVal = memory.readword(addressHex)
					if newVal > oldVal then
						memoryWrite(addressHex, value, 2)
						--message("wrote expansion to Metroid while in Zelda")
						memory.writeword(addressHex - 2, ammoCount + 5) -- Add 5 ammo
					end
				else
					local ammoCount = memory.readword(address-2)
					local oldVal = memory.readword(address)
					if newVal > oldVal then
						memoryWrite(address, value, 2)
						--message("wrote expansion to Metroid while in Metroid")
						memory.writeword(address - 2, ammoCount + 5) -- Add 5 ammo
					end
				end
			end
		end,
		
		msynctank = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = string.sub(payload, 9)
			local currentGame = memoryRead(0xA173FE)
			local newVal = tonumber(value, 10)
			if noSend == true and backup[address] ~= nil then
				if currentGame == 255 then
					backup[address] = {value, backup[address][2], backup[address][3], backup[address][4]}
				else 
					backup[address+MSTORAGE] = {value, backup[address+MSTORAGE][2], backup[address+MSTORAGE][3]}
				end
			else
				if currentGame == 0 then
					local addressHex = address + MSTORAGE
					local oldVal = memory.readword(addressHex)
					if newVal > oldVal then
						memory.writeword(0x7E09C2 + MSTORAGE, value) -- Refill health on any Etank collection
						memoryWrite(addressHex, value, 2)
						--message("wrote E-tank to Metroid while in Zelda")
					end
				else
					local oldVal = memory.readword(address)
					if newVal > oldVal then
						memory.writeword(0x7E09C2, value) -- Refill health on any Etank collection
						memoryWrite(address, value, 2)
						--message("wrote E-tank to Metroid while in Metroid")
					end
				end
			end
		end,
		
		msynctankreserve = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = string.sub(payload, 9)
			local currentGame = memoryRead(0xA173FE)
			if noSend == true and backup[address] ~= nil then
				if currentGame == 255 then
					backup[address] = {value, backup[address][2], backup[address][3], backup[address][4]}
				else 
					backup[address+MSTORAGE] = {value, backup[address+MSTORAGE][2], backup[address+MSTORAGE][3]}
				end
			else
				if currentGame == 0 then
					local addressHex = address + MSTORAGE
					memoryWrite(addressHex, value, 2)
					--message("wrote R-tank to Metroid while in Zelda")
				else
					memoryWrite(address, value, 2)
					--message("wrote R-tank to Metroid while in Metroid")
				end
			end
		end,
		
		mroomswap = function(payload)
			partnerGame = 255
			partnerRoom = tonumber(payload, 10)
			message(partnerGame)
			message(partnerRoom)
		end,
		
		zroomswap = function(payload)
			partnerGame = 0
			partnerRoom = tonumber(payload, 10)
			message(partnerGame)
			message(partnerRoom)
		end
		
	}
}