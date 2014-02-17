#!/usr/bin/env bash

appledoc --project-name "MIKMIDI" --project-company "Mixed In Key" --company-id "com.mixedinkey" --output ./Documentation --keep-undocumented-objects --keep-undocumented-members --keep-intermediate-files --no-repeat-first-par --no-warn-invalid-crossref --docset-platform-family macosx --ignore "*.m" --index-desc "README.md" Source