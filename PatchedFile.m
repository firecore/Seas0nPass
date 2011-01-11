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

@end
