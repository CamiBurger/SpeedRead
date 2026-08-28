.PHONY: project build run icon package clean

# Regenerate the Xcode project from project.yml
project:
	xcodegen generate

build: project
	xcodebuild -project SpeedRead.xcodeproj -scheme SpeedRead -configuration Debug build

run: build
	open ~/Library/Developer/Xcode/DerivedData/SpeedRead-*/Build/Products/Debug/SpeedRead.app

# Regenerate the app icon (zooming 🐇)
icon:
	swift Tools/makeicon.swift

# Universal Release build + DMG into dist/ (see scripts/package.sh for signing env)
package:
	./scripts/package.sh

clean:
	rm -rf build dist SpeedRead.xcodeproj
