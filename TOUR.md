# A tour of letdown

## Block elements

Block elements are separated by blank lines.

### Headings

Three levels of headings:

```
# heading

## subheading

### sub-subheading
```

### Lists

Lists: (only one kind, no nesting)

```
- first
- second
- third
```

### Images

Images are always rendered as block elements. You can include an image like so:

```
=> path/to/img.png this is an image
```

The images start with a `=> `, followed by the path, then at least one whitespace
character, and then the rest of the text is used for the image's alt text.

### Blockquotes

Block quotes work like they do in gemtext- the line starts with `> ` and the 
rest of the block element is in the block quote.

### Preformatted text

Preformatted text can either occur in blocks using triple-backticks, like in 
markdown, or as span elements, using single-backticks.

## Span elements

### Emphasis

Emphasis is done solely by surrounding text in asterisks, like so: 

```
The following text is *emphasized*
```

### Links

Links come in a number of forms. You can use the following format for inline links:

```
This is a link to [Wikipedia](https://www.wikipedia.org/), the free encyclopedia.
```

These are configured to always open in a new tab when converted to HTML.

If there is no text between the `[` and `]` for this style of link, the link
URL is automatically inserted.

For internal links, you can use the wikilink format:

```
This is a [[wikilink]].
```

Whitespace that is not leading or trailing gets converted to a single underscore.

If a file extension is not provided, this markup language's extension (TBD) is
implicitly inserted to the end of the link. If one is included, it is not displayed
when rendered to HTML. For example:

```
Here is a [[wiki link]]
```

This refers to a file that would be named `wiki_link.tbd`, and would converted 
to HTML as:

```
<p>Here is a <a href="wiki_link.html">wiki link</a></p>
```

## Meta elements

### Tags

Tags can be used to insert metadata into the file. When the file is converted to
HTML, these tags are inserted as a comma-separated list in a `meta` tag, like so:

```
#tag1 #tag2
```

This becomes:

```
<meta name="keywords" content="tag1, tag2">
```

Tags may also be optionally rendered to the user in a list somewhere on the page.

### Comments

Comments are not rendered to the user. Comments are surrounded by `%%`. 
For example:

```
This is text %% with a comment %% and nothing else.
```
