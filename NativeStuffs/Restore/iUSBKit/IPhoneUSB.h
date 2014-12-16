//
//  IPhoneUSB.h
//  iUSBKit
//
//  Created by iH8sn0w on 9/4/12.
//  Copyright (c) 2012 iH8sn0w. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import "libusb.h"


@interface IPhoneUSB : NSObject
{
    UKDevice* Device;
}
@property (assign) UKDevice* Device;

+ (IPhoneUSB *)sharedInstance;
- (void)start;
- (void)stop;
- (void)notifyDFUConnected;
- (void)notifyRecoveryConnected;
- (void)notifyNormalConnected;
- (void)notifyUploadInProgress:(double)value;
- (void)notifyFileUploadError;
- (void)notifyExploitError;
- (void)notifyIFaithError:(const char*)error;

- (BOOL)isDFUMode;
- (BOOL)isRecoveryMode;

- (int)exploit:(BOOL)mode;
- (int)uploadFile:(NSString *)file;
- (int)uploadData:(NSData *)data;
- (int)getEnv:(NSString *)variable;
- (int)sendCommand:(NSString*)command;
//-(char *)dumpIFaithTo:(NSString*)path;
- (NSDictionary*)dumpBlobs;
- (int)rebootDevice;


@end