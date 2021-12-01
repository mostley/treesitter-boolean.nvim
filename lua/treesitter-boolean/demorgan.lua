local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

function M.is_boolean_constant(node)
  local type = node:type()
  return type == "true" or type == "false"
end

function M.find_boolean_expression(node)
  -- print("type: " .. node:type())
  -- print("type: " .. node:type())
  if M.is_boolean_constant(node) then
    return node
  elseif node:type() == "unary_expression" then
    return node
  elseif node:type() == "if_statement" then
    return node:named_child(0):child(1)
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

function M.flipBooleanOperator(node)
  if node:type() == "&&" then
    return "||" -- todo make language independent
  elseif node:type() == "||" then
    return "&&" -- todo make language independent
  end
end

function M.invertBinaryExpression(node)
  -- print("binary expression: " .. vim.inspect(node))
  -- print("binary expression: " .. vim.inspect(getmetatable(node)))
  local left = node:named_child(0)
  local operator = node:child(1)
  local right = node:named_child(1)
  local invertedLeft = M.getInvertedBooleanExpression(left)
  local invertedRight = M.getInvertedBooleanExpression(right)
  local flipBooleanOperator = M.flipBooleanOperator(operator)
  return { invertedLeft, " ", flipBooleanOperator, " ", invertedRight }
end

function M.getInvertedBooleanExpression(node)
  if node:type() == "binary_expression" then
    local inverted_expression = M.invertBinaryExpression(node)
    return table.concat(inverted_expression)
  elseif node:type() == "unary_expression" then
    local inverted_expression = M.invertUnaryExpression(node)
    return table.concat(inverted_expression)
  elseif node:type() == "identifier" then
    return "!" .. table.concat(ts_utils.get_node_text(node)) -- todo make language independent
  elseif node:type() == "true" then
    return "false" -- TODO make language independent
  elseif node:type() == "false" then
    return "true" -- TODO make language independent
  else
    error("Expected boolean expression")
  end
end

-- invertExpression(node: TreesitterNode) -> String
function M.invertExpression(bufnr, node)
  if not node then
    error("Expected node")
  end
  local bool_expression_node = M.find_boolean_expression(node)

  if not bool_expression_node then
    error("No boolean expression to invert found in given node")
  end

  -- print("type: " .. bool_expression_node:type())
  -- print("type: " .. bool_expression_node:type())

  local range = ts_utils.node_to_lsp_range(bool_expression_node)
  local edit = {
    range = range,
    newText = M.getInvertedBooleanExpression(bool_expression_node),
  }

  vim.lsp.util.apply_text_edits({ edit }, bufnr)
end

return M
