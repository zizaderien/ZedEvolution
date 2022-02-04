ZEFRuntime = {}

local function unpackNodes (node)
  if type(node) == 'table' then
    if node.type == 'list' then
      return unpack(node.args)
    else
      return (unpackNodes(node[1])), (unpackNodes(node[2]))
    end
  else
    return node
  end
end

function ZEFRuntime:new ()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.functions = {}
  o.parameters = {}
  o.constants = {}
  o.operators = {}
  return o
end

function ZEFRuntime:addFunctions (tbl)
  for name, func in pairs(tbl) do self.functions[name] = func end
end

function ZEFRuntime:addParameters (tbl)
  for name, func in pairs(tbl) do self.parameters[name] = func end
end

function ZEFRuntime:addConstants (tbl)
  for name, func in pairs(tbl) do self.parameters[name] = func end
end

function ZEFRuntime:addOperators (tbl)
  for name, func in pairs(tbl) do self.operators[name] = func end
end

function ZEFRuntime:getFunctions ()
  return self.functions
end

function ZEFRuntime:getParameters ()
  return self.parameters
end

function ZEFRuntime:getConstants ()
  return self.constants
end

function ZEFRuntime:preprocess (node)
  if type(node) == 'table' and node.type then
    -- Parameters cannot be simplified
    if node.type == 'param' then
      return node, false

    -- Constants can always be precalculated
    elseif node.type == 'const' then
      return self.constants[node.op](), true

    -- Simplify list by simplifying all elements
    elseif node.type == 'list' then
      local primitive = true
      for i, child in ipairs(node.args) do
        local n, p = self:preprocess(child)
        node.args[i] = n
        if not p then primitive = false end
      end
      return node, primitive
    
    -- Simplify infix operator by simplifying all operands first
    elseif node.type == 'infix' then
      local primitive = true
      for i, child in ipairs(node.args) do
        local n, p = self:preprocess(child)
        node.args[i] = n
        if not p then primitive = false end
      end
      if primitive then node = self.operators['infix_' .. node.op](unpackNodes(node.args)) end
      return node, primitive

    -- Everything else has just one argument
    else
      local n, p = self:preprocess(node.args)
      node.args = n
      if p then 
        if node.type == 'prefix' then 
          node = self.operators['prefix_' .. node.op](unpackNodes(node.args))
        elseif node.type == 'postfix' then 
          node = self.operators['postfix_' .. node.op](unpackNodes(node.args))
        elseif node.type == 'func' then 
          node = self.functions[node.op](unpackNodes(node.args)) 
        end
      end
      return node, p
    end
  else
    -- Already simplified
    return node, true
  end
end

function ZEFRuntime:execute (node)
  if type(node) == 'table' and node.type then
    -- Compute parameters
    if node.type == 'param' then
      return self.parameters[node.op]()

    -- Compute constants
    elseif node.type == 'const' then
      return self.constants[node.op]()

    -- Compute list entries
    elseif node.type == 'list' then
      for i, child in ipairs(node.args) do
        node.args[i] = self:execute(child)
      end
      return node

    -- Compute args for infix
    elseif node.type == 'infix' then
      for i, child in ipairs(node.args) do
        node.args[i] = self:execute(child)
      end
      return self.operators['infix_' .. node.op](unpackNodes(node.args))

    -- Compute other args
    else
      local arg = self:execute(node.args)
      if node.type == 'prefix' then 
        return self.operators['prefix_' .. node.op](unpackNodes(arg))
      elseif node.type == 'postfix' then 
        return self.operators['postfix_' .. node.op](unpackNodes(arg))
      elseif node.type == 'func' then 
        return self.functions[node.op](unpackNodes(arg)) 
      end
    end
  else
    return node
  end
end

function ZEFRuntime:run (ast)
  --print(ZEUtils.kv('ast', ast))
  local result = self:execute(ast)
  --print(ZEUtils.kv('result', result))
  -- Tables only get unpacked when used, so if the root node is a table we unpack it manually.
  if type(result) == 'table' then return (unpackNodes(result)) end
  return result
end
