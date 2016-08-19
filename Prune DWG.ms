/*
[INFO]

NAME = Prune DWG
VERSION = 1.0.3
AUTHOR = MastaMan
DEV = ViscoCG
HELP = https://sightline-vision.github.io/Prune-DWG/

[1.0.0]

* First release =

[ABOUT]

This script helps to clean dwg after import in 3Ds Max.=

Features:=
- Create layers=
- Create groups=
- Attach by colors=
- Remove Mesh=
- Convert VIZBlock to Splines=
- Attach by color=


[TEST]


[SCRIPT]

*/



try(closeRolloutFloater fPruneDWG)catch()
global fPruneDWG = newRolloutFloater "Prune DWG" 250 370
	
fn getScriptInfo s releaseInfo: "" =
(		
	if(releaseInfo != "") do
	(
		r = getINISetting s releaseInfo
		return r
	)
	
	v = getINISetting s "INFO" "VERSION"
	a = getINISetting s "INFO" "AUTHOR"
	n = getINISetting s "INFO" "NAME"
	o = getINISetting s "ABOUT"
	c = getINISetting s "INFO" "DEV"
	h = getINISetting s "INFO" "HELP"
	
	r = for i in (getINISetting s) where i != "ABOUT" and i != "SCRIPT" and i != "COPY" collect i
	
	return #(n, a, v, o, r, c, h)
)

fn writeFile f s =
(			
	f = createFile f mode: "wt"

	format(s as string) to:f

	flush f
	close f
)

fn parseIniLine m = 
(
	if(m.count == 0) do return ""
	
	l = ""	

	try
	(
		for i in m do 
		(	
			if(i[1] == "_") do 
			(
				l += "_______________________________________\r\n\r\n" 
				continue
			)
			if(i[1] == "@") do 
			(
				l += "\r\n"
				continue
			)
			
			l += i + "\r\n"
		)
	) catch()
	return l
)

fn useSettings k p w =
(	
	d = getFilenamePath  (getThisScriptFilename())
	n = filenameFromPath (getThisScriptFilename())			
	settingsFile = d + @"ini\" + (sysInfo.username) + "_" + n + ".ini"
	szUser = sysInfo.computername
	case w of
	(
		"r":
		(
			s = getINISetting settingsFile szUser k
			case p of
			(
				"int": return s as integer
				"float": return s as float
				"bool": if s == "true" then true else false
				default: return s
			)
		)
		default: return setINISetting settingsFile szUser k (p as string)
	)
)


fn validObj o = o != undefined and not isDeleted o and isValidNode o and superClassOf o == Shape

fn freezeUi =
(
  	source = ""
  	source += "using System;\n"
  	source += "using System.Runtime.InteropServices;\n"
  	source += "class WindowsGhosting\n"
  	source += "{\n"
  	source += " [DllImport(\"user32.dll\")]\n"
  	source += " public static extern void DisableProcessWindowsGhosting();\n"
  	source += "}\n"
  
  	csharpProvider = dotnetobject "Microsoft.CSharp.CSharpCodeProvider"
  	compilerParams = dotnetobject "System.CodeDom.Compiler.CompilerParameters"
  
  	compilerParams.GenerateInMemory = on
  	compilerResults = csharpProvider.CompileAssemblyFromSource compilerParams #(source)
  
  	assembly = compilerResults.CompiledAssembly
  	windowsGhosting = assembly.CreateInstance "WindowsGhosting"
  	windowsGhosting.DisableProcessWindowsGhosting()
)

rollout rPruneSettings "Options" 
(
	group "Prune DWG Options"
	(			
		dotNetControl _tbTextBox "System.Windows.Forms.TextBox" width: 210
		
		checkbox _chkBox1 "Create Layer:"  width:125 height:18 checked:true across: 2 align: #left tooltip: "Moves all selected dwg's in to separate layer." offset: [0, 10] 
		dotNetControl _lblStatus1 "System.Windows.Forms.label" width:72  align: #right offset: [0, 10]
		
		checkbox _chkBox2 "Unlink Objects:"  width:125 height:18 checked:true across: 2 align: #left tooltip: "Removes all dependences and links for selected dwg's."
		dotNetControl _lblStatus2 "System.Windows.Forms.label" width:72  align: #right 
		
		checkbox _chkBox3 "Convet to Splines:"  width:125 height:18 checked:true across: 2 align: #left tooltip: "Converts all dwg's to \"Spline Shape\".\n\nThis option also converts VIZBlock to \"Spline Shape\".\n\nNote:\nIf it option disabled all VIZBlocks will be deleted!"
		dotNetControl _lblStatus3 "System.Windows.Forms.label" width:72  align: #right 
		
		checkbox _chkBox4 "Clear Invalid Objects:"  width:125 height:18 checked:true across: 2 align: #left tooltip: "Removes all \"CompositeLink\", \"Mesh\", \"VIZBlock\" and etc. invalid objects for selected dwg's."
		dotNetControl _lblStatus4 "System.Windows.Forms.label" width:72  align: #right 
		
		checkbox _chkBox5 "Delete Empty Layers:"  width:125 height:18 checked:true across: 2 align: #left tooltip: "Removes all the layers in which there are no objects."
		dotNetControl _lblStatus5 "System.Windows.Forms.label" width:72  align: #right 
		
		checkbox _chkBox6 "Attach By Color:"  width:125 height:18 checked:true across: 2 align: #left tooltip: "Attaches all dwg's depending on the color.\n\nA large number of splines is hanging scene.\nThis option will help to simplify the drawings.\n\n*WARNING*:\nIf you selected more then 1000 items, this operation may take some time, chillout ;)..."
		dotNetControl _lblStatus6 "System.Windows.Forms.label" width:72  align: #right 
		
		checkbox _chkBox7 "Flatten:"  width:125 height:18 checked:true across: 2 align: #left tooltip: "This option helps make drawings flat on Z axis."
		dotNetControl _lblStatus7 "System.Windows.Forms.label" width:72  align: #right 
		
		checkbox _chkBox8 "Rename:"  width:125 height:18 checked:true across: 2 align: #left tooltip: "Renames all selected dwg's."
		dotNetControl _lblStatus8 "System.Windows.Forms.label" width:72  align: #right 
		
		checkbox _chkBox9 "Make Group:"  width:125 height:18 checked:true across: 2 align: #left tooltip: "Creates group for selected dwg's.\n\nThe group will be created in \"default (0)\" layer."
		dotNetControl _lblStatus9 "System.Windows.Forms.label" width:72  align: #right 
		
		
		button _btnStart "Start" width:210 height:32 offset: [0, 10]
	)
		
	timer tmrPrune "" interval: 10 active: false
	timer tmrAttach "" interval: 300 active: false
	timer tmrAttachNode "" interval: 100 active: false
		
	global objByColors = #()
	
	global hLabels = #(
		"_lblStatus1",	
		"_lblStatus2",
		"_lblStatus3",	
		"_lblStatus4",	
		"_lblStatus5",	
		"_lblStatus6",	
		"_lblStatus7",	
		"_lblStatus8",
		"_lblStatus9"	
	)
	
	global iWindowPos = [0,0]	
	
	global _DISABLED = "DISABLED"
	global _OK = "OK"
	global _NOTFOUND = "NOT FOUND"
	global _EXIST = "EXIST"
	global _WAIT = "WAIT..."
	global _CLEARED = "CLEARED"
	global _CANCEL = "CANCEL"
	
	fn saveWindowPos =
	(
		useSettings "X"  iWindowPos[1] "w"
		useSettings "Y"  iWindowPos[2] "w"		
	)
	
	fn disableUI d =
	(
		for i in rPruneSettings.controls do i.enabled = d
	)
	
	fn getColor r g b = (dotnetclass "System.Drawing.Color").FromArgb r g b
	fn getControl c = for i in rPruneSettings.controls where matchPattern (i as string) pattern: ("*:" + c + ":*") do return i
		
	fn getBorderStyle s: #none =
	(
		d = dotnetclass "System.Windows.Forms.BorderStyle"
		i = case s of
		(
			#solid: d.Solid
			#fixed3d: d.Fixed3D	
			default: d.None	
		)
		
		return i
	)
	
	fn getBgColor = 
	(
		b = (colorman.getcolor #background) * 255
		c = getColor b[1] b[2] b[3]
		return c
	)
	
	fn getTextColor =
	(
		t = (colorMan.getColor #text) * 255
		c = getColor t[1] t[2] t[3]
		return c
	)
		
	fn createLabel lbl =
	(							
		lbl.BackColor = getBgColor()
		lbl.ForeColor = getTextColor()	
		
		lbl.BorderStyle = getBorderStyle s: #fixed3d
	)
	
	fn getFont s: #regular f: #arial fs: 8 =
	(
		d = dotnetclass "System.Drawing.FontStyle"
		i = case s of
		(
			#italic: d.Italic
			#bold: d.Bold
			default: d.Regular
		)
			
		z = case f of
		(
			#tahoma: "Tahoma"
			default: "Arial"
		)
		
		return dotnetobject "System.Drawing.Font" z fs i
	)
	
	fn lablelStatus lbl status: #wait = 
	(
		txt = ""
		bgColor = getColor 255 255 255 
		fgColor = getColor 0 0 0
		lbl.BorderStyle = getBorderStyle()
	
		lbl.Font =getFont f: #bold
		
		case status of
		(
			#disabled:
			(
				bgColor = getColor 183 183 183
				fgColor = getColor 67 67 67				
				txt = _DISABLED
			)
			#notfound:
			(
				bgColor = getColor 224 102 102
				fgColor = getColor 153 0 0
				txt = _NOTFOUND
			)
			#cancel:
			(
				bgColor = getColor 224 102 102
				fgColor = getColor 153 0 0
				txt = _CANCEL
			)
			#exist:
			(
				bgColor = getColor 255 229 153
				fgColor = getColor 215 144 0
				txt = _EXIST
			)
			#ok:
			(
				bgColor = getColor 147 196 125
				fgColor = getColor 56 118 79
				txt = _OK
			)
			#cleared:
			(
				bgColor = getColor 147 196 125
				fgColor = getColor 56 118 79
				
				txt = _CLEARED
			)
			#none:
			(
				txt = ""
				bgColor = getBgColor()
				fgColor = getTextColor()	
		
				lbl.BorderStyle = getBorderStyle s: #fixed3d
			)
			default:
			(
				bgColor = getColor 255 229 153
				fgColor = getColor 215 144 0
				txt = _WAIT
			)
		)
		
		lbl.BackColor = bgColor
		lbl.ForeColor = fgColor
		lbl.Text = txt
	)
	
	fn initDotNet disabled: false clr: false err: false = 
	(	
		bgColor = getBgColor()
		fgColor = getTextColor()	
		
		if(err) do 
		(
			bgColor = getColor 255 229 153
			fgColor = getColor 215 144 0
		)
		
				
		_tbTextBox.BackColor = bgColor
		_tbTextBox.ForeColor = fgColor

		_tbTextBox.Font = getFont s: #italic
		if(clr) do _tbTextBox.text  = "Enter DWG Name..."	
		
		s = case disabled of
		(
			true: #wait
			default: #none
		)
		
		for i in hLabels do lablelStatus (getControl i) status: s	
	)
	
	fn convertColor c =  (c as integer) as string
	
	fn AttachObj x c =
	(
		if(x.count < 2) do return 0
	
		global attachResult = 0
		sleep 0.1
		/*
		undo off
		(			
			j = 1
			t = 1
			while x.count > 1 do
			(											
				addAndWeld x[j] x[j+1] 0
				deleteItem x (j+1)
							
				j += 1
				t += 1
				
				progressUpdate (100.0 * t / total)
				if(getProgressCancel() == true)do exit	
				
				if (j + 1) > x.count then j = 1  				
			)
		)*/
		
		o = x[1]
		
		r = convertColor c.r
		g = convertColor c.g
		b = convertColor c.b
		
		m = "Attach By R:" + r + " G:" +g + " B:" + b
		progressStart m
		escapeEnable
				
		
		global attachObjs = x

		fn startAttach =
		(
			pause = 0
			undo off
			(
				for i in attachObjs.count to 2 by -1 do
				(
					try(addAndWeld attachObjs[1] attachObjs[i] -1) catch()
				
					--deleteItem attachObjs i
				
					attachResult += 1
					pause += 1
					
					progressUpdate (100.0 * attachResult / attachObjs.count)
					if(getProgressCancel() == true) do exit		
					
					if(pause > 350) do 
					(						
						pause = 0
						exit
					)
				)
			)
		)
		
		
		startAttach()
		

		disableSceneRedraw()
				
		
		progressEnd()
		
		o.wirecolor = c
		o.pivot = o.center
		updateShape o
		
		enableSceneRedraw()	
			
		gc()
		
		return attachResult
	)
	
	global attObjCnt = 0
	
	fn attachByColor o =
	(
		if(not _chkBox6.checked) do 
		(
			lablelStatus _lblStatus6 status:#disabled
			return 0
		)
		
		lablelStatus _lblStatus6 status:#wait
		
		result = 0
		objColors = #()
		objByColors = #()
		
		for i in o where validObj i do appendIfUnique objColors i.wirecolor
		
		for i in 1 to o.count where validObj o[i] do
		(
			c = o[i].wirecolor
						
			for ii in 1 to objColors.count where objColors[ii] == c do 
			(
				if(objByColors[ii] == undefined) do objByColors[ii] = #()	
				append objByColors[ii] o[i]
			)
		)
					
		for i in 1 to objByColors.count do 
		(						
			result += AttachObj objByColors[i]	objColors[i]
		)
		
		attObjCnt += result
		
		enableSceneRedraw()		
		enableSceneRedraw()		
		enableSceneRedraw()		
		enableSceneRedraw()		
		enableSceneRedraw()		
		forceCompleteRedraw()
						
		case attObjCnt of
		(	
			0: lablelStatus _lblStatus6 status:#notfound
			default: lablelStatus _lblStatus6 status:#ok	
		)
		
		return result
	)
	
	-- CALL FIRST
	fn initalCall o =
	(	
		objColors = #()
		
		n = _tbTextBox.text
		
		for i in 1 to o.count  where validObj o[i] do
		(
			o[i].colorbylayer = false
				
			case of
			(
				(o[i].layer.wirecolor != white /*and o[i].layer.name != "0"*/ and o[i].layer.name[1] != "[") : o[i].wirecolor = o[i].layer.wirecolor 
				(o[i].wirecolor != white): o[i].wirecolor = o[i].wirecolor
				default: o[i].wirecolor = green
			)										
		)
	)
	
	fn moveToLayer o =
	(
		if(not _chkBox1.checked) do
		(
			lablelStatus _lblStatus1 status:#disabled
			return 0
		)
		
				
		lablelStatus _lblStatus1 status:#wait
		
		n = "[" + _tbTextBox.text + "]"
		
		layer = LayerManager.getLayerFromName n
		
		result = 0
		
		if(layer != undefined) then 
		(
			q = yesNoCancelBox "The layer with this name already exist!\nAdd to exist layer?" title: "Warning"
			lablelStatus _lblStatus1 status:#cancel
			if(q == #no) do return 0
			if(q == #cancel) do return -1
		)
		else
		(
			layer = Layermanager.newLayerFromName n
			result = 1
		)		
		
		progressStart ("Move To Layer: " + n)
		escapeEnable
		
		for i in 1 to o.count  do
		(
			if(validObj o[i]) do
			(
				layer.addnode o[i]										
			)
			
			progressUpdate (100.0 * i / o.count)
			if(getProgressCancel() == true) do exit	
		)
		
		case result of
		(
			0: lablelStatus _lblStatus1 status:#exist
			default: lablelStatus _lblStatus1 status:#ok
		)
			
		progressEnd()
		
		return result
	)
	
	fn unlinkObjects o =
	(
		if(not _chkBox2.checked) do 
		(
			lablelStatus _lblStatus2 status:#disabled
			return 0
		)
		
		lablelStatus _lblStatus2 status:#wait
		
		progressStart "Unlink Objects..."
		escapeEnable
				
		result = 0
		for i in 1 to o.count  do
		(
			if(validObj o[i] and o[i].parent != undefined and not isGroupHead o[i].parent) do
			(
				o[i].parent = undefined
				o[i].transform.controller = prs()
				result += 1
			)
			
			progressUpdate (100.0 * i / o.count)
			if(getProgressCancel() == true) do exit	
		)
		
		case result of
		(	
			0: lablelStatus _lblStatus2 status:#notfound
			default: lablelStatus _lblStatus2 status:#ok	
		)
		
		progressEnd()
		
		return result
	)
	
	fn convertToShape o =
	(
		
		if(not _chkBox3.checked) do 
		(
			lablelStatus _lblStatus3 status:#disabled
			return 0
		)
		
		lablelStatus _lblStatus3 status:#wait
		
		progressStart "Convert to Shape..."
		escapeEnable
				
		result = 0
		a = #()
		for i in 1 to o.count where validObj o[i] and classOf o[i]  != SplineShape and classOf o[i] == LinkCompositeshape and canConvertTo o[i] SplineShape do 
		(	
			append a o[i]
			
			result += 1
					
			progressUpdate (100.0 * i / o.count)
			if(getProgressCancel() == true) do exit	
		)
		
		convertToSplineShape a
		
		progressEnd()
		
		case result of
		(	
			0: lablelStatus _lblStatus3 status:#notfound
			default: lablelStatus _lblStatus3 status:#ok	
		)
		
		return result
	)
	
	global invalidObjCnt = 0
	
	fn deleteBadObjects o =
	(
		if(not _chkBox4.checked) do 
		(
			lablelStatus _lblStatus4 status:#disabled
			return 0
		)
		
		lablelStatus _lblStatus4 status:#wait
		
		progressStart "Delete Invald Objects..."
		escapeEnable
		
		result = 0
		
		badObjects = #()
		for i in 1 to o.count  do
		(
			if(o[i] != undefined and not isDeleted o[i] and classOf o[i] != SplineShape and classOf o[i] != line and not isGroupHead o[i]) do
			(
				append badObjects o[i]				
				result += 1
			)
						
			progressUpdate (100.0 * i / o.count)
			if(getProgressCancel() == true) do exit	
		)
		
		if(badObjects.count > 0) do
		(
			invalidObjCnt += result
			try(delete badObjects) catch(print "Can't delete invalid objects")								
		)
		
		progressEnd()
		
		case invalidObjCnt of
		(	
			0: lablelStatus _lblStatus4 status:#notfound
			default: lablelStatus _lblStatus4 status:#cleared	
		)
		
		return result
	)
		
	fn deleteEmptyLayers = 
	(
		if(not _chkBox5.checked) do 
		(
			lablelStatus _lblStatus5 status:#disabled
			return 0
		)
		
		lablelStatus _lblStatus5 status:#wait
		
		progressStart "Delete Empty Layers..."
		escapeEnable
		
		result = 0
		(layerManager.getLayer 0).current = true
		
		i = 0
		
		o = layerManager 
		for l = o.count to 2 by -1 do
		(
			i += 1
			local layer = layerManager.getLayer (l - 1)
			
			local n = undefined
			layer.nodes &n
			
			if n.count == 0 do 
			(	
				layerManager.deleteLayerByName layer.name
				result += 1
			)
			
			progressUpdate (100.0 * i / o.count)
			if(getProgressCancel() == true) do exit	
		)
			
		progressEnd()
		
		case result of
		(	
			0: lablelStatus _lblStatus5 status:#notfound
			default: lablelStatus _lblStatus5 status:#cleared	
		)
		
		return result
	)
	
	fn flattenDWG o = 
	(
		if(not _chkBox7.checked) do 
		(
			lablelStatus _lblStatus7 status:#disabled
			return 0
		)
		
		lablelStatus _lblStatus7 status:#wait
		
		sleep 0.1
		
		result = 0
				
		vMin = o.min.z
		vMax = o.max.z

		a = vMax - vMin
	
		if((floor  a) > 0.0) do
		(
			o.pivot = o.center
			scale o [1.0, 1.0, 0.000001]
			o.pos.z = 0.0
			
			result += 1
		)
			
		case result of
		(	
			0: lablelStatus _lblStatus7 status:#notfound
			default: lablelStatus _lblStatus7 status:#ok	
		)
		
		return result
	)
	
	fn renameObjects o =
	(
		if(not _chkBox8.checked) do 
		(
			lablelStatus _lblStatus8 status:#disabled
			return 0
		)
		
		lablelStatus _lblStatus8 status:#wait
		
		progressStart "Rename Objects..."
		escapeEnable
			
		n = _tbTextBox.text
		
		result = 0
		for i in 1 to o.count do
		(
			if(validObj o[i]) do
			(
				o[i].name = n + "_" + result as string
				result += 1
			)
			
			progressUpdate (100.0 * i / o.count)
			if(getProgressCancel() == true) do exit	
		)
		
		case result of
		(	
			0: lablelStatus _lblStatus8 status:#notfound
			default: lablelStatus _lblStatus8 status:#ok	
		)
		
		progressEnd()
		
		return result
	)
		
	fn groupObjects o =
	(
		if(not _chkBox9.checked) do 
		(
			lablelStatus _lblStatus9 status:#disabled
			return 0
		)
		
		lablelStatus _lblStatus9 status:#wait
		
		progressStart "Rename Objects..."
		escapeEnable
			
		n = _tbTextBox.text
		
		result = 0
				
		for i in 1 to o.count do
		(
			if(o[i] != undefined and isValidObj o[i] and isGroupHead o[i]) do
			(
				explodeGroup o[i]
				result += 1
			)
			
			progressUpdate (100.0 * i / o.count)
			if(getProgressCancel() == true) do exit	
		)
		
		--g = for i in o where validObj i collect i
			
		if(selection.count > 0) do group selection name: n select: false
		
		result += 1
		
		case result of
		(	
			0: lablelStatus _lblStatus9 status:#notfound
			default: lablelStatus _lblStatus9 status:#ok	
		)
		
		progressEnd()
		
		return result
	)
	
	fn pruneDWG=
	(	
		freezeUi()
		
		n = _tbTextBox.text
				
		if(n.count == 0 or n == "Enter DWG Name...") do 
		(
			initDotNet clr: false err: true
			return messageBox "Please enter dwg name!" title: "Warning!"
		)
		if(selection.count == 0) do 
		(
			initDotNet clr: false
			return messageBox "Please select dwg's!" title: "Warning!"
		)
		
		disableUI false

	
		-- Create layers +
		-- Create groups
		-- Remove Mesh +
		-- Convert VIZBlock to Splines +
		-- Attach by color +
		-- Flatten 
		-- Clear empty layers +
		
		initalCall selection
		sleep 0.1
		
		-- Create single layer
		r = 0
		
		l = moveToLayer selection
		if(l == -1) then 
		(
			initDotNet()
			disableUI true
			return MessageBox "Canelled..." title:"Cancel" beep: false
		)
		r += l
		sleep 0.1
		
		r += unlinkObjects selection
		sleep 0.1
			
		r += convertToShape selection
		sleep 0.1
		
		--
		invalidObjCnt = 0
		bad = deleteBadObjects selection		
		r += bad
		
		sleep 0.1
		while bad > 0 do bad = deleteBadObjects selection				
		sleep 0.1
		
		r += deleteEmptyLayers()
		sleep 0.1
		
		attObjCnt = 0		
		att = attachByColor selection
		r += att
		
		sleep 0.1
		while att > 0 do att = attachByColor selection
		sleep 0.1		
		
		r += flattenDWG selection
		
		sleep 0.1
		
		r += renameObjects selection
		
		sleep 0.1
		
		r += groupObjects selection

		disableUI true
		
		sleep 0.1		
		
		if(r > 0) then
		(
			messageBox "Done!" title: "Success!" beep: false
		)
		else
		(
			messageBox "Nothing is done!" title: "Success!" beep: false
		)
	)	
	
	on _tbTextBox GotFocus do
	(
		initDotNet()
		
		t = _tbTextBox.text 
				
		if(t.count == 0 or t == "Enter DWG Name...") do
		(			
			_tbTextBox.Font = getFont()
			_tbTextBox.text  = ""
		)
	)
	
	on _tbTextBox LostFocus do
	(
		t = _tbTextBox.text 
				
		if(t.count == 0) do
		(
			_tbTextBox.Font = getFont s: #italic
			_tbTextBox.text  = "Enter DWG Name..."
		)
	)
	
	on _btnStart pressed do
	(
		initDotNet disabled: true
		
		tmrPrune.active = true
		
		/*
		if(_chkBox1.checked) do 
		(		
			lablelStatus _lblStatus1 status:#ok	
			lablelStatus _lblStatus1 status:#notfound	
			lablelStatus _lblStatus1 status:#wait
		)*/
	)
	
	on tmrPrune tick do
	(
		pruneDWG() 
		
		tmrPrune.active = false
	)
	
	on rPruneSettings open do
	(	
		initDotNet clr: true
				
		x = (useSettings "x" "float" "r") 
		y = (useSettings "y" "float" "r") 
		
		if(x != 0.0 and y != 0.0) do fPruneDWG.pos = [x, y]
		
		_chkBox1.checked = useSettings "CBX1" "bool" "r"
		_chkBox2.checked = useSettings "CBX2" "bool" "r"
		_chkBox3.checked = useSettings "CBX3" "bool" "r"
		_chkBox4.checked = useSettings "CBX4" "bool" "r"
		_chkBox5.checked = useSettings "CBX5" "bool" "r"
		_chkBox6.checked = useSettings "CBX6" "bool" "r"
		_chkBox7.checked = useSettings "CBX7" "bool" "r"
		_chkBox8.checked = useSettings "CBX8" "bool" "r"
		_chkBox9.checked = useSettings "CBX9" "bool" "r"
	)
	
	on _chkBox1 changed x do useSettings "CBX1" x "w"
	on _chkBox2 changed x do useSettings "CBX2" x "w"
	on _chkBox3 changed x do useSettings "CBX3" x "w"
	on _chkBox4 changed x do useSettings "CBX4" x "w"
	on _chkBox5 changed x do useSettings "CBX5" x "w"
	on _chkBox6 changed x do useSettings "CBX6" x "w"
	on _chkBox7 changed x do useSettings "CBX7" x "w"
	on _chkBox8 changed x do useSettings "CBX8" x "w"
	on _chkBox9 changed x do useSettings "CBX9" x "w"
		
	on rPruneSettings close do
	(
		saveWindowPos()
	)
	
	on rPruneSettings moved p do
	(
		iWindowPos = p
	)
)

rollout rAbout "About" 
(	
	label lblName "" 
	label lblVer "" 
	
	label lblAuthor "" height: 30
	label lblCopy ""  height: 30
	button btnHelp "Help" enabled: false
	
	fn getHelp run: false =
	(
		s = getThisScriptFilename()
		i = getScriptInfo s
		
		szHelp = i[7]
		
		if(findString i[7] "http://" == undefined and findString i[7] "https://" == undefined) do
		(
			szHelp = (getFilenamePath s) + i[7]
			if(not doesFileExist szHelp) do szHelp = ""
		)
		
		if(szHelp!= "") do btnHelp.enabled = true
			
		if(run) do ShellLaunch szHelp ""
	)
	
	on btnHelp pressed do getHelp run: true
				
	on rAbout open do
	(		
		i = getScriptInfo (getThisScriptFilename())
			
		lblName.caption = i[1]
		lblAuthor.caption = i[2]
		lblVer.caption = i[3]
		lblCopy.caption = i[6]
		
		getHelp()
	)
)

addRollout rPruneSettings fPruneDWG rolledUp:false 
addRollout rAbout fPruneDWG rolledUp:true 






