#!/usr/bin/env bash
# Sync selected Hagezi DoH/VPN/proxy bypass lists and append dnsbunker.org.
#
# Writes through a staging directory so a failed fetch never leaves a half-updated
# working tree. Append is idempotent (exact line match, case-insensitive).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_BASE="${UPSTREAM_BASE:-https://raw.githubusercontent.com/hagezi/dns-blocklists/main}"
DOMAIN="dnsbunker.org"
CURL_OPTS=( -fsSL --retry 3 --retry-delay 2 --connect-timeout 15 --max-time 120 )

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

STAGE=""
cleanup() {
  if [[ -n "${STAGE}" && -d "${STAGE}" ]]; then
    rm -rf "${STAGE}"
  fi
}
trap cleanup EXIT

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

# Required marker line(s) for a format (one per line).
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
    adblock) printf '%s\n' "! Local append: dnsbunker.org (complete-doh-vpn-proxy-bypass-blocklist)" ;;
    rpz) printf '%s\n' "; Local append: dnsbunker.org (complete-doh-vpn-proxy-bypass-blocklist)" ;;
    *) printf '%s\n' "# Local append: dnsbunker.org (complete-doh-vpn-proxy-bypass-blocklist)" ;;
  esac
}

# Exact whole-line match, case-insensitive (fixed string).
line_present() {
  local file="$1"
  local needle="$2"
  grep -Fixq -- "$needle" "$file"
}

# Strip trailing blank lines; ensure exactly one final newline.
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

# Bump every "Number of entries: N" header field by $delta (keeps upstream style).
bump_entry_count() {
  local file="$1"
  local delta="$2"
  local tmp

  if [[ "$delta" -le 0 ]]; then
    return 0
  fi
  if ! grep -Eq 'Number of entries:[[:space:]]*[0-9]+' "$file"; then
    return 0
  fi

  tmp="$(mktemp "${STAGE}/bump.XXXXXX")"
  awk -v d="$delta" '
    {
      if (match($0, /Number of entries:[[:space:]]*[0-9]+/)) {
        line = $0
        if (match(line, /[0-9]+$/)) {
          # Prefer the number after the label anywhere on the line.
        }
        if (match(line, /Number of entries:[[:space:]]*[0-9]+/)) {
          prefix = substr(line, 1, RSTART - 1)
          matched = substr(line, RSTART, RLENGTH)
          suffix = substr(line, RSTART + RLENGTH)
          if (match(matched, /[0-9]+$/)) {
            n = substr(matched, RSTART, RLENGTH) + d
            label = substr(matched, 1, RSTART - 1)
            print prefix label n suffix
            next
          }
        }
      }
      print
    }
  ' "$file" >"$tmp"
  mv "$tmp" "$file"
}

append_missing() {
  local file="$1"
  local format="$2"
  local marker
  local missing=()
  local comment
  local added=0

  while IFS= read -r marker; do
    [[ -z "$marker" ]] && continue
    if ! line_present "$file" "$marker"; then
      missing+=("$marker")
    fi
  done < <(markers_for "$format")

  if [[ ${#missing[@]} -eq 0 ]]; then
    echo 0
    return 0
  fi

  comment="$(local_comment_for "$format" | tr -d '\n')"
  if ! grep -Fiq "Local append: dnsbunker.org" "$file" 2>/dev/null; then
    printf '%s\n' "$comment" >>"$file"
  fi

  for marker in "${missing[@]}"; do
    printf '%s\n' "$marker" >>"$file"
    added=$((added + 1))
  done

  bump_entry_count "$file" "$added"
  echo "$added"
}

fetch_and_transform() {
  local rel="$1"
  local stage_root="$2"
  local format
  local url="${UPSTREAM_BASE}/${rel}"
  local dest="${stage_root}/${rel}"
  local raw
  local tmp
  local added

  format="$(list_format "$rel")"
  mkdir -p "$(dirname "$dest")"
  raw="$(mktemp "${STAGE}/raw.XXXXXX")"
  tmp="$(mktemp "${STAGE}/norm.XXXXXX")"

  echo "Fetching ${rel} ..."
  if ! curl "${CURL_OPTS[@]}" -o "$raw" "$url"; then
    echo "error: failed to fetch ${url}" >&2
    return 1
  fi

  if [[ ! -s "$raw" ]]; then
    echo "error: empty response for ${url}" >&2
    return 1
  fi

  # Reject accidental HTML error pages from a bad CDN/proxy response.
  if head -c 200 "$raw" | grep -qiE '<(!DOCTYPE|html)[[:space:]>]'; then
    echo "error: response for ${url} looks like HTML, not a list" >&2
    return 1
  fi

  normalize_to "$tmp" <"$raw"
  added="$(append_missing "$tmp" "$format")"
  mv "$tmp" "$dest"
  echo "Wrote ${rel} (appended ${added} marker(s) onto upstream)"
}

promote_stage() {
  local stage_root="$1"
  local rel
  local dest
  local src

  for rel in "${FILES[@]}"; do
    src="${stage_root}/${rel}"
    dest="${ROOT}/${rel}"
    if [[ ! -f "$src" ]]; then
      echo "error: staged file missing: ${rel}" >&2
      return 1
    fi
    mkdir -p "$(dirname "$dest")"
    mv "$src" "$dest"
  done
}

main() {
  local rel

  STAGE="$(mktemp -d "${TMPDIR:-/tmp}/hagezi-sync.XXXXXX")"
  mkdir -p "${STAGE}/out"

  for rel in "${FILES[@]}"; do
    fetch_and_transform "$rel" "${STAGE}/out"
  done

  promote_stage "${STAGE}/out"
  echo "Sync complete (${#FILES[@]} files)."
}

main "$@"
