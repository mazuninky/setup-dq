#!/usr/bin/env bash
# install.sh — resolve, download, verify, and install the dq CLI.
#
# Inputs (env):
#   INPUT_VERSION       — "latest" or a calendar version (with or without "v" prefix)
#   GH_TOKEN            — token for the GitHub API
#   RUNNER_OS_INPUT     — Linux | macOS | Windows (from ${{ runner.os }})
#   RUNNER_ARCH_INPUT   — X64 | ARM64 (from ${{ runner.arch }})
#
# Sets on success:
#   $GITHUB_PATH        — appends install dir
#   $GITHUB_OUTPUT      — version=..., bin-path=...

set -euo pipefail

REPO="mazuninky/dq"

log() { printf '::group::%s\n' "$1"; }
end() { printf '::endgroup::\n'; }
err() { printf '::error::%s\n' "$1" >&2; }

# -- Resolve version --------------------------------------------------------

log "Resolving dq version"
if [[ "${INPUT_VERSION}" == "latest" ]]; then
    if ! TAG=$(gh api "repos/${REPO}/releases/latest" --jq '.tag_name' 2>&1); then
        err "Failed to resolve latest release of ${REPO}: ${TAG}"
        exit 1
    fi
else
    # Accept "2026.20.1" or "v2026.20.1"; normalize to v-prefixed tag.
    TAG="v${INPUT_VERSION#v}"
fi
VERSION="${TAG#v}"
if ! printf '%s' "${VERSION}" | grep -Eq '^[0-9]{4}\.(0[1-9]|[1-4][0-9]|5[0-3])\.[1-9][0-9]*$'; then
    err "Version '${INPUT_VERSION}' (resolved to '${VERSION}') is not in YYYY.WW.BUILD format"
    exit 1
fi
echo "Resolved: ${TAG}"
end

# -- Detect platform --------------------------------------------------------

log "Detecting platform"
case "${RUNNER_OS_INPUT}-${RUNNER_ARCH_INPUT}" in
    Linux-X64)
        TARGET="x86_64-unknown-linux-gnu"
        ;;
    Linux-ARM64)
        TARGET="aarch64-unknown-linux-gnu"
        ;;
    macOS-ARM64)
        TARGET="aarch64-apple-darwin"
        ;;
    *)
        err "Unsupported runner platform: ${RUNNER_OS_INPUT}/${RUNNER_ARCH_INPUT}. dq ships builds for Linux x64, Linux arm64, and macOS arm64."
        exit 1
        ;;
esac
ARCHIVE_EXT="tar.gz"
BIN="dq"
echo "Target: ${TARGET}"
end

# -- Download and verify ----------------------------------------------------

ASSET="dq-${VERSION}-${TARGET}.${ARCHIVE_EXT}"
ASSET_URL="https://github.com/${REPO}/releases/download/${TAG}/${ASSET}"
SHA_URL="${ASSET_URL}.sha256"

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

log "Downloading ${ASSET}"
curl --fail --silent --show-error --location \
    --header "Authorization: Bearer ${GH_TOKEN}" \
    --header "Accept: application/octet-stream" \
    --output "${TMP}/${ASSET}" \
    "${ASSET_URL}"
curl --fail --silent --show-error --location \
    --header "Authorization: Bearer ${GH_TOKEN}" \
    --header "Accept: application/octet-stream" \
    --output "${TMP}/${ASSET}.sha256" \
    "${SHA_URL}"
end

log "Verifying checksum"
EXPECTED=$(awk '{print $1}' "${TMP}/${ASSET}.sha256")
if command -v sha256sum >/dev/null 2>&1; then
    ACTUAL=$(sha256sum "${TMP}/${ASSET}" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
    ACTUAL=$(shasum -a 256 "${TMP}/${ASSET}" | awk '{print $1}')
else
    err "Neither sha256sum nor shasum is available on this runner"
    exit 1
fi
if [[ "${EXPECTED}" != "${ACTUAL}" ]]; then
    err "Checksum mismatch for ${ASSET}: expected ${EXPECTED}, got ${ACTUAL}"
    exit 1
fi
echo "OK: ${ACTUAL}"
end

# -- Extract and install ----------------------------------------------------

log "Installing"
TOOL_CACHE_ROOT="${RUNNER_TOOL_CACHE:-${HOME}/.tool-cache}"
INSTALL_DIR="${TOOL_CACHE_ROOT}/dq/${VERSION}/${TARGET}"
mkdir -p "${INSTALL_DIR}"

EXTRACT_DIR="${TMP}/extract"
mkdir -p "${EXTRACT_DIR}"

tar -xzf "${TMP}/${ASSET}" -C "${EXTRACT_DIR}"

SRC="${EXTRACT_DIR}/dq-${VERSION}-${TARGET}/${BIN}"
if [[ ! -f "${SRC}" ]]; then
    err "Expected binary not found in archive: ${SRC}"
    exit 1
fi
cp "${SRC}" "${INSTALL_DIR}/${BIN}"
chmod +x "${INSTALL_DIR}/${BIN}"
echo "Installed to ${INSTALL_DIR}/${BIN}"
end

# -- Wire up PATH and outputs ----------------------------------------------

echo "${INSTALL_DIR}" >> "${GITHUB_PATH}"
{
    printf 'version=%s\n' "${VERSION}"
    printf 'bin-path=%s\n' "${INSTALL_DIR}"
} >> "${GITHUB_OUTPUT}"

log "Smoke test"
"${INSTALL_DIR}/${BIN}" --version
end
