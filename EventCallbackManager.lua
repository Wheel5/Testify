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

--[[
EM:RegisterForEvent(sam.name.."UnitDiedXP", EVENT_COMBAT_EVENT, callback)
EM:AddFilterForEvent(sam.name.."UnitDiedXP", EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DIED_XP)
EM:UnregisterForEvent(sam.name..self.name..tostring(v), self.event)
]]

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
	--df("Event Registered: %s %d, %s", name, eventName, tostring(val))
	if not name or not eventName or not callback then return val end
 	-- df("callback registered for %s", name)
	if not self.registry[eventName] then
		self.registry[eventName] = { }
	end
	self.registry[eventName][name] = {callback, false}
	return val
end

function EventCallbackManager:UnregisterForEvent(name, eventName)
	local val = te.EM:UnregisterForEvent(name, eventName)
	--df("Event Unregistered: %s %d, %s", name, eventName, tostring(val))
	if not name or not eventName then return val end
	if not self.registry[eventName] then
		-- df("No registrations found for %d", eventName)
		return val
	end
 	-- df("callback unregistered for %s", tostring(name))
	self.registry[eventName][name] = nil
	return val
end

function EventCallbackManager:AddFilterForEvent(name, eventName, ...)
	local val = te.EM:AddFilterForEvent(name, eventName, ...)
	if not name or not eventName then return val end
	if not self.registry[eventName] or not self.registry[eventName][name] then return val end
	-- TODO: add addition filters to lookup
	--if not eventFilterLookup[eventName] or not eventFilterLookup[eventName][eventFilterName] then
	--	--d("no applicable filters found")
	--	return val
	--end
	-- df("callback filter added for %s, filter value: %s", name, tostring(filter))
	self.registry[eventName][name][2] = true
	local len = select('#', ...)
	if len%2 ~= 0 then
		d("UNEXPECTED FILTER ARG LENGTH, ABORTING")
		return val
	-- else
	-- 	df("Inserting %d filters", len/2)
	end
	for i = 1, len, 2 do
		--df("filter: %s, filter value: %s", tostring(select(i, ...)), tostring(select(i+1, ...)))
		table.insert(self.registry[eventName][name], {[1] = select(i, ...), [2] = select(i+1, ...)})
	end
	--table.insert(self.registry[eventName][name], {eventFilterName, filter})
	return val
end

-- placeholders
-- (eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId) EVENT_COMBAT_EVENT
-- (eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceType) EVENT_EFFECT_CHANGED

-- callbacktable - {callbackFunc, bool, {filterid, filter}, {filterid, filter}, ...}
function EventCallbackManager:FireCallbacks(...)
	-- filter check
	-- fire ALL callbacks
	-- d("firing")
	if not self.registry[select(1, ...)] then
		--d("no events registered, skipping...")
		return
	end
	-- d(self.registry[select(1, ...)])
	for k, callbackTable in pairs(self.registry[select(1, ...)]) do
		--df("processing callback: %s", k)
		local firecallback = true
		if not callbackTable[2] then
			--d("no filters, firing")
			callbackTable[1](...)
		else
			--d("processing filters...")
			for i = 3, #callbackTable do
				if callbackTable[i][2] ~= nil then
					--df("filter value found: %s", tostring(callbackTable[i][2]))
					if eventFilterLookup[select(1, ...)][callbackTable[i][1]] and not eventFilterLookup[select(1, ...)][callbackTable[i][1]](callbackTable[i][2], ...) then
						--d("filter failed")
						firecallback = false
						break
					end
				else
					-- this should never fire actually
					--d("filter value not found")
					if not eventFilterLookup[select(1, ...)][callbackTable[i][1]](...) then
						--d("filter failed")
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
	--df("Update registered: %s, %d", name, time)
	return val
end

function EventCallbackManager:UnregisterForUpdate(name)
	local val = te.EM:UnregisterForUpdate(name)
	--df("Update Unregistered: %s", name)
	return val
end

function EventCallbackManager:RegisterForAllEvents(...)
	local val = te.EM:RegisterForAllEvents(...) -- maybe no return value?
	return val
end

local manager = EventCallbackManager:New("GlobalEventManager")
GetEventManager = function() return manager end
EVENT_MANAGER = manager
