-- ACTUAL WORK HAPPENS HERE

function memoryRead(addr, size)
	if not size or size == 1 then
		return memory.readbyte(addr)
	elseif size == 2 then
		return memory.readword(addr)
	elseif size == 4 then
		return memory.readdword(addr)
	else
		error("Invalid size to memoryRead")
	end
end

function memoryWrite(addr, value, size)
	if not size or size == 1 then
		memory.writebyte(addr, value)
	elseif size == 2 then
		memory.writeword(addr, value)
	elseif size == 4 then
		memory.writedword(addr, value)
	else
		error("Invalid size to memoryWrite")
	end
end

function recordChanged(record, value, previousValue, receiving)
	local allow = true

	if type(record.kind) == "function" then
		allow, value = record.kind(value, previousValue, receiving)
	elseif record.kind == "high" then
		allow = value > previousValue
	elseif record.kind == "bitOr" then
		local maskedValue         = value                        -- Backup value and previousValue
		local maskedPreviousValue = previousValue

		if record.mask then                                      -- If necessary, mask both before checking
			maskedValue = AND(maskedValue, record.mask)
			maskedPreviousValue = AND(maskedPreviousValue, record.mask)
		end

		maskedValue = OR(maskedValue, maskedPreviousValue)

		allow = maskedValue ~= maskedPreviousValue               -- Did operated-on bits change?
		value = OR(previousValue, maskedValue)                   -- Copy operated-on bits back into value
	else
		allow = value ~= previousValue
	end
	if allow and record.cond then
		allow = performTest(record.cond, value, record.size)
	end
	return allow, value
end

function performTest(record, valueOverride, sizeOverride)
	if not record then return true end

	if record[1] == "test" then
		local value = valueOverride or memoryRead(record.addr, sizeOverride or record.size)
		return (not record.gte or value >= record.gte) and
			   (not record.lte or value <= record.lte)
	elseif record[1] == "stringtest" then
		local test = record.value
		local len = #test
		local addr = record.addr

		for i=1,len do
			if string.byte(test, i) ~= memory.readbyte(addr + i - 1) then
				return false
			end
		end
		return true
	elseif record[1] == "modulo" then
		return valueOverride % record.mod == 0
	else
		return false
	end
end

class.GameDriver(Driver)
function GameDriver:_init(spec, forceSend)
	self.spec = spec
	self.sleepQueue = {}
	self.forceSend = forceSend
	self.didCache = false
	
	-- Tracks memory locations until a settling period has elapsed, then allows further updates
	self.settlingAddresses = {}
end

function GameDriver:checkFirstRunning() -- Do first-frame bootup-- only call if isRunning()
	if not self.didCache then
		if driverDebug then print("First moment running") end

		for k,v in pairs(self.spec.sync) do -- Enter all current values into cache so we don't send pointless 0 values later
			local value = memoryRead(k, v.size)
			if not v.cache then v.cache = value end

			if self.forceSend then -- Restoring after a crash send all values regardless of importance
				if value ~= 0 then -- FIXME: This is adequate for all current specs but maybe it will not be in future?!
					if driverDebug then print("Sending address " .. tostring(k) .. " at startup") end

					self:sendTable({addr=k, value=value})
				end
			end
		end

		if self.spec.startup then
			self.spec.startup(self.forceSend)
		end

		self.didCache = true
	end
end

function GameDriver:childTick()
	if self:isRunning() then
		self:checkFirstRunning()

		if #self.sleepQueue > 0 then
			local sleepQueue = self.sleepQueue
			self.sleepQueue = {}
			for i, v in ipairs(sleepQueue) do
				self:handleTable(v)
			end
		end
	end
end

function GameDriver:childWake()
	self:sendTable({"hello", version=version.release, guid=self.spec.guid})

	for k,v in pairs(self.spec.sync) do
		local syncTable = self.spec.sync -- Assume sync table is not replaced at runtime
		local baseAddr = k - (k%2)       -- 16-bit aligned equivalent of address
		local size = v.size or 1

		local function callback(a,b) -- I have no idea what "b" is but snes9x passes it
			-- So, this is pretty awful: There is a bug in some versions of snes9x-rr where you if you have registered a registerwrite for an even and odd address,
			-- SOMETIMES (not always) writing to the odd address will trigger the even address's callback instead. So when we get a callback we trigger the underlying
			-- callback twice, once for each byte in the current word. This does mean caughtWrite() must tolerate spurious extra calls.
			for offset=0,1 do
				local checkAddr = baseAddr + offset
				local record = syncTable[checkAddr]
				if record then self:caughtWrite(checkAddr, b, record, size) end
			end
		end

		memory.registerwrite (k, size, callback)
	end
end

function GameDriver:isRunning()
	return performTest(self.spec.running)
end

function GameDriver:caughtWrite(addr, arg2, record, size)
	local running = self.spec.running

	if self:isRunning() then -- TODO: Yes, we got record, but double check
		self:checkFirstRunning()

		local allow = true
		local value = memoryRead(addr, size)

		if record.timer then
			if value % record.cond.mod == 0 then
				self.settlingAddresses = {}
			end
			
			return
		end
		
		if record.cache then
			allow = recordChanged(record, value, record.cache, false)
		end

		
		if allow and record.settle then -- ensure memory location has settled before allowing
			allow = self.settlingAddresses[addr] == nil
			
			if allow then
				self.settlingAddresses[addr] = value
				if driverDebug then print("Added settle to table: " .. tostring(addr)) end
			end
		end

		if allow then
			record.cache = value -- FIXME: Should this cache EVER be cleared? What about when a new game starts?

			self:sendTable({addr=addr, value=value})
		end
	else
		if driverDebug then print("Ignored memory write because the game is not running") end
	end
end

function GameDriver:handleTable(t)
	if t[1] == "hello" then
		if t.guid ~= self.spec.guid then
			self.pipe:abort("Partner has an incompatible .lua file for this game.")
			print("Partner's game mode file has guid:\n" .. tostring(t.guid) .. "\nbut yours has:\n" .. tostring(self.spec.guid))
		end
		return
	end

	local addr = t.addr
	local record = self.spec.sync[addr]
	if self:isRunning() then
		self:checkFirstRunning()

		if record then
			local value = t.value
			local allow = true
			local previousValue = memoryRead(addr, record.size)

			allow, value = recordChanged(record, value, previousValue, true)

			if allow then
				if record.receiveTrigger then -- Extra setup/cleanup on receive
					record.receiveTrigger(value, previousValue)
				end

				local name = record.name
				local names = nil

				if not name and record.nameMap then
					name = record.nameMap[value]
				end

				if name then
					names = {name}
				elseif record.nameBitmap then
					names = {}
					for b=0,7 do
						if 0 ~= AND(BIT(b), value) and 0 == AND(BIT(b), previousValue) then
							table.insert(names, record.nameBitmap[b + 1])
						end
					end
				end

				if names then
					local verb = record.verb or "got"
					for i, v in ipairs(names) do
						message("Partner " .. verb .. " " .. v)
					end
				else
					if driverDebug then print("Updated anonymous address " .. tostring(addr) .. " to " .. tostring(value)) end
				end
				record.cache = value
				memoryWrite(addr, value, record.size)
			end
		else
			if driverDebug then print("Unknown memory address was " .. tostring(addr)) end
			message("Partner changed unknown memory address...? Uh oh")
		end
	else
		if driverDebug then print("Queueing partner memory write because the game is not running") end
		table.insert(self.sleepQueue, t)
	end
end

function GameDriver:handleError(s, err)
	print("FAILED TABLE LOAD " .. err)
end
