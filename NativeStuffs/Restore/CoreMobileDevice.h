//
//  CoreMobileDevice.h
//  iFaith
//
//  Created by Steven De Franco on 30/09/13.
//  Copyright (c) 2013 iH8sn0w. All rights reserved.


#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <mach/error.h>

#define ADNCI_MSG_CONNECTED     1
#define ADNCI_MSG_DISCONNECTED  2
#define ADNCI_MSG_UNKNOWN       3

typedef struct am_recovery_device am_recovery_device;
typedef struct am_device am_device;
typedef struct am_device_notification am_device_notification;

typedef struct am_device_notification_callback_info {
    
    struct am_device *dev;  /* 0    device */
    unsigned int msg;       /* 4    one of ADNCI_MSG_* */

} __attribute__ ((packed)) am_device_notification_callback_info;

typedef void(*am_device_notification_callback)(struct am_device_notification_callback_info *callback_info,
void* arg);

typedef void (*am_restore_device_notification_callback)(struct am_recovery_device *,
                                                        void *arg);

mach_error_t    AMDeviceNotificationSubscribe(am_device_notification_callback callback,
                                           unsigned int unused0,
                                           unsigned int unused1,
                                           void* dn_unknown3,
                                           struct am_device_notification **notification);



mach_error_t    AMDeviceNotificationUnsubscribe(struct am_device_notification *notification);



unsigned int    AMRestoreRegisterForDeviceNotifications
                                                (am_restore_device_notification_callback dfu_connect_callback,
                                                    am_restore_device_notification_callback recovery_connect_callback,
                                                    am_restore_device_notification_callback dfu_disconnect_callback,
                                                    am_restore_device_notification_callback recovery_disconnect_callback,
                                                    unsigned int unknown0,
                                                    void *user_info);



 void AMRestoreUnregisterForDeviceNotifications(void);


mach_error_t    AMDeviceConnect(struct am_device *device);


int             AMDeviceIsPaired(struct am_device *device);


mach_error_t    AMDevicePair(struct am_device *device);


mach_error_t    AMDeviceValidatePairing(struct am_device *device);


mach_error_t    AMDeviceStartSession(struct am_device *device);

mach_error_t AMDeviceStopSession(struct am_device *device);

mach_error_t AMDeviceDisconnect(struct am_device *device);


unsigned int    AMRestoreEnableFileLogging(char *path);


void            AMRestoreSetLogLevel(int level);


void            AMDSetLogLevel(int level);


void            AMDAddLogFileDescriptor(int fd);


CFMutableDictionaryRef AMRestoreCreateDefaultOptions(CFAllocatorRef allocator);
typedef CFMutableDictionaryRef (*AMRestoreCreateDefaultOptionsPtr)(CFAllocatorRef allocator);

NSString *AMDeviceCopyValue(struct am_device *device, unsigned int value, const NSString *cfstring);


uint64_t AMRecoveryModeDeviceGetECID(am_recovery_device *dev);


uint32_t AMRecoveryModeDeviceGetBoardID(am_recovery_device *dev);


uint32_t AMRecoveryModeDeviceGetChipID(am_recovery_device *dev);


uint64_t AMDFUModeDeviceGetECID(am_recovery_device *dev);

uint32_t AMDFUModeDeviceGetBoardID(am_recovery_device *dev);


uint32_t AMDFUModeDeviceGetLocationID(am_recovery_device *dev);


uint32_t AMDFUModeDeviceGetProductID(am_recovery_device *dev);


uint32_t AMDFUModeDeviceGetChipID(am_recovery_device *dev);


int tss_get_partial_hash_from_file(const char *file, int *number, char *out_buffer);

int tss_stitch_img3_from_file_to_file(const char *inFile, void *partialDigest, void *tatsuData, long tatsuLength, const char * outFile);

// AMRESTORE

typedef void *AMRestorableDeviceRef;
typedef void *DFUModeDeviceRef;
typedef void *RecoveryModeDeviceRef;
typedef void *RestoreModeDeviceRef;

int AMRestorableDeviceRegisterForNotifications(void *eventHandler, void *arg, CFErrorRef *err);
int AMRestorableDeviceUnregisterForNotifications(int clientID);

int AMRestorePerformDFURestore(DFUModeDeviceRef device, CFDictionaryRef options,
                               void(*cb)(void *device, int operation, int progress, void *user_info)
                               , void* user_info);
int AMRestorePerformRecoveryModeRestore(RecoveryModeDeviceRef device, CFDictionaryRef options, void(*cb)(void *device, int operation, int progress, void *user_info), void* user_info);
int AMRestorePerformRestoreModeRestore(RestoreModeDeviceRef device, CFDictionaryRef options, void(*cb)(void *device, int operation, int progress, void *user_info), void* user_info);

int AMRestorableDeviceGetState(AMRestorableDeviceRef device);
uint32_t AMRestorableDeviceGetLocationID(AMRestorableDeviceRef device);
uint32_t AMRestorableDeviceGetProductID(AMRestorableDeviceRef device);
uint32_t AMRestorableDeviceGetChipID(AMRestorableDeviceRef device);
uint32_t AMRestorableDeviceGetBoardID(AMRestorableDeviceRef device);
uint64_t AMRestorableDeviceGetECID(AMRestorableDeviceRef device);


DFUModeDeviceRef        AMRestorableDeviceCopyDFUModeDevice(AMRestorableDeviceRef device);
RecoveryModeDeviceRef   AMRestorableDeviceCopyRecoveryModeDevice(AMRestorableDeviceRef device);
RestoreModeDeviceRef    AMRestorableDeviceCopyRestoreModeDevice(AMRestorableDeviceRef device);

CFDictionaryRef AMRestorableDeviceCopyRestoreOptionsFromDocument(CFURLRef file, CFErrorRef *error);
CFDictionaryRef AMRestorableDeviceCopyDefaultRestoreOptions(void);

CFTypeID AMDFUModeDeviceGetTypeID(void);
CFTypeID AMRecoveryModeDeviceGetTypeID(void);
CFTypeID AMRestoreModeDeviceGetTypeID(void);

