; UnMacOS: Spicetify color scheme, rendered by unmacos-theme-render.
; ~/.config/spicetify/Themes/UnMacOS/color.ini links here; Spicetify wants
; hex without the leading #.
[UnMacOS]
text               = {{ .hex.foreground }}
subtext            = {{ .hex.dark_foreground }}
main               = {{ .hex.background }}
main-elevated      = {{ .hex.lighter_background }}
main-secondary     = {{ .hex.darker_background }}
highlight          = {{ .hex.selection }}
highlight-elevated = {{ .hex.selection }}
sidebar            = {{ .hex.dark_background }}
player             = {{ .hex.dark_background }}
card               = {{ .hex.lighter_background }}
shadow             = {{ .hex.dark_background }}
selected-row       = {{ .hex.dark_foreground }}
button             = {{ .hex.accent }}
button-active      = {{ .hex.accent }}
button-secondary   = {{ .hex.muted }}
button-disabled    = {{ .hex.selection }}
tab-active         = {{ .hex.selection }}
nav-active         = {{ .hex.accent }}
nav-active-text    = {{ .hex.background }}
play-button        = {{ .hex.accent }}
playback-bar       = {{ .hex.accent }}
notification       = {{ .hex.selection }}
notification-error = {{ .hex.red }}
misc               = {{ .hex.muted }}
