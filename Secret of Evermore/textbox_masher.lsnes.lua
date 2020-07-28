local inputs = {}

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

local function set_frame(i)
	table.insert(inputs, toBits({i, i, i, i, i, i, i, i}))
end

local function gen_input()
	set_frame(0xAA)
	set_frame(0x55)
end

gen_input()

function on_input()
	local b = inputs[movie.currentframe() % 2 + 1]
	
	for c=0, 3 do
		for i=0, 15 do
			--print(b[c+1][i+1])
			input.set2(bit.lrshift(c, 1)+1, c%2, i, b[c+1][i+1])
			input.set2(bit.lrshift(c, 1)+1, c%2+2, i, b[c+1][i+1])
		end
	end
end