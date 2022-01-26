require "EvolutionVersion"

local modID = 'ZedEvolution'
local handlers
local version = 3
local weightFunctions = {}
local updateInterval = 500
local evolution = 0

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
local function updateEvolution ()
  local gameTime = getGameTime()
  evolution = 
    (math.max(0, getTimeElapsed(gameTime) / 86400 - SandboxVars.ZedEvolution.Delay)
      + SandboxVars.ZedEvolution.StartSlow)
      * SandboxVars.ZedEvolution.Factor
  print(modID, 'Evolution factor is now:', evolution)
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

-- Set a weight for attributes affecting the zombie population.
local function getPopWeight (weight)
  local y = -(Math.log(weight) / Math.log(2))
  if weight == 0 then
    return function (n) return 0 end
  else
    return function (n) return Math.pow(n, y) end
  end
end

-- Create the functions for population attribute weights.
local function createWeightFunctions (modData)
  for _, handler in ipairs(handlers) do
    weightFunctions[handler.name] = getPopWeight(
      SandboxVars.ZedEvolution.Weight / 100 * SandboxVars.ZedEvolution[handler.name .. 'Weight']
    )
  end
end

local function clamp (value, min, max)
  return math.max(min, math.min(value, max))
end

-- Create all settings handlers for supported evolution settings.
local function createHandlers ()
  handlers = {
    -- Evolve speed over time only if speed is not randomized.
    createSettingHandler('Speed', SandboxVars.ZombieLore.Speed, 3,
      function (f, d, l, div)
        if d ~= 4 then
          getSandboxOptions():set('ZombieLore.Speed', PZMath.roundToNearest(clamp(d - f / div, l.min, l.max)))
        end 
      end),

    -- Evolve strength over time only if strength is not randomized.
    createSettingHandler('Strength', SandboxVars.ZombieLore.Strength, 3,
      function (f, d, l, div) 
        if d ~= 4 then
          getSandboxOptions():set('ZombieLore.Strength', PZMath.roundToNearest(clamp(d - f / div, l.min, l.max)))
        end 
      end),

    -- Evolve toughness over time only if toughness is not randomized.
    createSettingHandler('Toughness', SandboxVars.ZombieLore.Toughness, 3,
      function (f, d, l, div) 
        if d ~= 4 then 
          getSandboxOptions():set('ZombieLore.Toughness', PZMath.roundToNearest(clamp(d - f / div, l.min, l.max)))
        end 
      end),

    -- Evolve intelligence over time only if intelligence is not randomized.
    createSettingHandler('Cognition', SandboxVars.ZombieLore.Cognition, 3,
      function (f, d, l, div) 
        if d ~= 4 then 
          getSandboxOptions():set('ZombieLore.Cognition', PZMath.roundToNearest(clamp(d - f / div, l.min, l.max)))
        end
      end),

    -- Evolve ability to crawl under cars over time.
    createSettingHandler('CrawlUnderVehicle', SandboxVars.ZombieLore.CrawlUnderVehicle, 7,
      function (f, d, l, div) 
        getSandboxOptions():set('ZombieLore.CrawlUnderVehicle', PZMath.roundToNearest(clamp(d - f / div, l.min, l.max)))
      end),

    -- Evolve memory over time.
    createSettingHandler('Memory', SandboxVars.ZombieLore.Memory, 4,
      function (f, d, l, div) 
        getSandboxOptions():set('ZombieLore.Memory', PZMath.roundToNearest(clamp(d - f / div, l.min, l.max)) )
      end),

    -- Evolve vision over time.
    createSettingHandler('Sight', SandboxVars.ZombieLore.Sight, 3,
      function (f, d, l, div) 
        getSandboxOptions():set('ZombieLore.Sight', PZMath.roundToNearest(clamp(d - f / div, l.min, l.max)))
      end),

    -- Evolve hearing over time.
    createSettingHandler('Hearing', SandboxVars.ZombieLore.Hearing, 3,
      function (f, d, l, div)
        getSandboxOptions():set('ZombieLore.Hearing', PZMath.roundToNearest(clamp(d - f / div, l.min, l.max)))
      end),

    -- Evolve transmission of zombie attacks over time only if not everyone is infected.
    createSettingHandler('Transmission', SandboxVars.ZombieLore.Transmission, 3,
      function (f, d, l, div) 
        if d ~= 3 then
          d = (d == 4) and 3 or d
          local temp = PZMath.roundToNearest(PZMath.clamp(d - f / div, l.min, l.max))
          temp = (temp == 3) and 4 or temp
          getSandboxOptions():set('ZombieLore.Transmission', temp)
        end 
      end),
  }
end

-- Get the evolution constraints for the handler
local function getLimits(handler)
  local values = { handler.default, SandboxVars.ZedEvolution[handler.name .. 'Limit'] }
  return { min = math.min(unpack(values)), max = math.max(unpack(values)) }
end

-- Ensure the mod's data for this save is up to date.
local function updateToCurrentVersion (modData)
  local saveVersion = modData.version or 1
  while saveVersion < version do saveVersion = ZedEvolution.updateVersion['v' .. saveVersion](modData) end
  modData.version = saveVersion
end

-- Change the stats for the given zombie
local function changeZombieStats (zombie)
  local modData = zombie:getModData()

  -- Init moddata if it doesn't exist
  if modData[modID] == nil then
    modData[modID] = { interval = 0 }
    for name, func in pairs(weightFunctions) do modData[modID][name] = func(ZombRandFloat(0, 1)) end
  end

  -- Ensure the zombie's stats are correct every so often.
  if modData[modID].interval > 0 then
    modData[modID].interval = modData[modID].interval - 1
  else
    modData[modID].interval = ZombRand(400, 600)
    for _, handler in ipairs(handlers) do 
      handler.set(evolution * modData[modID][handler.name], handler.default, getLimits(handler), handler.div)
    end
    zombie:makeInactive(true)
    zombie:makeInactive(false)
    zombie:DoZombieStats()
  end
end

-- Enable the mod in this world only if evolution is enabled.
Events.OnGameTimeLoaded.Add(function ()
  -- Remove leftover handlers.
  Events.EveryHours.Remove(updateEvolution)
  Events.OnZombieUpdate.Remove(changeZombieStats)

  if SandboxVars.ZedEvolution.DoEvolve then
    -- Init mod data and handlers.
    local modData = getGameTime():getModData()
    createHandlers()
    if modData[modID] ~= nil then
      updateToCurrentVersion(modData[modID])
      for _, handler in ipairs(handlers) do handler.default = modData[modID][handler.name] end
    else
      modData[modID] = { version = version }
      for _, handler in ipairs(handlers) do modData[modID][handler.name] = handler.default end
    end
    createWeightFunctions(modData[modID])
    updateEvolution()

    -- Update evolution level & zombie stats
    Events.EveryHours.Add(updateEvolution)
    Events.OnZombieUpdate.Add(changeZombieStats)
  end
end)