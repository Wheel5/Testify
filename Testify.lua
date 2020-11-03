Testify = Testify or { }
local te = Testify

te.name = "Testify"
te.version = "1.0"

te.testReplay_01 = {
	[1] = {1000, {131106, 2250, nil, "Ranger", 0, 0, nil, 0, "My Slap on One^Fx", 1, 0, -1, 1, nil, 0, 48207, 45493, 0}},
	[2] = {2000, {131106, 2250, nil, "Accuracy", 0, 0, nil, 0, "My Slap on One^Fx", 1, 0, -1, 1, nil, 0, 48207, 45492, 0}},
	[3] = {3000, {131106, 2250, nil, "Bitter Harvest", 0, 0, nil, 0, "My Slap on One^Fx", 1, 0, -1, 1, nil, 0, 48207, 124006, 0}},
	[4] = {4000, {131106, 2240, nil, "Heavy Weapons", 0, 0, "My Slap on One^Fx", 1, "My Slap on One^Fx", 1, 1, -1, 1, nil, 48207, 48207, 29375, 0}},
}

local chatOutEvent = false
local modsChecked = false

local defaults = {
}

function te.getEventData(...)
	d(table.concat({...}, ", "))
end

function te.runTestData()
	local manager = EventCallbackManager:New("TestifyTestManager")
	manager:RegisterForEvent(te.name.."Test", EVENT_COMBAT_EVENT, te.getEventData)
	--manager:AddFilterForEvent(te.name.."Test", EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, 45493)

	te.startReplay(manager, te.testReplay_01, 1)

	--manager:FireCallbacks(131106, 2250, nil, "Ranger", 0, 0, nil, 0, "My Slap on One^Fx", 1, 0, -1, 1, nil, 0, 48207, 45493, 0)
	--manager:FireCallbacks(131106, 2250, nil, "Accuracy", 0, 0, nil, 0, "My Slap on One^Fx", 1, 0, -1, 1, nil, 0, 48207, 45492, 0)
	--manager:FireCallbacks(131106, 2250, nil, "Bitter Harvest", 0, 0, nil, 0, "My Slap on One^Fx", 1, 0, -1, 1, nil, 0, 48207, 124006, 0)
	--manager:FireCallbacks(131106, 2240, nil, "Heavy Weapons", 0, 0, "My Slap on One^Fx", 1, "My Slap on One^Fx", 1, 1, -1, 1, nil, 48207, 48207, 29375, 0)

	manager:UnregisterForEvent(te.name.."Test", EVENT_COMBAT_EVENT, te.getEventData)

	--manager:FireCallbacks(131106, 2240, nil, "Heavy Weapons", 0, 0, "My Slap on One^Fx", 1, "My Slap on One^Fx", 1, 1, -1, 1, nil, 48207, 48207, 29375, 0)
end

local function toggleEvents()
	chatOutEvent = not chatOutEvent
	if chatOutEvent then
		te.EM:RegisterForEvent(te.name, EVENT_COMBAT_EVENT, te.getEventData)
	else
		te.EM:UnregisterForEvent(te.name, EVENT_COMBAT_EVENT)
	end
end

local function chatToggleRecording(input)
	local args = {}
	for str in string.gmatch(input, "%S+") do
		table.insert(args, str)
	end
	te.toggleRecording(args[1], args[2])
end

local function chatStartReplay(input)
	local args = {}
	for str in string.gmatch(input, "%S+") do
		table.insert(args, str)
	end
	if args[3] then
		args[3] = tonumber(args[3])
	else
		d("ERROR")
	end
	local manager = te.registeredCallbackManagers[args[1]]
	local replay = te.recordings[args[2]]
	te.startReplay(manager, replay, args[3])
end

local function toggleFrame()
	te.UI.frame:SetHidden(not te.UI.frame:IsHidden())
end

local function moduleCheck()
	if modsChecked then return end
	modsChecked = true
	local count = 0
	for k, v in pairs(te.dataModules) do
		count = count + 1
	end
	if count < 10 then
		d("[Testify]: |cff0000ERROR:|r there are missing data modules. Do not save or load data without first enabling all required data modules in the addon list")
		te.UI.displayStatus("|cff0000ERROR:|r there are missing data modules", -1)
	end
end

function te.Init(e, addonName)
	if addonName ~= te.name then return end
	te.EM:UnregisterForEvent(te.name.."AddonLoad", EVENT_ADD_ON_LOADED)
	te.EM:RegisterForEvent(te.name.."modCheck", EVENT_PLAYER_ACTIVATED, moduleCheck)
	te.savedVars = ZO_SavedVars:NewAccountWide("TestifySavedVariables", 1, nil, defaults)
	te.startManager()
	te.setupUI()
	SLASH_COMMANDS["/techatout"] = toggleEvents
	SLASH_COMMANDS["/tetestdata"] = te.runTestData
	SLASH_COMMANDS["/terecord"] = chatToggleRecording
	SLASH_COMMANDS["/tereplay"] = chatStartReplay
	SLASH_COMMANDS["/testify"] = toggleFrame

end

te.EM:RegisterForEvent(te.name.."AddonLoad", EVENT_ADD_ON_LOADED, te.Init)
