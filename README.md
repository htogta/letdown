# letdown markup language

This is a markup language I have created based on Obsidian and GitHub markdown,
as well as gemtext, for use in a static site generator for my personal blog.

Letdown aspires to be:

- Easy to read
- Easy to implement
- Convenient for blogging and writing wiki pages
- Ergonomic (minimizing keystrokes)
- As small as possible

All without being overly spartan.

> [!WARNING]
> This markup language is still in beta- expect non-backwards-compatible changes
> in the future.

## Features

- blank-line-delimited blocks (no writing everything on one line, *ahem* gemtext)
- 3 levels of headings
- unordered, non-nestable lists
- reference-style links
- one level of emphasis (who needs both bold *and* italics?)
- block-level images
- blockquotes
- inline code and code blocks
- comments
- tagging

## Using letdown.lua

Included in this repo is a Lua script that will convert files in this markup 
language (`.let` files) into HTML.

Feel free to run `lua letdown.lua -h` to get some basic usage information.

By default, the script just outputs the content that would go inside an HTML
`<body>` tag. However, this script allows for the use of HTML templates with 
the `-t` flag.

The script supports the following templating features to be used in template HTML
files:

- `%body` inserts the basic output body of the letdown file
- `%tags` inserts tags as a comma-separated list
- `%file` inserts the name of the file, without its `.let` extension
- `%h1` inserts the text of the first `<h1>` (i.e. `= `) element

Example:

```sh
lua letdown.lua file.let -t template.html -o newfile.html
```

The resulting file will be `newfile.html` using `template.html` as a template.

## Resources

See `letdown.ebnf` for a (rough) grammar of this language in EBNF notation.

See `tour.md` for a description/tour of the language.

See `example.let` for an example that showcases every feature of the language.

`extras/letdown.yaml` contains syntax highlighting support for the 
[micro](https://github.com/zyedidia/micro) text editor.
