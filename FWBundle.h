//
//  FWBundle.h
//  tetherKit
//
//  Created by Kevin Bradley on 1/14/11.
//  Copyright 2011 FireCore, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

	//#import "tetherKitAppDelegate.h" //such bad form!!! #lazy

#define FS_PATCHES @"FilesystemPatches"
#define FS_JB @"Filesystem Jailbreak"
#define FW_PATCHES @"FirmwarePatches"
#define RD_PATCHES @"RamdiskPatches"
#define PREINST_PACKAGES @"PreInstalledPackages"
#define RS_MOUNT @"RestoreRamdiskMountVolume"
#define ROOT_FS @"RootFilesystem"
#define FS_KEY @"RootFilesystemKey"
#define FILE_NAME @"Filename"
#define BUNDLE_NAME @"Name"
#define UPDATE_RD @"Update Ramdisk"
#define RESTORE_RD @"Restore Ramdisk"
#define MOUNTED_RAMDISK @"RestoreRamdiskMountVolume"
#define CORE_FILES @"Core Files Installation"

enum  {
	
	kAppleTVDevice,
	kiPadDevice,
	kiPhoneDevice,
	kUnknownDevice,
};

@interface FWBundle : NSBundle	{

	NSString *fwRoot;
}

@property (nonatomic, retain) NSString *fwRoot;

+ (FWBundle *)bundleWithName:(NSString *)bundleName;
+ (FWBundle *)bundleForFile:(NSString *)theFile;
- (void)logDescription;
- (NSDictionary *)coreFilesInstallation;
- (NSDictionary	*)filesystemPatches;
- (NSArray *)filesystemJailbreak;
- (NSDictionary *)firmwarePatches;
- (NSDictionary *)ramdiskPatches;
- (NSDictionary *)preInstalledPackages;
- (NSDictionary *)iBSS;
- (NSDictionary *)restoreRamdisk;
- (NSDictionary *)updateRamdisk;
- (NSString *)rootFilesystem;
- (NSString *)filesystemKey;
- (NSString *)filename;
- (NSString *)restoreRamdiskFile;
- (NSString *)restoreRamdiskVolume;
- (NSString *)updateRamdiskFile;
- (NSString *)bundleName;
- (NSDictionary *)extraPatch;
- (NSString *)ramdiskSize;
- (NSString *)outputName;
- (NSDictionary *)appleLogo;
- (NSString *)filesystemSize;
- (NSDictionary *)kernelcache;

	//really lazy convenience classes
- (NSDictionary *)buildManifest;
- (NSString *)localKernel;
- (NSString *)localiBSS;
- (NSString *)localiBEC;
- (NSString *)kernelCacheName;
- (NSString *)iBSSName;
- (NSDictionary *)fwDictionary;
- (NSString *)localBundlePath;

- (BOOL)is4point3;
- (BOOL)is4point4;
- (BOOL)untethered;
@end

/*

 2011-01-15 16:03:42 - Loaded .ipsw file from '/Users/kevinbradley/Desktop/AppleTV/AppleTV2,1_4.3_8F5148c_Restore.ipsw'.
 2011-01-15 16:03:46 - Recognized .ipsw file as AppleTV2,1_4.3_8F5148c.
 ------------------------------
 2011-01-15 16:03:58 - Unzipping .ipsw file to /tmp/ipsw.
 2011-01-15 16:04:05 - OK
 2011-01-15 16:04:05 - Patching iBSS.
 2011-01-15 16:04:05 - OK
 2011-01-15 16:04:08 - Updating Restore Ramdisk.
 2011-01-15 16:04:08 - OK
 2011-01-15 16:04:10 - Converting root filesystem to UDRW image.
 2011-01-15 16:04:33 - OK
 2011-01-15 16:04:33 - Resizing root filesystem to 855m.
 2011-01-15 16:04:35 - OK
 2011-01-15 16:04:35 - Attaching root filesystem to '/Volumes/DurangoVail8F5148c.K66DeveloperOS'.
 2011-01-15 16:04:37 - OK
 2011-01-15 16:04:37 - Making Core Files Installation.
 2011-01-15 16:04:37 - OK
 2011-01-15 16:04:37 - Making Filesystem Jailbreak.
 2011-01-15 16:04:41 - OK
 2011-01-15 16:04:41 - Adding Cydia Installer custom package.
 2011-01-15 16:04:53 - OK
 2011-01-15 16:04:53 - Detaching root filesystem from '/Volumes/DurangoVail8F5148c.K66DeveloperOS'.
 2011-01-15 16:04:54 - OK
 2011-01-15 16:04:54 - Converting root filesystem to UDZO image.
 2011-01-15 16:06:13 - OK
 2011-01-15 16:06:13 - Scanning root filesystem with ASR.
 2011-01-15 16:06:21 - OK
 2011-01-15 16:06:21 - Zipping .ipsw file.
 
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
 <key>FilesystemPatches</key>
 <dict>
 <key>Filesystem Jailbreak</key>
 <array>
 <dict>
 <key>Action</key>
 <string>Patch</string>
 <key>File</key>
 <string>etc/fstab</string>
 <key>Name</key>
 <string>Filesystem Write Access</string>
 <key>Patch</key>
 <string>fstab.patch</string>
 </dict>
 </array>
 </dict>
 <key>FirmwarePatches</key>
 <dict>
 <key>Restore Ramdisk</key>
 <dict>
 <key>File</key>
 <string>018-9940-004.dmg</string>
 <key>IV</key>
 <string>bab07889e0d5ba26521e7f141e213178</string>
 <key>Key</key>
 <string>3e88b3dfbb432a60d3475ebee8570c83c52612465f4db7686f62415f4b6e1bdd</string>
 <key>TypeFlag</key>
 <integer>8</integer>
 </dict>
 <key>iBSS</key>
 <dict>
 <key>File</key>
 <string>Firmware/dfu/iBSS.k66ap.RELEASE.dfu</string>
 <key>IV</key>
 <string>03baadf8801e8b7cdcee5a9f53609d0c</string>
 <key>Key</key>
 <string>c9f8bd4e52530ec8ef3e2b5926777f624061a38d09f07785287de6e88353f752</string>
 <key>Patch</key>
 <string>iBSS.k66ap.RELEASE.patch</string>
 <key>TypeFlag</key>
 <integer>8</integer>
 </dict>
 </dict>
 <key>RamdiskPatches</key>
 <dict>
 <key>asr</key>
 <dict>
 <key>File</key>
 <string>usr/sbin/asr</string>
 <key>Patch</key>
 <string>asr.patch</string>
 </dict>
 </dict>
 <key>PreInstalledPackages</key>
 <array>
 <string>org.saurik.cydia-atv</string>
 </array>
 <key>DeleteBuildManifest</key>
 <false/>
 <key>RestoreRamdiskMountVolume</key>
 <string>ramdisk</string>
 <key>RootFilesystem</key>
 <string>018-7744-116.dmg</string>
 <key>RootFilesystemSize</key>
 <integer>770</integer>
 <key>RootFilesystemKey</key>
 <string>fd73cd898b7e55f9dc24092a4c574f1f284087075520a7d30232b0b6af8871743a0f0b82</string>
 <key>RootFilesystemMountVolume</key>
 <string>Jasper8C150.K66OS</string>
 <key>SHA1</key>
 <string>58f9ab479783dad3dff3834452abc2917aaef2a5</string>
 <key>Filename</key>
 <string>AppleTV2,1_4.2_8C150_Restore.ipsw</string>
 <key>Name</key>
 <string>AppleTV2,1_4.2_8C150</string>
 <key>DownloadUrl</key>
 <string></string>
 <key>Platform</key>
 <integer>3</integer>
 <key>SubPlatform</key>
 <integer>10</integer>
 </dict>
 </plist>
 

*/