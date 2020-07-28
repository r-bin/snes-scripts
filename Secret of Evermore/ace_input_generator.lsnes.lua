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
				"0x910101: %04X\n" ..
				"0x910104: %04X\n" ..
				"\n" ..
				"0x914216: %04X\n" ..
				"0x914218: %04X\n" ..
				"0x91421A: %04X\n" ..
				"0x91421C: %04X\n" ..
				"0x91421E: %04X\n" ..
				"0x914220: %04X",
				
				memory2.BUS:read(0x913378, 0x913379), 
				memory2.BUS:read(0x91005A, 0x91005B), 
				memory2.BUS:read(0x910101, 0x910102), 
				memory2.BUS:read(0x910104, 0x910105), 
				
				memory2.BUS:read(0x914216, 0x914217), 
				memory2.BUS:read(0x914218, 0x914219), 
				memory2.BUS:read(0x91421A, 0x91421B), 
				memory2.BUS:read(0x91421C, 0x91421D), 
				memory2.BUS:read(0x91421E, 0x91421F), 
				
				memory2.BUS:read(0x914220, 0x914221)
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

local start = 23459 - 1 -- offset + 0x010000 + 0x4218 + 2 (frame points at controller2)
local inputs = {}

local stap = 0xDB
local rts = 0x60
local nop = 0xEA
local wai = 0xCB
local ldx = 0xA2
local stx = 0x8E
local lda = 0xA9
local sta = 0x8D
local sta3 = 0x8F
local bra = 0x80

local function set_frame(i)
	table.insert(inputs, toBits({i, i, i, i, i, i, i, i}))
end

local function gen_id_frames(count)
	for i=1, count do
		set_frame(i)
	end
end

local function send_init()
	table.insert(inputs, toBits({0x1A, 0x42, nop, nop, nop, wai, bra, 0xF8}))
end
local function send_init2()
	table.insert(inputs, toBits({0x1A, 0x42, lda, 0xFF-10, bra, sta, 0x20, 0x42}))
end

local function send_init_looper()
	table.insert(inputs, toBits({0x1A, 0x42, lda, 0xFF-10, bra, sta, 0x20, 0x42}))
end

local function looper(dest)
	local d_1 = bit.lrshift(dest, 8)
	local d_2 = bit.band(dest, 0xFF)
	
	table.insert(inputs, toBits({lda, 0xFF-10, bra, sta3, d_2, d_1, 0x91, wai}))
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

local function send_sta_sta_rts(dest1, dest2)
	local d_1 = bit.lrshift(dest1, 8)
	local d_2 = bit.band(dest1, 0xFF)
	
	local d_3 = bit.lrshift(dest2, 8)
	local d_4 = bit.band(dest2, 0xFF)
	
	table.insert(inputs, toBits({sta, d_2, d_1, sta, d_4, d_3, wai, rts}))
end

local function send_sta91(dest)
	local d_1 = bit.lrshift(dest, 8)
	local d_2 = bit.band(dest, 0xFF)
	
	table.insert(inputs, toBits({sta3, d_2, d_1, 0x91, nop, wai, bra, 0xF8}))
end


local function send_init_lda(value)
	local v_1 = bit.lrshift(value, 8)
	local v_2 = bit.band(value, 0xFF)
	
	table.insert(inputs, toBits({0x1A, 0x42, lda, v_2, v_1, wai, bra, 0xF8}))
end


local function send_lda_sta(value, address)
	local v_1 = bit.lrshift(value, 8)
	local v_2 = bit.band(value, 0xFF)
	
	local v_3 = bit.lrshift(address, 8)
	local v_4 = bit.band(address, 0xFF)
	
	table.insert(inputs, toBits({lda, v_2, v_1, sta, v_3, v_4, nop, 0x60}))
end

local function send_sta_sta(address1, address2)
	local v_1 = bit.lrshift(address1, 8)
	local v_2 = bit.band(address1, 0xFF)
	
	local v_3 = bit.lrshift(address1, 8)
	local v_4 = bit.band(address1, 0xFF)
	
	table.insert(inputs, toBits({sta, v_2, v_1, sta, v_3, v_4, nop, 0x60}))
end

local function gen_input()
	send_init_lda(0x006F)
	send_sta(0x22EB) --credit_active
	send_sta(0x22F1)
	send_sta(0x4F51) --dog_x
	
	send_lda(0x000F)
	send_sta(0x4F53) --dog_y
	send_sta_sta_rts(0x3365, 0x3377) --clear_crashing_alchemy ($3364-$337C)
end

local function gen_input_test()
	send_init_lda(0xFFFF)
	send_sta_sta(0x22EB, 0x22F1) --credit_active
	
	send_lda_sta(0x0066, 0x4F51) --dog_x
	send_lda_sta(0x0015, 0x4F53) --dog_y
	
	send_lda_sta(0x0000, 0x3364) --clear_crashing_alchemy ($3364-$337C)
	send_sta_sta(0x3366, 0x3368)
	send_sta_sta(0x336A, 0x336C)
	send_sta_sta(0x336D, 0x336F)
	send_sta_sta(0x3371, 0x3373)
	send_sta_sta(0x3375, 0x3377)
	send_sta_sta(0x3379, 0x337B)
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