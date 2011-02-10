#pragma rtGlobals = 1

// This file will contain support code to integrate control of the Odour Delivery Devices
// completed in early 2011 with Neuromatic/NClamp

// Alex Hodge has written an Igor XOP which can be used to control which odour
// valves open. It waits for a trigger from Igor to start each stimulus
// sequence The stimulus details are defined in a simple text file.
// Usage is basically:
    // oddRun(<configfile>,<logfile>)

// The main goal of this support code is to provide a wrapper so that NClamp
// can used to configure and call oddRun

//****************************************************************
//
//	NCOddRun()
//	Call oddRun XOP function to setup 
//
//
//****************************************************************

Function NCOddRun(mode)
	Variable mode // (-1) kill (0) run (1) config (2) init
	
	Variable telValue
	String cdf = ClampDF()
	
	switch(mode)
	
		case 0:
			break
	
		case 1:
			NCOddRunConfig()
			break
	
		case 2:
		case -1:
		default:
			return 0
			
	endswitch
	
	String configfile = StrVarOrDefault(cdf+"ConfigFile", "")
	String logfile = StrVarOrDefault(cdf+"LogFile", "")
			
	NMHistory("ODD Config: " + configfile)
	NMHistory("ODD Log: " + logfile)
	
    // NotesFileVar("F_Temp", telValue)
	
End // NCOddRun

//****************************************************************
//****************************************************************
//****************************************************************

Function NCOddRunConfig()
	String cdf = ClampDF()
	
	String configfile = StrVarOrDefault(cdf+"ConfigFile", "")
	String logfile = StrVarOrDefault(cdf+"LogFile", "")
	
	Prompt configfile, "enter name of ODD config file"
	Prompt logfile, "enter name of ODD log file"
	DoPrompt "Configure oddRun", configfile, logfile
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	SetNMstr(cdf+"ConfigFile",configfile)
	SetNMstr(cdf+"LogFile", logfile)

End // NCOddRunConfig
