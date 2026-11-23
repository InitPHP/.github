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

<a id="top"></a>

## Local
