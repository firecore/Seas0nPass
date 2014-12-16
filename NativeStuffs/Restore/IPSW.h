//
//  IPSW.h
//  iFaith
//
//  Created by Steven De Franco on 06/11/2013.
//  Copyright (c) 2013 iH8sn0w. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IPSW : NSObject
{
    NSString     *path;
    NSString     *allFlashDirectory;
    NSString     *firmwareDirectory;
    NSDictionary *restorePlist;
    NSString     *productBuildVersion;
    NSString     *productType;
    NSString     *productVersion;
    NSString     *boardConfig;
    NSString     *platform;
    NSString     *iBSS;
    NSString     *iBEC;
    NSString     *kernelcache;
    NSString     *rootFS;
    NSString     *restoreRAMDisk;
    NSString     *mountedRAMDisk;
    NSString     *NORmanifest;
    NSDictionary *NORfiles;
    NSString     *LLB;
    NSString     *iBoot;
    NSString     *deviceTree;
    NSString     *bootLogo;
    NSString     *apticket;
}

@property (retain) NSString     *path;
@property (retain) NSString     *allFlashDirectory;
@property (retain) NSString     *firmwareDirectory;
@property (retain) NSDictionary *restorePlist;
@property (retain) NSString     *productBuildVersion;
@property (retain) NSString     *productType;
@property (retain) NSString     *productVersion;
@property (retain) NSString     *boardConfig;
@property (retain) NSString     *platform;
@property (retain) NSString     *iBSS;
@property (retain) NSString     *iBEC;
@property (retain) NSString     *kernelcache;
@property (retain) NSString     *rootFS;
@property (retain) NSString     *restoreRAMDisk;
@property (retain) NSString     *mountedRAMDisk;
@property (retain) NSString     *NORmanifest;
@property (retain) NSDictionary *NORfiles;
@property (retain) NSString     *LLB;
@property (retain) NSString     *iBoot;
@property (retain) NSString     *deviceTree;
@property (retain) NSString     *bootLogo;
@property (retain) NSString     *apticket;

- (id)initWithPath:(NSString *)path;
- (BOOL)processIPSWwithError:(out NSError **)error;
@end
