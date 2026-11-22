#!/bin/bash
# UnMacOS: macOS settings for a tiling desktop. Re-runs when this file changes.
set -euo pipefail
echo "==> macOS settings"

# Dock: hidden, no recents; Spaces stay in order (Rift needs this)
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock tilesize -int 64
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock expose-group-apps -bool true

# Displays have separate Spaces (required by Rift)
defaults write com.apple.spaces spans-displays -bool false

# Hide the menu bar (SketchyBar replaces it); dark mode
defaults write NSGlobalDomain _HIHideMenuBar -bool true
defaults write NSGlobalDomain AppleInterfaceStyle -string Dark

# Keyboard: hold a key to repeat it (no accent popup)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Ctrl+Cmd drag to move windows from anywhere
defaults write NSGlobalDomain NSWindowShouldDragOnGesture -bool true

# Stage Manager / native tiling off (Rift does tiling)
defaults write com.apple.WindowManager GloballyEnabled -bool false
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false
defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false

# Finder: list view, path bar, extensions
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
defaults write com.apple.finder ShowPathbar -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true


killall Dock Finder SystemUIServer 2>/dev/null || true
echo "Log out and back in for Spaces and menu bar changes."
