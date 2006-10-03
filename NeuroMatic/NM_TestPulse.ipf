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

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckTestPulse() // declare global variables

	String df = TestPulseDF()
	
	if (DataFolderExists(df) == 0)
		return -1 // folder doesnt exist
	endif
	
	// Check to see if ITC is active:
	make/I /O devices
	Execute /Z "ITC18GetDevices devices"
	// will be non zero if there is a problem accessing the ITC
	SetNMvar(df+"AcqMode",V_Flag) // set variable (also see Configurations.ipf)
	
	// Create Global variables and waves
	CheckNMvar(df+"TestPulseSize", -10) // create variable (also see Configurations.ipf)
	CheckNMvar(df+"resistance",0) // create variable (also see Configurations.ipf)

	CheckNMvar(df+"ADCRange",10) // create variable (also see Configurations.ipf)
	
	CheckNMvar(df+"fps", 0) // create variable (also see Configurations.ipf)
	CheckNMvar(df+"tryFPS",15) // create variable (also see Configurations.ipf)
	CheckNMvar(df+"nticksLast",ticks) // create variable (also see Configurations.ipf)
		
	CheckNMwave(df+"testpulseout", 500, 0) // numeric wave
	CheckNMwave(df+"testpulsein", 500, 0) // numeric wave
	CheckNMwave(df+"itcout", 500, 0) // numeric wave
	CheckNMwave(df+"itcin", 500, 0) // numeric wave
	
	SetScale/P x 0,1e-5,"s", $(df+"testpulsein"), $(df+"testpulseout")
	SetScale d 0,0,"A", $(df+"testpulsein")
	SetScale d 0,0,"V", $(df+"testpulseout")

	
	CheckNMtwave(df+"MyText", 5, "Anything") // text wave
	
	return 0
	
End // CheckTestPulse
	
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeTestPulse() // create controls that will begin with appropriate prefix

	Variable x0 = 60, y0 = 250, xinc, yinc = 60
	
	String df = TestPulseDF()

	ControlInfo /W=NMPanel $TestPulsePrefix("Function0") // check first in a list of controls
	
	if (V_Flag != 0)
		return 0 // tab controls exist, return here
	endif

	DoWindow /F NMPanel
	
	Button $TestPulsePrefix("MakeTPGraph"), pos={x0,y0+0*yinc}, title="Test Pulse Graph", size={200,20}, proc=TestPulseButton
	Button $TestPulsePrefix("Demo"), pos={x0,y0+1*yinc}, title="Macro TP Setup", size={200,20}, proc=TestPulseButton
	Button $TestPulsePrefix("Function1"), pos={x0,y0+2*yinc}, title="Test Pulse", size={200,20}, proc=TestPulseButton
	Button $TestPulsePrefix("Function2"), pos={x0,y0+3*yinc}, title="Macro TestPulse", size={200,20}, proc=TestPulseButton
	
	SetVariable $TestPulsePrefix("Function3"), title="Test Pulse /mV", pos={x0,y0+4*yinc}, size={120,50}, limits={-50,50,1}
	SetVariable $TestPulsePrefix("Function3"), value=$(df+"TestPulseSize"), proc=TestPulseSetVariable

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
	
	Variable snum = str2num(select) // parameter variable number
	
	strswitch(fxn)
	
		case "MakeTPGraph":
			Execute "TestPulseGraph()"
			return 0
			//return NMMainLoop() // see NM_MainTab.ipf

	endswitch
	
End // TestPulseCall


//****************************************************************
//****************************************************************
//****************************************************************

Function SingleAcq()
	String df = TestPulseDF()

	silent 1									// don't print commands to the command line
	Wave testpulseout=$(df+"testpulseout"), testpulsein= $(df+"testpulsein"), itcout=$(df+"itcout"),itcin=$(df+"itcin")
	PauseUpdate
	
	NVAR tps = $(df +"TestPulseSize")
	NVAR resistance = $(df +"resistance")
	NVAR AcqMode = $(df+"AcqMode")
	NVAR ADCRange = $(df+"ADCRange")
	Variable lev=tps*1e-3
	
	testpulseout=0
	testpulseout[numpnts(testpulseout)/4,3*numpnts(testpulseout)/4]=lev
	Variable AM2400ExternalGain50=50
	Variable probeGainLowAmps= 100e-3*1e9 // 100*1e9 mV/A probe gain 
	itcout=testpulseout*AM2400ExternalGain50*3200
	Variable AcqFailed=0
	try
		if(AcqMode==0)
			Execute /Z "ITC18seq \"0\",\"0\""		                    		// 1 DAC and 1 ADC. First string is DACs. 2nd string is ADCs
			AbortOnValue V_Flag!=0,0
		
			Execute /Z  "ITC18StimandSample "+df+"itcout, "+df+"itcin,"+ num2str(8)+", 2, 0"	// load output data, start acquisition for 10 microsecond sampling and stop
			// NB ADCRange must be factored in 
			testpulsein=itcin/(3200*probeGainLowAmps)*	ADCRange/10	// scale data into volts	
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
		
	Variable I1,I2
	I2=mean(testpulsein,pnt2x(testpulsein,1.5*numpnts(testpulsein)/4),pnt2x(testpulsein,2.5*numpnts(testpulsein)/4))
	I1=mean(testpulsein,0,pnt2x(testpulsein,1*numpnts(testpulsein)/4))
	resistance=lev/(I2-I1)/1e6
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
	Variable checked			// 1 if selelcted, 0 if not

	ModifyGraph live(testpulsein)= checked
End

Function SizePop(theTag,value,item) : PopupMenuControl
	String theTag,item
	Variable value

	String df = TestPulseDF()
	Wave testpulseout=$(df+"testpulseout"), testpulsein= $(df+"testpulsein"), itcout=$(df+"itcout"),itcin=$(df+"itcin")

	Make tdata={100,300,500,1000,10000}
	Redimension/N=(tdata[value-1]) testpulsein,testpulseout,itcin,itcout
	KillWaves tdata
	SetScale/P x 0,0.01,"ms", testpulsein,testpulseout
End

Function ADCPop(theTag,value,item) : PopupMenuControl
	String theTag,item
	Variable value

	String df = TestPulseDF()
	NVAR ADCRange = $(df+"ADCRange")
	NVAR AcqMode = $(df+"AcqMode")
	
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
			Execute /Z "ITC18SetADCRange 0,"+num2str(ADCRange)		                    		// 1 DAC and 1 ADC. First string is DACs. 2nd string is ADCs
			AbortOnValue V_Flag!=0,0
		endif	
	catch
		print "Caught Acq Exception"
	endtry

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
	print tryFPS
	if( cmpstr(theTag,"StartButton")==0 )
		Button $theTag,rename=StopButton,title="stop"
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
	if( cmpstr(ctrlName,"ResetButton")==0 )
		CheckTestPulse()
	endif

End


Window TestPulseGraph() : Graph
	PauseUpdate		// building window...
	Silent 1
	String df = TestPulseDF()

	Display /W=(523,444,1327,929) $(df+"testpulsein")

	ModifyGraph grid=1
	ModifyGraph minor=1
	ModifyGraph axOffset(left)=-3.57143,axOffset(bottom)=3.93333
	ControlBar 112
	NewPanel/W=(0.2,0.2,0.8,0)/FG=(FL,FT,GR,)/HOST=# 
	SetDrawLayer UserBack
	SetDrawEnv textxjust= 1
	DrawText 400,31,"Pulse Rate /Hz"
	SetDrawEnv textxjust= 1
	DrawText 400,82,"Test Pulse /mV"
	Button StartButton,pos={25,14},size={50,20},proc=StartButton,title="start"
	Button ResetButton,pos={90,14},size={50,20},proc=ButtonProc,title="reset"

	CheckBox GraphModeBox,pos={200,75},size={79,14},proc=ModePop,title="Fast Graphing"
	CheckBox GraphModeBox,help={"When checked the graph uses a special fast mode - among other things it does not autoscale"}
	CheckBox GraphModeBox,value= 0

	Slider pulserate,pos={455,16},size={200,45},proc=SliderProc,fSize=9
	Slider pulserate,limits={0,30,1},variable= $(df+"tryFPS"),live= 0,vert= 0,ticks= 30
	Slider TestPulseSlider,pos={455,61},size={200,45},proc=SliderProc,fSize=9
//	Slider TestPulseSlider,pos={385,61},size={200,45},proc=SliderProc,fSize=9
	Slider TestPulseSlider,limits={-20,20,1},variable= $(df+"TestPulseSize"),vert= 0,ticks= 25
	
	
	CheckBox AcqModeBox,pos={200,90},size={121,14},title="Demo Acquisition Mode"
	CheckBox AcqModeBox,help={"When checked the test pulse displays fake data rather than trying to query the ITC interface"}
	CheckBox AcqModeBox,variable= root:Packages:TestPulse:AcqMode
	
	ValDisplay vd1,pos={24,51},size={225,14},title="Actual F/S"
	ValDisplay vd1,limits={0,30,0},barmisc={0,40},value= root:Packages:TestPulse:fps
	PopupMenu b5,pos={16,81},size={125,20},proc=SizePop,title="Wave size:"
	PopupMenu b5,mode=3,popvalue="Std 500",value= #"\"Short 100;Medium 300;Std 500;Long 1000;longer 10000\""

	PopupMenu adcrange,pos={686,17},size={94,20},proc=ADCPop,title="ADC Range"
	PopupMenu adcrange,mode=3,popvalue="10",value= "1;2;5;10", help={"Range of ITC ADC converter default = +/- 10.24 V => 312.5µV resolution"}

	ValDisplay valdisp0,pos={173,13},size={151,24},title="R /M½",fSize=18
	ValDisplay valdisp0,format="%07.2f",frame=2
	ValDisplay valdisp0,limits={0,1000,0},barmisc={0,200},bodyWidth= 92
	ValDisplay valdisp0,value= #"root:Packages:TestPulse:resistance"
	RenameWindow #,PTop
	SetActiveSubwindow ##
EndMacro

