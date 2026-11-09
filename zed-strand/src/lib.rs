//! Starts `strand-dev lsp` for `.strand` files.
//!
//! The server is `strand-dev` on the PATH Zed's shell sees (install.sh links
//! it into ~/.local/bin). Settings can point elsewhere or pass the server's
//! initialization options:
//!
//! "lsp": { "strand-dev": {
//!   "binary": { "path": "/path/to/strand-dev", "arguments": ["lsp"] },
//!   "initialization_options": { "debounceMs": 200, "configDir": "..." }
//! } }

use zed_extension_api::{self as zed, settings::LspSettings, LanguageServerId, Result};

struct Strand;

impl zed::Extension for Strand {
    fn new() -> Self {
        Strand
    }

    fn language_server_command(
        &mut self,
        id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        let binary = LspSettings::for_worktree(id.as_ref(), worktree)
            .ok()
            .and_then(|s| s.binary);
        let args = binary
            .as_ref()
            .and_then(|b| b.arguments.clone())
            .unwrap_or_else(|| vec!["lsp".into()]);
        let command = match binary.and_then(|b| b.path) {
            Some(path) => path,
            None => worktree.which("strand-dev").ok_or_else(|| {
                "strand-dev is not on PATH: install Strand (install.sh links it into ~/.local/bin)"
                    .to_string()
            })?,
        };
        Ok(zed::Command {
            command,
            args,
            env: worktree.shell_env(),
        })
    }

    fn language_server_initialization_options(
        &mut self,
        id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<zed::serde_json::Value>> {
        Ok(LspSettings::for_worktree(id.as_ref(), worktree)
            .ok()
            .and_then(|s| s.initialization_options))
    }
}

zed::register_extension!(Strand);
