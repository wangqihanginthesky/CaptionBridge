#!/bin/zsh
set -eu
cd "${0:A:h:h}"
zsh scripts/build.sh
mkdir -p "$HOME/Applications"
ditto "$PWD/.build/CaptionBridge.app" "$HOME/Applications/CaptionBridge.app"
echo "Installed: $HOME/Applications/CaptionBridge.app"
