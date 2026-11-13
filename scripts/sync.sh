#!/usr/bin/env bash
# Sync selected Hagezi DoH/VPN/proxy bypass lists and append dnsbunker.org.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_BASE="${UPSTREAM_BASE:-https://raw.githubusercontent.com/hagezi/dns-blocklists/main}"
DOMAIN="dnsbunker.org"

FILES=(
  "adblock/doh-vpn-proxy-bypass.txt"
  "adblock/doh.top.txt"
  "adblock/doh.txt"
  "dnsmasq/doh-vpn-proxy-bypass.txt"
  "dnsmasq/doh.txt"
  "wildcard/doh-onlydomains.txt"
  "wildcard/doh-vpn-proxy-bypass-onlydomains.txt"
  "wildcard/doh-vpn-proxy-bypass.txt"
  "wildcard/doh.txt"
  "rpz/doh-vpn-proxy-bypass.txt"
  "rpz/doh.txt"
)

list_format() {
  local path="$1"
  case "$path" in
    adblock/*) echo "adblock" ;;
    dnsmasq/*) echo "dnsmasq" ;;
    wildcard/*-onlydomains.txt) echo "onlydomains" ;;
    wildcard/*) echo "wildcard" ;;
    rpz/*) echo "rpz" ;;
    *)
      echo "error: unknown format for path: $path" >&2
      return 1
      ;;
  esac
}

# Print required marker line(s) for a format (one per line).
markers_for() {
  local format="$1"
  case "$format" in
    adblock) printf '%s\n' "||${DOMAIN}^" ;;
    dnsmasq) printf '%s\n' "local=/${DOMAIN}/" ;;
    wildcard) printf '%s\n' "*.${DOMAIN}" ;;
    onlydomains) printf '%s\n' "${DOMAIN}" ;;
    rpz)
      printf '%s\n' "${DOMAIN} CNAME ."
      printf '%s\n' "*.${DOMAIN} CNAME ."
      ;;
  esac
}

local_comment_for() {
  local format="$1"
  case "$format" in
    adblock) printf '%s\n' "! Local append: dnsbunker.org (dnsbunker mirror)" ;;
    rpz) printf '%s\n' "; Local append: dnsbunker.org (dnsbunker mirror)" ;;
    *) printf '%s\n' "# Local append: dnsbunker.org (dnsbunker mirror)" ;;
  esac
}

line_present() {
  local file="$1"
  local needle="$2"
  grep -Fixq -- "$needle" "$file"
}

# Write stdin to $1 with trailing blank lines stripped and exactly one final newline.
normalize_to() {
  local dest="$1"
  awk '
    { lines[NR] = $0 }
    END {
      end = NR
      while (end > 0 && lines[end] ~ /^[[:space:]]*$/) end--
      for (i = 1; i <= end; i++) print lines[i]
    }
  ' >"$dest"
}

append_missing() {
  local file="$1"
  local format="$2"
  local marker
  local missing=()
  local comment

  while IFS= read -r marker; do
    [[ -z "$marker" ]] && continue
    if ! line_present "$file" "$marker"; then
      missing+=("$marker")
    fi
  done < <(markers_for "$format")

  if [[ ${#missing[@]} -eq 0 ]]; then
    return 0
  fi

  comment="$(local_comment_for "$format" | tr -d '\n')"
  if ! grep -Fq "Local append: dnsbunker.org" "$file" 2>/dev/null; then
    printf '%s\n' "$comment" >>"$file"
  fi

  for marker in "${missing[@]}"; do
    printf '%s\n' "$marker" >>"$file"
  done
}

fetch_and_transform() {
  local rel="$1"
  local format
  local url="${UPSTREAM_BASE}/${rel}"
  local dest="${ROOT}/${rel}"
  local tmp raw

  format="$(list_format "$rel")"
  mkdir -p "$(dirname "$dest")"
  raw="$(mktemp)"
  tmp="$(mktemp)"

  echo "Fetching ${rel} ..."
  if ! curl -fsSL --retry 3 --retry-delay 2 -o "$raw" "$url"; then
    rm -f "$raw" "$tmp"
    echo "error: failed to fetch ${url}" >&2
    return 1
  fi

  if [[ ! -s "$raw" ]]; then
    rm -f "$raw" "$tmp"
    echo "error: empty response for ${url}" >&2
    return 1
  fi

  normalize_to "$tmp" <"$raw"
  rm -f "$raw"

  append_missing "$tmp" "$format"
  mv "$tmp" "$dest"
  echo "Wrote ${rel}"
}

main() {
  local rel
  local failed=0

  for rel in "${FILES[@]}"; do
    if ! fetch_and_transform "$rel"; then
      failed=1
    fi
  done

  if [[ "$failed" -ne 0 ]]; then
    echo "error: one or more lists failed to sync" >&2
    exit 1
  fi

  echo "Sync complete."
}

main "$@"
