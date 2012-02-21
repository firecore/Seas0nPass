//
//  PatchedFile.m
//  tetherKit
//
//  Created by Kevin Bradley on 12/30/10.
//  Copyright 2011 Fire Core, LLC. All rights reserved.
//

#import "PatchedFile.h"



@implementation PatchedFile

@synthesize originalFile, patchFile, md5;

- (void)dealloc
{
	
	[originalFile release];
	[patchFile release];
	[md5 release];
	
	originalFile = nil;
	patchFile = nil;
	md5 = nil;
	[super dealloc];
}

-(NSDictionary *)patchDictionary
{
	return [NSDictionary dictionaryWithObjectsAndKeys:originalFile, @"inputFile", patchFile, @"patchFile", md5, @"md5", nil];
							
}


void QuietLog (NSString *format, ...) {
    if (format == nil) {
        printf("nil\n");
        return;
    }


		// Get a reference to the arguments that follow the format parameter
    va_list argList;
    va_start(argList, format);
		// Perform format string argument substitution, reinstate %% escapes, then print
    NSString *s = [[NSString alloc] initWithFormat:format arguments:argList];
    fprintf(stdout, "%s\n", [[s stringByReplacingOccurrencesOfString:@"%%" withString:@"%%%%"] UTF8String]);
    [s release];
    va_end(argList);

}

@end
