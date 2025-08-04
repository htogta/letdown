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
> This markup language is still in beta- expect non-backwards-compatible changes in the future.

## Features

- blank-line-delimited blocks (no writing everything on one line, *ahem* gemtext)
- 3 levels of headings
- unordered, non-nestable lists
- links
- one level of emphasis (who needs both bold *and* italics?)
- block-level images
- blockquotes
- inline code and code blocks
- comments
- tagging

## Resources

Included in this repo is a Lua script that will convert files in this markup
language (`.let` or `.letdown` files) into HTML. To use it, make sure you have
installed Lua and run `lua letdown.lua -h` to learn how to use it.

See `letdown.ebnf` for a grammar of this language in EBNF notation.

See `TOUR.md` for a description/tour of the language.

See `example.let` for an example that shows all of the features of the language.
