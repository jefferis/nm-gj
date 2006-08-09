#pragma rtGlobals = 1
#pragma IgorVersion = 4
#pragma version = 1.86

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic Main Menu Functions
//	To be run with NeuroMatic, v1.86
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro 4
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Began 5 May 2002
//	Last Modified 25 Nov 2004
//
//****************************************************************
//****************************************************************
//****************************************************************

Menu "NeuroMatic", dynamic // define main NeuroMatic drop-down menu

	Submenu "Data Folder"
		"New", NMFolderCall("New")
		"Open", NMFolderCall("Open")
		"Open | Append", NMFolderCall("Append")
		"Save", NMFolderCall("Save")
		"Kill", NMFolderCall("Kill")
		"Duplicate", NMFolderCall("Duplicate")
		"Rename", NMFolderCall("Rename")
		"Change", NMFolderCall("Change")
		"Merge", NMFolderCall("Merge")
		"Convert", NMFileCall("Convert")
		"-"
		"Open All", NMFolderCall("Open All")
		"Save All", NMFolderCall("Save All")
		"Kill All", NMFolderCall("Kill All")
	End
	
	Submenu "Stim Folder"
		NMStimMenu(), SubStimCall("Details")
		"-"
		"Pulse Table", SubStimCall("Pulse Table")
		"ADC Table", SubStimCall("ADC Table")
		"DAC Table", SubStimCall("DAC Table")
		"TTL Table", SubStimCall("TTL Table")
		"Stim Waves", SubStimCall("Stim Waves")
	End
	
	Submenu "Import Waves"
		"Axograph", NMFileCall("Axograph")
		"Pclamp", NMFileCall("Pclamp")
	End

	"Reload Waves", NMFileCall("Reload Waves")
	"Rename Waves", NMFolderCall("Rename Waves")
	"Set Open Path", NMFolderCall("Open Path")
	"Set Save Path", NMFolderCall("Save Path")
	
	"-"
	
	Submenu "Configs"
		"Edit", NMConfigCall("Edit")
		"Open", NMConfigCall("Open")
		"Save", NMConfigCall("Save")
		"Kill", NMConfigCall("Kill")
	End
	
	Submenu "Tabs"
		"Add", NMCall("Add Tab")
		"Remove", NMCall("Remove Tab")
		"Kill", NMCall("Kill Tab")
	End
	
	Submenu "Analysis"
		"Stability | Stationarity", NMCall("Stability")
		"Significant Difference", NMCall("KSTest")
	End
	
	"-"
	
	"Make Main Panel", NMCall("Panel")
	"Set Progress Position", NMCall("Progress XY")
	"Screen Size", NMCall("Computer")
	"Reset Cascade", NMCall("Reset Cascade")
	"Chan Graphs On", NMCall("Graphs On")
	"Update NeuroMatic", NMCall("Update")
	
	AboutNM()
	
	"-"
	
	Submenu "Main Hot Keys"
		"Next Wave/0", NMCall("Next")
		"Previous Wave/9", NMCall("Last")
		NMSetsDisplayName(0) + " Checkbox/1", NMCall("Set1 Toggle")
		NMSetsDisplayName(1) +" Checkbox/2", NMCall("Set2 Toggle")
		NMSetsDisplayName(2) +" Checkbox/3", NMCall("SetX Toggle")
	End

End // NeuroMatic Menu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S AboutNM() // executes every time NM menu is accessed

	CheckNM(0)
	CheckNMversion()
	
	return ""
	//return "About NeuroMatic"
	
End // AboutNM

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimMenu()

	String df = SubStimName("")
	
	if (strlen(df) == 0)
		return "No Stim"
	else
		return SubStimName("")
	endif

End // NMStimMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMQuickLoadMenu()

	Variable flag = NumVarOrDefault(NMDF() + "FastLoad", 0)
	
	if (flag == 0)
		return "Quick Load" // unchecked
	else	
		return "!" +  num2char(18) + "Quick Load" // checked
	endif

End // NMQuickLoadMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMAutoPlotMenu()

	Variable flag = NumVarOrDefault(NMDF() + "AutoPlot", 0)
	
	if (flag == 0)
		return "Auto Plot" // unchecked
	else	
		return "!" +  num2char(18) + "Auto Plot" // checked
	endif

End // NMAutoPlotMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMProgressMenu() // return appropriate Progress menu item

	Variable progflag = NumVarOrDefault(NMDF() + "ProgFlag", 1)
	
	if (progflag == 1)
		return "!" +  num2char(18) + "ProgWin On" // checked
	else	
		return "ProgWin On" // unchecked
	endif

End // NMProgressMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNameFormatMenu() // return appropriate quick load menu item

	Variable flag = NumVarOrDefault(NMDF() + "NameFormat", 0)
	
	if (flag == 0)
		return "Long Name Format" // unchecked
	else	
		return "!" +  num2char(18) + "Long Name Format" // checked
	endif

End // NMNameFormatMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMCmdHistoryMenu()
	String df = NMDF()

	Variable flag = NumVarOrDefault(df+"CmdHistory", 0)
	
	if (flag == 0)
		return "Command History" // unchecked
	else	
		return "!" +  num2char(18) + "Command History" // checked
	endif

End // NMCmdHistoryMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMHistoryMenu()

	Variable flag = NumVarOrDefault(NMDF() + "WriteHistory", 0)
	
	if (flag == 0)
		return "Results History" // unchecked
	else	
		return "!" +  num2char(18) + "Results History" // checked
	endif

End // NMHistoryMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCall(fxn)
	String fxn
	
	String setList = NMSetsDisplayList()
	
	strswitch(fxn)
			
		case "Stability":
		case "Stationarity":
			Execute "NMStabilityCall0()"
			return 0
		
		case "KSTest":
			Execute "KSTestCall()" // NM_Kolmogorov.ipf
			return 0
	
		case "Name Format":
			return NMNameFormatToggle()
	
		case "Update":
			return ResetNMCall()
	
		case "Add Tab":
			return NMTabAddCall()
			
		case "Remove Tab":
			return NMTabRemoveCall()
			
		case "Kill Tab":
			return NMTabKillCall()
	
		case "Progress":
			return NMProgressToggle()
			
		case "Progress XY":
			return NMProgressXYPanel()
	
		case "History":
			return NMHistoryCall()
			
		case "CmdHistory":
			return NMCmdHistoryCall()
			
		case "Panel":
		case "Main Panel":
		case "Make Main Panel":
			return MakeNMpanelCall()
			
		case "Graphs On":
			return ChanOnAllCall()
			
		case "Computer":
		case "Computer Stats":
			return NMComputerCall(1)
			
		case "Reset Cascade":
		case "Reset Window Cascade":
		case "ResetCascade":
			return ResetCascadeCall()
			
		case "Next":
			return NMNextWaveCall(+1)
			
		case "Last":
			return NMNextWaveCall(-1)
			
		case "Set1 Toggle":
			return NMSetsToggleCall(StringFromList(0, setList))
			
		case "Set2 Toggle":
			return NMSetsToggleCall(StringFromList(1, setList))
			
		case "SetX Toggle":
			return NMSetsToggleCall(StringFromList(2, setList))
	
	endswitch
	
	return -1

End // NMCall

//****************************************************************
//****************************************************************
//****************************************************************