//
//  TSSManager.mm
//  TSSAgent
//
//  Created by Kevin Bradley on 1/16/12.
//  Copyright 2012 nito, LLC. All rights reserved.
//

//#import "MSettingsController.h"

#import "TSSManager.h"
#import <IOKit/IOKitLib.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <sys/types.h>
#import "TSSCommon.h"
#import "TSSWorker.h"
#import "nitoUtility.h"
#import "../include/libpois0n.h"

static NSString *myChipID_ = nil;


@implementation TSSManager

@synthesize baseUrlString, delegate, _returnDataAsString, ecid, mode, theDevice, deviceModel;



/*
 
 [{"model": "AppleTV2,1", "chip": 35120, "firmware": "4.2", "board": 16, "build": "8C150"}, {"model": "AppleTV2,1", "chip": 35120, "firmware": "4.2.1", "board": 16, "build": "8C154"}, {"model": "AppleTV2,1", "chip": 35120, "firmware": "4.3", "board": 16, "build": "8F191m"}, {"model": "AppleTV2,1", "chip": 35120, "firmware": "4.3.1", "board": 16, "build": "8F202"}, {"model": "AppleTV2,1", "chip": 35120, "firmware": "4.3~b1", "board": 16, "build": "8F5148c"}, {"model": "AppleTV2,1", "chip": 35120, "firmware": "4.3~b2", "board": 16, "build": "8F5153d"}, {"model": "AppleTV2,1", "chip": 35120, "firmware": "4.3~b3", "board": 16, "build": "8F5166b"}, {"model": "AppleTV2,1", "chip": 35120, "firmware": "4.1", "board": 16, "build": "8M89"}, {"model": "AppleTV2,1", "chip": 35120, "firmware": null, "board": 16, "build": "9A406a"}]
 
 
 1. separate by "}," (then remove [{)
 
 [{"model": "AppleTV2,1", "chip": 35120, "firmware": "4.2", "board": 16, "build": "8C150"
 
 2. separate by ", "
 
 "model": "AppleTV2,1"
 
 3. separate by :
 
 "model"
 
 4. set object 1 of array3 as key
 
 5. add final dictionary to full array
 
 6. return
 
 
 */




+ (NSArray *)blobArrayFromString:(NSString *)theString
{
		//NSLog(@"theString: %@", theString);
	if ([[theString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@"[]"])
	{
		return nil;
	}
	NSMutableString *stripped = [[NSMutableString alloc] initWithString:theString];
	[stripped replaceOccurrencesOfString:@"[" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [stripped length])];
	[stripped replaceOccurrencesOfString:@"{" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [stripped length])];
	[stripped replaceOccurrencesOfString:@"\"" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [stripped length])];
	
	NSMutableArray *blobArray = [[NSMutableArray alloc] init];
	
	NSArray *fullArray = [stripped componentsSeparatedByString:@"},"]; //1.
	for (id currentBlob in fullArray)
	{ 
		NSArray *keyItems = [currentBlob componentsSeparatedByString:@", "]; //2.
		NSMutableDictionary *theDict = [[NSMutableDictionary alloc] init];
		for (id currentKey in keyItems)
		{
			NSArray *keyObjectArray = [[currentKey stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\"}]"]] componentsSeparatedByString:@":"]; //3.
			NSString *theObject = [[keyObjectArray objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			NSString *theKey = [[keyObjectArray objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];			
			[theDict setObject:theObject forKey:theKey];	//4.		
		}
		
		[blobArray addObject:[theDict autorelease]]; //5.
		
	}
	[stripped release];
	stripped = nil;
	return [blobArray autorelease];
	
}

+ (NSString *)versionFromBuild:(NSString *)buildNumber
{
	if ([buildNumber isEqualToString:@"8F455"])
		return @"4.3";
	if ([buildNumber isEqualToString:@"9A334v"])
		return @"4.4";
	if ([buildNumber isEqualToString:@"9A335a"])
		return @"4.4.1";
	if ([buildNumber isEqualToString:@"9A336a"])
		return @"4.4.2";
	if ([buildNumber isEqualToString:@"9A405l"])
		return @"4.4.3";
	if ([buildNumber isEqualToString:@"9A406a"])
		return @"4.4.4";
	if ([buildNumber isEqualToString:@"9B5127c"])
		return @"5.0b1";
	if ([buildNumber isEqualToString:@"9B5141a"])
		return @"5.0b2";
	
	return nil;
}

- (void)logDevice:(TSSDeviceID)inputDevice
{
	NSLog(@"TSSDeviceID(boardID: %i, chipID: %i)", inputDevice.boardID, inputDevice.chipID);
}

+ (NSString *)buildModel
{
	return [[TSSCommon stringReturnForProcess:@"/usr/sbin/sysctl -n hw.model"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (TSSDeviceID)currentDevice
{
	return DeviceIDMake(16, 35120);
	
	NSString *theDevice = [[TSSCommon stringReturnForProcess:@"/usr/sbin/sysctl -n hw.machine"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		//NSString *theDevice = [rawDevice stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	//NSLog(@"theDevice: -%@-", theDevice);
	
	if ([theDevice isEqualToString:@"AppleTV3,1"])
		return DeviceIDMake(8, 35138);
	
	if ([theDevice isEqualToString:@"AppleTV2,1"])
		return DeviceIDMake(16, 35120);
	
	if ([theDevice isEqualToString:@"iPad1,1"])
		return DeviceIDMake(2, 35120);
		
	if ([theDevice isEqualToString:@"iPad2,1"])
		return DeviceIDMake(4, 35136);

	if ([theDevice isEqualToString:@"iPad2,2"])
		return DeviceIDMake(6, 35136);
	
	if ([theDevice isEqualToString:@"iPad2,3"])
		return DeviceIDMake(2, 35136);
	
	if ([theDevice isEqualToString:@"iPad2,1"])
		return DeviceIDMake(4, 35136);
	
	if ([theDevice isEqualToString:@"iPhone1,1"])
		return DeviceIDMake(0, 35072);
	
	if ([theDevice isEqualToString:@"iPhone1,2"])
		return DeviceIDMake(4, 35072);
	
	if ([theDevice isEqualToString:@"iPhone2,1"])
		return DeviceIDMake(0, 35104);
	
	if ([theDevice isEqualToString:@"iPhone3,1"])
		return DeviceIDMake(0, 35120);
	
	if ([theDevice isEqualToString:@"iPhone3,3"])
		return DeviceIDMake(6, 35120);
	
	if ([theDevice isEqualToString:@"iPod1,1"])
		return DeviceIDMake(2, 35072);
	
	if ([theDevice isEqualToString:@"iPod2,1"])
		return DeviceIDMake(0, 34592);

	if ([theDevice isEqualToString:@"iPod3,1"])
		return DeviceIDMake(2, 35106);
	
	if ([theDevice isEqualToString:@"iPod4,1"])
		return DeviceIDMake(8, 35120);
	
	return TSSNullDevice;
	
	/*
	 

	 "appletv2,1": (35120, 16, 'AppleTV2,1'),
	 
	 "ipad1,1": (35120, 2, 'iPad1,1'),
	 "ipad2,1": (35136, 4, 'iPad2,1'),
	 "ipad2,2": (35136, 6, 'iPad2,2'),
	 "ipad2,3": (35136, 2, 'iPad2,3'),
	 
	 "iphone1,1": (35072, 0, 'iPhone1,1'),
	 "iphone1,2": (35072, 4, 'iPhone1,2'),
	 "iphone2,1": (35104, 0, 'iPhone2,1'),
	 "iphone3,1": (35120, 0, 'iPhone3,1'),
	 "iphone3,3": (35120, 6, 'iPhone3,3'),
	 
	 "ipod1,1": (35072, 2, 'iPod1,1'),
	 "ipod2,1": (34592, 0, 'iPod2,1'),
	 "ipod3,1": (35106, 2, 'iPod3,1'),
	 "ipod4,1": (35120, 8, 'iPod3,1'),
	 
	 */
}

+ (NSString *)rawBlobFromResponse:(NSString *)inputString
{

	NSArray *componentArray = [inputString componentsSeparatedByString:@"&"];
	int count = [componentArray count];
//	int status = [[[[componentArray objectAtIndex:0] componentsSeparatedByString:@"="] lastObject] intValue];
//	NSString *message = [[[componentArray objectAtIndex:1] componentsSeparatedByString:@"="] lastObject];
	if (count >= 3)
	{
		NSString *plist = [[componentArray objectAtIndex:2] substringFromIndex:15];
		return plist;
	} else {
		
		NSLog(@"probably failed: %@ count: %i", componentArray, count);
		
		return nil;
	}
	
	
}



+(NSString *) ipAddress {
    NSString * h = [[[NSHost currentHost] addresses] objectAtIndex:1];
    return h ;  
}

	/* 
	 
	 the request we send to get the list of SHSH blobs for the current device 

	 NOTE: this is all requisite on saurik updating the BuildManifest info on his servers to reflect new versions.
*/


- (NSMutableURLRequest *)requestForList
{

	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setURL:[NSURL URLWithString:baseUrlString]];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"X-User-Agent" forHTTPHeaderField:@"User-Agent"];
	[request setValue:nil forHTTPHeaderField:@"X-User-Agent"];
	
	return request;
		//return request;
}

/*
 
 we call this request when we are trying to send the blob TO cydia after fetching it FROM apple
 
 */


- (NSMutableURLRequest *)requestForBlob:(NSString *)post
{

	NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	
	NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setURL:[NSURL URLWithString:baseUrlString]];
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"X-User-Agent" forHTTPHeaderField:@"User-Agent"];
	[request setValue:nil forHTTPHeaderField:@"X-User-Agent"];
	[request setHTTPBody:postData];
	
	return request;
}

- (NSDictionary *)dictionaryFromString:(NSString *)theString
{
	NSString *error = nil;
	NSPropertyListFormat format;
	NSData *theData = [theString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	id theDict = [NSPropertyListSerialization propertyListFromData:theData
											 mutabilityOption:NSPropertyListImmutable 
													   format:&format
											 errorDescription:&error];
	return theDict;
}

/*
 
 we use this to convert and NSDictionary (the dictionary we got from the initial string) into a string.
 
 */

- (NSString *)stringFromDictionary:(NSDictionary *)theDict
{
	NSString *error = nil;
	NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:theDict format:kCFPropertyListXMLFormat_v1_0 errorDescription:&error];
	NSString *s=[[NSString alloc] initWithData:xmlData encoding: NSUTF8StringEncoding];
	return [s autorelease];
}

/*
 
 the url request to fetch a particular version from apple for the SHSH blob
 
 */

- (NSMutableURLRequest *)postRequestFromVersion:(NSString *)theVersion
{

	NSDictionary *theDict = [self tssDictFromVersion:theVersion]; //create a dict based on buildmanifest, we want to read this dictionary from a server in the future.
	self.ecid = [theDict valueForKey:@"ApECID"];
		//NSLog(@"self.ecid: %@", self.ecid);
	[ecid retain];


	NSString *post = [self stringFromDictionary:theDict]; //convert the nsdictionary into a string we can submit
	
	NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]; //this might actually need to be NSUTF8StringEncoding, but it works.
	
	NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setURL:[NSURL URLWithString:baseUrlString]];
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"InetURL/1.0" forHTTPHeaderField:@"User-Agent"];
	[request setHTTPBody:postData];
	
	return request;
	//return request;
}

+ (NSArray *)signableVersionsFromModel:(NSString *)theModel
{
	if (theModel == nil) theModel = @"k66ap";
	if ([[TSSManager supportedDevices] containsObject:theModel])
	{
		NSString *theURL = [BLOB_PLIST_BASE_URL stringByAppendingFormat:@"/%@.plist", theModel];
		//NSLog(@"url: %@", theURL);
		NSDictionary *blobDict = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:theURL]];
		return [blobDict valueForKey:@"openVersions"];
	}
	return nil;
}

+ (NSArray *)signableVersions
{
	NSDictionary *k66 = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:BLOB_PLIST_URL]];
	return [k66 valueForKey:@"openVersions"];
}

+ (NSArray *)supportedDevices
{
	return [NSArray arrayWithObjects:APPLETV_21_DEVICE_CLASS, APPLETV_31_DEVICE_CLASS, nil];
}


/*
 
 grabs the proper build manifest info from a local plist called k66ap.plist, in the future (for release) need to fetch from a plist onlinel.
 
 we combine this build manifest into an example dictionary (plist) to make a tss request from apples servers.
 
 
 */

- (NSDictionary *)tssDictFromVersion:(NSString *)versionNumber //ie 9A406a
{
	TSSDeviceID cd = self.theDevice;
	//[self logDevice:cd];
	
	NSString *theModel = self.deviceModel;
	if (theModel == nil) theModel = @"k66ap";
	
	NSString *theURL = [BLOB_PLIST_BASE_URL stringByAppendingFormat:@"/%@.plist", theModel];
	
	NSLog(@"theURl: %@", theURL);
	
	NSDictionary *k66 = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:theURL]];
		//NSDictionary *k66 = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[TSSManager class]] pathForResource:@"k66ap" ofType:@"plist"]];
	//NSLog(@"k66: %@", k66);
	NSDictionary *versionDict = [k66 valueForKey:versionNumber];
	
	NSMutableDictionary *theDict = [[NSMutableDictionary alloc] initWithDictionary:versionDict];

	[theDict setObject:[NSNumber numberWithBool:YES] forKey:@"@APTicket"];
	[theDict setObject:[TSSManager ipAddress] forKey:@"@HostIpAddress"];
	[theDict setObject:@"mac" forKey:@"@HostPlatformInfo"];
	//[theDict setObject:[TSSManager uuidFormatted] forKey:@"@UUID"];
	[theDict setObject:[NSNumber numberWithInt:cd.boardID] forKey:@"ApBoardID"];
	[theDict setObject:[NSNumber numberWithInt:cd.chipID] forKey:@"ApChipID"];
	[theDict setObject:@"libauthinstall-107" forKey:@"@VersionInfo"];
	[theDict setObject:myChipID_ forKey:@"ApECID"];
	
	//FIXME: STILL NEED ApNonce?
	
	[theDict setObject:[NSNumber numberWithBool:YES] forKey:@"ApProductionMode"];
	[theDict setObject:[NSNumber numberWithInt:1] forKey:@"ApSecurityDomain"];
	
	return [theDict autorelease];
	
}


/*
 
 should have a switch statement here to start the requisite processes, not just for the blob listing one, even if the delegate is set after its hould still pick up the end functions properly.
 
 
 */

- (id)init
{
	if ((self = [super init]) != nil);
	{
		
		theDevice = [TSSManager currentDevice];
		
		
		
		return (self);
		
	}
	
	return nil;
}

- (id)initWithECID:(NSString *)theEcid;
{
	if ((self = [super init]) != nil);
	{
		
		myChipID_ = theEcid;
		theDevice = [TSSManager currentDevice];

			
		
		return (self);
		
	}
	
	return nil;
}

- (id)initWithECID:(NSString *)theEcid device:(TSSDeviceID)myDevice
{
	if ((self = [super init]) != nil);
	{
		
		myChipID_ = theEcid;
		theDevice = myDevice;
		
		
		
		return (self);
		
	}
	
	return nil;
}



+ (NSArray *)localAppleTVBlobs
{
	NSString *shshPath = [NSHomeDirectory() stringByAppendingPathComponent:@".shsh"];
	NSArray *allBlobs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:shshPath error:nil]; //for now we will assume the default setup of .shsh in the ~ folder
																									   //NSLog(@"allblobs; %@", allBlobs);
	NSMutableArray *atvArray = [[NSMutableArray alloc] init];
	for (id blob in allBlobs)
	{
		if ([[[blob pathExtension] lowercaseString] isEqualToString:@"shsh"])
		{
			if ([blob rangeOfString:@"appletv2,1"].length > 0) {
				
					//96655119119-appletv2,1-4.1.shsh
				NSArray *components = [blob componentsSeparatedByString:@"-"];
				NSString *theEcid = [components objectAtIndex:0];
				NSString *thePath = [shshPath stringByAppendingPathComponent:blob];
				NSDictionary *blobDict = [NSDictionary dictionaryWithObjectsAndKeys:theEcid, @"ecid", thePath, @"path", nil];
				
					//NSLog(@"blobDict: %@", blobDict);
				[atvArray addObject:blobDict];
			}
		}
	}
	
	return [atvArray autorelease];
}

#pragma mark * Core transfer code


- (void)_sendBlobs:(NSArray *)blobs
{
	/*
	 
	 1. cycle through the filtered list
	 2. copy file to /tmp with gz suffix
	 3. gunzip
	 4. push blob
	 
	 */
	
	NSFileManager *man = [NSFileManager defaultManager];
	NSString *tmpPath = [@"/private/tmp" stringByAppendingPathComponent:@"shsh"];
	
	for (id currentBlob in blobs) //1
	{
		
		NSString *oldPath = [currentBlob valueForKey:@"path"];
		NSString *theID = [currentBlob valueForKey:@"ecid"];
			//[myChipID_ retain];
		
		if (![man fileExistsAtPath:tmpPath])
		{
			[man createDirectoryAtPath:tmpPath withIntermediateDirectories:TRUE attributes:nil error:nil];
				
		}
		
		NSString *newName = [[[oldPath lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"gz"];
		NSString *newPath = [tmpPath stringByAppendingPathComponent:newName];
		NSString *finalFile = [newPath stringByDeletingPathExtension];
		[man copyItemAtPath:oldPath toPath:newPath error:nil]; //2
		[nitoUtility changeOwner:@"501:20" onFile:tmpPath isRecursive:TRUE];
		[nitoUtility gunzip:newPath]; //3
		
		NSDictionary *theBlob = [NSDictionary dictionaryWithContentsOfFile:finalFile];
		NSString *blobString = [self stringFromDictionary:theBlob];
			//NSLog(@"blobString: %@", blobString);
			//NSLog(@"blobStringLength: %i", [blobString length]);
		if ([blobString length] > 0)
		{
			NSLog(@"pushingBlob: %@ with ecid: %@", finalFile, theID);
			NSString *theReturn = [self _synchronousPushBlob:blobString withECID:theID]; //4
			NSLog(@"%@", theReturn);
		}
		
		
	}
	
	[nitoUtility changeOwner:@"501:20" onFile:tmpPath isRecursive:TRUE];
	[man removeItemAtPath:tmpPath error:nil];
	
	
}


- (void)_sendLocalBlobs
{

	NSArray *blobs = [TSSManager localAppleTVBlobs];
	[self _sendBlobs:blobs];
	
}

- (NSArray *)_simpleSynchronousBlobCheck
{
	NSArray *complexBlobArray = [self _synchronousBlobCheck];
	return [TSSWorker buildsFromList:complexBlobArray];
}

- (NSArray *)_synchronousBlobCheck
{
    BOOL                success;
    NSURL *             url;
    NSMutableURLRequest *      request;
    
	// First get and check the URL.
    
	baseUrlString = [NSString stringWithFormat:@"http://cydia.saurik.com/tss@home/api/check/%@", myChipID_];
	
	//baseUrlString = @"http://cydia.saurik.com/TSS/controller?action=2";
	
	
	url = [NSURL URLWithString:baseUrlString];
	
    success = (url != nil);
	
	//NSLog(@"URL: %@", url);
	
	
	// If the URL is bogus, let the user know.  Otherwise kick off the connection.
    
    if ( ! success) {
		assert(!success);
		
    } else {
		
		
		// Open a connection for the URL.
		
        request = [self requestForList];
		
        assert(request != nil);
        
	
		NSURLResponse *theResponse = nil;
		NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
		
		NSString *datString = [[NSString alloc] initWithData:returnData  encoding:NSUTF8StringEncoding];
		
		NSArray *blobArray = [TSSManager blobArrayFromString:datString]; 
		
		[datString release];
		
		return blobArray;
	
    }
	
	return nil;
}

- (NSString *)_synchronousPushBlob:(NSString *)theBlob withECID:(NSString *)theEcid
{
	
		//NSLog(@"pushingBlob: %@", theBlob);
    BOOL                success;
    NSURL *             url;
    NSMutableURLRequest *      request;
    
	TSSDeviceID cd = self.theDevice;
	
		//[self logDevice:cd];
		// First get and check the URL.
    
	
	baseUrlString = [NSString stringWithFormat:@"http://cydia.saurik.com/tss@home/api/store/%i/%i/%@", cd.chipID, cd.boardID, theEcid];
	
		//baseUrlString = @"http://cydia.saurik.com/TSS/controller?action=2";
	
	
	url = [NSURL URLWithString:baseUrlString];
	
    success = (url != nil);
	
		//NSLog(@"URL: %@", url);
	
	
		// If the URL is bogus, let the user know.  Otherwise kick off the connection.
    
    if ( ! success) {
		assert(!success);
		
			//self.statusLabel.text = @"Invalid URL";
    } else {
		
		
			// Open a connection for the URL.
		
        request = [self requestForBlob:theBlob];
		assert(request != nil);
		
			//NSURLResponse *theResponse = nil;
		NSHTTPURLResponse * theResponse = nil;
		[NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
		
			//NSString *datString = [[NSString alloc] initWithData:returnData  encoding:NSUTF8StringEncoding];
		
			//NSLog(@"DatString: %@", datString);
		NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %i",[NSHTTPURLResponse localizedStringForStatusCode:theResponse.statusCode], theResponse.statusCode ];
		
			//NSLog(@"didReceiveResponse: %@ statusCode: %i", [NSHTTPURLResponse localizedStringForStatusCode:theResponse.statusCode], theResponse.statusCode);
			//NSString *outString = [TSSManager rawBlobFromResponse:datString]; 
		
			//[datString release];
		
		return returnString;
		
		
	}
	
	return nil;
}

- (NSString *)_synchronousPushBlob:(NSString *)theBlob
{
	
	//NSLog(@"pushingBlob: %@", theBlob);
    BOOL                success;
    NSURL *             url;
    NSMutableURLRequest *      request;
    
	TSSDeviceID cd = self.theDevice;
	
	//[self logDevice:cd];
	// First get and check the URL.
    

	baseUrlString = [NSString stringWithFormat:@"http://cydia.saurik.com/tss@home/api/store/%i/%i/%@", cd.chipID, cd.boardID, myChipID_];
	
	//baseUrlString = @"http://cydia.saurik.com/TSS/controller?action=2";
	
	
	url = [NSURL URLWithString:baseUrlString];
	
    success = (url != nil);
	
	//NSLog(@"URL: %@", url);
	
	
	// If the URL is bogus, let the user know.  Otherwise kick off the connection.
    
    if ( ! success) {
		assert(!success);
		
		//self.statusLabel.text = @"Invalid URL";
    } else {
		
		
		// Open a connection for the URL.
		
        request = [self requestForBlob:theBlob];
		assert(request != nil);
   
		//NSURLResponse *theResponse = nil;
		NSHTTPURLResponse * theResponse = nil;
		[NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
		
		//NSString *datString = [[NSString alloc] initWithData:returnData  encoding:NSUTF8StringEncoding];
		
		//NSLog(@"DatString: %@", datString);
		NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %i",[NSHTTPURLResponse localizedStringForStatusCode:theResponse.statusCode], theResponse.statusCode ];
		
		//NSLog(@"didReceiveResponse: %@ statusCode: %i", [NSHTTPURLResponse localizedStringForStatusCode:theResponse.statusCode], theResponse.statusCode);
		//NSString *outString = [TSSManager rawBlobFromResponse:datString]; 
		
		//[datString release];
		
		return returnString;
		
		
	}
	
	return nil;
}

- (NSString *)_synchronousCydiaReceiveVersion:(NSString *)theVersion
{
		//NSLog(@"receivingVersion: %@", theVersion);
    BOOL                success;
    NSURL *             url;
    NSMutableURLRequest *      request;

	
		baseUrlString = @"http://cydia.saurik.com/TSS/controller?action=2";
	
	
	url = [NSURL URLWithString:baseUrlString];
	
    success = (url != nil);
	
		//NSLog(@"URL: %@", url);
	
		// If the URL is bogus, let the user know.  Otherwise kick off the connection.
    
    if ( ! success) {
		assert(!success);
		
			//self.statusLabel.text = @"Invalid URL";
    } else {
		
			// Open a connection for the URL.
        request = [self postRequestFromVersion:theVersion];

		
		
		NSURLResponse *theResponse = nil;
		
		NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
		
		NSString *datString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
		
		NSString *outString = [TSSManager rawBlobFromResponse:datString]; 
		
		[datString release];
		
		return outString;
		
    }
	return nil;
}

+ (NSData *)ticketHeader
{
	NSString *headerHex = @"33676D49000C0000EC0B0000000000004241435345505954200000000400000042414353000000000000000000000000312F736F41544144AC0A00009A0A0000";
	return [NSData dataFromStringHex:headerHex];
}


#define TICKET_FULLSIZE_RANGE NSMakeRange(0x0003C, 4)
#define TICKET_SIZE_RANGE NSMakeRange(0x00038, 4)



+ (NSData *)apTicketFromDictionary:(NSDictionary *)thePlist
{
	id theData = nil;
	NSData *apTicket = [thePlist valueForKey:@"APTicket"];
	if (apTicket !=nil)
	{
		theData = [[NSMutableData alloc] initWithData:[TSSManager ticketHeader]];
		
		int size = [apTicket length];
		
		NSString *sizeString = [NSString stringWithFormat:@"%.8x",size ];
		NSString *fullSizeString = [NSString stringWithFormat:@"%.8x",(size+0x30) ];
		
		NSLog(@"size: %@ fullSize: %@", sizeString, fullSizeString);
		
		NSData *newLengthHex = [[NSData dataFromStringHex:sizeString] reverse];
		NSData *newFullLengthHex = [[NSData dataFromStringHex:fullSizeString] reverse];
		
		NSLog(@"newLengthHex: %@ newFullLengthHex: %@", newLengthHex, newFullLengthHex);
		
		
		[theData replaceBytesInRange:TICKET_FULLSIZE_RANGE withBytes:[newFullLengthHex bytes]];
		[theData replaceBytesInRange:TICKET_SIZE_RANGE withBytes:[newLengthHex bytes]];
		
		[theData appendData:apTicket];
		int length = [theData length];
		
		int extraBytes = 3072 - length;
			//	NSLog(@"length: %i desired length: 3072. padding needed: %i", length, extraBytes);
		int i;
		for (i = 0; i < extraBytes; i++)
		{
			
			[theData appendData:[NSData dataWithBytes:"\x00" length:1]];
		}
		
		length = [theData length];
		
			//NSLog(@"length after loop: %i", length);
		
	} else {
		
		return nil;
	}

	return [theData autorelease];
}

+ (NSString *)apTicketFileFromDictionary:(NSDictionary *)thePlist
{
	id theData = [TSSManager apTicketFromDictionary:thePlist];
	
	NSString *outputFile = @"/private/tmp/apticket";
	[theData writeToFile:outputFile options:NSDataWritingAtomic error:nil];
	[theData release];
	return outputFile;
}
   
- (NSString *)_synchronousReceiveVersion:(NSString *)theVersion
{
	//NSLog(@"receivingVersion: %@", theVersion);
    BOOL                success;
    NSURL *             url;
    NSMutableURLRequest *      request;
 
	// First get and check the URL.
    
	baseUrlString = @"http://gs.apple.com/TSS/controller?action=2";
	
	//baseUrlString = @"http://cydia.saurik.com/TSS/controller?action=2";
	
	
	url = [NSURL URLWithString:baseUrlString];
	
    success = (url != nil);
	
	//NSLog(@"URL: %@", url);
	//LocationLog(@"URL: %@", url);
	
	
	// If the URL is bogus, let the user know.  Otherwise kick off the connection.
    
    if ( ! success) {
		assert(!success);
		
		//self.statusLabel.text = @"Invalid URL";
    } else {
		
		
		// Open a connection for the URL.
		
        request = [self postRequestFromVersion:theVersion];
		//[request setHTTPMethod:@"POST"];
		
		
		NSURLResponse *theResponse = nil;
		NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
		
		NSString *datString = [[NSString alloc] initWithData:returnData  encoding:NSUTF8StringEncoding];
		
		NSString *outString = [TSSManager rawBlobFromResponse:datString]; 
		
		[datString release];
		
		return outString;
      
    }
	
	return nil;
}

	//http://cydia.saurik.com/tss@home/api/check/%llu <--ecid
		
/*
 
 moving all the stiching / signing code into here in an effort to be better organized.
 
 
 
 */


- (int)stitchFirmware:(FWBundle *)theBundle
{
	/*
	 
	 1. stitch it up, we shouldn't be called if its not possible.
	 
	 */
	
	
	NSArray *keyArray = [FWBundle signKeyArray]; //array of keys that needs to be signed
	NSString *buildNumber = [theBundle buildVersion];
	
	if (myChipID_ == nil)
		myChipID_ = [[[NSApplication sharedApplication] delegate] theEcid];
	
	NSLog(@"chipID_: %@", myChipID_);
	
	NSString *blob = [self _synchronousCydiaReceiveVersion:buildNumber];
	
		//okay we got a blob, lets make it a dictionary
	
	NSDictionary *blobDict = [self dictionaryFromString:blob];
	
		//NSLog(@"blobDict: %@", blobDict);
	
		//take the apticket and make it into an img3 file
	
	NSData *apTicketFull = [TSSManager apTicketFromDictionary:blobDict];
	NSString *allFlash = [theBundle allFlashLocation];
	NSString *apTicketFile = [allFlash stringByAppendingPathComponent:@"apticket.img3"];
	[apTicketFull writeToFile:apTicketFile options:NSDataWritingAtomic error:nil];
	
		//update manifest file to include apticket
	
	[self updateManifestFile:[allFlash stringByAppendingPathComponent:@"manifest"]];
	
		//start signin the files
	
	for (id fwKey in keyArray)
	{
			//first get the blob
		
		NSData *theBlob = [[blobDict valueForKey:fwKey] valueForKey:@"Blob"];
		NSString *fwFile = [theBundle unzippedPathForFirmwareKey:fwKey];
		
		if ([self signFile:fwFile withBlob:theBlob])
		{
			NSLog(@"signed file: %@ successfully!", fwFile);
			
		} else {
			
			NSLog(@"sign file: %@ fail!", fwFile);
		
			return -1;
			
		}
		
	}
	
		//we got the apticket done and the files signed, what else is there? pretty sure we are golden!
	
	
	
	NSLog(@"files signed successfully, firmware stitched: %@", buildNumber);

	
	return 0;
}


#define FULL_SIZE_RANGE NSMakeRange(0x00004, 4)
#define SIZE_RANGE NSMakeRange(0x00008, 4)
#define BLOB_RANGE NSMakeRange(0x0000C, 4)


- (BOOL)signFile:(NSString *)inputFile withBlob:(NSData *)blobData
{
		//	NSLog(@"signing file: %@", inputFile);
	
		//thanks ih8sn0w for information on this!!
	
	NSString *newFile = [inputFile stringByAppendingString:@"_patched"];
	NSMutableData *myData = [[NSMutableData alloc] initWithContentsOfMappedFile:inputFile];
	NSData *blobOffsetData = [myData subdataWithRange:BLOB_RANGE];
	
	NSString *converted = [blobOffsetData decimalString]; //take raw NSData, flip the bytes and make it a decimal string.
	NSUInteger offset = [converted intValue]+0x14; //take the intValue and add 14 for the address of where the SHSH blob will be added.
	NSRange blobRange = NSMakeRange(offset, [myData length]-offset); //we create the full range of the bytes we will replace with the blob we retreive from plist
	
		//offset is where we start, then we take the full length and delete the offset for the properly adjustsed range.
	
	
	NSString *replacementString = [NSString stringWithFormat:@"%.8x",([converted longLongValue]+0x40) ]; //flipped string that we replace in the header
	
	NSData *replacementData = [[NSData dataFromStringHex:replacementString] reverse]; //the actual data we use to replace the blob range in the header. take the hex string from above- reverse and datafy it.
	
	[myData replaceBytesInRange:BLOB_RANGE withBytes:[replacementData bytes]]; //changing the blob offset as necessary for signature
	
	[myData replaceBytesInRange:blobRange withBytes:[blobData bytes] length:[blobData length]]; //inserting the blob from the plist
	
	int dataLength = [myData length];
	
		//time to adjust the header - the full file size is at 0x00004 and is 4 bytes long. take the new length (dataLength) and convert it to hex properly to replace the current value
	
	NSString *newLengthHexString = [NSString stringWithFormat:@"%.8x",dataLength ]; //converted back to hex
	NSString *newHeaderlessLengthHexString = [NSString stringWithFormat:@"%.8x",dataLength-0x14 ]; //converted back to hex - the second header replacement without the header size factored in
	NSData *newLengthHex = [[NSData dataFromStringHex:newLengthHexString] reverse]; //reversed as necessary for re-adding to the file
	
	NSData *newLengthHeaderlessHex = [[NSData dataFromStringHex:newHeaderlessLengthHexString] reverse]; //reversed as necessary for re-adding to the file (no header size)
	[myData replaceBytesInRange:FULL_SIZE_RANGE withBytes:[newLengthHex bytes]]; //actually replace the new proper full size
	[myData replaceBytesInRange:SIZE_RANGE withBytes:[newLengthHeaderlessHex bytes]]; //replace the new proper headerless size.
	
	if ([myData writeToFile:newFile atomically:YES])
	{
			//NSLog(@"newFile: %@", newFile);
		
			//everything should have been a success! time to remove the old file and replace it with the new.
		
		[[NSFileManager defaultManager] removeItemAtPath:inputFile error:nil];
		[[NSFileManager defaultManager] moveItemAtPath:newFile toPath:inputFile error:nil];
		[myData release];
		
		return TRUE;
	}
	
	
	[myData release];
	return FALSE;
	
}


- (void)updateManifestFile:(NSString *)manifest
{
	NSMutableArray *manifestFileItemArray = [[NSMutableArray alloc] initWithArray:[[NSString stringWithContentsOfFile:manifest encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"]];
		//NSMutableArray *manifestFileItemArray = [[NSMutableArray alloc] initWithArray:[[NSString stringWithContentsOfFile:manifest] componentsSeparatedByString:@"\n"]];
		//NSLog(@"manifest: %@ manifestFileItemArray: %@", manifest, manifestFileItemArray);
	[manifestFileItemArray insertObject:@"apticket.img3" atIndex:0];
	NSString *finalString = [manifestFileItemArray componentsJoinedByString:@"\n"];
	
	[manifestFileItemArray release];
	manifestFileItemArray = nil;
		//[finalString writeToFile:manifest atomically:YES];
	[finalString writeToFile:manifest atomically:TRUE encoding:NSUTF8StringEncoding error:nil];
}


- (void)signFiles:(NSString *)theFile withBlob:(NSData *)theBlob //pseduo code that i never ended up using 
{
	/*
	 
	 1. find data at offset range 0xF->0xC
	 2. flip data
	 3. add 0x14
	 4. return $location
	 5. get range from $location to end
	 6. replace bytes with blob
	 7. fix headers 0x4 -- 0x8 is the overall filesize. So adjust it to properly have the correct file size.
	 0x8 -- 0xC is the img3 overall filesize - 0x14.
	 0xC -- 0xF is the current value + 0x40
	 
	 
	 */
}

-(void)fixfileHeader:(NSString *)inputFile //unused
{
	int fileSize = [[[[NSFileManager defaultManager] attributesOfItemAtPath:inputFile error:nil] objectForKey:NSFileSize] intValue];
	NSLog(@"fileSize: %i", fileSize);
		//NSString *theString = [NSString stringWithFormat:@"%i", fileSize];
	
}


- (void)dealloc {

	
	[deviceModel release];
    [super dealloc];
}



@end
