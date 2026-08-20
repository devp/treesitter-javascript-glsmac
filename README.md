# tree-sitter-javascript-glsmac

Fork of [tree-sitter-javascript](https://github.com/tree-sitter/tree-sitter-javascript)
for **GSE** (`.gls.js`), [GLSMAC](https://github.com/devp/glsmac)'s embedded
script language. GSE is JS-*shaped* but not JS — this fork adds the handful
of real grammar constructs JS doesn't have. See
[glsmac-contrib/editor/neovim](https://github.com/devp/glsmac-contrib/tree/main/editor/neovim)
for how this gets wired into an editor.

Language name is `gls_js`, not `javascript` — deliberate, so the built
parser (`gls_js.so`, exported symbol `tree_sitter_gls_js`) can sit on a
runtime path next to the real JS/TS parser without colliding.

## What's forked and why

Each grammar addition is its own commit with the rationale (and the
`glsmac` source citation it's based on) in the commit body — `git log` is
the actual changelog, this is just the summary:

| construct | example | GSE source |
|---|---|---|
| `#builtin(...)` call target | `#uppercase(x)`, `#main(fn)` | `src/gse/parser/JS.h:98-109`, `src/gse/context/Context.cpp:123` |
| `#builtin` as assignment/declaration target | `let #builtin = 5;` | `src/gse/parser/JS.cpp` (GetObject path) |
| `:+` push, `:-` erase | `arr :+ x` | `src/gse/parser/JS.h:340,348` |
| `:~` pop (postfix, no right operand) | `arr :~` | `src/gse/parser/JS.h:344` |
| `::` range (either side optional) | `arr[2::5]`, `arr[::3]`, `arr[::]` | `src/gse/parser/JS.h:352` |
| catch body is a handler-map object, not a statement block | `catch { TypeName: (e) => {...}, : (e) => {...} }` | `src/gse/parser/JS.cpp:493` (`GetObject`) |

All citations are `glsmac` repo paths — clone it alongside this repo to
check them (`GLSMAC` Makefile var, defaults to `../glsmac`).

## Known gaps

`GLSMAC_data/tests/exceptions.gls.js` has 6 remaining `ERROR` nodes,
deliberately: it's a test fixture for the interpreter's runtime error
paths (`1 = 5`, `'asd'++`, `(a, b) => {} = 5`). GSE's parser doesn't
restrict assignment-LHS shape at parse time at all — any expression is
syntactically legal there, validity is a runtime `GSEInvalidAssignment`.
Matching that means loosening `_lhs_expression` to arbitrary
`$.expression`, real ambiguity risk (`a + b = 5`?) for zero benefit to
real authored code (every file under `GLSMAC_data/default/` — the actual
game content — parses with zero `ERROR` nodes). Left as-is; `make verify`
will (correctly) fail on this file until/unless that changes.

## Build

```sh
make build              # gls_js.so
make verify GLSMAC=../glsmac   # acceptance check against real .gls.js files
make install                    # copy .so + queries to ~/.local/share/nvim
```

See `Makefile` for targets and overridable vars (`GLSMAC`, `NVIM_DATA`).

## Updating from upstream

`master` tracks upstream `tree-sitter/tree-sitter-javascript` unmodified.
The fork commits live on `glsmac` (this repo's default branch). To pull
upstream changes:

```sh
git fetch origin master
git checkout glsmac
git rebase origin/master
make verify GLSMAC=../glsmac
```
