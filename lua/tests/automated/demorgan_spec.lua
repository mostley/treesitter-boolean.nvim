local treesitterBoolean = require("treesitter-boolean")

describe("TreesitterBoolean.demorgan", function()
  describe("invertExpression", function() -----------------------------------------------
    it("should print", function()
      treesitterBoolean.demorgan.invertExpression()
      assert.are.same("test", "test")
    end)
  end)
end)
