
require "SandboxOptions"

local entryHLarge = getTextManager():getFontFromEnum(UIFont.Large):getLineHeight() + 4
local entryHMedium = getTextManager():getFontFromEnum(UIFont.Medium):getLineHeight() + 6
local modID = 'ZedEvolution'
local OnPresetChange = { function () end }

-- Validator definitions.
local vMeta = {
  -- Forbid correction of "Random" selection.
  ForbidRandom = function (makeValid, mult, loreVal, evoVal)
    if loreVal ~= 4 and mult * (loreVal - evoVal) < 0 then
      ({
        mult = function (e) e.javaObject:SetText(tostring(-mult)) end,
        evo = function (e) e.selected = loreVal end
      })[makeValid.ZedEvolutionType](makeValid)
    end
  end,

  -- Forbid correction of "Everyone's Infected" selection.
  Transmission = function (makeValid, mult, loreVal, evoVal)
    if loreVal ~= 3 and mult * (loreVal - evoVal) < 0 then
      if loreVal == 4 then loreVal = 3 end
      ({
        mult = function (e) e.javaObject:SetText(tostring(-mult)) end,
        evo = function (e) e.selected = loreVal end
      })[makeValid.ZedEvolutionType](makeValid)
    end
  end,

  -- Inverted constraint.
  Inverted = function (makeValid, mult, loreVal, evoVal)
    if mult * (evoVal - loreVal) < 0 then
      ({
        mult = function (e) e.javaObject:SetText(tostring(-mult)) end,
        evo = function (e) e.selected = loreVal end
      })[makeValid.ZedEvolutionType](makeValid)
    end
  end,

  -- Forbid none.
  ForbidNone = function (makeValid, mult, loreVal, evoVal)
    if mult * (loreVal - evoVal) < 0 then
      ({
        mult = function (e) e.javaObject:SetText(tostring(-mult)) end,
        evo = function (e) e.selected = loreVal end
      })[makeValid.ZedEvolutionType](makeValid)
    end
  end,
}

-- Validator associations.
local validators = {
  Speed = vMeta.ForbidRandom,
  Strength = vMeta.ForbidRandom,
  Toughness = vMeta.ForbidRandom,
  Transmission = vMeta.Transmission,
  Cognition = vMeta.ForbidRandom,
  Crawl = vMeta.Inverted,
  Memory = vMeta.ForbidNone,
  Sight = vMeta.ForbidNone,
  Hearing = vMeta.ForbidNone,
}


local function createEvolutionParamDef (default, min, max)
  return { default = default, min = min, max = max, }
end

local evolutionFuncDefs = {
  { -- Linear
    createEvolutionParamDef('30', -math.huge, math.huge),
  },
  { -- Asymptotic
    createEvolutionParamDef('30', 0, math.huge),
    createEvolutionParamDef('0.0', -math.huge, math.huge),
    createEvolutionParamDef('1.0', -math.huge, math.huge),
  },
  { -- Cyclic
    createEvolutionParamDef('60', -math.huge, math.huge),
    createEvolutionParamDef('0.0', -math.huge, math.huge),
    createEvolutionParamDef('1.0', -math.huge, math.huge),
  },
}

local function setElementVisible (element, visible, shiftables)
  element:setVisible(visible)
  local m = visible and 1 or -1
  for _, shiftable in pairs(shiftables) do
    if shiftable:getY() > element:getY() then
      shiftable:setY(shiftable:getY() + m * entryHMedium)
    end
  end
  element:setY(element:getY() + m * entryHMedium / 2)
end


local function showPairs (controls, labels, panel, careVisible)
  local children = panel.javaObject:getControls()
  for i = 1, #controls do
    local control = controls[i]
    local label = labels[i]
    if careVisible and control:isVisible() then
      -- Skip
    else
      control:setVisible(true)
      label:setVisible(true)
      for j = 1, children:size() do
        local child = children:get(j - 1)
        if child:getY() > control:getY() then
          child:setY(child:getY() + entryHMedium)
        end
      end
      control:setY(control:getY() + entryHMedium / 2)
      label:setY(label:getY() + entryHMedium / 2)
    end
  end
end


local function hidePairs (controls, labels, panel, careVisible)
  local children = panel.javaObject:getControls()
  for i = 1, #controls do
    local control = controls[i]
    local label = labels[i]
    if careVisible and not control:isVisible() then
      -- Skip
    else
      control:setVisible(false)
      label:setVisible(false)
      for j = 1, children:size() do   
        local child = children:get(j - 1)
        if child:getY() > control:getY() then
          child:setY(child:getY() - entryHMedium)
        end
      end
      control:setY(control:getY() - entryHMedium / 2)
      label:setY(label:getY() - entryHMedium / 2)
    end
  end
end

local function buildTooltip (descName, paramDef)
  local desc = getText(descName .. '_tooltip')
    :gsub('\\n', '\n')
    :gsub('\\"', '"') 
  -- Leverage Double class for math.huge values, since we want "Infinity" rather than "inf"
  local sub = Translator.getText('Sandbox_MinMaxDefault')
    :gsub('%%1', Double.toString(tonumber(paramDef.min)))
    :gsub('%%2', Double.toString(tonumber(paramDef.max)))
    :gsub('%%3', Double.toString(tonumber(paramDef.default)))
  return desc .. '. \n' .. sub
end

local function updateFunctionSettings (_, comboBox, controls, labels, setDefaults, careVisible)
  if setDefaults == nil then setDefaults = true end
  if careVisible == nil then careVisible = true end
  local funcDef = evolutionFuncDefs[comboBox.selected]
  local panel = comboBox:getParent()
  -- comboBox.tooltip = getText('Sandbox_ZedEvolution_Function_option' .. comboBox.selected .. '_tooltip')

  -- Show all relevant items.
  hidePairs(controls, labels, panel, careVisible)
  for i, param in ipairs(funcDef) do
    local tl = 'Sandbox_ZedEvolution_Function_option' .. comboBox.selected .. '_Param' .. i
    showPairs({controls[i]}, {labels[i]}, panel, careVisible)
    labels[i].name = getText(tl)
    local oldWidth = labels[i]:getWidth()
    labels[i]:setWidthToName()
    local newWidth = labels[i]:getWidth()
    labels[i]:setX(labels[i].x + oldWidth - newWidth)
    if setDefaults then
      controls[i]:setText(param.default)
    end
    controls[i].tooltip = buildTooltip(tl, param)
    labels[i].tooltip = buildTooltip(tl, param)
  end
end



local function addPrerenderHook (panel, comboBox, controls, labels)
  local pfn = panel.prerender
  panel.prerender = function (self)
    pfn(self)
    local funcDef = evolutionFuncDefs[comboBox.selected]
    for i = 1, #funcDef do
      local control = controls[i]
      local label = labels[i]
      local num = tonumber(control:getText())
      label:setColor(1, 1, 1)
      if num and num ~= tonumber(funcDef[i].default) then
        label:setColor(1, 1, 0)
      end
      if num == nil or num < tonumber(funcDef[i].min) or num > tonumber(funcDef[i].max) then
        control.borderColor.a = 0.9
        control.borderColor.g = 0.0
        control.borderColor.b = 0.0
      end
    end
  end
end

local function addFunctionHandler (panel, control, paramControls)
  local controls = {} 
  local labels = {}
  local tooltipMap = {}
  local comboBox = panel.controls[control]
  for i, name in ipairs(paramControls) do
    table.insert(controls, panel.controls[name])
    table.insert(labels, panel.labels[name])
    tooltipMap[comboBox.options[i]] = getText('Sandbox_ZedEvolution_Function_option' .. i .. '_tooltip')
  end

  comboBox.onChangeArgs = { controls, labels }
  comboBox.onChange = updateFunctionSettings
  comboBox:setToolTipMap(tooltipMap)
  addPrerenderHook(panel, comboBox, controls, labels)
  updateFunctionSettings(nil, comboBox, controls, labels, true)
end

local function addHeading(panel, name, before)
  local x = 24
  local heading = ISLabel:new(0, 0, entryHLarge, getText(name), 1, 1, 1, 1, UIFont.Large)
  panel:addChild(heading)
  heading:setX(panel.controls[before].x)
  heading:setY(panel.labels[before].y)
  return heading
end

local function bumpDown(headings, elements, extra)
  local largestY = 0
  for _, element in pairs(elements) do
    local addY = 0
    for _, heading in ipairs(headings) do
      if element.y >= heading.y and element ~= heading then 
        addY = addY + entryHLarge * 1.5
      end
    end
    element:setY(element.y + addY + entryHLarge * extra)
    largestY = math.max(largestY, element.y + element.height)
  end
  return largestY
end

-- Keep deprecated controls for compatibility so their values can be accessed in-game, but hide them from view. 
local function removeDeprecatedControls (panel)
  local deprecated = { 
    'ZedEvolution.Factor', 'ZedEvolution.Crawl', 
    'ZedEvolution.CrawlLimit', 'ZedEvolution.CrawlWeight',
    'ZedEvolution.Weight',
  }
  for _, name in ipairs(deprecated) do
    panel.labels[name]:setVisible(false)
    panel.labels[name]:setY(0)
    panel.labels[name]:setWidth(0)
    panel.controls[name]:setVisible(false)
    panel.controls[name]:setY(0)
  end
end

-- Update each element with the correct language information.
local function updateSettingsPanel (panel)
  removeDeprecatedControls(panel)
  local headings = {
    addHeading(panel, 'Sandbox_ZedEvolution_TBasic', 'ZedEvolution.DoEvolve'),
    addHeading(panel, 'Sandbox_ZedEvolution_TFunc', 'ZedEvolution.Function'),
    addHeading(panel, 'Sandbox_ZedEvolution_TFactor', 'ZedEvolution.Speed'),
    addHeading(panel, 'Sandbox_ZedEvolution_TWeight', 'ZedEvolution.SpeedWeight'),
    addHeading(panel, 'Sandbox_ZedEvolution_TCap', 'ZedEvolution.SpeedMin'),
  }
  
  panel:setScrollHeight(6 + math.max(
    bumpDown(headings, panel.labels, 0),
    bumpDown(headings, panel.controls, 0),
    bumpDown(headings, headings, 0.5)
  ))
  addFunctionHandler(panel, 'ZedEvolution.Function', { 'ZedEvolution.Param1', 'ZedEvolution.Param2', 'ZedEvolution.Param3' })
  panel.controls['ZedEvolution.TransmissionLimit'].options[3] = getText('Sandbox_ZTransmission_option4')
  panel.controls['ZedEvolution.TransmissionMin'].options[3] = getText('Sandbox_ZTransmission_option4')
end

-- Add constraints to a trio of associated evolution settings.
local function addAutoConstraint (els, makeValid)
  els.evo.ZedEvolutionType = 'evo'
  els.mult.ZedEvolutionType = 'mult'

  -- If the cap is changed, invert the multiplier if it no longer makes sense.
  local pfn1 = els.evo.onChange
  els.evo.onChange = function (self, arg1, arg2)
    if pfn1 then pfn1(self, arg1, arg2) end
    local num = tonumber(els.mult:getInternalText())
    if num ~= nil then makeValid(els.mult, num, els.lore.selected, els.evo.selected) end
  end

  -- If the base value is changed, invert the multiplier if it no longer makes sense.
  local pfn2 = els.lore.onChange
  els.lore.onChange = function (self, arg1, arg2)
    if pfn2 then pfn2(self, arg1, arg2) end
    local num = tonumber(els.mult:getInternalText())
    if num ~= nil then makeValid(els.mult, num, els.lore.selected, els.evo.selected) end
  end

  -- If the multiplier is changed, set the cap to the base value if it no longer makes sense. 
  local pfn3 = els.mult.onTextChange
  els.mult.onTextChange = function (self)
    pfn3(self)
    local num = tonumber(self:getInternalText())
    if num ~= nil then makeValid(els.evo, num, els.lore.selected, els.evo.selected) end
  end
end

-- Add constraints to all the evolution setting trios.
local function addAutoConstraints (listbox)
  local lore
  local evo

  -- Fetch relevant pages.
  for _, v in ipairs(listbox.items) do
    local item = v.item
    if item.page ~= nil then
      if item.page.name == getText('Sandbox_ZedEvolution') then evo = item end
      if item.page.name == getText('Sandbox_ZombieLore') then lore = item end
    end 
  end

  -- For each attribute, constrain the associated settings.
  for attr, validator in pairs(validators) do
    local elements = {}
    for _, name in ipairs(lore.panel.settingNames) do
      if string.find(name, attr) then
        -- Zombie lore base value
        elements.lore = lore.panel.controls[name]
      end
    end
    for _, name in ipairs(evo.panel.settingNames) do
      if string.find(name, attr) then
        if string.find(name, 'Limit') then 
          -- Cap
          elements.evo = evo.panel.controls[name]
        else
          -- Multiplier
          elements.mult = evo.panel.controls[name]
        end
      end
    end
    addAutoConstraint(elements, validator)
  end
end

local function updateFunctionsFromListbox (listbox)
  for _, v in ipairs(listbox.items) do
    local item = v.item
    if item.page ~= nil and item.page.name == getText('Sandbox_ZedEvolution') then
      local controls = {} 
      local labels = {}
      local comboBox = item.panel.controls['ZedEvolution.Function']
      for _, name in ipairs({ 'ZedEvolution.Param1', 'ZedEvolution.Param2', 'ZedEvolution.Param3' }) do
        table.insert(controls, item.panel.controls[name])
        table.insert(labels, item.panel.labels[name])
      end
      updateFunctionSettings(nil, comboBox, controls, labels, false, true)
    end
  end
end

-- Make necessary UI changes given the listbox for the settings UI.
local function updateSettingsFromListbox (listbox)
  --addAutoConstraints(listbox)
  for _, v in ipairs(listbox.items) do
    local item = v.item
    if item.page ~= nil and item.page.name == getText('Sandbox_ZedEvolution') then
      updateSettingsPanel(item.panel)
    end
  end
end

-- Apply UI changes to sandbox settings.
local SandboxOptionsScreen_create = SandboxOptionsScreen.create
function SandboxOptionsScreen:create ()
  SandboxOptionsScreen_create(self)
  updateSettingsFromListbox(self.listbox)
  local pfn = self.onPresetChange
  self.onPresetChange = function ()
    pfn(self)
    updateFunctionsFromListbox(self.listbox)
  end
  self.presetList.onChange = self.onPresetChange
end

-- Apply UI changes to server settings.
local ServerSettingsScreen_create = ServerSettingsScreen.create
function ServerSettingsScreen:create ()
  ServerSettingsScreen_create(self)
  updateSettingsFromListbox(self.pageEdit.listbox)
end

