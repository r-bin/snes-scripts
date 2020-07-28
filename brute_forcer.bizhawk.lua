-- internal
--BUTTONS = { "U", "D", "L", "R", "s", "S", "Y", "B", "X", "A", "l", "r", "0", "1", "2", "3" }
BUTTONS = { "P1 Up", "P1 Down", "P1 Left", "P1 Right", "P1 Select", "P1 Start", "P1 Y", "P1 B", "P1 X", "P1 A", "P1 L", "P1 R" }
STATE = {
	current_frame = 0,
	best_result = -1
}

-- config
SETTINGS = {
	allow_empty_input = false,
	allow_more_than_one_button = false,
}
--RNG_BUTTONS = { "U", "D", "L", "R", "B" }
RNG_BUTTONS = { "P1 Up", "P1 Down", "P1 Left", "P1 Right", "P1 B", "/wait" } --, "/end"
MEMORY_WATCHER = {
	{ address=0x2210, name="boy_firstLetter", desiredValue=15}
}

NUM_FRAMES = 1;
NUM_ITER = 1000;

function set_rng_buttons(button, random_button)
	if SETTINGS.allow_empty_input == true and random_button == "/wait" then
		return false
	else
		return button == random_button
	end
end
function progress_rng()
	random_button = RNG_BUTTONS[math.random(#RNG_BUTTONS)]
	print("random input=" .. random_button)
	
	if SETTINGS.allow_empty_input and random_button == "/wait" then
		return true
	end

	local buttons = joypad.get()
	for i = 1, #RNG_BUTTONS do
		local button = RNG_BUTTONS[i]
		buttons[button] = set_rng_buttons(button, random_button)
    end
	joypad.set(buttons)
	
	--print(joypad.get())
end

function check_cond()	
	for i = 1, #MEMORY_WATCHER do
		print("?")
		local watcher = MEMORY_WATCHER[i]
		local value = mainmemory.readbyte(watcher.address)
		
		print(watcher.name.."="..value)
		if value == watcher.desiredValue then
			return true
		end
    end
end

function advance_frames(count)
	for i=1,count,1 do
		print("+advance frame")
		emu.frameadvance();
		print("-advance frame")
	end
	
	STATE.current_frame = STATE.current_frame + count
end

-- Sets up the save states
savestate.saveslot(5);
savestate.loadslot(5);
--client.unpause()
tastudio.setrecording(true);

emu.limitframerate(false);
	
-- Initialize some variables
mycount = 0;

function renderOverlay()
	gui.drawText(5,5,string.format("COUNT:   %d",mycount));
	gui.drawText(5,20,string.format("FRAME:   %d",mycount));
	gui.drawText(5,35,string.format("BEST:    %d",mycount));
	for i = 1, #MEMORY_WATCHER do
		gui.drawText(5,35 + i*15,
			string.format("WATCHER: %d == %d",
				MEMORY_WATCHER[i].address,
				MEMORY_WATCHER[i].desiredValue
			));
    end
end

while true do
	--print("do sth.")
	renderOverlay()
	
	progress_rng()
	advance_frames(1)
	
	if check_cond() then
		STATE.best_result = STATE.current_frame
		savestate.loadslot(5)
		
		print("yay")
	else
		print("ney")
	end
end
	
emu.limitframerate(true);