//
//  nitoFlowHelper.m
//  Seas0nPass
//
//  Created by Kevin Bradley on 2/20/07.
//  Copyright 2007 nito, LLC. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "pwnHelperClass.h"
#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>




int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];	
	
	NSRunLoop *rl = [NSRunLoop currentRunLoop];
	
		//	[rl configureAsServer];
	if (argc < 2){
		//printf("\nUsage: nitoFlowHelper: --dictPath dictPath\n");
		//printf("\n");
	}
	int i;
	for (i = 1; i < (argc - 1); i+= 2){
		NSString *path = [NSString stringWithUTF8String:argv[0]];
			//NSString *option = [NSString stringWithUTF8String:argv[i]]; //uuencode string later
		NSString *value = [NSString stringWithUTF8String:argv[i+1]]; //plist location
		pwnHelperClass *phc = [[pwnHelperClass alloc] init];
		NSDictionary *pDict = [NSDictionary dictionaryWithContentsOfFile:value];
		[phc setProcessDict:pDict];
		[phc setRunPath:path];
		[phc patchDmg:[pDict valueForKey:@"patch"]];
		[pool release];
		return 0;
	}
		
	[rl run];
	
	
    [pool release];
    return 0;
}


