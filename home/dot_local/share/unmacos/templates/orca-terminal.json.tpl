{
  "schemaVersion": 1,
  "mode": "{{ .theme.mode }}",
  "terminal": {
    "foreground": "{{ .color.foreground }}",
    "background": "{{ .color.background }}",
    "cursor": "{{ .color.foreground }}",
    "cursorAccent": "{{ .color.background }}",
    "selectionBackground": "{{ .color.selection }}",
    "selectionForeground": "{{ .color.foreground }}",
    "black": "{{ .color.dark_background }}",
    "red": "{{ .color.red }}",
    "green": "{{ .color.green }}",
    "yellow": "{{ .color.yellow }}",
    "blue": "{{ .color.blue }}",
    "magenta": "{{ .color.magenta }}",
    "cyan": "{{ .color.cyan }}",
    "white": "{{ .color.dark_foreground }}",
    "brightBlack": "{{ .color.selection }}",
    "brightRed": "{{ .color.bright_red }}",
    "brightGreen": "{{ .color.bright_green }}",
    "brightYellow": "{{ .color.bright_yellow }}",
    "brightBlue": "{{ .color.bright_blue }}",
    "brightMagenta": "{{ .color.bright_magenta }}",
    "brightCyan": "{{ .color.bright_cyan }}",
    "brightWhite": "{{ .color.bright_foreground }}"
  }
}
