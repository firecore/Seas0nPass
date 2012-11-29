//
//  nitoUtility.h
//  Seas0nPass
//
//  Created by Kevin Bradley on 3/20/09.
//  Copyright 2009 nito, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PatchedFile.h"
#import "FWBundle.h"
#import "NSData+Flip.h"

#define XPWN [[NSBundle mainBundle] pathForResource:@"xpwntool" ofType:@"" inDirectory:@"bin"]
#define IMAGE_TOOL [[NSBundle mainBundle] pathForResource:@"imagetool" ofType:@"" inDirectory:@"bin"]
#define VFDECRYPT [[NSBundle mainBundle] pathForResource:@"vfdecrypt" ofType:@"" inDirectory:@"bin"]
#define CYDIA_TAR [[NSBundle mainBundle] pathForResource:@"Cydia" ofType:@"tgz" inDirectory:@"archives"]
#define SPACE_SCRIPT [[NSBundle mainBundle] pathForResource:@"space" ofType:@"sh" inDirectory:@"scripts"]
#define DEB_PATH [[NSBundle mainBundle] pathForResource:@"debs" ofType:@""]

#define HDIUTIL @"/usr/bin/hdiutil"
#define ASR @"/usr/sbin/asr"
#define BSPATCH @"/usr/bin/bspatch"
#define FM [NSFileManager defaultManager]
#define TMP_ROOT @"/private/tmp/tk"
#define IPSW_TMP @"/private/tmp/tk/ipsw"



enum{
	kDMGReadWrite = 0,
	kDMGReadOnly = 1,
	
};

@interface nitoUtility : NSObject {
	
	id delegate;
	BOOL enableScripting;
	BOOL sigServer;
    BOOL debWhitelist;
	NSString *sshKey;
	FWBundle *currentBundle;
	int restoreMode;
	

}
@property (readwrite, assign) BOOL enableScripting;
@property (readwrite, assign) BOOL sigServer;
@property (readwrite, assign) BOOL debWhitelist;
@property (readwrite, assign) int restoreMode;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSString *sshKey;
@property (nonatomic, assign) FWBundle *currentBundle;


- (void)failedWithReason:(NSString *)theReason;
+ (int)patchFile:(NSString *)patchFile withPatch:(NSString *)thePatch toLocation:(NSString *)endLocationFile inWorkingDirectory:(NSString *)theDir;
+ (int)gunzip:(NSString *)inputFile;
+ (BOOL)hasFirmware;
+ (NSString *)firmwareFolder;
+ (BOOL)validateFile:(NSString *)inputFile withChecksum:(NSString *)checksum;
+ (float)sizeFreeOnMountedPath:(NSString *)theDevice;
+ (int)linkFile:(NSString *)theFile toPath:(NSString *)thePath inWorkingDirectory:(NSString *)theDir;
+ (int)bunZip:(NSString *)inputTar toRoot:(NSString *)toLocation excluding:(NSString *)excludeFile;
+ (int)extractGZip:(NSString *)inputTar toRoot:(NSString *)toLocation;
+ (int)bunZip:(NSString *)inputTar toRoot:(NSString *)toLocation;
+ (int)extractGZip:(NSString *)inputTar toLocation:(NSString *)toLocation;
+ (BOOL)unzipFile:(NSString *)theFile toPath:(NSString *)newPath;
+ (int)extractTar:(NSString *)inputTar toLocation:(NSString *)toLocation;

+ (NSDictionary *)fsImageInfo:(NSString *)inputFilesystem;
- (NSString *)filesystemResizeValue:(NSString *)inputFilesystem;
- (NSString *)ramdiskResizeValue:(NSString *)inputRD;
+ (int)mountImageSimple:(NSString *)irString;
+ (void)unmountVolume:(NSString *)theVolume;
+ (NSString *)mountImage:(NSString *)irString;
+ (BOOL)checkFile:(NSString *)inputFile againstMD5:(NSString *)properMD5;
+ (int)scanForRestore:(NSString *)drivepath;
+ (int)resizeVolume:(NSString *)theVolume toSize:(NSString *)theSize;

+ (void)changeOwner:(NSString *)theOwner onFile:(NSString *)theFile isRecursive:(BOOL)isR;
+ (void)changePermissions:(NSString *)perms onFile:(NSString *)theFile isRecursive:(BOOL)isR;
+ (int)cleanupRamdisk;
+ (int)patchFile:(NSString *)patchFile withPatch:(NSString *)thePatch endMD5:(NSString *)desiredMD5;
+ (int)decryptRamdisk:(NSString *)theRamdisk toPath:(NSString *)outputDisk withIV:(NSString *)iv key:(NSString *)key;
+ (int)repackRamdisk:(NSString *)theRamdisk toPath:(NSString *)outputDisk withIV:(NSString *)iv key:(NSString *)key originalPath:(NSString *)original;
+ (int)decryptFilesystem:(NSString *)fileSystem withKey:(NSString *)fileSystemKey;
+ (NSString *)convertImage:(NSString *)irString toFile:(NSString *)outputFile toMode:(int)theMode;
+ (int)patchIBSS:(NSString *)ibssFile;
- (void)patchFilesystem:(NSString *)inputFilesystem;
- (NSString *)pwnctionaryFromPath:(NSString *)mountedPath original:(NSString *)original withBundle:(FWBundle *)theBundle;
- (void)permissionedPatch:(NSString *)theFile withOriginal:(NSString *)originalDMG;
+ (int)migrateFiles:(NSArray *)migration toPath:(NSString *)finalPath;
+ (void)createTempSetup;
- (int)patchRamdisk:(NSString *)theRamdisk;
+ (int)runScript:(NSString *)theScript withInput:(NSString *)theInput;
+ (int)createIPSWToFile:(NSString *)theName;
+(int)decryptedPatchFromData:(NSDictionary *)patchData atRoot:(NSString *)rootPath fromBundle:(NSString *)bundlePath;
- (int)performPatchesFromBundle:(FWBundle *)theBundle onRamdisk:(NSDictionary *)ramdiskDict;
+(int)decryptImage:(NSString *)theImage toPath:(NSString *)finalPath withIV:(NSString *)iv key:(NSString *)key;
+(int)decryptedImageFromData:(NSDictionary *)patchData atRoot:(NSString *)rootPath fromBundle:(NSString *)bundlePath;
+ (NSString *)applicationSupportFolder;
@end
