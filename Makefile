export PJ_ROOT=$(PWD)

FILTER=.*

INIT_LUAROCKS := eval $$(luarocks --lua-version=5.1 path) &&

.DEFAULT_GOAL := build

NEOVIM_BRANCH := master

deps/neovim:
	@mkdir -p deps
	git clone --depth 1 https://github.com/neovim/neovim --branch $(NEOVIM_BRANCH) $@
	make -C $@

deps/plenary.nvim:
	@mkdir -p deps
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim $@

deps/treesitter.nvim:
	@mkdir -p deps
	git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter $@

export VIMRUNTIME=$(PWD)/deps/neovim/runtime
export TEST_COLORS=1

test:
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory lua/tests/automated/ { minimal_init = './scripts/minimal_init.vim' }"

