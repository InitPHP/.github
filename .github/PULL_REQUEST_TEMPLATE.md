<!--
Thanks for sending a pull request! Please:
- Read CONTRIBUTING.md if you haven't: https://github.com/InitPHP/.github/blob/main/CONTRIBUTING.md
- Open one PR per repository — cross-repo changes need a separate PR in each repo, linked in the description.
- Keep the PR focused on one change. If you spotted unrelated improvements, please send them as separate PRs.
-->

## Summary

<!-- One or two sentences: what does this PR do, and why? Focus on the why — the diff already shows the what. -->

## Type of change

<!-- Check all that apply. -->

- [ ] 🐛 Bug fix (non-breaking change that fixes an issue)
- [ ] ✨ New feature (non-breaking change that adds functionality)
- [ ] 💥 Breaking change (fix or feature that changes existing behaviour in an incompatible way)
- [ ] 📖 Documentation update
- [ ] 🔧 Refactor / internal change (no behaviour change)
- [ ] ✅ Tests only
- [ ] 🚀 CI / build / tooling

## Linked issues

<!-- e.g. "Closes #123" / "Refs #456" / "Related: InitPHP/HTTP#42" for cross-repo work. -->

## How was this tested?

<!--
Describe the tests you ran and any manual verification steps.
Paste relevant output (test runs, before/after) if helpful.
If this PR adds or changes behaviour, it should also add or update a test.
-->

## Breaking changes

<!--
If you checked "Breaking change" above, describe:
- What breaks (which public API, signature, behaviour)
- The migration path users need to take
- Whether a BC shim (class_alias, deprecation wrapper) was added or considered
Otherwise, write "N/A".
-->

## Checklist

- [ ] Code follows PSR-12 and the project's existing style (PHP-CS-Fixer if available, no warnings)
- [ ] `declare(strict_types=1);` is present in any new PHP files in `src/`
- [ ] Public methods have proper type declarations (parameters and return types)
- [ ] Tests cover the change — added new tests or updated existing ones (N/A for docs-only PRs)
- [ ] PHPStan passes locally at the level configured in the package
- [ ] PHPUnit passes locally (`composer test` or `vendor/bin/phpunit`)
- [ ] Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
- [ ] I have read and agree to the [Code of Conduct](https://github.com/InitPHP/.github/blob/main/CODE_OF_CONDUCT.md)
