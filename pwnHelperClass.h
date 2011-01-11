//
//  pwnHelperClass.h
//  Seas0nPass
//
//  Created by Kevin Bradley on 4/16/09.
//  Copyright 2009 nito, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PatchedFile.h"

@interface pwnHelperClass : NSObject {
	NSString *runPath;
	NSString *theDownloadPath;
	NSDictionary *processDict;

}

- (int)permissionedCopy:(NSString *)inputFile toPath:(NSString *)outputFile;
- (NSDictionary *)processDict;
- (void)setProcessDict:(NSDictionary *)value;
- (void)patchDmg:(NSString *)theDMG;
- (void)changeStatus:(NSString *)theStatus;
- (NSString *)runPath;
- (void)setRunPath:(NSString *)value;
- (void)installPackages:(NSString *)theDMG;
- (NSString *)theDownloadPath;
- (BOOL)enableAssistiveDevices;

@end
