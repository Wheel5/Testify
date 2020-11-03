Testify = Testify or { }
local te = Testify
local df = df
local unpack = unpack
local zo_callLater = zo_callLater
local GetFrameDeltaMilliseconds = GetFrameDeltaMilliseconds
local max = math.max

te.continueReplay = true
te.scenarioTime = 0
-- replay frame: [int] = {timestamp, {eventData}}

-- scenario replay covered 12461ms (real time 26482ms) -- 1463 frames of lokke_1
-- scenario replay: 1690 frames covering 13818ms (real time 30210ms) -- all zo_callLater
-- scenario replay: 1641 frames covering 13266ms (real time 19885ms) -- 0 ms diffs use recursion
-- scenario replay: 2959 frames covering 16920ms (real time 26433ms) -- <1 ms diffs use recursion
-- scenario replay: 2964 frames covering 16950ms (real time 19997ms) -- <1 ms diffs use recursion + no chat output
-- siri changes:
-- scenario replay: 1643 frames covering 13559ms (real time 14844ms)
-- scenario replay: 2599 frames covering 16408ms (real time 18227ms)
-- scenario replay: 9556 frames covering 22598ms (real time 75374ms) NEEDS WORK
-- ==== fixed ====
-- scenario replay: 327 frames covering 12555ms (real time 13366ms) global
-- scenario replay: 408 frames covering 17028ms (real time 17860ms) isolated
-- scenario replay: 38784 frames covering 49481ms (real time 54773ms) large log

local function updateStatus()
	local currentTime = GetGameTimeMilliseconds() - te.startTime
	local desync = te.scenarioTime - currentTime
	ZO_StatusBar_SmoothTransition(te.UI.progressBar, te.frameNum, te.replayLength, false)
	te.UI.replayInfo:SetText(string.format(te.replayStatusTemplate, te.replayLength, te.replayDuration, desync, te.scenarioTime, currentTime, te.frameNum))
end

-- TODO: replace callLater with a manual registration? probably faster
function te.startReplay(manager, replay, startFrame)
	local startTime = GetGameTimeMilliseconds()
	te.startTime = startTime
	local firstFrame
	local lastFrame
	local lastFrameNum
	te.continueReplay = true
	local frame = startFrame
	local len = #replay
	if frame >= len then
		te.UI.displayStatus("|cff0000Start frame is invalid for this scenario!|r", 2000)
		return
	end
	local function frameLoop()
		if frame == startFrame then firstFrame = replay[frame][1] end
		lastFrame = replay[frame][1]
		lastFrameNum = frame
		local currentFrame = replay[frame]
		local nextFrame = replay[frame + 1] -- nilable
		--df("Playing frame %d/%d", frame, len)
		manager:FireCallbacks(unpack(currentFrame[2]))
		if nextFrame and te.continueReplay then
			local diff = nextFrame[1] - currentFrame[1]
			local delta = GetFrameDeltaMilliseconds()
			frame = frame + 1

			te.frameNum = frame -- for monitoring
			te.scenarioTime = lastFrame - firstFrame

			-- This commented code will either make the timings closer, or wayyyyy too fast
			-- (it attempts to compensate for the frame time in event time differences between 1 and 2 frames)
			-- Use at own discretion
			if diff > delta then
		--	if diff > 2*delta then 
				zo_callLater(frameLoop, diff)
		--	elseif diff > delta then
		--		local delay = max(0, diff - delta)
		--		zo_callLater(frameLoop, delay)
			else
				frameLoop()
			end
		else
			te.EM:UnregisterForUpdate(te.name.."ReplayStatus")
			local currentTime = GetGameTimeMilliseconds() - te.startTime
			local desync = te.scenarioTime - currentTime
			te.UI.replayInfo:SetText(string.format(te.replayStatusTemplate, te.replayLength, te.replayDuration, desync, te.scenarioTime, currentTime, te.frameNum))
			--df("scenario replay: %s frames covering %dms (real time %dms)", lastFrameNum - startFrame, lastFrame - firstFrame, GetGameTimeMilliseconds() - startTime)
		end
	end

	updateStatus()
	te.EM:RegisterForUpdate(te.name.."ReplayStatus", 10, updateStatus)
	frameLoop()
end

