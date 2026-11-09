# Strand for Zed

A Zed extension for `.strand` files: highlighting, brackets, indents and
the outline from Strand's tree-sitter grammar, and `strand-dev lsp`
(diagnostics, completion, hover, go to definition, rename, code actions,
formatting).

Install it once: in Zed, run `zed: install dev extension` and pick
`~/.local/share/zed-strand`. Zed builds it with rustup's Rust (adding the
`wasm32-wasip2` target) and fetches the grammar from GitHub at the `rev`
in `extension.toml`. `strand-dev` must be on PATH; install.sh puts it in
`~/.local/bin`.

When Strand's grammar changes, set `rev` to the new commit, copy the
changed patterns of `queries/highlights.scm` into
`languages/strand/highlights.scm` (keeping its order: general patterns
first, since Zed lets the later pattern win), and rebuild the extension
from Zed's extensions page.
