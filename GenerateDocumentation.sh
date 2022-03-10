#!/bin/sh

ln -s Source MIKMIDI # Workaround for https://github.com/realm/jazzy/issues/667

jazzy \
--objc \
--clean \
--github_url "https://github.com/mixedinkey-opensource/MIKMIDI" \
--hide-documentation-coverage \
--undocumented-text "This is currently undocumented. Documentation contributions are always welcome!" \
--framework-root Framework \
--umbrella-header Source/MIKMIDI.h \
--output Documentation

rm MIKMIDI
