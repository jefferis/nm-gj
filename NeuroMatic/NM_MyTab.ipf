#pragma rtGlobals = 1
#pragma IgorVersion = 4
#pragma version = 1.86

//****************************************************************
//****************************************************************
//****************************************************************
//
//	NeuroMatic MyTab Demo Tab
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

Function /S MyTabPrefix(varName) // tab prefix identifier
	String varName
	
	return "MY_" + varName
	
End // MyTabPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S MyTabDF() // package full-path folder name

	return PackDF("MyTab")
	
End // MyTabDF

//****************************************************************
//****************************************************************
//****************************************************************

Function MyTab(enable)
	Variable enable // (0) disable (1) enable tab
	
	if (enable == 1)
		CheckPackage("MyTab", 0) // declare globals if necessary
		MakeMyTab() // create tab controls if necessary
		AutoMyTab()
	endif

End // MyTab

//****************************************************************
//****************************************************************
//****************************************************************

Function AutoMyTab()

// put a function here that runs each time CurrentWave number has been incremented 
// see "AutoSpike" for example

End // AutoMyTab

//****************************************************************
//****************************************************************
//****************************************************************

Function KillMyTab(what)
	String what
	String df = MyTabDF()

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

End // KillMyTab

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckMyTab() // declare global variables

	String df = MyTabDF()
	
	if (DataFolderExists(df) == 0)
		return -1 // folder doesnt exist
	endif
	
	CheckNMvar(df+"MyVar", 33) // create variable (also see Configurations.ipf)
	
	CheckNMstr(df+"MyStr", "Anything") // create string
	
	CheckNMwave(df+"MyWave", 5, 22) // numeric wave
	
	CheckNMtwave(df+"MyText", 5, "Anything") // text wave
	
	return 0
	
End // CheckMyTab
	
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeMyTab() // create controls that will begin with appropriate prefix

	Variable x0 = 60, y0 = 250, xinc, yinc = 60
	
	String df = MyTabDF()

	ControlInfo /W=NMPanel $MyTabPrefix("Function0") // check first in a list of controls
	
	if (V_Flag != 0)
		return 0 // tab controls exist, return here
	endif

	DoWindow /F NMPanel
	
	Button $MyTabPrefix("Function0"), pos={x0,y0+0*yinc}, title="Your button can go here", size={200,20}, proc=MyTabButton
	Button $MyTabPrefix("Demo"), pos={x0,y0+1*yinc}, title="Demo Function", size={200,20}, proc=MyTabButton
	Button $MyTabPrefix("Function1"), pos={x0,y0+2*yinc}, title="My Function 1", size={200,20}, proc=MyTabButton
	Button $MyTabPrefix("Function2"), pos={x0,y0+3*yinc}, title="My Function 2", size={200,20}, proc=MyTabButton
	
	SetVariable $MyTabPrefix("Function3"), title="my variable", pos={x0,y0+4*yinc}, size={200,50}, limits={-inf,inf,1}
	SetVariable $MyTabPrefix("Function3"), value=$(df+"MyVar"), proc=MyTabSetVariable

End // MakeMyTab

//****************************************************************
//****************************************************************
//****************************************************************

Function MyTabButton(ctrlName) : ButtonControl
	String ctrlName
	
	String fxn = NMCtrlName(MyTabPrefix(""), ctrlName)
	
	MyTabCall(fxn, "")
	
End // MyTabButton

//****************************************************************
//****************************************************************
//****************************************************************

Function MyTabSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String fxn = NMCtrlName(MyTabPrefix(""), ctrlName)
	
	MyTabCall(fxn, varStr)
	
End // MyTabSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function MyTabCall(fxn, select)
	String fxn // function name
	String select // parameter string variable
	
	Variable snum = str2num(select) // parameter variable number
	
	strswitch(fxn)
	
		case "Demo":
			return NMMainLoop() // see NM_MainTab.ipf
	
		case "Function0":
			return MyFunction0()
			
		case "Function1":
			return MyFunction1()
			
		case "Function2":
			return MyFunction2()
			
		case "Function3":
			return MyFunction3(select)

	endswitch
	
End // MyTabCall

//****************************************************************
//****************************************************************
//****************************************************************

Function MyFunction0()

	String df = MyTabDF()

	DoAlert 0, "Your macro can be run here."
	
	NVAR MyVar = $(df+"MyVar")
	SVAR MyStr = $(df+"MyStr")
	
	Wave MyWave = $(df+"MyWave")
	Wave /T MyText = $(df+"MyText")

End // MyFunction0

//****************************************************************
//****************************************************************
//****************************************************************

Function MyFunction1()

	Print "My Function 1"

End // MyFunction1

//****************************************************************
//****************************************************************
//****************************************************************

Function MyFunction2()

	Print "My Function 2"

End // MyFunction2

//****************************************************************
//****************************************************************
//****************************************************************

Function MyFunction3(select)
	String select

	Print "You entered : " + select

End // MyFunction3

//****************************************************************
//****************************************************************
//****************************************************************
