//
//  PatchedFile.h
//  tetherKit
//
//  Created by Kevin Bradley on 12/30/10.
//  Copyright 2011 Fire Core, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define LOG_SELF NSLog(@"%@ %s", self, _cmd)
#ifndef LocationLog
#define LocationLog(format,...) \
{ \
NSString *file = [[NSString stringWithUTF8String:__FILE__] lastPathComponent]; \
fprintf(stdout, "%s:%d - ", [file UTF8String], __LINE__); \
QuietLog((format),##__VA_ARGS__); \
}
#endif


#define APPLETV_32_DEVICE DeviceIDMake(0, 35143)
#define APPLETV_31_DEVICE DeviceIDMake(8, 35138)
#define APPLETV_21_DEVICE DeviceIDMake(16, 35120)
#define IPAD_11_DEVICE DeviceIDMake(2, 35120)
#define IPAD_21_DEVICE DeviceIDMake(4, 35136)
#define IPAD_22_DEVICE DeviceIDMake(6, 35136)
#define IPAD_23_DEVICE DeviceIDMake(2, 35136)
#define IPHONE_11_DEVICE DeviceIDMake(0, 35072)
#define IPHONE_12_DEVICE DeviceIDMake(4, 35072)
#define IPHONE_21_DEVICE DeviceIDMake(0, 35104)
#define IPHONE_31_DEVICE DeviceIDMake(0, 35120)
#define IPHONE_33_DEVICE DeviceIDMake(6, 35120)
#define IPOD_11_DEVICE DeviceIDMake(2, 35072)
#define IPOD_21_DEVICE DeviceIDMake(0, 34592)
#define IPOD_31_DEVICE DeviceIDMake(2, 35106)
#define IPOD_41_DEVICE DeviceIDMake(8, 35120)

#define APPLETV_32_DEVICE_CLASS @"j33iap"
#define APPLETV_31_DEVICE_CLASS @"j33ap"
#define APPLETV_21_DEVICE_CLASS @"k66ap"

@interface PatchedFile : NSDictionary {
	
	NSString *originalFile;
	NSString *patchFile;
	NSString *md5;
	
}

@property (nonatomic, retain) NSString *originalFile;
@property (nonatomic, retain) NSString *patchFile;
@property (nonatomic, retain) NSString *md5;
-(NSDictionary *)patchDictionary;
@end
