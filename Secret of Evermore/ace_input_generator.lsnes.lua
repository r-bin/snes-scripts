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
				"0x913378: %04X\n" ..
				"0x91005A: %04X\n" ..
				"0x910100: %04X\n" ..
				
				"4218: %02X\n" ..
				"4219: %02X\n" ..
				"421A: %02X\n" ..
				"421B: %02X\n" ..
				"421C: %02X\n" ..
				"421D: %02X\n" ..
				"421E: %02X\n" ..
				"421F: %02X", 
				
				memory2.BUS:read(0x913378, 0x913379), 
				memory2.BUS:read(0x91005A, 0x91005B), 
				memory2.BUS:read(0x910100, 0x910101), 
				
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

local start = 35814 - 1 -- offset + 0x010000 + 0x4218 + 2 (frame points at controller2)
local inputs = {}

local stop = 0xDB
local nop = 0xEA
local wai = 0xCB
local ldx = 0xA2
local stx = 0x8E
local lda = 0xA9
local sta = 0x8D
local bra = 0x80

local function set_frame(i)
	table.insert(inputs, toBits({i, i, i, i, i, i, i, i}))
end

local function gen_id_frames(count)
	for i=1, count do
		set_frame(i)
	end
end

local function send_nop()
	table.insert(inputs, toBits({nop, nop, nop, nop, nop, wai, bra, 0xF8}))
end

local function send_lda(value)
	local v_1 = bit.lrshift(value, 8)
	local v_2 = bit.band(value, 0xFF)
	
	table.insert(inputs, toBits({lda, v_2, v_1, nop, nop, wai, bra, 0xF8}))
end

local function send_sta(dest)
	local d_1 = bit.lrshift(dest, 8)
	local d_2 = bit.band(dest, 0xFF)
	
	table.insert(inputs, toBits({sta, d_2, d_1, nop, nop, wai, bra, 0xF8}))
end

local function gen_input()
	send_nop()
	
	send_lda(0x0015)
	send_sta(0x4F53) --dog_y
	
	send_lda(0xFFFF)
	send_sta(0x22EB) --credit_active
	send_sta(0x22F1)
	
	send_lda(0x0000)
	send_sta(0x3364) --clear_crashing_alchemy ($3364-$337C)
	send_sta(0x3366)
	send_sta(0x3368)
	send_sta(0x336A)
	send_sta(0x336C)
	send_sta(0x336D)
	send_sta(0x336F)
	send_sta(0x3371)
	send_sta(0x3373)
	send_sta(0x3375)
	send_sta(0x3377)
	send_sta(0x3379)
	send_sta(0x337B)
	
	set_frame(0x60) --exit_crashing_alchemy
end

gen_input()

function on_input()
	local index = movie.currentframe()-start
	
	--print(movie.currentframe() .. " - " .. start .. " = " .. index)

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