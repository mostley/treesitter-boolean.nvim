# treesitter-boolean.nvim

Library containing useful utils for boolean refactoring based on treesitter

# Installation

**Using Packer**
```lua
use {
  "mostley/treesitter-boolean",
  requires = { "nvim-treesitter/nvim-treesitter" }
}
```

# Usage

### :lua require('treesitter-boolean').DeMorgan.invertExpression(<expr>) -> <expr>

Inverts the given expression.

# Execute test suite

    make test
