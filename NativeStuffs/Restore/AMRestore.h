//
//  AMRestore.h
//  AMRestore
//
//  Created by Steven De Franco on 10/16/12.
//  Copyright (c) 2012 iH8sn0w. All rights reserved.
//

#ifndef AMRestore_AMRestore_h
#define AMRestore_AMRestore_h

typedef void *AMRestorableDeviceRef;
typedef void *DFUModeDeviceRef;
typedef void *RecoveryModeDeviceRef;
typedef void *RestoreModeDeviceRef;

int AMRestorableDeviceRegisterForNotifications(void (*eventHandler)(AMRestorableDeviceRef device, int event, void *user_info), void *user_info, CFErrorRef *err);
int AMRestorableDeviceUnregisterForNotifications(int clientID);

int AMRestorePerformDFURestore(DFUModeDeviceRef device, CFDictionaryRef options, void(*cb)(void *device, int operation, int progress, void *user_info), void* user_info);
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

#endif
