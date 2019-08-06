LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := Chromium
LOCAL_MODULE_CLASS := APPS
LOCAL_MULTILIB := both
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_REQUIRED_MODULES := \
	libwebviewchromium_loader \
	libwebviewchromium_plat_support

LOCAL_MODULE_TARGET_ARCH := arm64
my_src_arch := $(call get-prebuilt-src-arch,$(LOCAL_MODULE_TARGET_ARCH))
LOCAL_SRC_FILES := prebuilt/$(my_src_arch)/MonochromePublic.apk

include $(BUILD_PREBUILT)
