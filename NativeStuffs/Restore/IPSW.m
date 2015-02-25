//
//  IPSW.m
//  iFaith
//
//  Created by Steven De Franco on 06/11/2013.
//  Copyright (c) 2013 iH8sn0w. All rights reserved.
//

#import "IPSW.h"

@interface NSString (Additions)

- (BOOL)containsString:(NSString *)theString;

@end

@implementation NSString (Additions)

/*
 
 char -[NSString(Additions) containsString:](void * self, void * _cmd, void * arg2) {
 var_C = self;
 var_10 = _cmd;
 var_14 = arg_8;
 eax = [var_C rangeOfString:arg_8];
 var_1C = var_C;
 var_20 = eax;
 if (var_20 == 0x7fffffff) {
 var_5 = 0x0;
 }
 else {
 var_5 = 0x1;
 }
 eax = sign_extend_32(var_5);
 return eax;
 }
 
 */

- (BOOL)containsString:(NSString *)theString
{
    if ([self rangeOfString:theString].location == NSNotFound)
        return NO;
    
    return YES;
}

@end

#define IF_ERROR_DOMAIN @"ih8sn0w.ifaith.com"

@implementation IPSW
@synthesize path, iBSS, iBEC, kernelcache, rootFS, restorePlist, restoreRAMDisk, NORmanifest, NORfiles, boardConfig, platform, allFlashDirectory, LLB, iBoot, deviceTree, bootLogo, apticket, mountedRAMDisk, firmwareDirectory, productType, productVersion, productBuildVersion;

- (id)initWithPath:(NSString *)_path
{
    self = [super init];
    
    if (self)
    {
        path = _path;
    }
    
    return self;
}

- (BOOL)processIPSWwithError:(out NSError **)error
{
    NSLog(@"processIPSW");
    //LOG_SELF;
    BOOL isDir;
    
    // check ipsw path
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] == NO)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"IPSW was not found at specified path"}];
        }

        return NO;
    }
    
    // check Restore.plist
    
    NSString *restorePlistPath = [path stringByAppendingPathComponent:@"/Restore.plist"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:restorePlistPath isDirectory:&isDir] == NO)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"Restore.plist was not found in IPSW"}];
        }
        
        return NO;
    }
    
    NSData *restorePlistData = [NSData dataWithContentsOfFile:restorePlistPath];
    
    self.restorePlist = [NSPropertyListSerialization propertyListWithData:restorePlistData options:NSPropertyListImmutable format:NULL error:NULL];
    
    if (self.restorePlist == nil)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"Restore.plist could not be fetched"}];
        }
        
        return NO;
    }
   
    self.productBuildVersion = [self.restorePlist valueForKey:@"ProductBuildVersion"];
    self.productVersion = [self.restorePlist valueForKey:@"ProductVersion"];
    self.productType = [self.restorePlist valueForKey:@"ProductType"];
    NSDictionary *deviceMap = [[self.restorePlist valueForKey:@"DeviceMap"] objectAtIndex:0];
    self.boardConfig = [deviceMap valueForKey:@"BoardConfig"];
    self.platform = [deviceMap valueForKey:@"Platform"];
    /*
    self.productBuildVersion = self.restorePlist[@"ProductBuildVersion"];
    self.productVersion = self.restorePlist[@"ProductVersion"];
    self.productType = self.restorePlist[@"ProductType"];
    
    self.boardConfig = self.restorePlist[@"DeviceMap"][0][@"BoardConfig"];
    self.platform = self.restorePlist[@"DeviceMap"][0][@"Platform"];
    */
    if (!self.productBuildVersion || !self.productVersion || !self.productType || !self.boardConfig || !self.platform)
    {
        NSLog(@"%@ %@ %@ %@ %@", self.productBuildVersion, self.productVersion, self.productType, self.boardConfig, self.platform);
        
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"Missing keys in Restore.plist"}];
        }
        
        return NO;
    }
    
    // dfu files
    
    self.iBSS = [self.path stringByAppendingPathComponent:[NSString stringWithFormat:@"/Firmware/dfu/iBSS.%@.RELEASE.dfu", self.boardConfig]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.iBSS isDirectory:&isDir] == NO)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"iBSS was not found in IPSW"}];
        }
        
        return NO;
    }
    
    self.iBEC = [self.path stringByAppendingPathComponent:[NSString stringWithFormat:@"/Firmware/dfu/iBEC.%@.RELEASE.dfu", self.boardConfig]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.iBEC isDirectory:&isDir] == NO)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"iBEC was not found in IPSW"}];
        }
        
        return NO;
    }
    
    // kernelcache
    
    NSString *noApBoardConfig = [self.boardConfig substringWithRange:NSMakeRange(0, self.boardConfig.length-2)];
    
    self.kernelcache = [self.path stringByAppendingPathComponent:[NSString stringWithFormat:@"/kernelcache.release.%@", noApBoardConfig]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.kernelcache isDirectory:&isDir] == NO)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"Kernelcache was not found in IPSW"}];
        }
        
        return NO;
    }
    
    // rootFS
    
   // self.rootFS = [self.path stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", self.restorePlist[@"SystemRestoreImages"][@"User"] ]];
    
    [[self.restorePlist valueForKey:@"SystemRestoreImages"] valueForKey:@"User"];
    
    self.rootFS = [self.path stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", [[self.restorePlist valueForKey:@"SystemRestoreImages"] valueForKey:@"User"]]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.rootFS isDirectory:&isDir] == NO)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"Restore image was not found in IPSW"}];
        }
        
        return NO;
    }
    
    // restore RAMDisk
    
    //self.restoreRAMDisk = [self.path stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", self.restorePlist[@"RestoreRamDisks"][@"User"]]];
    
    self.restoreRAMDisk = [self.path stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", [[self.restorePlist valueForKey:@"RestoreRamDisks"] valueForKey:@"User"]]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.restoreRAMDisk isDirectory:&isDir] == NO)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"Restore RAMDisk was not found in IPSW"}];
        }
        
        return NO;
    }
    
    // all_flash directory
    
    self.allFlashDirectory = [self.path stringByAppendingPathComponent:[NSString stringWithFormat:@"/Firmware/all_flash/all_flash.%@.production", self.boardConfig]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.allFlashDirectory isDirectory:&isDir] == NO)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"all_flash directory was not found in IPSW"}];
        }
        
        return NO;
    }
    
    // NOR manifest
    
    self.NORmanifest = [self.allFlashDirectory stringByAppendingPathComponent:@"/manifest"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.NORmanifest isDirectory:&isDir] == NO)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"NOR manifest was not found in IPSW"}];
        }
        
        return NO;
    }
    
    // norFiles
    
    if ([self analyzeNORManifest] == NO)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"Error while analyzing NOR manifest"}];
        }
        
        return NO;
    }
    
    // LLB
    
   // self.LLB = self.NORfiles[@"LLB"];
    
    self.LLB = [self.NORfiles valueForKey:@"LLB"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.LLB isDirectory:&isDir] == NO)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"LLB was not found in IPSW"}];
        }
        
        return NO;
    }
    
    // iBoot
    
 //   self.iBoot = self.NORfiles[@"iBoot"];
   
    self.iBoot = [self.NORfiles valueForKey:@"iBoot"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.iBoot isDirectory:&isDir] == NO)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"iBoot was not found in IPSW"}];
        }
        
        return NO;
    }
    
    // boot logo
    
    //self.bootLogo = self.NORfiles[@"AppleLogo"];
    
    self.bootLogo = [self.NORfiles valueForKey:@"AppleLogo"];
    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.bootLogo isDirectory:&isDir] == NO)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"Boot logo was not found in IPSW"}];
        }
        
        return NO;
    }
    
    // device tree
    
   // self.deviceTree = self.NORfiles[@"DeviceTree"];
    
    self.deviceTree = [self.NORfiles valueForKey:@"DeviceTree"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.deviceTree isDirectory:&isDir] == NO)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"DeviceTree was not found in IPSW"}];
        }
        
        return NO;
    }
    
    // apticket
    
    //self.apticket = self.NORfiles[@"APTicket"];
    
    self.apticket = [self.NORfiles valueForKey:@"APTicket"];
    
    if (self.apticket && ([[NSFileManager defaultManager] fileExistsAtPath:self.apticket isDirectory:&isDir] == NO) )
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IF_ERROR_DOMAIN code:1 userInfo:@{NSLocalizedDescriptionKey : @"APTicket was not found in IPSW"}];
        }
        
        return NO;
    }
    
    return YES;
}

- (BOOL)analyzeNORManifest
{
    __block BOOL ret = YES;
    NSString *NORManifestContents = [[NSString alloc] initWithContentsOfFile:self.NORmanifest encoding:NSUTF8StringEncoding error:nil];
    
    if (!NORManifestContents)
        return NO;
    
    NSMutableDictionary *norFilesDict = [NSMutableDictionary dictionary];

    [NORManifestContents enumerateLinesUsingBlock:^(NSString *file, BOOL *stop){
        
        NSString *manifestKey = [self getManifestKeyForNorFile:file];
        
        NSString *filePath = [self.allFlashDirectory stringByAppendingPathComponent:file];
        
        if (!filePath || !manifestKey)
        {
            NSLog(@"filepath or manifest keys are nil");
            
            ret = NO;
            *stop = YES;
            return;
        }
        
       // norFilesDict[manifestKey] = filePath;
        
        [norFilesDict setObject:filePath forKey:manifestKey];
        
    }];
    
    
    if (ret)
        self.NORfiles = norFilesDict;
    
    return ret;
}

- (NSString *)getManifestKeyForNorFile:(NSString *)norFile
{
    if ([norFile containsString:@"applelogo"])
        return @"AppleLogo";
    else if ([norFile containsString:@"batterycharging0"])
        return @"BatteryCharging0";
    else if ([norFile containsString:@"batterycharging1"])
        return @"BatteryCharging1";
    else if ([norFile containsString:@"glyphcharging"])
        return @"BatteryCharging";
    else if ([norFile containsString:@"batteryfull"])
        return @"BatteryFull";
    else if ([norFile containsString:@"batterylow0"])
        return @"BatteryLow0";
    else if ([norFile containsString:@"batterylow1"])
        return @"BatteryLow1";
    else if ([norFile containsString:@"glyphplugin"])
        return @"BatteryPlugin";
    else if ([norFile containsString:@"DeviceTree"])
        return @"DeviceTree";
    else if ([norFile containsString:@"iBoot"])
        return @"iBoot";
    else if ([norFile containsString:@"LLB"])
        return @"LLB";
    else if ([norFile containsString:@"recoverymode"])
        return @"RecoveryMode";
    else if ([norFile containsString:@"apticket"])
        return @"APTicket";
    else if ([norFile containsString:@"needservice"])
        return @"NeedService";
    else
        return nil;
}

@end
