# Strand issues

Problems found while building this shell that look like Strand's to fix. They're parked here and get
fixed in Strand later. Newest first.

## Checking an issue

Each issue has a folder under `strand-issues/` with its own config and a check that reads the result
from a screenshot. It runs in Strand's CI container on a headless sway, never on a desktop session, and
needs nothing from this machine's config.

```sh
cd ~/projects/strand
scripts/container/run.sh cargo build -p strand
~/.local/share/chezmoi/docs/strand-shell/strand-issues/verify.sh ~/.local/share/chezmoi/docs/strand-shell/strand-issues/<issue-folder> ~/projects/strand
```

| Exit | Meaning |
| --- | --- |
| 0 | Fixed |
| 1 | The issue is still there |
| 2 | The check itself could not run, or a control failed. Says nothing about the issue |

It prints the checkout's commit and when the binary was built, since nothing ties the two together:
build first, as above. Its working files go in the checkout's `target/issue-repro/`.

A new issue needs a folder with `strand/`, `home/` (the check's `$HOME`) and `check.py`, plus controls
where they can show the check is working.

## Open

None.

Fixed issues and their repro folders are in git history (the last went with the cleanup of 2026-11-07).
