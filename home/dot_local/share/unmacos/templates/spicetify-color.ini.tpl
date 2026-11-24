; UnMacOS: Spicetify color scheme, rendered by unmacos-theme-render.
; ~/.config/spicetify/Themes/UnMacOS/color.ini links here; Spicetify wants
; hex without the leading #.
[UnMacOS]
text               = {{ .bare.foreground }}
subtext            = {{ .bare.dark_foreground }}
main               = {{ .bare.background }}
main-elevated      = {{ .bare.lighter_background }}
main-secondary     = {{ .bare.darker_background }}
highlight          = {{ .bare.selection }}
highlight-elevated = {{ .bare.selection }}
sidebar            = {{ .bare.dark_background }}
player             = {{ .bare.dark_background }}
card               = {{ .bare.lighter_background }}
shadow             = {{ .bare.dark_background }}
selected-row       = {{ .bare.dark_foreground }}
button             = {{ .bare.accent }}
button-active      = {{ .bare.accent }}
button-secondary   = {{ .bare.muted }}
button-disabled    = {{ .bare.selection }}
tab-active         = {{ .bare.selection }}
nav-active         = {{ .bare.accent }}
nav-active-text    = {{ .bare.background }}
play-button        = {{ .bare.accent }}
playback-bar       = {{ .bare.accent }}
notification       = {{ .bare.selection }}
notification-error = {{ .bare.red }}
misc               = {{ .bare.muted }}
