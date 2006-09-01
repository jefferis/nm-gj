#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic MyTab Demo Tab
//	To be run with NeuroMatic, v1.91
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 30 Nov 2004
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S CamTabPrefix(varName) // tab prefix identifier
	String varName
	
	return "CAM_" + varName
	
End // CamTabPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CamTabDF() // package full-path folder name

	return PackDF("CamTab")
	
End // CamTabDF

//****************************************************************
//****************************************************************
//****************************************************************

Function CamTab(enable)
	Variable enable // (0) disable (1) enable tab
	
	if (enable == 1)
		CheckPackage("CamTab", 0) // declare globals if necessary
		MakeCamTab() // create tab controls if necessary
		AutoCamTab()
	endif

End // CamTab

//****************************************************************
//****************************************************************
//****************************************************************

Function AutoCamTab()

// put a function here that runs each time CurrentWave number has been incremented 
// see "AutoSpike" for example

End // AutoCamTab

//****************************************************************
//****************************************************************
//****************************************************************

Function KillCamTab(what)
	String what
	String df = CamTabDF()

	// TabManager will automatically kill objects that begin with appropriate prefix
	// place any other things to kill here.
	
	strswitch(what)
	
		case "waves":
			// kill any other waves here
			break
			
		case "folder":
			if (DataFolderExists(df) == 1)
				KillDataFolder $df
			endif
			break
			
	endswitch

End // KillCamTab

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckCamTab() // declare global variables

	String df = CamTabDF()
	
	if (DataFolderExists(df) == 0)
		return -1 // folder doesnt exist
	endif
	
	CheckNMvar(df+"Gain", 0) // create variable (also see Configurations.ipf)
	
	CheckNMstr(df+"MyStr", "Anything") // create string
	
	CheckNMwave(df+"MyWave", 5, 22) // numeric wave
	
	CheckNMtwave(df+"MyText", 5, "Anything") // text wave
	
	return 0
	
End // CheckCamTab
	
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeCamTab() // create controls that will begin with appropriate prefix

	Variable x0 = 60, y0 = 200, xinc, yinc = 30
	
	String df = CamTabDF()

	ControlInfo /W=NMPanel $CamTabPrefix("Function0") // check first in a list of controls
	
	if (V_Flag != 0)
		return 0 // tab controls exist, return here
	endif

	DoWindow /F NMPanel
	
	Button $CamTabPrefix("Init"), pos={x0,y0+0*yinc}, title="Initialise Communication", size={200,20}, proc=CamTabButton
	Button $CamTabPrefix("CamModeRemote"), pos={x0,y0+1*yinc}, title="Computer Camera Control", size={200,20}, proc=CamTabButton
	Button $CamTabPrefix("CamModeJumper"), pos={x0,y0+2*yinc}, title="Jumper Camera Control", size={200,20}, proc=CamTabButton
	//Button $CamTabPrefix("Function2"), pos={x0,y0+3*yinc}, title="My Function 2", size={200,20}, proc=CamTabButton
	
	PopupMenu $CamTabPrefix("GainMode"), pos={x0+80,y0+4*yinc}, size={0,0}, bodyWidth=100, fsize=14, proc=CamTabPopup
// 000 : 0 dB (AGC OFF)	001 : +6dB	002 : AGC ON	004 : Manual by m_gain
	PopupMenu $CamTabPrefix("GainMode"), value="0 dB (AGC OFF);+6dB;AGC ON;---;Manual;"
	SetVariable $CamTabPrefix("GainValue"), title="Gain (dB)", pos={x0+100,y0+4*yinc}, size={100,50}, limits={0,24,1}
	SetVariable $CamTabPrefix("GainValue"), value=$(df+"Gain"), proc=CamTabSetVariable

	PopupMenu $CamTabPrefix("ShutterMode"), pos={x0+60,y0+5*yinc}, size={0,0}, bodyWidth=80, fsize=10, proc=CamTabPopup
//000 : ES OFF	001 : FL	002 : E..IRIS ON	004 : Manual by m_es
	PopupMenu $CamTabPrefix("ShutterMode"), value="ES OFF;FL;E IRIS ON;---;Manual;"
	
	PopupMenu $CamTabPrefix("ShutterSpeed"), pos={x0+200,y0+5*yinc}, size={0,0}, bodyWidth=80, fsize=14, proc=CamTabPopup
	PopupMenu $CamTabPrefix("ShutterSpeed"), fsize=14,title="Shutter",value="50;120;250;500;1000;2000;4000;10000;20000;30000"

End // MakeCamTab

//****************************************************************
//****************************************************************
//****************************************************************
Function CamTabPopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	//PopupMenu $ctrlName, win=NMpanel, mode=1 // force menus back to title
	String fxn = NMCtrlName(CamTabPrefix(""), ctrlName)
	if (cmpstr(popStr, "---")==0)
		// deal with dividers
		popNum=0
	endif

	CamTabCall(fxn,num2str(popNum))	
	//NMMainCall(popStr)
			
End // MainTabPopup


Function CamTabButton(ctrlName) : ButtonControl
	String ctrlName
	
	String fxn = NMCtrlName(CamTabPrefix(""), ctrlName)
	
	CamTabCall(fxn, "")
	
End // CamTabButton

//****************************************************************
//****************************************************************
//****************************************************************

Function CamTabSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String fxn = NMCtrlName(CamTabPrefix(""), ctrlName)
	
	CamTabCall(fxn, varStr)
	
End // CamTabSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function CamTabCall(fxn, select)
	String fxn // function name
	String select // parameter string variable
	
	Variable snum = str2num(select) // parameter variable number
	
	strswitch(fxn)
	
		case "CamModeJumper":
//			return NMMainLoop() // see NM_MainTab.ipf
			return CamSetMode(0)
	
		case "CamModeRemote":
			return CamSetMode(1)
			
		case "Init":
			return CamCommInit()
		
		case "GainMode":
			return CamSetGenericAddress(1,snum-1,0,4)

		case "GainValue":
			return CamSetGenericAddress(7,snum*10,0,240)
			
		case "ShutterMode":
			return CamSetGenericAddress(2,snum-1,0,4)

		case "ShutterSpeed":
			CamSetShutterSpeed(snum)
			
		case "Function2":
			return CamFunction2()
			
		case "Function3":
			return CamFunction3(select)

	endswitch
	
End // CamTabCall

//****************************************************************
//****************************************************************
//****************************************************************
Function CamSetShutterSpeed(mode)
	Variable mode
	Variable speedVal
	print mode

	switch(mode)	// numeric switch
		case 1:		// 50
			speedVal=0
			break						// exit from switch
		case 2:		// 50
			speedVal=35
			break						// exit from switch
		case 3:		// 50
			speedVal=64
			break						// exit from switch
		case 4:		// 50
			speedVal=92
			break						// exit from switch
		case 5:		// 50
			speedVal=119
			break						// exit from switch
		case 6:		// 50
			speedVal=147
			break						// exit from switch
		case 7:		// 50
			speedVal=175
			break						// exit from switch
		case 8:		// 50
			speedVal=211
			break						// exit from switch
		case 9:		// 50
			speedVal=239
			break						// exit from switch
		case 10:		// 50
			speedVal=255
			break						// exit from switch
		default:							// optional default expression executed
			print "Unknown shutter speed"					// when no case matches
	endswitch
	CamSetGenericAddress(8,speedVal,0,255)
	
End // CamSetGainMode

Function CamSetGenericAddress(address,value,minval,maxval)
	Variable address // a 0 padded 3-string 
	Variable value,minval, maxval

	// Check we have a valid mode
	if (value<minval  || value>maxval)
		printf "Bad value %d",value
	endif

	String vdtstr
	sprintf vdtstr, "000000W%03.f%03.f" ,address,value
	VDTWrite2 vdtstr+"\r"
	print vdtstr
End // CamSetGenericAddress


Function CamSetMode(mode)
	Variable mode
	
	// Check we have a valid mode
	if (mode<0  || mode>3)
		return (-1)
	endif

	VDTWrite2 "000000W00000"+num2str(mode)+"\r"
	
//	String df = CamTabDF()
//
//	DoAlert 0, "Your macro can be run here."
//	
//	NVAR MyVar = $(df+"MyVar")
//	SVAR MyStr = $(df+"MyStr")
//	
//	Wave MyWave = $(df+"MyWave")
//	Wave /T MyText = $(df+"MyText")

End // CamFunction0

//****************************************************************
//****************************************************************
//****************************************************************

Function CamCommInit()

	Print "CamCommInit"
	VDTOperationsPort2 'Modem'
	// Set communications parameters
	VDT2 baud=9600 , stopbits=1,databits=8, parity=0, in=0, out=0
	VDTWrite2 "000000W000001\r"

End // CamFunction1

//****************************************************************
//****************************************************************
//****************************************************************

Function CamFunction2()

	Print "My Function 2"

End // CamFunction2

//****************************************************************
//****************************************************************
//****************************************************************

Function CamFunction3(select)
	String select

	Print "You entered : " + select

End // CamFunction3

//****************************************************************
//****************************************************************
//****************************************************************
