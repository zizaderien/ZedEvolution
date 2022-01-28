ZedEvolution = ZedEvolution or {}

-- Invert the cap if it's default and doesn't make sense with the provided factor.
local function maybeInvert(name, default, new) 
  if SandboxVars.ZedEvolution[name .. 'Limit'] == default 
    and SandboxVars.ZedEvolution.Factor * SandboxVars.ZedEvolution[name] < 0 then 
    SandboxVars.ZedEvolution[name .. 'Limit'] = new
  end
end

-- Calculate caps based on evolution factor being positive / negative.
-- Evolution caps were introduced in v2, so we need to account for them to keep devolution compatible from v1.
local function updateFromV1 ()
  local vars = SandboxVars.ZedEvolution
  maybeInvert('Speed', 1, 3)
  maybeInvert('Strength', 1, 3)
  maybeInvert('Toughness', 1, 3)
  maybeInvert('Transmission', 1, 3)
  maybeInvert('Cognition', 1, 3)
  maybeInvert('Crawl', 7, 1)
  maybeInvert('Memory', 1, 4)
  maybeInvert('Sight', 1, 3)
  maybeInvert('Hearing', 1, 3)
  getSandboxOptions():updateFromLua()
  return 2
end

-- Rename all variables with Crawl to CrawlUnderVehicle to match vanilla.
local function updateFromV2 (modData)
  SandboxVars.ZedEvolution.Weight = 100
  modData.CrawlUnderVehicle = modData.Crawl or modData.CrawlUnderVehicle
  SandboxVars.ZedEvolution.CrawlUnderVehicleLimit =
    SandboxVars.ZedEvolution.CrawlLimit or SandboxVars.ZedEvolution.CrawlUnderVehicleLimit
  SandboxVars.ZedEvolution.CrawlUnderVehicle =
    SandboxVars.ZedEvolution.Crawl or SandboxVars.ZedEvolution.CrawlUnderVehicle
  getSandboxOptions():updateFromLua()
  return 3
end

-- Multiplies the weight to make it a percentage
local function updateWeightV3 (name)
  SandboxVars.ZedEvolution[name .. 'Weight'] = 
    SandboxVars.ZedEvolution[name .. 'Weight'] * SandboxVars.ZedEvolution.Weight
end

-- Sets the min and max value for evolution appropriately.
local function updateLimitV3 (name, modData, limit, m)
  local default = modData[name]
  local cap = SandboxVars.ZedEvolution[name .. 'Limit']
  if cap < default then
    SandboxVars.ZedEvolution[name .. 'Min'] = limit
  elseif cap > default then
    SandboxVars.ZedEvolution[name .. 'Min'] = 1
  elseif m * SandboxVars.ZedEvolution.Param1 * SandboxVars.ZedEvolution[name] > 0 then
    SandboxVars.ZedEvolution[name .. 'Min'] = 1
  elseif m * SandboxVars.ZedEvolution.Param1 * SandboxVars.ZedEvolution[name] < 0 then
    SandboxVars.ZedEvolution[name .. 'Min'] = limit
  end
end

-- Phase out the evolution factor setting and roll it into the linear function instead.
local function updateFromV3 (modData)
  SandboxVars.ZedEvolution.Param1 = SandboxVars.ZedEvolution.Param1 / (SandboxVars.ZedEvolution.Factor or 1)
  updateWeightV3('Speed')
  updateWeightV3('Strength')
  updateWeightV3('Toughness')
  updateWeightV3('Transmission')
  updateWeightV3('Cognition')
  updateWeightV3('CrawlUnderVehicle')
  updateWeightV3('Memory')
  updateWeightV3('Sight')
  updateWeightV3('Hearing')
  updateLimitV3('Speed', modData, 3, -1)
  updateLimitV3('Strength', modData, 3, -1)
  updateLimitV3('Toughness', modData, 3, -1)
  updateLimitV3('Transmission', modData, 3, -1)
  updateLimitV3('Cognition', modData, 3, -1)
  updateLimitV3('CrawlUnderVehicle', modData, 7, 1)
  updateLimitV3('Memory', modData, 4, -1)
  updateLimitV3('Sight', modData, 3, -1)
  updateLimitV3('Hearing', modData, 3, -1)
  getSandboxOptions():updateFromLua()
  return 4
end

-- Update the way the moddata / sandboxvars are stored to fit the current version of the mod.
ZedEvolution.updateVersion = {
  v1 = updateFromV1,
  v2 = updateFromV2,
  v3 = updateFromV3,
}