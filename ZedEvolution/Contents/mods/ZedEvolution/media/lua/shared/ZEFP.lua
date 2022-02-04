--- ZEFP source reader
local Reader = {}
function Reader:new (string, head)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.string = string
  o.head = head or 1
  return o
end
function Reader:clone () return Reader:new(self.string, self.head) end
function Reader:to (head) self.head = head; return self end
function Reader:read (to) return string.sub(self.string, self.head, to) end
function Reader:exec (pattern)
  local s, e = string.find(self.string, '^' .. pattern, self.head)
  return e
end



--- ZEFP rule match holder
local Match = {}
function Match:new (reader, value, ok)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.reader = reader:clone()
  o.value = value
  if ok ~= nil then o.ok = ok else o.ok = true end
  return o
end
function Match:getRaw () return self.value end
function Match:isSuccess () return self.ok end
function Match:getReader () return self.reader end



--- ZEFP rule node
local Node = {}
function Node:new (name, children, modifier, handler)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.name = name
  o.children = children
  if modifier then
    o.modifier = modifier
  else
    o.modifier = function (o) return o end
  end
  o.handler = handler
  return o
end
function Node:parse (grammar, reader) return self.handler(self, grammar, reader) end
function Node:fail (reader) return Match:new(reader, {}, false) end
function Node:applyOne (match, reader) return Match:new(reader, self.modifier(match:getRaw()), true) end
function Node:apply (matches, reader)
  local raws = {}
  for i, match in ipairs(matches) do
    raws[i] = match:getRaw()
  end
  return Match:new(reader, self.modifier(raws), true)
end



--- ZEFP node tree handlers
local handlers = {}

function handlers.OR (node, grammar, reader)
  for i, child in ipairs(node.children) do
    local match = child:parse(grammar, reader)
    if match:isSuccess() then return node:applyOne(match, match:getReader()) end
  end
  return node:fail(reader)
end

function handlers.NOT (node, grammar, reader)
  local child = node.children[1]
  local match = child:parse(grammar, reader)
  if match:isSuccess() then return node:fail(reader) end
  return node:applyOne(Match:new(reader, {}, true), reader)
end

function handlers.RULE (node, grammar, reader)
  local str = node.children[1]
  local match = grammar[str]:parse(grammar, reader)
  if not match:isSuccess() then return node:fail(reader) end
  return node:applyOne(match, match:getReader())
end

function handlers.OPLUS (node, grammar, reader)
  local matches = {}
  local child = node.children[1]
  repeat
    local match = child:parse(grammar, reader)
    if match:isSuccess() then
      reader = match:getReader()
      table.insert(matches, match)
    end
  until not match:isSuccess()
  if #matches > 0 then
    return node:apply(matches, reader)
  else
    return node:fail(reader)
  end
end

function handlers.ZPLUS (node, grammar, reader)
  local matches = {}
  local child = node.children[1]
  repeat
    local match = child:parse(grammar, reader)
    if match:isSuccess() then
      reader = match:getReader()
      table.insert(matches, match)
    end
  until not match:isSuccess()
  return node:apply(matches, reader)
end

function handlers.MAYBE (node, grammar, reader)
  local matches = {}
  local child = node.children[1]
  local match = child:parse(grammar, reader)
  if match:isSuccess() then
    reader = match:getReader()
    table.insert(matches, match)
  end
  return node:apply(matches, reader)
end

function handlers.PATT (node, grammar, reader)
  local pattern = node.children[1]
  local endPos = reader:exec(node.children[1])
  if not endPos then return node:fail(reader) end
  local str = reader:read(endPos)
  reader = reader:clone():to(endPos + 1)
  return node:applyOne(Match:new(reader, str), reader)
end

function handlers.SEQ (node, grammar, reader)
  local matches = {}
  for i, child in ipairs(node.children) do
    local match = child:parse(grammar, reader)
    if not match:isSuccess() then return node:fail(reader) end
    reader = match:getReader()
    matches[i] = match
  end
  return node:apply(matches, reader)
end



--- ZedEvolution Function Parser
ZEFP = {}
function ZEFP.NOT (node, func) return Node:new('NOT', { node }, func, handlers.NOT) end
function ZEFP.RULE (node, func) return Node:new('RULE', { node }, func, handlers.RULE) end
function ZEFP.OPLUS (node, func) return Node:new('OPLUS', { node }, func, handlers.OPLUS) end
function ZEFP.ZPLUS (node, func) return Node:new('ZPLUS', { node }, func, handlers.ZPLUS) end
function ZEFP.MAYBE (node, func) return Node:new('MAYBE', { node }, func, handlers.MAYBE) end
function ZEFP.PATT (node, func) return Node:new('PATT', { node }, func, handlers.PATT) end
function ZEFP.OR (nodes, func) return Node:new('OR', nodes, func, handlers.OR) end
function ZEFP.SEQ (nodes, func) return Node:new('SEQ', nodes, func, handlers.SEQ) end
function ZEFP.RULESEQ (nodes, func)
  local tbl = {}
  for i, node in ipairs(nodes) do tbl[i] = ZEFP.RULE(node) end
  return ZEFP.SEQ(tbl, func)
end
function ZEFP.PATTSEQ (nodes, func)
  local tbl = {}
  for i, node in ipairs(nodes) do tbl[i] = ZEFP.PATT(node) end
  return ZEFP.SEQ(tbl, func)
end



--- ZEFP parser generator
function ZEFP.getParser (grammar, root)
  return function (source)
    local reader = Reader:new(source)
    local match = root:parse(grammar, reader)
    if match.reader.head < string.len(source) then
      return root:fail(reader)
    else
      return match
    end
  end
end



ZEFP.Node = Node
ZEFP.Match = Match
ZEFP.Reader = Reader
