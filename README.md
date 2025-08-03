# letdown markup language

This is a markup language I have created based on Obsidian and GitHub markdown,
as well as gemtext, for use in a static site generator for my personal blog.

Included in this repo is a Lua script that will convert files in this markup
language (`.let` or `.letdown` files) into HTML. To use it, make sure you have
installed Lua and run `lua letdown.lua -h` to learn how to use it.

See `letdown.ebnf` for a grammar of this language in EBNF notation.

See `TOUR.md` for a description/tour of the language.

See `example.let` for an example that shows all of the features of the language.
