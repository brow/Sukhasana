APP=build/Release/Sukhasana.app

$(APP):
	carthage bootstrap --platform Mac
	xcodebuild -configuration Release

install: $(APP)
	cp -r $(APP) /Applications

clean:
	rm -rf build
