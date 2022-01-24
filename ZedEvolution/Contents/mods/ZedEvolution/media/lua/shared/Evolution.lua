local modID = 'ZedEvolution'
local handlers

-- Get the os.time for given time data.
local function getTime (year, month, day, hour)
  return os.time{ year = year, month = month, day = day, hour = math.floor(hour)}
end

-- Get the os.difftime for both the current and start time.
local function getTimeElapsed (gameTime)
  local nowTime = getTime(
    gameTime:getYear(),
    gameTime:getMonth(),
    gameTime:getDay(),
    gameTime:getTimeOfDay())
  local startTime = getTime(
    gameTime:getStartYear(),
    gameTime:getStartMonth(),
    gameTime:getStartDay(),
    gameTime:getStartTimeOfDay())
  return os.difftime(nowTime, startTime)
end

-- Calculate the evolution factor.
local function getEvolution ()
  local gameTime = getGameTime()
  local evolution = 
    (math.max(0, getTimeElapsed(gameTime) / 86400 - SandboxVars.ZedEvolution.Delay)
      + SandboxVars.ZedEvolution.StartSlow)
      * SandboxVars.ZedEvolution.Factor
  print(modID, 'Evolution factor is now:', evolution)
  return evolution
end

-- Clamp a value between two limits.
local function clamp(min, value, max)
  return math.max(min, math.min(value, max))
end

-- Create a SettingsHandler table.
local function createSettingHandler (name, default, set)
  return {
    default = default,
    name = name,
    set = set,
  }
end

-- Create all settings handlers for supported evolution settings.
local function createHandlers ()
  handlers = {
    -- Evolve speed over time only if speed is not randomized.
    createSettingHandler('Speed', SandboxVars.ZombieLore.Speed,
      function (f, d)
        if d ~= 4 then SandboxVars.ZombieLore.Speed = math.floor(clamp(1, d - f / 10, 3)) end 
      end),

    -- Evolve strength over time only if strength is not randomized.
    createSettingHandler('Strength', SandboxVars.ZombieLore.Strength,
      function (f, d) 
        if d ~= 4 then SandboxVars.ZombieLore.Strength = math.floor(clamp(1, d - f / 10, 3)) end 
      end),

    -- Evolve toughness over time only if toughness is not randomized.
    createSettingHandler('Toughness', SandboxVars.ZombieLore.Toughness,
      function (f, d) 
        if d ~= 4 then SandboxVars.ZombieLore.Toughness = math.floor(clamp(1, d - f / 10, 3)) end 
      end),

    -- Evolve intelligence over time only if intelligence is not randomized.
    createSettingHandler('Cognition', SandboxVars.ZombieLore.Cognition,
      function (f, d) 
        if d ~= 4 then SandboxVars.ZombieLore.Cognition = math.floor(clamp(1, d - f / 10, 3)) end
      end),

    -- Evolve ability to crawl under cars over time.
    createSettingHandler('Crawl', SandboxVars.ZombieLore.CrawlUnderVehicle,
      function (f, d) SandboxVars.ZombieLore.CrawlUnderVehicle = math.floor(clamp(1, d + f / 4.29, 7)) end),

    -- Evolve memory over time.
    createSettingHandler('Memory', SandboxVars.ZombieLore.Memory,
      function (f, d) SandboxVars.ZombieLore.Memory = math.floor(clamp(1, d - f / 7.5, 4)) end),

    -- Evolve vision over time.
    createSettingHandler('Sight', SandboxVars.ZombieLore.Sight,
      function (f, d) SandboxVars.ZombieLore.Sight = math.floor(clamp(1, d - f / 7.5, 4)) end),

    -- Evolve hearing over time.
    createSettingHandler('Hearing', SandboxVars.ZombieLore.Hearing,
      function (f, d) SandboxVars.ZombieLore.Hearing = math.floor(clamp(1, d - f / 7.5, 4)) end),

    -- Evolve transmission of zombie attacks over time only if not everyone is infected.
    createSettingHandler('Transmission', SandboxVars.ZombieLore.Transmission,
      function (f, d) 
        if d ~= 3 then
          d = (d == 4) and 3 or d
          local temp = math.floor(clamp(1, d - f / 30, 3))
          temp = (temp == 3) and 4 or temp
          SandboxVars.ZombieLore.Transmission = temp
        end 
      end),
  }
end

-- Update the settings to match the evolution level using the setting handlers.
local function runHandlers ()
  local evolution = getEvolution()
  for _, handler in ipairs(handlers) do
    handler.set(evolution * SandboxVars.ZedEvolution[handler.name], handler.default)
  end
  getSandboxOptions():updateFromLua()
end

-- Enable the mod in this world only if evolution is enabled.
Events.OnGameTimeLoaded.Add(function ()
  -- Remove leftover handlers.
  Events.EveryHours.Remove(runHandlers)
  if SandboxVars.ZedEvolution.DoEvolve then
    -- Init mod data and setting handlers.
    local modData = getGameTime():getModData()
    createHandlers()
    print('handlers', handlers)
    if modData[modID] ~= nil then
      for _, handler in ipairs(handlers) do handler.default = modData[modID][handler.name] end
    else
      modData[modID] = {}
      for _, handler in ipairs(handlers) do modData[modID][handler.name] = handler.default end
      runHandlers()
    end
    -- Update evolution level every hour.
    Events.EveryHours.Add(runHandlers)
  end
end)
