-- helpers
function clean_empty(array)
	local clean_array = {}
	for _,value in pairs(array) do
	  if not (value == "") then
		  clean_array[ #clean_array+1 ] = value
	  end
	end
	return clean_array
  end
  function split(s, delimiter)
	  result = {};
	  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		  table.insert(result, match);
	  end
	  return result;
  end
  
  -- internal
  function split_inputs(inputs_string)
	  local inputs = {}
	  
	  inputs = clean_empty(split(inputs_string, "\n"))
	  
	  return inputs
  end
  
  --BUTTONS = "F.|BYsSudlrAXLR0123|BYsSudlrAXLR0123|BYsSudlrAXLR0123|BYsSudlrAXLR0123"
  STATE = {
	  count = 1,
	  current_frame = 0,
	  best_result = -1,
	  base_save_slot = 5,
	  save_slot = 5,
	  settings = -1
  }
  RESULT = {}
  
  -- config
  RNG_BYTES = { 0x0133, 0x0134, 0x0135, 0x0136, 0x0137, 0x0138, 0x0139, 0x013A }
  
  SETTING_SETS = {
	  {
		  name = "Camera Setup",
		  allow_empty_input = false,
		  allow_more_than_one_button = true,
		  watchers = {
			  {
				  address = 0x005A,
				  data_type = "ushort",
				  name = "camera_xy",
				  win = function(value) return value == 0x8104 end,
				  reset = function(value) return value < 0x8104 end
			  }
		  },
		  rng_buttons = "..|....u.lr........|................|................|................",
		  inputs = nil
	  },
	  {
		  name = "Crash Game",
		  allow_empty_input = false,
		  allow_more_than_one_button = false,
		  rng_buttons = nil,
		  watchers = {
			  {
				  address = 0x005A,
				  data_type = "ushort",
				  name = "camera_xy",
				  win = nil,
				  reset = function(value) return not (value == 0x8104) end
			  }
		  },
		  rng_buttons = { "P1 L", "P1 R" },
		  inputs = split_inputs([[
  ..|.Y..............|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|................|................|................|................
  ..|B...............|................|................|................
  ..|................|................|................|................
  ..|B...............|................|................|................
  ]])
	  },
	  {
		  name = "Rain dance",
		  allow_empty_input = false,
		  allow_more_than_one_button = true,
		  watchers = {
			  {
				  address = 0x005A,
				  data_type = "ushort",
				  name = "camera_xy",
				  win = nil,
				  reset = function(value) return not (value == 0x8104) end
			  },
			  {
				  address = 0x3378,
				  data_type = "ushort",
				  name = "crash_rng",
				  win = function(value) return value == 0x005A end,
				  reset = function(value) return not (value == 0) end
			  }
		  },
		  rng_buttons = nil,
		  inputs = nil
	  }
  }
  function nextState()
	  STATE.win = false
	  STATE.reset = false
	  STATE.input_index = 1
  
	  if STATE.settings == -1 then
		  STATE.settings = 1
		  SETTINGS = SETTING_SETS[STATE.settings]
	  elseif STATE.settings + 1 <= #SETTING_SETS then
		  STATE.settings = STATE.settings + 1
		  SETTINGS = SETTING_SETS[STATE.settings]
	  else
		  finish()
	  end
	  
	  --print("state="..STATE.settings.."\n - "..SETTINGS.name.."\n - #wachers="..#SETTINGS.watchers)
  end
  nextState()
  
  function rng_string()
	  local rng_bytes = {}
  
	  for i = 1, #RNG_BYTES do
		  local value = memory2.WRAM:word(RNG_BYTES[i])
		  
		  rng_bytes[i] = string.format("%02X", value)
	  end
	  
	  return table.concat(rng_bytes, ",")
  end
  function updateBest()
	  RESULT = {
		  frames = STATE.current_frame,
		  RNG_BYTES = rng_string()
	  }
	  
	  print("Success!\n  - "..STATE.current_frame.." frames\n  - "..rng_string())
		  
	  if STATE.current_frame < STATE.best_result or STATE.best_result == -1 then
		  STATE.best_result = STATE.current_frame
		  
		  print("New record!")
		  --TODO: savestate.saveslot(6)
	  end
  end
  function rewind()
	  STATE.settings = -1
	  STATE.count = STATE.count + 1
	  STATE.current_frame = 0
	  
	  STATE.win = null
	  STATE.reset = null
	  
	  nextState()
	  
	  --TODO: savestate.loadslot(5)
	  quickLoad()
  end
  function finish()
	  updateBest()
	  
	  rewind()
  end
  
  
  -- #1
  function set_rng_buttons(button, random_button)
	  if random_button == "/wait" then
		  return false
	  elseif SETTINGS.allow_more_than_one_button then
		  return math.random(2) == 1
	  else
		  return button == random_button
	  end
  end
  function progress_rng()
	  random_button = SETTINGS.rng_buttons[math.random(#SETTINGS.rng_buttons)]
	  --print("random input=" .. random_button)
	  --TODO: set_rng_buttons(button, random_button
	  
	  for c=0, 3 do
		  offset = 4 + 17 * c
		  for i=0, 15 do
			  button = string.sub(SETTINGS.rng_buttons, offset+i, offset+i)
			  value = (button == "." and 0 or (math.random(2) == 1) and 1 or 0)
			  --print("button["..(offset+i).."]="..value)
			  input.set2(bit.lrshift(c, 1)+1, c%2, i, value)
		  end
	  end
	  
	  --print(joypad.get())
  end
  function progress_inputs()
	  if STATE.input_index > #SETTINGS.inputs then
		  STATE.win = true
		  return
	  end
  
	  local buttons = SETTINGS.inputs[STATE.input_index]
	  --print(STATE.input_index.."/"..#SETTINGS.inputs.." = "..buttons)
	  STATE.input_index = STATE.input_index + 1
	  
	  for c=0, 3 do
		  offset = 4 + 17 * c
		  for i=0, 15 do
			  button = string.sub(buttons, offset+i, offset+i)
			  value = (button == "." and 0 or 1)
			  --print("button["..(offset+i).."]="..value)
			  input.set2(bit.lrshift(c, 1)+1, c%2, i, value)
		  end
	  end
  end
  function on_input()
	  --print("on_input")
	  
	  if not (SETTINGS.inputs == nil) then
		  progress_inputs()
	  elseif not (SETTINGS.rng_buttons == nil) then
		  progress_rng()
	  else
		  for c=0, 3 do
			  for i=0, 15 do
				  input.set2(bit.lrshift(c, 1)+1, c%2, i, 0)
			  end
		  end
	  end
  end
  
  -- #2
  function check_cond()
	  for _, watcher in pairs(SETTINGS.watchers) do
		  local value = memory2.WRAM:word(watcher.address)
		  
		  --print(watcher.name .. "=" .. value)
		  if watcher.win ~= nil then
			  STATE.win = STATE.win or watcher.win(value)
			  if watcher.win(value) then
				  print(string.format("YAY: %s = %04X", watcher.name, value))
			  end
		  end
		  if watcher.reset ~= nil then
			  STATE.reset = STATE.reset or watcher.reset(value)
			  if watcher.reset(value) then
				  print(string.format("NEY: %s = %04X", watcher.name, value))
			  end
		  end
	  end
	  
	  
	  return STATE.win, STATE.reset
  end
  function on_frame_emulated()
	  --print("on_frame_emulated")
	  
	  local win, reset = check_cond()
	  --print("win="..tostring(win)..", reset="..tostring(reset))
	  if win then
		  --print("yay")
		  nextState()
	  elseif reset then
		  --print("ney")
		  rewind()
	  end
  end
  
  -- #3
  function on_paint(sync)
	  local opacity = 0x80
	  local fg_color = 0x00FFFFFF
	  local bg_color = 0x00000000
	  local x_padding = 0
	  local y_padding = 0
  
	  local function trans(color)
		  return color + (opacity * 0x1000000)
	  end
	  local function text(x, y, message)
		  gui.text(x+x_padding, y+y_padding, message, trans(fg_color), trans(bg_color))
	  end
  
	  --print("on_paint("..tostring(sync)..")")
	  
	  text(5,5,string.format("COUNT:   %d", STATE.count));
	  text(5,25,string.format("FRAME:   %d", STATE.current_frame));
	  text(5,45,string.format("BEST:    %d", STATE.best_result));
	  text(5,70,string.format("STATE:   [%d] %s", STATE.settings, SETTINGS.name));
	  for i = 1, #SETTINGS.watchers do
		  text(5, 75 + i*20,
			  string.format("WATCHER: %s = %04X",
				  SETTINGS.watchers[i].name,
				  memory2.WRAM:word(SETTINGS.watchers[i].address)
			  ));
	  end
	  
	  STATE.current_frame = STATE.current_frame + 1
  end
  
  -- misc
  unsafe = true
  unsafe_state = nil
  function quickSave()
	  --print("quickSave(" .. tostring(unsafe) .. ")")
	  
	  if unsafe then
		  movie.unsafe_rewind()
		  --print("unsafe_state=" .. tostring(unsafe_state))
	  else
		  --local file = "test.lsmv"
		  --print("set_rewind=" .. file)
		  --movie.set_rewind(file)
	  end
  end
  function quickLoad()
	  --print("quickLoad(" .. tostring(unsafe) .. ")")
		  
	  if unsafe then
		  if unsafe_state == nil then
			  print("failed to load")
			  return
		  end
		  --print("unsafe_state=" .. tostring(unsafe_state))
		  movie.unsafe_rewind(unsafe_state)
	  else
		  local file = "movieslot6.lsmv"
		  --print("to_rewind=" .. file)
		  movie.to_rewind(file)
	  end
  end
  function on_set_rewind(state)
	  --print("on_set_rewind(" .. tostring(state) .. ")")
	  
	  unsafe_state = state
	  --print("unsafe_state=" .. tostring(unsafe_state))
  end
  function on_pre_rewind()
	  --print("on_pre_rewind()")
  end
  function on_post_rewind()
	  --print("on_post_rewind()")
  end
  
  -- main
  quickSave()
  settings.set_speed("turbo")