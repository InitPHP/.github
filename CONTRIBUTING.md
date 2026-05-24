# Contributing to InitPHP

Thank you for considering contributing to InitPHP. This document is the **org-wide** contribution guide that applies to every package in the [InitPHP organisation](https://github.com/InitPHP). Individual packages may add their own `CONTRIBUTING.md` with extra detail; if a package-level guide says something different from this one, the **package-level guide wins**.

If you are completely new to contributing on GitHub, the [GitHub "First Contributions" tutorial](https://github.com/firstcontributions/first-contributions) is a friendly starting point.

## Code of Conduct

By participating in this project — issues, pull requests, discussions, or any other interaction — you agree to abide by our [Code of Conduct](./CODE_OF_CONDUCT.md). Be kind, assume good faith, and help us keep the project welcoming.

## Ways to Contribute

There is no contribution too small. All of these are welcome:

- **Reporting a bug** — open an issue on the affected package's repository.
- **Suggesting a feature or a new package** — open a [Discussion](https://github.com/orgs/InitPHP/discussions/categories/ideas) first so we can talk through the design before code is written.
- **Asking a question** — use [Discussions → Q&A](https://github.com/orgs/InitPHP/discussions/categories/q-a) (not Issues).
- **Improving documentation** — README, inline doc-blocks, [initphp.org](https://initphp.org) content; doc PRs are merged eagerly.
- **Sending code** — bug fixes, new features, tests, refactors. Read the PR section below before you start.
- **Triaging issues** — reproducing reported bugs, adding labels, asking for missing information. We always need help with this.
- **Reviewing PRs** — leave thoughtful comments on open pull requests; you do not need to be a maintainer.

## How the Multi-Repo Layout Works

InitPHP packages live in **separate repositories**, one per Composer package. There is no monorepo. This matters when you contribute:

- **Open issues against the affected package's repo**, not against `.github` or `initphp.github.io`. The `.github` repo is for org-wide concerns only.
- **One PR per repository.** If your change spans multiple packages (e.g. you update `initphp/http` and need a matching change in `initphp/router`), open a separate PR in each repo and link them with `Related: InitPHP/HTTP#NN` in the descriptions.
- **Releases are per-package.** Each package follows its own semver timeline; an `initphp/auth 2.0` does not imply that any other package bumps a major.

## Reporting Bugs

Before opening an issue, please:

1. **Search existing issues** (open and closed) and Discussions — your bug may already be reported or even fixed on `main`.
2. **Update to the latest version** of the package and check whether the bug is still reproducible.
3. **Confirm the bug is in InitPHP**, not in a dependency or your own code.

A good bug report contains:

- Package name and exact version (`composer show initphp/<package>`)
- PHP version and OS
- Required extensions / dependencies (Redis, PDO driver, etc.)
- A minimal reproducer (a small standalone script or a failing test)
- What you expected to happen and what actually happened
- Full error message, stack trace, or unexpected output

Issue templates are provided in the **New issue** picker — please use them.

## Suggesting Features

Open a **Discussion in the [Ideas](https://github.com/orgs/InitPHP/discussions/categories/ideas) category** first. Rationale:

- Most feature ideas need design discussion before code makes sense.
- Discussions are searchable and stay open without being "stale".
- Once an idea has consensus and a clear shape, a maintainer will promote it to a tracked issue and the PR can follow.

Avoid sending a large PR for a feature that has not been discussed — you may invest substantial time only to learn the feature does not fit the package's scope.

## Pull Request Process

### 1. Pick something to work on

- Browse [open issues](https://github.com/InitPHP) labelled `good-first-issue` or `help-wanted` (we will populate these over time).
- Comment on the issue to claim it. This avoids two contributors racing on the same fix.
- If no issue exists yet for what you want to do, open one first (or a Discussion for larger work).

### 2. Fork, branch, code

- **Fork** the affected repository and clone your fork locally.
- **Branch off `main`**, using a descriptive name: `fix/cache-file-locking`, `feat/csv-translator-loader`, `docs/router-middleware-example`.
- **Make focused commits**. One PR should do one thing — if you spot a second bug while fixing the first, send a separate PR.

### 3. Coding Standards

Every InitPHP package follows the same baseline:

- **PSR-12** code style. CI runs PHP-CS-Fixer; please run it locally before pushing (`composer cs-fix` if the package exposes it).
- **`declare(strict_types=1);`** at the top of every `.php` source file in `src/`.
- **Typed properties, parameters and return types** wherever PHP allows it (PHP 7.4+ for properties, 8.0+ for union types, 8.1+ for readonly / enum / intersection).
- **PHPStan** at the level configured in the package — fix every reported issue, do not silence.
- **No dead code.** Remove unused imports, classes and helpers rather than commenting them out.
- **No emoji or decorative comments** in source files. Comments explain *why*, not *what*.
- **English** in code, identifiers, comments and commit messages. Issues and Discussions may be in Turkish or English.

If the package has its own `phpstan.neon`, `.php-cs-fixer.dist.php` or `phpcs.xml`, treat those as authoritative. They override the defaults above.

### 4. Testing

- Every behaviour change needs a test. Bug fix? Write a test that reproduces the bug first, watch it fail, then make it pass.
- We use **PHPUnit** (the version is pinned by each package's `composer.json`).
- Run the suite locally before pushing: `composer test` (or `vendor/bin/phpunit`).
- If the package does not yet have tests, please **add a test for the area you are touching** — even one test is a strict improvement over zero.

### 5. Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<optional scope>): <short imperative description>

<optional body explaining the why, wrapped at ~72 columns>

<optional footer: Closes #NN, BREAKING CHANGE: ...>
```

Common types: `feat`, `fix`, `docs`, `chore`, `refactor`, `perf`, `test`, `ci`.

Good:

```
fix(client): pass listener, not listeners array, to call_user_func_array

The emit() loop previously passed the surrounding $listeners array as
the first argument to call_user_func_array(), so no listener was ever
actually invoked. Pass the iterated $listener instead.

Closes #NN
```

Bad:

```
update stuff
```

### 6. Opening the PR

- Target the **`main`** branch of the package repo.
- Fill in the PR template — it asks the questions reviewers always end up asking anyway.
- Link related issues with `Closes #NN` or `Refs #NN`.
- Keep the PR description focused: what changed, why, anything reviewers should pay attention to.
- Expect feedback. Reviewers are not nitpicking; they are trying to keep the package consistent across the ecosystem.

### 7. Review and Merge

- A maintainer will respond, usually within a week. Larger PRs may take longer.
- We may request changes. Please update the same branch (force-push is fine if needed) — do not open a fresh PR for revisions.
- We squash-merge by default to keep history readable. The squashed commit message will follow Conventional Commits.

## Versioning and Releases

Every package follows [Semantic Versioning 2.0](https://semver.org/):

- **Patch** (`1.2.3 → 1.2.4`) — bug fixes, internal refactors, documentation. No public API changes.
- **Minor** (`1.2.x → 1.3.0`) — new features, deprecations. Backwards compatible.
- **Major** (`1.x → 2.0.0`) — breaking changes. Migration notes are required in the release notes.

Releases are cut by maintainers via Git tags + GitHub Releases; Packagist auto-syncs from there. Contributors do not need to bump versions in PRs — leave that to the maintainer who cuts the release.

## Recognition

Every merged PR is permanently credited on the GitHub commit history and in the release notes for the version that includes it. We are also happy to add active contributors to the maintainer team once trust is established — typically after several merged PRs and demonstrated good judgement in reviews.

## Questions?

- Process or workflow questions → [Discussions → General](https://github.com/orgs/InitPHP/discussions/categories/general)
- "How do I do X with package Y?" → [Discussions → Q&A](https://github.com/orgs/InitPHP/discussions/categories/q-a)
- Code of Conduct concerns → [info@muhammetsafak.com.tr](mailto:info@muhammetsafak.com.tr)

Thanks again. Contributions of any size make the difference between a project that is alive and one that just sits on a shelf.
