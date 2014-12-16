//
//  IPSWRestore.h
//  iFaith
//
//  Created by Steven De Franco on 10/16/12.
//  Copyright (c) 2012 iH8sn0w. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreMobileDevice.h"
#import "IPSW.h"

#define RESTORABLE_CONNECTED 0
#define RESTORABLE_DISCONNECTED 1

#define IDLE_STATE 0
#define SUCCESS_STATE 1
#define ERROR_STATE 2
#define DISAPPEARED_STATE 3
#define TRANSITIONING_STATE 4
#define RESTORING_STATE 5

//#import "CoreMobileDevice.h"

/*
struct __DeviceProxy {
	void *device; // 0 ; AMXXXModeDeviceRef
	int unknwn4; // (char in IDA) 4
	char unknwn[4]; // 8
	CFStringRef (*CopyBoardConfig)(struct __DeviceProxy *prox, CFDictionaryRef deviceMap);
	unsigned int (*GetLocationID)(struct __DeviceProxy *prox);
	unsigned long long (*GetECID)(struct __DeviceProxy *prox);
	unsigned int (*GetState)(struct __DeviceProxy *prox);
	//unsigned int (*Restore)(struct DeviceProxy *prox, CFDictionaryRef bootOptions, void ()
};
                                                                                         
struct __RestorableDevice {
        //CFRuntimeBase base; 		// 0
                                    // 8
        //DeviceProxyRef deviceProxy	// 12
};
                                                                                         
    */

/*
 
 AMRestorable
 
 */
/*
typedef void *AMRestorableDeviceRef;

int AMRestorableDeviceRegisterForNotifications(void (*eventHandler)(AMRestorableDeviceRef, int, void *), void *refCon, CFErrorRef *err);

int AMRestorableDeviceUnregisterForNotifications(int clientID);

uint8_t AMRestorableDeviceRestore(AMRestorableDeviceRef device,
                                  int clientID,
                                  CFDictionaryRef options,
                                  void (*callback)(AMRestorableDeviceRef device, CFDictionaryRef data, void *arg),
                                  void *unk5,
                                  CFErrorRef *error);

int AMRestorableDeviceGetState(AMRestorableDeviceRef device);
 */


@interface IPSWRestore : NSObject
{
    IPSW         *ipsw;
    NSDictionary *restoreInfo;
    int          dfuCycles;
    int          recoveryCycles;
    int          restoreCycles;
    int          currentState;
    int          clientID;
    BOOL         isListening;
    CFBundleRef  mdfBundle;
    BOOL         isiTunes111Plus;
}

@property (strong) IPSW         *ipsw;
@property (strong) NSDictionary *restoreInfo;
@property (assign) int          dfuCycles;
@property (assign) int          recoveryCycles;
@property (assign) int          restoreCycles;
@property (assign) int          currentState;
@property (assign) int          clientID;
@property (assign) BOOL         isListening;
@property (assign) CFBundleRef  mdfBundle;
@property (assign) BOOL         isiTunes111Plus;

- (id)initWithIPSW:(IPSW *)ipsw andECID:(NSString *)ecid;
- (void)startListening;
- (void)stopListening;

void iFaithStateMachineSetState(AMRestorableDeviceRef device, int state);


void eventHandler(AMRestorableDeviceRef device, int event, void *refCon);
void progress_callback(void *device, int operation, int progress, void *user_info);
void postProgressEvent(NSDictionary *info);

void iFaithStateMachineDoRestore(AMRestorableDeviceRef device);
void iFaithStateMachineHandleRestoreComplete(AMRestorableDeviceRef device);

bool deviceIsTheOne(AMRestorableDeviceRef device);
void handleNewDevice(AMRestorableDeviceRef device);
void handleKnownDevice(AMRestorableDeviceRef device);
void handleDisconnectedDevice(AMRestorableDeviceRef device);

void cancelTimer();

int restoreDFUMode(AMRestorableDeviceRef device);
int restoreRecoveryMode(AMRestorableDeviceRef device);
int restoreRestoreMode(AMRestorableDeviceRef device);

int dfuMode();
int recoveryMode();
int restoreMode();

NSDictionary * getBootOptions();

@end

