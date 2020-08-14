#!/bin/zsh

xcodebuild clean 
rm -r build
xcodebuild archive -scheme MIKMIDI -destination "platform=macOS" -archivePath "build/MIKMIDI.macOS.xcarchive" SKIP_INSTALL=NO
xcodebuild archive -scheme MIKMIDI-iOS -destination "generic/platform=iOS" -archivePath "build/MIKMIDI.iOS.xcarchive" SKIP_INSTALL=NO
xcodebuild archive -scheme MIKMIDI-iOS -destination "platform=iOS Simulator,name=iPhone 11" -archivePath "build/MIKMIDI.iOS-simulator.xcarchive" SKIP_INSTALL=NO
xcodebuild archive -scheme MIKMIDI-iOS -destination "platform=macOS,variant=Mac Catalyst" -archivePath "build/MIKMIDI.catalyst.xcarchive" SKIP_INSTALL=NO
xcodebuild -create-xcframework -framework "build/MIKMIDI.macOS.xcarchive/Products/Library/Frameworks/MIKMIDI.framework" -framework "build/MIKMIDI.iOS.xcarchive/Products/Library/Frameworks/MIKMIDI.framework" -framework "build/MIKMIDI.iOS-simulator.xcarchive/Products/Library/Frameworks/MIKMIDI.framework" -framework "build/MIKMIDI.catalyst.xcarchive/Products/Library/Frameworks/MIKMIDI.framework" -output "build/MIKMIDI.xcframework"
