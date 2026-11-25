{
  "schemaVersion": 1,
  "mode": "{{ .theme.mode }}",
  "terminal": {
    "foreground": "{{ .theme.foreground }}",
    "background": "{{ .theme.background }}",
    "cursor": "{{ .theme.foreground }}",
    "cursorAccent": "{{ .theme.background }}",
    "selectionBackground": "{{ .theme.selection }}",
    "selectionForeground": "{{ .theme.foreground }}",
    "black": "{{ .theme.dark_background }}",
    "red": "{{ .theme.red }}",
    "green": "{{ .theme.green }}",
    "yellow": "{{ .theme.yellow }}",
    "blue": "{{ .theme.blue }}",
    "magenta": "{{ .theme.magenta }}",
    "cyan": "{{ .theme.cyan }}",
    "white": "{{ .theme.dark_foreground }}",
    "brightBlack": "{{ .theme.selection }}",
    "brightRed": "{{ .theme.bright_red }}",
    "brightGreen": "{{ .theme.bright_green }}",
    "brightYellow": "{{ .theme.bright_yellow }}",
    "brightBlue": "{{ .theme.bright_blue }}",
    "brightMagenta": "{{ .theme.bright_magenta }}",
    "brightCyan": "{{ .theme.bright_cyan }}",
    "brightWhite": "{{ .theme.bright_foreground }}"
  }
}
