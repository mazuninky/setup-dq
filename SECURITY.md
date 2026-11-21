# Security Policy

## Reporting a vulnerability

Please do not open a public issue or pull request for a security report. Report it privately
through [GitHub Security Advisories](https://github.com/mazuninky/setup-dq/security/advisories/new):
only the maintainer sees it.

Include what goes wrong, how to reproduce it (a workflow snippet is ideal), and the version of the
action you use (`@v1`, `@v1.1.0` or a commit SHA). You should get an acknowledgement within a few
days. The fix is released as a new version, `v1` moves to it, and the advisory is published after
that.

## Scope

setup-dq downloads a dq release archive from
[GitHub Releases](https://github.com/mazuninky/dq/releases), checks it against the `.sha256` file
published next to it, and puts the binary on `PATH`. In scope:

- anything that makes it install a binary other than the one in the release;
- a way to skip or weaken the checksum check;
- an input (`version`, `token`) that leads to code execution or leaks the token.

The checksum comes from the same release as the archive. It catches a corrupted or swapped
download, not a compromised release. Vulnerabilities in dq itself go to
[its security policy](https://github.com/mazuninky/dq/security/policy).
