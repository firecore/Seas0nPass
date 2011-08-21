GO_EASY_ON_ME=1
FW_DEVICE_IP=kbtv2.local
export SDKVERSION=4.3
TOOL_NAME := SPHelper
SPHelper_FILES = SPHelper.m SPHelperClass.m
SPHelper_PACKAGE_TARGET_DIR = /usr/bin
SPHelper_LDFLAGS = -framework Foundation #-framework BackRow

include theos/makefiles/common.mk
include theos/makefiles/tool.mk

after-SPHelper-stage::
	$(FAKEROOT) chmod 6755 $(FW_STAGING_DIR)/usr/bin/SPHelper
	mkdir -p ../_/usr/bin/
	$(FAKEROOT) cp $(FW_STAGING_DIR)/usr/bin/SPHelper ../_/usr/bin/SPHelper
	$(FAKEROOT) chmod 6755 ../_/usr/bin/SPHelper