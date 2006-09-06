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
	
	// Initialise serial communication
	// In the end it seems to be possible to hang terribly easily with the serial port write 
	//CamCommInit() // create variable (also see Configurations.ipf)	

	// Set camera control mode to remote (ie Computer) rather than jumper
	// do this by default since this is the whole point of this tab!
	CamSetMode(1)
	CheckNMvar(df+"Gain", 0) // create variable (also see Configurations.ipf)	
	return 0
	
End // CheckCamTab
	
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeCamTab() // create controls that will begin with appropriate prefix

	Variable x0 = 60, y0 = 200, xinc, yinc = 30
	
	String df = CamTabDF()

	ControlInfo /W=NMPanel $CamTabPrefix("Init") // check first in a list of controls
	
	if (V_Flag != 0)
		return 0 // tab controls exist, return here
	endif

	DoWindow /F NMPanel
	
	Button $CamTabPrefix("Init"), pos={x0,y0+0*yinc}, title="Reset Communication", size={200,20}, proc=CamTabButton
	Button $CamTabPrefix("Init"),	help = {"Resets the serial port communication with the modem.  Runs automatically when tab is loaded."}
	Button $CamTabPrefix("CamModeRemote"), pos={x0-40,y0+2*yinc}, title="\\K(65535,0,0)Computer Control", size={120,20}, proc=CamTabButton, help={"Control the camera from the computer ie using this tab"}
	Button $CamTabPrefix("CamModeJumper"), pos={x0+100,y0+2*yinc}, title="Jumper Control", size={120,20}, proc=CamTabButton, help={"Control the camera using the jumpers on the camera body"}
	//Button $CamTabPrefix("Function2"), pos={x0,y0+3*yinc}, title="My Function 2", size={200,20}, proc=CamTabButton

	Button $CamTabPrefix("FullManual"), pos={x0-40,y0+4*yinc}, title="Manual Exposure", size={120,20}, proc=CamTabButton
	Button $CamTabPrefix("FullManual"),	help = {"Sets the camera shutter and gain modes to manual"}
	Button $CamTabPrefix("FullAuto"), pos={x0+100,y0+4*yinc}, title="Auto Exposure", size={120,20}, proc=CamTabButton
	Button $CamTabPrefix("FullAuto"),	help = {"Sets the camera shutter and gain modes to auto"}
	
	PopupMenu $CamTabPrefix("GainMode"), pos={x0+60,y0+6*yinc}, size={0,0}, bodyWidth=80, fsize=14, proc=CamTabPopup
// 000 : 0 dB (AGC OFF)	001 : +6dB	002 : AGC ON	004 : Manual by m_gain
	PopupMenu $CamTabPrefix("GainMode"), value="AGC OFF;+6dB;AGC ON;---;Manual;", title="Gain",help={"Set Gain mode. Must be manual for gain slider to function"}
	Slider $CamTabPrefix("GainSlider"),  limits= {0,24,1 }, proc=CamTabSlider, pos={x0+70,y0+6*yinc}, vert=0,size={24*6,50}
	
//	SetVariable $CamTabPrefix("GainValue"), title="Gain (dB)", pos={x0+90,y0+6*yinc}, size={110,50}, limits={0,24,1}
//	SetVariable $CamTabPrefix("GainValue"), value=$(df+"Gain"), proc=CamTabSetVariable, fsize=14, help = {"Analogue Gain 0-24 dB; only relevant when AGC is set to manual"}

	PopupMenu $CamTabPrefix("ShutterMode"), pos={x0+80,y0+8*yinc}, size={0,0}, bodyWidth=80, fsize=12, proc=CamTabPopup, title = "Shutter"
//000 : ES OFF	001 : FL	002 : E..IRIS ON	004 : Manual by m_es
	PopupMenu $CamTabPrefix("ShutterMode"), value="E IRIS OFF;Manual-Camera;E IRIS ON;---;Manual;",help={"Shutter Mode; Choose Manual to adjust or E Iris On for auto, Manual-Camera uses the potentiometer on the camera body"}

	PopupMenu $CamTabPrefix("MeteringArea"), pos={x0+200,y0+12*yinc}, size={0,0}, bodyWidth=80, fsize=12, proc=CamTabPopup, title = "Auto Expos Metering Area"
	PopupMenu $CamTabPrefix("MeteringArea"), value="Upper Corners;Upper Side;Lower Corners;Lower Side;Centre;Spot",help={"Different metering areas for the auto exposure mechanism"}
	
	PopupMenu $CamTabPrefix("ShutterSpeed"), pos={x0+200,y0+8*yinc}, size={0,0}, bodyWidth=70, fsize=14, proc=CamTabPopup, help={"Shutter Speed in reciprocal seconds"}
	PopupMenu $CamTabPrefix("ShutterSpeed"), fsize=12,title="Speed",value="50;120;250;500;1000;2000;4000;10000;20000;30000"

	//magnification = 256 / (X+1) 63 ... 255
	Slider $CamTabPrefix("ZoomSlider"),  limits= {1,4,.1 }, proc=CamTabSlider, pos={x0,y0+10*yinc}, vert=0,size={39*6,50}, title="Zoom"
	TitleBox  $CamTabPrefix("ZoomTitle") , pos={x0-40,y0+10*yinc} ,title="Zoom"
//	DrawText x0+10,10*yinc,"Zoom"
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
	//UpdateExposureModeButtons()
	//NMMainCall(popStr)
			
End // MainTabPopup


Function CamTabButton(ctrlName) : ButtonControl
	String ctrlName
	
	String fxn = NMCtrlName(CamTabPrefix(""), ctrlName)
	
	CamTabCall(fxn, "")
	
End // CamTabButton

Function CamTabSlider(name, value, event)
	String name	// name of this slider control
	Variable value	// value of slider
	Variable event	// bit field: bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved

	if( event&1 )
		if(cmpstr(name, CamTabPrefix("GainSlider"))==0 )
			CamSetGenericAddress(7,value*10,0,240)
		endif
		if(cmpstr(name, CamTabPrefix("ZoomSlider"))==0 )
		//magnification = 256 / (X+1)
		// X=256/mag -1
			CamSetGenericAddress(17,round(256/value-1),63,255)
		endif		
	endif
	return 0	// other return values reserved	
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
		
		case "FullManual":
			return CamFullAutoManual(1)

		case "FullAuto":
			return CamFullAutoManual(0)

		case "GainMode":
			return CamSetGenericAddress(1,snum-1,0,4) || UpdateExposureModeButtons()

		case "GainValue":
			return CamSetGenericAddress(7,snum*10,0,240)
			
		case "ShutterMode":
			return CamSetGenericAddress(2,snum-1,0,4) || UpdateExposureModeButtons()

		case "ShutterSpeed":
			return CamSetShutterSpeed(snum)
			
	endswitch
	
End // CamTabCall

//****************************************************************
//****************************************************************
//****************************************************************
Function CamSetShutterSpeed(mode)
	Variable mode
	Variable speedVal

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
	
End // CamSetShutterSpeed

Function CamSetGenericAddress(address,value,minval,maxval)
	Variable address // a 0 padded 3-string 
	Variable value,minval, maxval

	String df = CamTabDF()
	NVAR SerialCommState = $(df+"SerialCommState")

	// Check we have a valid mode
	if (value<minval  || value>maxval)
		printf "Bad value %d",value
	endif

	String vdtstr
	sprintf vdtstr, "000000W%03.f%03.f" ,address,value
	//GJ Comment out while on GJPB
	
	if(SerialCommState==0)
		// SerialCommState is set to 0 by CamCommInit when successful
		try
			// Note the use of the one second timeout
			VDTWrite2 /O=1 vdtstr+"\r"; AbortOnRTE
			//Manual recommends 30 ms interval between commands
			Sleep 0:0:0.03
		catch
			// Write failed so set comm state to error level
			SetNMvar(df+"SerialCommState",-1)
			print "Comm Failure, Try resetting communication: "+vdtstr
		endtry
	else
		print "Comm Failure: "+vdtstr
	endif
End // CamSetGenericAddress


Function CamFullAutoManual(mode)
	Variable mode // 0 = full auto, 1 = full manual	

	// Check we have a valid mode
	if (mode<0  || mode>1)
		return (-1)
	endif
	
	if( mode<2)
		CamSetGenericAddress(1,(mode+1)*2,0,4) // gain mode  
		CamSetGenericAddress(2,(mode+1)*2,0,4) // shutter mode 				
	endif
	if( mode==0)
		// Update popups
		PopupMenu $CamTabPrefix("GainMode"), mode=3
		PopupMenu $CamTabPrefix("ShutterMode"), mode=3
	endif
	if(mode==1)
		// Update popups
		PopupMenu $CamTabPrefix("GainMode"), mode=5
		PopupMenu $CamTabPrefix("ShutterMode"), mode=5
	endif
	UpdateExposureModeButtons()
End // CamFullAutoManual

Function UpdateExposureModeButtons()
	Variable gainMode,shutterMode
	
	ControlInfo $CamTabPrefix("GainMode")
	gainMode=V_Value
	ControlInfo $CamTabPrefix("ShutterMode")
	shutterMode=V_Value
	
	if(gainMode==5 && shutterMode==5)
		// both manual
		Button $CamTabPrefix("FullManual"), title="\\K(65535,0,0)Manual Exposure"
		Button $CamTabPrefix("FullAuto"), title="\\K(0,0,0)Auto Exposure"
	else
		if(gainMode==3 && shutterMode==3)
			// both auto
			Button $CamTabPrefix("FullManual"), title="\\K(0,0,0)Manual Exposure"
			Button $CamTabPrefix("FullAuto"), title="\\K(65535,0,0)Auto Exposure"
		else
			// neither of above
			Button $CamTabPrefix("FullManual"), title="\\K(0,0,0)Manual Exposure"
			Button $CamTabPrefix("FullAuto"), title="\\K(0,0,0)Auto Exposure"		
		endif
	endif		
	return (0)
End


Function CamSetMode(mode)
	Variable mode
	
	// Check we have a valid mode
	if (mode<0  || mode>3)
		return (-1)
	endif
	if(mode==0)
		Button $CamTabPrefix("CamModeRemote") ,title="\\K(0,0,0)Computer Control"
		Button $CamTabPrefix("CamModeJumper") ,title="\\K(65535,0,0)Jumper Control"
	else
		Button $CamTabPrefix("CamModeRemote") ,title="\\K(65535,0,0)Computer Control"
		Button $CamTabPrefix("CamModeJumper") ,title="\\K(0,0,0)Jumper Control"
	endif		
	CamSetGenericAddress(0,mode,0,4)
End // CamSetMode

//****************************************************************
//****************************************************************
//****************************************************************

Function CamCommInit()
	// NB It seems to be vital to call CamComInit before attempting any serial port
	// communication.
	String df = CamTabDF()
	Print "CamCommInit"
	try
		VDTOperationsPort2 'Modem'; AbortOnRTE
		VDTOpenPort2 'Modem'; AbortOnRTE
		// Set communications parameters
		VDT2 baud=9600 , stopbits=1,databits=8, parity=0, in=0, out=0
	catch
		print "Unable to open modem"
		SetNMvar(df+"SerialCommState",-1)
		return -1
	endtry
	SetNMvar(df+"SerialCommState",0)
	return 0
End // CamCommInit
