SIMULATOR_ID = 94C6E24B-5AD7-4465-BF85-3F560FE3F1FE
SCHEME       = SceneTalk
PROJECT      = SceneTalk.xcodeproj
DEST         = platform=iOS Simulator,id=$(SIMULATOR_ID)

.PHONY: gen test build run clean

## Regenerate Xcode project from project.yml (run after adding/removing source files)
gen:
	xcodegen generate

## Regenerate project then run all tests
test: gen
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
	  -destination '$(DEST)' -configuration Debug \
	  test 2>&1 | xcpretty || xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
	  -destination '$(DEST)' -configuration Debug test

## Build only (no tests)
build: gen
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
	  -destination '$(DEST)' -configuration Debug \
	  build

## Build and launch on the iPad simulator (boots it if needed)
run: gen
	xcrun simctl boot $(SIMULATOR_ID) 2>/dev/null || true
	open -a Simulator
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
	  -destination '$(DEST)' -configuration Debug build
	@APP=$$(xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
	  -destination '$(DEST)' -configuration Debug \
	  -showBuildSettings 2>/dev/null \
	  | awk -F' = ' '/^ *BUILT_PRODUCTS_DIR /{dir=$$2} /^ *FULL_PRODUCT_NAME /{name=$$2} END{print dir"/"name}'); \
	BUNDLE=$$(xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
	  -destination '$(DEST)' -configuration Debug \
	  -showBuildSettings 2>/dev/null \
	  | awk -F' = ' '/^ *PRODUCT_BUNDLE_IDENTIFIER /{print $$2}'); \
	echo "Installing $$APP"; \
	xcrun simctl install $(SIMULATOR_ID) "$$APP"; \
	echo "Launching $$BUNDLE"; \
	xcrun simctl launch $(SIMULATOR_ID) "$$BUNDLE"

## Clean derived data
clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
