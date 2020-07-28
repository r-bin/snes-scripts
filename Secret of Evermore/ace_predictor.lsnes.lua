RNG_BYTES = { 0x0133, 0x0134, 0x0135, 0x0136, 0x0137, 0x0138, 0x0139, 0x013A }
DESIRED_WORDS = { 0x4218,0x4219, 0x421A,0x421B, 0x421C,0x421D, 0x421E,0x421F,
					0x0104}
BLACK_LIST = { 0x0011, 0x0013, 0x0015, 0x0016, 0x0017 }
WATCH_LIST = { 0x0066 }

RNG_NUMBER = 0x00
FRAME = 0x00

function range()
	local range = {}
	
	for i=0, 0x80 do
		table.insert(range, 0x0000 + i)
	end
	for i=0x81, 0xFF do
		table.insert(range, 0xFF00 + i)
	end
	
	return range
end
RANGE = range()

function dump_loram()
	local out = io.open('file.log', 'w')
	
	for i=0, 0xFFFF do
		out:write(string.format("%04X [%05d]", memory2.BUS:word(0x910000+i), i))
	end
	
	out:close()
end
function scan_loram()	
	for i=0, 0xFFFF do
		local address = 0x910000 + i
		local word = memory2.BUS:word(address)
		
		for _, desired_word in pairs(DESIRED_WORDS) do
			if (word == desired_word) or (word == (desired_word + 0x8000) & 0xFFFF) then
				print(string.format("%06X = %02X", address, word))
				return true
			end
		end
	end
	
	return false
end
function scan_loram_quick()
	for _, i in pairs(RANGE) do
		local address = 0x910000 + i
		local word = memory2.BUS:word(address)
		
		for _, desired_word in pairs(DESIRED_WORDS) do
			if (word == (desired_word + 0x8000) & 0xFFFF) then
				print(string.format("%06X = %02X", address, word))
			end
		end
	end
	
	return false
end
function scan_loram_quick_indirect()
	local address_1 = 0x3378
	for _, crash_1 in pairs(RANGE) do
		local address_2 = crash_1
		local crash_2 = memory2.BUS:word(0x910000 + address_2)
		
		local address_3 = (crash_2 + 0x8000) & 0xFFFF
		local crash_3 = memory2.BUS:word(0x910000 + address_3)
		
		local address_4 = crash_3
		--local crash_4 = memory2.BUS:word(0x910000 + address_4)
		
		for _, desired_word in pairs(DESIRED_WORDS) do
			local blacklisted = false
			
			for _, address in pairs(BLACK_LIST) do
				if address_1 == address or address_2 == address or address_3 == address then
					blacklisted = true
					break
				end
			end
		
			if (desired_word == crash_1) or (((desired_word + 0x8000) & 0xFFFF) == crash_2) or (desired_word == crash_3) then
				print(string.format("[%04X]=%04X -> [%04X]=%04X -8k-> [%04X]=%04X -> [%04X]=...%s",
					address_1, crash_1,
					address_2, crash_2,
					address_3, crash_3,
					address_4,
					blacklisted and " (blacklisted)" or ""
				))
				return
			end
		end
	end
	
	return false
end

function on_frame_emulated()
	--print("on_frame_emulated")
	
	local crash = memory2.BUS:word(0x7E0000 + 0x3378)
	local crash2 = memory2.BUS:word(0x910000 + crash)
	local crash22 = (crash2 + 0x8000) & 0xFFFF
	local crash3 = memory2.BUS:word(0x910000 + crash22)
	
	if (not (crash == 0x0000)) or FRAME > 200 then
		if false then
			print(string.format("%04X [->%04X] [%04X] [%02X%02X%02X%02X%02X%02X%02X%02X]",
				crash22,
				crash2,
				crash,
				memory2.WRAM:byte(RNG_BYTES[1]),
				memory2.WRAM:byte(RNG_BYTES[2]),
				memory2.WRAM:byte(RNG_BYTES[3]),
				memory2.WRAM:byte(RNG_BYTES[4]),
				memory2.WRAM:byte(RNG_BYTES[5]),
				memory2.WRAM:byte(RNG_BYTES[6]),
				memory2.WRAM:byte(RNG_BYTES[7]),
				memory2.WRAM:byte(RNG_BYTES[8])
				)
			)
		else
			scan_loram_quick_indirect()
		end
		
		--FRAME = 0
		--quickLoad()
	else		
		FRAME = FRAME + 1
		
		--dump_loram()
	end
end