# Tide Code Editor
### A thing I've been working on for the past few months. I think it's pretty cool.

## New Features (as of version 0.0.3):
- Files load considerably faster than previously.
- Added a Ruby lexer.
- Added keyboard shortcuts.
- Choosing a theme/lexer without having loaded a file works now.
- 

## Current Features:
- Lexers for C, JavaScript, Ruby, JSON, Lua, Talk (my programming language), Text, and Tcl.
- Some themes.
- Keybindings (e.g. Ctrl+c to copy text).
- Other miscellaneous things I've forgotten about.

## Soon-to-come Features:
- Customizable linemap (the thing with the line numbers).
- Multi-file editing (yeah that's not happening right now).
- Font chooser.
- In-app lexer/theme editor.

## Known Bugs (and very well know for that matter):
- Files over about 20kb may take a moment to load.
- Switching between lexers/themes repeatedly results in a file error that I have yet to find.
- If the application crashes when the lexer or theme menu is pulled up, the configuration file gets wiped (luckily, Tide can fix it when you reopen the application).
- For some reason, single-line c-style comments go through strings.
- Lua comments are kind of a mess.
- Regex rules in lexers only highlight a single line (so no multi-line regexes).

## Other Known Issues:
- Tide doesn't have an icon yet. Sorry, I'm not an artist.
- Most of the menu options are empty.
- Some highlighting is weird.

## If you want to contribute:
#### I have no clue how pull requests and related stuff works on github, so just email me at alan.invents@gmail.com or something if you want me to add a new lexer, theme, or feature.

## Other Notes:
- When opening a file, setting the lexer beforehand usually loads the file faster.
- Please don't copy my project and call it your own. I find that quite rude and disrespectful.
- Do not ask me to add Python. It's not happening.
- Tide stands for: Tcl IDE.
- Do not ask for Python. It still isn't happening.
- I am one person, so updates will take time.
- Again, no Python.

