export ARCHS = armv7 arm64
export TARGET = iphone:clang:8.1:latest

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PreferredRotation
PreferredRotation_FILES = PRRootListController.m
PreferredRotation_INSTALL_PATH = /Library/PreferenceBundles
PreferredRotation_FRAMEWORKS = UIKit MessageUI
PreferredRotation_PRIVATE_FRAMEWORKS = Preferences
PreferredRotation_LIBRARIES = applist

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PreferredRotation.plist$(ECHO_END)
