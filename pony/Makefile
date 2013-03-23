export GO_EASY_ON_ME=1
export SDKVERSION=4.3
export FW_DEVICE_IP=apple-tv.local
export THEOS_DEVICE_IP=apple-tv.local

include theos/makefiles/common.mk

TWEAK_NAME = apocalypsePony
apocalypsePony_FILES = apocalypsePony.xm
apocalypsePony_LDFLAGS = -undefined dynamic_lookup
include $(FW_MAKEDIR)/tweak.mk

after-apocalypsePony-stage::
	$(FAKEROOT) chown -R root:wheel $(FW_STAGING_DIR)
