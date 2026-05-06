SIMULATOR_ID = 94C6E24B-5AD7-4465-BF85-3F560FE3F1FE
SCHEME       = SceneTalk
PROJECT      = SceneTalk.xcodeproj
DEST         = platform=iOS Simulator,id=$(SIMULATOR_ID)

.PHONY: gen test build clean

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

## Clean derived data
clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
