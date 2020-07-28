// Secret of Evermore AutoSplitter, hosted at:
// #TODO#
// 
// Basic format of the script is based on:
// https://github.com/UNHchabo/AutoSplitters/blob/master/SuperMetroid
// https://github.com/Spiraster/ASLScripts/tree/master/LiveSplit.ALttP
// 
// Most of the RAM values taken from:
// https://datacrystal.romhacking.net/wiki/Secret_of_Evermore:RAM_map
//
// Installation guide:
// https://github.com/LiveSplit/LiveSplit/blob/master/Documentation/Auto-Splitters.md#testing-your-script
// https://github.com/LiveSplit/LiveSplit/blob/master/Documentation/Auto-Splitters.md#debugging

state("higan"){}
state("bsnes"){}
state("snes9x"){}
state("snes9x-x64"){}
state("emuhawk"){}
state("retroarch"){}

startup
{
	print("startup");
	
	vars.split = new Dictionary<string, ExpandoObject>();
	var currentAct = "";
	
	Action<int, string> AddAct = (act, name) => {
		print("+act (act="+act+", name="+name+")");
		currentAct = "act"+act;
		settings.Add("act"+act, true, "Act "+act+" - "+name);
	};
	Action<string, string, string, bool> AddOptionalSplit = (key, name, description, activated) => {
		print("+split (key="+key+", name="+name+", description="+description+", activated="+activated+")");
		
		settings.Add(key, activated, name, currentAct);
		settings.SetToolTip(key, description);
		
		vars.split[key] = new ExpandoObject();
		vars.split[key].achieved = false;
	};
	Action<string, string, string> AddSplit = (key, name, description) => {
		AddOptionalSplit(key, name, description, true);
	};
	
	AddAct(1, "Prehistoria");
	AddSplit ("flowers", "Flowers", "Split on dog dragging the boy to the right, after entering the map with 0 HP");
	AddSplit ("thraxx", "Thraxx", "Split on leaving the room");
	AddSplit ("magmar", "Magmar", "Split on victory hymn");
	
	AddAct(2, "Antiqua");
    AddSplit("enterNobilia", "Enter Nobilia", "Split on resting pose of the boy, after entering Nobilia for the first time");
    AddSplit("marketTimer", "Market Timer", "Split on resting pose of the boy, after leaving the market post Market Timer");
    AddSplit("vigor", "Vigor", "Split on victory hymn");
    AddSplit("megataur", "Megataur", "Split on victory hymn");
    AddSplit("rimsala", "Rimsala", "Split on victory hymn");
    AddSplit("aegis", "Aegis", "Split on victory hymn");
    AddSplit("aquagoth", "Aquagoth", "Split on victory hymn");
	
	AddAct(3, "Gothica");
    AddSplit("footknight", "FootKnight", "Split on victory hymn");
    AddSplit("badBoy", "Bad Boy", "Split on victory hymn");
    AddSplit("timberdrake", "Timberdrake", "Split on victory hymn");
    AddSplit("verminator", "Verminator", "Split on victory hymn");
    AddSplit("sterling", "Sterling", "Split on victory hymn");
    AddSplit("mungola", "Mungola", "Split on victory hymn");
    AddOptionalSplit("windwalker", "Windwalker", "Split on leaving the screen, at the beginning of the fading animation", false);
    AddSplit("rocket", "Rocket", "Split on leaving the screen, at the beginning of the fading animation");
	
	AddAct(4, "Omnitopia");
    AddSplit("carltron", "Carltron", "Split on xp gain (The boy can still be controlled)");
}

init
{
	print("init");
	
    IntPtr memoryOffset = IntPtr.Zero;

    if (memory.ProcessName.ToLower().Contains("snes9x")) {
        // TODO: These should probably be module-relative offsets too. Then
        // some of this codepath can be unified with the RA stuff below.
        var versions = new Dictionary<int, long>{
            { 10330112, 0x789414 },   // snes9x 1.52-rr
            { 7729152, 0x890EE4 },    // snes9x 1.54-rr
            { 5914624, 0x6EFBA4 },    // snes9x 1.53
            { 6909952, 0x140405EC8 }, // snes9x 1.53 (x64)
            { 6447104, 0x7410D4 },    // snes9x 1.54/1.54.1
            { 7946240, 0x1404DAF18 }, // snes9x 1.54/1.54.1 (x64)
            { 6602752, 0x762874 },    // snes9x 1.55
            { 8355840, 0x1405BFDB8 }, // snes9x 1.55 (x64)
            { 6856704, 0x78528C },    // snes9x 1.56/1.56.2
            { 9003008, 0x1405D8C68 }, // snes9x 1.56 (x64)
            { 6848512, 0x7811B4 },    // snes9x 1.56.1
            { 8945664, 0x1405C80A8 }, // snes9x 1.56.1 (x64)
            { 9015296, 0x1405D9298 }, // snes9x 1.56.2 (x64)
            { 6991872, 0x7A6EE4 },    // snes9x 1.57
            { 9048064, 0x1405ACC58 }, // snes9x 1.57 (x64)
            { 7000064, 0x7A7EE4 },    // snes9x 1.58
            { 9060352, 0x1405AE848 }, // snes9x 1.58 (x64)
            { 8953856, 0x975A54 },    // snes9x 1.59.2
            { 12537856, 0x1408D86F8 },// snes9x 1.59.2 (x64)
            { 9646080, 0x97EE04 },    // Snes9x-rr 1.60
            { 13565952, 0x140925118 },// Snes9x-rr 1.60 (x64)
            { 9027584, 0x94DB54 },    // snes9x 1.60
            { 12836864, 0x1408D8BE8 } // snes9x 1.60 (x64)
        };

        long pointerAddr;
        if (versions.TryGetValue(modules.First().ModuleMemorySize, out pointerAddr)) {
            memoryOffset = memory.ReadPointer((IntPtr)pointerAddr);
        }
    } else if (memory.ProcessName.ToLower().Contains("higan") || memory.ProcessName.ToLower().Contains("bsnes") || memory.ProcessName.ToLower().Contains("emuhawk")) {
        var versions = new Dictionary<int, long>{
            { 12509184, 0x915304 },      // higan v102
            { 13062144, 0x937324 },      // higan v103
            { 15859712, 0x952144 },      // higan v104
            { 16756736, 0x94F144 },      // higan v105tr1
            { 16019456, 0x94D144 },      // higan v106
            { 15360000, 0x8AB144 },      // higan v106.112
            { 10096640, 0x72BECC },      // bsnes v107
            { 10338304, 0x762F2C },      // bsnes v107.1
            { 47230976, 0x765F2C },      // bsnes v107.2/107.3
            { 142282752, 0xA65464 },     // bsnes v108
            { 131354624, 0xA6ED5C },     // bsnes v109
            { 131543040, 0xA9BD5C },     // bsnes v110
            { 51924992, 0xA9DD5C },      // bsnes v111
            { 52056064, 0xAAED7C },      // bsnes v112
            { 7061504,  0x36F11500240 }, // BizHawk 2.3
            { 7249920,  0x36F11500240 }, // BizHawk 2.3.1
            { 6938624,  0x36F11500240 }, // BizHawk 2.3.2
        };

        long wramAddr;
        if (versions.TryGetValue(modules.First().ModuleMemorySize, out wramAddr)) {
            memoryOffset = (IntPtr)wramAddr;
        }
    } else if (memory.ProcessName.ToLower().Contains("retroarch")) {
        // RetroArch stores a pointer to the emulated WRAM inside itself (it
        // can get this pointer via the Core API). This happily lets this work
        // on any variant of Snes9x cores, depending only on the RA version.

        var retroarchVersions = new Dictionary<int, int>{
            { 18649088, 0x608EF0 }, // Retroarch 1.7.5 (x64)
        };
        IntPtr wramPointer = IntPtr.Zero;
        int ptrOffset;
        if (retroarchVersions.TryGetValue(modules.First().ModuleMemorySize, out ptrOffset)) {
            wramPointer = memory.ReadPointer(modules.First().BaseAddress + ptrOffset);
        }

        if (wramPointer != IntPtr.Zero) {
            memoryOffset = wramPointer;
        } else {
            // Unfortunately, Higan doesn't support that API. So if the address
            // is missing, try to grab the memory from the higan core directly.

            var higanModule = modules.FirstOrDefault(m => m.ModuleName.ToLower() == "higan_sfc_libretro.dll");
            if (higanModule != null) {
                var versions = new Dictionary<int, int>{
                    { 4980736, 0x1F3AC4 }, // higan 106 (x64)
                };
                int wramOffset;
                if (versions.TryGetValue(higanModule.ModuleMemorySize, out wramOffset)) {
                    memoryOffset = higanModule.BaseAddress + wramOffset;
                }
            }
        }
    }

    if (memoryOffset == IntPtr.Zero) {
        vars.DebugOutput("Unsupported emulator version");
        var interestingModules = modules.Where(m =>
            m.ModuleName.ToLower().EndsWith(".exe") ||
            m.ModuleName.ToLower().EndsWith("_libretro.dll"));
        foreach (var module in interestingModules) {
            vars.DebugOutput("Module '" + module.ModuleName + "' sized " + module.ModuleMemorySize.ToString());
        }
        vars.watchers = new MemoryWatcherList{};
        // Throwing prevents initialization from completing. LiveSplit will
        // retry it until it eventually works. (Which lets you load a core in
        // RA for example.)
        throw new InvalidOperationException("Unsupported emulator version");
    }
	
	print("emulator="+memory.ProcessName);
	print("memoryOffset="+memoryOffset);

    vars.watchers = new MemoryWatcherList
    {
        new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x4EA3) { Name = "boy_x" },
        new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x4EA5) { Name = "boy_y" },
		new MemoryWatcher<uint>((IntPtr)memoryOffset + 0x0A49) { Name = "boy_xp" },
		new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x4EB3) { Name = "boy_hp" },
		
        new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x0ADB) { Name = "map" },
        new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x0E4B) { Name = "music" },
    };
	
	vars.currentSplit = "flowers";
}

update
{	
    vars.watchers.UpdateAll(game);
}

start
{	
	var start = vars.watchers["map"].Old == 97 && vars.watchers["map"].Current == 49;
	
	if(start) {
		print("+run");
	
		foreach(var split in vars.split)
		{
			vars.split[split.Key].achieved = false;
		}
	}
	
	
    return start;
}

reset
{
	var consoleReset = vars.watchers["map"].Old == 0 && vars.watchers["map"].Current == 0;
	var mainMenu = vars.watchers["map"].Old == 97 && vars.watchers["map"].Current == 97;
	
	var reset = consoleReset || mainMenu;
	
	if(reset) {
		print("-run");
	}
	
    return reset;
}

split
{
	print("split");

	var split = false;
	
	Action<string, bool> checkSplit = (key, condition) => {
		if (settings[key] && vars.split[key].achieved == false && condition) {
			vars.split[key].achieved = true;
			print("~split="+key);
			
			split = true;
		}
	};
	Action<string, int, int> checkSplitForSound = (key, map, sound) => {
		checkSplit(key, vars.watchers["map"].Current == map && vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == sound);
	};
	Action<string, int> checkSplitForHymn = (key, map) => {
		checkSplitForSound(key, map, 26);
	};
	Action<string, int, int> checkSplitForMapChange = (key, map, previousMap) => {
		checkSplit(key, vars.watchers["map"].Current == map && vars.watchers["map"].Old == previousMap);
	};
	Action<string, int, int> checkSplitForXPosition = (key, map, x) => {
		checkSplit(key, vars.watchers["map"].Current == map && vars.watchers["boy_x"].Current > vars.watchers["boy_x"].Old && vars.watchers["boy_x"].Current == x);
	};
		
	// Act 1
	checkSplitForXPosition("flowers", 92, 234);
	checkSplitForMapChange("thraxx", 103, 24);
	checkSplitForHymn("magmar", 63);
	
	// Act 2
	checkSplitForXPosition("enterNobilia", 10, 88);
	checkSplit("marketTimer", vars.watchers["map"].Current == 8 && vars.watchers["music"].Current == 38  && vars.watchers["boy_x"].Current > vars.watchers["boy_x"].Old && vars.watchers["boy_x"].Current == 56);
	checkSplitForHymn("vigor", 29);
	checkSplitForHymn("megataur", 42);
	checkSplitForHymn("rimsala", 88);
	checkSplitForHymn("aegis", 9);
	checkSplitForHymn("aquagoth", 109);
	
	// Act 3
	checkSplitForHymn("footknight", 25);
	checkSplitForHymn("badBoy", 31);
	checkSplitForHymn("timberdrake", 32);
	checkSplitForHymn("verminator", 94);
	checkSplitForHymn("sterling", 55);
	checkSplitForHymn("mungola", 119);
	checkSplitForSound("windwalker", 57, 3341);
	checkSplitForMapChange("rocket", 72, 57);
	
	// Act 4
	checkSplit("carltron", vars.watchers["map"].Current == 74 && vars.watchers["boy_xp"].Current > vars.watchers["boy_xp"].Old && ((vars.watchers["boy_xp"].Current - vars.watchers["boy_xp"].Old) >= 100000));
	
    return split;
}
