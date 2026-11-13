[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.html)
![GitHub last commit](https://img.shields.io/github/last-commit/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist)

# Complete DoH/VPN/Proxy Bypass Blocklist

Mirror of selected [HaGeZi DNS blocklists](https://github.com/hagezi/dns-blocklists) for **DoH / VPN / Tor / proxy bypass**, with **`dnsbunker.org` appended** in the correct format for each list type.

Upstream Hagezi lists do **not** include `dnsbunker.org`. This mirror adds it on every sync.

**License:** [GPL-3.0](LICENSE) (same as upstream). Lists keep HaGeZi headers and attribution.

**Source:** [hagezi/dns-blocklists](https://github.com/hagezi/dns-blocklists) — credit to [HaGeZi](https://github.com/hagezi).

---

## DoH/VPN/Tor/Proxy Bypass <a name="bypass"></a>

Blocks common ways to bypass your DNS setup.

> [!NOTE]
> To make sure your DNS server is actually the one being used, you'll need to redirect or block standard DNS traffic (TCP/UDP 53) and also block DNS over TLS/QUIC (TCP/UDP 853) outbound.

**Pick one of the two domain lists below** (Complete **or** Encrypted DNS only). IP lists are out of scope for this mirror (v1).

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

## Raw GitHub URLs

Same paths as upstream Hagezi. Examples (branch `main` after merge):

```text
https://raw.githubusercontent.com/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist/main/adblock/doh-vpn-proxy-bypass.txt
https://raw.githubusercontent.com/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist/main/adblock/doh.txt
https://raw.githubusercontent.com/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist/main/dnsmasq/doh-vpn-proxy-bypass.txt
https://raw.githubusercontent.com/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist/main/wildcard/doh-vpn-proxy-bypass.txt
https://raw.githubusercontent.com/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist/main/rpz/doh-vpn-proxy-bypass.txt
```

jsDelivr CDN (used in the tables above):

```text
https://cdn.jsdelivr.net/gh/EriusCalrissian/complete-doh-vpn-proxy-bypass-blocklist@latest/<path>
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

The workflow commits only when list content changed. Append is idempotent: if upstream later includes `dnsbunker.org`, the sync will not duplicate it.

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
