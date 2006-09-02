#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp Acquisition Functions
//	To be run with NeuroMatic, v1.91
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Created in the Laboratory of Dr. Angus Silver
//	Department of Physiology, University College London
//
//	This work was supported by the Medical Research Council
//	"Grid Enabled Modeling Tools and Databases for NeuroInformatics"
//
//	Began 1 July 2003
//	Last modified 08 June 2006
//
//	NM tab entry "Clamp"
//
//	Requires:
//	NM_ClampTab.ipf			creates Tab control interface
//	NM_ClampLog.ipf			Notes/Log functions
//	NM_ClampStim.ipf		stim protocol folder manager
//	NM_ClampUtility.ipf		misc functions
//	NM_PulseGen.ipf			creates stim pulses
//
//	Also:
//	NM_ClampNIDAQ.ipf		acquires data using NIDAQ boards
//	NIM_ClampITC.ipf			acquires data using ITC boards
//
//	Note: this software is best run with ProgWin XOP.
//	Download from ftp site www.wavemetrics.com/Support/ftpinfo.html
//	(IgorPro/User_Contributions/)
//
//****************************************************************
//****************************************************************
//****************************************************************

Menu "NeuroMatic", dynamic

	Submenu "Clamp Hot Keys"
		"Preview/4", ClampButton("CT_StartPreview")
		"Record/5", ClampButton("CT_StartRecord")
		"Add Note/6", NotesAddNote("")
		"Auto Scale/7", ClampAutoScale()
	End

End

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampPrefix(objName) // tab prefix identifier
	String objName

	return "CT_" + objName
	
End // ClampPrefix


//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampDF() // package full-path folder name

	return PackDF("Clamp")
	
End // ClampDF

//****************************************************************
//****************************************************************
//****************************************************************

Function Clamp(enable)
	Variable enable // (0) disable (1) enable
	
	Variable statsOn
	
	Variable CurrentChan = NumVarOrDefault("CurrentChan", 0)
	Variable CurrentWave = NumVarOrDefault("CurrentWave", 0)

	if (enable == 1)
	
		CheckPackage("Stats", 0) // necessary for auto-stats
		CheckPackage("Clamp", 0) // create clamp global variables
		CheckPackage("Notes", 0) // create Notes folder
		
		ClampSetPrefs() // set data paths, open stim files, test board config
		
		statsOn = StimStatsOn()
		
		if (statsOn == 1)
			StatsComputeAmps(CurrentChanDisplayWave(), CurrentChan, CurrentWave, -1, 0, 1)
		endif
		
	endif
	
	StatsDisplay(statsOn)
	
	ClampTabEnable(enable) // (NM_ClampTab.ipf)
	
	SetNMVar(StimDF()+"CurrentChan", NumVarOrDefault("CurrentChan", 0)) // update current channel

End // Clamp

//****************************************************************
//****************************************************************
//****************************************************************

Function KillClamp(what)
	String what // to kill
	String cdf = ClampDF()

	strswitch(what)
		case "waves":
			break
		case "globals":
			if (DataFolderExists(cdf) == 1)
				KillDataFolder $cdf
			endif 
			break
	endswitch

End // KillClamp

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckClamp()
	
	Variable saveformat = 1 // NM binary
	Variable first = NMCountFrom()
	
	String cdf = ClampDF()

	if (DataFolderExists(cdf) == 0)
		return -1
	endif
	
	if (FileBinType() == 1)
		saveformat = 2 // Igor binary
	endif
	
	CheckNMstr(cdf+"ClampErrorStr", "No Error")		// error message
	CheckNMvar(cdf+"ClampError", 0)					// error number (0) no error (-1) error
	
	// Config variables
	
	CheckNMstr(cdf+"AcqBoard", "Demo")				// interface board
	CheckNMstr(cdf+"BoardList", "0, Demo;")			// acquisition board list
	CheckNMvar(cdf+"BoardDriver", 0)					// main board driver number
	
	CheckNMvar(cdf+"AcqBackGrnd", 0)				// background acq flag (0) no (1) yes
	
	CheckNMvar(cdf+"LogDisplay", 1)					// auto save log notes flag
	CheckNMvar(cdf+"LogAutoSave", 1)					// auto save log notes flag
	
	CheckNMstr(cdf+"TGainList", "")					// telegraph gain ADC channel list
	CheckNMstr(cdf+"ClampInstrument", "")				// clamp instrument name
	
	// data folder variables
	
	CheckNMstr(cdf+"CurrentFolder", "")				// current data file
	CheckNMstr(cdf+"FolderPrefix", ClampDateName())	// data file prefix name
	CheckNMstr(cdf+"StimTag", "")						// stim tag name
	CheckNMstr(cdf+"ClampPath", "")					// external save data path
	CheckNMstr(cdf+"DataPrefix", "Record"	)			// default data prefix name
	
	CheckNMvar(cdf+"DataFileCell", first)				// data file cell number
	CheckNMvar(cdf+"DataFileSeq", first)				// data file sequence number
	CheckNMvar(cdf+"SeqAutoZero", 1)					// auto zero seq number after cell increment
	
	CheckNMvar(cdf+"SaveWhen", 1)					// (0) never (1) after recording (2) while recording
	CheckNMvar(cdf+"SaveFormat", saveformat)			// (1) NM binary file (2) Igor binary file (3) both
	CheckNMvar(cdf+"SaveWithDialogue", 0)			// (0) no dialogue (1) save with dialogue
	CheckNMvar(cdf+"SaveInSubfolder", 1)				// save data in subfolders (0) no (1) yes
	CheckNMvar(cdf+"AutoCloseFolder", 1)				// auto delete data folder flag (0) no (1) yes
	CheckNMvar(cdf+"CopyStim2Folder", 1)				// copy stim to data folder flag (0) no (1) yes
	
	// stim protocol variables
	
	CheckNMstr(cdf+"StimPath", "")					// external save stim path
	CheckNMstr(cdf+"OpenStimList", "")				// external stim files to open
	CheckNMstr(cdf+"CurrentStim", "") 					// current stimulus protocol
	
	//CheckNMvar(cdf+"AcqStimList", 0)				// acquire stim list flag
	
	// Igor clock error variables 
	
	CheckNMvar(cdf+"InterStimError", 0)				// inter-stim clock error
	CheckNMvar(cdf+"InterStimCnt", 0)					// 	count
	CheckNMvar(cdf+"InterStimCF", 0)					// 	correction flag
	CheckNMvar(cdf+"InterRepError", 0)					// inter-rep clock error
	CheckNMvar(cdf+"InterRepCnt", 0)					//	count
	CheckNMvar(cdf+"InterRepCF", 0)					// 	correction flag
	
	return 0
	
End // CheckClamp

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSetPrefs()

	Variable test
	String cdf = ClampDF()
	
	if (NumVarOrDefault(cdf+"ClampSetPreferences", 0) == 1)
		return 0 // already set
	endif

	String ClampPathStr = StrVarOrDefault(cdf+"ClampPath", "")
	String StimPathStr = StrVarOrDefault(cdf+"StimPath", "")
	String sList = StrVarOrDefault(cdf+"OpenStimList", "")
	
	if (strlen(ClampPathStr) > 0)
		NewPath /Z/O ClampPath ClampPathStr
		if (V_flag != 0)
			DoAlert 0, "Failed to create external path to: " + ClampPathStr
			SetNMstr(cdf+"ClampPath", "")
		endif
	endif
	
	if (strlen(StimPathStr) > 0)
		NewPath /Z/O StimPath StimPathStr
		if (V_flag != 0)
			DoAlert 0, "Failed to create external path to: " + StimPathStr
			SetNMstr(cdf+"StimPath", "")
		endif
	endif
	
	if ((strlen(StimPathStr) > 0) && (strlen(sList) > 0))
		StimOpenList(sList)
	endif
	
	test = ClampAcquireManager(StrVarOrDefault(cdf+"AcqBoard","Demo"), -2, 0) // test configuration
	
	if (test < 0)
		SetNMstr(cdf+"AcqBoard","Demo")
	endif
	
	ClampProgress() // make sure progress display is OK
	
	SetNMvar(cdf+"ClampSetPreferences", 1)
	
	SetIgorHook IgorQuitHook = ClampExitHook // runs this fxn before quitting Igor

End // ClampSetPrefs

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampDateName()
	String name = "", d = Date()
	
	Variable icnt
	
	for (icnt = 0; icnt < strlen(d); icnt += 1)
		if ((StringMatch(d[icnt,icnt], " ") == 0) && (StringMatch(d[icnt,icnt], ".") == 0) && (StringMatch(d[icnt,icnt], ",") == 0))
			name += d[icnt,icnt]
		endif
	endfor
	
	icnt = strsearch(name, "200", 0) // look for year 200x
	
	if (icnt >= 0)
		name = name[0,icnt-1] + name[icnt+2,inf] // abbreviate
	endif

	if (numtype(str2num(name[0,0])) == 0)
		name = "f" + name
	endif
	
	return name

End // ClampDateName

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampError(errorStr)
	String errorStr
	String cdf = ClampDF()
	
	if (strlen(errorStr) == 0)
		SetNMstr(cdf+"ClampErrorStr", "No Error")
		SetNMvar(cdf+"ClampError", 0)
	else
		SetNMstr(cdf+"ClampErrorStr", errorStr)
		SetNMvar(cdf+"ClampError", -1)
		DoAlert 0, "Clamp Error: " + errorStr
		ClampButtonDisable(-1)
	endif
	
End // ClampError

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampProgress() // use ProgWin XOP display to allow cancel of acquisition
	String ndf = NMDF()

	Variable pflag = NumVarOrDefault(ndf+"ProgFlag", 0)
	Variable xPixels = NumVarOrDefault(ndf+"xPixels", 1000)
	Variable yPixels = NumVarOrDefault(ndf+"yPixels", 700)
	
	Variable xProgress = NumVarOrDefault(ndf+"xProgress", -1)
	Variable yProgress = NumVarOrDefault(ndf+"yProgress", -1)
	
	String txt = "Alert: Clamp Tab requires ProgWin XOP to cancel acquisition."
	txt += "Download from ftp site www.wavemetrics.com/Support/ftpinfo.html (IgorPro/User_Contributions/)."
	
	if (pflag != 1)
	
		Execute /Z "ProgressWindow kill" // try to use ProgWin function
	
		if (V_flag == 0)
			SetNMVar(ndf+"ProgFlag", 1)
		else
			DoAlert 0, txt
		endif
	
	endif
	
	if ((pflag == 1) && ((xProgress < 0) || (yProgress < 0)))
		SetNMVar(ndf+"xProgress", xPixels - 500)
		SetNMVar(ndf+"yProgress", yPixels/2)
	endif

End // ClampProgress

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardNum(boardListStr)
	String boardListStr // such as "1,PCI-6052E"
	
	return str2num(StringFromList(0, boardListStr, ","))
	
End // ClampBoardNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampBoardName(boardListStr)
	String boardListStr // such as "1,PCI-6052E"
	
	return StringFromList(1, boardListStr, ",")
	
End // ClampBoardName

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardListNum(boardNum) // return list number of given board
	Variable boardNum
	
	String cdf = ClampDF()
	
	String boardList = StrVarOrDefault(cdf+"BoardList", "")
	
	Variable icnt
	String item
	
	for (icnt = 0; icnt < ItemsInList(boardList); icnt += 1)
		item = StringFromList(icnt, boardList, ";")
		item = StringFromList(0, item, ",")
		if (str2num(item) == boardNum)
			return icnt
		endif
	endfor
	
	return -1

End // ClampBoardListNum

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Clamp aquisition/manager functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireCall(mode)
	Variable mode // (0) preview (1) record
	
	String cdf = ClampDF()
	
	String aboard = StrVarOrDefault(cdf+"AcqBoard", "")
	
	if (StimChainOn() == 1)
		ClampAcquireChain(aboard, mode)
	else
		ClampAcquire(aboard, mode)
	endif

End // ClampAcquireCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquire(AcqBoard, mode)
	String AcqBoard
	Variable mode // (0) preview (1) record
	
	Variable error
	String cdf = ClampDF(), sdf = StimDF(), ldf = LogDF()
	
	Variable saveWhen = NumVarOrDefault(cdf+"SaveWhen", 0)
	Variable AcqMode = NumVarOrDefault(sdf+"AcqMode", 0)
	String path = StrVarOrDefault(cdf+ "ClampPath", "")
	
	ClampError("")
	
	if (strlen(path) == 0)
		ClampError("Please specify \"save to\" path on CF tab.")
		return -1
	endif
	
	if (StimStatsOn() == 1)
		ClampStatsSaveAsk(sdf)
		ClampStatsRetrieve(sdf) // get Stats from new stim
		StatsDisplayClear()
	else
		ClampStatsRemoveWaves(1)
	endif
	
	if (WinType(NotesTableName()) == 2)
		NotesTable(1) // update notes if table is open
	endif
	
	ClampSaveSubPath()
	
	CheckLog(ldf) // check Log folder is OK
	
	if (ClampConfigCheck() == -1)
		return -1
	endif
	
	if ((AcqMode == 1) && (saveWhen == 2) && (mode == 1))
		ClampError("Save While Recording is not allowed with continuous acquisition.")
		return -1
	endif
	
	StimWavesUpdate(0)
	
	if (ClampDataFolderCheck() == -1)
		return -1
	endif
	
	if ((mode == 1) && (ClampSaveTest(GetDataFolder(0)) == -1))
		return -1
	endif
	
	ClampTgainUpdate()
	
	// no longer test timers
	
	//if (NumVarOrDefault(cdf+"TestTimers", 1) == 1)
	//if (ClampAcquireManager(AcqBoard, -1, 0)  == -1) // test timers
	//	return -1 
	//endif
	//endif
	
	SetNMvar("NumWaves", 0)
	SetNMvar("NumActiveWaves", 0)
	SetNMvar("CurrentWave", 0)
	SetNMvar("CurrentGrp", NMGroupFirstDefault())

	if ((mode == 1) && (ClampSaveBegin() == -1))
		SetNMvar("NumWaves", 0)
		return -1
	endif
	
	DoUpdate
	
	error = ClampAcquireManager(acqboard, mode, saveWhen)
	
	if ((error == -1) || (NumVarOrDefault(cdf+"ClampError", -1) == -1))
		SetNMvar("NumWaves", 0)
		return -1
	endif
	
	DoWindow /F NMPanel
	
	return 0
	
End // ClampAcquire

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireDemo(mode, savewhen, WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime)
	Variable mode // (0) preview (1) record (-1) test timers
	Variable savewhen // (0) never (1) after (2) while
	Variable WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime // msec
	
	Variable nwaves, rcnt, wcnt, config, chan, chanCount, npnts
	String wname, gdf, cdf = ClampDF(), sdf = StimDF()
	
	if (NumVarOrDefault(sdf+"AcqMode", 0) == 1) // continuous
		InterStimTime = 0
		InterRepTime = 0
	endif
	
	NVAR CurrentWave
	
	Variable pulseOff = NumVarOrDefault(sdf+"PulseGenOff", 0)
	Variable SampleInterval = NumVarOrDefault(sdf+"SampleInterval", 0)
	Variable SamplesPerWave = WaveLength / SampleInterval
	
	Wave DACon = $(sdf+"DACon")
	Wave TTLon = $(sdf+"TTLon")
	Wave ADCon = $(sdf+"ADCon")
	Wave ADCscale = $(sdf+"ADCscale")
	Wave ADCmode = $(sdf+"ADCmode")
	
	Make /O/N=(SamplesPerWave) CT_OutTemp
	Setscale /P x 0, SampleInterval, CT_OutTemp
	
	nwaves = NumStimWaves * NumStimReps // total number of waves

	ClampAcquireStart(mode, nwaves)
	
	for (rcnt = 0; rcnt < NumStimReps; rcnt += 1) // loop thru reps
	
	ClampWait(InterRepTime) // inter-rep time

	for (wcnt = 0; wcnt < NumStimWaves; wcnt += 1) // loop thru stims
	
		ClampWait(InterStimTime) // inter-wave time
		
		CT_OutTemp = 0
		npnts = numpnts(DACon)
		
		for (config = 0; config < npnts; config += 1)
		
			if (DACon[config] == 1)
			
				chan = StimWaveVar(sdf, "DAC", "chan", config)
			
				//if (pulseOff == 0)
					wname = sdf + StimWaveName("DAC", config, wcnt)
				//else
				//	wname = sdf + StimWaveName("MyDAC", config, wcnt)
				//endif
				
				if (WaveExists($wname) == 1)
					Wave wtemp = $wname
					CT_OutTemp += wtemp
				endif
				
			endif
			
		endfor
		
		npnts = numpnts(TTLon)
		
		for (config = 0; config < npnts; config += 1)
		
			if (TTLon[config] == 1)
			
				chan = StimWaveVar(sdf, "TTL", "chan", config)
				
				//if (pulseOff == 0)
					wname = sdf + StimWaveName("TTL", config, wcnt)
				//else
				//	wname = sdf + StimWaveName("MyTTL", config, wcnt)
				//endif
				
				if (WaveExists($wname) == 1)
					Wave wtemp = $wname
					CT_OutTemp += wtemp
				endif
				
			endif
			
		endfor
		
		ClampWait(WaveLength) // simulates delay in acquisition
		
		chanCount = 0
		npnts = numpnts(ADCon)

		for (config = 0; config < npnts; config += 1)
		
			if ((ADCon[config] == 1) && (ADCmode[config] == 0)) // stim/samp
			
				gdf = ChanDF(chanCount)
				
				if (NumVarOrDefault(gdf+"overlay", 0) > 0)
					ChanOverlayUpdate(chanCount)
				endif
				
				if (mode == 1) // record
					wname = GetWaveName("default", chanCount, CurrentWave)
				else // preview
					wname = GetWaveName("default", chanCount, 0)
				endif
				
				CT_OutTemp /= ADCscale[config]
				
				Duplicate /O CT_OutTemp $wname

				ChanWaveMake(chanCount, wName, ChanDisplayWave(chanCount)) // make display wave
		
				if ((mode == 1) && (saveWhen == 2))
					ClampNMbinAppend(wname) // update waves in saved folder
				endif
				
				chanCount += 1
				
			endif
			
		endfor
		
		ClampAcquireNext(mode, nwaves)
		
		if (ClampAcquireCancel() == 1)
			break
		endif

	endfor
	
		if (ClampAcquireCancel() == 1)
			break
		endif
		
	endfor
	
	KillWaves /Z CT_OutTemp
	
	ClampAcquireFinish(mode, savewhen)
	
	return 0

End // ClampAcquireDemo

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireStart(mode, nwaves) // update folders and graphs, start timers
	Variable mode, nwaves
	
	String cdf = ClampDF()
	String gtitle = "Clamp Acquire"
	String wPrefix = StrVarOrDefault("WavePrefix", "Record")
	String currentStim = StimCurrent()
	
	Variable stats = StimStatsOn()

	ClampDataFolderUpdate(nwaves, mode)
	ClampGraphsUpdate(mode)
	UpdateNMPanel(0)
	ClampButtonDisable(mode)
	
	ClampStatsDisplay(0) // clear display
	ClampStatsRemoveWaves(1) // kill waves
	
	if (stats == 1)
		StatsWinSelectUpdate()
		StatsWavesMake(NumVarOrDefault("CurrentChan", 0), 1)
		ClampStatsDisplay(1)
	endif
	
	if (mode >= 0)
		ClampFxnExecute("pre") // compute pre-stim analyses
	endif
	
	if (NumVarOrDefault(cdf+"ClampError", -1) == -1)
		return -1
	endif
	
	CallProgress(0)
	
	DoUpdate
	
	Variable tref = stopMSTimer(0)
	
	SetNMvar(cdf+"TimerRef", startMSTimer)
	
	return 0

End // ClampAcquireStart

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireNext(mode, nwaves) // increment counters, online analyses
	Variable mode, nwaves
	
	Variable tstamp, tintvl, cancel, ccnt
	
	String cdf = ClampDF()
	
	NVAR CurrentChan, CurrentWave, CurrentGrp, NumGrps, NumChannels
	
	Wave CT_TimeStamp, CT_TimeIntvl
	
	Variable firstGrp = NMGroupFirstDefault()
	Variable tref = NumVarOrDefault(cdf+"TimerRef", 0)
	
	String gtitle = StrVarOrDefault(cdf+"ChanTitle", "Clamp Acquire")
	
	if (WinType("ChanA") == 1)
		gtitle = NMFolderListName("") + " : Ch A : " + num2str(CurrentWave)
		DoWindow /T ChanA, gtitle
	endif
	
	for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
		if (NumVarOrDefault(ChanDF(ccnt)+"AutoScale", 1) == 0)
			ChanGraphAxesSet(ccnt)
		endif
	endfor

	if (StimStatsOn() == 1)
		StatsComputeAmps(ChanDisplayWave(CurrentChan), CurrentChan, CurrentWave, -1, 1, 1)
		ClampStatsDisplayUpdate(CurrentWave, nwaves)
	endif
	
	if (mode >= 0)
		ClampFxnExecute("inter")
	endif
	
	tintvl = stopMSTimer(tref)/1000
	tref = startMSTimer
	tstamp = tintvl
	
	SetNMvar(cdf+"TimerRef", tref)
	
	if (CurrentWave == 0)
		tintvl = Nan
	else
		tstamp += CT_TimeStamp[CurrentWave-1]
	endif
	
	CT_TimeStamp[CurrentWave] = tstamp
	CT_TimeIntvl[CurrentWave] = tintvl
	
	CurrentWave += 1
	CurrentGrp += 1
	
	if (CurrentGrp - firstGrp == NumGrps)
		CurrentGrp = firstGrp
	endif
	
	cancel = CallProgress(CurrentWave/nwaves)
	
	DoUpdate
	
	return cancel

End // ClampAcquireNext

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireFinish(mode, savewhen)
	Variable mode // (0) preview (1) record (-1) test timers (-2) error
	Variable savewhen // (0) never (1) after (2) while
	
	String file, cdf = ClampDF()
	
	NVAR NumWaves, CurrentWave, NumActiveWaves
	
	SetNMstr("FileFinish", time())
	
	CallProgress(1) // close progress window
	
	if (StimStatsOn() == 1)
		ClampStatsResize(CurrentWave)
	endif
	
	NumWaves = CurrentWave
	CurrentWave = 0
	
	ClampGraphsFinish()
	CheckNMDataFolder()
	ChanWaveListSet(1) // set channel wave names
	NMGroupSeqDefault()
	UpdateNMPanel(0)
	ClampTgainConvert()
	
	if (mode >= 0)
		ClampFxnExecute("post") // compute post-stim analyses
	endif
	
	if (mode <= 0) // preview, test, error
	
		NumWaves = 0 // back to zero
		NumActiveWaves = 0
		
	elseif (mode == 1) // record and update Notes and Log variables
	
		if (strlen(StrVarOrDefault(NotesDF()+"H_Name", "")) == 0)
			NotesEditHeader()
		endif
		
		NotesBasicUpdate()
		NotesCopyVars(LogDF(),"H_") // update header Notes
		NotesCopyFolder(GetDataFolder(1)+"Notes") // copy Notes to data folder
		ClampAcquireNotes()
		ClampSaveFinish() // save data folder
		NotesBasicUpdate() // do again, this includes new external file name
		NotesCopyFolder(LogDF()+StrVarOrDefault(cdf+"CurrentFolder","nofolder")) // save log notes
		
		if (NumVarOrDefault(cdf+"LogAutoSave", 1) == 1)
			LogSave()
		endif
		
		LogDisplay2(LogDF(), NumVarOrDefault(cdf+"LogDisplay", 1))
		
		NotesClearFileVars() // clear file note vars before next recording
		
	endif
	
	ClampButtonDisable(-1)
	
	ClampAvgInterval()
	
	//if ((mode == 1) && (NumVarOrDefault(NMDF()+"AutoPlot", 0) == 1))
	//	ResetCascade()
	//	NMPlot( "" )
	//endif
	
	return 0

End // ClampAcquireFinish

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireCancel()
	
	return (NumVarOrDefault("V_Progress", 0) == 1)

End // ClampAcquireCancel

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireNotes()
	Variable ccnt, wcnt
	String wName, wNote, yl, type = "NMData"
	
	String stim = StimCurrent()
	String folder = GetDataFolder(0)
	String fdate = StrVarOrDefault("FileDate", "")
	String ftime = StrVarOrDefault("FileTime", "")
	String xl = StrVarOrDefault("xLabel", "")
	
	NVAR NumChannels, NumWaves
	
	Wave CT_TimeStamp
	Wave /T yLabel
	
	for (ccnt = 0; ccnt < NumChannels; ccnt += 1)
	
		yl = yLabel[ccnt]
	
		for (wcnt = 0; wcnt < NumWaves; wcnt += 1)
	
			wName = GetWaveName("default", ccnt, wcnt)
			
			wNote = "Stim:" + stim
			wNote += "\rFolder:" + folder
			wNote += "\rDate:" + NMNoteCheck(fdate)
			wNote += "\rTime:" + NMNoteCheck(ftime)
			wNote += "\rTime Stamp:" + num2strLong(CT_TimeStamp[wcnt], 3) + " msec"
			wNote += "\rChan:" + ChanNum2Char(ccnt)
			
			NMNoteType(wName, type, xl, yl, wNote)
		
		endfor
		
	endfor
	
End // ClampAcquireNotes

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAvgInterval()
	Variable rcnt, wcnt, we, wn, re, rn, dr, icnt, isi
	String txt, sdf = StimDF()
	
	Variable amode = NumVarOrDefault(sdf + "AcqMode", -1)
	Variable WaveLength = NumVarOrDefault(sdf+"WaveLength", 0)
	Variable NumStimWaves = NumVarOrDefault(sdf+"NumStimWaves", 0)
	Variable interStimTime = NumVarOrDefault(sdf+"InterStimTime", 0)
	Variable NumStimReps = NumVarOrDefault(sdf+"NumStimReps", 0)
	Variable interRepTime = NumVarOrDefault(sdf+"InterRepTime", 0)
	
	if ((amode != 2) || (WaveExists(CT_TimeIntvl) == 0))
		return 0
	endif
	
	Wave CT_TimeIntvl
	
	for (rcnt = 0; rcnt < NumStimReps; rcnt += 1) // loop thru reps
	
		for (wcnt = 0; wcnt < NumStimWaves; wcnt += 1) // loop thru stims
			
			//dw = WaveLength + interStimTime + dr
			isi = CT_TimeIntvl[icnt]
			
			if (numtype(isi) == 0)
				if (dr == 0) // clock controlling inter-stim times
					we += isi
					wn += 1
				else // clock controlling inter-rep times
					re += isi
					rn += 1
				endif
			endif
			
			dr = 0
			icnt += 1
			
		endfor
		
		dr = interRepTime
		
	endfor
	
	if (wn > 0)
		we /= wn
		Print "Average episodic wave interval:", we, " msec"
	endif
	
	if (rn > 0)
		re /= rn
		//Print "Average episodic rep interval:", re, " msec"
	endif

End // ClampAvgInterval

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireManager(atype, callmode, savewhen) // call appropriate aquisition function
	String atype // acqusition board ("Demo", "ITC", "NIDAQ")
	Variable callmode // (0) preview (1) record (-1) test timers (-2) config test
	Variable savewhen // (0) never (1) after (2) while
	
	String cdf = ClampDF(), sdf = StimDF() 
	
	Variable WaveLength = NumVarOrDefault(sdf+"WaveLength", 0)
	Variable NumStimWaves = NumVarOrDefault(sdf+"NumStimWaves", 0)
	Variable interStimTime = NumVarOrDefault(sdf+"InterStimTime", 0)
	Variable NumStimReps = NumVarOrDefault(sdf+"NumStimReps", 0)
	Variable interRepTime = NumVarOrDefault(sdf+"InterRepTime", 0)
	
	String currentStim = StimCurrent()
	
	ClampError("")
	
	switch(callmode)
		case -1: // test timers
			NMProgressStr("Testing Timers...")
			break
		case 0: // preview
			NMProgressStr("Preview : " + currentStim)
			break
		case 1: // record
			NMProgressStr("Record : " + currentStim)
			break
		default:
			NMProgressStr("")
			break
	endswitch

	strswitch(atype)
	
		case "Demo":
		
			switch(callmode)
			
				case -2: // test config
					ClampConfigDemo()
					break
				case -1: // test timers
					break // (nothing to do)
					
				case 0: // preview
				case 1: // record
					ClampAcquireDemo(callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime)
					break
					
				default:
					ClampError("demo acquire mode " + num2str(callmode) + " not supported.")
					return -1
					
			endswitch
			
			break
		
		case "NIDAQ":
			
			switch(callmode)
			
				case -2: // config
					Execute /Z "NIDAQconfig()"
					if (V_flag != 0)
						ClampError("cannot locate function in NM_ClampNIDAQ.ipf")
						return -1
					endif
					break
					
				case -1: // test timers
				
					if (ClampTestClockErrors("root:Packages:NIDAQTools:") == 0)
						break
					endif
					
					WaveLength = 100
					NumStimWaves = 2; interStimTime = 100
					NumStimReps = 10; interRepTime = 100
					
				case 0: // preview
				case 1: // record
					Execute /Z "NIDAQacquire" + ClampParameterList(callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime)
					if (V_flag != 0)
						ClampError("cannot locate function in NM_ClampNIDAQ.ipf")
						return -1
					endif
					if (callmode == -1)
						ClampUpdateClockErrors("root:Packages:NIDAQTools:", WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime)
					endif
					break
					
				default:
					ClampError("NIDAQ acquire mode " + num2str(callmode) + " not supported.")
					return -1
					
			endswitch
			
			break
			
		case "ITC16":
		case "ITC18":
		
			switch(callmode)
				case -2: // config
					Execute /Z "ITCconfig(\"" + atype + "\")"
					if (V_flag != 0)
						ClampError("cannot locate function in NM_ClampITC.ipf")
						return -1
					endif
					break
					
				case -1: // test timers (nothing to do)
					break
					
				case 0: // preview
				case 1: // record
					Execute /Z "ITCacquire" + ClampParameterList(callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime)
					if (V_flag != 0)
						ClampError("cannot locate function in NM_ClampITC.ipf")
						return -1
					endif
					break
					
				default:
					ClampError("ITC acquire mode " + num2str(callmode) + " not supported")
					return -1
					
			endswitch
			
			break
			
		default:
			ClampError("interface " + atype + " is not supported.")
			return -1
			break
		
	endswitch

	return NumVarOrDefault(cdf+"ClampError", -1)

End // ClampAcquireManager

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampReadManager(atype, board, ADCchan, gain, npnts) // call appropriate read function
	String atype // acqusition board ("Demo", "ITC", "NIDAQ")
	Variable board
	Variable ADCchan // ADC input channel to read
	Variable gain
	Variable npnts // number of points to average
	
	String cdf = ClampDF(), vlist = ""
	
	SetNMvar(cdf+"ClampReadValue", Nan)
	
	strswitch(atype)
	
		case "Demo":
			return Nan
			break
		
		case "NIDAQ":
		
			vlist = AddListItem(num2str(board), vlist, ",", inf)
			vlist = AddListItem(num2str(ADCchan), vlist, ",", inf)
			vlist = AddListItem(num2str(gain), vlist, ",", inf)
			vlist += num2str(npnts) 
			
			Execute /Z "NIDAQread(" + vlist + ")"
			
			if (V_flag != 0)
				ClampError("cannot locate function in NM_ClampNIDAQ.ipf")
				return Nan
			endif
			
			break
			
		case "ITC16":
		case "ITC18":
		
			vlist = AddListItem(num2str(ADCchan), vlist, ",", inf)
			vlist = AddListItem(num2str(gain), vlist, ",", inf)
			vlist += num2str(npnts) 
			
			Execute /Z "ITCread(" + vlist + ")"
			
			if (V_flag != 0)
				ClampError("cannot locate function in NM_ClampITC.ipf")
				return Nan
			endif
			
			break
			
		default:
			ClampError("interface " + atype + " is not supported.")
			return Nan
			
	endswitch

	return NumVarOrDefault(cdf+"ClampReadValue", Nan)
	
End // ClampReadManager

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampParameterList(callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime)
	Variable callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime

	String paramstr = "("+num2str(callmode)+","+num2str(savewhen)+","+num2str(WaveLength)+","+num2str(NumStimWaves)+","
	paramstr += num2str(interStimTime)+","+num2str(NumStimReps)+","+num2str(interRepTime)+")"
	
	return paramstr

End // ClampParameterList

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampFxnExecute(select)
	String select
	
	String flist, fxn, sdf = StimDF()
	Variable icnt
	
	strswitch(select)
	
		case "pre":
		case "pre-stim":
			flist = StrVarOrDefault(sdf+"PreStimFxnList","")
			break
			
		case "inter":
		case "inter-stim":
			flist = StrVarOrDefault(sdf+"InterStimFxnList","")
			break
			
		case "post":
		case "post-stim":
			flist = StrVarOrDefault(sdf+"PostStimFxnList","")
			break
			
	endswitch
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
	
		fxn = StringFromList(icnt, flist)
		
		if (StringMatch(fxn[strlen(fxn)-3,strlen(fxn)-1],"(0)") == 0)
			fxn += "(0)" // run function
		endif
		
		Execute /Z fxn
		
	endfor

End // ClampFxnExecute

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAcquireChain(AcqBoard, mode)
	String AcqBoard
	Variable mode // (0) preview (1) record (-1) test timers
	
	Variable scnt, npnts
	String sname, cdf = ClampDF(), sdf = StimDF()

	if (WaveExists($(sdf+"Stim_Name")) == 0)
		return -1
	endif
	
	String aboard = StrVarOrDefault(cdf+"AcqBoard", "")
	String saveStim = StimCurrent()
	
	Wave /T Stim_Name = $(sdf+"Stim_Name")
	Wave Stim_Wait = $(sdf+"Stim_Wait")
	
	if (numpnts(Stim_Name) == 0)
		ClampError("Alert: no stimulus protocols in Run Stim List.")
		return -1
	endif
	
	npnts = numpnts(Stim_Name)
	
	for (scnt = 0; scnt < npnts; scnt += 1)
	
		sname = Stim_Name[scnt]
		
		if (strlen(sname) == 0)
			continue
		endif
		
		if (IsStimFolder(cdf, sname) == 0)
			DoAlert 0, "Alert: stimulus protocol \"" + sname + "\" does not appear to exist."
			continue
		endif
		
		if (StimCurrentSet(sname) == 0)
			ClampTabUpdate()
			ClampAcquire(AcqBoard, mode)
			ClampWait(Stim_Wait[scnt]) // delay in acquisition
		endif
		
		if (ClampAcquireCancel() == 1)
			break
		endif
		
	endfor
	
	StimCurrentSet(saveStim)
	ClampTabUpdate()

End // ClampAcquireChain

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampConfigCheck()
	String sdf = StimDF()
	
	if (WaveExists($(sdf+"ADCon")) == 0)
		ClampError("ADC input has not been configured.")
		return -1
	endif
	
	if (StimOnCount(sdf, "ADC") == 0)
		ClampError("ADC input has not been configured.")
		return -1
	endif
	
	return StimCheckChannels()
	
End // ClampConfigCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampConfigDemo()

	String cdf = ClampDF()
	
	ClampError("")
	
	SetNMStr(cdf+"AcqBoard", "Demo")
	SetNMVar(cdf+"BoardDriver", 0)
	SetNMStr(cdf+"BoardList", "0, Demo;")
	
	return 0

End // ClampConfigDemo

//****************************************************************
//****************************************************************
//****************************************************************
//
//
//	Telegraph gain functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTgainConfig()
	Variable icnt, achan, gchan, on, mode, ibgn, iend
	String item, tlist = ""
	
	String cdf = ClampDF()
	
	String blist = StrVarOrDefault(cdf+"BoardList", "")
	Variable driver = NumVarOrDefault(cdf+"BoardDriver", 0)
	
	String instr = StrVarOrDefault(cdf+"ClampInstrument", "")
	String tGainList = StrVarOrDefault(cdf+"TGainList", "")
	
	Prompt mode, " ", popup "edit existing config;add new config;"
	Prompt gchan, "ADC input channel to read telegraph gain:"
	Prompt achan, "ADC input channel to scale:"
	Prompt instr, "telegraphed instrument:", popup "Axopatch200B;AM2400"
	Prompt on, " ", popup "off;on;"
	
	if (ItemsInList(tGainList) > 0)
	
		DoPrompt "ADC Telegraph Gain Config", mode
	
		if (V_flag == 1)
			return -1 // cancel
		endif
		
	else
	
		mode = 2 // nothing to edit
		
	endif
	
	if (mode == 1)
		ibgn = 0; iend = ItemsInList(tGainList) - 1
	elseif (mode == 2)
		ibgn = ItemsInList(tGainList); iend = ItemsInList(tGainList)
		tlist = TGainList
		tGainList = ""
	endif
	
	for (icnt = ibgn; icnt <= iend; icnt += 1)
	
		if (icnt < ItemsInList(tGainList))
			item = StringFromList(icnt, tGainList)
			gchan = str2num(StringFromList(0, item, ","))
			achan = str2num(StringFromList(1, item, ","))
		else
			gchan = 1
			achan = 0
		endif
		
		on = 2
		
		DoPrompt "ADC Telegraph Gain Config " + num2str(icnt), on, gchan, achan, instr
		
		if (V_flag == 1)
			return -1 // cancel
		endif
		
		item = num2str(gchan) + "," + num2str(achan)
		
		if ((on == 2) && (WhichListItem(item, tlist) == -1))
			tlist = AddListItem(item, tlist, ";", inf)
		endif
		
	endfor
	
	SetNMstr(cdf+"TGainList", tlist)
	SetNMstr(cdf+"ClampInstrument", instr)

End // ClampTgainConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTgainUpdate()
	Variable icnt, config, aChan, gChan, npnts
	String item
	
	String cdf = ClampDF(), sdf = StimDF()
	
	String tGainList = StrVarOrDefault(cdf+"TGainList", "")

	Wave ADCon = $(sdf+"ADCon")
	Wave ADCchan = $(sdf+"ADCchan")

	if (strlen(tGainList) > 0)
	
		npnts = numpnts(ADCon)
		
		Make /O/N=(npnts) $(cdf+"ADCtgain") = Nan
		
		Wave ADCtgain = $(cdf+"ADCtgain")
	
		for (icnt = 0; icnt < ItemsInList(tGainList); icnt += 1)
		
			item = StringFromList(icnt, tGainList)
			gChan = str2num(StringFromList(0, item, ",")) // corresponding telegraph ADC input channel
			aChan = str2num(StringFromList(1, item, ",")) // ADC input channel
			
			for (config = 0; config < npnts; config += 1)
			
				if ((ADCon[config] == 1) && (ADCchan[config] == achan))
					ADCtgain[config] = gChan
					break
				endif
				
			endfor
			
		endfor
		
	endif

End // ClampTgainUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTgainValue(df, chanNum, waveNum)
	String df // data folder
	Variable chanNum
	Variable waveNum
	
	Variable npnts
	
	String wname = df + "CT_Tgain" + num2str(chanNum) // telegraph gain wave
	
	if (WaveExists($wname) == 0)
		return -1
	endif
	
	Wave temp = $wname

	if (waveNum == -1) // return avg of wave
		npnts = numpnts(temp)
		WaveStats /Q/R=[npnts-3,npnts-1] temp
		return V_avg
	else
		return temp[waveNum]
	endif

End // ClampTgainValue

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTgainConvert() // convert final tgain values to scale values
	Variable ocnt, icnt, tvalue, npnts
	String olist, oname
	
	olist = WaveList("CT_Tgain*", ";", "") // created by NIDAQ code
	
	for (ocnt = 0; ocnt < ItemsInList(olist); ocnt += 1)
	
		oname = StringFromList(ocnt, olist)
		
		Wave wtemp = $oname
		
		npnts = numpnts(wtemp)
		
		for (icnt = 0; icnt < npnts; icnt += 1)
		
			tvalue = wtemp[icnt]
			
			if (numtype(tvalue) == 0)
				wtemp[icnt] = MyTelegraphGain(tvalue, tvalue)
			endif
			
		endfor
	
	endfor
	
	olist = VariableList("Tgain*",";",4+2) // created by ITC code
	
	for (ocnt = 0; ocnt < ItemsInList(olist); ocnt += 1)
	
		oname = StringFromList(ocnt, olist)
		
		tvalue = NumVarOrDefault(oname, -1)
		
		if (tvalue == -1)
			continue
		endif
		
		SetNMvar(oname, MyTelegraphGain(tvalue, tvalue))
		
	endfor

End // ClampTgainConvert

//****************************************************************
//****************************************************************
//****************************************************************
//
//
//	Igor-timed clock functions
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampWait(t)
	Variable t
	
	if (IgorVersion() >= 5)
		return ClampWaitMSTimer(t)
	else
		return ClampWaitTicks(t)
	endif
	
End // ClampWait

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampWaitTicks(t) // wait t msec (only accurate to 17 msec)
	Variable t
	
	if (t == 0)
		return 0
	endif
	
	Variable t0 = ticks
	
	t *= 60 / 1000

	do
	while ((ClampAcquireCancel() == 0) && (ticks - t0 < t ))
	
	return 0
	
End // ClampWaitTicks

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampWaitMSTimer(t) // wait t msec (this is more accurate)
	Variable t
	
	if (t == 0)
		return 0
	endif
	
	Variable t0 = stopMSTimer(-2)
	
	t *= 1000 // convert to usec
	
	do
	while ((ClampAcquireCancel() == 0) && (stopMSTimer(-2) - t0 < t ))
	
	return 0
	
End // ClampWaitMSTimer

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampUpdateClockErrors(dpath, WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime)
	String dpath // directory path of clock variables
	Variable WaveLength, NumStimWaves, InterStimTime, NumStimReps, InterRepTime // msec
	
	if (WaveExists(CT_TimeIntvl) == 0)
		return -1
	endif

	Wave CT_TimeIntvl
	
	Variable interStimError = NumVarOrDefault((dpath + "InterStimError"), 0)
	Variable interStimCnt = NumVarOrDefault((dpath + "InterStimCnt"), 0)
	Variable interStimCF = NumVarOrDefault((dpath + "InterStimCF"), 0)
	Variable interRepError = NumVarOrDefault((dpath + "InterRepError"), 0)
	Variable interRepCnt = NumVarOrDefault((dpath + "InterRepCnt"), 0)
	Variable interRepCF = NumVarOrDefault((dpath + "InterRepCF"), 0)
	
	if ((interStimCF == 0) && (interRepCF == 0))
		return 0 // nothing to compute
	endif

	Variable icnt, rcnt, wcnt, isi, dw, dr
	Variable we, wn, re, rn
	
	for (rcnt = 0; rcnt < NumStimReps; rcnt += 1) // loop thru reps
		for (wcnt = 0; wcnt < NumStimWaves; wcnt += 1) // loop thru stims
			dw = WaveLength + interStimTime + dr
			isi = CT_TimeIntvl[icnt]
			if (numtype(isi) == 0)
				if (dr == 0) // clock controlling inter-stim times
					we += isi - dw
					wn += 1
				else // clock controlling inter-rep times
					re += isi - dw
					rn += 1
				endif
			endif
			dr = 0
			icnt += 1
		endfor
		dr = interRepTime
	endfor
	
	if (interStimCF == 1)
		if ((wn > 0) && (numtype(wn) == 0))
			we /= wn
			we += interStimError
			interStimError = (interStimError * interStimCnt + we * wn) / (interStimCnt + wn)
			interStimCnt += wn
		endif
	else
		interStimError = 0
		interStimCnt = 0
	endif
	
	if (interRepCF == 1)
		if ((rn > 0) && (numtype(rn) == 0))
			re /= rn
			re -= we
			re += interRepError
			interRepError = (interRepError * interRepCnt + re * rn) / (interRepCnt + rn)
			interRepCnt += rn
		endif
	else
		interRepError = 0
		interRepCnt = 0
	endif
	
	SetNMVar((dpath + "InterStimError"), interStimError)
	SetNMVar((dpath + "InterStimCnt"), interStimCnt)
	SetNMVar((dpath + "InterRepError"), interRepError)
	SetNMVar((dpath + "InterRepCnt"), interRepCnt)

End // ClampUpdateClockErrors

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampZeroClockErrors(dpath)
	String dpath // directory path of clock variables
	
	SetNMVar((dpath + "InterStimError"), 0)
	SetNMVar((dpath + "InterStimCnt"), 0)
	SetNMVar((dpath + "InterRepError"), 0)
	SetNMVar((dpath + "InterRepCnt"), 0)

End // ClampZeroClockErrors

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTestClockErrors(dpath)
	String dpath // directory path of clock variables
	Variable test

	Variable interStimError = NumVarOrDefault((dpath + "InterStimError"), 0)
	Variable interStimCnt = NumVarOrDefault((dpath + "InterStimCnt"), 0)
	Variable interStimCF = NumVarOrDefault((dpath + "InterStimCF"), 0)
	Variable interRepError = NumVarOrDefault((dpath + "InterRepError"), 0)
	Variable interRepCnt = NumVarOrDefault((dpath + "InterRepCnt"), 0)
	Variable interRepCF = NumVarOrDefault((dpath + "InterRepCF"), 0)
	
	if (interStimCF == 1)
		if (numtype(interStimCnt * interStimError) > 0)
			test = 1
		endif
		if ((interStimCnt == 0) || (interStimError <= 0))
			test = 1
		endif
	endif
	
	if (interRepCF == 1)
		if (numtype(interRepCnt * interRepError) > 0)
			test = 1
		endif
		if ((interRepCnt == 0) || (interRepError <= 0))
			test = 1
		endif
	endif

	if (test == 1)
		ClampZeroClockErrors(dpath)
	endif
	
	return test
	
End // ClampTestClockErrors

//****************************************************************
//****************************************************************
//****************************************************************
//
//
//	Channel graph functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampGraphsCopy(chanNum, direction)
	Variable chanNum // (-1) for all
	Variable direction // (1) data folder to clamp data folder (-1) visa versa

	Variable ccnt
	String cdf = ClampDF(), sdf = StimDF(), gdf = GetDataFolder(1)
	
	String currFolder = StrVarOrDefault(cdf + "CurrentFolder", "")
	
	if (direction == 1)
		ChanFolderCopy(-1, gdf, sdf, 1)
	elseif (direction == -1)
		ChanFolderCopy(-1, sdf, gdf, 0)
	endif

End // ClampGraphsCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampGraphsUpdate(mode)
	Variable mode
	
	Variable ccnt, icnt
	String gName, wlist, wname, cdf = ClampDF()
	
	Variable numChannels = NumVarOrDefault("NumChannels", 0)
	Variable GetChanConfigs = NumVarOrDefault(cdf+"GetChanConfigs", 0)
	
	if (GetChanConfigs == 1)
		ClampGraphsCopy(-1, -1)
		SetNMVar(cdf+"GetChanConfigs", 0)
	else
		ClampGraphsCopy(-1, 1)
	endif
	
	ChanGraphsUpdate(1) // set scales
	ChanWavesClear(-1) // clear all display waves
	
	for (ccnt = 0; ccnt < numChannels; ccnt += 1)
	
		gName = ChanGraphName(ccnt)
	
		if (Wintype(gName) == 0)
			continue
		endif
		
		ChanControlsDisable(ccnt, "111111") // turn off controls (eliminates flashing)
		
		wlist = WaveList("*", ";", "WIN:" + gName)
		
		for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
			wname = StringFromList(icnt, wlist)
			RemoveFromGraph /Z/W=$gName $wname // remove extra waves
		endfor
		
		ChanGraphTagsKill(ccnt)
		
		DoWindow /T $gName, NMFolderListName("") + " : Ch " + ChanNum2Char(ccnt)
		
		DoWindow /F $gName
		
		HideInfo /W=$gName
		
		// kill cursors in case they exist
		Cursor /K/W=$gName A // kill cursor A
		Cursor /K/W=$gName B // kill cursor B
		
	endfor
	
	if (NumChannels > 0)
		ChanGraphClose(-2, 1) // close unecessary windows (kills Chan DF)
	endif
	
	StatsDisplay(StimStatsOn())

End // ClampGraphsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampGraphsFinish()
	Variable ccnt
	
	for (ccnt = 0; ccnt < NumVarOrDefault("NumChannels", 0); ccnt += 1)
		ChanControlsDisable(ccnt, "000000")
	endfor

End // ClampGraphsFinish

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAutoScale()
	Variable chan
	
	String gName = WinName(0,1) // top graph
	
	if (StringMatch(gName[0,3], "Chan") == 1)
		chan = ChanNumGet(gName)
	else
		chan = 0
		gName = "ChanA"
	endif
	
	SetAxis /A/W=$gName
	
	ChanAutoScale(chan, 1)

End // ClampAutoScale

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampZoom(xzoom, yzoom, xshift, yshift)
	Variable xzoom, yzoom, xshift, yshift
	Variable chan, xmin, xmax, ymin, ymax, ydelta, xdelta
	
	Variable zfactor = 0.1 // zoom factor
	
	String gName = WinName(0,1) // top graph
	String cdf = ClampDF()
	
	if (StringMatch(gName[0,3], "Chan") == 1)
		chan = ChanNumGet(gName)
	else
		chan = 0
		gName = "ChanA"
	endif
	
	String wName = ChanDisplayWave(chan) // display wave
	
	GetAxis /Q/W=$gName bottom
	xmin = V_min; xmax = V_max
		
	GetAxis /Q/W=$gName left
	ymin = V_min; ymax = V_max
	
	ydelta = abs(ymax - ymin)
	xdelta = abs(xmax - xmin)
	
	ymin -= yzoom * zfactor * ydelta
	ymax += yzoom * zfactor * ydelta
	
	ymin += yshift * zfactor * ydelta
	ymax += yshift * zfactor * ydelta
	
	xmin -= xzoom * zfactor * xdelta
	xmax += xzoom * zfactor * xdelta
	
	xmin += xshift * zfactor * xdelta
	xmax += xshift * zfactor * xdelta
	
	SetAxis /W=$gName bottom xmin, xmax
	SetAxis /W=$gName left ymin, ymax
	
	ChanAutoScale(chan, 0)
	
	SetNMVar(cdf+"AutoScale" + num2str(chan), 0)
	SetNMVar(cdf+"xAxisMin" + num2str(chan), xmin)
	SetNMVar(cdf+"xAxisMax" + num2str(chan), xmax)
	SetNMVar(cdf+"yAxisMin" + num2str(chan), ymin)
	SetNMVar(cdf+"yAxisMax" + num2str(chan), ymax)

End // ClampZoom

//****************************************************************
//****************************************************************
//****************************************************************
//
//
//	Clamp Online Stats functions
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStats(on)
	Variable on // (0) no (1) yes
	
	String cdf = ClampDF(), sdf = StimDF()
	
	if (DataFolderExists(sdf) == 0)
		return -1
	endif
	
	SetNMvar(sdf+"StatsOn", on)
	
	if (on == 1)
	
		if (DataFolderExists(sdf+"Stats") == 1)
		
			DoAlert 1, "A Stats configuration for this stimulus already exists. Do you want to over-write it with the current configuration?"
			
			if (V_flag == 1)
				ClampStatsSave(sdf)
			else
				ClampStatsRetrieve(sdf)
			endif
			
		endif
		
	endif
	
	return 0
	
End // ClampStats

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsSave(sdf) // save Stats waves to stim folder
	String sdf // stim data folder
	
	if ((DataFolderExists(sdf) == 1) && (StimStatsOn() == 1))
		StatsWavesCopy(StatsDF(), sdf+"Stats")
	endif

End // ClampStatsSave

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsSaveAsk(sdf)
	String sdf // stim data folder
	
	if (StatsTimeStampCompare(StatsDF(), sdf+"Stats:") == 0)
	
		DoAlert 1, "Your Stats configuration has changed. Do you want to update the current stimulus configuration to reflect these changes?"
		
		if (V_flag == 1)
			ClampStatsSave(sdf)
		endif
	
	endif

End // ClampStatsSaveAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsRetrieve(sdf) // retrieve Stats waves from stim folder
	String sdf // stim data folder
	
	if (StimStatsOn() == 0)
		return -1
	endif
	
	if ((DataFolderExists(sdf) == 0) || (StimStatsOn() == 0) || (DataFolderExists(sdf+"Stats") == 0))
		return -1
	endif
	
	StatsWavesCopy(sdf+"Stats", StatsDF())
	
	if (WaveExists($(StatsDF()+"ChanSelect")) == 1)
		Wave chan = $(StatsDF()+"ChanSelect")
		CurrentChanSet(chan[0])
	endif
		
	return 0

End // ClampStatsRetrieve

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsResize(npnts)
	Variable npnts
	
	Variable icnt
	String wname, wlist = WaveList("ST_*", ";", "")
	
	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
		wname = StringFromList(icnt, wlist)
		Redimension /N=(npnts) $wname
	endfor

End // ClampStatsResize

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplay(enable)
	Variable enable
	
	Variable red, green, blue, wcnt, acnt, askbsln, asktau, foundtau
	String wlist, wname, xy, amp, tbox = "", tbox2 = ""
	
	String gName = "ClampStatsAmp", gName2 = "ClampStatsTau"
	
	String cdf = ClampDF(), stdf = StatsDF()
	
	Variable gexists = WinType(gName)
	Variable texists = WinType(gName2)
	
	Variable numAmps = StatsWinCount()
	Variable numWaves = NumVarOrDefault("NumWaves", 0)
	
	Variable bsln = NumVarOrDefault(cdf+"StatsBslnDsply", 1)
	Variable tau = NumVarOrDefault(cdf+"StatsTauDsply", 2)
	
	String ampColor = StrVarOrDefault(stdf+"AmpColor", "65535,0,0")
	String baseColor = StrVarOrDefault(stdf+"BaseColor", "16386,65535,16385")
	String riseColor = StrVarOrDefault(stdf+"RiseColor", "0,0,65535")
	String dcayColor = StrVarOrDefault(stdf+"DcayColor", "0,0,65535")
	
	if (WaveExists($(stdf+"AmpSlct")) == 0)
		return -1
	endif
	
	Wave /T AmpSlct = $(stdf+"AmpSlct")
	Wave BslnSubt = $(stdf+"BslnSubt")
	
	if (gexists == 1) // remove waves
	
		wlist = WaveList("*", ";", "WIN:"+gName)
		
		for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
			wname = StringFromList(wcnt, wlist)
			RemoveFromGraph /Z/W=$gName $wname
		endfor
		
		TextBox /K/N=text0/W=$gName
		
	endif
	
	if (texists == 1) // remove tau waves
	
		wlist = WaveList("*", ";", "WIN:"+gName2)
		
		for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
			wname = StringFromList(wcnt, wlist)
			RemoveFromGraph /Z/W=$gName2 $wname
		endfor
		
		TextBox /K/N=text0/W=$gName2
		
	endif
	
	if ((StimStatsOn() == 0) || (enable == 0))
		return 0
	endif
	
	wlist = WaveList("ST_*",";","")
	
	foundtau = (StringMatch(wlist, "*ST_RiseT*") == 1) || (StringMatch(wlist, "*ST_DcayT*") == 1)
	
	if ((gexists == 0) || (texists == 0))
	
		if ((gexists == 0) && (StringMatch(wlist, "*ST_Bsln*") == 1))
			askbsln = 1
		endif
		
		if (foundtau == 1)
		if ((gexists == 0) || ((texists == 0) && (tau == 2)))
			asktau = 1
		endif
		endif
	
		bsln += 1
		tau += 1
	
		Prompt bsln, "Display baseline values?", popup "no;yes;"
		Prompt tau, "Display time constants?", popup "no;yes, same window;yes, seperate window;"
		
		if (askbsln && asktau)
			DoPrompt "Clamp Online Stats Display", bsln, tau
		elseif (askbsln && !asktau)
			DoPrompt "Clamp Online Stats Display", bsln
		elseif (!askbsln && asktau)
			DoPrompt "Clamp Online Stats Display", tau
		endif
	
		bsln -= 1
		tau -= 1
		
		SetNMvar(cdf+"StatsBslnDsply", bsln)
		SetNMvar(cdf+"StatsTauDsply", tau)
	
	endif
	
	if (gexists == 0)
		Make /O/N=0 CT_DummyWave
		DoWindow /K $gName
		Display /K=1/W=(0,0,200,100) CT_DummyWave as "NClamp Stats"
		DoWindow /C $gName
		RemoveFromGraph /Z CT_DummyWave
		KillWaves /Z CT_DummyWave
	endif
	
	DoWindow /F $gName
	
	tau *= foundtau
	
	if (tau == 2)
	
		if (texists == 0)
			Make /O/N=0 CT_DummyWave
			DoWindow /K $gName2
			Display /K=1/W=(20,50,220,150) CT_DummyWave as "Clamp Stats Time Constants"
			DoWindow /C $gName2
			RemoveFromGraph /Z CT_DummyWave
			KillWaves /Z CT_DummyWave
		endif
		
		DoWindow /F $gName2
		
	elseif (tau == 1)
	
		DoWindow /K $gName2
		gName2 = gName
		
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt += 1)
	
		wname = StringFromList(wcnt, wlist)
		
		if ((StringMatch(wname, "ST_Bsln*") == 1) && (bsln == 1))
		
			acnt = str2num(wname[7,7])
			
			red = str2num(StringFromList(0,baseColor,","))
			green = str2num(StringFromList(1,baseColor,","))
			blue = str2num(StringFromList(2,baseColor,","))
		
			AppendToGraph /W=$gName $wname
			ModifyGraph /W=$gName rgb($wname)=(red,green,blue)
			ModifyGraph /W=$gName marker($wname)=ClampStatsMarker(acnt)
			
			tbox += "\rbsln" + num2str(acnt) + " \\s(" + wname + ")"
			
		elseif ((StringMatch(wname, "ST_RiseT*") == 1) && (tau > 0))
		
			acnt = str2num(wname[8,8])
				
			red = str2num(StringFromList(0,riseColor,","))
			green = str2num(StringFromList(1,riseColor,","))
			blue = str2num(StringFromList(2,riseColor,","))
			
			if (tau == 1)
				AppendToGraph /R=tau /W=$gName2 $wname
				ModifyGraph axRGB(tau)=(red,green,blue)
				tbox += "\rriseT" + num2str(acnt) + " \\s(" + wname + ")"
			elseif (tau == 2)
				AppendToGraph /W=$gName2 $wname
				tbox2 += "\rriseT" + num2str(acnt) + " \\s(" + wname + ")"
			endif
			
			ModifyGraph /W=$gName2 rgb($wname)=(red,green,blue)
			ModifyGraph /W=$gName2 marker($wname)=ClampStatsMarker(acnt)
			
		elseif ((StringMatch(wname, "ST_DcayT*") == 1) && (tau > 0))
		
			acnt = str2num(wname[8,8])
		
			red = str2num(StringFromList(0,dcayColor,","))
			green = str2num(StringFromList(1,dcayColor,","))
			blue = str2num(StringFromList(2,dcayColor,","))
			
			if (tau == 1)
				AppendToGraph /R=tau /W=$gName2 $wname
				ModifyGraph axRGB(tau)=(red,green,blue)
				tbox += "\rdecayT" + num2str(acnt) + " \\s(" + wname + ")"
			elseif (tau == 2)
				AppendToGraph /W=$gName2 $wname
				tbox2 += "\rdecayT" + num2str(acnt) + " \\s(" + wname + ")"
			endif
			
			ModifyGraph /W=$gName2 rgb($wname)=(red,green,blue)
			ModifyGraph /W=$gName2 marker($wname)=ClampStatsMarker(acnt)
			
		else
		
			for (acnt = 0; acnt < numAmps; acnt += 1) // loop through stats amp windows
			
				amp = AmpSlct[acnt]
				xy = "*Y" + num2str(acnt) + "*"
				
				if (StringMatch(amp, "Level*") == 1)
					xy = "*X" + num2str(acnt) + "*"
				endif
			
				if (StringMatch(wname, xy) == 1)
				
					red = str2num(StringFromList(0,ampColor,","))
					green = str2num(StringFromList(1,ampColor,","))
					blue = str2num(StringFromList(2,ampColor,","))
			
					AppendToGraph /W=$gName $wname
					ModifyGraph /W=$gName rgb($wname)=(red,green,blue)
					ModifyGraph /W=$gName marker($wname)=ClampStatsMarker(acnt)
					
					tbox += "\r" + amp + num2str(acnt) + " \\s(" + wname + ")"
					
				endif
				
			endfor
		
		endif
		
	endfor
	
	ModifyGraph /W=$gName mode=4, msize=4, standoff=0 
	
	if (strlen(tbox) > 0)
		tbox = tbox[1,inf] // remove carriage return at beginning
		Label /W=$gName bottom StrVarOrDefault("WavePrefix", "Wave")
		TextBox /E/C/N=text0/A=MT/W=$gName tbox
		
		if (numWaves > 0)
			SetAxis /W=$gName bottom 0,(min(numWaves,10))
		endif
	
	endif
	
	if (tau == 1)
	
		Label /W=$gName2 tau StrVarOrDefault("xLabel", "msec")
		
	elseif (tau == 2)
	
		ModifyGraph /W=$gName2 mode=4, msize=4, standoff=0
		
		if (strlen(tbox2) > 0)
			tbox2 = tbox2[1,inf] // remove carriage return at beginning
			Label /W=$gName2 bottom StrVarOrDefault("WavePrefix", "Wave")
			Label /W=$gName2 left StrVarOrDefault("xLabel", "msec")
			TextBox /E/C/N=text0/A=MT/W=$gName2 tbox2
			
			if (numWaves > 0)
				SetAxis /W=$gName bottom 0,(min(numWaves,10))
			endif
			
		else
		
			TextBox /K/W=$gName2
		
		endif
		
	endif

End // ClampStatsDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplayUpdate(currentWave, numwaves) // resize stats display x-scale
	Variable currentWave
	Variable numwaves
	
	Variable inc = 10
	Variable num = inc * (1 + floor(currentWave / inc))
	
	num = min(numwaves, num)

	if (WinType("ClampStatsAmp") == 1)
		SetAxis /Z/W=ClampStatsAmp bottom 0, num
	endif
	
	if (WinType("ClampStatsTau") == 1)
		SetAxis /Z/W=ClampStatsTau bottom 0, num
	endif
	
End // ClampStatsDisplayUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsRemoveWaves(kill)
	Variable kill // (0) dont kill waves (1) kill waves
	
	Variable icnt
	String wname
	
	if (WinType("ClampStatsAmp") == 1)
	
		String wlist = WaveList("*", ";", "WIN:ClampStatsAmp")
		
		for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
			wname = StringFromList(icnt, wlist)
			RemoveFromGraph /Z/W=ClampStatsAmp $wname
		endfor
		
	endif
	
	if (WinType("ClampStatsTau") == 1)
	
		wlist = WaveList("*", ";", "WIN:ClampStatsTau")
		
		for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
			wname = StringFromList(icnt, wlist)
			RemoveFromGraph /Z/W=ClampStatsTau $wname
		endfor
		
	endif
	
	if (kill == 1)
		KillGlobals("", "ST_*", "001") // kill Stats waves in current folder
	endif

End // ClampStatsRemoveWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsMarker(select)
	Variable select

	switch(select)
		case 0:
			return 8
		case 1:
			return 6
		case 2:
			return 5
		case 3:
			return 2
		case 4:
			return 22
		case 5:
			return 4
		default:
			return 0
	endswitch

End // ClampStatsMarker

//****************************************************************
//****************************************************************
//****************************************************************
//
//
//	Folder functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderNewCell()
	String cdf = ClampDF()

	Variable cell = ClampDataFolderCell()
	
	if (numtype(cell) > 0)
		return 0
	endif
	
	NotesCopyVars(LogDF(),"H_") // update header Notes
	NotesCopyFolder(LogDF()+"Final_Notes") 
	LogSave() // save any remaining log notes
	
	ClampDataFolderSeqReset()
	SetNMvar(cdf+"DataFileCell", cell+1)
	SetNMvar(cdf+"LogFileSeq", -1) // reset log file counter
	
End // ClampDataFolderNewCell

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderCell()

	return NumVarOrDefault(ClampDF()+"DataFileCell", NMCountFrom())

End // ClampDataFolderCell

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderSeq()

	return NumVarOrDefault(ClampDF()+"DataFileSeq", NMCountFrom())

End // ClampDataFolderSeq

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderSeqReset()
	String cdf = ClampDF()
	
	if (NumVarOrDefault(cdf+"SeqAutoZero", 1) == 1)
		SetNMvar(cdf+"DataFileSeq", 0)
	endif

End // ClampDataFolderSeqReset

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampDataFolderPrefix()

	return StrVarOrDefault(ClampDF()+"FolderPrefix", ClampDateName())

End // ClampDataFolderPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampDataFolderName(next)
	Variable next // (0) this data folder name (1) next data folder name
	
	Variable icnt
	String fname = "", suffix = ""
	
	String cdf = ClampDF()
	
	String clampPrefix = ClampDateName()
	String userPrefix = StrVarOrDefault(cdf+"UserFolderPrefix", "")
	String prefix = StrVarOrDefault(cdf+"FolderPrefix", clampPrefix)
	String stimtag = StrVarOrDefault(cdf+"StimTag", "")
	
	Variable first = NMCountFrom()
	Variable cell = ClampDataFolderCell()
	Variable seq = ClampDataFolderSeq()
	
	if ((strlen(userPrefix) == 0) && (StringMatch(prefix, clampPrefix) == 0))
		SetNMstr(cdf+"FolderPrefix", clampPrefix)
		prefix = clampPrefix
	endif
	
	if (numtype(seq) > 0)
		seq = 0
	endif
	
	if (numtype(str2num(prefix[0,0])) == 0)
		prefix = "f" + prefix
	endif
	
	if (numtype(cell) == 0)
		prefix += "c" + num2str(cell)
	endif
	
	for (icnt = seq; icnt <= 999; icnt += 1)

		suffix = "_"
	
		if (icnt < 10)
			suffix += "00"
		elseif (icnt < 100)
			suffix += "0"
		endif
		
		fname = prefix + suffix + num2str(icnt)
		
		if (ClampSaveTestStr(fname) == -1)
			continue // ext file already exists
		endif
		
		if (strlen(stimtag) > 0)
			fname += "_" + stimtag
		endif
		
		if (ClampSaveTest(fname) == -1) // final check
			continue // ext file already exists
		endif
		
		if (next == 0)
			break // found OK current folder name
		elseif (next == 1)
			if (IsNMDataFolder(fname) == 0)
				break // found OK next folder name
			endif
		endif
		
	endfor
	
	SetNMVar(cdf+"DataFileSeq", icnt) // set new seq num
	
	return fname

End // ClampDataFolderName

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderCheck()
	String cdf = ClampDF()
	
	String prefix = StrVarOrDefault(cdf+"FolderPrefix", ClampDateName())
	
	String CurrentFolder = StrVarOrDefault(cdf+"CurrentFolder", "")
	String fname = ClampDataFolderName(0)
	
	if (strlen(CurrentFolder) == 0) // no data folders yet
		CurrentFolder = GetDataFolder(0)
	endif

	if ((StringMatch(CurrentFolder, GetDataFolder(0)) == 0) && (IsNMDataFolder(CurrentFolder) == 1))
		NMFolderChange(CurrentFolder) // data folder has changed, move back to current folder
	endif
	
	String thisFolder = GetDataFolder(0)
	String currentFile = StrVarOrDefault("CurrentFile", "")
	
	Variable nwaves = NumVarOrDefault("NumWaves", 0)
	Variable lastMode = NumVarOrDefault("CT_Record", 0)
	
	if (IsNMDataFolder(thisFolder) == 1)
	
		if (StringMatch(fname, thisFolder) == 1)
		
			if ((lastMode == 0) && (strlen(currentFile) == 0))
				return 0
			endif
			
		else
		
			if ((nwaves == 0) && (strlen(currentFile) == 0))
			
				thisFolder = NMFolderRename(thisFolder, fname)
				
				if (strlen(thisFolder) > 0)
					SetNMVar(cdf+"GetChanConfigs", 1)
					return 0
				endif
				
			endif
		endif
		
	endif
	
	return ClampDataFolderNew() // make new folder

End // ClampDataFolderCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderNew() // create a new data folder
	String cdf = ClampDF()

	String newfolder = ClampDataFolderName(1) // folder name
	String oldfolder = StrVarOrDefault(cdf+"CurrentFolder", "")
	String extfile = StrVarOrDefault("CurrentFile", "")
	
	Variable autoClose = NumVarOrDefault(cdf+"AutoCloseFolder", 0)
	Variable saveWhen = NumVarOrDefault(cdf+"SaveWhen", 0)
	
	if ((autoClose == 1) && (SaveWhen > 0) && (IsNMDataFolder(oldfolder) == 1) && (strlen(extfile) > 0))
		SetNMvar(NMDF()+"ChanGraphCloseBlock", 1) // block closing chan graphs
		ClampGraphsUpdate(0)
		ClampStatsRemoveWaves(0)
		SetNMvar(NMDF()+"ChanGraphCloseBlock", 1) // block closing chan graphs
		NMFolderClose(oldfolder) // close current folder before opening new one
		ClampDataFolderCloseEmpty()
	endif
	
	SetNMvar(NMDF()+"UpdateNMBlock", 1) // block update
	SetNMvar(NMDF()+"ChanGraphCloseBlock", 1) // block closing chan graphs
	newfolder = NMFolderNew(newfolder) // create a new folder
	SetNMvar(NMDF()+"UpdateNMBlock", 0) // unblock
	
	CheckNMwave("CT_TimeStamp", 0, Nan)
	CheckNMwave("CT_TimeIntvl", 0, Nan)
	
	if (strlen(newfolder) == 0)
		return -1
	endif
	
	SetNMstr(cdf+"CurrentFolder", newfolder)
	
	SetNMVar(cdf+"GetChanConfigs", 1) // get chan graph configs
	
End // ClampDataFolderNew

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderCloseEmpty()
	Variable icnt, nwaves, match
	String extfile, cdf = ClampDF()
	
	String prefix = StrVarOrDefault(cdf+"FolderPrefix", ClampDateName())
	
	String fname, flist = NMDataFolderList()
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
	
		fname = StringFromList(icnt, flist)
		
		nwaves = NumVarOrDefault("root:" + fname + ":NumWaves", 0)
		extfile = StrVarOrDefault("root:" + fname + ":CurrentFile", "")
		match = strsearch(UpperStr(fname), UpperStr(prefix), 0)
		
		if ((match >= 0) && (nwaves == 0) && (strlen(extfile) == 0))
			NMFolderClose(fname)
		endif
		
	endfor

End // ClampDataFolderCloseEmpty

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDataFolderUpdate(nwaves, mode)
	Variable nwaves
	Variable mode // (0) preview (1) record
	
	Variable config, icnt, npnts
	String wlist, item
	
	String cdf = ClampDF(), sdf = StimDF(), ndf = NotesDF(), gdf = cdf+"Temp:"

	Variable CopyStim2Folder = NumVarOrDefault(cdf+"CopyStim2Folder", 1)
	String CurrentStim = StimCurrent()
	
	NVAR NumChannels, NumWaves

	Wave ADCon = $(sdf+"ADCon")
	Wave ADCmode = $(sdf+"ADCmode")
	Wave /T ADCname = $(sdf+"ADCname")
	Wave /T ADCunits = $(sdf+"ADCunits")
	
	Wave /T yLabel
	
	Variable nchans = StimNumChannels(sdf)
	
	Redimension /N=(nchans) yLabel
	
	npnts = numpnts(ADCon)
	
	for (config = 0; config < npnts; config += 1)
		if ((ADCon[config] == 1) && (ADCmode[config] <= 0))
			yLabel[icnt] = ADCname[config] + " (" + ADCunits[config] + ")"
			icnt += 1
		endif
	endfor
	
	String wPrefix = StimWavePrefix()

	SetNMVar("NumChannels", icnt)
	SetNMVar("NumWaves", nwaves)
	SetNMVar("TotalNumWaves", icnt*nwaves)
	SetNMVar("FileDateTime", DateTime)
	SetNMstr(cdf+"CurrentFolder", GetDataFolder(0))
	SetNMVar("SamplesPerWave", NumVarOrDefault(sdf+"SamplesPerWave", 0))
	SetNMVar("SampleInterval", NumVarOrDefault(sdf+"SampleInterval", 0))
	SetNMvar("NumGrps", NumVarOrDefault(sdf+"NumStimWaves", 1))
	SetNMvar ("FirstGrp", NMGroupFirstDefault())
	SetNMvar("CT_Record", mode)

	SetNMstr("WavePrefix", wPrefix)
	SetNMstr("CurrentPrefix", wPrefix)
	SetNMstr("FileDate", date())
	SetNMstr("FileTime", time())
	SetNMstr("FileName", GetDataFolder(0))
	
	switch(NumVarOrDefault(sdf+"AcqMode", 0))
		case 0:
			SetNMstr("AcqMode", "episodic")
			break
		case 1:
			SetNMstr("AcqMode", "continuous")
			break
		default:
			SetNMstr("AcqMode", "")
			break
	endswitch
	
	CheckNMwave("CT_TimeStamp", nwaves, Nan) // waves to save acquisition times
	CheckNMwave("CT_TimeIntvl", nwaves, Nan)
	
	SetNMwave("CT_TimeStamp", -1, Nan)
	SetNMwave("CT_TimeIntvl", -1, Nan)
	
	CheckNMDataFolderWaves() // redimension NM waves
	
	if ((mode == 1) && (copyStim2Folder == 1))
	
		if (DataFolderExists(CurrentStim) == 1)
			KillDataFolder $CurrentStim
		endif
		
		if (DataFolderExists(gdf) == 1)
			KillDataFolder $(gdf) // shouldnt exist yet
		endif
		
		StimWavesMove(sdf, gdf)
		
		DuplicateDataFolder $sdf, $CurrentStim // save copy of stim protocol folder
		
		if (DataFolderExists(gdf) == 1)
			StimWavesMove(gdf, sdf)
			KillDataFolder $(gdf)
		endif
		
	endif
	
	wlist = WaveList(wPrefix+"*",";","")
	
	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
		KillWaves /Z $(StringFromList(icnt, wlist)) // kill existing input waves
	endfor
	
	if (StimStatsOn() == 0)
		ClampStatsRemoveWaves(1)
	endif

End // ClampDataFolderUpdate

//****************************************************************
//****************************************************************
//****************************************************************
//
//
//	Save folder functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampSaveSubPath()

	String subStr, cdf = ClampDF()
	String ClampPathStr = StrVarOrDefault(cdf+"ClampPath", "")
	String prefix = StrVarOrDefault(cdf+"FolderPrefix", "")
	
	Variable saveSub = NumVarOrDefault(cdf+"SaveInSubfolder", 1)
	Variable cell = NumVarOrDefault(cdf+"DataFileCell", Nan)
	
	if ((saveSub == 0) || (strlen(ClampPathStr) == 0))
		return ""
	endif
	
	if (numtype(cell) == 0)
		prefix += "c" + num2str(cell)
	endif
	
	if ((strlen(ClampPathStr) > 0) && (strlen(prefix) > 0))
		subStr = ClampPathStr + prefix + ":"
		NewPath /C/Z/O ClampSubPath subStr
		if (V_flag != 0)
			DoAlert 0, "Failed to create external path to: " + subStr
			SetNMstr(cdf+"ClampSubPath", "")
		else
			SetNMstr(cdf+"ClampSubPath", subStr)
		endif
	endif
	
	return subStr

End // ClampSaveSubPath

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampSavePathGet()

	String cdf = ClampDF()
	
	if (NumVarOrDefault(cdf+"SaveInSubfolder", 1) == 1)
		return "ClampSubPath"
	else
		return "ClampPath"
	endif

End // ClampSavePathGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampSavePathStr()

	String cdf = ClampDF()
	String path = ""
	
	if (NumVarOrDefault(cdf+"SaveInSubfolder", 1) == 1)
		path = StrVarOrDefault(cdf+"ClampSubPath", "")
	endif
	
	if (strlen(path) == 0)
		path = StrVarOrDefault(cdf+"ClampPath", "")
	endif
	
	return path

End // ClampSavePathStr

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSaveBegin() // NM binary format only

	String path, cdf = ClampDF(), sdf = StimDF()

	Variable saveWhen = NumVarOrDefault(cdf+"SaveWhen", 0)
	Variable numStimWaves = NumVarOrDefault(sdf+"NumStimWaves", 0)
	Variable numStimReps = NumVarOrDefault(sdf+"NumStimReps", 0)
	Variable ask = NumVarOrDefault(cdf+"SaveWithDialogue", 1)
	
	if (saveWhen == 2) // begin save while recording
		ClampDataFolderUpdate(NumStimWaves * NumStimReps, 1)
		KillWaves /Z CT_TimeStamp, CT_TimeIntvl
		FileBinSave(ask, 1, "", ClampSavePathGet(), "", 0, 0) // NM_FileManager.ipf
		Make /O/N=(NumStimWaves * NumStimReps) CT_TimeStamp, CT_TimeIntvl
	endif
	
	return 0

End // ClampSaveBegin

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSaveFinish()

	String file, cdf = ClampDF()
	String path = ClampSavePathGet()
	
	Variable saveFormat = NumVarOrDefault(cdf+"SaveFormat", 1)
	Variable saveWhen = NumVarOrDefault(cdf+"SaveWhen", 0)
	Variable ask = NumVarOrDefault(cdf+"SaveWithDialogue", 1)

	if ((SaveFormat == 1) || (SaveFormat == 3)) // NM binary
	
		if (saveWhen == 1) // save after recording (Igor 4)
		
			file = FileBinSave(ask, 1, "", path, "", 1, 0) // NM_FileManager.ipf
			
		elseif (saveWhen == 2) // save while recording (Igor 4 and 5)
		
			file = ClampNMbinAppend("CT_TimeStamp") // append
			file = ClampNMbinAppend("CT_TimeIntvl") // append
			file = ClampNMbinAppend("close file") // close file
			ask = 0
			
		endif
		
	endif
	
	if ((SaveFormat == 2) || (SaveFormat == 3)) // Igor binary
		file = FileBinSave(ask, 1, "", path, "", 1, 1) // NM_FileManager.ipf
	endif
	
	path = GetPathName(file, 1)
	
	PathInfo /S ClampPath
	
	if (strlen(S_path) > 0)
		SetNMStr(cdf+"ClampPath", S_path)
	elseif ((strlen(file) > 0) && (strlen(path) > 0))
		SetNMStr(cdf+"ClampPath", path)
		NewPath /Z/Q/O ClampPath path
	endif
	
	if (strlen(file) == 0)
		SetNMstr("CurrentFile", "not saved")
	endif

End // ClampSaveFinish

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSaveTest(folderName)
	String folderName
	
	String cdf = ClampDF()
	String file = FolderNameCreate(folderName)
	
	String path = ClampSavePathStr()
	
	if ((strlen(path) == 0) || (strlen(file) == 0))
		return -1
	endif
	
	if (FileBinType() == 1)
		file = FileExtCheck(file, ".pxp", 1) // force this ext
	else
		file = FileExtCheck(file, ".nmb", 1) // force this ext
	endif
	
	file = path + file
	
	if (FileExists(file) == 1)
		return -1
	endif
	
	return 0

End // ClampSaveTest

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSaveTestStr(folderName)
	String folderName
	
	Variable icnt
	String file, slist = "", cdf = ClampDF()
	
	PathInfo /S ClampPath
	
	if (strlen(S_path) == 0)
		return 0
	endif
	
	if (NumVarOrDefault(cdf+"SaveInSubfolder", 1) == 1)
		PathInfo /S ClampSubPath
		if (strlen(S_path) > 0)
			slist = IndexedFile(ClampSubPath,-1,"????")
		endif
	endif
	
	if (strlen(slist) == 0)
		slist = IndexedFile(ClampPath,-1,"????")
	endif
	
	for (icnt = 0; icnt < ItemsInList(slist); icnt += 1)
	
		file = StringFromList(icnt, slist)
		
		if (StrSearchLax(file, folderName, 0) >= 0)
			return -1 // already exists
		endif
		
	endfor
	
	return 0

End // ClampSaveTestStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampNMbinAppend(oname) // NM binary format only
	String oname // object name (or "close file")
	
	String cdf = ClampDF()
	String file = StrVarOrDefault("CurrentFile", "")
	
	if ((strlen(file) == 0) || (NumVarOrDefault(cdf+"SaveWhen", 0) != 2))
		return ""
	endif
	
	strswitch(oname)
		case "close file":
			NMbinWriteObject(file, 3, "") // close object file
			break
		default:
			NMbinWriteObject(file, 2, oname) // append object to file
	endswitch
	
	return file

End // ClampNMbinAppend

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Log Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogDF() // return full-path name of Log folder

	return "root:" + LogFolderName() +  ":"
	
End // LogDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogFolderName()
	Variable icnt, ibgn = NMCountFrom(), iend = 99

	String fname, cdf = ClampDF()
	
	Variable seq = NumVarOrDefault(cdf+"LogFileSeq", -1)
	Variable cell = ClampDataFolderCell()
	
	String prefix = ClampDataFolderPrefix()
	
	if (numtype(cell) == 0)
		prefix += "c" + num2str(cell)
	endif

	if (seq >= 0)
		return prefix + "_log" + num2str(seq)
	endif
	
	for (icnt = ibgn; icnt <= iend; icnt += 1)
	
		fname = prefix + "_log" + num2str(icnt)

		if (ClampSaveTest(fname) == 0)
			break
		endif
	
	endfor
	
	SetNMvar(cdf+"LogFileSeq", icnt)
	
	return fname

End // LogFolderName

//****************************************************************
//****************************************************************
//****************************************************************

Function LogDisplay2(ldf, select)
	String ldf // log data folder
	Variable select // (1) notebook (2) table (3) both

	if ((select == 1) || (select == 3))
		LogNoteBookUpdate(ldf)
	endif
	
	if ((select == 2) || (select == 3))
		LogTable(ldf)
	endif
	
End // LogDisplay2

//****************************************************************
//****************************************************************
//****************************************************************

Function LogNoteBookUpdate(ldf) // update existing notebook
	String ldf // log data folder
	
	ldf = LastPathColon(ldf,1)
	
	String nbName = GetPathName(ldf,0) + "_notebook"
	
	if (DataFolderExists(ldf) == 0)
		DoAlert 0, "Error: data folder \"" + ldf + "\" does not appear to exist."
		return -1
	endif
	
	if (StringMatch(StrVarOrDefault(ldf+"FileType", ""), "NMLog") == 0)
		DoAlert 0, "Error: data folder \"" + ldf + "\" does not appear to be a NeuroMatic Log folder."
		return -1
	endif
	
	if (WinType(nbName) == 5)
		LogNoteBookFileVars(PackDF("Notes"), nbName)
	else
		LogNoteBook(ldf)
	endif
	
End // LogNoteBookUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function LogSave()
	
	String ldf = LogDF() // log data folder
	String path = ClampSavePathGet()

	if (StringMatch(StrVarOrDefault(ldf+"FileType", ""), "NMLog") == 0)
		//ClampError(ldf + " is not a NeuroMatic Log folder.")
		return -1
	endif
	
	if (strlen(StrVarOrDefault(ldf+"CurrentFile", "")) > 0)
		FileBinSave(0, 0, ldf, path, "", 1, -1) // replace file
	else
		FileBinSave(0, 1, ldf, path, "", 1, -1) // new file
	endif

End // LogSave

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampExitHook()

	String board = StrVarOrDefault(ClampDF()+"AcqBoard","")
	
	DoAlert 0, "Clamp Exit"
	
	strswitch(board) // Reset boards
		case "ITC16":
		case "ITC18":
			Execute /Z "ITCconfig(\"" + board + "\")" 
			break
		case "NIDAQ":
			Execute /Z "NidaqResetHard()"
			break
	endswitch

End // ClampExitHook

//****************************************************************
//****************************************************************
//****************************************************************










