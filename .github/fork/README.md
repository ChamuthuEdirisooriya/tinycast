# Tinycast Plus

This branch is upstream Tinycast plus a **Move pasted items to the top** setting (Settings →
Clipboard). It builds as **Tinycast Plus** (`com.tinycast.app.plus`), which installs beside upstream
Tinycast, keeps its own settings and history, and updates only from this fork's releases.

## How it stays current

[`fork.yml`](../workflows/fork.yml) runs daily. When upstream publishes a new stable release
`vX.Y.Z`, it merges that release into this branch, runs lint, the Model purity check and the test
harnesses (failing only on a harness that passes on upstream), builds a signed Release app and
publishes it here as release `X.Y.Z`. The installed app finds it on its daily update check.

A merge conflict or a new test failure stops the run before anything is pushed or published, and
GitHub emails the failure. Resolve it on this branch, push, then use **Run workflow**.

## One-time setup

- This branch is the repository's default branch, so the daily and manual runs exist.
- Secrets `FORK_SIGNING_P12_BASE64` and `FORK_SIGNING_P12_PASSWORD` hold the `Tinycast Fork
  Signing` certificate. Every release must carry the same one: the updater installs a build only
  when its certificate is byte-identical to the running app's.
- Optional `FORK_PUSH_TOKEN`: a fine-grained token with Contents and Workflows write on this fork.
  Without it, a merge that changes upstream's own `.github/workflows` files cannot be pushed.
