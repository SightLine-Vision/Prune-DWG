/*
[INFO]

NAME = Prune DWG
VERSION = 1.0.0
AUTHOR = MastaMan
DEV = ViscoCG
HELP = \help\pruneDwg.html

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
global fPruneDWG = newRolloutFloater "Prune DWG" 250 300


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
		
		checkbox _chkBox6 "Attach By Color:"  width:125 height:18 checked:true across: 2 align: #left tooltip: "Attaches all dwg's depending on the color.\n\nA large number of splines is hanging scene.\nThis option will help to simplify the drawings."
		dotNetControl _lblStatus6 "System.Windows.Forms.label" width:72  align: #right 
		
		
		button _btnStart "Start" width:196 height:32 offset: [0, 10]
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
		"_lblStatus6"	
	)
	
	global iWindowPos = [0,0]	
	
	global _DISABLED = "DISABLED"
	global _OK = "OK"
	global _NOTFOUND = "NOT FOUND"
	global _EXIST = "EXIST"
	global _WAIT = "WAIT..."
	global _CLEARED = "CLEARED"
	
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
			#exist:
			(
				bgColor = getColor 147 196 125
				fgColor = getColor 56 118 79
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
	
	fn initDotNet disabled: false clr: false = 
	(	
		_tbTextBox.BackColor = getBgColor()
		_tbTextBox.ForeColor = getTextColor()

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
	
		result = 0
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

		disableSceneRedraw()
		undo off
		(
			for i in x.count to 2 by -1 do
			(
				addAndWeld o x[i] -1	
				
				deleteItem x i
				
				result += 1
				
				progressUpdate (100.0 * result / x.count)
				if(getProgressCancel() == true) do exit		
				
				/*if(result > 300) do 
				(
					--tmrAttachNode.active = false
					exit
				)*/
			)
		)
		
		
		progressEnd()
		
		o.wirecolor = c
		CenterPivot o
		updateShape o
		
		enableSceneRedraw()	
			
		gc()
		
		return result
	)
	
	on tmrAttachNode tick do
	(				
		
	)
	
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
		
		enableSceneRedraw()		
		enableSceneRedraw()		
		enableSceneRedraw()		
		enableSceneRedraw()		
		enableSceneRedraw()		
		forceCompleteRedraw()
						
		case result of
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
		
		for i in 1 to o.count  do
		(
			if(validObj o[i]) do
			(
				o[i].colorbylayer = false
				o[i].name = uniqueName (n + "_")	
				
				case of
				(
					(o[i].layer.wirecolor != white /*and o[i].layer.name != "0"*/ and o[i].layer.name != n) : o[i].wirecolor = o[i].layer.wirecolor 
					(o[i].wirecolor != white): o[i].wirecolor = o[i].wirecolor
					default: o[i].wirecolor = green
				)							
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
		
		n = _tbTextBox.text
		
		layer = LayerManager.getLayerFromName n
		
		result = 0
		
		if(layer != undefined) then 
		(
			q = queryBox "The layer with this name already exist!\nAdd to exist layer?" title: "Warning"
			lablelStatus _lblStatus1 status:#ok
			if(not q) do return false
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
		
		progressStart "Unlink objects..."
		escapeEnable
				
		result = 0
		for i in 1 to o.count  do
		(
			if(validObj o[i] and o[i].parent != undefined) do
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
		for i in 1 to o.count where validObj o[i] and classOf o[i] == LinkCompositeshape and canConvertTo o[i] SplineShape do 
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
		for i in 1 to o.count  do
		(
			if(validObj o[i] and classOf o[i] != SplineShape and classOf o[i] != line) do
			(
				delete o[i]
				result += 1
			)
			
			progressUpdate (100.0 * i / o.count)
			if(getProgressCancel() == true) do exit	
		)
		
		progressEnd()
		
		case result of
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
	
	fn pruneDWG =
	(		
		n = _tbTextBox.text
				
		if(n.count == 0 or n == "Enter DWG Name...") do 
		(
			initDotNet clr: false
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
		-- Attach by color
		-- Flatten 
		-- Clear empty layers +
		
		initalCall selection
		sleep 0.1
		
		-- Create single layer
		r = 0
		
		r += moveToLayer selection
		sleep 0.1
		
		r += unlinkObjects selection
		sleep 0.1
			
		r += convertToShape selection
		sleep 0.1
				
		r += deleteBadObjects selection
		sleep 0.1
		
		r += deleteEmptyLayers()
		sleep 0.1
		
		r += attachByColor selection
		sleep 0.1
		
			
		disableUI true
		
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
	)
	
	on _chkBox1 changed x do useSettings "CBX1" x "w"
	on _chkBox2 changed x do useSettings "CBX2" x "w"
	on _chkBox3 changed x do useSettings "CBX3" x "w"
	on _chkBox4 changed x do useSettings "CBX4" x "w"
	on _chkBox5 changed x do useSettings "CBX5" x "w"
	on _chkBox6 changed x do useSettings "CBX6" x "w"
		
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
		szHelp = (getFilenamePath s) + i[7]
		if(i[7] != "" and doesFileExist szHelp) do btnHelp.enabled = true
			
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
