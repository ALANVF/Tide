# Tide Code Editor
### A thing I've been working on for the past few months. I think it's pretty cool.

## New Features (as of version 0.0.4):
- Added auto-indenting (mostly).
- Added a C++ lexer.
- Added a Java lexer.
- Added a Pascal lexer.
- Added a Perl 6 lexer.
- Added a Scala lexer.
- File chooser actually acknowledges extensions listed in language files.
- Fixed some weird bugs.

## Current Features:
- Lexers for C, C++, Java, JavaScript, JSON, Lua, Pascal, Perl 6, Ruby (it's a bit broken fsr), Scala, Talk (my own programming language), Tcl, and normal text.
- Some themes (adding more soon).
- Other miscellaneous things I've forgotten about.

## Soon-to-come Features:
- Customizable linemap (the thing with the line numbers).
- Multi-file editing (yeah that's not happening right now).
- Ability to load bigger files.
- Font chooser.
- In-app lexer/theme editor.
- Macros.
- Application extensions.

## Known Bugs (and very well know for that matter):
- Files over, like, 20kb crash for some reason.
- Some files under 20kb to a while to load, and may freeze the application for a few seconds.
- Switching between lexers/themes constantly results in a file error that I have yet to find.
- The config file can randomly get messed up if something goes wrong, which is why there is a file called "CONFIG-BACKUP".
- For some reason, single-line c-style comments go through strings.
- Lua comments are kind of a mess.
- Ruby pretty much ignores strings and highlights everything in them.

## Other Known Issues:
- Tide doesn't have an icon yet. Sorry, I'm not an artist.
- Most of the menu options are empty.

## If you want to contribute:
#### I have no clue how pull requests and related stuff works on github, so just email me at alan.invents@gmail.com or something if you want me to add a new lexer, theme, or feature.

## Other Notes:
- Please don't copy my project and call it your own. I find that quite rude and disrespectful.
- Do not ask me to add Python. It's not happening.
- Tide stands for: Tcl IDE.
- Do not ask for Python. It still isn't happening.
- I am one person, so updates will take time.
- Again, no Python.
