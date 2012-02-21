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
#import "TSSManager.h"
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
		//NSString *option = [NSString stringWithUTF8String:argv[i]];
		NSString *value = [NSString stringWithUTF8String:argv[i+1]]; //plist location
		
			//[phc sendCommand:value];
		
		NSDictionary *pDict = [NSDictionary dictionaryWithContentsOfFile:value];
		NSArray *keys = [pDict allKeys];
		if ([keys containsObject:@"bundle"]) //we are processing fw bundle
		{
			pwnHelperClass *phc = [[pwnHelperClass alloc] init];
			FWBundle *cBundle = (FWBundle *)[FWBundle bundleWithPath:[pDict valueForKey:@"bundle"]];
			[phc setCurrentBundle:cBundle];
			[phc setProcessDict:pDict];
			[phc setRunPath:path];
			int returnStatus = [phc patchDmg:[pDict valueForKey:@"patch"]];
			
			[phc release];
			phc = nil;
			
			[pool release];
			return returnStatus;
		} 
		
		
			//if we get this far we are processing local blobs instead! 
		NSArray *blobs = [pDict valueForKey:@"blobs"];
		TSSManager *theMan = [[TSSManager alloc] init];
		[theMan _sendBlobs:blobs];
		
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"blobsFinished" object:nil userInfo:nil deliverImmediately:YES];
		[theMan release];
		
		[pool release];
		
		return 0;
		

	}
		
	[rl run];
	
	
    [pool release];
    return 0;
}


