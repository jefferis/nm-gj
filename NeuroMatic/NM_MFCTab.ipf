#pragma rtGlobals = 1
#pragma IgorVersion = 5
#pragma version = 1.91

Constant kMFCMaxControllers=3
static Constant kMFCSerialTimeOutLength=0.2
static Constant kMFCok=0,kMFCcommError=-1, kMFCcontrollerError=-2, kMFCcmdError=-3
static Constant kMFCRefreshRate=5 // 5Hz refresh of controller flow rate

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

Function /S MFCPrefix(varName) // tab prefix identifier
	String varName
	
	return "MFC_" + varName
	
End // MFCPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S MFCDF() // package full-path folder name

	return PackDF("MFC")
	
End // MFCDF

//****************************************************************
//****************************************************************
//****************************************************************

Function MFC(enable)
	Variable enable // (0) disable (1) enable tab
	
	if (enable == 1)
		CheckPackage("MFC", 0) // declare globals if necessary
		MakeMFC() // create tab controls if necessary
		EnableControlLines() // Enable the controls for active MFCs 
		AutoMFC()
	endif

End // MFC

//****************************************************************
//****************************************************************
//****************************************************************

Function AutoMFC()

// put a function here that runs each time CurrentWave number has been incremented 
// see "AutoSpike" for example

End // AutoMFC

//****************************************************************
//****************************************************************
//****************************************************************

Function KillMFC(what)
	String what
	String df = MFCDF()

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

End // KillMFC

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckMFC() // declare global variables

	String df = MFCDF()
	
	if (DataFolderExists(df) == 0)
		return -1 // folder doesnt exist
	endif
	
	// Initialise serial communication
	// In the end it seems to be possible to hang terribly easily with the serial port write 
	//MFCCommInit() // create variable (also see Configurations.ipf)	

	CheckNMWave(df+"FlowWave;"+df+"SetPointWave;"+df+"MaxFlowWave;"+df+"MFCActiveWave",kMFCMaxControllers,0)
	CheckNMWave(df+"FlowRatioWave",kMFCMaxControllers,0)
	CheckNMTWave(df+"MFCIDWave",kMFCMaxControllers,"")

	CheckNMVar(df+"TotalFlowRate",0)
	CheckNMVar(df+"TotalSetPoint",0)
	CheckNMVar(df+"CleverTotals",0) // Makes other MFCs adjust flows.
	CheckNMVar(df+"liveCheck",0) // Live updates of flow rates
	CheckNMVar(df+"liveSend",0) // Live sending of commands
	
//	CheckNMvar(df+"Gain", 0) // create variable (also see Configurations.ipf)	
	return 0
	
End // CheckMFC
	
//****************************************************************
//****************************************************************
//****************************************************************
Function MFCActivateCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
End

Function MFCActiveBox (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selelcted, 0 if not
	String df = MFCDF()
	WAVE MFCActiveWave=$(df+"MFCActiveWave")
	Variable changed=0
	
	Variable ctrlNumber = -1
	sscanf ctrlName, MFCPrefix("Active")+"%d", ctrlNumber
//	printf "ctrlNumber=%d; V_flag=%d", ctrlNumber, V_flag
	if (V_flag==1 && ctrlNumber< kMFCMaxControllers)
		if(MFCActiveWave[ctrlNumber]!=checked)
			MFCActiveWave[ctrlNumber]=checked
			changed=1
		endif
	endif
	if(changed)
		EnableControlLines()
	endif
End

Function EnableControlLines()
	String df = MFCDF()
	WAVE MFCActiveWave=$(df+"MFCActiveWave")
	Variable i
	for (i=0;i<kMFCMaxControllers;i+=1)
		SetVariable $MFCPrefix("MFCID"+num2str(i))  disable=(1-MFCActiveWave[i])
		SetVariable $MFCPrefix("MaxFlow"+num2str(i)) disable=1-MFCActiveWave[i]
		SetVariable $MFCPrefix("SetPoint"+num2str(i)) disable=1-MFCActiveWave[i]
		SetVariable $MFCPrefix("FlowRate"+num2str(i)) disable=1+MFCActiveWave[i]
	endfor
End

Function MFCSendCommands()
	String df = MFCDF()
	WAVE MFCActiveWave=$(df+"MFCActiveWave")

	WAVE SetPointWave=$(df+"SetPointWave")
	WAVE MaxFlowWave=$(df+"MaxFlowWave")
	WAVE /T MFCIDWave=$(df+"MFCIDWave")

	Variable i=0, errorVal,rval=0
	STRUCT MFCStatusStruct mss

	for (i=0; i<kMFCMaxControllers;i+=1)
		if(MFCActiveWave[i])
			print "Sending command to MFC"+num2str(i)
			errorVal=MFCSetFlowRate(MFCIDWave[i],SetPointWave[i],MaxFlowWave[i])
			if(errorVal!=kMFCok)
				rval-=1
			endif
		endif
	endfor
	// Will be the number of controllers that had trouble reporting
	return rval
End

Function MFCZeroFlow()
	String df = MFCDF()
	WAVE MFCActiveWave=$(df+"MFCActiveWave")
	WAVE SetPointWave=$(df+"SetPointWave")
	SetPointWave=0
	MFCSendCommands()
End

Function MFCSetVarValidator (ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	
	String df = MFCDF()
	NVAR CleverTotals=$(df+"CleverTotals")

	WAVE MFCActiveWave=$(df+"MFCActiveWave"),MFCFlowWave=$(df+"FlowWave") ,SetPointWave=$(df+"SetPointWave") 
	NVAR TotalFlowRate=$(df+"TotalFlowRate"),TotalSetPoint=$(df+"TotalSetPoint")
	//print varName
	Variable computedTotal=MatrixDot(SetPointWave,MFCActiveWave)
	if(!CleverTotals)
		// Just update the total set point if we have clever totals off
		TotalSetPoint=computedTotal		
	elseif(stringmatch(varName, "TotalSetPoint" ))
		// scale all the active flow rates
		Variable oldNewRatio=TotalSetPoint/computedTotal
		MatrixOP /O SetPointWave=MFCActiveWave*SetPointWave*oldNewRatio
	elseif(stringmatch(varName, "SetPointWave[0]" ))
		// Update Total Set Point
		TotalSetPoint=computedTotal
	elseif (stringmatch(varName, "SetPointWave[*]" ))
		// Reduce Dilution flow rate to keep Total flow constant
		SetPointWave[0]+=TotalSetPoint-computedTotal
	endif
	NVAR liveSend=$(df+"liveSend")
	if(liveSend)
		MFCSendCommands()
	endif

//	TotalSetPoint
End

Function MFCSetLiveCheck (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selelcted, 0 if not
	String df = MFCDF()
	NVAR liveCheck=$(df+"liveCheck"), liveSend=$(df+"liveSend")

	if(stringmatch(ctrlName,"*MFCSetLiveSendCheck"))
		liveSend=checked
		return 1
	else
		liveCheck=checked
	endif
	if(checked)
		SetBackground CheckActiveControllers()
		CtrlBackground period=60/kMFCRefreshRate,dialogsOK=1,noBurst=1,start
	else
		CtrlBackground stop
	endif
	return 0
End


Function MakeMFC() // create controls that will begin with appropriate prefix

	Variable x0 = 40, y0 = 200, xinc, yinc = 30
	
	String df = MFCDF()

	ControlInfo /W=NMPanel $MFCPrefix("Init") // check first in a list of controls
	
	if (V_Flag != 0)
		return 0 // tab controls exist, return here
	endif


	NVAR liveCheck=$(df+"liveCheck"), liveSend=$(df+"liveSend")

	DoWindow /F NMPanel
	
	Button $MFCPrefix("Init"), pos={x0-20,y0+0*yinc}, title="Reset Comms", size={130,20}, proc=MFCButton
	Button $MFCPrefix("Init"),	help = {"Resets the serial port communication with the modem.  Runs automatically when tab is loaded."}
	
	Button $MFCPrefix("CheckStatus"), pos={x0+130,y0+0*yinc}, title="Check Flow Status", size={130,20}, proc=MFCButton
	Button $MFCPrefix("CheckStatus"),	help = {"Checks the current flow reading and set point for the active MFCs."}
	
	Button $MFCPrefix("ZeroFlow"), pos={x0-20,y0+1*yinc}, title="Zero Flow", size={130,20}, proc=MFCButton
	Button $MFCPrefix("ZeroFlow"),	help = {"Sets all active MFCs to zero flow"}
	
	Button $MFCPrefix("SendCommands"), pos={x0+130,y0+1*yinc}, title="Send Commands", size={130,20}, proc=MFCButton
	Button $MFCPrefix("SendCommands"),	help = {"Sends current set points to active flow meters"}

	Checkbox $MFCPrefix("MFCSetLiveCheck"), pos={x0-20,y0+2*yinc}, title="Continuous polling", size={20,20}, proc=MFCSetLiveCheck, fsize=12
	Checkbox $MFCPrefix("MFCSetLiveCheck"), help = {"Continuous polling of MFC status"}, proc = MFCSetLiveCheck,value= liveCheck 

	Checkbox $MFCPrefix("MFCSetLiveSendCheck"), pos={x0+130,y0+2*yinc}, title="Continuous send", size={20,20}, fsize=12
	Checkbox $MFCPrefix("MFCSetLiveSendCheck"), help = {"Immediately send commands to MFC - otherwise press Send Commands"}, proc=MFCSetLiveCheck, value= liveSend

//	Button $MFCPrefix("CheckStatus"), pos={x0,y0+0*yinc}, title="Check Flow Status", size={140,20}, proc=MFCButton
//	Button $MFCPrefix("CheckStatus"),	help = {"Checks the current flow reading and set point for the active MFCs."}
	
	// Each controller should display
	// Active ID MaxFlow SetPoint CurrentFlow
	WAVE MFCActiveWave=$(df+"MFCActiveWave"),MFCFlowWave=$(df+"FlowWave") ,SetPointWave=$(df+"SetPointWave") 
	NVAR TotalFlowRate=$(df+"TotalFlowRate"),TotalSetPoint=$(df+"TotalSetPoint")
	
	NVAR CleverTotals=$(df+"CleverTotals")

	TitleBox $MFCPrefix("Text0") pos={x0+10,y0+105},title="MFCID",size={0,0},frame=0,fsize=12
	TitleBox $MFCPrefix("Text1") pos={x0+50,y0+105},title="FullScale",size={0,0},frame=0,fsize=12
	TitleBox $MFCPrefix("Text2") pos={x0+120,y0+105},title="SetPoint",size={0,0},frame=0,fsize=12
	TitleBox $MFCPrefix("Text3") pos={x0+190,y0+105},title="FlowRate",size={0,0},frame=0,fsize=12

	Variable i=0, ypos
	for (i=0;i<kMFCMaxControllers;i+=1)
		ypos=y0+100+(i+1)*yinc
		Checkbox $MFCPrefix("Active"+num2str(i)), pos={x0-20,ypos+2}, title="", size={20,20}, proc=MFCActivateCheckBox, fsize=12
		Checkbox $MFCPrefix("Active"+num2str(i)), help = {"Activate MFC."}, proc = MFCActiveBox,value= MFCActiveWave[i] 
	
		SetVariable $MFCPrefix("MFCID"+num2str(i)) size={30,20}, value=::Packages:MFC:MFCIDWave[i],pos={x0+10,ypos},title=" ", fsize=12, help={"Controller ID (A-Z)"}
		SetVariable $MFCPrefix("MaxFlow"+num2str(i)) size={60,20},value=::Packages:MFC:MaxFlowWave[i],pos={x0+50,ypos},limits={0,2000,500}
		SetVariable $MFCPrefix("MaxFlow"+num2str(i)) title=" ", fsize=12,help={"The Full Scale value of the controller - eg 2000 ml/min = SCCM"}

		SetVariable $MFCPrefix("SetPoint"+num2str(i)) size={60,20},value=::Packages:MFC:SetPointWave[i],pos={x0+120,ypos}, title=" ",limits={0,2000,50}, fsize=12, proc=MFCSetVarValidator,help={"The set point that will be sent to the controller - in SCCM"}
		SetVariable $MFCPrefix("FlowRate"+num2str(i)) , fsize=12,pos={x0+190,ypos},size={60,20}, title=" ", value=::Packages:MFC:FlowWave[i],  noedit=1
		SetVariable $MFCPrefix("FlowRate"+num2str(i)) help = {"The Flow Rate reported by the controler"}
		//SetVariable $MFCPrefix("FlowRatio"+num2str(i)) , fsize=12, mode=2,pos={x0+240,ypos}, size={50,20}, disable=1,value=::Packages:MFC:FlowWave[i]/root:Packages:MFC:TotalSetPoint
	endfor	
//	ValDisplay $MFCPrefix("FlowRatio"+num2str(i)) value=#root:Packages:MFC:SetPointWave[2]/root:Packages:MFC:TotalSetPoint
//	ValDisplay $MFCPrefix("FlowRatio"+num2str(i)) value=#root:Packages:MFC:SetPointWave[3]/root:Packages:MFC:TotalSetPoint

	Checkbox $MFCPrefix("CleverTotals"), pos={x0-20,ypos+yinc+10+2}, title="Clever Totals", size={20,20}, fsize=12
	Checkbox $MFCPrefix("CleverTotals"), help = {"Clever Totalling (adjusts flow rates to main total flow or same ratio)"}, variable=$(df+"CleverTotals")
	SetVariable $MFCPrefix("TotalSetPoint"+num2str(i)) size={60,20},value=TotalSetPoint,pos={x0+120,ypos+yinc+10}, title=" ",limits={0,2000,50}, fsize=12, proc=MFCSetVarValidator
	ValDisplay $MFCPrefix("TotalFlowRate"+num2str(i)) , fsize=12, value=#root:Packages:MFC:TotalFlowRate,mode=2,pos={x0+190,ypos}
	
End // MakeMFC

//****************************************************************
//****************************************************************
//****************************************************************
Function MFCPopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	//PopupMenu $ctrlName, win=NMpanel, mode=1 // force menus back to title
	String fxn = NMCtrlName(MFCPrefix(""), ctrlName)
	if (cmpstr(popStr, "---")==0)
		// deal with dividers
		popNum=0
	endif

	MFCCall(fxn,num2str(popNum))
	//MFCUpdateExposureModeButtons()
	//NMMainCall(popStr)
			
End // MainTabPopup


Function MFCButton(ctrlName) : ButtonControl
	String ctrlName
	
	String fxn = NMCtrlName(MFCPrefix(""), ctrlName)
	
	MFCCall(fxn, "")
	
End // MFCButton


Function CheckActiveControllers()
	String df = MFCDF()
	WAVE FlowRateWave=$(df+"FlowWave")
	WAVE SetPointWave=$(df+"SetPointWave")
	WAVE MFCActiveWave=$(df+"MFCActiveWave")
//	WAVE MaxFlowWave=$(df+"MaxFlowWave")
	WAVE /T MFCIDWave=$(df+"MFCIDWave")
	
	Variable i, comError,rval=0
	STRUCT MFCStatusStruct mss

	for (i=0; i<kMFCMaxControllers;i+=1)
		if(MFCActiveWave[i])
			//print "Checking MFC"+num2str(i)
			comError=MFCStatus(MFCIDWave[i],mss)
			if(comError>=0)
				FlowRateWave[i]=mss.MassFlow
				// Do I want two waves for the flow command? One for Igor, One for MFC
			//	SetPointWave[i]=mss.MassFlowCmd
			else
				rval-=1
			endif
		endif
	endfor
	// Will be the number of controllers that had trouble reporting
	return rval
End

//****************************************************************
//****************************************************************
//****************************************************************

Function MFCSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String fxn = NMCtrlName(MFCPrefix(""), ctrlName)
	
	MFCCall(fxn, varStr)
	
End // MFCSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function MFCCall(fxn, select)
	String fxn // function name
	String select // parameter string variable
	
	Variable snum = str2num(select) // parameter variable number
	
	strswitch(fxn)
				
		case "Init":
			return MFCCommInit()
		case "CheckStatus":
			return CheckActiveControllers()
		case "SendCommands":
			return MFCSendCommands()
		case "ZeroFlow":
			return MFCZeroFlow()	
	endswitch
	
End // MFCCall

Function MFCWriteString(vdtstr)
	String vdtstr
	Variable rval=0
	// GJ TODO should I put a carriage return at beginning and end?
	// GJ TODO Do I need to read a string back as well?
	String df = MFCDF()
	NVAR SerialCommState = $(df+"SerialCommState")
	
	if(SerialCommState==0)
		// SerialCommState is set to 0 by MFCCommInit when successful
		try
			VDTWrite2 /O=(kMFCSerialTimeOutLength) vdtstr+"\r"; AbortOnRTE
		catch
			// Write failed so set comm state to error level
			SetNMvar(df+"SerialCommState",-1)
			print "Comm Failure, Try resetting communication: "+vdtstr
			rval=-1
		endtry
	else
		print "Comm Failure: "+vdtstr
		rval=-2
	endif
	return(rval)
End // MFCWriteString

Function /S MFCReadString()
	String vdtstr=""
	// GJ TODO should I put a carriage return at beginning and end?
	// GJ TODO Do I need to read a string back as well?
	String df = MFCDF()
	NVAR SerialCommState = $(df+"SerialCommState")
	
	if(SerialCommState==0)
		// SerialCommState is set to 0 by MFCCommInit when successful
		try
			VDTRead2 /Q /O=(kMFCSerialTimeOutLength) vdtstr; AbortOnRTE
		catch
			// Write failed so set comm state to error level
			// Is this appropriate for a read failure?
			// could be other reasons, so just print message
			// SetNMvar(df+"SerialCommState",-1)
			print "Comm Failure, Try resetting communication: "+vdtstr
		endtry
	else
		print "MFC Comm Disabled: "+vdtstr
	endif
	return(vdtstr)
End // MFCReadString


Function /S MFCReadWriteString(cmdstr)
	String cmdstr
	String outstr="" 
	if( MFCWriteString(cmdstr) ==0)
		outstr=MFCReadString()
	endif
	return outstr
End

Function MFCSetCommID(MFCID)
	String MFCID
	return(MFCWriteString("*@="+MFCID))
	// GJ TODO check if this has a return value
End

Function MFCSetFlowRate(MFCID,FlowRateCmd,MaxFlowRate)
	String MFCID
	Variable FlowRateCmd,MaxFlowRate
	
	Variable flowSignal = (FlowRateCmd/MaxFlowRate*64000)
	Variable rval=kMFCok
	
	if( ! ( flowSignal>=0 && flowSignal<=65535 ) )
		print "MFCSetFlowRate: Invalid flow commands "+num2str(FlowRateCmd)+" / "+num2str(MaxFlowRate)
		return kMFCcmdError
	endif

	if(flowSignal<320)
		print "MFCSetFlowRate: FlowRate Set to 0 for commands"+num2str(FlowRateCmd)+" / "+num2str(MaxFlowRate)
		flowSignal=0
	endif
	
	String cmdstr,returnstr
	Sprintf cmdstr "%s%d", MFCID, round(flowSignal)
	returnstr=MFCReadWriteString(cmdstr)
	
	STRUCT MFCStatusStruct ms
	
	if( ParseMFCStatusString(returnstr,ms)>0)
		if(ms.MassFlowCmd==FlowRateCmd)
			// print "Successfully set MFC Command to "+num2str(FlowRate)
		else
			printf "Mismatch between desired command flow (%f) and MFC Set Point (%f)\r", FlowRateCmd, ms.MassFlowCmd
			return kMFCcontrollerError
		endif		
	else
		print "No intelligible response from MFC"
		return kMFCcommError
	endif
	
	// eg of response:
	// +014.70 +025.00 +02.004 +02.004 2.004 Air 

End

Structure MFCStatusStruct
	Variable Pressure
	Variable Temp
	Variable VolFlow
	Variable MassFlow
	Variable MassFlowCmd
	String Gas
EndStructure

Function testParseMFCStatusString(tstr)
	String tstr
//	tstr="+014.70 +025.00 +02.004 +02.004 2.004 Air"
	STRUCT MFCStatusStruct ms2
	ParseMFCStatusString(tstr,ms2)
	print "Actual Flow rate is "+num2str(ms2.MassFlow)
End

Function testMFCStatus()
	STRUCT MFCStatusStruct ms2
	MFCStatus("A",ms2)
	print "Actual Flow rate is "+num2str(ms2.MassFlow)
End

Function MFCStatus(MFCID,mss)
	String MFCID
	STRUCT MFCStatusStruct &mss
	Variable numericMFCID=-1
	
	// Check if we have a sensible MFC ID in range A-Z
	sscanf MFCID,"%c",numericMFCID
	if( numericMFCID<(1+64) || numericMFCID>(26+64) )
		print ("Invalid MFCID "+MFCID)
		return -1
	endif
	// Interrogate MFC - NB RWString will add CR
	return ParseMFCStatusString(MFCReadWriteString(MFCID),mss)
End
	
Function ParseMFCStatusString(vdtstr, ms)
	String vdtstr
	
	STRUCT MFCStatusStruct &ms
	
	Variable f1,f2,f3,f4,f5, nRead=-1
	String id, Gas
	sscanf vdtstr,"%s %f %f %f %f %f %s", id, f1,f2,f3,f4,f5,Gas
	nRead=V_flag
	if(nRead==7)
		ms.Pressure=f1
		ms.Temp=f2
		ms.VolFlow=f3*1000
		ms.MassFlow=f4*1000
		ms.MassFlowCmd=f5*1000
		ms.Gas=Gas
//	printf "%f, %f, %f, %f, %f, %s\r",f1,f2,f3,f4,f5,Gas
	else 
		ms.MassFlow=NaN
	endif 
	return nRead
End


print ParseMFCStatusString("+014.70 +025.00 +02.004 +02.004 2.004 Air ")
//****************************************************************
//****************************************************************
//****************************************************************

Function MFCCommInit()
	// NB It seems to be vital to call MFCComInit before attempting any serial port
	// communication.
	String df = MFCDF()
	Print "MFCCommInit"
	try
		VDTOperationsPort2 'KeySerial1'; AbortOnRTE
		VDTOpenPort2 'KeySerial1'; AbortOnRTE
		// Set communications parameters
		VDT2 baud=19200 , stopbits=1,databits=8, parity=0, in=0, out=0
		// Send a few returns to clear any pending commands
		VDTWrite2 /O=(kMFCSerialTimeOutLength) "\r\r"; AbortOnRTE
	catch
		print "Unable to open modem"
		SetNMvar(df+"SerialCommState",-1)
		return -1
	endtry
	SetNMvar(df+"SerialCommState",0)
	return 0
End // MFCCommInit
