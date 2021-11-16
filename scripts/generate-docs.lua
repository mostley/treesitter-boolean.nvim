docgen = require("babelfish")
local metadata = {
  input_file = "README.md",
  output_file = "doc/treesitter-boolean.txt",
  project_name = "treesitter-boolean",
}
docgen.generate_readme(metadata)
