Testify = Testify or { }
local te = Testify
te.EM = GetEventManager()

te.registeredCallbackManagers = { }

local eventFilterLookup = {
	[EVENT_COMBAT_EVENT] = {
		[REGISTER_FILTER_ABILITY_ID] = function(abilityId, ...)
			return abilityId == select(17, ...)
		end,
		[REGISTER_FILTER_COMBAT_RESULT] = function(result, ...)
			return result == select(2, ...)
		end,
		[REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE] = function(unitType, ...)
			return unitType == select(8, ...)
		end,
		[REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE] = function(unitType, ...)
			return unitType == select(9, ...)
		end,
	},
	[EVENT_EFFECT_CHANGED] = {
		[REGISTER_FILTER_ABILITY_ID] = function(abilityId, ...)
			return abilityId == select(16, ...)
		end,
		[REGISTER_FILTER_UNIT_TAG] = function(unitTag, ...)
			return string.find(select(5, ...), unitTag) ~= nil
		end,
		[REGISTER_FILTER_UNIT_TAG_PREFIX] = function(unitTag, ...)
			return string.find(select(5, ...), unitTag) ~= nil
		end,
		[REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE] = function(unitType, ...)
			return unitType == select(17, ...)
		end,
	},
}

EventCallbackManager = ZO_Object:Subclass()

function EventCallbackManager:New(managerID)
	local manager = ZO_Object.New(self)
	manager.registry = {
		--[EVENT_COMBAT_EVENT] = { },
		--[EVENT_EFFECT_CHANGED] = { },
	}
	-- . . .
	manager.ID = managerID
	te.registeredCallbackManagers[managerID] = manager
	return manager
end

function EventCallbackManager:RegisterForEvent(name, eventName, callback)
	local val = te.EM:RegisterForEvent(name, eventName, callback)
	if not name or not eventName or not callback then return val end
	if not self.registry[eventName] then
		self.registry[eventName] = { }
	end
	self.registry[eventName][name] = {callback, false}
	return val
end

function EventCallbackManager:UnregisterForEvent(name, eventName)
	local val = te.EM:UnregisterForEvent(name, eventName)
	if not name or not eventName then return val end
	if not self.registry[eventName] then
		return val
	end
	self.registry[eventName][name] = nil
	return val
end

function EventCallbackManager:AddFilterForEvent(name, eventName, ...)
	local val = te.EM:AddFilterForEvent(name, eventName, ...)
	if not name or not eventName then return val end
	if not self.registry[eventName] or not self.registry[eventName][name] then return val end
	-- TODO: add addition filters to lookup
	self.registry[eventName][name][2] = true
	local len = select('#', ...)
	if len%2 ~= 0 then
		d("UNEXPECTED FILTER ARG LENGTH, ABORTING")
		return val
	end
	for i = 1, len, 2 do
		table.insert(self.registry[eventName][name], {[1] = select(i, ...), [2] = select(i+1, ...)})
	end
	return val
end

-- placeholders
-- (eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId) EVENT_COMBAT_EVENT
-- (eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceType) EVENT_EFFECT_CHANGED

-- callbacktable - {callbackFunc, bool, {filterid, filter}, {filterid, filter}, ...}
function EventCallbackManager:FireCallbacks(...)
	-- filter check
	-- fire ALL callbacks
	if not self.registry[select(1, ...)] then
		return
	end
	for k, callbackTable in pairs(self.registry[select(1, ...)]) do
		local firecallback = true
		if not callbackTable[2] then
			callbackTable[1](...)
		else
			for i = 3, #callbackTable do
				if callbackTable[i][2] ~= nil then
					if eventFilterLookup[select(1, ...)][callbackTable[i][1]] and not eventFilterLookup[select(1, ...)][callbackTable[i][1]](callbackTable[i][2], ...) then
						firecallback = false
						break
					end
				else
					-- this should never fire actually
					if not eventFilterLookup[select(1, ...)][callbackTable[i][1]](...) then
						firecallback = false
						break
					end
				end
			end
			if firecallback then
				callbackTable[1](...)
			end
		end
	end
	
end

-- Forwarding of other requests
function EventCallbackManager:RegisterForUpdate(name, time, callback)
	local val = te.EM:RegisterForUpdate(name, time, callback)
	return val
end

function EventCallbackManager:UnregisterForUpdate(name)
	local val = te.EM:UnregisterForUpdate(name)
	return val
end

function EventCallbackManager:RegisterForAllEvents(...)
	local val = te.EM:RegisterForAllEvents(...) -- maybe no return value?
	return val
end

local manager = EventCallbackManager:New("GlobalEventManager")
GetEventManager = function() return manager end
EVENT_MANAGER = manager
