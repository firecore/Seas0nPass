//
//  TSSWorker.m
//  TSSAgent
//
//  Created by Kevin Bradley on 1/22/12.
//  Copyright 2012 nito, LLC. All rights reserved.
//

#import "TSSWorker.h"
#import "FWBundle.h"

@implementation TSSWorker

@synthesize savedBuilds, queueNumber, currentIndex, currentBuild, queuedBuilds, ecid;

void WorkLog (NSString *format, ...)
{
    va_list args;
	
    va_start (args, format);
	
    NSString *string;
	
    string = [[NSString alloc] initWithFormat: format  arguments: args];
	
    va_end (args);
	
    printf ("%s", [string UTF8String]);
	
    [string release];
	
} // LogIt


- (NSString *)getVersionTicket:(NSString *)theVersion
{

	if (self.ecid == nil)
	{
		NSLog(@"no ecid found!, bail!");
		return nil;
	}
	TSSManager *man = [[TSSManager alloc] initWithECID:self.ecid];
	NSString *theBlob = [man _synchronousCydiaReceiveVersion:theVersion];
	NSDictionary *theDict = [man dictionaryFromString:theBlob];
	NSString *tmpFile = @"/private/tmp/test.plist";
	[theDict writeToFile:tmpFile atomically:YES];
	return [TSSManager apTicketFileFromDictionary:theDict];

}

- (NSString *)getAppleVersionTicket:(NSString *)theVersion
{
	
	if (self.ecid == nil)
	{
		NSLog(@"no ecid found!, bail!");
		return nil;
	}
	TSSManager *man = [[TSSManager alloc] initWithECID:self.ecid];
	NSString *theBlob = [man _synchronousReceiveVersion:theVersion];
	NSLog(@"theBlobl: %@", theBlob);
	NSDictionary *theDict = [man dictionaryFromString:theBlob];
	NSString *tmpFile = @"/private/tmp/test.plist";
	[theDict writeToFile:tmpFile atomically:YES];
	return [TSSManager apTicketFileFromDictionary:theDict];

}

- (void)sendLocalBlobs
{
	
}



- (void)theWholeShebang
{
	/*
	 
	 1. grab available blob listing from cydia
	 2. get signing list from wherever
	 3. cycle through filtered array grabbing blob from apple then sending to cydia
	
	 */

	TSSManager *man = [[TSSManager alloc] initWithECID:self.ecid];
	
	WorkLog(@"synchronous blob check...\n\n");
	
	NSArray *blobs = [man _synchronousBlobCheck];
	
	WorkLog(@"filtering list...\n\n");
	NSArray *filteredList = [self filteredList:blobs];
	
	WorkLog(@"processing versions...\n\n");
	
	for (id fw in filteredList)
	{
		WorkLog(@"fetching version: %@...\n\n", fw);
		
		NSString *theBlob = [man _synchronousReceiveVersion:fw];
		
		WorkLog(@"pushing version: %@...\n\n", fw);
		
		NSString *returns = [man _synchronousPushBlob:theBlob];
		
		WorkLog(@"%@\n\n", returns);
	}
	
	[man autorelease];
	
	WorkLog(@"Done!!\n\n");
	
}



- (NSArray *)filteredList:(NSArray *)signedFW
{
	NSMutableArray *fetchList = [[NSMutableArray alloc] init];
	NSArray *avail = [TSSManager signableVersions]; //the versions we still report that can be signed from apple, from a plist we maintain
	NSArray *trimmedList = [TSSWorker buildsFromList:signedFW]; //this SHOULD cut the array down to single string objects of JUST the "build" key
	
	//	NSLog(@"trimmedList: %@", trimmedList);
	
	for (id currentFW in avail)
	{
		//see if the trimmed list contains our current build, if it does, dont add, otherwise, add.
		
		if (![trimmedList containsObject:currentFW])
		{
			[fetchList addObject:currentFW];
		}
		
	}
	
	return [fetchList autorelease];
}



+ (NSArray *)buildsFromiFaithList:(NSArray *)ifaithList
{
	NSMutableArray *newArray = [[NSMutableArray alloc] init];
	for (NSString *theFw in ifaithList)
	{//4.1 (8B117)
		NSArray *newSplit = [theFw componentsSeparatedByString:@"("]; //@"4.1 ", @"8B117)"
		NSString *buildPre = [newSplit lastObject];
		NSString *buildClip = [buildPre substringToIndex:([buildPre length]-1)]; //clip off the }
			//NSLog(@"buildClip %@", buildClip);
		[newArray addObject:buildClip];
	}
	
	return [newArray autorelease];
}


/*
 
 
 board = 16;
 build = 8C150;
 chip = 35120;
 firmware = "4.2";
 model = "AppleTV2,1";
 
 
 */

+ (NSArray *)buildsFromList:(NSArray *)theList
{
	//LOG_SELF
	NSMutableArray *newArray = [[NSMutableArray alloc] init];
	
	for (id theItem in theList)
	{
		NSString *build = [theItem valueForKey:@"build"];
		[newArray addObject:build];
	}
	
	return [newArray autorelease];
}




- (void)dealloc
{
	[savedBuilds release];
	[currentBuild release];
	[super dealloc];
}


@end
