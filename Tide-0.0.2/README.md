# Tide Code Editor
### A thing I've been working on for the past few months. I think it's pretty cool.

## Current Features:
- Lexers for C, JavaScript, JSON, Lua, Talk (my programming language), Text, and Tcl.
- Some themes.
- Other miscellaneous things I've forgotten about.

## Soon-to-come Features:
- Customizable linemap (the thing with the line numbers).
- Multi-file editing (yeah that's not happening right now).
- Ability to load bigger files.
- Font chooser.
- Key bindings.
- Editing commands (e.g. undo, copy/paste, etc.)
- In-app lexer/theme editor.

## Known Bugs (and very well know for that matter):
- Files over, like, 20kb crash for some reason.
- Some files under 20kb to a while to load, and may freeze the application for a few seconds.
- Switching between lexers/themes constantly results in a file error that I have yet to find.
- If the application crashes when the lexer or theme menu is pulled up, the configuration file gets wiped, which is why there is a file called "CONFIG-BACKUP".
- For some reason, single-line c-style comments go through strings.
- Lua comments are kind of a mess.
- Regex rules in lexers only highlight a single line (so no multi-line regexes).

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