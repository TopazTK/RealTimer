LUAGUI_NAME = "In-Game Time"
LUAGUI_AUTH = "TopazTK"
LUAGUI_DESC = "Adds a timer, independent of the game timer."

_startTime = 0

_startSteps = 0

_finished = false
_started = false

function getDigit(num, digit)
	local n = 10 ^ digit
	local n1 = 10 ^ (digit - 1)
	return math.floor((num % n) / n1)
end

function _OnInit()
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
        _readXemmy = ReadByte(0x2A0D3E0 - 0x56454E)

        if _readXemmy ~= 0x04 and _finished == false then
            _localTime = os.difftime(os.time(), _startTime)

            _localSeconds = _localTime % 60
            _localMinutes = (_localTime / 60) % 60
            _localHours = _localTime / 3600

            WriteByte(0x49FA16, 175 + getDigit(_localHours, 2))
            WriteByte(0x49FA16 + 0x14, 175 + getDigit(_localHours, 1))

            WriteByte(0x49FA16 + 0x14 * 2, 175 + getDigit(_localMinutes, 2))
            WriteByte(0x49FA16 + 0x14 * 3, 175 + getDigit(_localMinutes, 1))

            WriteByte(0x49FA16 + 0x14 * 4, 175 + getDigit(_localSeconds, 2))
            WriteByte(0x49FA16 + 0x14 * 5, 175 + getDigit(_localSeconds, 1))
        else if _readXemmy == 0x04 then 
            _finished = true
        end
    end
end
