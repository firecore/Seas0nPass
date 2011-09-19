//
//  pwnHelperClass.h
//  Seas0nPass
//
//  Created by Kevin Bradley on 4/16/09.
//  Copyright 2009 nito, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PatchedFile.h"
#import "FWBundle.h"

@interface pwnHelperClass : NSObject {
	NSString *runPath;
	NSString *theDownloadPath;
	NSDictionary *processDict;
	FWBundle *currentBundle;

}
@property (nonatomic, assign) FWBundle *currentBundle;
- (int)permissionedCopy:(NSString *)inputFile toPath:(NSString *)outputFile;
- (NSDictionary *)processDict;
- (void)setProcessDict:(NSDictionary *)value;
- (int)patchDmg:(NSString *)theDMG;
- (void)changeStatus:(NSString *)theStatus;
- (NSString *)runPath;
- (void)setRunPath:(NSString *)value;
- (void)installPackages:(NSString *)theDMG;
- (NSString *)theDownloadPath;
- (BOOL)enableAssistiveDevices;
- (int)fileSystemPatches:(NSString *)theVolume;
- (int)performAction:(NSDictionary *)actionDict onVolume:(NSString *)theVolume;
- (int)patchAction:(NSDictionary *)actionDict toVolume:(NSString *)theVolume;
- (int)addAction:(NSDictionary *)actionDict toVolume:(NSString *)theVolume;
- (int)ownerAction:(NSDictionary *)actionDict toVolume:(NSString *)theVolume;
- (int)permissionAction:(NSDictionary *)actionDict toVolume:(NSString *)theVolume;
- (int)extractAction:(NSDictionary *)actionDict toVolume:(NSString *)theVolume;
- (void)useCydiaServer;
- (int)disableBetaExpiry:(NSString *)theVolume;
@end
