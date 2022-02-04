require "ZEFGrammar"
require "ZEFLib"
require "ZEFRuntime"

ZEFunction = {}

local runtime = ZEFRuntime:new()
runtime:addFunctions(ZEFLib.functions)
runtime:addOperators(ZEFLib.operators)
runtime:addParameters(ZEFLib.parameters)
runtime:addConstants(ZEFLib.constants)
local parse = ZEFGrammar.create(runtime:getFunctions(), runtime:getParameters(), runtime:getConstants())

function ZEFunction:new (source)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.ast = parse(source).value
  --print(ZEUtils.kv('ast', o.ast))
  o.ast = runtime:preprocess(o.ast)
  return o
end

function ZEFunction:execute ()
  return runtime:run(self.ast)
end




--local fn = ZEFunction:new('sqrt 16 - 4! / (2 + 1 + rain)')
--print(fn:execute())