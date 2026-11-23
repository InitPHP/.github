# Home

- [Installation](Installation)
- [Quick start](Quick-Start)
- [Configuration, section](Quick-Start#configuration)
- [Titled](Installation "Install it") and [angled](<Installation#requirements>)
- Two on one line: [a](Installation) and [b](Quick-Start#x)
- [Site](https://example.com/guide.md) stays, so does [mail](mailto:a@b.c) and [anchor](#local).
- Inline code is untouched: `[x](Installation.md)`, but [this](Installation) is rewritten.
- [Not markdown](../src/Foo.php) stays.

[ref]: Installation#requirements
[ref-titled]: Quick-Start "Quick start"
[external]: https://example.com/Page.md

```markdown
[inside fence](Installation.md) must stay exactly as written.
```

~~~
[inside tilde fence](Installation.md)
~~~

[after fences](Installation)

````markdown
```php
[inside a longer fence](Installation.md) must stay, the shorter marker above does not close it.
```
````

~~~
```
[inside tilde fence with a backtick line](Installation.md)
~~~

Two-backtick span: ``[x](Installation.md)`` and a `[y](Installation.md)` span stay, [this](Installation) is rewritten.

[after the longer fences](Installation)

```text
> ```php
> [inside the outer fence](Installation.md)
> ```
```

[after the outer fence](Installation)

> ```php
> [inside a quoted fence](Installation.md)
> ```

[after the quoted fence](Installation)

> ```php
> an unclosed quoted fence

[after the unclosed quoted fence](Installation)

<a id="top"></a>

## Local
