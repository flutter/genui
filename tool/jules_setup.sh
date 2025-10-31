#!/bin/bash
set -e

git clone -b stable https://github.com/flutter/flutter.git $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"
flutter precache
