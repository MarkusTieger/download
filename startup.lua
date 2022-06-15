--[[This is a fix of the original version (https://pastebin.com/knPtJCjb). Thanks to https://pastebin.com/dyre9saS and https://pastebin.com/gyMNUyRb for providing a fix to the clock while I was distracted from this project. I've remade the getTime function to make it work with Timezones again]] 
local mon = peripheral.find("monitor")
local core = peripheral.find("draconic_rf_storage")
local tier = 0
local colorShield = colors.white
local colorCore = colors.white
local input, output = peripheral.find("flux_gate")
local limitTransfer = true
local currentControls = "main"
local page = 1
local putLimit = ""
local version = "1.0"
local timediff = 0
local monthDays = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 ,31}

if fs.exists("logs.cfg") then
else
	file = io.open("logs.cfg", "w")
	file:write("")
	file:close()
end

if fs.exists("config.cfg") then
else
	file = io.open("config.cfg", "w")
	file:write("Timezone: 0")
	file:close()
end

mon.setTextScale(1)

local function fileWrite(path, text)
	local file = io.open(path, "w")
	file:write(text)
	file:close()
end

local function fileWriteFromTable(path, t)
	local text = ""
	for _, line in pairs(t) do
		text = text..line.."\n"
	end
	fileWrite(path, text)
end

local function fileGetTable(path)
	if fs.exists(path) then
		local file = io.open(path, "r")
		local lines = {}
		local i = 1
		local line = file:read("*l")
		while line ~= nil do
			lines[i] = line
			line = file:read("*l")
			i = i +1
		end
		file:close()
		return lines
	end
	return {}
end

local function fileReplaceLine(path, n, text)
	local lines = fileGetTable(path)
	lines[n] = text
	fileWriteFromTable(path, lines)
end

local function fileAppend(path, text)
	local file = io.open(path, "a")
	file:write(text.."\n")
	file:close()
end

local function fileGetLength(path)
	local file = io.open(path, "r")
	local i = 0
	while file:read("*l") ~= nil do
		i = i +1
	end
	file:close()
	return i
end

local function fileGetLines(path, startN, endN)
	local lines = fileGetTable(path)
	local linesOut = {}
	local x = 1
	for i = startN, endN, 1 do
		linesOut[x] = lines[i]
		x = x + 1
	end
	return linesOut	
end

local function editConfigFile(path,line,text)
	fileReplaceLine(path,line,text)
end

local function detectInOutput()
	input, output = peripheral.find("flux_gate")
	--print(input)
	--print(output)
	if core.getTransferPerTick() ~= 0 then
		if core.getTransferPerTick() < 0 then
			output.setSignalLowFlow(0)
			sleep(2)
			if core.getTransferPerTick() >= 0 then
				--keep it
			else
				output, input = peripheral.find("flux_gate")
			end
			output.setSignalLowFlow(2147483647)
			input.setSignalLowFlow(2147483647)
		elseif core.getTransferPerTick() > 0 then
			input.setSignalLowFlow(0)
			sleep(2)
			if core.getTransferPerTick() <= 0 then
				--keep it
			else
				output, input = peripheral.find("flux_gate")
			end
			output.setSignalLowFlow(2147483647)
			input.setSignalLowFlow(2147483647)
		end
	end	
end

if peripheral.find("flux_gate") == nil then
	limitTransfer = false
else 
	limitTransfer = true
	detectInOutput()
end

local function makeNumber2Digits(number)
    strNumber = tostring(number)
    if string.len(strNumber) == 1 then
        return "0" .. strNumber
    else
        return string.sub(strNumber, string.len(strNumber) - 2)
    end
end

local function getTime(long)
    date_table = os.date("*t")

    hour, minute, second = date_table.hour, date_table.min, date_table.sec
    year, month, day = date_table.year, date_table.month, date_table.day

	timezoneConfig = fileGetLines("config.cfg",1,1)
    timedifflocal = tonumber(string.sub(timezoneConfig[1], 10))

    if hour + timedifflocal > 24 then 
        if day + 1 > monthDays[month] then
            if month + 1 > 12 then
                year = year + 1
                month = 1
                day = 1
                hour = hour + timedifflocal - 24
            else 
                month = month + 1
                day = 1
                hour = hour + timedifflocal - 24
            end
        else
            day = day + 1
            hour = hour + timedifflocal - 24
        end
    elseif hour + timedifflocal < 0 then
        if day - 1 < 1 then
            if month -1 < 1 then
                year = year - 1
                month = 12
                day = monthDays[12]
                hour = hour + timedifflocal + 24
            else 
                month = month - 1
                day = monthDays[month]
                hour = hour + timedifflocal + 24
            end
        else
            day = day - 1
            hour = hour + timedifflocal + 24
        end
    else
        hour = hour + timedifflocal
    end
    if long then
        return string.format("%s.%s.%d %s:%s:%s", makeNumber2Digits(day), makeNumber2Digits(month), year, makeNumber2Digits(hour), makeNumber2Digits(minute), makeNumber2Digits(second))
    else
        return string.format("%s.%s.%d %s:%s", makeNumber2Digits(day), makeNumber2Digits(month), year, makeNumber2Digits(hour), makeNumber2Digits(minute))
    end
end

local function getLogs(path, xPos, yPos)
	local Logs = fileGetLines(path, fileGetLength(path)-5, fileGetLength(path))
	for i = 1, 6, 1 do
		mon.setCursorPos(xPos+2,yPos+1+i)
		mon.write(Logs[i])
	end
end

local function addLog(path, time, text)
	fileAppend(path, "["..time.."]")
	fileAppend(path, text)
end

local function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function convertRF(rf)
	rfString = ""
	if rf < 1000 then
		rfString = tostring(rf)
	elseif rf < 1000000 then
		rfString = tostring(round((rf/1000),1)).."k"
	elseif rf < 1000000000 then
		rfString = tostring(round((rf/1000000),1)).."M"
	elseif rf < 1000000000000 then
		rfString = tostring(round((rf/1000000000),1)).."G"
	elseif rf < 1000000000000000 then
		rfString = tostring(round((rf/1000000000000),1)).."T"
	elseif rf < 1000000000000000000 then
		rfString = tostring(round((rf/1000000000000000),1)).."P"
	elseif rf < 1000000000000000000000 then
		rfString = tostring(round((rf/1000000000000000000),1)).."E"
	end
	return(rfString.."RF")
end

local function drawL1(xPos, yPos)
	mon.setCursorPos(xPos, yPos)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+1)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+2)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+3)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+4)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+5)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+6)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+7)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+8)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
end

local function drawL2(xPos, yPos)
	mon.setCursorPos(xPos, yPos)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+1)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+2)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+3)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+4)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+5)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+6)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+7)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+8)
	mon.write(" ")
end

local function drawL3(xPos, yPos)
	mon.setCursorPos(xPos, yPos)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+1)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+2)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+3)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+4)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+5)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+6)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+7)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+8)
	mon.write(" ")
end

local function drawL4(xPos, yPos)
	mon.setCursorPos(xPos, yPos)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+1)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+2)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+3)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+4)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+5)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+6)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+7)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+8)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
end

local function drawL5(xPos, yPos)
	mon.setCursorPos(xPos, yPos)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+1)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+2)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+3)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+4)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+5)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+6)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+7)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+8)
	mon.write(" ")
end

local function drawL6(xPos, yPos)
	mon.setCursorPos(xPos, yPos)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+1)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+2)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+3)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+4)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+5)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+6)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+7)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+8)
	mon.write(" ")
end

local function drawL7(xPos, yPos)
	mon.setCursorPos(xPos, yPos)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+1)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+2)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+3)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+4)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+5)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+6)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+7)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+8)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
end

local function drawL8(xPos, yPos)
	mon.setCursorPos(xPos, yPos)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+1)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+2)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+3)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+4)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+5)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+6)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+7)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+8)
	mon.write(" ")
end

local function drawL9(xPos, yPos)
	mon.setCursorPos(xPos, yPos)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+1)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+2)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+3)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+4)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+5)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+6)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+7)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+8)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
end

local function drawL10(xPos, yPos)
	mon.setCursorPos(xPos, yPos)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+1)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+2)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+3)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+4)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+5)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+6)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+7)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+8)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
end

local function drawL11(xPos, yPos)
	mon.setCursorPos(xPos, yPos)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+1)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+2)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+3)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+4)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+5)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+6)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+7)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+8)
	mon.write(" ")
end

local function drawL12(xPos, yPos)
	mon.setCursorPos(xPos, yPos)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+1)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+2)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+3)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+4)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+5)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+6)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+7)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+8)
	mon.write(" ")
end

local function drawL13(xPos, yPos)
	mon.setCursorPos(xPos, yPos)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+1)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+2)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+3)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+4)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+5)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+6)
	mon.setBackgroundColor(colorShield)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+7)
	mon.setBackgroundColor(colorCore)
	mon.write(" ")
	mon.setCursorPos(xPos, yPos+8)
	mon.write(" ")
end

local function drawBox(xMin, xMax, yMin, yMax, title)
	mon.setBackgroundColor(colors.gray)
	for xPos = xMin, xMax, 1 do
		mon.setCursorPos(xPos, yMin)
		mon.write(" ")
	end
	for yPos = yMin, yMax, 1 do
		mon.setCursorPos(xMin, yPos)
		mon.write(" ")
		mon.setCursorPos(xMax, yPos)
		mon.write(" ")
	end
	for xPos = xMin, xMax, 1 do
		mon.setCursorPos(xPos, yMax)
		mon.write(" ")
	end
	mon.setCursorPos(xMin+2, yMin)
	mon.setBackgroundColor(colors.black)
	mon.write(" ")
	mon.write(title)
	mon.write(" ")
end	

local function drawButton(xMin, xMax, yMin, yMax, text1, text2, bcolor)
    mon.setBackgroundColor(bcolor)
    for yPos = yMin, yMax, 1 do
        for xPos = xMin, xMax, 1 do
            mon.setCursorPos(xPos, yPos)
            mon.write(" ")
        end
    end
    mon.setCursorPos(math.floor((((xMax+xMin)/2)+0.5)-string.len(text1)/2),math.floor(((yMax+yMin)/2)))
    mon.write(text1)
    if text2 == nil then
    else
        mon.setCursorPos(math.floor((((xMax+xMin)/2)+0.5)-string.len(text2)/2),math.floor(((yMax+yMin)/2)+0.5))
        mon.write(text2)
    end
    mon.setBackgroundColor(colors.black)
end

local function drawClear(xMin, xMax, yMin, yMax)
mon.setBackgroundColor(colors.black)
	for yPos = yMin, yMax, 1 do
		for xPos = xMin, xMax, 1 do
			mon.setCursorPos(xPos, yPos)
			mon.write(" ")
		end
	end
end

local function drawNumpad(xPos ,yPos)
	mon.setCursorPos(xPos+2,yPos+4)
	mon.setBackgroundColor(colors.lightGray)
	mon.write(" 1 ")
	mon.setBackgroundColor(colors.gray)
	mon.write(" ")
	mon.setCursorPos(xPos+6,yPos+4)
	mon.setBackgroundColor(colors.lightGray)
	mon.write(" 2 ")
	mon.setBackgroundColor(colors.gray)
	mon.write(" ")
	mon.setCursorPos(xPos+10,yPos+4)
	mon.setBackgroundColor(colors.lightGray)
	mon.write(" 3 ")
	mon.setCursorPos(xPos+2,yPos+5)
	mon.setBackgroundColor(colors.lightGray)
	mon.write(" 4 ")
	mon.setBackgroundColor(colors.gray)
	mon.write(" ")
	mon.setCursorPos(xPos+6,yPos+5)
	mon.setBackgroundColor(colors.lightGray)
	mon.write(" 5 ")
	mon.setBackgroundColor(colors.gray)
	mon.write(" ")
	mon.setCursorPos(xPos+10,yPos+5)
	mon.setBackgroundColor(colors.lightGray)
	mon.write(" 6 ")
	mon.setCursorPos(xPos+2,yPos+6)
	mon.setBackgroundColor(colors.lightGray)
	mon.write(" 7 ")
	mon.setBackgroundColor(colors.gray)
	mon.write(" ")
	mon.setCursorPos(xPos+6,yPos+6)
	mon.setBackgroundColor(colors.lightGray)
	mon.write(" 8 ")
	mon.setBackgroundColor(colors.gray)
	mon.write(" ")
	mon.setCursorPos(xPos+10,yPos+6)
	mon.setBackgroundColor(colors.lightGray)
	mon.write(" 9 ")
	mon.setCursorPos(xPos+2,yPos+7)
	mon.setBackgroundColor(colors.red)
	mon.write(" < ")
	mon.setBackgroundColor(colors.gray)
	mon.write(" ")
	mon.setCursorPos(xPos+6,yPos+7)
	mon.setBackgroundColor(colors.lightGray)
	mon.write(" 0 ")
	mon.setBackgroundColor(colors.gray)
	mon.write(" ")
	mon.setCursorPos(xPos+10,yPos+7)
	mon.setBackgroundColor(colors.red)
	mon.write(" X ")
	mon.setCursorPos(xPos+16,yPos+5)
	mon.setBackgroundColor(colors.lime)
	mon.write(" Apply")
	mon.setCursorPos(xPos+16,yPos+7)
	mon.setBackgroundColor(colors.red)
	mon.write("Cancel")
	mon.setBackgroundColor(colors.black)
end	
local function drawControls(xPos, yPos)
	if currentControls == "main" then
		--drawClear(xPos+1,xPos+22,yPos+1,yPos+8)
		if limitTransfer == false then
			drawButton(xPos+2,xPos+9,yPos+2,yPos+3,"Edit","InputMax",colors.gray)
			drawButton(xPos+13,xPos+21,yPos+2,yPos+3,"Edit","OutputMax",colors.gray)
		else
			drawButton(xPos+2,xPos+9,yPos+2,yPos+3,"Edit","InputMax",colors.lime)
			drawButton(xPos+13,xPos+21,yPos+2,yPos+3,"Edit","OutputMax",colors.red)
		end
		drawButton(xPos+2,xPos+9,yPos+6,yPos+7,"Edit","Config",colorCore)
		drawButton(xPos+13,xPos+21,yPos+6,yPos+7,"No Use","Yet",colors.gray)
	elseif currentControls == "editInput" or currentControls == "editOutput" then
		--drawClear(xPos+1,xPos+22,yPos+1,yPos+8)
		mon.setCursorPos(xPos+2,yPos+2)
		if currentControls == "editInput" then
			mon.write("Edit Max Input Rate")
		else
			mon.write("Edit Max Output Rate")
		end
		mon.setCursorPos(xPos+2,yPos+3)
		mon.setBackgroundColor(colors.gray)
		mon.write("___________")
		if string.len(putLimit) >= 11 then
				putLimit = string.sub(putLimit,string.len(putLimit)-10)
		end
		if putLimit ~= "" then
			if tonumber(putLimit) <= 2147483647 then
				mon.setCursorPos(xPos+13-string.len(putLimit),yPos+3)
				mon.write(putLimit)
				putLimitNum = tonumber(putLimit)
				mon.setBackgroundColor(colors.black)
				fix = 0
				if putLimitNum < 1000 then
					if string.len(putLimit) <= 3 then
						mon.setCursorPos(xPos+22-string.len(putLimit)-2,yPos+3)
						mon.write(putLimit)
					else
						mon.setCursorPos(xPos+22-4-2,yPos+3)
						mon.write(string.sub(putLimit,string.len(putLimit)-2))
					end
				elseif putLimitNum < 1000000 then
						if (round((putLimitNum/1000),1)*10)/(round((putLimitNum/1000),0)) == 10 then
							fix = 2
						end
					mon.setCursorPos(xPos+22-string.len(tostring(round((putLimitNum/1000),1)))-3-fix,yPos+3)
					mon.write(round((putLimitNum/1000),1))
					mon.write("k")
				elseif putLimitNum < 1000000000 then
						--if putLimitNum == 1000000*i or putLimitNum == 10000000*i or putLimitNum == 100000000*i then
						if (round((putLimitNum/1000000),1)*10)/(round((putLimitNum/1000000),0)) == 10 then
							fix = 2
						end	
					mon.setCursorPos(xPos+22-string.len(tostring(round((putLimitNum/1000000),1)))-3-fix,yPos+3)
					mon.write(round((putLimitNum/1000000),1))
					mon.write("M")
				elseif putLimitNum < 1000000000000 then
						if (round((putLimitNum/1000000000),1)*10)/(round((putLimitNum/1000000000),0)) == 10 then
							fix = 2
						end	
					mon.setCursorPos(xPos+22-string.len(tostring(round((putLimitNum/1000000000),1)))-3-fix,yPos+3)
					mon.write(round((putLimitNum/1000000000),1))
					mon.write("G")
				end
				mon.write("RF")
			else
				putLimit = "2147483647"
				mon.setCursorPos(xPos+13-string.len(putLimit),yPos+3)
				mon.write(putLimit)
				mon.setCursorPos(xPos+22-6,yPos+3)
				mon.setBackgroundColor(colors.black)
				mon.write("2.1GRF")
				mon.setCursorPos(xPos+22-6,yPos+4)
				mon.write("(max)")
				
			end
			
		end
		drawNumpad(xPos, yPos)
	elseif currentControls == "editOutput" then
	elseif currentControls == "editConfig" then
		mon.setCursorPos(xPos+2,yPos+2)
		mon.write("Edit Config")
		if limitTransfer == true then
			drawButton(xPos+2,xPos+10,yPos+3,yPos+4,"Detect","Flux_Gate",colorCore)
		else
			drawButton(xPos+2,xPos+10,yPos+3,yPos+4,"Detect","Flux_Gate",colors.gray)
		end
		drawButton(xPos+14,xPos+21,yPos+3,yPos+4,"Edit","Timezone",colorCore)
		mon.setCursorPos(xPos+16,yPos+7)
		mon.setBackgroundColor(colors.red)
		mon.write("Cancel")
		mon.setCursorPos(xPos+2,yPos+7)
		mon.setBackgroundColor(colors.gray)
		mon.write("Prev")
		mon.setCursorPos(xPos+7,yPos+7)
		mon.write("Next")
		mon.setBackgroundColor(colors.black)
	elseif currentControls == "editTimezone" then
		mon.setCursorPos(xPos+2,yPos+2)
		mon.write("Type Differenz")
		mon.setCursorPos(xPos+5,yPos+4)
		mon.setBackgroundColor(colors.red)
		mon.write(" -1 ")
		mon.setBackgroundColor(colors.lightGray)
		mon.write(" ")
		mon.setBackgroundColor(colors.gray)
		mon.write("   ")
		if timediff >= -12 and timediff <= 12 then
		elseif timediff < -12 then
			timediff = -12
		elseif timediff > 12 then
			timediff = 12
		end
		mon.setCursorPos(xPos+13-string.len(tostring(timediff)),yPos+4)
		mon.setBackgroundColor(colors.gray)
		mon.write(tostring(timediff))
		mon.setBackgroundColor(colors.lightGray)
		mon.write(" ")
		mon.setBackgroundColor(colors.lime)
		mon.write(" +1 ")
		mon.setCursorPos(xPos+9,yPos+7)
		mon.setBackgroundColor(colors.red)
		mon.write("Cancel")
		mon.setBackgroundColor(colors.black)
		mon.write(" ")
		mon.setBackgroundColor(colors.lime)
		mon.write(" Apply")
		mon.setBackgroundColor(colors.black)
	end
end

local alarm = false

local function onAlarmOff()
    if alarm == true then
        addLog("logs.cfg",getTime(false),"Alarm turned off")
        alarm = false
    end
end

local function onAlarmOn()
    if alarm == false then
        addLog("logs.cfg",getTime(false),"Alarm turned on")
        alarm = true
    end
end

local function checkReactor(energyTransfer)
	if energyTransfer < 20000000 then
		redstone.setOutput("right", true)

        onAlarmOn()
    else
        redstone.setOutput("right", false)

        onAlarmOff()
	end
end

local function drawDetails(xPos, yPos)
	energyStored = core.getEnergyStored()
	energyMax = core.getMaxEnergyStored()
	energyTransfer = core.getTransferPerTick()

    checkReactor(energyTransfer)


	if limitTransfer == true then
		inputRate = input.getFlow()
		outputRate = output.getFlow()
	end
	mon.setCursorPos(xPos, yPos)
	if energyMax < 50000000 then
		tier = 1
	elseif energyMax < 300000000 then
		tier = 2
	elseif energyMax < 2000000000 then
		tier = 3 
	elseif energyMax < 10000000000 then
		tier = 4
	elseif energyMax < 50000000000 then
		tier = 5
	elseif energyMax < 400000000000 then
		tier = 6
	elseif energyMax < 3000000000000 then
		tier = 7
	else
		tier = 8
	end
	mon.write("Tier: ")
	mon.write(tier)
	mon.setCursorPos(xPos+7, yPos)
	mon.write("  ")
	mon.setCursorPos(xPos, yPos+1)
	mon.write("Stored: ")
	if energyStored < 1000 then
		mon.write(energyStored)
	elseif energyStored < 1000000 then
		mon.write(round((energyStored/1000),1))
		mon.write("k")
	elseif energyStored < 1000000000 then
		mon.write(round((energyStored/1000000),1))
		mon.write("M")
	elseif energyStored < 1000000000000 then
		mon.write(round((energyStored/1000000000),1))
		mon.write("G")
	elseif energyStored < 1000000000000000 then
		mon.write(round((energyStored/1000000000000),1))
		mon.write("T")
	elseif energyStored < 1000000000000000000 then
		mon.write(round((energyStored/1000000000000000),1))
		mon.write("P")
	elseif energyStored < 1000000000000000000000 then
		mon.write(round((energyStored/1000000000000000000),1))
		mon.write("E")
	end
	mon.write("RF")
	mon.write("/")
	if energyMax < 1000 then
		mon.write(energyMax)
	elseif energyMax < 1000000 then
		mon.write(round((energyMax/1000),1))
		mon.write("k")
	elseif energyMax < 1000000000 then
		mon.write(round((energyMax/1000000),1))
		mon.write("M")
	elseif energyMax < 1000000000000 then
		mon.write(round((energyMax/1000000000),1))
		mon.write("G")
	elseif energyMax < 1000000000000000 then
		mon.write(round((energyMax/1000000000000),1))
		mon.write("T")
	elseif energyMax < 1000000000000000000 then
		mon.write(round((energyMax/1000000000000000	),1))
		mon.write("P")
	elseif energyMax < 1000000000000000000000 then
		mon.write(round((energyMax/1000000000000000000),1))
		mon.write("E")
	end
	mon.write("RF")
	mon.setCursorPos(xPos, yPos+2)
	mon.setBackgroundColor(colors.lightGray)
	for l = 1, 20, 1 do
		mon.write(" ")
	end
	mon.setCursorPos(xPos, yPos+2)
	mon.setBackgroundColor(colors.lime)
	for l = 0, round((((energyStored/energyMax)*10)*2)-1,0), 1 do
		mon.write(" ")
	end
	mon.setCursorPos(xPos, yPos+3)
	mon.setBackgroundColor(colors.lightGray)
	for l = 1, 20, 1 do
		mon.write(" ")
	end
	mon.setCursorPos(xPos, yPos+3)
	mon.setBackgroundColor(colors.lime)
	for l = 0, round((((energyStored/energyMax)*10)*2)-1,0), 1 do
		mon.write(" ")
	end
	mon.setBackgroundColor(colors.black)
	mon.setCursorPos(xPos, yPos+4)
	mon.write("                      ")
	if string.len(tostring(round((energyStored/energyMax)*100))) == 1 then
		if round((energyStored/energyMax)*100) <= 10 then
			mon.setCursorPos(xPos, yPos+4)
			mon.write(round((energyStored/energyMax)*100))
			mon.setCursorPos(xPos+1, yPos+4)
			mon.write("% ")
		else
			mon.setCursorPos(xPos+round((((energyStored/energyMax)*100)-10)/5), yPos+4)
			mon.write(round((energyStored/energyMax)*100))
			mon.setCursorPos(xPos+round((((energyStored/energyMax)*100)-10)/5)+1, yPos+4)
			mon.write("% ")
		end
	elseif string.len(tostring(round((energyStored/energyMax)*100))) == 2 then
		if round((energyStored/energyMax)*100) <= 15 then
			mon.setCursorPos(xPos, yPos+4)
			mon.write(round((energyStored/energyMax)*100))
			mon.setCursorPos(xPos+2, yPos+4)
			mon.write("% ")
		else
			mon.setCursorPos(xPos+round((((energyStored/energyMax)*100)-15)/5), yPos+4)
			mon.write(round((energyStored/energyMax)*100))
			mon.setCursorPos(xPos+round((((energyStored/energyMax)*100)-15)/5)+2, yPos+4)
			mon.write("% ")
		end
	elseif string.len(tostring(round((energyStored/energyMax)*100))) == 3 then
		if round((energyStored/energyMax)*100) <= 20 then
			mon.setCursorPos(xPos, yPos+4)
			mon.write(round((energyStored/energyMax)*100))
			mon.setCursorPos(xPos+3, yPos+4)
			mon.write("% ")
		else
			mon.setCursorPos(xPos+round((((energyStored/energyMax)*100)-20)/5), yPos+4)
			mon.write(round((energyStored/energyMax)*100))
			mon.setCursorPos(xPos+round((((energyStored/energyMax)*100)-20)/5)+3, yPos+4)
			mon.write("% ")
		end
	end
	mon.setCursorPos(xPos, yPos+5)
	mon.write("InputMax:")
	mon.setCursorPos(xPos, yPos+6)
	mon.write("         ")
	mon.setCursorPos(xPos, yPos+6)
	mon.setTextColor(colors.lime)
	if limitTransfer == true then
		if inputRate == 0 then
			mon.setTextColor(colors.red)
		end
		if inputRate < 1000 then
			mon.write(inputRate)
		elseif inputRate < 1000000 then
			mon.write(round((inputRate/1000),1))
			mon.write("k")
		elseif inputRate < 1000000000 then
			mon.write(round((inputRate/1000000),1))
			mon.write("M")
		elseif inputRate < 1000000000000 then
			mon.write(round((inputRate/1000000000),1))
			mon.write("G")
		elseif inputRate < 1000000000000000 then
			mon.write(round((inputRate/1000000000000),1))
			mon.write("T")
		elseif inputRate < 1000000000000000000 then
			mon.write(round((inputRate/1000000000000000	),1))
			mon.write("P")
		elseif inputRate < 1000000000000000000000 then
			mon.write(round((inputRate/1000000000000000000),1))
			mon.write("E")
		end
		mon.write("RF")
	else
		mon.write("INFINITE")
	end
	mon.setTextColor(colors.white)
	mon.setCursorPos(xPos+12, yPos+5)
	mon.write("OutputMax:")
	mon.setCursorPos(xPos+12, yPos+6)
	mon.write("         ")
	mon.setTextColor(colors.red)
	mon.setCursorPos(xPos+12, yPos+6)
	if limitTransfer == true then
		if outputRate < 1000 then
			mon.write(outputRate)
		elseif outputRate < 1000000 then
			mon.write(round((outputRate/1000),1))
			mon.write("k")
		elseif outputRate < 1000000000 then
			mon.write(round((outputRate/1000000),1))
			mon.write("M")
		elseif outputRate < 1000000000000 then
			mon.write(round((outputRate/1000000000),1))
			mon.write("G")
		elseif outputRate < 1000000000000000 then
			mon.write(round((outputRate/1000000000000),1))
			mon.write("T")
		elseif outputRate < 1000000000000000000 then
			mon.write(round((outputRate/1000000000000000),1))
			mon.write("P")
		elseif outputRate < 1000000000000000000000 then
			mon.write(round((outputRate/1000000000000000000),1))
			mon.write("E")
		end
		mon.write("RF")
	else
		mon.write("INFINITE")
	end
	mon.setTextColor(colors.white)
	mon.setCursorPos(xPos, yPos+7)
	mon.write("Transfer:")
	mon.setCursorPos(xPos, yPos+8)
	if energyTransfer < 0 then
		mon.setTextColor(colors.red)
		if energyTransfer*(-1) < 1000 then
			mon.write(energyTransfer)
		elseif energyTransfer*(-1) < 1000000 then
			mon.write(round((energyTransfer/1000),1))
			mon.write("k")
		elseif energyTransfer*(-1) < 1000000000 then
			mon.write(round((energyTransfer/1000000),1))
			mon.write("M")
		elseif energyTransfer*(-1) < 1000000000000 then
			mon.write(round((energyTransfer/1000000000),1))
			mon.write("G")
		elseif energyTransfer*(-1) < 1000000000000000 then
			mon.write(round((energyTransfer/1000000000000),1))
			mon.write("T")
		elseif energyTransfer*(-1) < 1000000000000000000 then
			mon.write(round((energyTransfer/1000000000000000),1))
			mon.write("P")
		elseif energyTransfer*(-1) < 1000000000000000000000 then
			mon.write(round((energyTransfer/1000000000000000000),1))
			mon.write("E")
		end
	elseif energyTransfer == 0 then
		mon.setTextColor(colors.red)
		mon.write("0")
	else 
		mon.setTextColor(colors.lime)
		if energyTransfer < 1000 then
			mon.write(energyTransfer)
		elseif energyTransfer < 1000000 then
			mon.write(round((energyTransfer/1000),1))
			mon.write("k")
		elseif energyTransfer < 1000000000 then
			mon.write(round((energyTransfer/1000000),1))
			mon.write("M")
		elseif energyTransfer < 1000000000000 then
			mon.write(round((energyTransfer/1000000000),1))
			mon.write("G")
		elseif energyTransfer < 1000000000000000 then
			mon.write(round((energyTransfer/1000000000000),1))
			mon.write("T")
		elseif energyTransfer < 1000000000000000000 then
			mon.write(round((energyTransfer/1000000000000000),1))
			mon.write("P")
		elseif energyTransfer < 1000000000000000000000 then
			mon.write(round((energyTransfer/1000000000000000000),1))
			mon.write("E")
		end
	end
	mon.write("RF")
	mon.setTextColor(colors.white)
	mon.setCursorPos(xPos+12, yPos+7)
	mon.write("Limited:")
	mon.setCursorPos(xPos+12, yPos+8)
	if limitTransfer == true then
		mon.setTextColor(colors.lime)
		mon.write("On")
	else
		mon.setTextColor(colors.red)
		mon.write("Off")
	end
	mon.setTextColor(colors.white)
end

local function drawAll()	
	while true do
		mon.clear()
		versionText = "Edited by MarkusTieger"
		verPos = 51 - string.len(versionText)
		mon.setCursorPos(verPos,26)
		mon.setTextColor(colors.gray)
		mon.write(versionText)
		mon.setTextColor(colors.white)
		drawBox(2,20,2,14,"ENERGY CORE")
		drawBox(22,49,2,14,"DETAILS")
		drawBox(2,24,16,25,"LOGS")
		drawBox(26,49,16,25,"CONTROLS")
		yPos = 4
		xMin = 5
		for xPos = xMin, xMin+12, 1 do
			drawDetails(24,4)
			drawControls(26,16)
			getLogs("logs.cfg",2,16)
			if tier <= 7 then
				colorShield = colors.lightBlue
				colorCore = colors.cyan
			else
				colorShield = colors.yellow
				colorCore = colors.orange
			end
			xPos1 = xPos
			if xPos1 >= xMin+13 then
				xPos1a = xPos1 - 13
				drawL1(xPos1a, yPos)
			else
				drawL1(xPos1, yPos)
			end
			xPos2 = xPos + 1
			if xPos2 >= xMin+13 then
				xPos2a = xPos2 - 13
				drawL2(xPos2a, yPos)
			else
				drawL2(xPos2, yPos)
			end
			xPos3 = xPos + 2
			if xPos3 >= xMin+13 then
				xPos3a = xPos3 - 13
				drawL3(xPos3a, yPos)
			else
				drawL3(xPos3, yPos)
			end
			xPos4 = xPos + 3
			if xPos4 >= xMin+13 then
				xPos4a = xPos4 - 13
				drawL4(xPos4a, yPos)
			else
				drawL4(xPos4, yPos)
			end
			xPos5 = xPos + 4
			if xPos5 >= xMin+13 then
				xPos5a = xPos5 - 13
				drawL5(xPos5a, yPos)
			else
				drawL5(xPos5, yPos)
			end
			xPos6 = xPos + 5
			if xPos6 >= xMin+13 then
				xPos6a = xPos6 - 13
				drawL6(xPos6a, yPos)
			else
				drawL6(xPos6, yPos)
			end
			xPos7 = xPos + 6
			if xPos7 >= xMin+13 then
				xPos7a = xPos7 - 13
				drawL7(xPos7a, yPos)
			else
				drawL7(xPos7, yPos)
			end
			xPos8 = xPos + 7
			if xPos8 >= xMin+13 then
				xPos8a = xPos8 - 13
				drawL8(xPos8a, yPos)
			else
				drawL8(xPos8, yPos)
			end
			xPos9 = xPos + 8
			if xPos9 >= xMin+13 then
				xPos9a = xPos9 - 13
				drawL9(xPos9a, yPos)
			else
				drawL9(xPos9, yPos)
			end
			xPos10 = xPos + 9
			if xPos10 >= xMin+13 then
				xPos10a = xPos10 - 13
				drawL10(xPos10a, yPos)
			else
				drawL10(xPos10, yPos)
			end
			xPos11 = xPos + 10
			if xPos11 >= xMin+13 then
				xPos11a = xPos11 - 13
				drawL11(xPos11a, yPos)
			else
				drawL11(xPos11, yPos)
			end
			xPos12 = xPos + 11
			if xPos12 >= xMin+13 then
				xPos12a = xPos12 - 13
				drawL12(xPos12a, yPos)
			else
				drawL12(xPos12, yPos)
			end
			xPos13 = xPos + 12
			if xPos13 >= xMin+13 then
				xPos13a = xPos13 - 13
				drawL13(xPos13a, yPos)
			else
				drawL13(xPos13, yPos)
			end
			mon.setBackgroundColor(colors.black)
			mon.setCursorPos(xMin, yPos)
			mon.write("   ")
			mon.setCursorPos(xMin+10, yPos)
			mon.write("   ")
			mon.setCursorPos(xMin, yPos+1)
			mon.write(" ")
			mon.setCursorPos(xMin+12, yPos+1)
			mon.write(" ")
			mon.setCursorPos(xMin, yPos+7)
			mon.write(" ")
			mon.setCursorPos(xMin+12, yPos+7)
			mon.write(" ")
			mon.setCursorPos(xMin, yPos+8)
			mon.write("   ")
			mon.setCursorPos(xMin+10, yPos+8)
			mon.write("   ")
			mon.setCursorPos(51 - string.len(getTime(true)),1)
			mon.write(getTime(true))
			sleep(1)
		end
	end
end

local function clickListener()
	event, side, xCPos, yCPos = os.pullEvent("monitor_touch")
	if xCPos == 1 and yCPos == 1 then
		mon.setCursorPos(1,1)
		mon.write("Click!")
		sleep(1)
		mon.write("      ")
	end
	if currentControls == "main" then
		if xCPos >= 28 and xCPos <= 35 and yCPos >= 18 and yCPos <= 19 and limitTransfer == true then
			drawClear(27,48,17,24)
			currentControls = "editInput"
		elseif xCPos >= 39 and xCPos <= 47 and yCPos >= 18 and yCPos <= 19 and limitTransfer == true then
			drawClear(27,48,17,24)
			currentControls = "editOutput"
		elseif xCPos >= 28 and xCPos <= 35 and yCPos >= 22 and yCPos <= 23 then
			drawClear(27,48,17,24)
			currentControls = "editConfig"
		end
	elseif currentControls == "editInput" or currentControls == "editOutput" then
		if xCPos >= 28 and xCPos <= 30 and yCPos == 20 then
			mon.setCursorPos(28,20)
			mon.setBackgroundColor(colors.gray)
			mon.write(" 1 ")
			putLimit = putLimit .. "1"
			sleep(0.2)
			mon.setCursorPos(28,20)
			mon.setBackgroundColor(colors.lightGray)
			mon.write(" 1 ")
			mon.setBackgroundColor(1,1)
			mon.setBackgroundColor(colors.black)
			mon.write(" ")
		elseif xCPos >= 32 and xCPos <= 34 and yCPos == 20 then
			mon.setCursorPos(32,20)
			mon.setBackgroundColor(colors.gray)
			mon.write(" 2 ")
			putLimit = putLimit .. "2"
			sleep(0.2)
			mon.setCursorPos(32,20)
			mon.setBackgroundColor(colors.lightGray)
			mon.write(" 2 ")
			mon.setBackgroundColor(1,1)
			mon.setBackgroundColor(colors.black)
			mon.write(" ")
			mon.write(" ")
		elseif xCPos >= 36 and xCPos <= 38 and yCPos == 20 then
			mon.setCursorPos(36,20)
			mon.setBackgroundColor(colors.gray)
			mon.write(" 3 ")
			putLimit = putLimit.."3"
			sleep(0.2)
			mon.setCursorPos(36,20)
			mon.setBackgroundColor(colors.lightGray)
			mon.write(" 3 ")
			mon.setBackgroundColor(1,1)
			mon.setBackgroundColor(colors.black)
			mon.write(" ")
		elseif xCPos >= 28 and xCPos <= 30 and yCPos == 21 then
			mon.setCursorPos(28,21)
			mon.setBackgroundColor(colors.gray)
			mon.write(" 4 ")
			putLimit = putLimit.."4"
			sleep(0.2)
			mon.setCursorPos(28,21)
			mon.setBackgroundColor(colors.lightGray)
			mon.write(" 4 ")
			mon.setBackgroundColor(1,1)
			mon.setBackgroundColor(colors.black)
			mon.write(" ")
		elseif xCPos >= 32 and xCPos <= 34 and yCPos == 21 then
			mon.setCursorPos(32,21)
			mon.setBackgroundColor(colors.gray)
			mon.write(" 5 ")
			putLimit = putLimit.."5"
			sleep(0.2)
			mon.setCursorPos(32,21)
			mon.setBackgroundColor(colors.lightGray)
			mon.write(" 5 ")
			mon.setBackgroundColor(1,1)
			mon.setBackgroundColor(colors.black)
			mon.write(" ")
		elseif xCPos >= 36 and xCPos <= 38 and yCPos == 21 then
			mon.setCursorPos(36,21)
			mon.setBackgroundColor(colors.gray)
			mon.write(" 6 ")
			putLimit = putLimit.."6"
			sleep(0.2)
			mon.setCursorPos(36,21)
			mon.setBackgroundColor(colors.lightGray)
			mon.write(" 6 ")
			mon.setBackgroundColor(1,1)
			mon.setBackgroundColor(colors.black)
			mon.write(" ")
		elseif xCPos >= 28 and xCPos <= 30 and yCPos == 22 then
			mon.setCursorPos(28,22)
			mon.setBackgroundColor(colors.gray)
			mon.write(" 7 ")
			putLimit = putLimit.."7"
			sleep(0.2)
			mon.setCursorPos(28,22)
			mon.setBackgroundColor(colors.lightGray)
			mon.write(" 7 ")
			mon.setBackgroundColor(1,1)
			mon.setBackgroundColor(colors.black)
			mon.write(" ")
		elseif xCPos >= 32 and xCPos <= 34 and yCPos == 22 then
			mon.setCursorPos(32,22)
			mon.setBackgroundColor(colors.gray)
			mon.write(" 8 ")
			putLimit = putLimit.."8"
			sleep(0.2)
			mon.setCursorPos(32,22)
			mon.setBackgroundColor(colors.lightGray)
			mon.write(" 8 ")
			mon.setBackgroundColor(1,1)
			mon.setBackgroundColor(colors.black)
			mon.write(" ")
		elseif xCPos >= 36 and xCPos <= 38 and yCPos == 22 then
			mon.setCursorPos(36,22)
			mon.setBackgroundColor(colors.gray)
			mon.write(" 9 ")
			putLimit = putLimit.."9"
			sleep(0.2)
			mon.setCursorPos(36,22)
			mon.setBackgroundColor(colors.lightGray)
			mon.write(" 9 ")
			mon.setBackgroundColor(1,1)
			mon.setBackgroundColor(colors.black)
			mon.write(" ")
		elseif xCPos >= 28 and xCPos <= 30 and yCPos == 23 then
			mon.setCursorPos(28,23)
			mon.setBackgroundColor(colors.gray)
			mon.write(" < ")
			putLimit = string.sub(putLimit,0,string.len(putLimit)-1)
			sleep(0.2)
			mon.setCursorPos(28,23)
			mon.setBackgroundColor(colors.red)
			mon.write(" < ")
			mon.setBackgroundColor(1,1)
			mon.setBackgroundColor(colors.black)
			mon.write(" ")
		elseif xCPos >= 32 and xCPos <= 34 and yCPos == 23 then
			mon.setCursorPos(32,23)
			mon.setBackgroundColor(colors.gray)
			mon.write(" 0 ")
			putLimit = putLimit.."0"
			sleep(0.2)
			mon.setCursorPos(32,23)
			mon.setBackgroundColor(colors.lightGray)
			mon.write(" 0 ")
			mon.setBackgroundColor(1,1)
			mon.setBackgroundColor(colors.black)
			mon.write(" ")
		elseif xCPos >= 36 and xCPos <= 38 and yCPos == 23 then
			mon.setCursorPos(36,23)
			mon.setBackgroundColor(colors.gray)
			mon.write(" X ")
			putLimit = ""
			sleep(0.2)
			mon.setCursorPos(36,23)
			mon.setBackgroundColor(colors.red)
			mon.write(" X ")
			mon.setBackgroundColor(1,1)
			mon.setBackgroundColor(colors.black)
			mon.write(" ")
		elseif xCPos >= 42 and xCPos <= 47 and yCPos == 23 then
			putLimit = ""
			drawClear(27,48,17,24)
			currentControls = "main"
		elseif xCPos >= 42 and xCPos <= 47 and yCPos == 21 then
			if currentControls == "editInput" then
				if putLimit == "" then
					putLimitNum = 0
				else
					putLimitNum = tonumber(putLimit)
				end
				input.setSignalLowFlow(putLimitNum)
				addLog("logs.cfg",getTime(false),"InputMax > "..convertRF(putLimitNum))
			else
				if putLimit == "" then
					putLimitNum = 0
				else
					putLimitNum = tonumber(putLimit)
				end
				output.setSignalLowFlow(putLimitNum)
				addLog("logs.cfg",getTime(false),"OutputMax > "..convertRF(putLimitNum))
			end
			putLimit = ""
			drawClear(27,48,17,24)
			currentControls = "main"
		end
	elseif currentControls == "editConfig" then
		if xCPos >= 28 and xCPos <= 28+8 and yCPos >= 18 and yCPos <= 19 and limitTransfer == true then
			drawButton(26+2,26+10,16+3,16+4,"Detect","Flux_Gate",colors.gray)
			detectInOutput()
			addLog("logs.cfg",getTime(false),"Detected Flux_Gates")
		elseif xCPos >= 26+16 and xCPos <= 26+16+6 and yCPos >= 16+7 and yCPos <= 16+7 then
			currentControls = "main"
		elseif xCPos >= 40 and xCPos <= 47 and yCPos >= 19 and yCPos <= 20 then
			currentControls = "editTimezone"
		end
	elseif currentControls == "editTimezone" then
		if xCPos >= 26+9 and xCPos <= 26+15 and yCPos >= 16+7 and yCPos <= 16+7 then
			currentControls = "main"
		elseif xCPos >= 26+16 and xCPos <= 26+16+6 and yCPos >= 16+7 and yCPos <= 16+7 then
			if timediff >= -12 and timediff <= 12 then
				editConfigFile("config.cfg",1,"Timezone: "..timediff)
			elseif timediff < -12 then
				editConfigFile("config.cfg",1,"Timezone: -12")
			elseif timediff > 12 then
				editConfigFile("config.cfg",1,"Timezone: 12")
			end
			addLog("logs.cfg",getTime(false),"Edited Timezone")
			currentControls = "main"
		elseif xCPos >= 26+2+3 and xCPos <= 26+2+4+2 and yCPos >= 16+4 and yCPos <= 16+4 then
			timediff = timediff-1
		elseif xCPos >= 26+2+4+8 and xCPos <= 26+2+4+6+5 and yCPos >= 16+4 and yCPos <= 16+4 then
			timediff = timediff+1
		end
	end
end

while true do
	parallel.waitForAny(drawAll,clickListener)
end