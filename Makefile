APP          = Snappy
VERSION     ?= $(shell /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Snappy/Resources/Info.plist 2>/dev/null || echo "0.0.0")
INSTALL      = $(HOME)/Applications
INSTALL_SYS  = /Applications
LSREG        = /System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister

.PHONY: build install install-system zip clean

build:
	xcodegen generate
	xcodebuild -project $(APP).xcodeproj -scheme $(APP) \
	  -configuration Debug \
	  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=YES

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

zip:
	xcodegen generate
	xcodebuild -project $(APP).xcodeproj -scheme $(APP) \
	  -configuration Release \
	  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=YES
	@BUILD_APP=$$(xcodebuild -project $(APP).xcodeproj -scheme $(APP) \
	  -configuration Release -showBuildSettings 2>/dev/null \
	  | awk -F ' = ' '/^[[:space:]]*BUILT_PRODUCTS_DIR/{print $$2; exit}'); \
	SRC="$$BUILD_APP/$(APP).app"; \
	OUT="$(APP)-$(VERSION).zip"; \
	echo "Archiving $$SRC → $$OUT"; \
	ditto -c -k --sequesterRsrc --keepParent "$$SRC" "$$OUT"; \
	echo "Created $$OUT"

clean:
	-pkill -x $(APP) 2>/dev/null
	tccutil reset Accessibility com.katsuma.$(APP)
	rm -rf "$(INSTALL)/$(APP).app"
	-sudo rm -rf "$(INSTALL_SYS)/$(APP).app" 2>/dev/null
	@echo "Uninstalled."
