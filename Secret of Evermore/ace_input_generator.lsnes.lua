--debug display control
local show_debug = true
local show_dma_debug = true
local active_screen = sprite_screen
local opacity = 0x80
local fg_color = 0x00FFFFFF
local bg_color = 0x00000000
local x_padding = -400
local y_padding = 0

--Add transparency to a color with default opacity
local function trans(color)
    return color + (opacity * 0x1000000)
end

local function text(x, y, message)
	gui.text(x+x_padding, y+y_padding, message, trans(fg_color), trans(bg_color))
end

function on_paint(sync)
	ports = string.format(
				"4016: %02X\n" ..
				"4017: %02X\n" ..
				
				"4213: %02X\n" ..
				
				"4218: %02X\n" ..
				"4219: %02X\n" ..
				"421A: %02X\n" ..
				"421B: %02X\n" ..
				"421C: %02X\n" ..
				"421D: %02X\n" ..
				"421E: %02X\n" ..
				"421F: %02X", 
				
				memory2.BUS:read(0x4016), 
				memory2.BUS:read(0x4017), 
				
				memory2.BUS:read(0x4213), 
				
				memory2.BUS:read(0x4218), 
				memory2.BUS:read(0x4219), 
				memory2.BUS:read(0x421A), 
				memory2.BUS:read(0x421B), 
				memory2.BUS:read(0x421C), 
				memory2.BUS:read(0x421D), 
				memory2.BUS:read(0x421E), 
				memory2.BUS:read(0x421F)
			)
			
	text(0, 0, ports)
end

local function toBits(input_array)
	local controllers = {}
	for i=0, 3 do
		local buttons = {}
		local input = input_array[i*2+1]+input_array[i*2+2]*256
		for k=0, 15 do
			buttons[16-k]=input%2
			input = bit.lrshift(input, 1)
		end
		table.insert(controllers, buttons)
	end
	
	controllers[2], controllers[3] = controllers[3], controllers[2]
	
	return controllers
end

--local start = 6418
local start = 8321
local inputs = {}

local stop = 0xDB
local nop = 0xEA
local wai = 0xCB

local function set_frame(i)
	table.insert(inputs, toBits({i, i, i, i, i, i, i, i}))
end

local function gen_id_frames(count)
	for i=1, count do
		set_frame(i)
	end
end

local function ldx_stx(value, dest)
	local d_1 = bit.lrshift(dest, 8)
	local d_2 = bit.band(dest, 0xFF)
	
	local v_1 = bit.lrshift(value, 8)
	local v_2 = bit.band(value, 0xFF)
	
	table.insert(inputs, toBits({0xA2, v_2, v_1, 0x8D, 0x0B, 0x42, 0x80, 0xF8}))  -- executed frame
	set_frame(nop)
	set_frame(nop)
	table.insert(inputs, toBits({0x8E, d_2, d_1, 0x8D, 0x0B, 0x42, 0x80, 0xF8}))  -- executed frame
	set_frame(nop)
	set_frame(nop)
end

local function lda_sta(value, dest)
	local d_2 = bit.band(dest, 0xFF)
	
	local v_1 = bit.lrshift(value, 8)
	local v_2 = bit.band(value, 0xFF)
	
	table.insert(inputs, toBits({0xA9, v_2, v_1, 0x85, d_2, 0xCB, 0x80, 0xF8}))
end

local function gen_input()
	
--First executed code (stage 1)
	table.insert(inputs, toBits({0x8D, 0x00, 0x42, 0x8D, 0x0B, 0x42, 0x80, 0xF8}))
  
  
--stage 3
	--code = {0x10A2, 0xA000, 0x0006, 0x18B9, 0x9542, 0xE80E, 0x88E8, 0x1088, 0xCBF5, 0x00E0, 0x9001, 0xEAEC}
	code = {0x30E2, 0x00A9, 0x008D, 0xAD42, 0x4212, 0xFB10, 0x98C8, 0x0F29, 0x008D, 0x9C21, 0x2121, 0x228D, 0x8D21, 0x2122, 0x12AD, 0x3042, 0x80FB, 0xEAE4}
	for i=1, #code do
		lda_sta(code[i], 0x40 + i*2 - 2)
	end
	
	table.insert(inputs, toBits({0x4C, 0x40, 0x00, 0xEA, 0xEA, 0xCB, 0x80, 0xF8}))
	set_frame(stop)

end

gen_input()

function on_input()
	local index = movie.currentframe()-start

	if index>=0 and index<#inputs then
		local b = inputs[index+1]
		for c=0, 3 do
			for i=0, 15 do
				--print(b[c+1][i+1])
				input.set2(bit.lrshift(c, 1)+1, c%2, i, b[c+1][i+1])
				input.set2(bit.lrshift(c, 1)+1, c%2+2, i, b[c+1][i+1])
			end
		end
	end
end


  --9D 0E 42 E8 E8 D0 F9
  --table.insert(inputs, toBits({0xEA, 0xEA, 0xEA, 0x64, 0x10, 0xCB, 0x80, 0xF8}))

  --local code = "0D 18 0E 1C FC 1D 11 12 1C FC 20 18 1B 14"
  --local addr = 0x0EF9

  --code=code:gsub(" ", "")
  --while #code%4~=0 do code=code.."00" end
  --for i=1, #code, 4 do
  --  local cur = tonumber(code:sub(i, i+3), 16)
  --  table.insert(inputs, toBits({0xA9, bits.rshift(cur, 8), cur%256, 0x64, 0x10, 0xCB, 0x80, 0xF8}))
  --  table.insert(inputs, toBits({0x8D, (addr+((i-1)//2))%256, (addr+((i-1)//2))//256, 0x64, 0x10, 0xCB, 0x80, 0xF8}))
  --end

  --table.insert(inputs, toBits({0x4C, addr%256, addr//256, 0x00, 0x00, 0x00, 0x80, 0xF8}))
