Testify = Testify or { }
local te = Testify

local strfmt = string.format
local strsub = string.sub
local tonumber = tonumber
local tinsert = table.insert
local gmatch = string.gmatch

--local typeTranslator = {
--	["number"] = "n",
--	["boolean"] = "b",
--	["string"] = "s",
--}

-- replay frame: [int] = {timestamp, {eventData}}

-- sample table:
-- {1000, {131106, 2250, nil, "Ranger", 0, 0, nil, 0, "My Slap on One^Fx", 1, 0, -1, 1, nil, 0, 48207, 45493, 0}},
-- n&3e8&n&20022&n&8ca&x&n&s&Ranger&n&0&n&0&x&n&n&0&s&My Slap on One^Fx&n&1&n&0&n&-1&n&1&x&n&n&0&n&bc4f&n&b1b5&n&0
-- n3e8&n20022&n8ca&xn&sRanger&n0&n0&xn&n0&sMy Slap on One^Fx&n1&n0&n-1&n1&xn&n0&nbc4f&nb1b5&n0
-- n3e8&h20022&h8ca&x&sRanger&n0&n0&x&n0&sMy Slap on One^Fx&n1&n0&n-1&n1&x&n0&hbc4f&hb1b5&n0 -- current

function te.DataToString(frame)
	local str = ""
	str = strfmt("h%x", frame[1])
	for i = 1, #frame[2] do
		local v = frame[2][i]
		local t = type(v)
		if t == "string" then
			str = strfmt("%s&s%s", str, v)
		elseif t == "number" then
			if v > 9 then
				str = strfmt("%s&h%x", str, v)
			else
				str = strfmt("%s&n%d", str, v)
			end
		elseif t == "boolean" then
			local val = v and "t" or "f"
			str = strfmt("%s&b%s", str, val)
		elseif t == "nil" then
			str = strfmt("%s&x", str)
		end
	end
	return str
end

function te.StringToData(str)
	local out = { }
	local holding = { }
	for w in gmatch(str, "[^&]+") do
		tinsert(holding, w)
	end
	out[1] = tonumber(strsub(holding[1], 2), 16)
	out[2] = { }
	for i = 2, #holding do
		local t = strsub(holding[i], 1, 1)
		if t ~= "x" then
			local d = strsub(holding[i], 2)
			if t == "n" then
				out[2][i-1] = tonumber(d)
			elseif t == "h" then
				out[2][i-1] = tonumber(d, 16)
			elseif t == "b" then
				out[2][i-1] = d == "t" and true or false
			elseif t == "s" then
				out[2][i-1] = d
			end
		end
	end
	return out
end
