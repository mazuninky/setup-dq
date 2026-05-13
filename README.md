# setup-dq

GitHub Action that installs [`dq`](https://github.com/mazuninky/dq) — the agent-friendly Rust CLI for structured data and the linter platform — on a workflow runner and adds it to `PATH`.

## Usage

```yaml
- uses: mazuninky/setup-dq@v1
  with:
    version: latest          # or a specific version like "2026.20.1"

- run: dq --version
- run: dq lint 'k8s/**/*.yaml' -F sarif
```

Pin to a specific version for reproducible builds:

```yaml
- uses: mazuninky/setup-dq@v1
  with:
    version: 2026.20.1
```

## Inputs

| Name      | Required | Default          | Description |
|-----------|----------|------------------|-------------|
| `version` | no       | `latest`         | Calendar version (`2026.20.1`), tag (`v2026.20.1`), or `latest`. |
| `token`   | no       | `${{ github.token }}` | Token used to query the GitHub API and download release assets. |

## Outputs

| Name       | Description |
|------------|-------------|
| `version`  | Resolved version that was installed (e.g. `2026.20.1`). |
| `bin-path` | Absolute path to the directory containing the `dq` binary. |

## Supported runners

| OS              | Arch   | Notes |
|-----------------|--------|-------|
| `ubuntu-*`      | x86_64 | `x86_64-unknown-linux-gnu` |
| `ubuntu-*`      | arm64  | `aarch64-unknown-linux-gnu` |
| `macos-*`       | arm64  | `aarch64-apple-darwin` (M1+) |

`dq` does not currently ship macOS x86_64 or Windows builds, so the action will fail fast on those runners. For Windows or containerised workflows, use the published OCI image at `ghcr.io/mazuninky/dq` instead.

## How it works

The action is a thin composite wrapper:

1. Resolves the version (queries `releases/latest` if `version: latest`).
2. Detects the runner OS/arch and picks the matching release asset.
3. Downloads the `tar.gz` and verifies its SHA256 sidecar.
4. Extracts the binary into `$RUNNER_TOOL_CACHE/dq/<version>/<target>/`.
5. Appends that directory to `$GITHUB_PATH`.

No build step, no Node dependencies — just bash.

## License

MIT.
