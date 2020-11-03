Testify = Testify or { }
local te = Testify

local getModule = {
	TestifyDB00 = {
		savedVarsName = "TestifyDB00SavedVars",
	},
	TestifyDB01 = {
		savedVarsName = "TestifyDB01SavedVars",
	},
	TestifyDB02 = {
		savedVarsName = "TestifyDB02SavedVars",
	},
	TestifyDB03 = {
		savedVarsName = "TestifyDB03SavedVars",
	},
	TestifyDB04 = {
		savedVarsName = "TestifyDB04SavedVars",
	},
	TestifyDB05 = {
		savedVarsName = "TestifyDB05SavedVars",
	},
	TestifyDB06 = {
		savedVarsName = "TestifyDB06SavedVars",
	},
	TestifyDB07 = {
		savedVarsName = "TestifyDB07SavedVars",
	},
	TestifyDB08 = {
		savedVarsName = "TestifyDB08SavedVars",
	},
	TestifyDB09 = {
		savedVarsName = "TestifyDB09SavedVars",
	},
}

local function attemptModuleRegistration(e, addonName)
	--df("loading %s", addonName)
	local mod = getModule[addonName]
	if not mod then return end

	te.dataModules[addonName] = mod
	_G[mod.savedVarsName] = _G[mod.savedVarsName] or { }
	te.dataModules[addonName].savedVars = _G[mod.savedVarsName]
end

function te.startManager()
	te.dataModules = { }
	te.EM:RegisterForEvent(te.name.."ModuleLoad", EVENT_ADD_ON_LOADED, function(e, addonName)
		attemptModuleRegistration(e, addonName)
	end)
end


