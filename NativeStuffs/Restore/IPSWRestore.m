//
//  IPSWRestore.m
//  iFaith
//
//  Created by Steven De Franco on 10/16/12.
//  Copyright (c) 2012 iH8sn0w. All rights reserved.
//

#import "IPSWRestore.h"
#import "IPhoneUSB.h"

#define LIBUSBRESTORE_DOMAIN @"com.ifaith.libusbrestore"
#define VERBOSE_LOG

void *functionIniTunes11Only = NULL;

dispatch_source_t timer_source = NULL;

int currentState = 0;
int dfuCycles = 2;
int recoveryCycles = 1;
int restoreCycles = 1;
BOOL deviceIsNew = YES;
NSString *ipswPath = nil;
NSString *iBSS = nil;
NSString *iBEC = nil;
NSString *ecid = nil;
NSError *restoreError = nil;
NSMutableDictionary *bootOptions = nil;


@implementation IPSWRestore
@synthesize ipsw,
clientID,
isListening,
mdfBundle,
isiTunes111Plus,
restoreInfo,
dfuCycles,
recoveryCycles,
restoreCycles,
currentState;


- (id)initWithIPSW:(IPSW *)_ipsw andECID:(NSString *)_ecid
{
    self = [super init];
    
    if (self)
    {
        ipsw = _ipsw;
        ecid = _ecid;
        
        ipswPath = ipsw.path;
        iBSS = ipsw.iBSS;
        iBEC = ipsw.iBEC;
        
        bootOptions = [NSMutableDictionary dictionaryWithDictionary:getBootOptions()];
        [bootOptions setObject:ipswPath forKey:@"RestoreBundlePath"];
        [bootOptions setObject:iBSS forKey:@"DFUFile"];
        // bootOptions[@"RestoreBundlePath"] = ipswPath;
        //bootOptions[@"DFUFile"] = iBSS;
        [bootOptions retain];
        [self loadMDF];
        [self iTunes111Plus];
        
        
    }
    
    return self;

}

- (BOOL)iTunes111Plus
{
    functionIniTunes11Only = CFBundleGetFunctionPointerForName(self.mdfBundle, CFSTR("AMRestorableDeviceCopyRestoreModeDevice"));
    
    if (functionIniTunes11Only == NULL)
    {
        NSLog(@"iTunes version is < 11.1");
        
        self.isiTunes111Plus = NO;
        
        return NO;
    
    } else
    {
        NSLog(@"iTunes version is => 11.1");
        
        self.isiTunes111Plus = YES;
        
        
        return YES;
    }
}

- (BOOL)loadMDF
{
    
    CFURLRef mdfURL = CFURLCreateWithString(kCFAllocatorDefault, CFSTR("/System/Library/PrivateFrameworks/MobileDevice.framework"), NULL);
    
    CFBundleRef bundle = CFBundleCreate(kCFAllocatorDefault, mdfURL);
    
    CFRelease(mdfURL);
    
    if (bundle == NULL)
    {
        NSLog(@"failed creating bundle ref");
        return NO;
    }
    
    
    mdfBundle = bundle;
    
    return YES;
    
}


-(void)dealloc
{
    if (self.isListening)
        [self stopListening];
    
    [super dealloc];
}
- (void)startListening
{
    if (self.isListening) return;
    
    
    CFErrorRef error;
   
#ifdef VERBOSE_LOG
    AMDSetLogLevel(INT_MAX);
    AMDAddLogFileDescriptor(1);
    AMRestoreSetLogLevel(INT_MAX);
    AMRestoreEnableFileLogging("/dev/stderr");
#endif
     self.clientID = AMRestorableDeviceRegisterForNotifications(eventHandler, (__bridge void *)self, &error);
    
    if (self.clientID > 0)
    {
        self.isListening = YES;
        
    } else
    {
        
        NSLog(@"CFError: %ld / %@", (long)((__bridge NSError*)error).code, ((__bridge NSError*)error).localizedDescription);
    }
}

- (void)stopListening
{
    [bootOptions release];
    bootOptions = nil;
    AMRestorableDeviceUnregisterForNotifications(self.clientID);
    self.clientID = 0;
    self.isListening = NO;
}

void postProgressEvent(NSDictionary *info)
{
    dispatch_async(dispatch_get_main_queue(), ^{
    
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RestoreProgress" object:nil userInfo:info];
    });
    
}

void iFaithStateMachineSetState(AMRestorableDeviceRef device, int state)
{
    // 5: Restoring , 4: Transitioning, 3: Disappeared, 2: Error, 1: Success, 0: Idle
    
    currentState = state;
    
    switch (state) {
        case IDLE_STATE:
            break;
        case SUCCESS_STATE:
            
            iFaithStateMachineHandleRestoreComplete(device);
            break;
        case ERROR_STATE:
            iFaithStateMachineHandleRestoreComplete(device);
            break;
        case DISAPPEARED_STATE:
            iFaithStateMachineHandleRestoreComplete(device);
            break;
        case TRANSITIONING_STATE:
            
            cancelTimer();
            
            timer_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, NULL, 0, dispatch_get_main_queue());
            
            dispatch_source_set_event_handler_f(timer_source, timerFired);
            
            dispatch_set_context(timer_source, device);
            
            dispatch_source_set_timer(timer_source, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 30),  0, 0);
            
            dispatch_resume(timer_source);
            
            break;
        case RESTORING_STATE:
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                iFaithStateMachineDoRestore(device);
            });
            
            break;
            
        default:
            
            iFaithStateMachineSetState(device, ERROR_STATE);
            break;
    }
}

void timerFired(void *context)
{
    AMRestorableDeviceRef device = (AMRestorableDeviceRef)context;
    
    iFaithStateMachineSetState(device, DISAPPEARED_STATE);
}

void cancelTimer()
{
    if (timer_source)
    {
        dispatch_source_cancel(timer_source);
        dispatch_release(timer_source);
        timer_source = NULL;
    }
}

void iFaithStateMachineDoRestore(AMRestorableDeviceRef device)
{
    if (device == NULL)
    {
        NSLog(@"device == NULL");
        iFaithStateMachineSetState(device, ERROR_STATE);
        return;
    }
    
    int deviceMode = AMRestorableDeviceGetState(device);
    
    if (deviceMode == dfuMode()) {
        
        int code = restoreDFUMode(device);
        
        if (code != 0)
        {
            iFaithStateMachineSetState(device, ERROR_STATE);
        }
        
    } else if (deviceMode == recoveryMode())
    {
        int code = restoreRecoveryMode(device);
        
        if (code != 0)
        {
            iFaithStateMachineSetState(device, ERROR_STATE);
        }
        
    } else if (deviceMode == restoreMode())
    {
        int code = restoreRestoreMode(device);
        
        if (code != 0)
        {
            iFaithStateMachineSetState(device, ERROR_STATE);
        
        } else
        {
            iFaithStateMachineSetState(device, SUCCESS_STATE);
        }
        
    } else {
        
        NSLog(@"Unknown mode: %d", deviceMode);
    }
}

int restoreDFUMode(AMRestorableDeviceRef device)
{
    DFUModeDeviceRef dfuDevice = AMRestorableDeviceCopyDFUModeDevice(device);
    
    if (dfuDevice)
    {
        if (dfuCycles == 2)
        {
            dfuCycles--;
            
        } else if (dfuCycles == 1)
        {
            dfuCycles--;
            
            [bootOptions setObject:iBEC forKey:@"DFUFile"];
            //bootOptions[@"DFUFile"] = iBEC;
        
        } else {
            
            NSLog(@"Expected recovery mode. Found DFU mode instead.");
            return -1;
            
        }
        
        return AMRestorePerformDFURestore(dfuDevice, (CFDictionaryRef)(bootOptions), progress_callback, NULL);
        
        
    } else {
        
        return  -1;
    }
}

int restoreRecoveryMode(AMRestorableDeviceRef device)
{
    
    RecoveryModeDeviceRef recoveryDevice = AMRestorableDeviceCopyRecoveryModeDevice(device);
    
    if (recoveryDevice)
    {
        if (recoveryCycles == 1)
        {
            recoveryCycles--;
            
            return AMRestorePerformRecoveryModeRestore(recoveryDevice, (__bridge CFDictionaryRef)(bootOptions), progress_callback, NULL);
            
        } else {
            
            return -1;
        }
    
    } else {
        
        return -1;
    }
    
    
}

int restoreRestoreMode(AMRestorableDeviceRef device)
{
    RestoreModeDeviceRef restoreDevice = AMRestorableDeviceCopyRestoreModeDevice(device);
    
    if (restoreDevice)
    {
        if (restoreCycles == 1)
        {
            restoreCycles--;
            
            return AMRestorePerformRestoreModeRestore(restoreDevice, (__bridge CFDictionaryRef)(bootOptions), progress_callback, NULL);
        
        } else
        {
            return -1;
        }
    
    } else {
        
        return -1;
    }
}

void iFaithStateMachineHandleRestoreComplete(AMRestorableDeviceRef device)
{
    cancelTimer();
    
    if (currentState == 1)
    {
        NSDictionary *info = @{@"Status" : @"Successful", @"Operation" : @(-1), @"Progress" : @(-1)};
        
        postProgressEvent(info);
        
    } else if (currentState == 2)
    {
        
        if (restoreError == NULL)
            restoreError = createRestoreErrorWithString(@"Unknown restore error.");
        
        NSDictionary *info = @{@"Status" : @"Failed", @"Operation" : @(-1), @"Progress" : @(-1), @"Error" : restoreError};
        
        postProgressEvent(info);
    }
    else if (currentState == 3)
    {
        
        NSError *error = createRestoreErrorWithString(@"Device disappeared.");
        
        NSDictionary *info = @{@"Status" : @"Failed", @"Operation" : @(-1), @"Progress" : @(-1), @"Error" : error};
        
        postProgressEvent(info);
        
    } else {
        
        NSError *error = createRestoreErrorWithString(@"State machine not in final state.");
        
        NSDictionary *info = @{@"Status" : @"Failed", @"Operation" : @(-1), @"Progress" : @(-1), @"Error" : error};
        
        postProgressEvent(info);
        
    }
}

void handleNewDevice(AMRestorableDeviceRef device)
{
    NSLog(@"handleNewDevice");
    if (currentState != IDLE_STATE)
    {
        NSLog(@"Device is already being restored");
        return;
    }
    
    deviceIsNew = NO;
    
    iFaithStateMachineSetState(device, RESTORING_STATE);
}

void handleKnownDevice(AMRestorableDeviceRef device)
{
    NSLog(@"handleKnownDevice");
    
    
    if (currentState == TRANSITIONING_STATE)
    {
        cancelTimer();
        
        iFaithStateMachineSetState(device, RESTORING_STATE);
    }
    else
    {
        NSLog(@"Device added from invalid state");
        
        iFaithStateMachineSetState(device, ERROR_STATE);
    }
}

void handleDisconnectedDevice(AMRestorableDeviceRef device)
{
    
    NSLog(@"handleDisconnectedDevice");
    

    if (currentState == RESTORING_STATE)
    {
        iFaithStateMachineSetState(device, TRANSITIONING_STATE);
    
    }
    
}

void eventHandler(AMRestorableDeviceRef device, int event, void *refCon)
{
    NSLog(@"eventHandler");
    
    if (event == RESTORABLE_CONNECTED)
    {
        if (deviceIsTheOne(device)) {
            
            if (deviceIsNew)
            {
                handleNewDevice(device);
            }
            else
            {
                handleKnownDevice(device);
            }
        }
    }
    else if (event == RESTORABLE_DISCONNECTED)
    {
        if (deviceIsTheOne(device))
        {
            handleDisconnectedDevice(device);
        }
    }
}

void progress_callback(void *device, int operation, int progress, void *user_info)
{
   //    NSLog(@"progress_callback");
    CFTypeID deviceTypeID = CFGetTypeID(device);
    
    NSMutableDictionary *info = [@{@"Status" : @"Restoring", @"Operation" : @(operation), @"Progress" : @(progress)} mutableCopy];
    
    if (deviceTypeID == AMDFUModeDeviceGetTypeID())
    {
        [info setObject:@"DFU" forKey:@"DeviceMode"];
      //  info[@"DeviceMode"] = @"DFU";
        
    } else if (deviceTypeID == AMRecoveryModeDeviceGetTypeID())
    {
        //info[@"DeviceMode"] = @"Recovery";
        
        [info setObject:@"Recovery" forKey:@"DeviceMode"];
        
    } else if (deviceTypeID == AMRestoreModeDeviceGetTypeID())
    {
        //info[@"DeviceMode"] = @"RestoreOS";
         [info setObject:@"RestoreOS" forKey:@"DeviceMode"];
    } else {
        
        NSLog(@"Unknown device type ID");
        return;
    }
    
    postProgressEvent(info);
    
}

bool deviceIsTheOne(AMRestorableDeviceRef device)
{
    if (device == NULL)
    {
        NSLog(@"device == NULL");
        return false;
    }
    
    unsigned long long _ecid = AMRestorableDeviceGetECID(device);
    NSString *ecidString = [NSString stringWithFormat:@"%llu", _ecid];
    
    return ([ecid isEqualToString:ecidString]) ? true : false;
}

NSDictionary* getBootOptions()
{
    
        NSDictionary *bootOptions = @{@"IsLegacy" : @YES, // legacy FTW !!!
                                      @"RestoreBootArgs" : @"rd=md0 nand-enable-reformat=1 -progress",
                                      @"CreateFilesystemPartitions" : @YES,
                                      @"UpdateBaseband" : @NO,
                                      @"FlashNOR" : @YES,
                                      @"NORImageType" : @"production",
                                      @"DFUFileType" : @"RELEASE",
                                      @"KernelCacheType" : @"Release",
                                      @"SystemImageType" : @"User",
                                      @"BootImageType" : @"User",
                                      @"RestoreBundlePath" : @"",
                                      @"DFUFile" : @""};
        
        return bootOptions;
        
 //    }
}

NSError *getRestoreErrorForCode(int code)
{
    return [NSError errorWithDomain:LIBUSBRESTORE_DOMAIN code:code userInfo:@{NSLocalizedDescriptionKey : @"Failed to restore device."}];
}

NSError *createRestoreErrorWithString(NSString *error)
{

    return [NSError errorWithDomain:LIBUSBRESTORE_DOMAIN code:-1 userInfo:@{NSLocalizedDescriptionKey : error}];

}
                          
int dfuMode()
{
    return (functionIniTunes11Only) ? 1 : 0;
}


int recoveryMode()
{
    return (functionIniTunes11Only) ? 2 : 1;
}

int restoreMode()
{
    return (functionIniTunes11Only) ? 3 : 2;
}

@end

