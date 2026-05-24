<p align="center">
  <img src="https://github.com/InitPHP/.github/assets/104234499/ba9a85b7-81f7-404f-8f29-9434e86fb374" width="200" alt="InitPHP">
</p>

<h1 align="center">InitPHP</h1>

<p align="center">
  <strong>A collection of small, focused, PSR-compliant PHP packages.</strong><br>
  Compose only the pieces you need — every package stands on its own.
</p>

<p align="center">
  <a href="https://initphp.org">Website</a> ·
  <a href="https://packagist.org/packages/initphp/">Packagist</a> ·
  <a href="https://github.com/orgs/InitPHP/discussions">Discussions</a> ·
  <a href="https://github.com/InitPHP/.github/blob/main/CONTRIBUTING.md">Contributing</a>
</p>

---

## What is InitPHP?

InitPHP publishes a family of independent, single-responsibility PHP packages. Each one solves a specific problem — HTTP messaging, routing, validation, sessions, etc. — and adheres to the relevant PHP-FIG standard (PSR-3, PSR-7, PSR-11, PSR-12, PSR-15, PSR-16, PSR-18 where applicable).

InitPHP is **not** a framework. There is no monolithic runtime, no opinionated bootstrap, no "you must structure your app like this". Take a router and nothing else; pair a query builder with a third-party DI container; or combine a dozen InitPHP packages to build something larger. The choice is yours.

If you have used the [League of Extraordinary Packages](https://thephpleague.com/) or browsed Symfony's individual components, the model will feel familiar.

## Featured packages

| Package | What it does |
| --- | --- |
| [**`initphp/http`**](https://github.com/InitPHP/HTTP) | PSR-7 messages, PSR-17 factory, PSR-18 client — a self-contained HTTP toolkit. |
| [**`initphp/router`**](https://github.com/InitPHP/Router) | Fast HTTP router with grouping, middleware, route caching and PSR-7 integration. |
| [**`initphp/database`**](https://github.com/InitPHP/Database) | PDO-based DBAL with Data Mapper, Query Builder and migration support. |
| [**`initphp/container`**](https://github.com/InitPHP/Container) | Minimal PSR-11 dependency container with reflection-based autowiring. |
| [**`initphp/auth`**](https://github.com/InitPHP/Auth) | Pluggable authentication with adapter-based credential and session storage. |
| [**`initphp/validation`**](https://github.com/InitPHP/Validation) | Expressive, rule-based data validation with fluent syntax. |

## Quick start

Every package is a standalone Composer install. There is no umbrella package to pull in — depend only on what you use.

```bash
composer require initphp/router
```

```php
use InitPHP\Router\Router;

$router = new Router();

$router->get('/hello/{name}', function (string $name) {
    return "Hello, {$name}!";
});

$router->run();
```

Browse the full documentation at [**initphp.org**](https://initphp.org).

## All packages

<details>
<summary><strong>Browse all 28 active packages by category</strong></summary>

### HTTP & Web
- [`initphp/http`](https://github.com/InitPHP/HTTP) — PSR-7 / 17 / 18 toolkit
- [`initphp/router`](https://github.com/InitPHP/Router) — HTTP router

### Data & Storage
- [`initphp/database`](https://github.com/InitPHP/Database) — DBAL, Data Mapper, Query Builder
- [`initphp/barbarian`](https://github.com/InitPHP/Barbarian) — Database migrations
- [`initphp/cache`](https://github.com/InitPHP/Cache) — PSR-16 simple cache (File, Redis, Memcache, PDO adapters)
- [`initphp/sessions`](https://github.com/InitPHP/Sessions) — Session manager (PDO, Memcache, Redis, Cookie, File, MongoDB adapters)
- [`initphp/cookies`](https://github.com/InitPHP/Cookies) — Cookie management

### Security
- [`initphp/auth`](https://github.com/InitPHP/Auth) — Authentication
- [`initphp/encryption`](https://github.com/InitPHP/Encryption) — OpenSSL / Sodium encrypt-decrypt
- [`initphp/escaper`](https://github.com/InitPHP/Escaper) — Context-aware output escaping
- [`initphp/validation`](https://github.com/InitPHP/Validation) — Input validation

### CLI
- [`initphp/console`](https://github.com/InitPHP/Console) — CLI application toolkit (incl. ANSI table renderer)

### Templating & I18n
- [`initphp/views`](https://github.com/InitPHP/Views) — View engine
- [`initphp/translator`](https://github.com/InitPHP/Translator) — Multi-language support

### Infrastructure
- [`initphp/container`](https://github.com/InitPHP/Container) — PSR-11 DI container
- [`initphp/config`](https://github.com/InitPHP/Config) — Configuration manager
- [`initphp/dotenv`](https://github.com/InitPHP/DotENV) — `.env` loader
- [`initphp/events`](https://github.com/InitPHP/Events) — Event dispatcher / hooks
- [`initphp/logger`](https://github.com/InitPHP/Logger) — PSR-3 logger (File, PDO handlers)
- [`initphp/parameterbag`](https://github.com/InitPHP/ParameterBag) — Key/value parameter bag

### Async & Networking
- [`initphp/fiber-loops`](https://github.com/InitPHP/FiberLoops) — PHP 8.1 fiber-based event loop
- [`initphp/socket`](https://github.com/InitPHP/Socket) — TCP / TLS / UDP / SSL sockets
- [`initphp/queue`](https://github.com/InitPHP/Queue) — Queue (PDO, RabbitMQ adapters)

### Utilities
- [`initphp/input`](https://github.com/InitPHP/Input) — Request input handling
- [`initphp/upload`](https://github.com/InitPHP/Upload) — File upload (Local, S3, FTP adapters)
- [`initphp/mailer`](https://github.com/InitPHP/Mailer) — Mail sending
- [`initphp/performance-meter`](https://github.com/InitPHP/PerformanceMeter) — Tiny zero-dep profiler

</details>

## Recent consolidation

The ecosystem has been streamlined: several narrow packages have been merged into broader, more capable ones, and a few stale wrappers have been retired. Composer surfaces the retired packages as `abandoned` and points you at the replacement.

| Retired package | Replacement |
| --- | --- |
| `initphp/event-emitter` | [`initphp/events`](https://github.com/InitPHP/Events) (≥ 2.0) |
| `initphp/http-client` | [`initphp/http`](https://github.com/InitPHP/HTTP) (≥ 2.2) |
| `initphp/http-factory` | [`initphp/http`](https://github.com/InitPHP/HTTP) (≥ 2.2) |
| `initphp/curl` | [`initphp/http`](https://github.com/InitPHP/HTTP) (≥ 2.2) |
| `initphp/redis-session-handler` | [`initphp/sessions`](https://github.com/InitPHP/Sessions) RedisAdapter |
| `initphp/cli-table` | [`initphp/console`](https://github.com/InitPHP/Console) (≥ 2.1) |
| `initphp/redis` | Use `ext-redis` directly, or [`initphp/cache`](https://github.com/InitPHP/Cache) / [`initphp/sessions`](https://github.com/InitPHP/Sessions) |
| `initphp/var-dumper` | [`symfony/var-dumper`](https://github.com/symfony/var-dumper) |
| `initphp/polyfill-php80` | [`symfony/polyfill-php80`](https://github.com/symfony/polyfill-php80) |

Migration guides live in the README of each retired package.

## Contributing

Contributions are welcome and encouraged. Start with [**CONTRIBUTING.md**](https://github.com/InitPHP/.github/blob/main/CONTRIBUTING.md) for the workflow and conventions, browse open issues across the org for ideas, or open a [Discussion](https://github.com/orgs/InitPHP/discussions) if you want to talk through a larger change before sending a PR.

Security issues should be reported privately — see [SECURITY.md](https://github.com/InitPHP/.github/blob/main/SECURITY.md).

## Sponsor

If InitPHP saves you time, please consider [sponsoring the project](https://github.com/sponsors/muhammetsafak). Sponsorship directly funds active maintenance, security updates, CI/CD across the ecosystem, and improvements to [initphp.org](https://initphp.org).

## License

All packages are released under the **MIT License** unless stated otherwise in the package's own `LICENSE` file.
