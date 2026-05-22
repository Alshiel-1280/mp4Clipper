.PHONY: app debug debug-app project build clean

project:
	xcodegen generate

build: project
	xcodebuild -scheme ClipBatcher -configuration Debug -derivedDataPath .build/XcodeDerivedData build

debug: debug-app

debug-app: build
	@mkdir -p build/Debug
	@rm -rf build/Debug/ClipBatcher.app
	@cp -R .build/XcodeDerivedData/Build/Products/Debug/ClipBatcher.app build/Debug/ClipBatcher.app
	@echo "Created build/Debug/ClipBatcher.app"

app: debug-app
	@rm -rf build/ClipBatcher.app
	@cp -R build/Debug/ClipBatcher.app build/ClipBatcher.app
	@echo "Created build/ClipBatcher.app"

clean:
	rm -rf .build/XcodeDerivedData build
