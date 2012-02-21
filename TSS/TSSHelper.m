/*
 TSSHelper.m
 TSSAgent
 
 Written by Kevin Bradley
 
 
 */


#import <Foundation/Foundation.h>
#include <sys/types.h>
#include <unistd.h>
#import "TSSCommon.h"
#import "TSSManager.h"
#import "TSSWorker.h"

int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	//LogIt(@"argc: %i\n", argc);
	setuid(0);
	int i;
	
	if (argc <= 1)
	{
		LogIt(@"\n");
		LogIt(@"AppleTV TSSAgent - a standalone solution for listing SHSH blobs, fetching SHSH blobs and submitting the blobs to saurik's SHSH server.\n\n");
		LogIt(@"Currently this is targeted for the AppleTV but it could definitely be expanded to work with other devices, not that it's necessary.\n\n");
		LogIt(@"-l \t\t\t lists all the SHSH blobs that are currently saved on sauriks server.\n");
		LogIt(@"-v osBuildVersion \t fetches the SHSH blobs for version specified from apples servers. ie -v 8F455.\n");
		LogIt(@"-p osBuildVersion \t fetch the SHSH blob for the version specified AND pushes to sauriks server.\n");
		LogIt(@"-1337 \t\t\t will fetch the versions that are still elgible to be signed and push them to sauirks server.\n\n");
		return -1;
			  
	}
	
	NSString *value = nil;
	//for (i = 0; i < argc; i++){
		

		NSString *path = [NSString stringWithUTF8String:argv[0]];
		NSString *option = [NSString stringWithUTF8String:argv[1]];
	if (argc >= 3)
		value = [NSString stringWithUTF8String:argv[2]];
		//NSLog(@"path: %@", path);
	//	NSLog(@"option: %@", option);
	//	NSLog(@"value: %@", value);
		if ([option isEqualToString:@"-l"]) //list
		{
			TSSManager *man = [[TSSManager alloc] initWithMode:kTSSCydiaBlobListingSolo];
			NSArray *blobs = [man _synchronousBlobCheck];
			[man autorelease];
			
			LogIt(@"%@", blobs);
			[pool release];
			return 0;
			
		} else if ([option isEqualToString:@"-v"]) //fetch version
		{
			if (value == nil)
			{
				LogIt(@"\nYou must specify a version number!\n\n");
				return -1;
			}
			
			TSSManager *man = [[TSSManager alloc] initWithMode:kTSSFetchBlobFromApple];
			NSString *theBlob = [man _synchronousReceiveVersion:value];
			[man autorelease];
			
			LogIt(@"%@", theBlob);
			
			[pool release];
			return 0;
			
		} else if ([option isEqualToString:@"-p"]) { //push version
			
			if (value == nil)
			{
				LogIt(@"\nYou must specify a version number!\n\n");
				return -1;
			}
			
			TSSManager *man = [[TSSManager alloc] initWithMode:kTSSFetchBlobFromApple];
			NSString *theBlob = [man _synchronousReceiveVersion:value];
			
			LogIt(@"%@", theBlob);
			
			NSString *push = [man _synchronousPushBlob:theBlob];
			
			
			[man autorelease];
			
			
			
			[pool release];
			return 0;
			
		} else if ([option isEqualToString:@"-1337"])
		{
			LogIt(@"\n");
			TSSWorker *worker = [[TSSWorker alloc] init];
			[worker theWholeShebang];
			
			[worker autorelease];
			
			[pool release];
			
			return 0;
			
		}
	//}
	
	[pool release];
    return 0;
}

void LogIt (NSString *format, ...)
{
    va_list args;
	
    va_start (args, format);
	
    NSString *string;
	
    string = [[NSString alloc] initWithFormat: format  arguments: args];
	
    va_end (args);
	
    printf ("%s", [string UTF8String]);
	
    [string release];
	
} // LogIt