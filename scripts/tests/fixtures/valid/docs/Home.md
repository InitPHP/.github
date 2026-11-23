# Home

- [Installation](Installation.md)
- [Quick start](./Quick-Start.md)
- [Configuration, section](Quick-Start.md#configuration)
- [Titled](Installation.md "Install it") and [angled](<Installation.md#requirements>)
- Two on one line: [a](Installation.md) and [b](Quick-Start.md#x)
- [Site](https://example.com/guide.md) stays, so does [mail](mailto:a@b.c) and [anchor](#local).
- Inline code is untouched: `[x](Installation.md)`, but [this](Installation.md) is rewritten.
- [Not markdown](../src/Foo.php) stays.

[ref]: Installation.md#requirements
[ref-titled]: ./Quick-Start.md "Quick start"
[external]: https://example.com/Page.md

```markdown
[inside fence](Installation.md) must stay exactly as written.
```

~~~
[inside tilde fence](Installation.md)
~~~

[after fences](Installation.md)

````markdown
```php
[inside a longer fence](Installation.md) must stay, the shorter marker above does not close it.
```
````

~~~
```
[inside tilde fence with a backtick line](Installation.md)
~~~

Two-backtick span: ``[x](Installation.md)`` and a `[y](Installation.md)` span stay, [this](Installation.md) is rewritten.

[after the longer fences](Installation.md)

```text
> ```php
> [inside the outer fence](Installation.md)
> ```
```

[after the outer fence](Installation.md)

> ```php
> [inside a quoted fence](Installation.md)
> ```

[after the quoted fence](Installation.md)

> ```php
> an unclosed quoted fence

[after the unclosed quoted fence](Installation.md)

<a id="top"></a>

## Local
