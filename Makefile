# treesitter-javascript-glsmac
#
# Fork of tree-sitter-javascript for GSE (.gls.js, GLSMAC's embedded
# script language). See README.md for what's forked and why; each
# grammar change is its own commit with rationale in the commit body,
# git log is the actual changelog.
#
# GLSMAC ?= path to a glsmac checkout, needed only by `verify`.
GLSMAC ?= ../glsmac

# Where a local neovim install looks for parsers/queries (core
# vim.treesitter, not nvim-treesitter's registry -- see
# glsmac-contrib/editor/neovim).
NVIM_DATA ?= $(HOME)/.local/share/nvim

.PHONY: all deps generate build verify install clean

all: build

deps: node_modules

node_modules: package.json
	npm install

generate: deps
	tree-sitter generate

build: generate
	tree-sitter build -o gls_js.so

# Acceptance check: parse every real .gls.js file in $(GLSMAC), fail if
# any ERROR node remains. This is the actual bar, not "it compiles."
verify: build
	@if [ ! -d "$(GLSMAC)/GLSMAC_data" ]; then \
		echo "GLSMAC_data not found under GLSMAC=$(GLSMAC) -- pass GLSMAC=<path-to-glsmac-checkout>"; \
		exit 1; \
	fi
	@errors="$$(find "$(GLSMAC)/GLSMAC_data" -name '*.gls.js' -print0 \
		| xargs -0 tree-sitter parse | grep ERROR || true)"; \
	if [ -n "$$errors" ]; then \
		echo "$$errors"; \
		echo; \
		echo "ERROR nodes found -- see README.md#known-gaps before assuming this is a regression."; \
		exit 1; \
	fi; \
	echo "clean: no ERROR nodes in $(GLSMAC)/GLSMAC_data"

install: build
	mkdir -p "$(NVIM_DATA)/parser" "$(NVIM_DATA)/queries/gls_js"
	cp gls_js.so "$(NVIM_DATA)/parser/gls_js.so"
	cp queries/highlights.scm "$(NVIM_DATA)/queries/gls_js/highlights.scm"
	@echo "installed to $(NVIM_DATA)/parser/gls_js.so and $(NVIM_DATA)/queries/gls_js/"

clean:
	rm -rf gls_js.so src/parser.c node_modules
