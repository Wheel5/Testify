Testify = Testify or { }
local te = Testify

te.UI = { }
local ui = te.UI
local task = te.task

te.currentRecordName = ""
te.selectedSavedName = ""
te.selectedLoadedName = ""
te.selectedReplayName = ""
te.selectedManager = ""
te.loadedScenarios = { }
te.savedScenarios = { }
te.replayScenarios = { }

te.replayStartFrame = 1
te.replayLength = 0
te.replayDuration = 0
te.startTime = 0
te.frameNum = 1

te.replayStatusTemplate = "Total frames: %d\nTotal duration: %dms\nCurrent desync: %dms\nScenario time: %dms\nCurrent Time: %dms\nCurrent frame: %d"

-- ZO_StatusBar_SmoothTransition(Testify.UI.progressBar, 11, 100, false)

function ui.displayStatus(text, duration)
	ui.status:SetText(text)
	if duration > 0 then
		zo_callLater(function() ui.status:SetText("") end, duration)
	end
end

local function populateTables()
	if not te.dataModules["TestifyDB00"] or not te.dataModules["TestifyDB00"].savedVars then
		zo_callLater(populateTables, 1000)
		return
	end

	local db = te.dataModules["TestifyDB00"]
	for k, v in pairs(db.savedVars) do --Testify.dataModules["TestifyDB00"].savedVars
		local entry = ui.manageSavedDropdown:CreateItemEntry(k, function() te.selectedSavedName = k end)
		table.insert(te.savedScenarios, entry)
	end

	for k, v in ipairs(te.savedScenarios) do
		ui.manageSavedDropdown:AddItem(v)
	end
	
end

function ui.refreshTables()
	te.savedScenarios = { }
	te.loadedScenarios = { }
	te.replayScenarios = { }
	te.selectedLoadedName = ""
	te.selectedSavedName = ""
	te.selectedReplayName = ""
	ui.manageLoadedDropdown:ClearItems()
	ui.manageSavedDropdown:ClearItems()
	ui.replayScenarioDropdown:ClearItems()
	populateTables()

	for k, v in pairs(te.recordings) do
		local entry = ui.manageLoadedDropdown:CreateItemEntry(k, function() te.selectedLoadedName = k end)
		local rep = ui.replayScenarioDropdown:CreateItemEntry(k, function()
			te.selectedReplayName = k
			te.replayLength = #te.recordings[k]
			te.replayDuration = te.recordings[k][te.replayLength][1] - te.recordings[k][1][1]
			ui.progressBar:SetMinMax(0, te.replayLength)
			ZO_StatusBar_SmoothTransition(ui.progressBar, te.replayStartFrame, te.replayLength, false)
			ui.replayInfo:SetText(string.format(te.replayStatusTemplate, te.replayLength, te.replayDuration, 0, te.scenarioTime, 0, te.frameNum))
		end)
		table.insert(te.loadedScenarios, entry)
		table.insert(te.replayScenarios, rep)
	end

	for k, v in ipairs(te.loadedScenarios) do
		ui.manageLoadedDropdown:AddItem(v)
	end

	for k, v in ipairs(te.replayScenarios) do
		ui.replayScenarioDropdown:AddItem(v)
	end

	ui.manageLoadedDropdown:SetSelectedItemText("Select Scenario")
	ui.manageSavedDropdown:SetSelectedItemText("Select Scenario")
	ui.replayScenarioDropdown:SetSelectedItemText("Select Scenario")
end

local function startRecordingHandler()
	--d("start recording")
	if not te.currentRecordName or te.currentRecordName == "" then
		ui.displayStatus("|cff0000Please enter a name for the recording|r", 2000)
		return
	end
	te.toggleRecording("true", te.currentRecordName)
	ui.recordingStatus:SetText("Recording: |c00ff00On|r")
	ui.recordingName:SetEditEnabled(false)
	ui.recordingName:SetMouseEnabled(false)
end

local function stopRecordingHandler()
	--d("stop recording")
	te.toggleRecording("false")
	ui.recordingStatus:SetText("Recording: |cff0000Off|r")
	ui.recordingName:SetEditEnabled(true)
	ui.recordingName:SetMouseEnabled(true)
	ui.refreshTables()

	local rec = te.recordings[te.currentRecordName]
	if rec then
		local len = #rec
		local dur = len >= 2 and rec[len][1] - rec[1][1] or 0
		local info = string.format("Frames: %d\nDuration: %dms", len, dur)
		ui.recordingInfo:SetText(info)
	else
		ui.recordingInfo:SetText("No recording data found")
	end
end

local function recordingNameHandler(control)
	--d(control:GetText())
	te.currentRecordName = control:GetText()
end

local function manageLoadedSaveHandler()
	d("loaded save")
	ui.displayStatus("Saving, please wait...", -1)
	te.saveRecording(te.selectedLoadedName)
end

local function manageLoadedDeleteHandler()
	d("loaded delete")
	if te.selectedLoadedName == "" then
		ui.displayStatus("|cff0000Please select a loaded scenario to delete|r", 2000)
		return
	end
	te.deleteLoadedRecording(te.selectedLoadedName)
	ui.refreshTables()
end

local function manageSavedLoadHandler()
	d("saved load")
	if te.selectedSavedName == "" then
		ui.displayStatus("|cff0000Please select a saved scenario to load|r", 2000)
		return
	end
	ui.displayStatus("Loading, please wait...", -1)
	te.loadRecording(te.selectedSavedName)
end

local function manageSavedDeleteHandler()
	d("saved delete")
	if te.selectedSavedName == "" then
		ui.displayStatus("|cff0000Please select a saved scenario to delete|r", 2000)
		return
	end
	te.deleteSavedRecording(te.selectedSavedName)
	ui.refreshTables()
end

local function startReplayHandler()
	d("start replay")
	if te.selectedReplayName == "" or te.selectedManager == "" then
		ui.displayStatus("|cff0000Please select a scenario and a manager|r", 2000)
		return
	end
	te.startReplay(te.registeredCallbackManagers[te.selectedManager], te.recordings[te.selectedReplayName], te.replayStartFrame)
end

local function stopReplayHandler()
	d("stop replay")
	te.continueReplay = false
end

local function startFrameHandler(control)
	d(control:GetText())
	te.replayStartFrame = true and tonumber(control:GetText()) or 1
	if te.selectedReplayName ~= "" then
		ZO_StatusBar_SmoothTransition(ui.progressBar, te.replayStartFrame, te.replayLength, false)
	end
end

function te.setupUI()
	ui.frame = Testify_Frame
	ui.status = Testify_Frame_Title_Status
	ui.close = Testify_Frame_Title_Close
	ui.startRecordingButton = Testify_Frame_Scenarios_Left_Recording_Right_Start_Button
	ui.stopRecordingButton = Testify_Frame_Scenarios_Left_Recording_Right_Stop_Button
	ui.recordingStatus = Testify_Frame_Scenarios_Left_Recording_Right_Status
	ui.recordingInfo = Testify_Frame_Scenarios_Left_Recording_Left_Info
	ui.recordingName = Testify_Frame_Scenarios_Left_Recording_Left_Name_Edit_Box
	ui.manageLoadedSaveButton = Testify_Frame_Scenarios_Right_Management_Left_Save_Button
	ui.manageLoadedDeleteButton = Testify_Frame_Scenarios_Right_Management_Left_Mem_Delete_Button
	ui.manageSavedLoadButton = Testify_Frame_Scenarios_Right_Management_Right_Load_Button
	ui.manageSavedDeleteButton = Testify_Frame_Scenarios_Right_Management_Right_Disk_Delete_Button
	ui.startReplayButton = Testify_Frame_Replay_Left_Right_Play_Button
	ui.stopReplayButton = Testify_Frame_Replay_Left_Right_Stop_Button
	ui.startFrame = Testify_Frame_Replay_Left_Left_Start_Frame_Edit_Box
	ui.replayInfo = Testify_Frame_Replay_Right_Info
	ui.progressBar = Testify_Frame_Replay_Progress_Bar

	ui.recordingInfo:SetText("")
	--ui.startFrame:SetEditEnabled(false)
	--ui.startFrame:SetMouseEnabled(false)
	
	ui.manageLoadedDropdown = ZO_ComboBox_ObjectFromContainer(Testify_Frame_Scenarios_Right_Management_Left_Mem_Dropdown)
	ui.manageLoadedDropdown:SetSelectedItemText("Select Scenario")

	ui.manageSavedDropdown = ZO_ComboBox_ObjectFromContainer(Testify_Frame_Scenarios_Right_Management_Right_Disk_Dropdown)
	ui.manageSavedDropdown:SetSelectedItemText("Select Scenario")

	ui.replayScenarioDropdown = ZO_ComboBox_ObjectFromContainer(Testify_Frame_Replay_Left_Left_Scenario_Dropdown)
	ui.replayScenarioDropdown:SetSelectedItemText("Select Scenario")

	ui.replayManagerDropdown = ZO_ComboBox_ObjectFromContainer(Testify_Frame_Replay_Left_Right_Manager_Dropdown)
	ui.replayManagerDropdown:SetSelectedItemText("Select Manager")

	ui.close:SetHandler("OnMouseUp", function() ui.frame:SetHidden(true) end, "Testify")

	ui.startRecordingButton:SetHandler("OnMouseUp", startRecordingHandler, "Testify")
	ui.stopRecordingButton:SetHandler("OnMouseUp", stopRecordingHandler, "Testify")
	ui.recordingName:SetHandler("OnTextChanged", recordingNameHandler, "Testify")
	ui.startFrame:SetHandler("OnTextChanged", startFrameHandler, "Testify")

	ui.manageLoadedSaveButton:SetHandler("OnMouseUp", manageLoadedSaveHandler, "Testify")
	ui.manageLoadedDeleteButton:SetHandler("OnMouseUp", manageLoadedDeleteHandler, "Testify")
	ui.manageSavedLoadButton:SetHandler("OnMouseUp", manageSavedLoadHandler, "Testify")
	ui.manageSavedDeleteButton:SetHandler("OnMouseUp", manageSavedDeleteHandler, "Testify")
	ui.startReplayButton:SetHandler("OnMouseUp", startReplayHandler, "Testify")
	ui.stopReplayButton:SetHandler("OnMouseUp", stopReplayHandler, "Testify")

	ui.progressBar:SetMinMax(1, 100)
	ui.progressBar:SetValue(0)

	ui.status:SetText("")

	populateTables()
	for k, v in pairs(te.registeredCallbackManagers) do
		local item = ui.replayManagerDropdown:CreateItemEntry(k, function() te.selectedManager = k end)
		ui.replayManagerDropdown:AddItem(item)
	end
	ui.replayInfo:SetText(string.format(te.replayStatusTemplate, te.replayLength, te.replayDuration, 0, te.scenarioTime, 0, te.frameNum))
end

