require "EvolutionVersion"
ZedEvolution = ZedEvolution or {}



-----------------------------------------------
--           Variable Declarations           --
-----------------------------------------------

--- ID for the ZedEvolution mod
local modID = 'ZedEvolution'

--- Handlers for updating attribute values
---@see createHandlers
local handlers

--- Sandbox data version
local version = 4

--- Distribution functions
---@see createWeightFunctions
---@see getPopWeight
local weightFunctions = {}

--- Current evolution factor
--- @see updateEvolution
local evolution = 0

--- Values associated with the ZedEvolution.Function enum
local evolutionFunctions



-----------------------------------------------
--            Evolution Functions            --
-----------------------------------------------

--- Make evolution increase linearly forever.
---@param f number 'base evolution'
---@param m number 'slope is 1/m'
---@return number 'net evolution'
local function evolutionLinearFunction (f, m)
  return f / m 
end

--- Make evolution approach a limit.
---@param f number - 'base evolution'
---@param h number - 'evolution gets 50% closer to the limit every multiple of h'
---@param b number - 'y value of the function midpoint'
---@param l number - 'lim(f -> ∞) = b+l; lim(f -> -∞) = b-l'
---@return number 'net evolution'
local function evolutionSigmoidFunction (f, h, b, l) 
  return (1 - math.pow(2, -math.abs(f / h))) * PZMath.sign(f) * l + b
end

--- Make evolution fluctuate in cycles.
--- Relative ordinality of m and l does not matter.
---@param f number 'base evolution'
---@param c number 'evolution repeats for every multiple of c'
---@param m number 'output values are in the interval [m, l]'
---@param l number 'output values are in the interval [m, l]'
---@return number 'net evolution'
local function evolutionCyclicFunction (f, c, m, l) 
  return (-math.cos(f * math.pi * 2 / c) + 1) / 2 * (l - m) + m
end

evolutionFunctions = {
  evolutionLinearFunction,
  evolutionSigmoidFunction,
  evolutionCyclicFunction,
}

--- Applies the selected function to the provided evolution factor.
---@param n number 'base evolution
---@return number 'net evolution'
local function applyEvolutionFunction(n)
  return evolutionFunctions[SandboxVars.ZedEvolution.Function](
    n, SandboxVars.ZedEvolution.Param1, SandboxVars.ZedEvolution.Param2, SandboxVars.ZedEvolution.Param3)
end



-----------------------------------------------
--             Utility Functions             --
-----------------------------------------------

--- Ensure the mod's data for this save is up to date.
---@param modData table 'ModData for this world'
local function updateToCurrentVersion (modData)
  local saveVersion = modData.version or 1
  while saveVersion < version do saveVersion = ZedEvolution.updateVersion['v' .. saveVersion](modData) end
  modData.version = saveVersion
end

--- Clamp a value between two limits.
---@param value number 'value to be clamped'
---@param min number 'lowest allowed value'
---@param max number 'highest allowed value'
---@return number 'clamped value'
local function clamp (value, min, max)
  return math.max(min, math.min(value, max))
end

--- Get the os.time for given time data.
---@param year integer 'current year'
---@param month integer 'current month'
---@param day integer 'current day'
---@param hour number 'current hour'
---@return integer 'os.time'
local function getTime (year, month, day, hour)
  return os.time{ year = year, month = month, day = day, hour = math.floor(hour)}
end

--- Get the os.difftime for both the current and start time.
---@param gameTime zombie.GameTime 'PZ GameTime object'
---@return integer 'seconds elapsed in world'
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



-----------------------------------------------
--          Distribution  Functions          --
-----------------------------------------------

--- Map an attribute weight to match the desired distribution.
--- This function is curried and arguments should be normalized.
---@param w number 'fraction of evolution that should affect 50% of zombies'
---@param n number 'distributed value'
---@return number 'redistributed value'
---@usage local distRand = getPopWeight(0.25)(ZombRandFloat(0, 1))
---@see weightFunctions
---@see createWeightFunctions
local function getPopWeight (w)
  local y = -(Math.log(w) / Math.log(2))
  if w == 0 then
    return function (n) return 0 end
  else
    return function (n) return Math.pow(n, y) end
  end
end

--- Create partially applied functions for distributing attribute weights across zombies.
---@see weightFunctions
---@see getPopWeight
local function createWeightFunctions ()
  for _, handler in ipairs(handlers) do
    weightFunctions[handler.name] = getPopWeight(SandboxVars.ZedEvolution[handler.name .. 'Weight'] / 100)
  end
end



-----------------------------------------------
--            Attribute Functions            --
-----------------------------------------------

--- Get the evolution constraints for an attribute.
---@param name string 'Internal attribute name'
---@return table 'Min and max values for the attribute'
local function getLimits(name)
  local values = {
    SandboxVars.ZedEvolution[name .. 'Min'],
    SandboxVars.ZedEvolution[name .. 'Limit'],
  }
  return { min = math.min(unpack(values)), max = math.max(unpack(values)) }
end

--- Create a handler for an evolvable attribute.
---@param name string 'Name of internal variables associated with this handler'
---@param default number 'The default value for this attribute'
---@param max number 'The maximum number vanilla allows'
---@param set fun(f:number, d:number, l:table, div:number):nil 'function that sets the attribute'
local function createSettingHandler (name, default, max, set)
  local limits = getLimits(name)
  return {
    limits = limits,
    div = 1 / (max - 1),
    default = default,
    name = name,
    set = set,
  }
end

--- Create all settings handlers for supported evolution settings.
---@see handlers
---@see createSettingHandler
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



-----------------------------------------------
--                Event Hooks                --
-----------------------------------------------

--- Calculate the evolution factor
--- @see evolution
local function updateEvolution ()
  local gameTime = getGameTime()
  evolution = applyEvolutionFunction(
    math.max(0, getTimeElapsed(gameTime) / 86400 - SandboxVars.ZedEvolution.Delay) + SandboxVars.ZedEvolution.StartSlow)
  print(modID, 'Evolution factor is now:', evolution)
end

--- Update a zombie's attributes.
---@param zombie zombie.characters.IsoZombie 'Zombie to change the attributes of'
local function changeZombieStats (zombie)
  local modData = zombie:getModData()

  -- Init moddata if it doesn't exist
  if modData[modID] == nil then
    modData[modID] = { interval = 0 }
    for name, func in pairs(weightFunctions) do modData[modID][name] = func(ZombRandFloat(0, 1)) end
  end

  -- Ensure the zombie's stats are correct every so often.
  -- Running it more than necessary creates a lot of lag since the event this function is attached to fires very often.
  if modData[modID].interval > 0 then
    modData[modID].interval = modData[modID].interval - 1
  else
    modData[modID].interval = ZombRand(400, 600)
    for _, handler in ipairs(handlers) do 
      handler.set(
        evolution * SandboxVars.ZedEvolution[handler.name] * modData[modID][handler.name],
        handler.default,
        handler.limits,
        handler.div)
    end
    zombie:makeInactive(true)
    zombie:makeInactive(false)
    zombie:DoZombieStats()
  end
end

--- Enable the mod in this world only if evolution is enabled.
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
      for _, handler in ipairs(handlers) do 
        handler.default = modData[modID][handler.name]
      end
    else
      modData[modID] = { version = version }
      for _, handler in ipairs(handlers) do 
        modData[modID][handler.name] = handler.default 
      end
    end
    createWeightFunctions()
    updateEvolution()

    -- Update evolution level & zombie stats
    Events.EveryHours.Add(updateEvolution)
    Events.OnZombieUpdate.Add(changeZombieStats)
  end
end)