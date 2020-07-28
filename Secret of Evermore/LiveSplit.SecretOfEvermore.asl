state("snes9x") {}
state("snes9x-x64") {}

startup
{
	print("startup");
	
    settings.Add("flowers", true, "Flowers");
    settings.SetToolTip("flowers", "Split on dog dragging the boy to the right, after entering the map with 0 HP");
    settings.Add("thraxx", true, "Thraxx");
    settings.SetToolTip("thraxx", "Split on leaving the room");
    settings.Add("magmar", true, "Magmar");
    settings.SetToolTip("magmar", "Split on victory hymn");
	
    settings.Add("enterNobilia", true, "Enter Nobilia");
    settings.SetToolTip("enterNobilia", "Split on resting pose of the boy, after entering Nobilia");
    settings.Add("marketTimer", true, "Market Timer");
    settings.SetToolTip("marketTimer", "Split on leaving the market, after the Market Timer has run out");
    settings.Add("vigor", true, "Vigor");
    settings.SetToolTip("vigor", "Split on on victory hymn");
    settings.Add("megataur", true, "Megataur");
    settings.SetToolTip("megataur", "Split on on victory hymn");
    settings.Add("rimsala", true, "Rimsala");
    settings.SetToolTip("rimsala", "Split on on victory hymn");
    settings.Add("aegis", true, "Aegis");
    settings.SetToolTip("aegis", "Split on on victory hymn");
    settings.Add("aquagoth", true, "Aquagoth");
    settings.SetToolTip("aquagoth", "Split on on victory hymn");
	
    settings.Add("footknight", true, "Footknight");
    settings.SetToolTip("footknight", "Split on on victory hymn");
    settings.Add("badBoy", true, "Bad Boy");
    settings.SetToolTip("badBoy", "Split on on victory hymn");
    settings.Add("timberdrake", true, "Timberdrake");
    settings.SetToolTip("timberdrake", "Split on on victory hymn");
    settings.Add("verminator", true, "Verminator");
    settings.SetToolTip("verminator", "Split on on victory hymn");
    settings.Add("sterling", true, "Sterling");
    settings.SetToolTip("sterling", "Split on on victory hymn");
    settings.Add("mungola", true, "Mungola");
    settings.SetToolTip("mungola", "Split on on victory hymn");
    settings.Add("windwalker", true, "Windwalker");
    settings.SetToolTip("windwalker", "Split on leaving the screen, at the beginning of the fading animation");
    settings.Add("rocket", true, "Rocket");
    settings.SetToolTip("rocket", "Split on leaving the screen, at the beginning of the fading animation");
	
    settings.Add("carltron", true, "Carltron");
    settings.SetToolTip("carltron", "Split on xp gain (The boy is still controllable, but no more inputs are needed to complete the game)");
}

init
{
	print("init");
	
    var states = new Dictionary<int, long>
    {
        { 9646080, 0x97EE04 },      // Snes9x-rr 1.60
        { 13565952, 0x140925118 },  // Snes9x-rr 1.60 (x64)
        { 9027584, 0x94DB54 },      // Snes9x 1.60
        { 12836864, 0x1408D8BE8 },  // Snes9x 1.60 (x64)
        { 16019456, 0x94D144 },     // higan v106
        { 15360000, 0x8AB144 },     // higan v106.112
        { 10096640, 0x72BECC },     // bsnes v107
        { 10338304, 0x762F2C },     // bsnes v107.1
        { 47230976, 0x765F2C },     // bsnes v107.2/107.3
        { 131543040, 0xA9BD5C },    // bsnes v110
        { 51924992, 0xA9DD5C },     // bsnes v111
        { 52056064, 0xAAED7C },     // bsnes v112
        { 7061504, 0x36F11500240 }, // BizHawk 2.3
        { 7249920, 0x36F11500240 }, // BizHawk 2.3.1
        { 6938624, 0x36F11500240 }, // BizHawk 2.3.2
    };

    long memoryOffset;
    if (states.TryGetValue(modules.First().ModuleMemorySize, out memoryOffset))
        if (memory.ProcessName.ToLower().Contains("snes9x"))
            memoryOffset = memory.ReadValue<int>((IntPtr)memoryOffset);

    if (memoryOffset == 0)
        throw new Exception("Memory not yet initialized.");

    vars.watchers = new MemoryWatcherList
    {
        new MemoryWatcher<short>((IntPtr)memoryOffset + 0x0ADB) { Name = "map" },
        new MemoryWatcher<short>((IntPtr)memoryOffset + 0x4EA3) { Name = "boy_x" },
        new MemoryWatcher<short>((IntPtr)memoryOffset + 0x0E4B) { Name = "music" },
		new MemoryWatcher<uint>((IntPtr)memoryOffset + 0x0A49) { Name = "boy_xp" },
    };
	
	vars.marketSplits = 0;
	vars.windwalkerSplits = 0;
}

update
{	
    vars.watchers.UpdateAll(game);
}

start
{
	var start = vars.watchers["map"].Old == 97 && vars.watchers["map"].Current == 49;
	
	if(start) {
		print("start="+start.ToString());
	
		vars.marketSplits = 0;
		vars.windwalkerSplits = 0;
	}
	
	
    return start;
}

reset
{
	var consoleReset = vars.watchers["map"].Old == 0 && vars.watchers["map"].Current == 0;
	var mainMenu = vars.watchers["map"].Old == 97 && vars.watchers["map"].Current == 97;
	
	var reset = consoleReset || mainMenu;
	
	if(reset) {
		print("reset"+reset.ToString());
		
		vars.marketSplits = 0;
		vars.windwalkerSplits = 0;
	}
	
    return reset;
}

split
{
	var flowers = settings["flowers"] && vars.watchers["map"].Current == 92 && vars.watchers["boy_x"].Current > vars.watchers["boy_x"].Old && vars.watchers["boy_x"].Current == 234;
	var thraxx = settings["thraxx"] && vars.watchers["map"].Current == 103 && vars.watchers["map"].Old == 24;
	var magmar = settings["magmar"] && vars.watchers["map"].Current == 63 && vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == 26;
	var enterNobilia = settings["enterNobilia"] && vars.marketSplits == 0 && vars.watchers["map"].Current == 10 && vars.watchers["boy_x"].Current > vars.watchers["boy_x"].Old && vars.watchers["boy_x"].Current == 88;
	if(enterNobilia) {
		vars.marketSplits++;
	}
	var marketTimer = settings["marketTimer"] && vars.watchers["map"].Current == 8 && vars.watchers["music"].Current == 38  && vars.watchers["boy_x"].Current > vars.watchers["boy_x"].Old && vars.watchers["boy_x"].Current == 56;
	var vigor = settings["vigor"] && vars.watchers["map"].Current == 29 && vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == 26;
	var megataur = settings["megataur"] && vars.watchers["map"].Current == 42 && vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == 26;
	var rimsala = settings["rimsala"] && vars.watchers["map"].Current == 88 && vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == 26;
	var aegis = settings["aegis"] && vars.watchers["map"].Current == 9 && vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == 26;
	var aquagoth = settings["aquagoth"] && vars.watchers["map"].Current == 109 && vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == 26;
	var footknight = settings["footknight"] && vars.watchers["map"].Current == 25 && vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == 26;
	var badBoy = settings["badBoy"] && vars.watchers["map"].Current == 31 && vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == 26;
	var timberdrake = settings["timberdrake"] && vars.watchers["map"].Current == 32 && vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == 26;
	var verminator = settings["verminator"] && vars.watchers["map"].Current == 94 && vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == 26;
	var sterling = settings["sterling"] && vars.watchers["map"].Current == 55 && vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == 26;
	var mungola = settings["mungola"] && vars.watchers["map"].Current == 119 && vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == 26;
	var windwalker = settings["windwalker"] && vars.windwalkerSplits == 0 && vars.watchers["map"].Current == 57 && vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == 3341;
	if(windwalker) {
		vars.windwalkerSplits++;
	}
	var rocket = settings["rocket"] && vars.watchers["map"].Current == 72 && vars.watchers["map"].Old == 57;
	var carltron = settings["carltron"] && vars.watchers["map"].Current == 74 && vars.watchers["boy_xp"].Current != vars.watchers["boy_xp"].Old && ((vars.watchers["boy_xp"].Current - vars.watchers["boy_xp"].Old) >= 100000);
	
	var split = flowers || thraxx || magmar // act 1
		|| enterNobilia || marketTimer || vigor || megataur || rimsala || aegis || aquagoth // act 2
		|| footknight || badBoy || timberdrake || verminator || sterling || mungola || windwalker || rocket // act 3
		|| carltron; // act 4

	if(split) {
		print("split="+split);
	}
    return split;
}
