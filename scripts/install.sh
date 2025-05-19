#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd -P)/.."

CURL_IMPERSONATE_VERSION="1.0.0"

# no action required if binding exists
if [[ -f lib/binding/node_libcurl_ja3.node ]]; then
  exit
fi

CURL_IMPERSONATE_DIR="$(dirname "$PWD")/deps/curl-impersonate"
BUILD_DIR="$CURL_IMPERSONATE_DIR/build/curl-impersonate"

# Determine OS-specific variables
if [ "$OS" = "Linux" ]; then
  MAKE="make"
  HOST="x86_64-linux-gnu"
  CPP_LIB="stdc++"
elif [ "$OS" = "Darwin" ]; then
  MAKE="gmake"
  HOST="arm64-apple-darwin"
  CPP_LIB="c++"
else
  echo "Unsupported operating system: $OS"
  exit 1
fi

fetch_curl_impersonate_build() {
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    curl -LO "https://github.com/lexiforest/curl-impersonate/releases/download/v${CURL_IMPERSONATE_VERSION}/libcurl-impersonate-v${CURL_IMPERSONATE_VERSION}.${HOST}.tar.gz"
    curl -LO "https://github.com/lexiforest/curl-impersonate/releases/download/v${CURL_IMPERSONATE_VERSION}/curl-impersonate-v${CURL_IMPERSONATE_VERSION}.${HOST}.tar.gz"
    tar xf "libcurl-impersonate-v${CURL_IMPERSONATE_VERSION}.${HOST}.tar.gz" -C lib
    tar xf "curl-impersonate-v${CURL_IMPERSONATE_VERSION}.${HOST}.tar.gz" -C bin
    mv 
}

fetch_curl_impersonate_source() {
  if [[ -f deps/curl-impersonate/configure ]]; then
    return
  fi
  if [[ -d .git ]] && [[ -f .gitmodules ]]; then
    git submodule update --init --recursive
  else
    [[ -d deps ]] || mkdir deps
    cd deps
    curl -LO "https://github.com/lexiforest/curl-impersonate/archive/refs/tags/v${CURL_IMPERSONATE_VERSION}.tar.gz"
    tar xf "v${CURL_IMPERSONATE_VERSION}.tar.gz"
    mv "curl-impersonate-${CURL_IMPERSONATE_VERSION}" curl-impersonate
    rm -f "v${CURL_IMPERSONATE_VERSION}.tar.gz"
    cd - >/dev/null
  fi
}

build_curl_impersonate() {
  if [[ -f deps/curl-impersonate/build/lib/libcurl-impersonate-chrome.a ]]; then
    return
  fi
  scripts/build.sh
}

install_from_source() {
  fetch_curl_impersonate_build
  # build_curl_impersonate
  npx node-pre-gyp rebuild
}

if [[ "${npm_config_build_from_source:-}" == "true" ]] \
    || ! npx node-pre-gyp install \
; then
  # fallback to build from source if node-pre-gyp install fails
  install_from_source
fi
