//
//  nitoUtility.m
//  Seas0nPass
//
//  Created by Kevin Bradley on 3/20/09.
//  Copyright 2009 nito, LLC. All rights reserved.
//

/* 
 
 a lot of this class is adapted from atvPwn and atvDrive, in addition to various other nito projects. 
 the bulk of convenience methods for extraction, hdiutil interactions, and actual patching/pwning process take place here
 
 */

#import "nitoUtility.h"
#import "FWBundle.h"

#define NULLOUT [NSFileHandle fileHandleWithNullDevice]

@implementation nitoUtility

@synthesize delegate, enableScripting, currentBundle, sshKey, sigServer, debWhitelist, restoreMode;

- (id)init
{
	
	self = [super init];
	
	return self;
}

- (void)dealloc {
	
    [sshKey release];
	[super dealloc];
}

+ (float)sizeFreeOnMountedPath:(NSString *)theDevice
{
	NSFileManager *man = [NSFileManager defaultManager];
	float available = [[[man attributesOfFileSystemForPath:theDevice error:nil] objectForKey:NSFileSystemFreeSize] floatValue];
	float avail2 = available / 1024 / 1024;
	return avail2;
}



#pragma mark •• dmg classes

+ (int)mountImageSimple:(NSString *)irString
{
	NSTask *irTask = [[NSTask alloc] init];
	
	NSMutableArray *irArgs = [[NSMutableArray alloc] init];
	
	[irArgs addObject:@"attach"];
	[irArgs addObject:irString];
	
	[irTask setLaunchPath:@"/usr/bin/hdiutil"];
	
	[irTask setArguments:irArgs];
	
	[irArgs release];
	
	[irTask setStandardError:NULLOUT];
	[irTask setStandardOutput:NULLOUT];
	
	[irTask launch];
	[irTask waitUntilExit];
	
	int returnStatus = [irTask terminationStatus];
	
	[irTask release];
	irTask = nil;	
	return returnStatus;
}

+ (NSString *)mountImageWithoutOwners:(NSString *)irString
{
	NSTask *irTask = [[NSTask alloc] init];
	NSPipe *hdip = [[NSPipe alloc] init];
    NSFileHandle *hdih = [hdip fileHandleForReading];
	
	NSMutableArray *irArgs = [[NSMutableArray alloc] init];
	
	[irArgs addObject:@"attach"];
	[irArgs addObject:@"-plist"];
	
	[irArgs addObject:irString];
	
	[irTask setLaunchPath:@"/usr/bin/hdiutil"];
	
	[irTask setArguments:irArgs];
	
	[irArgs release];
	
		//[irTask setStandardError:hdip];
	[irTask setStandardOutput:hdip];
		//NSLog(@"hdiutil %@", [[irTask arguments] componentsJoinedByString:@" "]);
	[irTask launch];
	
		NSData *outData = [hdih readDataToEndOfFile];
	
	[irTask waitUntilExit];
	

	NSString *the_error;
	NSPropertyListFormat format;
	id plist;
	plist = [NSPropertyListSerialization propertyListFromData:outData
											 mutabilityOption:NSPropertyListImmutable 
													   format:&format
											 errorDescription:&the_error];
	
	if(!plist)
		
	{
		
		NSLog(@"%@",the_error);
		
		[the_error release];
		
	}
		//NSLog(@"plist: %@", plist);
	
	NSArray *plistArray = [plist objectForKey:@"system-entities"];
	
		//int theItem = ([plistArray count] - 1);
	
	int i;
	
	NSString *mountPath = nil;
	
	for (i = 0; i < [plistArray count]; i++)
	{
		NSDictionary *mountDict = [plistArray objectAtIndex:i];
		
		mountPath = [mountDict objectForKey:@"mount-point"];
		if (mountPath != nil)
		{
				//NSLog(@"Mount Point: %@", mountPath);
			
			
			int rValue = [irTask terminationStatus];
			
			if (rValue == 0)
			{	[irTask release];
				irTask = nil;
				[hdip release];
				hdip = nil;
				return mountPath;
			}
		}
	}
	
	[irTask release];
	irTask = nil;	
	[hdip release];
	hdip = nil;
	return nil;
}

+ (NSString *)mountImage:(NSString *)irString
{
	NSTask *irTask = [[NSTask alloc] init];
	NSPipe *hdip = [[NSPipe alloc] init];
    NSFileHandle *hdih = [hdip fileHandleForReading];
	
	NSMutableArray *irArgs = [[NSMutableArray alloc] init];
	
	[irArgs addObject:@"attach"];
	[irArgs addObject:@"-plist"];
	
	[irArgs addObject:irString];
	
	[irArgs addObject:@"-owners"];
	[irArgs addObject:@"on"];
	
	[irTask setLaunchPath:@"/usr/bin/hdiutil"];
	
	[irTask setArguments:irArgs];
	
	[irArgs release];
	
		//[irTask setStandardError:hdip];
	[irTask setStandardOutput:hdip];
	//NSLog(@"hdiutil %@", [[irTask arguments] componentsJoinedByString:@" "]);
	[irTask launch];
	
	NSData *outData = [hdih readDataToEndOfFile]; //FIX_ME: DO THIS TO ALL READDATATOENDOFFILES
	
	[irTask waitUntilExit];
	
	
	NSString *the_error;
	NSPropertyListFormat format;
	id plist;
	plist = [NSPropertyListSerialization propertyListFromData:outData
											 mutabilityOption:NSPropertyListImmutable 
													   format:&format
											 errorDescription:&the_error];
	
	if(!plist)
		
	{
		
		NSLog(@"%@", the_error);
		
		[the_error release];
		
	}
	//NSLog(@"plist: %@", plist);
	
	NSArray *plistArray = [plist objectForKey:@"system-entities"];
	
	//int theItem = ([plistArray count] - 1);
	
	int i;
	
	NSString *mountPath = nil;
	
	for (i = 0; i < [plistArray count]; i++)
	{
		NSDictionary *mountDict = [plistArray objectAtIndex:i];
		
		mountPath = [mountDict objectForKey:@"mount-point"];
		if (mountPath != nil)
		{
			//NSLog(@"Mount Point: %@", mountPath);
			
			
			int rValue = [irTask terminationStatus];
			
			if (rValue == 0)
			{	[irTask release];
				irTask = nil;
				return mountPath;
			}
		}
	}
	
	[irTask release];
	irTask = nil;	
	return nil;
}

+ (void)unmountVolume:(NSString *)theVolume
{

	NSTask *umountTask = [[NSTask alloc] init];
	
	[umountTask setLaunchPath:HDIUTIL];
	[umountTask setArguments:[NSArray arrayWithObjects:@"detach", theVolume, nil]];
	[umountTask setStandardError:NULLOUT];
	[umountTask setStandardOutput:NULLOUT];
	[umountTask launch];
	
	[umountTask waitUntilExit];
	[umountTask release];
	
}

+ (int)scanForRestore:(NSString *)drivepath
{
	
	NSTask *asrTask = [[NSTask alloc] init];
	
	[asrTask setLaunchPath:ASR];
	[asrTask setArguments:[NSArray arrayWithObjects:@"-imagescan", drivepath, nil]];
	
	[asrTask launch];
	[asrTask waitUntilExit];
	int termStatus = [asrTask terminationStatus];
	
	return termStatus;
}

+ (void)altValidateFile:(NSString *)inputFile withChecksum:(NSString *)checksum
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSTask *sslTask = [[NSTask alloc] init];
	NSPipe *sspipe = [[NSPipe alloc] init];
	NSFileHandle *ssh = [sspipe fileHandleForReading];
	
	[sslTask setLaunchPath:@"/usr/bin/openssl"];
	
	[sslTask setArguments:[NSArray arrayWithObjects:@"sha1", inputFile, nil]];
	[sslTask setStandardOutput:sspipe];
	[sslTask setStandardError:sspipe];
	[sslTask launch];
	
	NSData *outData = [ssh readDataToEndOfFile];
	
	[sslTask waitUntilExit];
	
	NSString *outputString = [[[NSString alloc] initWithData:outData 
													encoding:NSASCIIStringEncoding] 
							  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
		//example outputString: SHA1(~/Documents/Tether/AppleTV2,1_4.3_8F455_Restore.ipsw)= b6a2b0baae79daf95f75044c12946839c662d01d
	
		//b6a2b0baae79daf95f75044c12946839c662d01d cleaned up
	NSString *outputSHA = [[[outputString componentsSeparatedByString:@"="] lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	
	
	NSLog(@"sha1: %@ against: %@", outputSHA, checksum);
	if ([outputSHA isEqualToString:checksum])
	{
		[sslTask release];
		sslTask = nil;
		[sspipe release];
		sspipe = nil;
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:inputFile, @"file", @"1", @"status", nil];
			//return YES;
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"checksumFinished" object:nil userInfo:userInfo deliverImmediately:YES];
		[pool release];
		return;
	} 
	[sslTask release];
	sslTask = nil;
	[sspipe release];
	sspipe = nil;
		//return NO;
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:inputFile, @"file", @"0", @"status", nil];
		//return YES;
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"checksumFinished" object:nil userInfo:userInfo deliverImmediately:YES];
	
	[pool release];

}

	


+ (BOOL)validateFile:(NSString *)inputFile withChecksum:(NSString *)checksum
{
		//LOG_SELF;
	
	NSTask *sslTask = [[NSTask alloc] init];
	NSPipe *sspipe = [[NSPipe alloc] init];
	NSFileHandle *ssh = [sspipe fileHandleForReading];
	
	[sslTask setLaunchPath:@"/usr/bin/openssl"];
	
	[sslTask setArguments:[NSArray arrayWithObjects:@"sha1", inputFile, nil]];
	[sslTask setStandardOutput:sspipe];
	[sslTask setStandardError:sspipe];
	[sslTask launch];
	
	NSData *outData = [ssh readDataToEndOfFile];
	
	[sslTask waitUntilExit];
	
	NSString *outputString = [[[NSString alloc] initWithData:outData 
													encoding:NSASCIIStringEncoding] 
							  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
		//example outputString: SHA1(~/Documents/Tether/AppleTV2,1_4.3_8F455_Restore.ipsw)= b6a2b0baae79daf95f75044c12946839c662d01d
	
							                 //b6a2b0baae79daf95f75044c12946839c662d01d cleaned up
	NSString *outputSHA = [[[outputString componentsSeparatedByString:@"="] lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	
	
	NSLog(@"sha1: %@ against: %@", outputSHA, checksum);
	if ([outputSHA isEqualToString:checksum])
	{
		[sslTask release];
		sslTask = nil;
		[sspipe release];
		sspipe = nil;
		return YES;
		
	} 
	[sslTask release];
	sslTask = nil;
	[sspipe release];
	sspipe = nil;
	return NO;
	
	
}

+ (BOOL)checkFile:(NSString *)inputFile againstMD5:(NSString *)properMD5
{
	//NSLog(@"%@ %s", self, _cmd);
	NSTask *mdTask = [[NSTask alloc] init];
	NSPipe *mdip = [[NSPipe alloc] init];
	//NSString *fullPath = [inputVolume stringByAppendingPathComponent:@"mach_kernel.prelink"];
	NSFileHandle *mdih = [mdip fileHandleForReading];
	[mdTask setLaunchPath:@"/sbin/md5"];
	
	[mdTask setArguments:[NSArray arrayWithObjects:@"-q", inputFile, nil]];
	[mdTask setStandardOutput:mdip];
	[mdTask setStandardError:mdip];
	[mdTask launch];
	
	NSData *outData;
	outData = [mdih readDataToEndOfFile];
	
	[mdTask waitUntilExit];

	NSString *temp = [[NSString alloc] initWithData:outData encoding:NSASCIIStringEncoding];
	temp = [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	//int theTerm = [mdTask terminationStatus];
	NSLog(@"md5: %@ against: %@ " , temp, properMD5);
	if ([temp isEqualToString:properMD5])
	{
		[mdTask release];
		mdTask = nil;
		[mdip release];
		mdip = nil;
		return YES;
		
	} 
	[mdTask release];
	mdTask = nil;
	[mdip release];
	mdip = nil;
	return NO;
	
}

#pragma mark •• owners / permissions

+ (void)changePermissions:(NSString *)perms onFile:(NSString *)theFile isRecursive:(BOOL)isR
{
	NSTask *permTask = [[NSTask alloc] init];
	NSMutableArray *permArgs = [[NSMutableArray alloc] init];
	if (isR)
		[permArgs addObject:@"-R"];
	[permArgs addObject:perms];
	[permArgs addObject:theFile];
	
	[permTask setLaunchPath:@"/bin/chmod"];
	
	[permTask setArguments:permArgs];
	
	//NSLog(@"chmod %@", [[permTask arguments] componentsJoinedByString:@" "]);
	[permTask launch];
	[permTask waitUntilExit];
	[permTask release];
	permTask = nil;
}

+ (void)changeOwner:(NSString *)theOwner onFile:(NSString *)theFile isRecursive:(BOOL)isR
{
	NSTask *ownTask = [[NSTask alloc] init];
	NSMutableArray *ownArgs = [[NSMutableArray alloc] init];
	[ownTask setLaunchPath:@"/usr/sbin/chown"];
	if (isR)
		[ownArgs addObject:@"-R"];
	[ownArgs addObject:theOwner];
	[ownArgs addObject:theFile];
	
	[ownTask setArguments:ownArgs];
	
	//NSLog(@"chown %@", [ownArgs componentsJoinedByString:@" "]);
	[ownArgs release];
	[ownTask launch];
	[ownTask waitUntilExit];
	[ownTask release];
	ownTask = nil;
}

#pragma mark •• pwnage classes


+ (void)createTempSetup
{
	if ([FM fileExistsAtPath:IPSW_TMP])
	{
		[FM removeItemAtPath:IPSW_TMP error:nil];
	}
	[FM createDirectoryAtPath:IPSW_TMP withIntermediateDirectories:YES attributes:nil error:nil];
	
}

- (void)editOptions:(NSString *)optionsFile withFSSize:(int)fsSize
{

	NSLog(@"editing options: %@", optionsFile);
	NSMutableDictionary *optionsDict = [[NSMutableDictionary alloc] initWithContentsOfFile:optionsFile];
	[optionsDict setObject:[NSNumber numberWithBool:NO] forKey:@"UpdateBaseband"];
	[optionsDict setObject:[NSNumber numberWithBool:YES] forKey:@"CreateFilesystemPartitions"];
	[optionsDict setObject:[NSNumber numberWithInt:fsSize] forKey:@"SystemPartitionSize"];
	[optionsDict setObject:[NSNumber numberWithInt:fsSize] forKey:@"MinimumSystemPartition"];
	[optionsDict writeToFile:optionsFile atomically:YES];
	[optionsDict release];
	
	
}

- (int)removeUselessFilesFromRamdisk:(NSString *)mountedRamdisk
{
	NSString *filePath = [mountedRamdisk stringByAppendingPathComponent:@"/usr/local/share/restore/PASS.png"];
	NSString *otherFilePath = [mountedRamdisk stringByAppendingPathComponent:@"/usr/share/progressui/images-1x"];
	NSString *otherFilePath2 = [mountedRamdisk stringByAppendingPathComponent:@"/usr/share/progressui/images-2x"];
	
	[[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:otherFilePath error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:otherFilePath2 error:nil];
	NSString *firmwarePath = [mountedRamdisk stringByAppendingPathComponent:@"/usr/local/standalone/firmware/"];
	NSArray *firmwareArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:firmwarePath error:nil];
	NSEnumerator *firmwareEnum = [firmwareArray objectEnumerator];
	id currentFile = nil;
	while (currentFile = [firmwareEnum nextObject]) {

        NSString *fullPath = [firmwarePath stringByAppendingPathComponent:currentFile];
        NSLog(@"removing file: %@", fullPath);
        
        if ([[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil])
        {
            NSLog(@"%@ removed successfully!", fullPath);
            
        } else {
            NSLog(@"%@ removal failed!!!!!", fullPath);
        }
		
	}
	
	return 0;
}

- (int)removeUselessFirmwareFilesFromRamdisk:(NSString *)mountedRamdisk
{
	NSString *firmwarePath = [mountedRamdisk stringByAppendingPathComponent:@"/usr/local/standalone/firmware/"];
	NSArray *firmwareArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:firmwarePath error:nil];
	NSEnumerator *firmwareEnum = [firmwareArray objectEnumerator];
	id currentFile = nil;
	while (currentFile = [firmwareEnum nextObject]) {
		
		NSString *extension = [[currentFile pathExtension] lowercaseString];
		if ([extension isEqualToString:@"zip"])
		{
			NSString *fullPath = [firmwarePath stringByAppendingPathComponent:currentFile];
			NSLog(@"removing file: %@", fullPath);

			if ([[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil])
			{
				NSLog(@"%@ removed successfully!", fullPath);
				return 0;
			} else {
				NSLog(@"%@ removal failed!!!!!", fullPath);
			}
		}
		
		
		
	}
	
	return -1;
}

- (int)performPatchesFromBundle:(FWBundle *)theBundle onRamdisk:(NSDictionary *)ramdiskDict
{
		//NSString *ramdiskSize = @"16541920";
		//NSString *ramdiskSize = [currentBundle ramdiskSize];
		//NSLog(@"ramdisk size: %@", ramdiskSize);
	NSString *ramdiskIV = [ramdiskDict valueForKey:@"IV"];
	NSString *ramdiskKey = [ramdiskDict valueForKey:@"Key"];
	NSDictionary *ramdiskPatches = [theBundle ramdiskPatches];
	NSString *theRamdisk = [TMP_ROOT stringByAppendingPathComponent:[ramdiskDict valueForKey:@"File"]];
	int status = 0;
	NSString *finalRam = [IPSW_TMP stringByAppendingPathComponent:[theRamdisk lastPathComponent]];
	NSString *decryptRam = [IPSW_TMP stringByAppendingPathComponent:@"decrypt.dmg"];
	status = [nitoUtility decryptRamdisk:theRamdisk toPath:decryptRam withIV:ramdiskIV key:ramdiskKey]; //1
	
		//change up here, smarterize resize ramdisk
	
	
	
	if (status == 0)
	{
		NSLog(@"decrypted %@ successfully!", theRamdisk);
		NSString *ramdiskSize = [self ramdiskResizeValue:decryptRam];
		
        if (![theBundle is4point4] || [theBundle fivePointOnePlus]) //is less than 4.4 or greater than 5.1
        {
            status = [nitoUtility resizeVolume:decryptRam toSize:ramdiskSize]; //2
        } else {
            //dont resize ramdisk for 4.4, fucks up in beta 3+
            status = 0; //hopefully the removeUselessFirmwareFiles function works!!
						
        }
        
		
		if (status == 0)
		{
			NSLog(@"resized %@ successfully!", decryptRam);
			NSString *mountedImage = [nitoUtility mountImageWithoutOwners:decryptRam]; //3
			if (mountedImage == nil) //an attempt to fix the Unexpected character 2 at line 1 bug
			{ 
				NSLog(@"dictionary parse may have failed, trying to unmount all /Volumes/ramdisk*");
				NSLog(@"remounting and hardcoding /Volumes/ramdisk, cross your fingers!");
				/*
				 
				 my theory is that the volume is mounting BUT the plist return from hdiutil is borking for some reason (maybe the use of deprecated code?)
				 
				 anyhow, going to try and "clean" any /Volume/ramdisk mounts (i know, not ideal, but what else can i do?)
				 
				 from there, use the attach code that doesnt try to parse the output, do a ghetto check to see if /Volumes/ramdisk exists, if it does, continue
				 
				 */
				
				[nitoUtility unmountVolume:@"/Volumes/ramdisk"];
				[nitoUtility unmountVolume:@"/Volumes/ramdisk 1"];
				[nitoUtility unmountVolume:@"/Volumes/ramdisk 2"];
				
				int mountReturn = [nitoUtility mountImageSimple:decryptRam]; //now force this to be /Volumes/ramdisk
				
				NSLog(@"mountImageSimple return: %i", mountReturn);
				
				if ([FM fileExistsAtPath:@"/Volumes/ramdisk"])
				{
					NSLog(@"ramdisk 'volume' exists!");
					mountedImage = @"/Volumes/ramdisk";
				}
				
				
			}
			if (mountedImage != nil)
			{
				NSLog(@"mountedImage %@ successfully!", decryptRam);
					/*
					 
					 patches here
					 
					 */
				
					//FIXME: for now we are just going to delete useless files to fix ramdisk issues in beta3
				
				[self removeUselessFirmwareFilesFromRamdisk:mountedImage];
                [self removeUselessFilesFromRamdisk:mountedImage];
				
				
				
				NSEnumerator *patchEnum = [ramdiskPatches objectEnumerator];
				id thePatch = nil;
				while (thePatch = [patchEnum nextObject])
				{
						//NSLog(@"thePAtch: %@", thePatch);
					NSString *file = [thePatch valueForKey:@"File"];
					NSString *patchFile = [thePatch valueForKey:@"Patch"];
					NSString *md5 = [thePatch valueForKey:@"MD5"];
					NSString *patchPath = [[theBundle bundlePath] stringByAppendingPathComponent:patchFile];
						
					NSLog(@"restoreMode: %i", [theBundle restoreMode]);
					if ([patchFile isEqualToString:@"restored_external.patch"])
					{
						if ([theBundle restoreMode] != 0)
						{
							status = [nitoUtility patchFile:[mountedImage stringByAppendingPathComponent:file] withPatch:patchPath endMD5:md5];
						} else {
							
							NSLog(@"recovery status 0, skip restored_external.patch");
							
							status = 0;
							
						}
						
					} else {
					
						NSLog(@"patching: %@ withPatch: %@", file, patchFile);
						status = [nitoUtility patchFile:[mountedImage stringByAppendingPathComponent:file] withPatch:patchPath endMD5:md5];
					}
					
					
					if (status == 0)
					{
						NSLog(@"patched %@ successfully!", file);
						[nitoUtility changePermissions:@"+x" onFile:[mountedImage stringByAppendingPathComponent:file] isRecursive:YES];
						if ([file isEqualToString:@"usr/sbin/asr"])
						{
							[nitoUtility changePermissions:@"100755" onFile:[mountedImage stringByAppendingPathComponent:file] isRecursive:YES];
						}
					} else {
						NSLog(@"patch %@ failure!!, bail!", thePatch);
						return -1;
					}
					
				}
				
				
				
				NSString *optionPath = [mountedImage stringByAppendingPathComponent:@"usr/local/share/restore/options.plist"];
				if ([[NSFileManager defaultManager] fileExistsAtPath:optionPath])
				{
					int fsSize = [[theBundle filesystemSize] intValue];
					fsSize += 100;
					[self editOptions:optionPath withFSSize:fsSize];
				}
				
				/*
				
					//update appletv partition size stuff
				NSString *optionPathATV = [mountedImage stringByAppendingPathComponent:@"usr/local/share/restore/options.k66.plist"];
				if ([[NSFileManager defaultManager] fileExistsAtPath:optionPathATV])
				{
					int fsSize = [[theBundle filesystemSize] intValue];
					[self editOptions:optionPathATV withFSSize:fsSize];
				}
				*/
				
				
				if (status == 0)
				{
					NSLog(@"performed patches successfully!");
					
					[nitoUtility unmountVolume:mountedImage]; //8
					
					status = [nitoUtility repackRamdisk:decryptRam toPath:finalRam withIV:ramdiskIV key:ramdiskKey originalPath:theRamdisk]; //9
					
						[FM removeItemAtPath:decryptRam error:nil]; //10 no need for 11?
					
					if (status == 0)
					{
					
						NSLog(@"patched ramdisk successfully!");
						return 0;
					} 
				} 
			} 
		} 
		
	}
	
	NSLog(@"patch ramdisk failed!");
	return -1;
	
	
	
}

- (int)patchRamdisk:(NSString *)theRamdisk
{
	NSString *ramdiskSize = @"16541920";
	NSString *ramdiskIV = @"7c256102d0580b960213540965618b5b";
	NSString *ramdiskKey = @"5d4e967158ab75ba27ec281bff4e714dacc88123ea4913ae2bee6a719c15496c";
	NSString *asrPath = [[NSBundle mainBundle] pathForResource:@"asr" ofType:@"patch" inDirectory:@"patches"];
	/*
	 TODO: add patch data dictionary
	 
	 1. xpwntool 038-0318-001.dmg ipsw/038-0318-001.dmg -iv 7c256102d0580b960213540965618b5b -k 5d4e967158ab75ba27ec281bff4e714dacc88123ea4913ae2bee6a719c15496c
	 
	 2. hdiutil resize -size 16541920 ipsw/038-0318-001.dmg
	 
	 3. hdiutil attach ipsw/038-0318-001.dmg
	 
	 4. bspatch /Volumes/ramdisk/usr/sbin/asr /Volumes/ramdisk/usr/sbin/asr.patched AppleTV2,1_4.2.1_8C154.bundle/asr.patch
	 
	 5. rm /Volumes/ramdisk/usr/sbin/asr
	 
	 6. mv /Volumes/ramdisk/usr/sbin/asr.patched /Volumes/ramdisk/usr/sbin/asr
	 
	 7. chmod +x  /Volumes/ramdisk/usr/sbin/asr
	 
	 8. hdiutil detach /Volumes/ramdisk/
	 
	 9. xpwntool ipsw/038-0318-001.dmg ipsw/038-0318-001-repack.dmg -iv 7c256102d0580b960213540965618b5b -k 5d4e967158ab75ba27ec281bff4e714dacc88123ea4913ae2bee6a719c15496c -t 038-0318-001.dmg
	 
	 10. rm ipsw/038-0318-001.dmg 
	 
	 11. mv ipsw/038-0318-001-repack.dmg ipsw/038-0318-001.dmg
	 
	 
	 */
	
	int status = 0;
	NSString *finalRam = [IPSW_TMP stringByAppendingPathComponent:[theRamdisk lastPathComponent]];
	NSString *decryptRam = [IPSW_TMP stringByAppendingPathComponent:@"decrypt.dmg"];
	status = [nitoUtility decryptRamdisk:theRamdisk toPath:decryptRam withIV:ramdiskIV key:ramdiskKey]; //1
	if (status == 0)
	{
		NSLog(@"decrypted %@ successfully!", theRamdisk);
		status = [nitoUtility resizeVolume:decryptRam toSize:ramdiskSize]; //2
		
		if (status == 0)
		{
			NSLog(@"resized %@ successfully!", decryptRam);
			NSString *mountedImage = [nitoUtility mountImageWithoutOwners:decryptRam]; //3
			
			if (mountedImage != nil)
			{
				NSLog(@"mountedImage %@ successfully!", decryptRam);
				status = [nitoUtility patchFile:[mountedImage stringByAppendingPathComponent:@"usr/sbin/asr"] withPatch:asrPath endMD5:@"072c70c08790a4d80f1683e60f4edb71"]; //4 5 6
				[nitoUtility changePermissions:@"+x" onFile:[mountedImage stringByAppendingPathComponent:@"usr/sbin/asr"] isRecursive:YES];
				
				if (status == 0)
				{
					NSLog(@"patched asr successfully!");
					[nitoUtility changePermissions:@"+x" onFile:[mountedImage stringByAppendingPathComponent:@"usr/sbin/asr"] isRecursive:YES]; //7
					[nitoUtility unmountVolume:mountedImage]; //8
					
					status = [nitoUtility repackRamdisk:decryptRam toPath:finalRam withIV:ramdiskIV key:ramdiskKey originalPath:theRamdisk]; //9
					
					if (status == 0)
					{
						[FM removeItemAtPath:decryptRam error:nil]; //10 no need for 11?
						NSLog(@"patched ramdisk successfully!");
						return 0;
					} 
				} 
			} 
		} 
		
	}
	
	NSLog(@"patch ramdisk failed!");
	return -1;
}

+ (NSDictionary *)fsImageInfo:(NSString *)inputFilesystem
{
	return nil;
	NSTask *irTask = [[NSTask alloc] init];
	NSPipe *hdip = [[NSPipe alloc] init];
    NSFileHandle *hdih = [hdip fileHandleForReading];
	
	NSMutableArray *irArgs = [[NSMutableArray alloc] init];
	
	[irArgs addObject:@"imageinfo"];
	[irArgs addObject:@"-plist"];
	
	[irArgs addObject:inputFilesystem];
	
	
	[irTask setLaunchPath:@"/usr/bin/hdiutil"];
	
	[irTask setArguments:irArgs];
	
	[irArgs release];
	
	[irTask setStandardError:hdip];
	[irTask setStandardOutput:hdip];
		//NSLog(@"hdiutil %@", [[irTask arguments] componentsJoinedByString:@" "]);
	[irTask launch];
	
	NSData *outData;
	outData = [hdih readDataToEndOfFile];
	
	[irTask waitUntilExit];
	
	
	NSString *the_error;
	NSPropertyListFormat format;
	id plist;
	plist = [NSPropertyListSerialization propertyListFromData:outData
											 mutabilityOption:NSPropertyListImmutable 
													   format:&format
											 errorDescription:&the_error];
	
	if(!plist)
		
	{
		
		NSLog(@"%@", the_error);
		
		[the_error release];
		
	}
		//NSLog(@"fsImageInfo: %@", plist);
	
	[irTask release];
	irTask = nil;	
	return plist;
}

- (NSString *)ramdiskResizeValue:(NSString *)inputRD //adds 3 megs to the ramdisk size
{
	return [currentBundle ramdiskSize];
	
	NSDictionary *fsImageInfo = [nitoUtility fsImageInfo:inputRD];
	
	if (fsImageInfo == nil)
	{
		return [currentBundle ramdiskSize];
		
	} else {
		
		NSLog(@"fsImageInfo: %@", fsImageInfo);
		
	}
	
	NSDictionary *sizeInfo = [fsImageInfo valueForKey:@"Size Information"];
	float totalBytes = [[sizeInfo valueForKey:@"Total Bytes"] floatValue];
	float totalEmptyBytes = [[sizeInfo valueForKey:@"Total Empty Bytes"] floatValue];
	NSLog(@"bytes free: %.0f", totalEmptyBytes);
	int finalTotal = totalBytes + 3145728;
	NSLog(@"finalTotal to resize rd: %i", finalTotal);
	return [NSString stringWithFormat:@"%i", finalTotal];

}
	//25747456

- (NSString *)filesystemResizeValue:(NSString *)inputFilesystem
{
	if([self.currentBundle is4point4])
	{
		NSLog(@"is 4.4/5.0");
		float resizeValue = [[[self currentBundle] filesystemSize] floatValue];
		int ft = resizeValue * 1048576;
		NSLog(@"resizeValue: %f MB", resizeValue);
		NSLog(@"finalTotal to resize fs: %i", ft);
		return [NSString stringWithFormat:@"%i", ft];
		
	}
	NSDictionary *fsImageInfo = [nitoUtility fsImageInfo:inputFilesystem];
	if (fsImageInfo == nil)
	{
		return nil;
		
	}//divide by 1048576 to get approx MB value
	
	NSDictionary *sizeInfo = [fsImageInfo valueForKey:@"Size Information"];
	NSLog(@"sizeInfo: %@", sizeInfo);
	float totalBytes = [[sizeInfo valueForKey:@"Total Bytes"] floatValue];
	float totalEmptyBytes = [[sizeInfo valueForKey:@"Total Empty Bytes"] floatValue];
	NSLog(@"totalEmptyBytes: %f", totalEmptyBytes);
	float freeMB = (totalEmptyBytes / 1048576);
	NSLog(@"MB free: %f", freeMB);
	
	if (freeMB < 100) //check to see if there is more than 100 megs free
	{
			//we need to resize the filesystem!!
			//approx 100 megs in bytes 104857600
		
		int finalTotal = totalBytes + 104857600;
		
		NSLog(@"finalTotal to resize fs: %i", finalTotal);
		return [NSString stringWithFormat:@"%i", finalTotal];
		
		
	}
	return nil;
	
	
}

#pragma mark this is where all the cleanup would need to occur.

- (void)patchFilesystem:(NSString *)inputFilesystem
{
	
	NSString *fsKey = [self.currentBundle filesystemKey];
		//	NSString *fstabPatch = [[NSBundle mainBundle] pathForResource:@"fstab" ofType:@"patch" inDirectory:@"patches"];
	/*
	 
	 1. vfdecrypt -i 038-0316-001.dmg -k 5407d28e075f5a2e06fddb7ad00123aa5a528bd6c2850d5fa0908a4dcae7dd3e00a9cdb2 -o ipsw/038-0316-001.dmg
	 
	 2. hdiutil convert ipsw/038-0316-001.dmg -format UDRW -o ipsw/converted.dmg
	 
	 3. sudo hdiutil attach -owners on ipsw/converted.dmg
	 
	 4. sudo bspatch /Volumes/Jasper8C154.K66OS/etc/fstab /Volumes/Jasper8C154.K66OS/etc/fstab.patched AppleTV2,1_4.2.1_8C154.bundle/fstab.patch
	 
	 5. sudo rm /Volumes/Jasper8C154.K66OS/etc/fstab
	 
	 6. sudo mv /Volumes/Jasper8C154.K66OS/etc/fstab.patched /Volumes/Jasper8C154.K66OS/etc/fstab
	 
	 7. sudo tar fxpz Cydia.tgz -C /Volumes/Jasper8C154.K66OS/
	 
	 8. sudo ./space.sh /Volumes/Jasper8C154.K66OS/
	 
	 9. hdiutil detach /Volumes/Jasper8C154.K66OS/
	 
	 10. hdiutil convert ipsw/converted.dmg -format UDZO -o ipsw/RO.dmg
	 
	 11. asr --imagescan ipsw/RO.dmg
	 
	 12. rm ipsw/converted.dmg
	 
	 13. rm ipsw/038-0316-001.dmg
	 
	 14. mv ipsw/RO.dmg ipsw/038-0316-001.dmg
	 
	 */
	int status = 0;
	NSLog(@"Decrypting Filesystem...");
		//	NSString *finalFS = [IPSW_TMP stringByAppendingPathComponent:[inputFilesystem lastPathComponent]];
	NSString *decryptFS = [inputFilesystem stringByAppendingPathExtension:@"decrypt"];
	NSString *rwFS = [TMP_ROOT stringByAppendingPathComponent:@"rw.dmg"];
	status = [nitoUtility decryptFilesystem:inputFilesystem withKey:fsKey]; //1
	if (status == 0)
	{
		NSLog(@"Decrypted Filesystem successfully!");
		NSLog(@"Converting Filesystem to read-write...");
		NSString *convertImage = [nitoUtility convertImage:decryptFS toFile:rwFS toMode:kDMGReadWrite]; //2
		if (convertImage != nil)
		{
			NSLog(@"converted to read write successfully: %@", rwFS); 
			
			/*
			 
			 attempt undocumented/unsupported compat with other iOS devices. this will require resizing the filesystem if it doesn't have enough space free
			 seems to be common.
			 
			 og line here was JUST 
			 
			 [self permissionedPatch:rwFS withOriginal:inputFilesystem];
			 */
			
			NSString *resizeFSValue = [self filesystemResizeValue:decryptFS];
				//[[NSApplication sharedApplication] terminate:self]; 
			if (resizeFSValue != nil)
			{
				NSLog(@"resizeFSValue: %@", resizeFSValue);
				[nitoUtility resizeVolume:rwFS toSize:resizeFSValue];
			}
			
				//need to take over with root access here for 3-8
			
			[self permissionedPatch:rwFS withOriginal:inputFilesystem];
			
		} else {
			
			NSLog(@"converting to read-write failed!");
			[self failedWithReason:@"Failed to convert filesystem to read-write!"];
			
			
		}
		
		
	} else {
		
		NSLog(@"filesystem decryption failed!");
		[self failedWithReason:@"Filesystem failed to decrypt!"];
		
		
		
	}
	
	
}

- (void)failedWithReason:(NSString *)theReason
{
	
	NSDictionary *failDict = [NSDictionary dictionaryWithObject:theReason forKey:@"AbortReason"];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"pwnFailed" object:nil userInfo:failDict deliverImmediately:YES];
}


- (void)oldpatchFilesystem:(NSString *)inputFilesystem
{
	
	NSString *fsKey = @"5407d28e075f5a2e06fddb7ad00123aa5a528bd6c2850d5fa0908a4dcae7dd3e00a9cdb2";
		//	NSString *fstabPatch = [[NSBundle mainBundle] pathForResource:@"fstab" ofType:@"patch" inDirectory:@"patches"];
	/*
	 
	1. vfdecrypt -i 038-0316-001.dmg -k 5407d28e075f5a2e06fddb7ad00123aa5a528bd6c2850d5fa0908a4dcae7dd3e00a9cdb2 -o ipsw/038-0316-001.dmg
	 
	2. hdiutil convert ipsw/038-0316-001.dmg -format UDRW -o ipsw/converted.dmg
	 
	3. sudo hdiutil attach -owners on ipsw/converted.dmg
	 
	4. sudo bspatch /Volumes/Jasper8C154.K66OS/etc/fstab /Volumes/Jasper8C154.K66OS/etc/fstab.patched AppleTV2,1_4.2.1_8C154.bundle/fstab.patch
	 
	5. sudo rm /Volumes/Jasper8C154.K66OS/etc/fstab
	 
	6. sudo mv /Volumes/Jasper8C154.K66OS/etc/fstab.patched /Volumes/Jasper8C154.K66OS/etc/fstab
	
	7. sudo tar fxpz Cydia.tgz -C /Volumes/Jasper8C154.K66OS/
	 
	8. sudo ./space.sh /Volumes/Jasper8C154.K66OS/
	 
	9. hdiutil detach /Volumes/Jasper8C154.K66OS/
	 
	10. hdiutil convert ipsw/converted.dmg -format UDZO -o ipsw/RO.dmg
	 
	11. asr --imagescan ipsw/RO.dmg
	 
	12. rm ipsw/converted.dmg
	 
	13. rm ipsw/038-0316-001.dmg
	 
	14. mv ipsw/RO.dmg ipsw/038-0316-001.dmg
	 
	 */
	int status = 0;
		//	NSString *finalFS = [IPSW_TMP stringByAppendingPathComponent:[inputFilesystem lastPathComponent]];
	NSString *decryptFS = [inputFilesystem stringByAppendingPathExtension:@"decrypt"];
	NSString *rwFS = [TMP_ROOT stringByAppendingPathComponent:@"rw.dmg"];
	status = [nitoUtility decryptFilesystem:inputFilesystem withKey:fsKey]; //1
	if (status == 0)
	{
		NSLog(@"Decrypted Filesystem successfully!");
		NSString *convertImage = [nitoUtility convertImage:decryptFS toFile:rwFS toMode:kDMGReadWrite]; //2
		if (convertImage != nil)
		{
			NSLog(@"converted to read write successfully: %@", rwFS); 
				//need to take over with root access here for 3-8
			[self permissionedPatch:rwFS withOriginal:inputFilesystem];
		}
	} 
	
	
	
}

- (void)permissionedPatch:(NSString *)theFile withOriginal:(NSString *)originalDMG
{
	
	NSString *theDict = [self pwnctionaryFromPath:theFile original:originalDMG withBundle:self.currentBundle];
	
		// NSLog(@"pwnctionary: %@", theDict);
    
	NSString *helpPath = [[NSBundle mainBundle] pathForResource: @"dbHelper" ofType: @""];
	
	NSTask *pwnHelper = [[NSTask alloc] init];
	
	[pwnHelper setLaunchPath:helpPath];
	
	[pwnHelper setArguments:[NSArray arrayWithObjects:@"nil", theDict, nil]];
	
	[pwnHelper launch];
	
	[pwnHelper waitUntilExit];
	
	[pwnHelper release];
	
	pwnHelper = nil;
}

+ (BOOL)hasFirmware //by default it returns false. it will check to see if the Firmware folder exists. if it does it will cycle through the folder till something has the "ipsw" path extension, as soon as it finds a single file that does, it will return true
{
	if ([FM fileExistsAtPath:[nitoUtility firmwareFolder]])
	{
		NSArray *contents = [FM contentsOfDirectoryAtPath:[nitoUtility firmwareFolder] error:nil];
			//	NSLog(@"contents: %@", contents);
		if ([contents count] > 1){
			for (id theObject in contents)
			{
				NSString *suffix = [[theObject pathExtension] lowercaseString];
				if ([suffix isEqualToString:@"ipsw"])
					return (TRUE);
			}
		} else if ([contents count] == 1){
			NSString *lastObject = [contents lastObject];
			if (![lastObject isEqualToString:@".DS_Store"])
			{
				
				if ([[[lastObject lastPathComponent] lowercaseString] isEqualToString:@"ipsw"])
				{
					NSLog(@"only one object, not .DS_Store, extension is ipsw. should be a ipsw!!: %@", lastObject);
					return (TRUE);
				}
					//make sure if there is only one item that its not .DS_Store
				
			}
		}
	}
	
	return (FALSE);
}

+ (NSString *)firmwareFolder
{
	NSFileManager *man = [NSFileManager defaultManager];
	NSString *fullFolder = [[nitoUtility applicationSupportFolder] stringByAppendingPathComponent:@"Firmware"];
	if (![man fileExistsAtPath:fullFolder])
	{
		if ([man createDirectoryAtPath:fullFolder withIntermediateDirectories:TRUE attributes:nil error:nil] == TRUE)
		{
			NSLog(@"created firmware folder successfully!");
		} else {
			
			NSLog(@"creating firmware folder failed!?!??! bail!!!");
			return nil;
		}
	}
	return fullFolder;
}

+ (NSString *)applicationSupportFolder {
	
	NSFileManager *man = [NSFileManager defaultManager];
    NSArray *paths =
	NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
										NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:
												0] : NSTemporaryDirectory();
	basePath = [basePath stringByAppendingPathComponent:@"Seas0nPass"];
    if (![man fileExistsAtPath:basePath])
		[man createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil];
	return basePath;
}

+ (NSString *)wifiFile 
{
	NSString *wf = [[nitoUtility applicationSupportFolder] stringByAppendingPathComponent:@"com.apple.wifi.plist"];
	
	if ([FM fileExistsAtPath:wf]) { return wf; }
	
	return nil;
	
}

- (NSString *)pwnctionaryFromPath:(NSString *)mountedPath original:(NSString *)original withBundle:(FWBundle *)theBundle
{
	NSString *es = [NSString stringWithFormat:@"%i", (int)[self enableScripting]];
	NSString *resMode = [NSString stringWithFormat:@"%i",[self restoreMode]];
	NSMutableDictionary *bundleDict = [[NSMutableDictionary alloc] init];
	[bundleDict setObject:es forKey:@"enableScripting"];
	[bundleDict setObject:mountedPath forKey:@"patch"];
	[bundleDict setObject:original forKey:@"os"];
	[bundleDict setObject:resMode forKey:@"restoreMode"];
		//[bundleDict setObject:[[NSBundle mainBundle] pathForResource:@"CydiaInstallerATV" ofType:@"bundle"] forKey:@"CydiaBundle"];
	NSMutableDictionary *fstabDict = [[NSMutableDictionary alloc] init];
	[fstabDict setObject:@"/etc/fstab" forKey:@"inputFile"];
	[fstabDict setObject:[[NSBundle mainBundle] pathForResource:@"fstab" ofType:@"patch" inDirectory:@"patches"] forKey:@"patchFile"];
	[fstabDict setObject:@"e34d097a1c6dc7fd95db41879129327b" forKey:@"md5"];
	[bundleDict setObject:[fstabDict autorelease] forKey:@"fstabPatch"];
	
	if ([nitoUtility wifiFile] != nil)
	{
		[bundleDict setObject:[nitoUtility wifiFile] forKey:@"wifi"];
	}
	
	if ([self sigServer] == TRUE)
	{
		[bundleDict setObject:@"TRUE" forKey:@"sigServer"];
	}
    
    if ([self debWhitelist] == TRUE)
	{
		[bundleDict setObject:@"TRUE" forKey:@"debWhitelist"];
	}
	
	if ([[self sshKey] length] > 0)
	{
		[bundleDict setObject:[self sshKey] forKey:@"sshKey"];
	}
	[bundleDict setObject:CYDIA_TAR forKey:@"cydia"];
	[bundleDict setObject:DEB_PATH forKey:@"debs"];
    
    if (![FM fileExistsAtPath:DEB_PATH_CUSTOM])
        
    
    if ([[FM contentsOfDirectoryAtPath:DEB_PATH_CUSTOM error:nil] count] > 0)
        [bundleDict setObject:DEB_PATH_CUSTOM forKey:@"debs2"];
    
		//if (![theBundle fivePointOnePlus])
		[bundleDict setObject:SPACE_SCRIPT forKey:@"stash"];
	[bundleDict setObject:[theBundle bundlePath] forKey:@"bundle"];
		//TODO: custom bundles
	NSString *cliPath = @"/tmp/031231";
	[bundleDict writeToFile:cliPath atomically:YES];
	return cliPath;	
	 
}

+ (int)linkFile:(NSString *)theFile toPath:(NSString *)thePath inWorkingDirectory:(NSString *)theDir
{
    NSTask *linkTask = [[NSTask alloc] init];
    [linkTask setLaunchPath:@"/bin/ln"];
    if ([theDir length] > 0)
    {
        [linkTask setCurrentDirectoryPath:theDir];
    }
    [linkTask setArguments:[NSArray arrayWithObjects:@"-ns", theFile, thePath, nil]];
    [linkTask launch];
    [linkTask waitUntilExit];
    int termStatus = [linkTask terminationStatus];
    [linkTask release];
    linkTask = nil;
    return  termStatus;
}

+ (int)patchFile:(NSString *)patchFile withPatch:(NSString *)thePatch toLocation:(NSString *)endLocationFile inWorkingDirectory:(NSString *)theDir
{
	NSTask *patchTask = [[NSTask alloc] init];
	[patchTask setLaunchPath:BSPATCH];
	NSString *patchFilePath = [theDir stringByAppendingPathComponent:patchFile];
	NSString *fullLocation = [theDir stringByAppendingPathComponent:endLocationFile];
	[patchTask setArguments:[NSArray arrayWithObjects:patchFilePath, fullLocation, thePatch, nil]];
	NSLog(@"patches: %@", [[patchTask arguments] componentsJoinedByString:@" "]);
	[patchTask launch];
	[patchTask waitUntilExit];
	
	int returnStatus = [patchTask terminationStatus];
	[patchTask release];
	patchTask = nil;
	if (returnStatus == 0)
	{

		if ([[endLocationFile lastPathComponent] isEqualToString:@"corona"])
		{
			NSLog(@"corona +x");
			[nitoUtility changePermissions:@"+x" onFile:fullLocation isRecursive:YES];
			
		}
		
		
		if ([[endLocationFile lastPathComponent] isEqualToString:@"racoon"])
		{
			NSLog(@"racoon +x");
			[nitoUtility changePermissions:@"+x" onFile:fullLocation isRecursive:YES];
		}
		
		return 0;
		
	} else {
		NSLog(@"patching: %@ failed!! ABORT!", patchFile);
		return -1;
	}
	return -1;
	
}

+ (int)runScript:(NSString *)theScript withInput:(NSString *)theInput
{
	setuid(0);
	setgid(0);
	NSString *command = [NSString stringWithFormat:@"/bin/sh \"%@\" \"%@\"", theScript, theInput];
	int sysReturn = system([command UTF8String]);
	return sysReturn;
}


+ (int)decryptRamdisk:(NSString *)theRamdisk toPath:(NSString *)outputDisk withIV:(NSString *)iv key:(NSString *)key

{
	NSTask *decryptTask = [[NSTask alloc] init];
	[decryptTask setLaunchPath:XPWN];
	NSMutableArray *decryptArgs = [[NSMutableArray alloc ]init];
	[decryptArgs addObject:theRamdisk];
	[decryptArgs addObject:outputDisk];
	if (iv != nil)
	{
		if (key != nil)
		{
			[decryptArgs addObject:@"-iv"];
			[decryptArgs addObject:iv];
			[decryptArgs addObject:@"-k"];
			[decryptArgs addObject:key];
			
		}
		
		
	}
	[decryptTask setArguments:decryptArgs];
	[decryptArgs release];
		//[decryptTask setArguments:[NSArray arrayWithObjects:theRamdisk, outputDisk, @"-iv", iv, @"-k", key, nil]];
	[decryptTask setStandardError:NULLOUT];
	[decryptTask setStandardOutput:NULLOUT];
	[decryptTask launch];
	[decryptTask waitUntilExit];
	
	int returnStatus = [decryptTask terminationStatus];
	[decryptTask release];
	decryptTask = nil;
	
	return returnStatus;
}

+ (int)repackRamdisk:(NSString *)theRamdisk toPath:(NSString *)outputDisk withIV:(NSString *)iv key:(NSString *)key originalPath:(NSString *)original

{
	NSTask *decryptTask = [[NSTask alloc] init];
	[decryptTask setLaunchPath:XPWN];
	[decryptTask setStandardError:NULLOUT];
	[decryptTask setStandardOutput:NULLOUT];
	
	NSMutableArray *decryptArgs = [[NSMutableArray alloc ]init];
	[decryptArgs addObject:theRamdisk];
	[decryptArgs addObject:outputDisk];
	if (iv != nil)
	{
		if (key != nil)
		{
			[decryptArgs addObject:@"-iv"];
			[decryptArgs addObject:iv];
			[decryptArgs addObject:@"-k"];
			[decryptArgs addObject:key];
			
		}
		
		
	}
	[decryptArgs addObject:@"-t"];
	[decryptArgs addObject:original];
	[decryptTask setArguments:decryptArgs];
		//NSLog(@"xpwntool %@", [decryptArgs componentsJoinedByString:@" "]);
	[decryptArgs release];
		//[decryptTask setArguments:[NSArray arrayWithObjects:theRamdisk, outputDisk, @"-iv", iv, @"-k", key, @"-t", original, nil]];
	[decryptTask launch];
	[decryptTask waitUntilExit];
	
	int returnStatus = [decryptTask terminationStatus];
	[decryptTask release];
	decryptTask = nil;
	
	return returnStatus;
}

	//hdiutil resize -size 16541920 ipsw/038-0318-001.dmg

+(int)resizeVolume:(NSString *)theVolume toSize:(NSString *)theSize
{
		//FIXME: for now this is just going to return 0 and we are going to delete the stupid files to test out latest bundle, make sure to make this smarter later!!
	//return 0;
	
	NSTask *hdiTask = [[NSTask alloc] init];
	[hdiTask setLaunchPath:HDIUTIL];
	[hdiTask setArguments:[NSArray arrayWithObjects:@"resize", @"-size", theSize, theVolume, nil]];
	[hdiTask launch];
	[hdiTask waitUntilExit];
	
	int returnStatus = [hdiTask terminationStatus];
	[hdiTask release];
	hdiTask = nil;
	
	return returnStatus;
}

+ (int)patchFile:(NSString *)patchFile withPatch:(NSString *)thePatch endMD5:(NSString *)desiredMD5
{
	NSTask *patchTask = [[NSTask alloc] init];
	[patchTask setLaunchPath:BSPATCH];
	NSString *patchedFile = [TMP_ROOT stringByAppendingPathComponent:[patchFile lastPathComponent]];
		//NSString *patchedFile = [patchFile stringByAppendingPathExtension:@"patched"];
	[patchTask setArguments:[NSArray arrayWithObjects:patchFile, patchedFile, thePatch, nil]];
		//NSLog(@"patches: %@", [[patchTask arguments] componentsJoinedByString:@" "]);
	[patchTask launch];
	[patchTask waitUntilExit];
	
	int returnStatus = [patchTask terminationStatus];
	[patchTask release];
	patchTask = nil;
	if (returnStatus == 0)
	{
		if (desiredMD5 == nil)
			
		{
			
			NSLog(@"no MD5, skip check!");
			if([FM removeItemAtPath:patchFile error:nil])
			{
				NSLog(@"%@ removed successfully!", patchFile);
				if ([FM moveItemAtPath:patchedFile toPath:patchFile error:nil])
				{
					NSLog(@"%@ patched and replaced successfully!!", patchFile);
					if ([[patchFile lastPathComponent] isEqualToString:@"AppleTV"])
					{
							//NSLog(@"AppleTV +x");
						[nitoUtility changePermissions:@"+x" onFile:patchFile isRecursive:YES];
					}
					if ([[patchFile lastPathComponent] isEqualToString:@"Lowtide"])
					{
							//NSLog(@"Lowtide +x");
						[nitoUtility changePermissions:@"+x" onFile:patchFile isRecursive:YES];
					}
					
					if ([[patchFile lastPathComponent] isEqualToString:@"launchd"])
					{
							//NSLog(@"Lowtide +x");
						[nitoUtility changePermissions:@"+x" onFile:patchFile isRecursive:YES];
					}
					return 0;
				} else {
					
					NSLog(@"replacement failed!! bail!!!");
					return -1;
				}
			}
			return 0;
			
		}
			//check to see if md5 is proper
		if ([nitoUtility checkFile:patchedFile againstMD5:desiredMD5])
		{
			if ([[patchedFile lastPathComponent] isEqualToString:@"AppleTV"])
			{
					//NSLog(@"AppleTV +x");
				[nitoUtility changePermissions:@"+x" onFile:patchedFile isRecursive:YES];
			}
			if ([[patchedFile lastPathComponent] isEqualToString:@"Lowtide"])
			{
					//NSLog(@"Lowtide +x");
				[nitoUtility changePermissions:@"+x" onFile:patchedFile isRecursive:YES];
			}
			
			if ([[patchFile lastPathComponent] isEqualToString:@"launchd"])
			{
					//NSLog(@"Lowtide +x");
				[nitoUtility changePermissions:@"+x" onFile:patchFile isRecursive:YES];
			}
			NSLog(@"md5 checks out!, replacing original");
			if([FM removeItemAtPath:patchFile error:nil])
			{
				NSLog(@"%@ removed successfully!", patchFile);
				if ([FM moveItemAtPath:patchedFile toPath:patchFile error:nil])
				{
					NSLog(@"%@ patched and replaced successfully!!", patchFile);
					return 0;
				}
			}
		}
		
	} else {
		NSLog(@"patching: %@ failed!! ABORT!", patchFile);
		return -1;
	}
	return -1;
	
}

+ (int)oldpatchFile:(NSString *)patchFile withPatch:(NSString *)thePatch endMD5:(NSString *)desiredMD5
{
	NSTask *patchTask = [[NSTask alloc] init];
	[patchTask setLaunchPath:BSPATCH];
	NSString *patchedFile = [patchFile stringByAppendingPathExtension:@"patched"];
	[patchTask setArguments:[NSArray arrayWithObjects:patchFile, patchedFile, thePatch, nil]];
		//NSLog(@"patches: %@", [[patchTask arguments] componentsJoinedByString:@" "]);
	[patchTask launch];
	[patchTask waitUntilExit];
	
	int returnStatus = [patchTask terminationStatus];
	[patchTask release];
	patchTask = nil;
	if (returnStatus == 0)
	{
		if (desiredMD5 == nil)
			
		{
			
			NSLog(@"no MD5, skip check!");
			if([FM removeItemAtPath:patchFile error:nil])
			{
				NSLog(@"%@ removed successfully!", patchFile);
				if ([FM moveItemAtPath:patchedFile toPath:patchFile error:nil])
				{
					NSLog(@"%@ patched and replaced successfully!!", patchFile);
					if ([[patchFile lastPathComponent] isEqualToString:@"AppleTV"])
					{
							//NSLog(@"AppleTV +x");
						[nitoUtility changePermissions:@"+x" onFile:patchFile isRecursive:YES];
					}
					if ([[patchFile lastPathComponent] isEqualToString:@"Lowtide"])
					{
							//NSLog(@"Lowtide +x");
						[nitoUtility changePermissions:@"+x" onFile:patchFile isRecursive:YES];
					}
					
					if ([[patchFile lastPathComponent] isEqualToString:@"launchd"])
					{
							//NSLog(@"Lowtide +x");
						[nitoUtility changePermissions:@"+x" onFile:patchFile isRecursive:YES];
					}
					return 0;
				}
			}
			return 0;
			
		}
			//check to see if md5 is proper
		if ([nitoUtility checkFile:patchedFile againstMD5:desiredMD5])
		{
			if ([[patchedFile lastPathComponent] isEqualToString:@"AppleTV"])
			{
					//NSLog(@"AppleTV +x");
				[nitoUtility changePermissions:@"+x" onFile:patchedFile isRecursive:YES];
			}
			if ([[patchedFile lastPathComponent] isEqualToString:@"Lowtide"])
			{
					//NSLog(@"Lowtide +x");
				[nitoUtility changePermissions:@"+x" onFile:patchedFile isRecursive:YES];
			}
			
			if ([[patchFile lastPathComponent] isEqualToString:@"launchd"])
			{
					//NSLog(@"Lowtide +x");
				[nitoUtility changePermissions:@"+x" onFile:patchFile isRecursive:YES];
			}
			NSLog(@"md5 checks out!, replacing original");
			if([FM removeItemAtPath:patchFile error:nil])
			{
				NSLog(@"%@ removed successfully!", patchFile);
				if ([FM moveItemAtPath:patchedFile toPath:patchFile error:nil])
				{
					NSLog(@"%@ patched and replaced successfully!!", patchFile);
					return 0;
				}
			}
		}
		
	} else {
		NSLog(@"patching: %@ failed!! ABORT!", patchFile);
		return -1;
	}
	return -1;
	
}


+ (NSString *)convertImage:(NSString *)irString toFile:(NSString *)outputFile toMode:(int)theMode
{
	NSFileManager *man = [NSFileManager defaultManager];
	if ([man fileExistsAtPath:outputFile])
	{
		NSLog(@"file already exists? thats not right!");
		[man removeItemAtPath:outputFile error:nil];
	}
	NSPipe *hdpipe = [[NSPipe alloc] init];
	NSFileHandle *hdhandle = [hdpipe fileHandleForReading];
	NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/SP_Debug.log"];
		//if (![man fileExistsAtPath:logPath])
		//[man createFileAtPath:logPath contents:nil attributes:nil];
		//NSLog(@"logpath: %@", logPath);
		//NSFileHandle *logHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
	NSString *outputName = outputFile;
	NSString *modeString = nil;
	switch (theMode)
	{
		case kDMGReadWrite: //UDRW
			modeString = @"UDRW";
			break;
			
		case kDMGReadOnly: //UDZO
			modeString = @"UDZO";
			break;
	}
	NSTask *irTask = [[NSTask alloc] init];
	
	
	NSMutableArray *irArgs = [[NSMutableArray alloc] init];
	
	[irArgs addObject:@"convert"];
	
	[irArgs addObject:irString];
	
	[irArgs addObject:@"-format"];
	
	[irArgs addObject:modeString];
	
	[irArgs addObject:@"-o"];
	
	[irArgs addObject:outputFile];
	
	[irTask setLaunchPath:HDIUTIL];
		//[irTask setStandardError:logHandle];
		//[irTask setStandardOutput:logHandle];
	[irTask setArguments:irArgs];
	
	[irArgs release];
	
	
		//NSLog(@"hdiutil %@", [[irTask arguments] componentsJoinedByString:@" "]);
	
	
	
	[irTask setStandardOutput:hdpipe];
	[irTask setStandardError:hdpipe];
	[irTask launch];
	
	NSData *outData = [hdhandle readDataToEndOfFile];
	
	
	[irTask waitUntilExit];
	
	
	NSFileHandle *aFileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];            //telling aFilehandle what file write to
	[aFileHandle truncateFileAtOffset:[aFileHandle seekToEndOfFile]];          //setting aFileHandle to write at the end of the file
	
	[aFileHandle writeData:outData];                        //actually write the data
	
	[aFileHandle synchronizeFile];
	
	[aFileHandle closeFile];
	
	
	[irTask release];
	irTask = nil;
	[hdpipe release];
	hdpipe = nil;
	
	return outputName;
	
}

+ (NSString *)oldconvertImage:(NSString *)irString toFile:(NSString *)outputFile toMode:(int)theMode
{
	NSFileManager *man = [NSFileManager defaultManager];
	if ([man fileExistsAtPath:outputFile])
	{
		NSLog(@"file already exists? thats not right!");
		[man removeItemAtPath:outputFile error:nil];
	}
	NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/SP_Debug2.log"];
	if (![man fileExistsAtPath:logPath])
		[man createFileAtPath:logPath contents:nil attributes:nil];
		//NSLog(@"logpath: %@", logPath);
	NSFileHandle *logHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
	NSString *outputName = outputFile;
	NSString *modeString = nil;
	switch (theMode)
	{
		case kDMGReadWrite: //UDRW
			modeString = @"UDRW";
			break;
			
		case kDMGReadOnly: //UDZO
			modeString = @"UDZO";
			break;
	}
	NSTask *irTask = [[NSTask alloc] init];
	
	
	NSMutableArray *irArgs = [[NSMutableArray alloc] init];
	
	[irArgs addObject:@"convert"];
	
	[irArgs addObject:irString];
	
	[irArgs addObject:@"-format"];
	
	[irArgs addObject:modeString];
	
	[irArgs addObject:@"-o"];
	
	[irArgs addObject:outputFile];
	
	[irTask setLaunchPath:HDIUTIL];
		//[irTask setStandardError:logHandle];
	[irTask setStandardOutput:logHandle];
	[irTask setArguments:irArgs];
	
	[irArgs release];
	
	
		//NSLog(@"hdiutil %@", [[irTask arguments] componentsJoinedByString:@" "]);
	[irTask launch];
	[irTask waitUntilExit];
	
	[irTask release];
	irTask = nil;
	
	return outputName;
	
}

+ (int)migrateFiles:(NSArray *)migration toPath:(NSString *)finalPath
{
	int fileCount = [migration count];
	NSEnumerator *fileEnum = [migration objectEnumerator];
	id theObject = nil;
	while (theObject = [fileEnum nextObject])
	{
		NSString *finalName = [finalPath stringByAppendingPathComponent:[theObject lastPathComponent]];
		if ([FM moveItemAtPath:theObject toPath:finalName error:nil])
			fileCount--;
	}
	return fileCount;
}

+ (int)decryptFilesystem:(NSString *)fileSystem withKey:(NSString *)fileSystemKey
{
	NSTask *vfTask = [[NSTask alloc] init];
	[vfTask setLaunchPath:VFDECRYPT];
	NSString *decrypted = [fileSystem stringByAppendingPathExtension:@"decrypt"];
	[vfTask setArguments:[NSArray arrayWithObjects:@"-i", fileSystem, @"-k", fileSystemKey, @"-o", decrypted, nil]];
		//[vfTask setStandardError:NULLOUT];
		//[vfTask setStandardOutput:NULLOUT];
	[vfTask launch];
	[vfTask waitUntilExit];
	
	int returnStatus = [vfTask terminationStatus];
	[vfTask release];
	vfTask = nil;
	return returnStatus;
}

	//end pwn classes


- (int)extractTetheredFiles:(NSString *)inputFile //deprecated
{
	NSString *uzp = @"/usr/bin/unzip";
	
		//NSFileManager *man = [NSFileManager defaultManager];
	
	NSFileHandle *nullOut = [NSFileHandle fileHandleWithNullDevice];
	
		//NSLog(@"uzp2: %@", uzp2);
	NSTask *unzipTask = [[NSTask alloc] init];
		//unzip -j ~/Desktop/tethered/AppleTV2,1_4.2_8C150_Custom_Restore.ipsw Firmware/dfu/iBSS.k66ap.RELEASE.dfu kernelcache.release.k66 -d ~/Desktop/tethered/
	
	NSString *outputFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Tether"];
	
	[unzipTask setLaunchPath:uzp];
	[unzipTask setArguments:[NSArray arrayWithObjects:@"-j", inputFile, @"Firmware/dfu/iBSS.k66ap.RELEASE.dfu", @"kernelcache.release.k66", @"-d",  outputFolder, nil]];
	[unzipTask setStandardOutput:nullOut];
	[unzipTask setStandardError:nullOut];
	[unzipTask launch];
	[unzipTask waitUntilExit];
	int theTerm = [unzipTask terminationStatus];
		//NSLog(@"helperTask terminated with status: %i",theTerm);
	if (theTerm != 0)
	{
			//NSLog(@"failure unzip %@ to %@", theFile, newPath);
		return (FALSE);
		
	} else if (theTerm == 0){
			//NSLog(@"success unzip %@ to %@", theFile, newPath);
		
		return (TRUE);
	}
	
	return (FALSE);
}

#pragma mark •• extraction classes

+ (int)extractTar:(NSString *)inputTar toLocation:(NSString *)toLocation
{
	NSTask *tarTask = [[NSTask alloc] init];
	NSFileHandle *nullOut = [NSFileHandle fileHandleWithNullDevice];
	
	[tarTask setLaunchPath:@"/usr/bin/tar"];
	[tarTask setArguments:[NSArray arrayWithObjects:@"fxp", inputTar, nil]];
	[tarTask setCurrentDirectoryPath:toLocation];
	[tarTask setStandardError:nullOut];
	[tarTask setStandardOutput:nullOut];
	[tarTask launch];
	[tarTask waitUntilExit];
	
	int theTerm = [tarTask terminationStatus];
	
	[tarTask release];
	tarTask = nil;
	return theTerm;
	
}

+ (int)gunzip:(NSString *)inputFile
{
	NSTask *gzTask = [[NSTask alloc] init];
	NSFileHandle *nullOut = [NSFileHandle fileHandleWithNullDevice];
	
	[gzTask setLaunchPath:@"/usr/bin/gunzip"];
	[gzTask setArguments:[NSArray arrayWithObjects:@"-d", inputFile, nil]];
		//NSLog(@"gunzip %@", [[gzTask arguments] componentsJoinedByString:@" "]);
		//[gzTask setCurrentDirectoryPath:toLocation];
	[gzTask setStandardError:nullOut];
	[gzTask setStandardOutput:nullOut];
	[gzTask launch];
	[gzTask waitUntilExit];
	
	int theTerm = [gzTask terminationStatus];
	
	[gzTask release];
	gzTask = nil;
	return theTerm;
}

+ (int)extractGZip:(NSString *)inputTar toRoot:(NSString *)toLocation
{
	NSTask *tarTask = [[NSTask alloc] init];
	NSFileHandle *nullOut = [NSFileHandle fileHandleWithNullDevice];
	
	[tarTask setLaunchPath:@"/usr/bin/tar"];
	[tarTask setArguments:[NSArray arrayWithObjects:@"fxpz", inputTar, @"-C", toLocation, nil]];
	NSLog(@"tar %@", [[tarTask arguments] componentsJoinedByString:@" "]);
	//[tarTask setCurrentDirectoryPath:toLocation];
	[tarTask setStandardError:nullOut];
	[tarTask setStandardOutput:nullOut];
	[tarTask launch];
	[tarTask waitUntilExit];
	
	int theTerm = [tarTask terminationStatus];
	
	[tarTask release];
	tarTask = nil;
	return theTerm;
	
}


+ (int)extractGZip:(NSString *)inputTar toLocation:(NSString *)toLocation
{
	NSTask *tarTask = [[NSTask alloc] init];
	NSFileHandle *nullOut = [NSFileHandle fileHandleWithNullDevice];
	
	[tarTask setLaunchPath:@"/usr/bin/tar"];
	[tarTask setArguments:[NSArray arrayWithObjects:@"fxpz", inputTar, nil]];
	[tarTask setCurrentDirectoryPath:toLocation];
	[tarTask setStandardError:nullOut];
	[tarTask setStandardOutput:nullOut];
	[tarTask launch];
	[tarTask waitUntilExit];
	
	int theTerm = [tarTask terminationStatus];
	
	[tarTask release];
	tarTask = nil;
	return theTerm;
	
}

+ (int)bunZip:(NSString *)inputTar toRoot:(NSString *)toLocation excluding:(NSString *)excludeFile
{
	NSTask *tarTask = [[NSTask alloc] init];
	NSFileHandle *nullOut = [NSFileHandle fileHandleWithNullDevice];
	NSString *excludeArg = [NSString stringWithFormat:@"--exclude-from=%@", excludeFile];
	[tarTask setLaunchPath:@"/usr/bin/tar"];
	[tarTask setArguments:[NSArray arrayWithObjects:@"fxpj", inputTar,@"-C", toLocation, excludeArg, nil]];
	//[tarTask setCurrentDirectoryPath:toLocation];
	[tarTask setStandardError:nullOut];
	[tarTask setStandardOutput:nullOut];
	[tarTask launch];
	[tarTask waitUntilExit];
	
	int theTerm = [tarTask terminationStatus];
	
	[tarTask release];
	tarTask = nil;
	return theTerm;
	
}

+ (int)bunZip:(NSString *)inputTar toRoot:(NSString *)toLocation
{
	NSTask *tarTask = [[NSTask alloc] init];
	NSFileHandle *nullOut = [NSFileHandle fileHandleWithNullDevice];
	
	[tarTask setLaunchPath:@"/usr/bin/tar"];
	[tarTask setArguments:[NSArray arrayWithObjects:@"fxpj", inputTar,@"-C", toLocation, nil]];
	//[tarTask setCurrentDirectoryPath:toLocation];
	[tarTask setStandardError:nullOut];
	[tarTask setStandardOutput:nullOut];
	[tarTask launch];
	[tarTask waitUntilExit];
	
	int theTerm = [tarTask terminationStatus];
	
	[tarTask release];
	tarTask = nil;
	return theTerm;
	
}

+(int)repackImage:(NSString *)theImage toPath:(NSString *)outputPath withIV:(NSString *)iv key:(NSString *)key originalPath:(NSString *)original
{
	
	NSTask *decryptTask = [[NSTask alloc] init];
	[decryptTask setLaunchPath:IMAGE_TOOL];
	[decryptTask setArguments:[NSArray arrayWithObjects:@"inject", theImage, outputPath, original, iv, key, nil]];
	[decryptTask setStandardError:NULLOUT];
	[decryptTask setStandardOutput:NULLOUT];
	[decryptTask launch];
	[decryptTask waitUntilExit];
	
	int returnStatus = [decryptTask terminationStatus];
	[decryptTask release];
	decryptTask = nil;
	
	return returnStatus;
	
}

+(int)repackImage:(NSString *)theImage toPath:(NSString *)outputPath originalPath:(NSString *)original
{
	
	NSTask *decryptTask = [[NSTask alloc] init];
	[decryptTask setLaunchPath:IMAGE_TOOL];
	[decryptTask setArguments:[NSArray arrayWithObjects:@"inject", theImage, outputPath, original, nil]];
	[decryptTask setStandardError:NULLOUT];
	[decryptTask setStandardOutput:NULLOUT];
	[decryptTask launch];
	[decryptTask waitUntilExit];
	
	int returnStatus = [decryptTask terminationStatus];
	[decryptTask release];
	decryptTask = nil;
	
	return returnStatus;
	
}



+(int)decryptImage:(NSString *)theImage toPath:(NSString *)decPath
{
	
	NSTask *decryptTask = [[NSTask alloc] init];
	[decryptTask setLaunchPath:IMAGE_TOOL];
	[decryptTask setArguments:[NSArray arrayWithObjects:@"extract", theImage, decPath, nil]];
	[decryptTask setStandardError:NULLOUT];
	[decryptTask setStandardOutput:NULLOUT];
	[decryptTask launch];
	[decryptTask waitUntilExit];
	
	int returnStatus = [decryptTask terminationStatus];
	[decryptTask release];
	decryptTask = nil;
	
	return returnStatus;
	
}

+(int)decryptImage:(NSString *)theImage toPath:(NSString *)decPath withIV:(NSString *)iv key:(NSString *)key
{
	
		NSTask *decryptTask = [[NSTask alloc] init];
		[decryptTask setLaunchPath:IMAGE_TOOL];
		[decryptTask setArguments:[NSArray arrayWithObjects:@"extract", theImage, decPath, iv,  key, nil]];
		[decryptTask setStandardError:NULLOUT];
		[decryptTask setStandardOutput:NULLOUT];
		[decryptTask launch];
		[decryptTask waitUntilExit];
		
		int returnStatus = [decryptTask terminationStatus];
		[decryptTask release];
		decryptTask = nil;
		
		return returnStatus;
	
}

+(int)decryptedImageFromData:(NSDictionary *)patchData atRoot:(NSString *)rootPath fromBundle:(NSString *)bundlePath
{
	/*
	 
	 <?xml version="1.0" encoding="UTF-8"?>
	 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	 <plist version="1.0">
	 <dict>
	 <key>File</key>
	 <string>Firmware/dfu/iBSS.k66ap.RELEASE.dfu</string>
	 <key>IV</key>
	 <string>03baadf8801e8b7cdcee5a9f53609d0c</string>
	 <key>Key</key>
	 <string>c9f8bd4e52530ec8ef3e2b5926777f624061a38d09f07785287de6e88353f752</string>
	 <key>Patch</key>
	 <string>iBSS.k66ap.RELEASE.patch</string>
	 <key>TypeFlag</key>
	 <integer>8</integer>
	 </dict>
	 </plist>
	 
	 add my own keys rootPath and bundlePath
	 
	 */
	
	NSString *file = [rootPath stringByAppendingPathComponent:[patchData valueForKey:@"File"]];
	NSString *decrypt = [file stringByAppendingPathExtension:@"decrypt"];
	NSString *repacked = [file stringByAppendingPathExtension:@"2"];
	NSString *patch = [bundlePath stringByAppendingPathComponent:[patchData valueForKey:@"Patch"]];
	NSString *iv = [patchData valueForKey:@"IV"];
	NSString *k = [patchData valueForKey:@"Key"];
	int decryptStatus = [nitoUtility decryptImage:file toPath:decrypt withIV:iv key:k];
	if (decryptStatus == 0)
	{
		NSLog(@"%@ decrypted successfully!",file);
		int patchStatus = [nitoUtility patchFile:decrypt withPatch:patch endMD5:nil];
		if (patchStatus == 0)
		{
			NSLog(@"%@ patched successfully!", file);
			int repack = [nitoUtility repackImage:decrypt toPath:repacked withIV:iv key:k originalPath:file];
			if (repack == 0)
			{
				NSLog(@"%@ repacked successfully!", file);
				[FM removeItemAtPath:file error:nil];
				[FM moveItemAtPath:repacked toPath:file error:nil];
				[FM removeItemAtPath:decrypt error:nil];
				NSLog(@"%@ patched, repacked and replaced successfully!", file);
				return 0;
			}
		}
	}
	
	NSLog(@"patch failed!! bail!");
	return -1;
}

+(int)decryptedPatchFromData:(NSDictionary *)patchData atRoot:(NSString *)rootPath fromBundle:(NSString *)bundlePath
{
	/*
	 
	 <?xml version="1.0" encoding="UTF-8"?>
	 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	 <plist version="1.0">
	 <dict>
	 <key>File</key>
	 <string>Firmware/dfu/iBSS.k66ap.RELEASE.dfu</string>
	 <key>IV</key>
	 <string>03baadf8801e8b7cdcee5a9f53609d0c</string>
	 <key>Key</key>
	 <string>c9f8bd4e52530ec8ef3e2b5926777f624061a38d09f07785287de6e88353f752</string>
	 <key>Patch</key>
	 <string>iBSS.k66ap.RELEASE.patch</string>
	 <key>TypeFlag</key>
	 <integer>8</integer>
	 </dict>
	 </plist>
	 
	 add my own keys rootPath and bundlePath
	 
	 */
	
		//NSLog(@"patchData: %@", patchData);
		//NSString *rootPath = [patchData valueForKey:@"rootPath"];
		//NSString *bundlePath = [patchData valueForKey:@"bundlePath"];
	NSString *file = [rootPath stringByAppendingPathComponent:[patchData valueForKey:@"File"]];
	NSString *decrypt = [file stringByAppendingPathExtension:@"decrypt"];
	NSString *repacked = [file stringByAppendingPathExtension:@"2"];
	NSString *patch = [bundlePath stringByAppendingPathComponent:[patchData valueForKey:@"Patch"]];
	
	if (![FM fileExistsAtPath:patch])
	{
		NSLog(@"patch %@ is missing!, bail!!!!", patch);
	}
	
	NSString *iv = [patchData valueForKey:@"IV"];
	NSString *k = [patchData valueForKey:@"Key"];
	int decryptStatus = [nitoUtility decryptRamdisk:file toPath:decrypt withIV:iv key:k];
	if (decryptStatus == 0)
	{
		NSLog(@"%@ decrypted successfully!",file);
		int patchStatus = [nitoUtility patchFile:decrypt withPatch:patch endMD5:nil];
		if (patchStatus == 0)
		{
			NSLog(@"%@ patched successfully!", file);
			int repack = [nitoUtility repackRamdisk:decrypt toPath:repacked withIV:iv key:k originalPath:file];
			if (repack == 0)
			{
				NSLog(@"%@ repacked successfully!", file);
				[FM removeItemAtPath:file error:nil];
				[FM moveItemAtPath:repacked toPath:file error:nil];
				[FM removeItemAtPath:decrypt error:nil];
				NSLog(@"%@ patched, repacked and replaced successfully!", file);
				return 0;
			}
		}
	}
	
	NSLog(@"patch failed!! bail!");
	return -1;
}

+ (int)patchIBSS:(NSString *)ibssFile
{
	NSString *iBSSPatch = [[NSBundle mainBundle] pathForResource:@"iBSS" ofType:@"patch" inDirectory:@"patches"];
	return [nitoUtility patchFile:ibssFile withPatch:iBSSPatch endMD5:@"3ad1f135589665086d9d7c3ac1ac3b8b"];
	
}

+ (int)createIPSWToFile:(NSString *)theName
{
	if ([FM fileExistsAtPath:theName])
	{
		NSLog(@"previous ipsw exists! %@ deleting!", theName);
		[FM removeItemAtPath:theName error:nil];
	}
	NSLog(@"createIPSWToFile: %@", theName);
	NSTask *zipTask = [[NSTask alloc] init];
	[zipTask setLaunchPath:@"/usr/bin/zip"];
	[zipTask setCurrentDirectoryPath:IPSW_TMP];
	[zipTask setArguments:[NSArray arrayWithObjects:@"-r", theName, @".", @"-x", @".DS_Store", nil]];
		//[zipTask setStandardOutput:NULLOUT];
		//[zipTask setStandardError:NULLOUT];
	[zipTask launch];
	[zipTask waitUntilExit];
	int termStatus = [zipTask terminationStatus];
	[zipTask release];
	zipTask = nil;
	
	return termStatus;
	
}

+ (BOOL)unzipFile:(NSString *)theFile toPath:(NSString *)newPath
{
	
	NSString *uzp = @"/usr/bin/unzip";
	
	//NSFileManager *man = [NSFileManager defaultManager];
	
	NSFileHandle *nullOut = [NSFileHandle fileHandleWithNullDevice];
	
	//NSLog(@"uzp2: %@", uzp2);
	NSTask *unzipTask = [[NSTask alloc] init];
	
	
	[unzipTask setLaunchPath:uzp];
	[unzipTask setArguments:[NSArray arrayWithObjects:@"-o", theFile, @"-d", newPath, @"-x", @"*MACOSX*", nil]];
	[unzipTask setStandardOutput:nullOut];
	[unzipTask setStandardError:nullOut];
	[unzipTask launch];
	[unzipTask waitUntilExit];
	int theTerm = [unzipTask terminationStatus];
	//NSLog(@"helperTask terminated with status: %i",theTerm);
	if (theTerm != 0)
	{
		//NSLog(@"failure unzip %@ to %@", theFile, newPath);
		return (FALSE);
		
	} else if (theTerm == 0){
		//NSLog(@"success unzip %@ to %@", theFile, newPath);
		
		return (TRUE);
	}
	
	return (FALSE);
}

@end
