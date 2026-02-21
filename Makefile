APP = pulse5ctl.app
INSTALL_DIR = /Applications

install:
	swift build -c release
	rm -rf $(INSTALL_DIR)/$(APP)
	mkdir -p $(INSTALL_DIR)/$(APP)/Contents/MacOS
	mkdir -p $(INSTALL_DIR)/$(APP)/Contents/Resources
	cp .build/release/pulse5ctl $(INSTALL_DIR)/$(APP)/Contents/MacOS/
	cp Sources/app/macos/Info.plist $(INSTALL_DIR)/$(APP)/Contents/
	cp -R .build/release/pulse5ctl_CoreLocalization.bundle $(INSTALL_DIR)/$(APP)/Contents/Resources/
	chmod +x $(INSTALL_DIR)/$(APP)/Contents/MacOS/pulse5ctl
