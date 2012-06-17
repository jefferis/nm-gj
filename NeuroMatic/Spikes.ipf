#pragma rtGlobals=1		// Use modern global access method.
Function SetupSpikes()
	ChanSmthNum( 0 , 20 )
	ChanFunc( 0 , 2 )
	ChanAutoScale( 0 , 0 )
	NMTab( "Spike" )
End

// RunSpikes
// Ask for threshold
// Hit All Waves

// Do all the stuff for spikes assuming that you have already
// run this semi-manually for at least one pxp file for this cell
Function RunSpikesAuto()
	SetupSpikes()
	SpikeAllWavesCall()
	SaveSpikes()
End

// SaveSpikes
// figure out name of current folder
// find sequence number of folder (eg 001)
// find path of folder on disk
// save root:nm20120322c1_002:SP_RX_RAll_A0 and root:nm20120322c1_002:SP_RY_RAll_A0
// String savDF= GetDataFolder(0)
Function SaveSpikes()
	String currentDF= GetDataFolder(0)
	String regexp = "(nm.*)_([[:digit:]]+)"
	String foldername, pxpname
	SplitString /E=(regExp) currentDF, foldername, pxpname
	String spikefilename = pxpname+"_SP_RX_RAll_A0++.txt"
	Save/G/W SP_RX_RAll_A0,SP_RY_RAll_A0 as spikefilename
End

Function HelpSpikes()
	BrowseUrl("http://flybrain.mrc-lmb.cam.ac.uk/dokuwiki/doku.php?id=protocols:analysing_spikes#Automating_Spike_Finding")
End

Menu "Macros"
"Setup Spikes", SetupSpikes()
"Save Spikes", SaveSpikes()
"Run Spikes Auto", RunSpikesAuto()
"Spikes Help", HelpSpikes()
End