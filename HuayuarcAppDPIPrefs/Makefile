include ../HuayuarcAppDPIBuild.mk
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = HuayuarcAppDPIPrefs
HuayuarcAppDPIPrefs_FILES = $(wildcard *.m)
HuayuarcAppDPIPrefs_CFLAGS = -fobjc-arc -I../Sources
HuayuarcAppDPIPrefs_FRAMEWORKS = UIKit Foundation CoreFoundation
HuayuarcAppDPIPrefs_PRIVATE_FRAMEWORKS = Preferences
HuayuarcAppDPIPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
