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

// Dependencies: 
// * Requires the XOP providing the oddRun() function
// * HFSAndPosix.xop (distributed with Igor, must be moved to Igor Extensions)


//****************************************************************
//
//	NCOddRun()
//	Call oddRun XOP function to setup 
//
//
//****************************************************************

Function NCOddRun(mode)
	Variable mode // (-1) kill (0) run (1) config (2) init
	
	String cdf = ClampDF()
	String sdf = CheckStimDF("")
	
	switch(mode)
	
		case 0:
			break
	
		case 1:
			NCOddRunConfig()
			return 0
	
		case 2:
			StimFxnListAdd(sdf, "Post", "NCOddPostRun")
			return 0
		case -1:
			StimFxnListRemove(sdf, "Post", "NCOddPostRun")
			return 0
		default:
			return 0
			
	endswitch
	
	String configfile = StrVarOrDefault(cdf+"ODDConfigFile", "")
	if(cmpstr(configfile,"")==0)
		NCOddRunConfig() // If we haven't got a config file set, then ask for one
		configfile = StrVarOrDefault(cdf+"ODDConfigFile", "") // and set the local variable
	endif
	
	String tempdir = SpecialDirPath("Temporary",0, 0, 0)
	String logfile = tempdir +"oddlog.txt"
	SetNMstr(cdf+"ODDLogFile", logfile)

//	NMHistory("ODD Log: " + logfile)

	// Find the POSIX path to the config and log files
	// This is needed because the XOP expects system paths but Igor
	// uses old style HFS paths internally.  It would be possible to change
	// the XOP to handle Igor style HFS paths.
	String posixLogFile = HFSToPosix("",tempdir,1,1)+"oddlog.txt"
	String posixConfigFile = HFSToPosix("",configfile,1,1)
	if (cmpstr(posixConfigFile,"") == 0)
		NMHistory("Missing config file: "+posixConfigFile)
		return 0
	elseif (cmpstr(posixLogFile,"oddlog.txt") == 0)
		NMHistory("Missing log file: "+posixLogFile)
		return 0
	endif
	
	#if Exists("oddRun")
		try
			oddRun(posixConfigFile,posixLogFile)
		catch
			print "Abort code= ", V_AbortCode
		endtry
	#else
		NMHistory("ODD ERROR: XOP missing!")
	#endif
    NotesFileStr("F_ODDConfig", configfile)
	
End // NCOddRun

//****************************************************************
//****************************************************************
//****************************************************************

Function NCOddRunConfig()
	String cdf = ClampDF()
	
	Variable refNum
	String configfile = StrVarOrDefault(cdf+"ODDConfigFile", "")
	Open /D /R /M="Please choose an ODD config file" refNum

	configfile = S_fileName

	SetNMstr(cdf+"ODDConfigFile",configfile)
	NMHistory("ODD Config: " + configfile)

End // NCOddRunConfig

//****************************************************************
//
//	NCOddPostRun()
//	A function that will be run at the end of a sweep using the ODD
//	Its main purpose will be to copy the ODD config/log files into 
//	the data save directory 
//
//****************************************************************

Function NCOddPostRun(mode)
	Variable mode // (-1) kill (0) run (1) config (2) init
	
	String cdf = ClampDF()
	
	switch(mode)
	
		case 0:
			break
	
		case 1:
		case 2:
		case -1:
		default:
			return 0
			
	endswitch
	
	String configfile = StrVarOrDefault(cdf+"ODDConfigFile", "")
	String logfile = StrVarOrDefault(cdf+"ODDLogFile","")
	String datadir = StrVarOrDefault(cdf+"ClampSubPath","")
	String datafile = datadir + StrVarOrDefault(ClampDF()+"CurrentFolder","")
	
	String savedlogfile = datafile + "_oddlog.txt"
	String savedconfigfile = datafile + "_odd.txt"
	
	if(NumVarOrDefault("CT_RecordMode", -1) > 0)
		// We are actually recording so save log files
		MoveFile /Z logfile as savedlogfile
		if(V_flag==0)
			NMHistory("ODD: Moving log file: " + logfile + " to: "+savedlogfile)
		else
			NMHistory("ODD ERROR:, unable to move log file: " + logfile + " to: "+savedlogfile)
		endif

		CopyFile /Z configfile as savedconfigfile
		if(V_flag==0)
			NMHistory("ODD: Saving odd config file: " + configfile + " to: "+savedconfigfile)
		else
			NMHistory("ODD ERROR:, unable to save config file: " + configfile + " to: "+savedconfigfile)
		endif
	else
		NMHistory("ODD: Preview mode, so skipping log file save")
	endif
End // NCOddPostRun
