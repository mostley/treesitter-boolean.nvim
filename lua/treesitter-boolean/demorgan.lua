local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

local language_specific_constants = {
  ["c"] = {
    ["!"] = "!",
    ["&&"] = "&&",
    ["||"] = "||",
    ["true"] = "true",
    ["false"] = "false",
  },
  ["python"] = {
    ["!"] = "not ",
    ["&&"] = "and",
    ["||"] = "or",
    ["true"] = "True",
    ["false"] = "False",
  },
}
language_specific_constants["javascript"] = language_specific_constants["c"]
language_specific_constants["typescript"] = language_specific_constants["c"]

function M.is_boolean_constant(node)
  local type = node:type()
  return type == "true" or type == "false"
end

function M.find_boolean_expression(node)
  -- print("find type: " .. node:type())
  if M.is_boolean_constant(node) then
    return node
  elseif node:type() == "unary_expression" then
    return node
  elseif node:type() == "if_statement" then
    local result = node:named_child(0)
    if result:type() == "parenthesized_expression" then
      result = result:child(1)
    end
    return result
  end

  for i = 0, node:named_child_count() - 1, 1 do
    local child = node:named_child(i)
    local result = M.find_boolean_expression(child)
    if result then
      return result
    end
  end

  return nil
end

function M.simplify_boolean_expression(node)
  local result = node
  if result:type() == "parenthesized_expression" then
    result = result:child(1)
  end
  return result
end

function M.invertUnaryExpression(node)
  local result = node:child(1) -- take 2nd child of unary expression to invert
  result = M.simplify_boolean_expression(result)
  return ts_utils.get_node_text(result)
end

function M.flipBooleanOperator(node, filetype)
  if node:type() == "&&" or node:type() == "and" then
    return language_specific_constants[filetype]["||"]
  elseif node:type() == "||" or node:type() == "or" then
    return language_specific_constants[filetype]["&&"]
  end
  error("Unexpected Boolean operator: " .. node:type())
end

function M.invertBinaryExpression(node, filetype)
  -- print("binary expression type: " .. node:type())
  -- print("binary expression: " .. vim.inspect(getmetatable(node)))
  local left = node:named_child(0)
  local operator = node:child(1)
  local right = node:named_child(1)

  -- print("left type: " .. left:type())
  -- print("operator type: " .. operator:type())
  -- print("right type: " .. right:type())

  local invertedLeft = M.getInvertedBooleanExpression(left, filetype)
  local invertedRight = M.getInvertedBooleanExpression(right, filetype)
  local invertedOperator = M.flipBooleanOperator(operator, filetype)

  -- print("inverted left: " .. invertedLeft)
  -- print("inverted operator: " .. invertedOperator)
  -- print("inverted right: " .. invertedRight)

  return { invertedLeft, " ", invertedOperator, " ", invertedRight }
end

function M.getInvertedBooleanExpression(node, filetype)
  -- print("getInvertedBooleanExpression " .. node:type())
  -- print("getInvertedBooleanExpression " .. node:type())
  if node:type() == "binary_expression" or node:type() == "boolean_operator" then
    local inverted_expression = M.invertBinaryExpression(node, filetype)
    return table.concat(inverted_expression)
  elseif node:type() == "unary_expression" then
    local inverted_expression = M.invertUnaryExpression(node)
    return table.concat(inverted_expression)
  elseif node:type() == "identifier" then
    local unary_operator = language_specific_constants[filetype]["!"]
    return unary_operator .. table.concat(ts_utils.get_node_text(node))
  elseif node:type() == "true" then
    return language_specific_constants[filetype]["false"]
  elseif node:type() == "false" then
    return language_specific_constants[filetype]["true"]
  else
    error("Expected boolean expression. Received: " .. node:type())
  end
end

-- invertExpression(node: TreesitterNode) -> String
function M.invertExpression(bufnr, node)
  -- print(">>")
  -- print(">>")
  if not node then
    error("Expected node")
  end
  -- print("node type: " .. node:type())
  -- print("node type: " .. node:type())
  local bool_expression_node = M.find_boolean_expression(node)

  if not bool_expression_node then
    error("No boolean expression to invert found in given node")
  end

  -- print("type: " .. bool_expression_node:type())
  -- print("type: " .. bool_expression_node:type())
  local filetype = vim.bo[bufnr].filetype
  if not language_specific_constants[filetype] then
    error("filetype not supported: " .. filetype)
  end

  local range = ts_utils.node_to_lsp_range(bool_expression_node)
  local newText = M.getInvertedBooleanExpression(bool_expression_node, filetype)
  -- print("newText " .. newText)
  -- print("newText " .. newText)
  local edit = {
    range = range,
    newText = newText,
  }

  vim.lsp.util.apply_text_edits({ edit }, bufnr)
  -- print("<<")
  -- print("<<")
end

return M
