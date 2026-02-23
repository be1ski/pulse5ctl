APP = pulse5ctl.app
INSTALL_DIR = /Applications

checkAll: checkSwift checkPython

checkSwift: lintSwift
	swift test

lintSwift:
	swiftlint lint --strict

checkPython:
	cd cli && pip install -e . pytest pytest-asyncio ruff -q && ruff check pulse5/ tests/ && pytest

installGitHooks:
	@mkdir -p .git/hooks
	@echo '#!/bin/bash' > .git/hooks/pre-commit
	@echo '' >> .git/hooks/pre-commit
	@echo 'echo "Running pre-commit checks..."' >> .git/hooks/pre-commit
	@echo '' >> .git/hooks/pre-commit
	@echo 'if ! make checkAll; then' >> .git/hooks/pre-commit
	@echo '  echo ""' >> .git/hooks/pre-commit
	@echo '  echo "Pre-commit verification failed. Please fix the issues above before committing."' >> .git/hooks/pre-commit
	@echo '  exit 1' >> .git/hooks/pre-commit
	@echo 'fi' >> .git/hooks/pre-commit
	@echo '' >> .git/hooks/pre-commit
	@echo 'echo "Pre-commit verification passed."' >> .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "Git hooks installed."

package:
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/{MacOS,Resources}
	cp .build/release/pulse5ctl $(APP)/Contents/MacOS/
	cp Sources/app/macos/Info.plist $(APP)/Contents/
	cp Sources/app/macos/AppIcon.icns $(APP)/Contents/Resources/
	cp -R .build/release/pulse5ctl_CoreLocalization.bundle $(APP)/
	chmod +x $(APP)/Contents/MacOS/pulse5ctl

install:
	-killall pulse5ctl 2>/dev/null
	swift build -c release
	$(MAKE) package
	rm -rf $(INSTALL_DIR)/$(APP)
	mv $(APP) $(INSTALL_DIR)/$(APP)
