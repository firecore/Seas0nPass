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
	

#define NULLOUT [NSFileHandle fileHandleWithNullDevice]

@implementation nitoUtility

@synthesize delegate, enableScripting;

- (id)init
{
	
	self = [super init];
	
	return self;
}

- (void)dealloc {
	
	[super dealloc];
}



#pragma mark •• dmg classes

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
	
	[irTask setStandardError:hdip];
	[irTask setStandardOutput:hdip];
		//NSLog(@"hdiutil %@", [[irTask arguments] componentsJoinedByString:@" "]);
	[irTask launch];
	[irTask waitUntilExit];
	
	NSData *outData;
	outData = [hdih readDataToEndOfFile];
	NSString *the_error;
	NSPropertyListFormat format;
	id plist;
	plist = [NSPropertyListSerialization propertyListFromData:outData
											 mutabilityOption:NSPropertyListImmutable 
													   format:&format
											 errorDescription:&the_error];
	
	if(!plist)
		
	{
		
		NSLog(the_error);
		
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
	
	[irTask setStandardError:hdip];
	[irTask setStandardOutput:hdip];
	//NSLog(@"hdiutil %@", [[irTask arguments] componentsJoinedByString:@" "]);
	[irTask launch];
	[irTask waitUntilExit];
	
	NSData *outData;
	outData = [hdih readDataToEndOfFile];
	NSString *the_error;
	NSPropertyListFormat format;
	id plist;
	plist = [NSPropertyListSerialization propertyListFromData:outData
											 mutabilityOption:NSPropertyListImmutable 
													   format:&format
											 errorDescription:&the_error];
	
	if(!plist)
		
	{
		
		NSLog(the_error);
		
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
	[mdTask waitUntilExit];
	NSData *outData;
	outData = [mdih readDataToEndOfFile];
	NSString *temp = [[NSString alloc] initWithData:outData encoding:NSASCIIStringEncoding];
	temp = [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	//int theTerm = [mdTask terminationStatus];
	NSLog(@"md5: %@ against: %@ " , temp, properMD5);
	if ([temp isEqualToString:properMD5])
	{
		
		return YES;
		
	} 
	
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

-(int)modifyPT:(NSString *)ptFile //deprecated?
{
	NSString *mountFile = [nitoUtility mountImage:ptFile];
	NSFileManager *man = [NSFileManager defaultManager];
	if (mountFile != nil)
	{
		NSString *pwnageTool = [mountFile stringByAppendingPathComponent:@"PwnageTool.app"];
		NSString *finalLocation = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Tether/PwnageTool.app"];
		[man copyItemAtPath:pwnageTool toPath:finalLocation error:nil];
		if ([man fileExistsAtPath:finalLocation])
		{
			NSLog(@"extract PT success!");
			[nitoUtility unmountVolume:mountFile];
			NSString *tgzFile = [[NSBundle mainBundle] pathForResource:@"PT" ofType:@"tgz"];
			if([nitoUtility extractGZip:tgzFile toRoot:[finalLocation stringByDeletingLastPathComponent]] == 0)
			{
				NSLog(@"PT Modified Successfully!");
				[[NSNotificationCenter defaultCenter] postNotificationName:@"FinishedModPT" object:nil];
				return 0;
			}
		
		}
	}
	return -1;
	
}

+ (void)createTempSetup
{
	if ([FM fileExistsAtPath:IPSW_TMP])
	{
		[FM removeItemAtPath:IPSW_TMP error:nil];
	}
	[FM createDirectoryAtPath:IPSW_TMP withIntermediateDirectories:YES attributes:nil error:nil];
	
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


- (void)patchFilesystem:(NSString *)inputFilesystem
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
		if (convertImage =! nil)
		{
			NSLog(@"converted to read write successfully: %@", rwFS); 
				//need to take over with root access here for 3-8
			[self permissionedPatch:rwFS withOriginal:inputFilesystem];
		}
	} 
	
	
	
}

- (void)permissionedPatch:(NSString *)theFile withOriginal:(NSString *)originalDMG
{
	
	NSString *theDict = [self pwnctionaryFromPath:theFile original:originalDMG withBundle:nil];
	
	NSString *helpPath = [[NSBundle mainBundle] pathForResource: @"dbHelper" ofType: @""];
	
	NSTask *pwnHelper = [[NSTask alloc] init];
	
	[pwnHelper setLaunchPath:helpPath];
	
	[pwnHelper setArguments:[NSArray arrayWithObjects:@"nil", theDict, nil]];
	
	[pwnHelper launch];
	
	[pwnHelper waitUntilExit];
	
	[pwnHelper release];
	
	pwnHelper = nil;
}

- (NSString *)pwnctionaryFromPath:(NSString *)mountedPath original:(NSString *)original withBundle:(NSDictionary *)theBundle
{
	NSString *es = [NSString stringWithFormat:@"%i", (int)[self enableScripting]];
	NSMutableDictionary *bundleDict = [[NSMutableDictionary alloc] init];
	[bundleDict setObject:es forKey:@"enableScripting"];
	[bundleDict setObject:mountedPath forKey:@"patch"];
	[bundleDict setObject:original forKey:@"os"];
	NSMutableDictionary *fstabDict = [[NSMutableDictionary alloc] init];
	[fstabDict setObject:@"/etc/fstab" forKey:@"inputFile"];
	[fstabDict setObject:[[NSBundle mainBundle] pathForResource:@"fstab" ofType:@"patch" inDirectory:@"patches"] forKey:@"patchFile"];
	[fstabDict setObject:@"e34d097a1c6dc7fd95db41879129327b" forKey:@"md5"];
	[bundleDict setObject:[fstabDict autorelease] forKey:@"fstabPatch"];

	[bundleDict setObject:CYDIA_TAR forKey:@"cydia"];
	[bundleDict setObject:SPACE_SCRIPT forKey:@"stash"];
		//TODO: custom bundles
	NSString *cliPath = @"/tmp/031231";
	[bundleDict writeToFile:cliPath atomically:YES];
	return cliPath;	
	 
}

+ (int)runScript:(NSString *)theScript withInput:(NSString *)theInput
{
	setuid(0);
	setgid(0);
	NSString *command = [NSString stringWithFormat:@"/bin/sh %@ %@", theScript, theInput];
	int sysReturn = system([command UTF8String]);
	return sysReturn;
}


+ (int)decryptRamdisk:(NSString *)theRamdisk toPath:(NSString *)outputDisk withIV:(NSString *)iv key:(NSString *)key

{
	NSTask *decryptTask = [[NSTask alloc] init];
	[decryptTask setLaunchPath:XPWN];
	[decryptTask setArguments:[NSArray arrayWithObjects:theRamdisk, outputDisk, @"-iv", iv, @"-k", key, nil]];
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
	[decryptTask setArguments:[NSArray arrayWithObjects:theRamdisk, outputDisk, @"-iv", iv, @"-k", key, @"-t", original, nil]];
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
					return 0;
				}
			}
			return 0;
			
		}
			//check to see if md5 is proper
		if ([nitoUtility checkFile:patchedFile againstMD5:desiredMD5])
		{
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
	
	[irTask setArguments:irArgs];
	
	[irArgs release];
	
	
		//NSLog(@"hdiutil %@", [[irTask arguments] componentsJoinedByString:@" "]);
	[irTask launch];
	[irTask waitUntilExit];
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
	[vfTask setStandardError:NULLOUT];
	[vfTask setStandardOutput:NULLOUT];
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

+ (int)extractGZip:(NSString *)inputTar toRoot:(NSString *)toLocation
{
	NSTask *tarTask = [[NSTask alloc] init];
	NSFileHandle *nullOut = [NSFileHandle fileHandleWithNullDevice];
	
	[tarTask setLaunchPath:@"/usr/bin/tar"];
	[tarTask setArguments:[NSArray arrayWithObjects:@"fxpz", inputTar, @"-C", toLocation, nil]];
	//NSLog(@"tar %@", [[tarTask arguments] componentsJoinedByString:@" "]);
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

+ (int)patchIBSS:(NSString *)ibssFile
{
	NSString *iBSSPatch = [[NSBundle mainBundle] pathForResource:@"iBSS" ofType:@"patch" inDirectory:@"patches"];
	return [nitoUtility patchFile:ibssFile withPatch:iBSSPatch endMD5:@"3ad1f135589665086d9d7c3ac1ac3b8b"];
	
}

+ (void)createIPSWToFile:(NSString *)theName
{
	NSTask *zipTask = [[NSTask alloc] init];
	[zipTask setLaunchPath:@"/usr/bin/zip"];
	[zipTask setCurrentDirectoryPath:IPSW_TMP];
	[zipTask setArguments:[NSArray arrayWithObjects:@"-r", theName, @".", @"-x", @".DS_Store", nil]];
	[zipTask setStandardOutput:NULLOUT];
	[zipTask setStandardError:NULLOUT];
	[zipTask launch];
	[zipTask waitUntilExit];
	[zipTask release];
	zipTask = nil;
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
