# Live preview is a Draft Look on the real desktop, so the Look renderer owns app configs

The Tune phase previews a change by rendering a Draft Look into the state directory apps already read and reloading them, then discarding it unless the user saves. To make that possible the Look renderer, not `chezmoi apply`, writes every visual value an app reads, including the whole Rift `config.toml` where an app has no include directive. A mock preview (terminal drawing or HTML) was rejected: it never matches the real desktop and is a second renderer to keep in step.
