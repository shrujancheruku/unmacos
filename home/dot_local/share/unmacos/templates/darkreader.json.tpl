{
  "enabled": true,
  "theme": {
    "mode": {{ if .dark }}1{{ else }}0{{ end }},
    "brightness": 100,
    "contrast": 100,
    "grayscale": 0,
    "sepia": 0,
    "useFont": false,
    "fontFamily": "Helvetica Neue",
    "textStroke": 0,
    "engine": "dynamicTheme",
    "stylesheet": "",
    "darkSchemeBackgroundColor": "{{ .theme.background }}",
    "darkSchemeTextColor": "{{ .theme.foreground }}",
    "lightSchemeBackgroundColor": "{{ .theme.background }}",
    "lightSchemeTextColor": "{{ .theme.foreground }}",
    "scrollbarColor": "{{ .theme.selection }}",
    "selectionColor": "{{ .theme.selection }}",
    "styleSystemControls": false,
    "lightColorScheme": "Default",
    "darkColorScheme": "Default",
    "immediateModify": false
  }
}
