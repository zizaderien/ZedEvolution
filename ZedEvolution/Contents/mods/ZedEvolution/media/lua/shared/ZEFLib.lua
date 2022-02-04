require "ZEUtils"

ZEFLib = {}

local asinh = function (x) return math.log(x + math.sqrt(math.pow(x, 2) + 1)) end
local acosh = function (x) return math.log(x + math.sqrt(math.pow(x, 2) - 1)) end
local atanh = function (x) return 0.5 * math.log(1 + x) - 0.5 * math.log(1 - x) end

local e = math.exp(1)
local phi = (1 + math.sqrt(5)) / 2

--- Operator table
ZEFLib.operators = {}
local infixOps = {}
local prefixOps = {}
local postfixOps = {}
infixOps['+'] = function (l, r) return l + r end
infixOps['-'] = function (l, r) return l - r end
infixOps['*'] = function (l, r) return l * r end
infixOps['/'] = function (l, r) return l / r end
infixOps['^'] = function (l, r) return math.pow(l, r) end
infixOps['%'] = function (l, r) return math.fmod(l, r) end
prefixOps['+'] = function (arg) return arg end
prefixOps['-'] = function (arg) return -arg end
postfixOps['!'] = function (arg) return ZEUtils.gamma(arg + 1) end
postfixOps['%'] = function (arg) return arg / 100 end
for k, v in pairs(infixOps) do ZEFLib.operators['infix_' .. k] = v end
for k, v in pairs(prefixOps) do ZEFLib.operators['prefix_' .. k] = v end
for k, v in pairs(postfixOps) do ZEFLib.operators['postfix_' .. k] = v end

--- Function table
ZEFLib.functions = {
  -- Exponentiation
  log = math.log,
  pow = math.pow,
  exp = math.exp,
  sqrt = math.sqrt,

  -- Trigenometry
  deg = math.deg,
  rad = math.rad,

  sin = math.sin,
  cos = math.cos,
  tan = math.tan,
  cot = function (x) return 1 / math.tan(x) end,
  sec = function (x) return 1 / math.cos(x) end,
  csc = function (x) return 1 / math.sin(x) end,

  sinh = math.sinh,
  cosh = math.cosh,
  tanh = math.tanh,
  coth = function (x) return 1 / math.tanh(x) end,
  sech = function (x) return 1 / math.cosh(x) end,
  csch = function (x) return 1 / math.sinh(x) end,

  asin = math.asin,
  acos = math.acos,
  atan = math.atan,
  acot = function (x) return math.atan(1 / x) end,
  asec = function (x) return math.acos(1 / x) end,
  acsc = function (x) return math.asin(1 / x) end,

  asinh = asinh,
  acosh = acosh,
  atanh = atanh,
  acoth = function (x) return atanh(1 / x) end,
  asech = function (x) return acosh(1 / x) end,
  acsch = function (x) return asinh(1 / x) end,

  -- Misc
  min = math.min,
  max = math.max,
  abs = math.abs,
  floor = math.floor,
  ceil = math.ceil,
  sign = math.sign,
  sgn = math.sign,
}

--- Constant table
ZEFLib.constants = {
  e = function () return e end,
  phi = function () return phi end,
  inf = function () return math.huge end,
  pi = function () return math.pi end,
  tau = function () return math.pi * 2 end,
}

--- Parameter table
ZEFLib.parameters = {
  days = function () return ZEUtils.getTimeElapsed() / 86400 end,
  hours = function () return ZEUtils.getTimeElapsed() / 3600 end,
  minutes = function () return ZEUtils.getTimeElapsed() / 60 end,

  rain = function () return 0 end,
}