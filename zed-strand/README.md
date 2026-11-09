# Strand for Zed

A Zed extension for `.strand` files: highlighting, brackets, indents and
the outline from Strand's tree-sitter grammar, and `strand-dev lsp`
(diagnostics, completion, hover, go to definition, rename, code actions,
formatting). `strand-dev` must be on PATH; Strand's install.sh puts it in
`~/.local/bin`.

`chezmoi apply` installs it: `run_onchange_after_install-zed-strand.sh.tmpl`
builds it as Zed's own builder would and puts it in
`~/.local/share/zed/extensions/installed/strand`, and runs again when a
file here changes. It builds in `~/.cache/zed-strand` (wasi-sdk's clang
for the grammar) and removes that when it is done.

When Strand's grammar changes, set `rev` in `extension.toml` to the new
commit and copy the changed patterns of the grammar's
`queries/highlights.scm` into `languages/strand/highlights.scm`, keeping
its order: general patterns first, since Zed lets the later pattern win.
