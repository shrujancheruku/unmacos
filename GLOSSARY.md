# UnMacOS

A keyboard-first, themeable macOS desktop installed with chezmoi. These are the words for what a user can pick, tweak and see.

## Configuration

**Setting**:
One value a user can change, with a type, a default and a plain-English label.
_Avoid_: option, preference, knob, pref

**Settings schema**:
The single list of every Setting UnMacOS understands, grouped for the wizard.
_Avoid_: config spec, settings registry

**Answers**:
A user's chosen values for the Settings they changed, kept in their own file and portable to another Mac.
_Avoid_: setup file, prefs, user config

**Feature**:
One part of UnMacOS a user can pick or leave out: a desktop part, a change to macOS or an app, or a group of apps to install. Features can need other Features.
_Avoid_: module, component, app group, keep flag, plugin

## Health

**Check**:
One thing UnMacOS can verify about the Mac, reported as done, to do, failed or unknown.
_Avoid_: test, probe

**Manual step**:
A Check for something macOS only lets the user do themselves, such as granting Accessibility.
_Avoid_: checklist item, todo

## Appearance

**Theme**:
A named palette of colours, plus any app files that palette ships with.
_Avoid_: colour scheme, skin

**Look**:
Everything about how the desktop appears: the Theme plus the visual Settings such as corner radius, gaps, fonts and bar height.
_Avoid_: appearance, style

**Draft Look**:
A Look shown on the real desktop while the user is still deciding, discarded unless they save it.
_Avoid_: preview mode, temp theme

## Wizard

**Install phase**:
The part of the wizard that runs before anything is installed: who you are, what to install, which Theme.
_Avoid_: pre-install, first run

**Tune phase**:
The part of the wizard that runs on the installed desktop, where Look changes show live as a Draft Look.
_Avoid_: customise step, settings mode
