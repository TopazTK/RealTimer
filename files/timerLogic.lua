LUAGUI_NAME = "In-Game Time"
LUAGUI_AUTH = "TopazTK"
LUAGUI_DESC = "Adds a timer, independent of the game timer."

RACETIME_URL = "PASTE_URL_HERE"
USERNAME = "PUT_USERNAME_HERE_CASE_SENSITIVE"

-- Format is ABGR
WIN_COLOR = 0x80108010
LOSE_COLOR = 0x80101080

local https = require("ssl.https")
local json = require("json") require("json-edit") require("json-beautify")

_startTime = 0

_startSteps = 0

_someoneFinished = false
_started = false

_startDate = 0

_allTable = {}

_usersTable = {}
_statusTable = {}
_placeTable = {}

milisecondClock = 0

function getDigit(num, digit)
	local n = 10 ^ digit
	local n1 = 10 ^ (digit - 1)
	return math.floor((num % n) / n1)
end

function parseDate(Input)
    local pattern = "(%d+)%-(%d+)%-(%d+)%a(%d+)%:(%d+)%:([%d%.]+)([Z%+%-])(%d?%d?)%:?(%d?%d?)"
    local year, month, day, hour, minute, 
        seconds, offsetsign, offsethour, offsetmin = Input:match(pattern)
    local timestamp = os.time{year = year, month = month, 
        day = day, hour = hour, min = minute, sec = math.floor(seconds)}
    local offset = 0
    if offsetsign ~= 'Z' then
      offset = tonumber(offsethour) * 60 + tonumber(offsetmin)
      if xoffset == "-" then offset = offset * -1 end
    end
    
    return timestamp + offset
end

function _OnInit()
    
end

function FetchRaceTime()
    local res, code = https.request(RACETIME_URL .. "/data");
    local _mainTable = json.decode(res)

    for k, v in pairs(_mainTable) do
        if k == "entrants" then
            _allTable = v
        end

        if k == "started_at" then
            _dateParse = v

            if _dateParse ~= nil and _dateParse ~= "null" then
                _startDate = parseDate(_dateParse)
            end
        end
    end 

    for k, v in pairs(_allTable) do
        _usersTable[k] = v["user"]
        _statusTable[k] = v["status"]
        _placeTable[k] = v["place"]
    end

    local _name = ""
    local _status = ""
    local _place = 0

    for i = 1, #_usersTable do
        for k, v in pairs(_usersTable[i]) do
            if k == "name" then
                _name = v
            end
        end

        for k, v in pairs(_statusTable[i]) do
            if k == "verbose_value" then
                _status = v
            end
        end

        _place = _placeTable[i]

        if _status == "Finished" then
            _someoneFinished = true
        end

        if _status == "Finished" and _place == 1 and _name == USERNAME then
            for i = 0, 10 do
                WriteInt(0x49F272 + 0x2C * i, WIN_COLOR)
                WriteInt(0x49F272 + 0x2C * i + 0x04, WIN_COLOR)
                WriteInt(0x49F272 + 0x2C * i + 0x08, WIN_COLOR)
                WriteInt(0x49F272 + 0x2C * i + 0x0C, WIN_COLOR)
            end
        elseif _status == "Finished" and _place == 1 and _name ~= USERNAME then
            for i = 0, 10 do
                WriteInt(0x49F272 + 0x2C * i, LOSE_COLOR)
                WriteInt(0x49F272 + 0x2C * i + 0x04, LOSE_COLOR)
                WriteInt(0x49F272 + 0x2C * i + 0x08, LOSE_COLOR)
                WriteInt(0x49F272 + 0x2C * i + 0x0C, LOSE_COLOR)
            end
        end
    end
end

function _OnFrame()
    if _started == false then
        _readWindow = ReadLong(0xBEBE10 - 0x56454E)
        _readButtons = ReadByte(0xBEBE08 - 0x56454E)
        _readTitle = ReadByte(0x711438 - 0x56454E)
        _readMap = ReadByte(0x0453B82)

        if _readTitle == 0x00 and _readMap == 0x01 then
            _started = true
            _startTime = os.time()
        else
            if _startSteps == 0x00 and _readButtons == 0x04 then
                _startSteps = 0x01
            elseif _startSteps == 0x01 then
                if _readWindow == 0x00 then
                    _startSteps = 0x00
                elseif _readButtons == 0x02 then
                    _startSteps = 0x02
                end
            elseif _startSteps == 0x02 then
                if _readButtons == 0x04 then
                    _startSteps = 0x01
                elseif _readWindow == 0x00 then
                    _startSteps = 0x00
                    _started = true
                    _startTime = os.time()
                end
            end
        end 
    else

        if _someoneFinished == false then
            for i = 0, 10 do
                WriteInt(0x49F272 + 0x2C * i, 0x80808080)
                WriteInt(0x49F272 + 0x2C * i + 0x04, 0x80808080)
                WriteInt(0x49F272 + 0x2C * i + 0x08, 0x80808080)
                WriteInt(0x49F272 + 0x2C * i + 0x0C, 0x80808080)
            end
        end

        _localTime = os.time(os.date("!*t")) - _startDate

        _localSeconds = _localTime % 60
        _localMinutes = (_localTime / 60) % 60
        _localHours = _localTime / 3600

        WriteByte(0x49FA16, 175 + getDigit(_localHours, 2))
        WriteByte(0x49FA16 + 0x14, 175 + getDigit(_localHours, 1))

        WriteByte(0x49FA16 + 0x14 * 2, 175 + getDigit(_localMinutes, 2))
        WriteByte(0x49FA16 + 0x14 * 3, 175 + getDigit(_localMinutes, 1))

        WriteByte(0x49FA16 + 0x14 * 4, 175 + getDigit(_localSeconds, 2))
        WriteByte(0x49FA16 + 0x14 * 5, 175 + getDigit(_localSeconds, 1))

        milisecondClock = milisecondClock + 1

        if milisecondClock >= 60 then
            FetchRaceTime()
            milisecondClock = 0
        end
    end
end
