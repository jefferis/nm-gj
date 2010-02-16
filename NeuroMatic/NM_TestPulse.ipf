#pragma rtGlobals = 1
#pragma IgorVersion = 4
#pragma version = 1.86

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic TestPulse Demo Tab
//	To be run with NeuroMatic, v1.86
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro 4
//
//	By Jason Rothman (Jason@ThinkRandom.com)
//
//	Last modified 30 Nov 2004
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S TestPulsePrefix(varName) // tab prefix identifier
	String varName
	
	return "TP_" + varName
	
End // TestPulsePrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TestPulseDF() // package full-path folder name

	return PackDF("TestPulse")
	
End // TestPulseDF

//****************************************************************
//****************************************************************
//****************************************************************

Function TestPulse(enable)
	Variable enable // (0) disable (1) enable tab
	
	if (enable == 1)
		CheckPackage("TestPulse", 0) // declare globals if necessary
		MakeTestPulse() // create tab controls if necessary
		AutoTestPulse()
		CheckTestPulse()
	endif

End // TestPulse

//****************************************************************
//****************************************************************
//****************************************************************

Function AutoTestPulse()

// put a function here that runs each time CurrentWave number has been incremented 
// see "AutoSpike" for example

End // AutoTestPulse

//****************************************************************
//****************************************************************
//****************************************************************

Function KillTestPulse(what)
	String what
	String df = TestPulseDF()

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

End // KillTestPulse

Function TestPulseConfigs()
	String fname = "TestPulse"

	NMConfigVar(fname, "ADCChannel", 0, "ADC Channel to read for Seal Test response data")
	NMConfigVar(fname, "DACChannel", 0, "DAC Channel to which Seal Test output is sent")

End // MyTabConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckTestPulse() // declare global variables

	String df = TestPulseDF()
	
	if (DataFolderExists(df) == 0)
		return -1 // folder doesnt exist
	endif
	
	NVAR AcqMode=$(df+"AcqMode")
	WAVE tmpdevices=$(df+"tmpdevices")
	
	// Check to see if ITC is active:
	CheckNMWave(df+"tmpdevices",4,0)
	// Need an integer wave (regular waves are double) NB this preserves values
	Redimension /I $(df+"tmpdevices")
//	Execute "ITC18GetDevices "+df+"tmpdevices"
	Execute /Z "ITC18GetDevices "+df+"tmpdevices"
	// will be non zero if there is a problem accessing the ITC
	SetNMvar(df+"AcqMode",V_Flag) // set variable (also see Configurations.ipf)
	
	// Create Global variables and waves
	CheckNMvar(df+"TestPulseSize", -10) // create variable (also see Configurations.ipf)
	CheckNMvar(df+"resistance",0) // create variable (also see Configurations.ipf)
	CheckNMvar(df+"accessResistance",0) // create variable (also see Configurations.ipf)
	// Size of moving average for resistance
	CheckNMvar(df+"SweeperWindow", 5) // create variable (also see Configurations.ipf)
	NVAR SweeperWindow=$(df+"SweeperWindow")
	CheckNMvar(df+"SweeperTimeStep",200e-6)
	NVAR SweeperTimeStep=$(df+"SweeperTimeStep")
	CheckNMWave(df+"SweeperStimWave",SweeperWindow/SweeperTimeStep,0)
	CheckNMWave(df+"SweeperSampWave",SweeperWindow/SweeperTimeStep,0)
	
	SetScale/P x 0,SweeperTimeStep,"s", $(df+"SweeperStimWave"), $(df+"SweeperSampWave")
	
	CheckNMvar(df+"ADCRange",10) // create variable (also see Configurations.ipf)
	CheckNMvar(df+"PulseOn",1) // Default is to have test pulse on (when graph is started)
	CheckNMvar(df+"ADCChannel",0) // create variable (also see Configurations.ipf)
	CheckNMvar(df+"DACChannel",0) // create variable (also see Configurations.ipf)
	NVAR ADCChannel = $(df+"ADCChannel")
	NVAR ADCRange = $(df+"ADCRange")
	
	// Make sure that we have set ADC range appropriately (eg in case nclamp changed it)
	Execute /Z "ITC18SetADCRange "+num2str(ADCChannel)+" "+num2str(ADCRange)
	
	CheckNMstr(df+"ClampMode","VC") // create variable (also see Configurations.ipf)
	CheckNMstr(df+"Amplifier","Multiclamp") // create variable (also see Configurations.ipf)
		
	CheckNMvar(df+"fps", 0) // create variable (also see Configurations.ipf)
	CheckNMvar(df+"tryFPS",15) // create variable (also see Configurations.ipf)
	CheckNMvar(df+"nticksLast",ticks) // create variable (also see Configurations.ipf)
	
	CheckNMvar(df+"WaveLength",500)
	NVAR WaveLength=$(df+"WaveLength")
	CheckNMwave(df+"testpulseout", WaveLength, 0) // numeric wave
	CheckNMwave(df+"testpulsein", WaveLength, 0) // numeric wave
	CheckNMwave(df+"itcout", WaveLength, 0) // numeric wave
	CheckNMwave(df+"itcin", WaveLength, 0) // numeric wave
	
	SetScale/P x 0,1e-5,"s", $(df+"testpulsein"), $(df+"testpulseout")
	SVAR ClampMode=$(df+"ClampMode")
	if(stringmatch(ClampMode,"VC"))
		SetScale d 0,0,"A", $(df+"testpulsein")
		SetScale d 0,0,"V", $(df+"testpulseout")
	else
		SetScale d 0,0,"V", $(df+"testpulsein")
		SetScale d 0,0,"A", $(df+"testpulseout")
	endif	
	
	CheckNMtwave(df+"MyText", 5, "Anything") // text wave
	//WAVE fit_testpulsein=$(df+"fit_testpulsein")
	if(  cmpstr(WinName(0, 3),"TestPulseGraph")==0)
		RemoveFromGraph /Z fit_testpulsein
	endif
	
	return 0
	
End // CheckTestPulse
	
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeTestPulse() // create controls that will begin with appropriate prefix

	Variable x0 = 40, y0 = 220, xinc, yinc = 50,buttonH=20,buttonW=140
	
	String df = TestPulseDF()

	ControlInfo /W=NMPanel $TestPulsePrefix("Function0") // check first in a list of controls
	
	if (V_Flag != 0)
		return 0 // tab controls exist, return here
	endif

	DoWindow /F NMPanel
	
	//DrawRect x0-10,y0-10,x0+20+2*buttonW,y0+10+1*(yinc+buttonH)
	GroupBox $TestPulsePrefix("TestPulseBox"), pos={x0-10,y0-20}, size={30+2*buttonW,30+1*(yinc+buttonH)}, title = "Test Pulse Graph"
	Button $TestPulsePrefix("MakeTPGraph"), pos={x0,y0+0*yinc}, title="Open Test Pulse", size={buttonW,buttonH}, proc=TestPulseButton
	Button $TestPulsePrefix("CloseTPGraph"), pos={x0+150,y0+0*yinc}, title="Close Test Pulse", size={buttonW,buttonH}, proc=TestPulseButton
	Button $TestPulsePrefix("StartStopTP"), pos={x0,y0+1*yinc}, title="Start/Stop Test Pulse", size={buttonW,buttonH}, proc=TestPulseButton
	Button $TestPulsePrefix("ResetTP"), pos={x0+150,y0+1*yinc}, title="Reset Test Pulse", size={buttonW,buttonH}, proc=TestPulseButton

//	DrawRect x0-10,y0-10+2*yinc,x0+20+2*buttonW,y0+10+1*(yinc+buttonH)+2*yinc
	GroupBox $TestPulsePrefix("SweeperBox"), pos={x0-10,y0-20+3*yinc}, size={30+2*buttonW,30+1*(yinc+buttonH)}, title = "Sweeper Graph"
	Button $TestPulsePrefix("MakeSweeperGraph"), pos={x0,y0+3*yinc}, title="Open Sweeper Graph", size={buttonW,buttonH}, proc=TestPulseButton
	Button $TestPulsePrefix("CloseSweeperGraph"), pos={x0+150,y0+3*yinc}, title="Close Sweeper", size={buttonW,buttonH}, proc=TestPulseButton
	Button $TestPulsePrefix("StartStopSweeper"), pos={x0,y0+4*yinc}, title="Start/Stop Sweeper", size={buttonW,buttonH}, proc=TestPulseButton
	Button $TestPulsePrefix("ResetSweeper"), pos={x0+150,y0+4*yinc}, title="Reset Sweeper", size={buttonW,buttonH}, proc=TestPulseButton, disable=2

//	Button $TestPulsePrefix(""), pos={x0,y0+3*yinc}, title="Macro TestPulse", size={buttonW,buttonH}, proc=TestPulseButton
	
	SetVariable $TestPulsePrefix("SweeperWidth"), title="Sweeper Window /s", pos={x0,y0+5*yinc}, size={140,50}, limits={1,20,1}
	SetVariable $TestPulsePrefix("SweeperWidth"), value=$(df+"SweeperWindow"), proc=TestPulseSetVariable

End // MakeTestPulse

//****************************************************************
//****************************************************************
//****************************************************************

Function TestPulseButton(ctrlName) : ButtonControl
	String ctrlName
	
	String fxn = NMCtrlName(TestPulsePrefix(""), ctrlName)
	
	TestPulseCall(fxn, "")
	
End // TestPulseButton

//****************************************************************
//****************************************************************
//****************************************************************

Function TestPulseSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String fxn = NMCtrlName(TestPulsePrefix(""), ctrlName)
	
	TestPulseCall(fxn, varStr)
	
End // TestPulseSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function TestPulseCall(fxn, select)
	String fxn // function name
	String select // parameter string variable
	String myTPWinName="TestPulseGraph"
	String mySweeperWinName="TPSweeperGraph"
	
	Variable snum = str2num(select) // parameter variable number
	
	strswitch(fxn)
	
		case "MakeTPGraph":
			// Check if we already have a graph
			if(strlen(WinList(myTPWinName,";",""))>0)
				Execute "DoWindow /F "+myTPWinName
			else
				Execute "TestPulseGraph()"
			endif
			return 0
			//return NMMainLoop() // see NM_MainTab.ipf
		case "CloseTPGraph":
			Execute /Z "DoWindow /K "+myTPWinName
			return 0
		case "StartStopTP":
// GJ to fix - doesn't seem to be able to see controls
//		Execute /Z "DoWindow /F "+myTPWinName
//		ControlInfo  /W=$(myTPWinName) StartButton
////		ControlInfo StartButton
//			if(V_flag==0)
//				// no Start button, so should stop
//				StartButton("StopButton")
//			else
//				StartButton("StartButton")
//			endif
			return 0
		case "MakeSweeperGraph":
			if(strlen(WinList(mySweeperWinName,";",""))>0)
				Execute "DoWindow /F "+mySweeperWinName
			else
				Execute mySweeperWinName+"()"
			endif
			return 0
		case "CloseSweeperGraph":
			Execute /Z "DoWindow /K "+mySweeperWinName
			return 0
		case "StartStopSweeper":
			Execute "TPSweepStart()"
			return 0
	endswitch
	
End // TestPulseCall


//****************************************************************
//****************************************************************
//****************************************************************

Function SingleAcq()
	String df = TestPulseDF()

	// don't print commands to the command line
	silent 1									
	Wave testpulseout=$(df+"testpulseout"), testpulsein= $(df+"testpulsein"), itcout=$(df+"itcout"),itcin=$(df+"itcin")
	PauseUpdate
	
	NVAR tps = $(df +"TestPulseSize")
	NVAR resistance = $(df +"resistance")
	NVAR accessResistance = $(df +"accessResistance")

	NVAR AcqMode = $(df+"AcqMode")
	NVAR ADCRange = $(df+"ADCRange")
	NVAR PulseOn = $(df+"PulseOn")
	SVAR ClampMode = $(df+"ClampMode")
	SVAR Amplifier = $(df+"Amplifier")
	
	NVAR ADCChannel= $(df+"ADCChannel") 
	NVAR DACChannel = $(df+"DACChannel")
	
	// TestPulseSize comes in as either mV or pA
	// But I will convert to A or V

	Variable lev, CommandGain, SignalGain
	if(stringmatch(ClampMode,"VC"))
		lev=tps*1e-3 // convert from mV to V
		CommandGain=50 // (20mV /V of cmd signal => 1/20e-3=50)
		if(stringmatch(Amplifier,"AM2400"))	
			// Amplifier Gain (1-100) * Raw Headstage gain (100mV/nA)
			SignalGain=10*100e-3*1e9 // 100*1e9 mV/A probe gain 	
		elseif(stringmatch(Amplifier,"Axoclamp"))	
			// Axoclamp
			SignalGain=100e-3*1e9 // 100*1e9 mV/A probe gain 
		elseif(stringmatch(Amplifier,"Multiclamp"))	
			//SignalGain=500e-3*1e9 // 500*1e9 mV/A probe gain 
			SignalGain=2.5e-3*1e12 // 2.5*1e12 mV/A probe gain  (MC Gain =5)
		endif
	else
		lev=tps*1e-12 // convert from pA to A
		if(stringmatch(Amplifier,"AM2400"))		
			CommandGain=5*100e6 // AM2400 IClamp cmd gain in Probe Low with 100 MOhm headstage
			SignalGain=10// 10V / V signal gain  (range 1-100, all on amplifier)
		elseif(stringmatch(Amplifier,"Axoclamp"))	
			// Axoclamp
			CommandGain=1e9 // (1nA/V of cmd signal => 1/1e-9=1e9)
			SignalGain=10 // 10V / V signal gain
		elseif(stringmatch(Amplifier,"Multiclamp"))	
			CommandGain=1/(400e-12) // (400 pA/V of cmd signal => 1/400e-12=2.5e9)
			SignalGain=50 // 50V / V signal gain or 0.05V/mV
		endif
	endif
	testpulseout=0
	if(PulseOn)
		testpulseout[numpnts(testpulseout)/4,3*numpnts(testpulseout)/4]=lev
	endif
	itcout=testpulseout*CommandGain*3200
	Variable AcqFailed=0
	try
		if(AcqMode==0)
			String cmdstr
			if(stringmatch(ClampMode,"VC") || stringmatch(Amplifier,"AM2400") || stringmatch(Amplifier,"Multiclamp"))
				sprintf cmdstr, "ITC18seq \"%d\",\"%d\"", DACChannel, ADCChannel
				Execute /Z cmdstr
//				Execute /Z "ITC18seq \""+ADCChannel) 0\",\"0\""		                    		// 1 DAC and 1 ADC. First string is DACs. 2nd string is ADCs
			else
				// Use channel 1 for input / output
				// (for Axoclamp 2B Bridge Mode)
				Execute /Z "ITC18seq \"1\",\"1\""		                    		// 1 DAC and 1 ADC. First string is DACs. 2nd string is ADCs
			endif
			AbortOnValue V_Flag!=0,0
		
			// load output data, start acquisition for 10 microsecond sampling and stop
			Execute /Z  "ITC18StimandSample "+df+"itcout, "+df+"itcin,"+ num2str(8)+", 2, 0"
			// NB ADCRange must be factored in 
			testpulsein=itcin/(3200*SignalGain)*	ADCRange/10	// scale data into volts	
		else
			AcqFailed=1
		endif	
	catch
		print "Caught Acq Exception"
		AcqFailed=1
	endtry

	// Fake some data 
	if(AcqFailed==1)
		Variable fakeresistance = 10e6 + gnoise(1e6)
		testpulsein = testpulseout/fakeresistance
		testpulsein = testpulsein+ gnoise(mean(testpulsein)/7)
	endif		
		
	Variable X1,X2
	X2=mean(testpulsein,pnt2x(testpulsein,2*numpnts(testpulsein)/4),pnt2x(testpulsein,3*numpnts(testpulsein)/4))
//	I2=mean(testpulsein,pnt2x(testpulsein,1.5*numpnts(testpulsein)/4),pnt2x(testpulsein,2.5*numpnts(testpulsein)/4))
	X1=mean(testpulsein,0,pnt2x(testpulsein,1*numpnts(testpulsein)/4))
	
	X2=mean(testpulsein,pnt2x(testpulsein,2.2*numpnts(testpulsein)/4),pnt2x(testpulsein,2.9*numpnts(testpulsein)/4))
//	I2=mean(testpulsein,pnt2x(testpulsein,1.5*numpnts(testpulsein)/4),pnt2x(testpulsein,2.5*numpnts(testpulsein)/4))
	X1=mean(testpulsein,0,pnt2x(testpulsein,1*numpnts(testpulsein)/5))
	//modified by Nick Sept 8, 2009
	
	if(stringmatch(ClampMode,"VC"))
		resistance=lev/(X2-X1)/1e6
	else
		resistance=(X2-X1)/lev/1e6	
	endif
	// Set a max value of 10 GOhm and min value of 0 for resistance
	if (resistance>10000)
		resistance=9999.99
	else
		if(resistance<0)
			resistance = 0
		endif
	endif
	ResumeUpdate
	return 0
End



//////////////////////////////////
// Copied from Live Mode Demo Proc File
//////////////////////////////////

Function UpdateFPS()
	String df = TestPulseDF()
	NVAR nticksLast= $(df+"nticksLast")
	NVAR fps= $(df+"fps")
	variable now= ticks,delta= now-nticksLast
	
	nticksLast= now
	fps= fps + ( 60/delta - fps )/max(1,20/delta)
	return 0
End

Function TestFetchDF(n)
	Variable n
	Variable microSeconds
	Variable timerRefNum
	Variable i
	timerRefNum = startMSTimer
	if (timerRefNum == -1)
		Abort "All timers are in use"
	endif
	for(i=0;i<n;i+=1)	// initialize variables;continue test
		TestPulseDF()
	endfor											// execute body code until continue test is FALSE
	microSeconds = stopMSTimer(timerRefNum)
	//Print microSeconds/n, "microseconds per iteration"
	return  microSeconds/n
End
	
Function ModePop(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not

	ModifyGraph live(testpulsein)= checked
End

Function AxisScalePop(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
	if(checked)
		SetAxis left -0.1,0.02
	else
		SetAxis/A
	endif
End
	
Function SizePop(theTag,value,item) : PopupMenuControl
	String theTag,item
	Variable value

	String df = TestPulseDF()
	NVAR WaveLength=$(df+"WaveLength")
	Wave testpulseout=$(df+"testpulseout"), testpulsein= $(df+"testpulsein"), itcout=$(df+"itcout"),itcin=$(df+"itcin")

	Make tdata={100,300,500,1000,5000,10000}
	WaveLength=tdata[value-1]
	Redimension/N=(WaveLength) testpulsein,testpulseout,itcin,itcout
	KillWaves tdata
	SetScale/P x 0,0.01e-3,"s", testpulsein,testpulseout
	
End

Function ADCPop(theTag,value,item) : PopupMenuControl
	String theTag,item
	Variable value

	String df = TestPulseDF()
	NVAR ADCRange = $(df+"ADCRange")
	NVAR AcqMode = $(df+"AcqMode")
	NVAR ADCChannel = $(df+"ADCChannel")
	
	switch(value)	// numeric switch
		case 1:		// execute if case matches expression
			ADCRange=1
			break						// exit from switch
		case 2:		// execute if case matches expression
			ADCRange=2
			break						// exit from switch
		case 3:		// execute if case matches expression
			ADCRange=5
			break						// exit from switch
		default:							// optional default expression executed
			ADCRange=10				// when no case matches
	endswitch

	// Now change the range
	try
		if(AcqMode==0)
			if (ADCChannel>1)
				Execute /Z "ITC18SetADCRange "+num2str(ADCChannel)+","+num2str(ADCRange)
			endif
			Execute /Z "ITC18SetADCRange 0,"+num2str(ADCRange)
			AbortOnValue V_Flag!=0,0
			Execute /Z "ITC18SetADCRange 1,"+num2str(ADCRange)
			AbortOnValue V_Flag!=0,0
		endif	
	catch
		print "Caught Acq Exception"
	endtry
End

Function CMPop(theTag,value,item) : PopupMenuControl
	String theTag,item
	Variable value

	String df = TestPulseDF()
	SVAR ClampMode = $(df+"ClampMode")
	NVAR tps = $(df +"TestPulseSize")
	if(stringmatch(ClampMode,item)==0)
		ClampMode=item
		CheckTestPulse()
		if(stringmatch(ClampMode,"VC"))
			Slider TestPulseSlider,limits={-20,20,1}
			if (tps<-20)
				tps=-20
			endif
			if (tps>20)
				tps=20
			endif
		else
			Slider TestPulseSlider,limits={-500,500,1}
		endif

	endif		
End
Function AmplifierPop(theTag,value,item) : PopupMenuControl
	String theTag,item
	Variable value

	String df = TestPulseDF()
	SVAR Amplifier = $(df+"Amplifier")
	Amplifier=item
End

Function SetFPS(name, value, event)
	String name	// name of this slider control
	Variable value	// value of slider
	Variable event	// bit field: bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved

	String df = TestPulseDF()
	if( event&1 )
		NVAR tryFPS=$(df+"tryFPS")
		tryFPS= value
		CtrlBackground period=60/value
		print "set CtrlBackground"
		Variable dummy= GetRTError(1)	// to clear the error in case start has not been pressed
	endif
	return 0	// other return values reserved
End

Function DoMacro(macstr)
	String macstr
	Execute /Z macstr
	return V_Flag
End

Function StartButton(theTag)
	String theTag

	String df = TestPulseDF()

	NVAR tryFPS=$(df+"tryFPS"),fps=$(df+"fps")

	NVAR ADCRange = $(df+"ADCRange")
	NVAR AcqMode = $(df+"AcqMode")

	if( cmpstr(theTag,"StartButton")==0 )
		Button $theTag,rename=StopButton,title="stop"

		try
			if(AcqMode==0)
				Execute /Z "ITC18SetADCRange 0,"+num2str(ADCRange)
				AbortOnValue V_Flag!=0,0
				Execute /Z "ITC18SetADCRange 1,"+num2str(ADCRange)
				AbortOnValue V_Flag!=0,0
			endif	
		catch
			print "Caught Acq Exception"
		endtry

		SetBackground SingleAcq() +UpdateFPS()
		CtrlBackground period=60/tryFPS,dialogsOK=1,noBurst=1,start
		fps= 0
	else
		Button $theTag,rename=StartButton,title="start"
		CtrlBackground stop
	endif
End


Function SliderProc(ctrlName,sliderValue,event) : SliderControl
	String ctrlName
	Variable sliderValue
	Variable event	// bit field: bit 0: value set, 1: mouse down, 2: mouse up, 3: mouse moved
	Variable dummy

	String df = TestPulseDF()

	if(cmpstr(ctrlName,"TestPulseSlider")==0  &&  event %& 0x1)	// bit 0, value set
		NVAR testPulseSize = $(df+"TestPulseSize")
		testPulseSize= sliderValue
		dummy= GetRTError(1)	// to clear the error in case start has not been pressed
	endif
	
	if(cmpstr(ctrlName,"pulserate")==0  &&  event %& 0x1)	// bit 0, value set
		NVAR tryFPS = $(df+"tryFPS")
		tryFPS= sliderValue
		CtrlBackground period=60/sliderValue
		dummy= GetRTError(1)	// to clear the error in case start has not been pressed
	endif

	return 0
End

Function ButtonProc(ctrlName) : ButtonControl
	String ctrlName
	strswitch(ctrlName)	// string switch
		case "ResetButton":		// execute if case matches expression
			CheckTestPulse()
			break						// exit from switch
		case "FitButton":		// execute if case matches expression
			TPFitTransient()
			break
	endswitch
//	if ( cmpstr(ctrlName,"ResetButton")==0 )
//		CheckTestPulse()
//	endif
End


Window TestPulseGraph() : Graph
	PauseUpdate		// building window...
	Silent 1
	String df = TestPulseDF()
	// Make sure we always start in VC
	$(df+"ClampMode")="VC"
	Variable LocalADCRange =  $(df+"ADCRange")
	Variable LocalWaveLength =  $(df+"WaveLength")
		 
	Display /W=(523,444,1327,929) $(df+"testpulsein")
	
	ModifyGraph grid=1
	ModifyGraph minor=1
	ModifyGraph axOffset(left)=-1.57143,axOffset(bottom)=0.2
	ControlBar 112
	NewPanel/W=(0.2,0.2,0.8,0)/FG=(FL,FT,GR,)/HOST=# 
	SetDrawLayer UserBack
	SetDrawEnv textxjust= 1
	DrawText 400,31,"Pulse Rate /Hz"
//	SetDrawEnv textxjust= 1, fsize=10
//	DrawText 400,82,"Test Pulse /mV or pA"
	Button StartButton,pos={15,14},size={45,20},proc=StartButton,title="start"
	Button ResetButton,pos={65,14},size={45,20},proc=ButtonProc,title="reset"
	Button FitButton,pos={115,14},size={45,20},proc=ButtonProc,title="Fit"

	SetVariable AcqChannel,pos={200,44},size={90,15},title="ADC Channel"
	SetVariable AcqChannel,help={"Sets the channel from which the seal test response is read."}
	SetVariable AcqChannel,limits={0,7,1},value= root:Packages:TestPulse:ADCChannel

	CheckBox GraphModeBox,pos={200,75},size={79,14},proc=ModePop,title="Fast Graphing"
	CheckBox GraphModeBox,help={"When checked the graph uses a special fast mode - among other things it does not autoscale"}
	CheckBox GraphModeBox,value= 0

	CheckBox AxisScaleBox,pos={200,60},size={79,14},proc=AxisScalePop,title="Full Range"
	CheckBox AxisScaleBox,help={"When checked the graph will change to a full scale range of -100 to +20 mV"}
	CheckBox AxisScaleBox,value= 0

	CheckBox AcqModeBox,pos={200,90},size={121,14},title="Demo Acquisition Mode"
	CheckBox AcqModeBox,help={"When checked the test pulse displays fake data rather than trying to query the ITC interface"}
	CheckBox AcqModeBox,variable= root:Packages:TestPulse:AcqMode

	CheckBox PulseOnBox, pos={350,60},size={95,14},fSize=10,title="Pulse /mV or pA"; DelayUpdate
	CheckBox PulseOnBox,help={"When unchecked the test pulse is not to sent the amplifier "}
	CheckBox PulseOnBox,variable= root:Packages:TestPulse:PulseOn
	
	Slider pulserate,pos={455,16},size={200,45},proc=SliderProc,fSize=9
	Slider pulserate,limits={0,30,1},variable= $(df+"tryFPS"),live= 0,vert= 0,ticks= 30
	Slider TestPulseSlider,pos={455,61},size={200,45},proc=SliderProc,fSize=9
	Slider TestPulseSlider,limits={-20,20,1},variable= $(df+"TestPulseSize"),vert= 0,ticks= 25
	
	
	ValDisplay vd1,pos={24,51},size={150,14},title="Actual F/S"
	ValDisplay vd1,limits={0,30,0},barmisc={0,40},value= root:Packages:TestPulse:fps
	PopupMenu b5,pos={16,81},size={125,20},proc=SizePop,title="Wave length:"
	PopupMenu b5,mode=3,popvalue=num2str(LocalWaveLength),value= #"\"100;300;500;1000;5000;10000\""

	PopupMenu adcrange,pos={675,17},size={94,20},proc=ADCPop,title="ADC Range"
	PopupMenu adcrange,mode=3,popvalue= num2str(LocalADCRange),value= "1;2;5;10", help={"Range of ITC ADC converter default = +/- 10.24 V => 312.5µV resolution"}

	PopupMenu ClampMode,pos={675,47},size={94,20},proc=CMPop,title="Clamp Mode"
	PopupMenu ClampMode,mode=3,popvalue="VC",value= "VC;IC", help={"Amplifier Mode - either Voltage Clamp or Current Clamp"}

	PopupMenu Amplifier,pos={675,77},size={94,20},proc=AmplifierPop,title="Amplifier"
	PopupMenu Amplifier,mode=3,popvalue="AM2400",value= "AM2400;Axoclamp;Multiclamp", help={"Choose the Amplifier"}

	ValDisplay valdisp0,pos={175,13},size={151,24},title="R /M½",fSize=18
	ValDisplay valdisp0,format="%07.2f",frame=2
	ValDisplay valdisp0,limits={0,1000,0},barmisc={0,200},bodyWidth= 92
	ValDisplay valdisp0,value= #"root:Packages:TestPulse:resistance"
	RenameWindow #,PTop
	SetActiveSubwindow ##
EndMacro

Window TPSweeperGraph() : Graph
	PauseUpdate; Silent 1		// building window...
	String df = TestPulseDF()
	Display /W=(12,44,984,392) $(df+"SweeperSampWave")
EndMacro

Function TPSweeperWriteSingleChunk(outwavename,offset,chunkSize,scaleFactor)
	// nb ChunkNum starts at 0
	String outwavename
	Variable offset,chunkSize,scaleFactor
	Wave outwave=$(outwavename)
	String df = TestPulseDF()
	Wave Avail2Write=$(df+"Avail2Write")

	if(chunkSize<=0)
		return 0
	endif
	
	Execute "ITC18WriteAvailable "+df+"Avail2Write"
	if(Avail2Write[0]>=chunkSize)
		make /o /n=(chunkSize) $(df+"gjtmpChunk")
		Wave gjtmpChunk=$(df+"gjtmpChunk")
		gjtmpChunk=(outwave[p+offset])*scaleFactor
		Execute "ITC18StimAppend "+df+"gjtmpChunk" 
		return chunkSize
	endif
	return 0
End

Function TPSweeperReadSingleChunk(inwavename,offset,chunkSize,scaleFactor)
	String inwavename
	Variable offset,chunkSize,scaleFactor
	Wave inwave=$(inwavename)
	String df = TestPulseDF()
	Wave Avail2Read=$(df+"Avail2Read")
	
	if(chunkSize<=0)
		return 0
	endif

	Execute "ITC18ReadAvailable "+df+"Avail2Read"
	
	if(Avail2Read[0]>=chunkSize)
		make /o /n=(chunkSize) $(df+"gjtmpChunk")
		Wave gjtmpChunk=$(df+"gjtmpChunk")
		Execute "ITC18SampAppend "+df+"gjtmpChunk"
				
		inwave[offset,offset+chunkSize-1] = (gjtmpChunk[p-offset])*scaleFactor
		return chunkSize
	endif
	return 0
End
Function TPFitTransient ()
	// Function to fit first transient of current test pulse sweep
	String df = TestPulseDF()

	// don't print commands to the command line
	silent 1									
	Wave testpulsein= $(df+"testpulsein")
	PauseUpdate
	
	NVAR tps = $(df +"TestPulseSize")
	Variable cfitStart,cfitEnd,pulseStart,pulseEnd,pulseLastFifthStart;

	switch(numpnts(testpulsein))	// numeric switch
		case 1000:		// execute if case matches expression
			cfitStart=260;cfitEnd=749
			// nick trying to move over a bit
			//cfitStart=253;cfitEnd=749;
			pulseStart=2.5e-3 //ie 2.5 ms
			break						// exit from switch
		case 5000:		// execute if case matches expression
			cfitStart=1267;cfitEnd=3749
			//cfitStart=1255;cfitEnd=3749;
			pulseStart=12.5e-3 //ie 12.5 ms
			break
		default:							// optional default expression executed
			print "Must use wave of length 1000 or 5000"
			return -1					// when no case matches
	endswitch
	pulseEnd=pulseStart*3
	pulseLastFifthStart=pulseStart+4/5*(pulseEnd-pulseStart)
	
	Variable V_fitOptions = 4	// suppress progress window
	Variable V_FitError = 0	// prevent abort on error

//	CurveFit /N /Q exp_XOffset  testpulsein[cfitStart,cfitEnd] /D 
	CurveFit /N /Q exp_XOffset  testpulsein[cfitStart,cfitEnd] /D 
	WAVE W_coef
	if (V_FitError == 0)
		Variable Q,tau,Cm,Ra;
		tau=W_coef[2]
		// Assume that the last 1/5 of pulse just corresponds to Rm step
	      Q=area(testpulsein,pulseStart,pulseEnd)- area(testpulsein,pulseLastFifthStart,pulseEnd)*5
		// NB TestPulseSize will be in mV, so convert to V
		Cm=Q/(tps*1e-3)
		Ra=tau/Cm
		printf "tau= %f ms; Q = %g pC; Cm = %g pF; Ra = %g MOhm\r", tau*1000, Q*1e12,  Cm*1e12, Ra*1e-6
		// Don't actually know how to prevent the fitted wave from being added to graph
		ModifyGraph rgb(fit_testpulsein)=(2,39321,1)
	else
		print "Fitting error!"
	endif
End
Function TPSingleSweep(timestep,maxChunkSize)
	Variable timestep,maxChunkSize
	Variable nTicks=round(timestep/1.25e-6)
	Variable chunkSize

	Variable writeOffset=0,readOffset=0, bytesWritten=-1,bytesRead=-1
	
	// These are defined as what you have to multiply samp wave to get data wave
	// and what you have to mutlply cmd wave to get stim wave 
	Variable rScaleFactor=1/3200,wScaleFactor=3200
	
	String df = TestPulseDF()
	Wave  SweeperStimWave=$(df+"SweeperStimWave")
	Wave  SweeperSampWave=$(df+"SweeperSampWave")
	
	chunkSize=min(maxChunkSize,numpnts(SweeperSampWave))
	CheckNMWave(df+"outwave",chunkSize,0)
	Wave outwave =$(df+"outwave")
	outwave=SweeperStimWave  // nb this will truncate longoutwave if reqd
		
	SweeperSampWave=NaN; DoUpdate
	
	Execute "ITC18Stim "+df+"outwave"    // load first chunk of stim
	writeOffset+=maxChunkSize
	
	if(0)
	do // Preload stim wave until there's nothing left or the FIFO's full
		chunkSize=min(maxChunkSize,numpnts(SweeperStimWave)-writeOffset)
		printf "writeOffset = %d; chunkSize = %d\r", writeOffset, chunkSize
		bytesWritten=TPSweeperWriteSingleChunk(df+"SweeperStimWave",writeOffset,chunkSize,wScaleFactor)
		writeOffset+=bytesWritten
	while (writeOffset<numpnts(SweeperStimWave) && bytesWritten!=0)
	endif
	
	Variable startTicks=ticks
	Execute "ITC18StartAcq "+num2str(nTicks)+",2,0"   // start acquisition, 100 microsecond sampling 

	do // Stim and Samp when possible until exhausted 

		chunkSize=min(maxChunkSize,numpnts(SweeperStimWave)-writeOffset)
		writeOffset+=TPSweeperWriteSingleChunk(df+"SweeperStimWave",writeOffset,chunkSize,wScaleFactor)

		chunkSize=min(maxChunkSize,numpnts(SweeperSampWave)-readOffset)
		bytesRead=TPSweeperReadSingleChunk(df+"SweeperSampWave",readOffset,chunkSize,rScaleFactor)
		
		if(bytesRead>0)
			if(readOffset==0)
				// The first 3 values will be bogus because of the pipeline delay
				SweeperSampWave[1,3]=NaN
			endif
			readOffset+=bytesRead
			DoUpdate
		endif
		
	while (writeOffset<numpnts(SweeperStimWave)  || readOffset<numpnts(SweeperSampWave) )

	Execute "ITC18StopAcq"    // terminate acquisition 	
	printf  "%f, ",(ticks-startTicks)/60.15
End

Function TPSweepStart()
	Execute "ITC18seq \"0\",\"0\""		                    		// 1 DAC and 1 ADC. First string is DACs. 2nd string is ADCs
	
	String df = TestPulseDF()
	
	NVAR SweeperTimeStep=$(df+"SweeperTimeStep")

	Variable chunkSize=max(0.25/SweeperTimeStep, 1000)

	CheckNMvar(df+"SweeperWindow", 5) // create variable (also see Configurations.ipf)
	NVAR SweeperWindow=$(df+"SweeperWindow")
	CheckNMvar(df+"SweeperTimeStep",200e-6)
	NVAR SweeperTimeStep=$(df+"SweeperTimeStep")
	CheckNMWave(df+"SweeperStimWave",SweeperWindow/SweeperTimeStep,0)
	CheckNMWave(df+"SweeperSampWave",SweeperWindow/SweeperTimeStep,0)

	Wave  SweeperStimWave=$(df+"SweeperStimWave")
	Wave  SweeperSampWave=$(df+"SweeperSampWave")	
	SetScale/P x 0,(SweeperTimeStep),"s", SweeperStimWave,SweeperSampWave
	
	make /n=1 /o /I $(df+"Avail2Read"),$(df+"Avail2Write")

	//longoutwave[1000,6000] = 1  // create data points

	do 
		//startTicks=ticks
		TPSingleSweep(SweeperTimeStep,chunkSize)
		//print (ticks-startTicks)/60.15
	while(1)
	Execute "ITC18StopAcq"
EndMacro