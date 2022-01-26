
require "SandboxOptions"

local entryH = getTextManager():getFontFromEnum(UIFont.Large):getLineHeight() + 4

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


local function addHeading(panel, name, before)
  local x = 24
  local heading = ISLabel:new(0, 0, entryH, getText(name), 1, 1, 1, 1, UIFont.Large)
  panel:addChild(heading)
  --heading:setX((panel.width - x - heading:getWidth()) / 2)
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
        addY = addY + entryH * 1.5
      end
    end
    element:setY(element.y + addY + entryH * extra)
    largestY = math.max(largestY, element.y + element.height)
  end
  return largestY
end

-- Update each element with the correct language information.
local function updateSettingsPanel (panel)
  local headings = {
    addHeading(panel, 'Sandbox_ZedEvolution_TBasic', 'ZedEvolution.DoEvolve'),
    addHeading(panel, 'Sandbox_ZedEvolution_TFactor', 'ZedEvolution.Speed'),
    addHeading(panel, 'Sandbox_ZedEvolution_TWeight', 'ZedEvolution.SpeedWeight'),
    addHeading(panel, 'Sandbox_ZedEvolution_TCap', 'ZedEvolution.SpeedLimit'),
  }
  
  panel:setScrollHeight(6 + math.max(
    bumpDown(headings, panel.labels, 0),
    bumpDown(headings, panel.controls, 0),
    bumpDown(headings, headings, 0.5)
  ))
  panel.controls['ZedEvolution.TransmissionLimit'].options[3] = getText('Sandbox_ZTransmission_option4')
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
end

-- Apply UI changes to server settings.
local ServerSettingsScreen_create = ServerSettingsScreen.create
function ServerSettingsScreen:create ()
  ServerSettingsScreen_create(self)
  updateSettingsFromListbox(self.pageEdit.listbox)
end