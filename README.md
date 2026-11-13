[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.html)
![GitHub last commit](https://img.shields.io/github/last-commit/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist)

# Complete DoH/VPN/Proxy Bypass Blocklist

Mirror of selected [HaGeZi DNS blocklists](https://github.com/hagezi/dns-blocklists) for **DoH / VPN / Tor / proxy bypass**, with **`dnsbunker.org` appended** in the correct format for each list type.

**License:** [GPL-3.0](LICENSE) (same as upstream). List files keep HaGeZi headers and attribution.

**Source:** [hagezi/dns-blocklists](https://github.com/hagezi/dns-blocklists) — credit to [HaGeZi](https://github.com/hagezi).

---

## Why this repo exists

Upstream HaGeZi **DoH/VPN/Tor/Proxy Bypass** lists do **not** include [`dnsbunker.org`](https://dnsbunker.org/). A request to add it was [declined](https://github.com/hagezi/dns-blocklists/issues/12316) because HaGeZi runs mirrors and tools on subdomains of that domain.

That creates a hole in the bypass list: `dnsbunker.org` itself offers DoH (`https://dnsbunker.org/dns-query`). Anyone blocked by the Hagezi bypass lists can still sneak around DNS by using that resolver — which defeats the purpose of the list.

This repository mirrors the same domain-list formats and **always appends `dnsbunker.org`**, so the bypass coverage stays complete for that domain. See [hagezi/dns-blocklists#12316](https://github.com/hagezi/dns-blocklists/issues/12316) for the discussion.

> [!WARNING]
> **Do not use HaGeZi (or other) lists that are hosted on `dnsbunker.org` while using these lists.**  
> This mirror blocks `dnsbunker.org`, so clients that download filter lists from that host will fail to refresh those URLs. Point your filter clients at **this** repository (GitHub raw / jsDelivr below) or another host that is not `dnsbunker.org`.

---

## DoH/VPN/Tor/Proxy Bypass <a name="bypass"></a>

Blocks common ways to bypass your DNS setup.

> [!NOTE]
> To make sure your DNS server is actually the one being used, redirect or block standard DNS (TCP/UDP 53) and block DNS over TLS/QUIC (TCP/UDP 853) outbound.

**Pick one of the two domain lists below** (Complete **or** Encrypted DNS only). IP lists are out of scope for this mirror (v1).

Entry counts are domain entries after appending `dnsbunker.org` (RPZ counts both apex and wildcard lines in the file header).

### Complete edition: encrypted DNS servers, VPN, Tor, proxies <a name="bypass_all"></a>

| Entries | Adblock | DNSMasq | Wildcard Asterisk | Wildcard Domains | RPZ |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 16507 | [Link](https://cdn.jsdelivr.net/gh/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist@latest/adblock/doh-vpn-proxy-bypass.txt) | [Link](https://cdn.jsdelivr.net/gh/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist@latest/dnsmasq/doh-vpn-proxy-bypass.txt) | [Link](https://cdn.jsdelivr.net/gh/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist@latest/wildcard/doh-vpn-proxy-bypass.txt) | [Link](https://cdn.jsdelivr.net/gh/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist@latest/wildcard/doh-vpn-proxy-bypass-onlydomains.txt) | [Link](https://cdn.jsdelivr.net/gh/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist@latest/rpz/doh-vpn-proxy-bypass.txt) |

### Encrypted DNS servers only <a name="bypass_dns"></a>

| Entries | Adblock | DNSMasq | Wildcard Asterisk | Wildcard Domains | RPZ |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 3572 | [Link](https://cdn.jsdelivr.net/gh/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist@latest/adblock/doh.txt) | [Link](https://cdn.jsdelivr.net/gh/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist@latest/dnsmasq/doh.txt) | [Link](https://cdn.jsdelivr.net/gh/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist@latest/wildcard/doh.txt) | [Link](https://cdn.jsdelivr.net/gh/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist@latest/wildcard/doh-onlydomains.txt) | [Link](https://cdn.jsdelivr.net/gh/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist@latest/rpz/doh.txt) |

### Encrypted DNS only — Top 1M (Adblock)

Smaller Adblock-only variant (domains also on various Top 1M lists), plus `dnsbunker.org`:

| Entries | Adblock |
|:---:|:---:|
| 287 | [Link](https://cdn.jsdelivr.net/gh/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist@latest/adblock/doh.top.txt) |

---

## URLs

Paths match upstream HaGeZi (no `lists/` prefix).

**jsDelivr** (tables above):

```text
https://cdn.jsdelivr.net/gh/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist@latest/<path>
```

**GitHub raw** (`main`):

```text
https://raw.githubusercontent.com/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist/main/adblock/doh-vpn-proxy-bypass.txt
https://raw.githubusercontent.com/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist/main/adblock/doh.txt
https://raw.githubusercontent.com/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist/main/dnsmasq/doh-vpn-proxy-bypass.txt
https://raw.githubusercontent.com/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist/main/wildcard/doh-vpn-proxy-bypass.txt
https://raw.githubusercontent.com/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist/main/rpz/doh-vpn-proxy-bypass.txt
```

---

## Sync

Lists are refreshed by GitHub Actions:

- **Schedule:** daily (`17 6 * * *` UTC)
- **Manual:** Actions → **Sync Hagezi DoH lists** → **Run workflow**

Locally:

```bash
bash scripts/sync.sh
```

The workflow commits only when list content changed (author: `github-actions[bot]`). Append is idempotent: if upstream later includes `dnsbunker.org`, the sync will not duplicate it. Header `Number of entries` is bumped when markers are added.

### Formats appended

| Format | Appended as |
| --- | --- |
| Adblock | `\|\|dnsbunker.org^` |
| DNSMasq | `local=/dnsbunker.org/` |
| Wildcard asterisk | `*.dnsbunker.org` |
| Wildcard domains | `dnsbunker.org` |
| RPZ | `dnsbunker.org CNAME .` and `*.dnsbunker.org CNAME .` |

---

## Not included (v1)

- `adblock/doh-ips.txt`
- `ips/doh.txt`

---

## Disclaimer

This repository redistributes transformed copies of HaGeZi lists under GPL-3.0. Use at your own risk. Blocking encrypted DNS / VPN / proxy domains can break legitimate services; maintain your own allowlist as needed.
