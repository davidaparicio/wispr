# wispr — Developer Makefile
#
# Handy targets for inspecting and cleaning local app data.

BUNDLE_ID    := com.stormacq.mac.wispr
CONTAINER    := $(HOME)/Library/Containers/$(BUNDLE_ID)/Data
MODEL_DIR    := $(CONTAINER)/Library/Application Support/wispr

SCHEME       := wispr
XCODEPROJ    := wispr.xcodeproj
ARCHIVE_PATH := $(CURDIR)/build/wispr.xcarchive
EXPORT_DIR   := $(CURDIR)/build/export

# App Store Connect API key (read from secrets/asc-api-key.json)
SECRETS_JSON   := $(CURDIR)/secrets/asc-api-key.json
API_KEYS_DIR   := $(CURDIR)/private_keys
API_KEY_ID     := $(shell jq -r .apple_api_key_id $(CURDIR)/secrets/asc-api-key.json 2>/dev/null)
API_ISSUER     := $(shell jq -r .apple_api_issuer_id $(CURDIR)/secrets/asc-api-key.json 2>/dev/null)
API_KEY_PATH   := $(API_KEYS_DIR)/AuthKey_$(API_KEY_ID).p8

.PHONY: help bump-build archive upload brew-release brew-clean list-downloads clean-downloads list-container list-prefs clean-prefs reset-permissions reset-login-item reset-onboarding

_setup-api-key:
	@test -f "$(SECRETS_JSON)" || { echo "Error: $(SECRETS_JSON) not found"; exit 1; }
	@mkdir -p $(API_KEYS_DIR)
	@jq -r .apple_api_key $(SECRETS_JSON) | base64 -d > $(API_KEY_PATH)

_cleanup-api-key:
	@rm -f $(API_KEY_PATH)

bump-build: ## Set build number (CFBundleVersion) to git commit count
	$(eval BUILD_NUM := $(shell git rev-list --count HEAD))
	@xcrun agvtool new-version -all $(BUILD_NUM) > /dev/null
	@echo "Build number set to $(BUILD_NUM)"

archive: bump-build ## Bump build number and create Release archive (version is unchanged)
	xcodebuild -project $(XCODEPROJ) -scheme $(SCHEME) -configuration Release \
		-archivePath $(ARCHIVE_PATH) archive | xcbeautify

upload: archive _setup-api-key ## Archive and upload to App Store Connect
	xcodebuild -exportArchive \
		-archivePath $(ARCHIVE_PATH) \
		-exportPath $(EXPORT_DIR) \
		-exportOptionsPlist ExportOptions.plist \
		-allowProvisioningUpdates \
		-authenticationKeyPath $(API_KEY_PATH) \
		-authenticationKeyID $(API_KEY_ID) \
		-authenticationKeyIssuerID $(API_ISSUER) | xcbeautify
	@$(MAKE) _cleanup-api-key

brew-clean: ## Clean up existing release tags and GitHub release (usage: make brew-clean VERSION=1.0.0)
	@test -n "$(VERSION)" || { echo "Usage: make brew-clean VERSION=1.0.0"; exit 1; }
	$(eval TAG := v$(VERSION))
	@echo "🧹 Cleaning up release $(TAG)..."
	@git tag -d $(TAG) 2>/dev/null || true
	@git push --no-verify --delete origin $(TAG) 2>/dev/null || true
	@gh release delete $(TAG) --yes 2>/dev/null || true
	@echo "✅ Cleanup complete"

brew-release: ## Create Homebrew cask release (usage: make brew-release VERSION=1.0.0)
	@test -n "$(VERSION)" || { echo "Usage: make brew-release VERSION=1.0.0"; exit 1; }
	@test -d "../homebrew-macos" || { echo "Error: ../homebrew-macos not found"; exit 1; }
	@command -v gh >/dev/null || { echo "Error: gh CLI not installed"; exit 1; }
	$(eval TAG := v$(VERSION))
	$(eval APP_NAME := Wispr.app)
	$(eval ZIP_NAME := wispr-$(VERSION).zip)
	$(eval BUILD_NUM := $(shell git rev-list --count HEAD))
	@echo "📝 Setting version to $(VERSION) (build $(BUILD_NUM))..."
	@xcrun agvtool new-marketing-version $(VERSION) > /dev/null
	@xcrun agvtool new-version -all $(BUILD_NUM) > /dev/null
	@echo "🏗️  Building Release archive..."
	@xcodebuild -project $(XCODEPROJ) -scheme $(SCHEME) -configuration Release \
		-archivePath $(ARCHIVE_PATH) \
		DEVELOPMENT_TEAM=56U756R2L2 \
		archive | xcbeautify
	@echo "📦 Exporting app..."
	@xcodebuild -exportArchive -archivePath $(ARCHIVE_PATH) \
		-exportPath $(EXPORT_DIR) -exportOptionsPlist ExportOptionsHomebrew.plist | xcbeautify
	@echo "🗜️  Creating zip..."
	@cd $(EXPORT_DIR) && zip -r -X $(ZIP_NAME) $(APP_NAME)
	@echo "🏷️  Creating GitHub release..."
	@git tag $(TAG) || true
	@git push --no-verify origin $(TAG) || true
	@gh release create $(TAG) --generate-notes $(EXPORT_DIR)/$(ZIP_NAME) || \
		gh release upload $(TAG) $(EXPORT_DIR)/$(ZIP_NAME)
	$(eval URL := https://github.com/sebsto/wispr/releases/download/$(TAG)/$(ZIP_NAME))
	@echo "🍺 Generating cask..."
	@echo "cask \"wispr\" do" > wispr.rb
	@echo "  version \"$(VERSION)\"" >> wispr.rb
	@echo "  sha256 \"$$(shasum -a 256 $(EXPORT_DIR)/$(ZIP_NAME) | awk '{print $$1}')\"" >> wispr.rb
	@echo "" >> wispr.rb
	@echo "  url \"$(URL)\"" >> wispr.rb
	@echo "  name \"Wispr\"" >> wispr.rb
	@echo "  desc \"Local speech-to-text transcription powered by OpenAI Whisper\"" >> wispr.rb
	@echo "  homepage \"https://github.com/sebsto/wispr\"" >> wispr.rb
	@echo "" >> wispr.rb
	@echo "  app \"Wispr.app\"" >> wispr.rb
	@echo "end" >> wispr.rb
	@echo "📦 Updating homebrew tap..."
	@cd ../homebrew-macos && git pull --rebase origin main
	@mkdir -p ../homebrew-macos/Casks
	@cp wispr.rb ../homebrew-macos/Casks/
	@cd ../homebrew-macos && git add Casks/wispr.rb && \
		git commit -m "Update wispr to $(VERSION)" && \
		git push --no-verify origin main
	@rm -f wispr.rb
	@echo "✅ Release $(VERSION) complete!"

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

list-downloads: ## List downloaded Whisper models in the sandbox container
	@if [ -d "$(MODEL_DIR)" ]; then \
		echo "Downloaded models in $(MODEL_DIR):"; \
		du -sh "$(MODEL_DIR)"/models/argmaxinc/whisperkit-coreml/*/ 2>/dev/null || echo "  (none)"; \
	else \
		echo "No model directory found at $(MODEL_DIR)"; \
	fi

clean-downloads: ## Delete all downloaded Whisper models from the sandbox container
	@if [ -d "$(MODEL_DIR)" ]; then \
		echo "Removing $(MODEL_DIR) …"; \
		rm -rf "$(MODEL_DIR)"; \
		echo "Done."; \
	else \
		echo "Nothing to clean — $(MODEL_DIR) does not exist."; \
	fi

list-container: ## Inspect the sandbox container directory
	@if [ -d "$(CONTAINER)" ]; then \
		echo "Sandbox container at $(CONTAINER):"; \
		ls -la "$(CONTAINER)/Library/Application Support/wispr/" 2>/dev/null || echo "  (empty or missing)"; \
	else \
		echo "No sandbox container found at $(CONTAINER)"; \
	fi

list-prefs: ## Show current UserDefaults for the app
	@defaults read $(BUNDLE_ID) 2>/dev/null || echo "No preferences found for $(BUNDLE_ID)."

clean-prefs: ## Delete all UserDefaults for the app
	@echo "Removing preferences for $(BUNDLE_ID) …"
	@defaults delete $(BUNDLE_ID) 2>/dev/null || true
	@echo "Done."

reset-permissions: ## Reset microphone and accessibility permissions for the app
	@echo "Resetting Microphone permission …"
	@tccutil reset Microphone $(BUNDLE_ID) 2>/dev/null || true
	@echo "Resetting Accessibility permission …"
	@tccutil reset Accessibility $(BUNDLE_ID) 2>/dev/null || true
	@echo "Done. Restart the app to be prompted again."

reset-login-item: ## Reset Background Task Management database (clears all login items)
	@echo "Resetting BTM database (clears all SMAppService login items) …"
	@sfltool resetbtm 2>/dev/null || true
	@echo "Done. The app will no longer launch at login."

reset-onboarding: ## Full onboarding reset (permissions + prefs + models + login item)
	@echo "=== Full onboarding reset ==="
	@$(MAKE) -s reset-permissions
	@$(MAKE) -s clean-prefs
	@$(MAKE) -s clean-downloads
	@$(MAKE) -s reset-login-item
	@echo "=== Ready to re-test onboarding ==="
