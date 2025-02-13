local function escape_literal(literal)
  local special_chars = {
    ["\\"] = true,
    ["^"] = true,
    ["$"] = true,
    ["."] = true,
    ["*"] = true,
    ["("] = true,
    [")"] = true,
    ["@"] = true,
  }

  local result = string.gsub(literal, ".", function(char)
    if special_chars[char] then
      return "\\" .. char
    else
      return char
    end
  end)

  return result
end

local function make_special(value)
  return { type = "special", value = value }
end

local function make_literal(value, is_literal)
  return { type = "literal", value = value, is_literal = is_literal }
end

local function startswith(str, prefix)
  return string.sub(str, 1, #prefix) == prefix
end

local function get_node_type(v)
  if v.type then
    return v.type
  elseif type(v) == "table" then
    return "tree"
  else
    error(string.format("not a node: %s", v))
  end
end

local function is_group(v)
  if get_node_type(v) ~= "tree" then
    return false
  else
    local first_node = v[1]
    return first_node and first_node.type == "special" and first_node.value == "{"
  end
end

local function split_group(group)
  -- split the group into sub-trees. Maybe I should fix the grammar so this
  -- happens automatically?
  local output = {}

  for _, node in ipairs(group) do
    if node.type == "special" then
      if node.value == "{" or node.value == "," then
        table.insert(output, {})
      elseif node.value ~= "}" then
        table.insert(output[#output], node)
      end
    else
      table.insert(output[#output], node)
    end
  end

  return output
end

local function compile_to_regex(tree)
  local function compile_special(value)
    if value == "*" then
      return "[^/]*"
    elseif value == "?" then
      return "."
    elseif value == "{" then
      return "("
    elseif value == "}" then
      return ")"
    elseif value == "," then
      return "|"
    elseif startswith(value, "**") then
      return ".*"
    else
      return value
    end
  end

  local function compile_literal(value, is_literal)
    if is_literal then
      return value
    else
      return escape_literal(value)
    end
  end

  local regex = ""
  for _, node in ipairs(tree) do
    local node_str
    local node_type = get_node_type(node)

    if node_type == "tree" then
      node_str = compile_to_regex(node)
    elseif node_type == "special" then
      node_str = compile_special(node.value)
    elseif node_type == "literal" then
      node_str = compile_literal(node.value, node.is_literal)
    end

    regex = regex .. node_str
  end

  return regex
end

-- LPeg grammar setup
local Ct, C, P, S, R, V = vim.lpeg.Ct, vim.lpeg.C, vim.lpeg.P, vim.lpeg.S, vim.lpeg.R, vim.lpeg.V

local GroupLiteralChar = R("AZ") + R("az") + R("09") + S(" !-+@_~;:./$^")
local LiteralChar = GroupLiteralChar + S(",}")
local OneStar = P("*") / make_special
local QuestionMark = P("?") / make_special
local TwoStars = (P("**") * (P("/*")) ^ 0) / make_special
local OpenGroup = P("{") / make_special
local CloseGroup = P("}") / make_special
local Comma = P(",") / make_special
local OpenRange = P("[") / make_special
local CloseRange = P("]") / make_special
local RangeNegation = P("!") / make_special
local RangeLiteral = (P(1) - P("]")) ^ 1 / function(x)
  return make_literal(x, true)
end
local InsideRange = (RangeNegation ^ -1) * RangeLiteral
local Range = OpenRange * InsideRange * CloseRange
local GroupLiteral = GroupLiteralChar ^ 1 / make_literal
local Literal = LiteralChar ^ 1 / make_literal

local glob_parser = P({
  V("Glob"),
  Glob = Ct(V("Term") ^ 1),
  Term = TwoStars + OneStar + QuestionMark + V("Group") + Literal + Range,
  Group = Ct(OpenGroup * V("InsideGroup") * CloseGroup),
  InsideGroup = V("GroupGlob") * (Comma * V("GroupGlob")) ^ 0,
  GroupGlob = V("GroupTerm") ^ 1,
  GroupTerm = TwoStars + OneStar + QuestionMark + V("Group") + GroupLiteral + Range,
})

glob_parser = glob_parser * -1

local function parse(glob)
  return vim.lpeg.match(glob_parser, glob)
end

local function compile(glob)
  local tree = parse(glob)
  if tree then
    local re = compile_to_regex(tree)
    re = "\\v^" .. re .. "$"
    local ok, pat_or_err = pcall(vim.regex, re)
    if ok then
      return true, pat_or_err
    else
      return false,
        string.format(
          "internal error compiling glob string '%s' to a regular expression:\n"
            .. "  generated regex: %s\n"
            .. "  vim.regex error: %s",
          glob,
          re,
          pat_or_err
        )
    end
  else
    return false, string.format("invalid glob string '%s'", glob)
  end
end

local function do_match(patt, str)
  local m = patt:match_str(str)
  return m and true or false
end

local function break_tree(tree)
  local function accumulate(acc, nodes)
    local result = {}
    for _, node_str in ipairs(nodes) do
      for _, e in ipairs(acc) do
        table.insert(result, e .. node_str)
      end
    end
    return result
  end

  local acc = { "" }
  for _, node in ipairs(tree) do
    if is_group(node) then
      local trees = split_group(node)
      local broken_trees = {}

      for _, t in ipairs(trees) do
        table.insert(broken_trees, break_tree(t))
      end

      local result = {}
      for _, nodes_str in ipairs(broken_trees) do
        acc = accumulate(acc, nodes_str)
      end
    else
      local new_acc = {}
      for _, e in ipairs(acc) do
        table.insert(new_acc, e .. node.value)
      end
      acc = new_acc
    end
  end

  return acc
end

local function strip_special(glob)
  return string.gsub(glob, "/?[^/]+[*?[{].*", "")
end

local function break_glob(glob)
  local tree = parse(glob)
  if not tree then
    vim.api.nvim_echo({
      { string.format("invalid glob %s", vim.inspect(glob)), "WarningMsg" },
    }, true, {})
    return nil
  else
    return break_tree(tree)
  end
end

return {
  compile = compile,
  match = do_match,
  break_glob = break_glob,
  parse = parse,
  strip_special = strip_special,
}
