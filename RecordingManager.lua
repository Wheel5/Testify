Testify = Testify or { }
local te = Testify

local async = LibAsync
local task = async:Create("Testify")
te.task = task

local tinsert = table.insert

te.recordingActive = false
te.recordings = { }

function te.addRecordEntry(...)
	tinsert(te.recordings[te.currentRecord], {GetGameTimeMilliseconds(), {...}})
end

-- ===========================================
-- MODIFY THIS FUNCTION TO CUSTOMIZE RECORDING
-- ===========================================
function te.toggleRecording(enable, name)
	if enable == "true" then
		df("[Testify] Recording |c00FF00Enabled|r")
		te.recordings[name] = { }
		te.currentRecord = name
		te.EM:RegisterForEvent(te.name.."RecordingManager", EVENT_COMBAT_EVENT, te.addRecordEntry)
		te.EM:AddFilterForEvent(te.name.."RecordingManager", EVENT_COMBAT_EVENT, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_NONE)
		te.EM:RegisterForEvent(te.name.."RecordingManager", EVENT_PLAYER_COMBAT_STATE, te.addRecordEntry)
		te.EM:RegisterForEvent(te.name.."RecordingManager", EVENT_EFFECT_CHANGED, te.addRecordEntry)
		te.EM:AddFilterForEvent(te.name.."RecordingManager", EVENT_EFFECT_CHANGED, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_NONE)
	else
		df("[Testify] Recording |cFF0000Disabled|r")
		te.EM:UnregisterForEvent(te.name.."RecordingManager", EVENT_COMBAT_EVENT)
		te.EM:UnregisterForEvent(te.name.."RecordingManager", EVENT_PLAYER_COMBAT_STATE)
		te.EM:UnregisterForEvent(te.name.."RecordingManager", EVENT_EFFECT_CHANGED)
	end
end

function te.saveRecording(recordingName)
	local start = GetGameTimeMilliseconds()
	local record = te.recordings[recordingName]
	if not record then
		d("could not find recording with that name")
		return
	end
	df("saving %s", recordingName)
	local tmp = { }
	task:For(ipairs(record)):Do(function(k,frame)
	--for k,frame in ipairs(record) do
		tmp[k] = te.DataToString(frame)	
	end):Then(function()
		local splitSize = math.floor(#tmp/10)
		local currentEnd = splitSize
		local saving = true
		local i = 1
		local j = 1
		local dbLookup = {
			[1] = "TestifyDB00",
			[2] = "TestifyDB01",
			[3] = "TestifyDB02",
			[4] = "TestifyDB03",
			[5] = "TestifyDB04",
			[6] = "TestifyDB05",
			[7] = "TestifyDB06",
			[8] = "TestifyDB07",
			[9] = "TestifyDB08",
			[10] = "TestifyDB09",
		}
		while saving do -- repeat .... until
			if j == 10 then saving = false end
			te.dataModules[dbLookup[j]].savedVars[recordingName] = { }
			local currentDB = te.dataModules[dbLookup[j]].savedVars[recordingName]
			-- TODO: function task:For(f,t,s)
			while i < currentEnd do
				tinsert(currentDB, tmp[i])
				i = i + 1
			end
			j = j + 1
			if j < 10 then
				currentEnd = currentEnd + splitSize
			else
				currentEnd = #tmp + 1
			end
		end
		df("save complete, duration %dms", GetGameTimeMilliseconds() - start)
		te.UI.displayStatus("|c00ff00Done!", 2000)
		te.UI.refreshTables()
	end)
end

function te.loadRecording(recordingName)
	-- TODO: handle loaded recording of that name?
	local start = GetGameTimeMilliseconds()
	df("loading %s", tostring(recordingName))
	te.recordings[recordingName] = { }
	local r = te.recordings[recordingName]
	task:For(0,9):Do(function(i)
	--for i = 0, 9 do
		local db = te.dataModules["TestifyDB0"..i]
		--d(tostring(db))
		local data = db.savedVars[recordingName]
		if not data then
			d("no saved recordings with the name %s", tostring(recordingName))
		end
		task:For(ipairs(data)):Do(function(k, frame)
		--for k,frame in ipairs(data) do
			tinsert(r, te.StringToData(frame))
		end)
	end):Then(function()
		df("loaded, duration %dms", GetGameTimeMilliseconds() - start)
		te.UI.displayStatus("|c00ff00Done!", 2000)
		te.UI.refreshTables()
	end)
end

function te.deleteSavedRecording(recordingName)
	df("deleting %s...", tostring(recordingName))
	for i = 0, 9 do
		local db = te.dataModules["TestifyDB0"..i]
		db.savedVars[recordingName] = nil
	end
	--te.recordings[recordingName] = nil
	-- collectgarbage()
end

function te.deleteLoadedRecording(recordingName)
	te.recordings[recordingName] = nil
end

