APP          = Snappy
VERSION     ?= $(shell /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Snappy/Resources/Info.plist 2>/dev/null || echo "0.0.0")
INSTALL      = $(HOME)/Applications
INSTALL_SYS  = /Applications
LSREG        = /System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister

SIGN_IDENTITY  ?= Developer ID Application: Ryo Katsuma (72LKS454FJ)
TEAM_ID        ?= 72LKS454FJ
NOTARY_PROFILE ?= AC_NOTARY
DMG_OUT         = $(APP)-$(VERSION).dmg

.PHONY: build install install-system release-build dmg notarize release clean

build:
	xcodegen generate
	xcodebuild -project $(APP).xcodeproj -scheme $(APP) \
	  -configuration Debug \
	  CODE_SIGN_STYLE=Manual \
	  CODE_SIGN_IDENTITY="$(SIGN_IDENTITY)" \
	  DEVELOPMENT_TEAM=$(TEAM_ID) \
	  CODE_SIGNING_REQUIRED=YES

install:
	$(MAKE) build
	@BUILD_APP=$$(xcodebuild -project $(APP).xcodeproj -scheme $(APP) \
	  -configuration Debug -showBuildSettings 2>/dev/null \
	  | awk -F ' = ' '/^[[:space:]]*BUILT_PRODUCTS_DIR/{print $$2; exit}'); \
	SRC="$$BUILD_APP/$(APP).app"; \
	DST="$(INSTALL)/$(APP).app"; \
	echo "Installing $$SRC → $$DST"; \
	mkdir -p "$(INSTALL)"; \
	rm -rf "$$DST"; \
	cp -R "$$SRC" "$$DST"; \
	$(LSREG) -f "$$DST"; \
	pkill -x $(APP) 2>/dev/null; sleep 0.5; \
	open "$$DST"; \
	echo "Done. Grant Accessibility in System Settings if prompted."

install-system:
	$(MAKE) build
	@BUILD_APP=$$(xcodebuild -project $(APP).xcodeproj -scheme $(APP) \
	  -configuration Debug -showBuildSettings 2>/dev/null \
	  | awk -F ' = ' '/^[[:space:]]*BUILT_PRODUCTS_DIR/{print $$2; exit}'); \
	SRC="$$BUILD_APP/$(APP).app"; \
	DST="$(INSTALL_SYS)/$(APP).app"; \
	echo "Installing $$SRC → $$DST (requires sudo)"; \
	sudo rm -rf "$$DST"; \
	sudo cp -R "$$SRC" "$$DST"; \
	sudo $(LSREG) -f "$$DST"; \
	pkill -x $(APP) 2>/dev/null; sleep 0.5; \
	open "$$DST"; \
	echo "Done. Grant Accessibility in System Settings if prompted."

release-build:
	xcodegen generate
	rm -rf build
	xcodebuild archive -project $(APP).xcodeproj -scheme $(APP) \
	  -configuration Release \
	  -archivePath build/$(APP).xcarchive \
	  CODE_SIGN_STYLE=Manual \
	  CODE_SIGN_IDENTITY="$(SIGN_IDENTITY)" \
	  DEVELOPMENT_TEAM=$(TEAM_ID)
	xcodebuild -exportArchive \
	  -archivePath build/$(APP).xcarchive \
	  -exportPath build/export \
	  -exportOptionsPlist ExportOptions.plist
	codesign --verify --deep --strict --verbose=2 "build/export/$(APP).app"

dmg:
	$(MAKE) release-build
	@command -v create-dmg >/dev/null 2>&1 || { echo "create-dmg not found. Install with: brew install create-dmg"; exit 1; }
	rm -f "$(DMG_OUT)"
	create-dmg \
	  --volname "$(APP)" \
	  --window-size 540 380 \
	  --icon-size 128 \
	  --icon "$(APP).app" 140 160 \
	  --app-drop-link 400 160 \
	  "$(DMG_OUT)" \
	  "build/export/$(APP).app"
	codesign --sign "$(SIGN_IDENTITY)" --timestamp "$(DMG_OUT)"
	codesign --verify --verbose=2 "$(DMG_OUT)"
	@echo "Created $(DMG_OUT)"

notarize:
	@if [ -n "$$NOTARY_API_KEY_PATH" ] && [ -n "$$NOTARY_KEY_ID" ] && [ -n "$$NOTARY_ISSUER_ID" ]; then \
	  xcrun notarytool submit "$(DMG_OUT)" \
	    --key "$$NOTARY_API_KEY_PATH" --key-id "$$NOTARY_KEY_ID" --issuer "$$NOTARY_ISSUER_ID" \
	    --wait; \
	else \
	  xcrun notarytool submit "$(DMG_OUT)" --keychain-profile "$(NOTARY_PROFILE)" --wait; \
	fi
	xcrun stapler staple "$(DMG_OUT)"
	spctl -a -t open --context context:primary-signature -v "$(DMG_OUT)"

release: dmg notarize
	@echo "Release-ready: $(DMG_OUT)"

clean:
	-pkill -x $(APP) 2>/dev/null
	tccutil reset Accessibility com.katsuma.$(APP)
	rm -rf "$(INSTALL)/$(APP).app"
	-sudo rm -rf "$(INSTALL_SYS)/$(APP).app" 2>/dev/null
	@echo "Uninstalled."
