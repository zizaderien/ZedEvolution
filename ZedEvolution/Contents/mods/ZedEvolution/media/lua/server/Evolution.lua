require "EvolutionVersion"

local modID = 'ZedEvolution'
local handlers
local version = 2

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

-- Rounds a number to the nearest integer
local function round (number)
  return math.floor(number + 0.5)
end

-- Clamp a value between two limits.
local function clamp (min, value, max)
  return math.max(min, math.min(value, max))
end

-- Create a SettingsHandler table.
local function createSettingHandler (name, default, max, set)
  return {
    max = max,
    div = 30 / max,
    default = default,
    name = name,
    set = set,
  }
end

-- Create all settings handlers for supported evolution settings.
local function createHandlers ()
  handlers = {
    -- Evolve speed over time only if speed is not randomized.
    createSettingHandler('Speed', SandboxVars.ZombieLore.Speed, 3,
      function (f, d, l, div)
        if d ~= 4 then SandboxVars.ZombieLore.Speed = round(clamp(l.min, d - f / div, l.max)) end 
      end),

    -- Evolve strength over time only if strength is not randomized.
    createSettingHandler('Strength', SandboxVars.ZombieLore.Strength, 3,
      function (f, d, l, div) 
        if d ~= 4 then SandboxVars.ZombieLore.Strength = round(clamp(l.min, d - f / div, l.max)) end 
      end),

    -- Evolve toughness over time only if toughness is not randomized.
    createSettingHandler('Toughness', SandboxVars.ZombieLore.Toughness, 3,
      function (f, d, l, div) 
        if d ~= 4 then SandboxVars.ZombieLore.Toughness = round(clamp(l.min, d - f / div, l.max)) end 
      end),

    -- Evolve intelligence over time only if intelligence is not randomized.
    createSettingHandler('Cognition', SandboxVars.ZombieLore.Cognition, 3,
      function (f, d, l, div) 
        if d ~= 4 then SandboxVars.ZombieLore.Cognition = round(clamp(l.min, d - f / div, l.max)) end
      end),

    -- Evolve ability to crawl under cars over time.
    createSettingHandler('Crawl', SandboxVars.ZombieLore.CrawlUnderVehicle, 7,
      function (f, d, l, div) SandboxVars.ZombieLore.CrawlUnderVehicle = round(clamp(l.min, d + f / div, l.max)) end),

    -- Evolve memory over time.
    createSettingHandler('Memory', SandboxVars.ZombieLore.Memory, 4,
      function (f, d, l, div) SandboxVars.ZombieLore.Memory = round(clamp(l.min, d - f / div, l.max)) end),

    -- Evolve vision over time.
    createSettingHandler('Sight', SandboxVars.ZombieLore.Sight, 3,
      function (f, d, l, div) SandboxVars.ZombieLore.Sight = round(clamp(l.min, d - f / div, l.max)) end),

    -- Evolve hearing over time.
    createSettingHandler('Hearing', SandboxVars.ZombieLore.Hearing, 3,
      function (f, d, l, div) SandboxVars.ZombieLore.Hearing = round(clamp(l.min, d - f / div, l.max)) end),

    -- Evolve transmission of zombie attacks over time only if not everyone is infected.
    createSettingHandler('Transmission', SandboxVars.ZombieLore.Transmission, 3,
      function (f, d, l, div) 
        if d ~= 3 then
          d = (d == 4) and 3 or d
          local temp = round(clamp(l.min, d - f / div, l.max))
          temp = (temp == 3) and 4 or temp
          SandboxVars.ZombieLore.Transmission = temp
        end 
      end),
  }
end

-- Get the evolution constraints for the handler
local function getLimits(handler)
  local values = { handler.default, SandboxVars.ZedEvolution[handler.name .. 'Limit'] }
  return { min = math.min(unpack(values)), max = math.max(unpack(values)) }
end

-- Update the settings to match the evolution level using the setting handlers.
local function runHandlers ()
  local evolution = getEvolution()
  for _, handler in ipairs(handlers) do
    handler.set(evolution * SandboxVars.ZedEvolution[handler.name], handler.default, getLimits(handler), handler.div)
  end
  getSandboxOptions():updateFromLua()
end

-- Ensure the mod's data for this save is up to date.
local function updateToCurrentVersion (modData)
  local saveVersion = modData.version or 1
  while saveVersion < version do saveVersion = ZedEvolution.updateVersion['v' .. saveVersion]() end
  modData.version = saveVersion
end

-- Enable the mod in this world only if evolution is enabled.
Events.OnGameTimeLoaded.Add(function ()
  -- Remove leftover handlers.
  Events.EveryHours.Remove(runHandlers)
  if SandboxVars.ZedEvolution.DoEvolve then
    -- Init mod data and setting handlers.
    local modData = getGameTime():getModData()
    createHandlers()
    if modData[modID] ~= nil then
      updateToCurrentVersion(modData[modID])
      for _, handler in ipairs(handlers) do handler.default = modData[modID][handler.name] end
    else
      modData[modID] = { version = version }
      for _, handler in ipairs(handlers) do modData[modID][handler.name] = handler.default end
      runHandlers()
    end
    -- Update evolution level every hour.
    Events.EveryHours.Add(runHandlers)
  end
end)