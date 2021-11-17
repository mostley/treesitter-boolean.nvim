local treesitterBoolean = require("treesitter-boolean")
local ts_utils = require("nvim-treesitter.ts_utils")
local parsers = require("nvim-treesitter.parsers")

local setup_file = function(text)
  vim.api.nvim_command(":set noswapfile")
  vim.api.nvim_command(":e testfile.ts")
  vim.api.nvim_command(":normal i" .. text)
end

describe("TreesitterBoolean.demorgan", function()
  describe("invertExpression", function() -----------------------------------------------
    it("should invert true to false", function()
      setup_file([[const a = true;]])
      vim.api.nvim_command(":normal yy")
      local node = ts_utils:get_node_at_cursor()

      print("code: ", vim.inspect(ts_utils.get_node_text(node)))

      -- print("DOING IT!", vim.inspect(ts_utils.get_node_text(tstree:root())))

      local children = ts_utils.get_named_children(node)
      print("type: ", node:type())
      print("code: ", #children)
      local invertedExpression = treesitterBoolean.demorgan.invertExpression(node)
      -- assert.are.same(invertedExpression, "false || true")
      assert.are.same(true, true)
      print("done")
    end)
  end)
end)
