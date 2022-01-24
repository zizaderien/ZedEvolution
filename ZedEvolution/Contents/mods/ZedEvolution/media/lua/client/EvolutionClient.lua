
require "SandboxOptions"

-- Set a tooltip for one element
local function setTooltip(element, tooltip)
  local translatedTooltip = getText('Sandbox_' .. tooltip:gsub('%.', '_') .. '_Tooltip')
    :gsub('\\n', '\n')
    :gsub('\\"', '"')
    .. '.'
  if element.setTooltip then
    element:setTooltip(translatedTooltip)
  elseif element.setToolTipMap then
    element:setToolTipMap({defaultTooltip = translatedTooltip})
  end
end

-- Set each tooltip given the elements to apply it to
local function setEachTooltip(elements)
  for name, element in pairs(elements) do setTooltip(element, name) end
end

-- Ensure tooltips for custom sandbox options are set.
-- Not yet shown in server / coop settings because that's a pain to hook into.
local SandboxOptionsScreen_createPanel = SandboxOptionsScreen.createPanel
function SandboxOptionsScreen:createPanel (page)
  local panel = SandboxOptionsScreen_createPanel(self, page)
  if page.name == getText('Sandbox_ZedEvolution') then
    setEachTooltip(panel.labels)
    setEachTooltip(panel.controls)
  end
  return panel
end