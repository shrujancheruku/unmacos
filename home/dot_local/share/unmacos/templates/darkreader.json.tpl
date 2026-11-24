{
  "enabled": true,
  "theme": {
    "mode": {{ if .theme.dark }}1{{ else }}0{{ end }},
    "brightness": 100,
    "contrast": 100,
    "grayscale": 0,
    "sepia": 0,
    "useFont": false,
    "fontFamily": "Helvetica Neue",
    "textStroke": 0,
    "engine": "dynamicTheme",
    "stylesheet": "",
    "darkSchemeBackgroundColor": "{{ .color.background }}",
    "darkSchemeTextColor": "{{ .color.foreground }}",
    "lightSchemeBackgroundColor": "{{ .color.background }}",
    "lightSchemeTextColor": "{{ .color.foreground }}",
    "scrollbarColor": "{{ .color.selection }}",
    "selectionColor": "{{ .color.selection }}",
    "styleSystemControls": false,
    "lightColorScheme": "Default",
    "darkColorScheme": "Default",
    "immediateModify": false
  }
}
