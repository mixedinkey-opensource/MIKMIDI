#!/bin/zsh

rm -r MIKMIDI.xcframework
rm -r build
xcodebuild clean 

echo "Building for macOS"
xcodebuild archive \
-scheme MIKMIDI \
-destination "platform=macOS" \
-archivePath "build/MIKMIDI.macOS.xcarchive" \
SKIP_INSTALL=NO

echo "Building for iOS devices (arm64)"
xcodebuild archive \
-scheme MIKMIDI-iOS \
-sdk iphoneos \
-destination "generic/platform=iOS" \
-archivePath "build/MIKMIDI.iOS.xcarchive" \
SKIP_INSTALL=NO

echo "Building for iOS simulator"
xcodebuild archive \
-scheme MIKMIDI-iOS \
-sdk iphonesimulator \
-archivePath "build/MIKMIDI.iOS-simulator.xcarchive" \
SKIP_INSTALL=NO

echo "Building for Mac Catalyst"
xcodebuild archive \
-scheme MIKMIDI-iOS \
-destination "platform=macOS,variant=Mac Catalyst" \
-archivePath "build/MIKMIDI.catalyst.xcarchive" \
SKIP_INSTALL=NO

xcodebuild -create-xcframework \
-framework "build/MIKMIDI.macOS.xcarchive/Products/Library/Frameworks/MIKMIDI.framework" \
-framework "build/MIKMIDI.iOS.xcarchive/Products/Library/Frameworks/MIKMIDI.framework" \
-framework "build/MIKMIDI.iOS-simulator.xcarchive/Products/Library/Frameworks/MIKMIDI.framework" \
-framework "build/MIKMIDI.catalyst.xcarchive/Products/Library/Frameworks/MIKMIDI.framework" \
-output "MIKMIDI.xcframework"

rm -r build

open .
