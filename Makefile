.PHONY: app project build clean

project:
	xcodegen generate

build: project
	xcodebuild -scheme ClipBatcher -configuration Debug -derivedDataPath .build/XcodeDerivedData build

app: build
	@mkdir -p build
	@rm -rf build/ClipBatcher.app
	@cp -R .build/XcodeDerivedData/Build/Products/Debug/ClipBatcher.app build/ClipBatcher.app
	@echo "Created build/ClipBatcher.app"

clean:
	rm -rf .build/XcodeDerivedData build
