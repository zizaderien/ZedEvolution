require "ZEFP"
require "ZEUtils"

ZEFGrammar = {}

-- AST util functions
local function getIndex (i) return function (o) return o[i] end end
local function createNode (type, op, args) return { type = type, op = op, args = args} end
local function createParam (o) return createNode('param', o, {}) end
local function createConst (o) return createNode('const', o, {}) end
local function createFunc (o) return createNode('func', o[2], o[4]) end
local function createPrefix (o) return createNode('prefix', o[2], o[4]) end
local function createInfix (o)
  return ZEUtils.reduce(o[2], function (a, c)
    return createNode('infix', c[2], { a, c[4] })
  end, o[1])
end
local function createList (o)
  local tbl = { o[1] }
  for _, el in ipairs(o[2]) do table.insert(tbl, el[4]) end
  return createNode ('list', nil, tbl)
end
local function createPostfix (o)
  return ZEUtils.reduce(o[2], function (a, c)
    return createNode('postfix', c, a)
  end, o[1])
end

--- Create a parser
function ZEFGrammar.create (funcs, params, consts) 
  local funcPatterns = {}
  local paramPatterns = {}
  local constPatterns = {}
  for name, _ in pairs(funcs) do table.insert(funcPatterns, ZEFP.PATT(name)) end
  for name, _ in pairs(params) do table.insert(paramPatterns, ZEFP.PATT(name)) end
  for name, _ in pairs(consts) do table.insert(constPatterns, ZEFP.PATT(name)) end

  local grammar = {
    -- Literals
    numExpr = ZEFP.OR({ ZEFP.RULE('numHead'), ZEFP.RULE('numTail') }, tonumber),
    numHead = ZEFP.SEQ({ ZEFP.RULE('numPart'), ZEFP.MAYBE(ZEFP.RULE('numTail'), getIndex(1)) }, table.concat),
    numTail = ZEFP.RULESEQ({ 'dec', 'numPart' }, table.concat),
    numPart = ZEFP.SEQ(
      { ZEFP.OPLUS(ZEFP.RULE('dig')), ZEFP.NOT(ZEFP.RULE('chr')) },
      function (o) return table.concat(o[1]) end),

    -- Expressions
    baseExpr = ZEFP.RULE('addExpr'),
    primExpr = ZEFP.OR({ ZEFP.RULE('grExpr'), ZEFP.RULE('param'), ZEFP.RULE('const'), ZEFP.RULE('numExpr') }),

    -- Postfix operators
    postExpr = ZEFP.SEQ({ ZEFP.RULE('primExpr'), ZEFP.ZPLUS(ZEFP.RULE('postOp')) }, createPostfix),

    -- Prefix operators
    prefExpr = ZEFP.OR({ ZEFP.RULE('postExpr'), ZEFP.OR({ ZEFP.RULE('prefTail'), ZEFP.RULE('prefFuncTail') }) }),
    prefTail = ZEFP.RULESEQ({ '_', 'prefOp', '_', 'prefExpr' }, createPrefix),
    prefFuncTail = ZEFP.RULESEQ({ '_', 'func', '_', 'prefExpr' }, createFunc),

    -- Exponentiation (right-associative)
    expExpr = ZEFP.SEQ({ ZEFP.RULE('prefExpr'), ZEFP.ZPLUS(ZEFP.RULE('expTail')) }, createInfix),
    expTail = ZEFP.RULESEQ({ '_', 'expOp', '_', 'expExpr' }),

    --  Multiplication (left-associative)
    multExpr = ZEFP.SEQ({ ZEFP.RULE('expExpr'), ZEFP.ZPLUS(ZEFP.RULE('multTail')) }, createInfix),
    multTail = ZEFP.RULESEQ({ '_', 'multOp', '_', 'expExpr' }),

    -- Addition (left-associative)
    addExpr = ZEFP.SEQ({ ZEFP.RULE('multExpr'), ZEFP.ZPLUS(ZEFP.RULE('addTail'))}, createInfix),
    addTail = ZEFP.RULESEQ({ '_', 'addOp', '_', 'multExpr' }),

    -- Parentheses
    seqExpr = ZEFP.SEQ({ ZEFP.RULE('baseExpr'), ZEFP.ZPLUS(ZEFP.RULE('seqTail')) }, createList),
    seqTail = ZEFP.RULESEQ({ '_', 'seq', '_', 'baseExpr' }, getIndex(4)),
    grExpr = ZEFP.RULESEQ({ 'grOpen', '_', 'seqExpr', '_', 'grClose' }, getIndex(3)),

    -- Tokens
    postOp = ZEFP.OR({ ZEFP.PATT('%%'), ZEFP.PATT('!') }),
    prefOp = ZEFP.OR({ ZEFP.PATT('%-'), ZEFP.PATT('%+') }),
    expOp = ZEFP.PATT('%^'),
    multOp = ZEFP.OR({ ZEFP.PATT('%*'), ZEFP.PATT('/') }),
    addOp = ZEFP.OR({ ZEFP.PATT('%-'), ZEFP.PATT('%+') }),
    dec = ZEFP.PATT('%.'),
    seq = ZEFP.PATT(','),
    grOpen = ZEFP.PATT('%('),
    grClose = ZEFP.PATT('%)'),

    -- Functions and parameters
    func = ZEFP.SEQ({ ZEFP.OR(funcPatterns), ZEFP.NOT(ZEFP.RULE('chrdig')) }, getIndex(1)),
    param = ZEFP.SEQ({ ZEFP.OR(paramPatterns, createParam), ZEFP.NOT(ZEFP.RULE('chrdig')) }, getIndex(1)),
    const = ZEFP.SEQ({ ZEFP.OR(constPatterns, createConst), ZEFP.NOT(ZEFP.RULE('chrdig')) }, getIndex(1)),

    -- Character sets
    chr = ZEFP.PATT('%a'),
    dig = ZEFP.PATT('%d'),
    chrdig = ZEFP.OR({ ZEFP.RULE('chr'), ZEFP.RULE('dig') }),
    _ = ZEFP.ZPLUS(ZEFP.PATT('%s')),
  }

  return ZEFP.getParser(grammar, grammar.baseExpr)
end