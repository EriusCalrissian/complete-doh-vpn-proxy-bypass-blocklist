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

REPO_URL="https://github.com/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist"
UPSTREAM_URL="https://github.com/hagezi/dns-blocklists"
NOW="$(LC_ALL=C date -u '+%d %b %Y %H:%M UTC')"

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

comment_prefix_for() {
  local format="$1"
  case "$format" in
    adblock) printf '%s' "!" ;;
    rpz) printf '%s' ";" ;;
    *) printf '%s' "#" ;;
  esac
}

# Prints title and description (one per line) for a list path.
header_text_for() {
  local name
  name="$(basename "$1" .txt)"
  case "$name" in
    doh-vpn-proxy-bypass|doh-vpn-proxy-bypass-onlydomains)
      printf '%s\n' "Complete DoH/VPN/Tor/Proxy Bypass Blocklist - incl. dnsbunker.org"
      printf '%s\n' "Blocks encrypted DNS, VPN, Tor and proxy domains used to bypass your DNS. HaGeZi's DoH/VPN/Tor/Proxy Bypass list plus dnsbunker.org."
      ;;
    doh|doh-onlydomains)
      printf '%s\n' "Complete Encrypted DNS Bypass Blocklist - incl. dnsbunker.org"
      printf '%s\n' "Blocks encrypted DNS servers used to bypass your DNS. HaGeZi's Encrypted DNS Bypass list plus dnsbunker.org."
      ;;
    doh.top)
      printf '%s\n' "Complete Encrypted DNS Bypass Blocklist (Top 1M) - incl. dnsbunker.org"
      printf '%s\n' "Blocks encrypted DNS servers used to bypass your DNS, only domains on various Top 1M lists. HaGeZi's Encrypted DNS Bypass Top 1M list plus dnsbunker.org."
      ;;
    *)
      echo "error: no header text for path: $1" >&2
      return 1
      ;;
  esac
}

# Replace upstream identity fields with this repo's; keep upstream date in "Last modified".
rewrite_header() {
  local file="$1"
  local rel="$2"
  local format="$3"
  local prefix
  local title
  local desc
  local tmp

  prefix="$(comment_prefix_for "$format")"
  { read -r title; read -r desc; } < <(header_text_for "$rel")
  tmp="$(mktemp "${STAGE}/header.XXXXXX")"

  awk \
    -v p="$prefix" \
    -v title="$title" \
    -v desc="$desc" \
    -v note="Use only with your own DNS enforced: redirect standard DNS outbound (TCP/UDP 53) to an internal server and block DoT/DoQ (TCP/UDP 853) outbound. Do not load lists hosted on dnsbunker.org together with this list." \
    -v home="${REPO_URL}" \
    -v src="${UPSTREAM_URL} (HaGeZi), modified" \
    -v lic="${REPO_URL}/blob/main/LICENSE" \
    -v issues="${REPO_URL}/issues" \
    -v disc="${REPO_URL}/blob/main/README.md#disclaimer" \
    -v now="${NOW}" '
    NR <= 30 && index($0, p " ") == 1 {
      rest = substr($0, length(p) + 2)
      if (rest ~ /^Title:/)       { print p " Title: " title; next }
      if (rest ~ /^Description:/) { print p " Description: " desc; next }
      if (rest ~ /^Note:/)        { print p " Note: " note; next }
      if (rest ~ /^Homepage:/)    { print p " Homepage: " home; print p " Source: " src; next }
      if (rest ~ /^License:/)     { print p " License: " lic; next }
      if (rest ~ /^Issues:/)      { print p " Issues: " issues; next }
      if (rest ~ /^Disclaimer:/)  { print p " Disclaimer: " disc; next }
      if (rest ~ /^Last modified:/) {
        orig = rest
        sub(/^Last modified:[[:space:]]*/, "", orig)
        print p " Last modified: " now " (" orig ")"
        next
      }
    }
    { print }
  ' "$file" >"$tmp"
  mv "$tmp" "$file"
}

# Files equal apart from the "Last modified" header line.
same_except_modified() {
  local a="$1"
  local b="$2"
  local re='^[!#;] Last modified:'
  cmp -s <(grep -Ev "$re" "$a") <(grep -Ev "$re" "$b")
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
  rewrite_header "$tmp" "$rel" "$format"
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
    # Keep the previous "Last modified" when nothing else changed (no timestamp-only commits).
    if [[ -f "$dest" ]] && same_except_modified "$src" "$dest"; then
      rm -f "$src"
      continue
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
