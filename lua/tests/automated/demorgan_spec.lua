local treesitterBoolean = require("../../treesitter-boolean")
local ts_utils = require("nvim-treesitter.ts_utils")

local setup_file = function(lines, extension)
  vim.api.nvim_command(":set noswapfile")
  vim.api.nvim_command(":e! testfile." .. extension)
  for _, line in ipairs(lines) do
    vim.api.nvim_command(":normal o" .. line)
  end
  vim.api.nvim_command(":normal gg")
  vim.api.nvim_command(":normal dd")
  vim.api.nvim_command(":normal 0")
  return vim.api.nvim_get_current_buf()
end

local buffer_to_string = function(bufnr)
  local content = vim.api.nvim_buf_get_lines(bufnr, 0, vim.api.nvim_buf_line_count(0), false)
  return table.concat(content, "\n")
end

local buffer_is_same = function(bufnr, expected_lines)
  local buffer_content = buffer_to_string(bufnr)
  local expected_string = table.concat(expected_lines, "\n")
  -- print("--")
  -- print("e" .. vim.inspect(expected_string))
  -- print("i" .. vim.inspect(buffer_content))
  -- print("--")
  assert.are.same(expected_string, buffer_content)
end

describe("TreesitterBoolean.demorgan", function()
  describe("invertExpression", function() -----------------------------------------------
    after_each(function()
      -- clear buffer
      vim.api.nvim_command(":normal gg")
      vim.api.nvim_command(":normal V")
      vim.api.nvim_command(":normal G")
      vim.api.nvim_command(":normal d")
    end)

    describe("[typescript]", function() -----------------------------------------------
      describe("with constants", function() -----------------------------------------------
        it("should invert true to false in assignments", function()
          local bufnr = setup_file({ [[const a = true;]] }, "ts")
          treesitterBoolean.demorgan.invertExpression(bufnr, ts_utils:get_node_at_cursor())

          buffer_is_same(bufnr, { "const a = false;" })
        end)

        it("should invert false to true in assignments", function()
          local bufnr = setup_file({ [[const a = false;]] }, "ts")
          treesitterBoolean.demorgan.invertExpression(bufnr, ts_utils:get_node_at_cursor())

          buffer_is_same(bufnr, { "const a = true;" })
        end)

        it("should invert constant in if term", function()
          local bufnr = setup_file({ "if (true) {", "console.log('always')", "}" }, "ts")
          treesitterBoolean.demorgan.invertExpression(bufnr, ts_utils:get_node_at_cursor())

          buffer_is_same(bufnr, { "if (false) {", "\tconsole.log('always')", "}" })
        end)

        it("should invert constant in loop term", function()
          local bufnr = setup_file({ "while (true) {", "console.log('always')", "}" }, "ts")
          treesitterBoolean.demorgan.invertExpression(bufnr, ts_utils:get_node_at_cursor())

          buffer_is_same(bufnr, { "while (false) {", "\tconsole.log('always')", "}" })
        end)
      end)

      describe("with boolean variable", function() -----------------------------------------------
        it("should invert variable in assignment", function()
          local bufnr = setup_file({ "const a = true;", "const b = !a;" }, "ts")
          vim.api.nvim_command(":normal j") -- move cursor to the start of the if statement

          treesitterBoolean.demorgan.invertExpression(bufnr, ts_utils:get_node_at_cursor())

          buffer_is_same(bufnr, { "const a = true;", "const b = a;" })
        end)

        it("should invert variable in if term", function()
          local bufnr = setup_file({ "const a = true;", "if (a) {", "console.log('always')", "}" }, "ts")
          vim.api.nvim_command(":normal j") -- move cursor to the start of the if statement

          treesitterBoolean.demorgan.invertExpression(bufnr, ts_utils:get_node_at_cursor())

          buffer_is_same(bufnr, { "const a = true;", "if (!a) {", "\tconsole.log('always')", "}" })
        end)
      end)

      describe("with unary operator", function() -----------------------------------------------
        it("should invert variable in if term", function()
          local bufnr = setup_file({ "const a = true;", "if (!a) {", "console.log('always')", "}" }, "ts")
          vim.api.nvim_command(":normal j") -- move cursor to the start of the if statement

          treesitterBoolean.demorgan.invertExpression(bufnr, ts_utils:get_node_at_cursor())

          buffer_is_same(bufnr, { "const a = true;", "if (a) {", "\tconsole.log('always')", "}" })
        end)

        it("should invert parenthesized_expression in if term", function()
          local bufnr = setup_file({ "const a = true;", "if (!(true && a)) {", "console.log('always')", "}" }, "ts")
          vim.api.nvim_command(":normal j") -- move cursor to the start of the if statement

          treesitterBoolean.demorgan.invertExpression(bufnr, ts_utils:get_node_at_cursor())

          buffer_is_same(bufnr, { "const a = true;", "if (true && a) {", "\tconsole.log('always')", "}" })
        end)
      end)

      describe("with and", function() -----------------------------------------------
        it("should invert simple and logic", function()
          local bufnr = setup_file({ "const a = true;", "if (true && a) {", "console.log('always')", "}" }, "ts")
          vim.api.nvim_command(":normal j") -- move cursor to the start of the if statement

          treesitterBoolean.demorgan.invertExpression(bufnr, ts_utils:get_node_at_cursor())

          buffer_is_same(bufnr, { "const a = true;", "if (false || !a) {", "\tconsole.log('always')", "}" })
        end)

        it("should invert simple or logic", function()
          local bufnr = setup_file({ "const a = true;", "if (true || a) {", "console.log('always')", "}" }, "ts")
          vim.api.nvim_command(":normal j") -- move cursor to the start of the if statement

          treesitterBoolean.demorgan.invertExpression(bufnr, ts_utils:get_node_at_cursor())

          buffer_is_same(bufnr, { "const a = true;", "if (false && !a) {", "\tconsole.log('always')", "}" })
        end)
      end)
    end)

    describe("[python]", function() -----------------------------------------------
      describe("with and", function() -----------------------------------------------
        it("should invert simple and logic", function()
          local bufnr = setup_file({ "a = True", "if True and a:", "print('always')" }, "py")
          vim.api.nvim_command(":normal j") -- move cursor to the start of the if statement

          treesitterBoolean.demorgan.invertExpression(bufnr, ts_utils:get_node_at_cursor())

          buffer_is_same(bufnr, { "a = True", "if False or not a:", "    print('always')" })
        end)

        it("should invert simple or logic", function()
          local bufnr = setup_file({ "a = True", "if True or a:", "print('always')" }, "py")
          vim.api.nvim_command(":normal j") -- move cursor to the start of the if statement

          treesitterBoolean.demorgan.invertExpression(bufnr, ts_utils:get_node_at_cursor())

          buffer_is_same(bufnr, { "a = True", "if False and not a:", "    print('always')" })
        end)
      end)
    end)
  end)
end)
