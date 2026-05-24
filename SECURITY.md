# Security Policy

We take the security of InitPHP packages seriously. This document describes how to report a vulnerability, what to expect after you do, and which versions are currently receiving security updates.

## Reporting a Vulnerability

**Please do not open a public GitHub issue or Discussion for security vulnerabilities.** Public disclosure before a fix is available puts every user of the affected package at risk.

You have two private channels — either is acceptable, pick whichever fits you:

### 1. GitHub Private Vulnerability Reporting (preferred)

Every InitPHP repository has Private Vulnerability Reporting enabled. From the repository's **Security** tab, click **"Report a vulnerability"** and fill in the form. GitHub will route the report to maintainers and provide a private workspace where we can discuss, share patches, and coordinate disclosure.

This is the preferred channel because it keeps the entire conversation, draft advisory, and CVE coordination in one place.

### 2. Email

If you cannot use GitHub PVR (for example, you do not have an account or your employer's policy blocks it), email:

**[info@muhammetsafak.com.tr](mailto:info@muhammetsafak.com.tr)**

Please include the word `SECURITY` in the subject line so the message is routed correctly. If you wish to encrypt the report, request a public key in your initial message and we will exchange one.

### What to include in a report

- Which package and which version(s) are affected (e.g. `initphp/auth` `1.0.0..1.2.1`)
- A description of the vulnerability and its impact
- Steps to reproduce — ideally a minimal proof-of-concept
- Any known mitigations or workarounds
- Whether you would like to be credited in the advisory, and if so, the name / handle to use

## What to Expect

We aim to follow this timeline. We are a small team, so these are best-effort targets, not guarantees.

| Stage | Target |
| --- | --- |
| Acknowledgement of the report | within 72 hours |
| Initial assessment and severity rating | within 7 days |
| Fix available (high / critical) | within 30 days |
| Fix available (medium / low) | within 90 days |
| Public disclosure | coordinated with the reporter, normally within 14 days of the fix shipping |

We follow **coordinated disclosure**: we will not disclose the vulnerability publicly until a patched release is available, and we will credit the reporter (unless they ask to remain anonymous) in the GitHub Security Advisory and release notes.

## Scope

**In scope** — any code shipped by an InitPHP-namespaced Composer package:

- The `initphp/*` packages published on [Packagist](https://packagist.org/packages/initphp/)
- Source code in any [InitPHP organisation repository](https://github.com/InitPHP) that is not archived

**Out of scope** — issues that fall under a different project's security policy:

- Vulnerabilities in our **dependencies** (PSR interfaces, third-party libraries) — please report those upstream.
- Vulnerabilities in **PHP itself**, web servers, or operating systems.
- Vulnerabilities in **InitPHP-based applications** authored by third parties — those are the application owner's responsibility.
- Issues that require an attacker to already have administrative access to the host running the code (privilege escalation from root, etc.).
- Theoretical issues with no demonstrable exploit path.

Archived repositories (visible at the [organisation page](https://github.com/InitPHP)) are no longer maintained. We will not ship security fixes for archived packages — see each archived package's README for the recommended replacement.

## Supported Versions

For each active package, only the **latest stable major version** receives security updates. Patches will land on `main` and on the latest minor branch of the supported major. Older majors are considered end-of-life on the day a new major is released, unless explicitly stated otherwise in the package's `SECURITY.md` (which overrides this org-wide policy for that one package).

| Status | Receives security updates |
| --- | --- |
| Latest stable major | ✅ Yes |
| Previous majors | ❌ No (please upgrade) |
| Pre-release / `0.x` packages | Best effort, not guaranteed |
| Archived packages | ❌ No |

Run `composer show initphp/<package>` to confirm which version you have, and `composer outdated` to see if a newer release is available.

## Public Advisories

Once a fix is shipped, we publish a [GitHub Security Advisory](https://github.com/InitPHP) on the affected repository. Subscribe to the repository's **Security** tab if you want to be notified of advisories for a specific package. We also recommend running `composer audit` regularly — it pulls from the [Packagist security advisories database](https://packagist.org/security-advisories), which mirrors our GitHub advisories.

## Thanks

If you take the time to find and responsibly disclose a vulnerability, you are doing real work for every InitPHP user. We appreciate it, and — with your permission — we will say so publicly in the advisory.
