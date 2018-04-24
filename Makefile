export ARCHS = armv7 arm64
export TARGET = iphone:clang:9.3:latest

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PreferredRotation
PreferredRotation_FILES = Tweak.xm
PreferredRotation_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += preferredrotation
include $(THEOS_MAKE_PATH)/aggregate.mk
