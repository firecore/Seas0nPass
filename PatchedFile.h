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
