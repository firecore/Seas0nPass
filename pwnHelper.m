//
//  nitoFlowHelper.m
//  Seas0nPass
//
//  Created by Kevin Bradley on 2/20/07.
//  Copyright 2007 nito, LLC. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "pwnHelperClass.h"
#import "FWBundle.h"
#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>




int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];	
	
	NSRunLoop *rl = [NSRunLoop currentRunLoop];
	
	if (argc < 2){
	
	}
	int i;
	for (i = 1; i < (argc - 1); i+= 2){
		NSString *path = [NSString stringWithUTF8String:argv[0]];
		NSString *option = [NSString stringWithUTF8String:argv[i]];
		NSString *value = [NSString stringWithUTF8String:argv[i+1]]; //plist location
		pwnHelperClass *phc = [[pwnHelperClass alloc] init];
		NSDictionary *pDict = [NSDictionary dictionaryWithContentsOfFile:value];
		FWBundle *cBundle = [FWBundle bundleWithPath:[pDict valueForKey:@"bundle"]];
		[phc setCurrentBundle:cBundle];
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


