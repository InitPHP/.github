# Home

- [Trait](#messagetraitsmessagetrait)
- [Code and emphasis](#the-get-method-is-final)
- [Repeat](Reference.md#usage-1) and [first](Reference.md#usage)
- [Link heading](Reference.md#see-the-faq)
- [Explicit](Reference.md#custom-target)
- [Accents](#çözümleme-sırası)
- [Angle brackets in code](#the-collectionuser-class)
- [Underscore emphasis](#foo-bar-baz)
- [Underscores inside words](#snake_case_name-stays)
- [Escaped underscore](#foo_bar-escaped)
- [Entity](#b--c)
- [Image text is dropped](#-foo)
- [Link text and emphasis](#wincache--deprecated)
- [Setext](#setext-title) and [setext over two lines](#two-linessetext-heading)
- [Block quote](#quoted) and [list item](#in-a-list)
- [Closing hashes](#closing-hashes) and [reference link](#see-the-docs)
- [Raw heading](#raw-heading), [id](#increment), [single-quoted name](#single-name), [div id](#boxed)
- [Top](#top), [upper-case top](#TOP), [percent-encoded](#%C3%B6n)
- [Repeats](#again), [again 1](#again-1), [again 2](#again-2), [clash with a literal heading](#again-1-1)
- [Inline tags are dropped](#press-ctrl-to-save)
- [Setext with an indented continuation](#para-before-indented-lineindented-continuation)
- [A target after a comment](#after-comment) and [a heading after one](#after-the-comment)
- [Reference definition on this page][local-ref]

[local-ref]: #foo-bar-baz
[docs]: Reference.md

## `Message\Traits\MessageTrait`

## The `get()` method is **final**

## Çözümleme sırası

## The `Collection<User>` class

## Foo _bar_ baz

## snake_case_name stays

## Foo\_bar escaped

## B &amp; C

## ![alt](image.png) Foo

## [WinCache](https://example.com) — _deprecated_

Setext title
------------

Para before indented line
    indented continuation
---

Two lines
setext heading
==============

> ## Quoted

- ## In a list

## Closing hashes ##

## See [the docs][docs]

<h2>Raw heading</h2>

<h3 id="increment">Not the same as the id</h3>

<a name='single-name'></a>

<div id="boxed">Boxed</div>

## Ön

## Again

## Again-1

## Again

## Again-1

## Press <kbd>Ctrl</kbd> to <em>save</em>

<!-- ## Commented out -->

## After the comment

<!-- note --> <a name="after-comment"></a>

```markdown
## Fenced heading is not a target
```

`<a name="inline-name">` and `## Not a heading` stay text.
