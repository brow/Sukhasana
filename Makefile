APP=build/Release/Sukhasana.app

$(APP):
	xcodebuild -configuration Release

install: $(APP)
	cp -r $(APP) /Applications

clean:
	rm -rf build
