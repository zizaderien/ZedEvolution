ZEUtils = {}



--- Gets the hour from a GameTime TimeOfDay number.
---@param timeOfDay number 'time of day'
---@return integer 'hour'
local function getHour (timeOfDay)
  return math.floor(timeOfDay)
end

--- Gets the minute of a GameTime TimeOfDay number.
---@param timeOfDay number 'time of day as given by GameTime'
---@return integer 'minute'
local function getMinute (timeOfDay) 
  return math.floor((timeOfDay - getHour(timeOfDay)) * 60)
end



--- Get the value for a sandbox option.
---@param name string 'name of the sandbox option'
function ZEUtils.getVar (name)
  return getSandboxOptions():getOptionByName(name):getValue()
end

--- Set the value for a sandbox option.
---@param name string 'name of the sandbox option'
---@param value any 'new value'
function ZEUtils.setVar (name, value)
  return getSandboxOptions():set(name, value)
end

--- Get the os.time for given time data.
---@param year integer 'year'
---@param month integer 'month'
---@param day integer 'day'
---@param hour integer 'hour'
---@param hour integer 'minute'
---@return integer 'os.time'
function ZEUtils.getTime (year, month, day, hour, minute)
  return os.time{ year = year, month = month, day = day, hour = hour, min = minute}
end

--- Get the os.difftime for both the current and start time.
---@return integer 'seconds elapsed in world'
function ZEUtils.getTimeElapsed ()
  local gameTime = getGameTime()
  local nowTime = ZEUtils.getTime(
    gameTime:getYear(),
    gameTime:getMonth(),
    gameTime:getDay(),
    getHour(gameTime:getTimeOfDay()),
    getMinute(gameTime:getTimeOfDay()))
  local startTime = ZEUtils.getTime(
    -- Can't use gameTime:getStart[...] for this because on servers it seems to return the wrong time for the client.
    ZEUtils.getVar('StartYear') + getSandboxOptions():getFirstYear() - 1,
    ZEUtils.getVar('StartMonth') -1,
    ZEUtils.getVar('StartDay') -1,
    getHour(gameTime:getStartTimeOfDay()),
    getMinute(gameTime:getStartTimeOfDay()))
  return os.difftime(nowTime, startTime)
end

--- Applies the gamma function using Nemes' approximation
---@param x number
---@return number
function ZEUtils.gamma (x)
  return math.exp(
    0.5 * math.log(2 * math.pi)
    + (x - 0.5) * math.log(x)
    - x
    + (x / 2) * math.log(
      x * math.sinh(1 / x)
      + 1 / (810 * math.pow(x, 6))))
end

--- Recurses over a table with an accumulator variable
---@param tbl table 'table to recurse over'
---@param callback fun(acc:any, val:any, ind:integer, tbl:table) 'function to recurse with'
---@param initial? any 'value the accumulator starts with. Defaults to tbl[1]'
---@return any 'the accumulated value'
function ZEUtils.reduce (tbl, callback, initial)
  local tbl = { unpack(tbl) }
  local acc = initial
  local start = 1
  if acc == nil then
    acc = tbl[1]
    start = 2
  end
  for i = start, #tbl do acc = callback(acc, tbl[i], i, tbl) end
  return acc
end


--- Returns a table as a string by doing a deep scan of its pairs
---@param karg any 'key'
---@param varg any 'value'
---@param level any 'indent'
function ZEUtils.kv(karg, varg, level)
  level = level or 0
  local str = tostring(karg) .. ': '

  if type(varg) == 'table' then
    str = str .. '\n'
    for k, v in pairs(varg) do
      str = str .. ZEUtils.kv(k, v, level + 1) .. '\n'
    end
    --str = str .. '}'
  else
    str = str .. tostring(varg)
  end

  local s = ''
  local l = level
  while l> 0 do
    s = s .. ' '
    l= l- 1
  end
  return s .. str
end