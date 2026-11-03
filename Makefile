DEBUG = 0
FINALPACKAGE = 1

ARCHS = arm64 arm64e

# Share the SDK and deployment targets with the PreferenceBundle.
include HuayuarcAppDPIBuild.mk
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HuayuarcAppDPI
HuayuarcAppDPI_FILES = $(wildcard Hooks/*.xm Sources/*.m)
HuayuarcAppDPI_CFLAGS = -fobjc-arc -I./Headers -I./Sources
HuayuarcAppDPI_FRAMEWORKS = UIKit Foundation CoreFoundation QuartzCore
HuayuarcAppDPI_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += HuayuarcAppDPIPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
