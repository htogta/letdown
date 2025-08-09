# A tour of letdown

## Block elements

Block elements are separated by blank lines.

### Headings

Three levels of headings:

```
= heading

== subheading

=== sub-subheading
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

Block quotes are groups of lines that start with `> `, like so:

```
> this is a block quote

> this is a separate block quote,
> and this line is still part of it
```

### Code blocks

Code blocks are surrounded in triple-backticks. Comments, hashtags, link 
definitions, etc. are not removed from the bodies of code blocks.

## Span elements

### Emphasis

Emphasis is done solely by surrounding text in asterisks, like so: 

```
The following text is *emphasized*
```

### Inline code

Inline code appears surrounded by single backticks.

### Links

Links appear like so:

```
This is [a link].
```

By default, providing no URL/destination path for a link implies that the link
goes to another `.let` file- the link's name is trimmed of leading and trailing
whitespace, and spaces are automatically replaced with underscores, so the link
above would link to a file named `a_link.let` in the same directory.

If you want the link to have a different destination, you can define its 
destination separately on its own line. Here is an example:

```
This is a link to [Wikipedia]. Oh, and here's another [Wikipedia] link.

[Wikipedia]: https://en.wikipedia.org/
```

These definitions can go anywhere in the file, and are handled in a separate
pass by the parser.

## Meta elements

### Tags

Tags can be used to insert metadata into the file, and do not have to be rendered
to the user:

```
#tag1 #tag2
```

### Comments

Comments are not rendered to the user. Comments are surrounded by `;;`. 
For example:

```
This is text ;; with a comment ;; and nothing else.
```
