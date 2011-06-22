//
//  pwnHelperClass.m
//  Seas0nPass
//
//  Created by Kevin Bradley on 4/16/09.
//  Copyright 2009 nito, LLC. All rights reserved.
//

#import "pwnHelperClass.h"
#import "nitoUtility.h"
#import "include/libpois0n.h"

@implementation pwnHelperClass

@synthesize currentBundle;

- (NSString *)convertImage:(NSString *)irString toMode:(int)theMode
{
	NSString *outputName = nil;
	NSString *modeString = nil;
	
	switch (theMode)
	{
		case 0: //UDRW
			outputName = [[self theDownloadPath] stringByAppendingPathComponent:@"converted.dmg"];
			modeString = @"UDRW";
			break;
			
		case 1: //
			outputName = [[self theDownloadPath] stringByAppendingPathComponent:@"final.dmg"];
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
	
	[irArgs addObject:outputName];
	
	[irTask setLaunchPath:@"/usr/bin/hdiutil"];
	
	[irTask setArguments:irArgs];
	
	[irArgs release];
	
	
	//NSLog(@"hdiutil %@", [[irTask arguments] componentsJoinedByString:@" "]);
	[irTask launch];
	//[self setCurrentTask:irTask];
	[irTask waitUntilExit];
	return outputName;
	
}

- (NSString *)theDownloadPath {
	
    NSString *thePath = [processDict valueForKey:@"download"];
	return thePath;
}



- (NSDictionary *)processDict {
    return [[processDict retain] autorelease];
}

- (void)setProcessDict:(NSDictionary *)value {
    if (processDict != value) {
        [processDict release];
        processDict = [value copy];
    }
}

- (void)changeOwner:(NSString *)theOwner onFile:(NSString *)theFile isRecursive:(BOOL)isR
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

- (void)changePermissions:(NSString *)perms onFile:(NSString *)theFile isRecursive:(BOOL)isR
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


- (int)patchFstab:(NSDictionary *)patchDict withRoot:(NSString *)mountedPath
{
	NSString *inputFile = [mountedPath stringByAppendingPathComponent:[patchDict valueForKey:@"inputFile"]];
	NSString *thePatch = [patchDict valueForKey:@"patchFile"];
	NSString *md5 = [patchDict valueForKey:@"md5"];
	
	return [nitoUtility patchFile:inputFile withPatch:thePatch endMD5:md5];
}

- (int)installCydia:(NSString *)cydiaPackage withRoot:(NSString *)mountedPath

{
	return [nitoUtility extractGZip:cydiaPackage toRoot:mountedPath];
}

- (void)installWifi:(NSString *)wifiFile withRoot:(NSString *)mountedPath
{
	[FM copyItemAtPath:wifiFile toPath:[mountedPath stringByAppendingPathComponent:@"/Library/Preferences/SystemConfiguration/com.apple.wifi.plist"] error:nil];
}

- (void)installSSHKey:(NSString *)sshKey withRoot:(NSString *)mountedPath
{
	NSString *sshFolder = [mountedPath stringByAppendingPathComponent:@"var/root/.ssh"];
	[FM createDirectoryAtPath:sshFolder withIntermediateDirectories:YES attributes:nil error:nil];
	
	if([FM copyItemAtPath:sshKey toPath:[sshFolder stringByAppendingPathComponent:@"authorized_keys"] error:nil])
	{
		[self changeOwner:@"root:wheel" onFile:sshFolder isRecursive:YES];
		NSLog(@"authorized key installed successfully!");
	}
	
	
}

- (int)runBundleCommands:(NSArray *)commands onFiles:(NSString *)thePath
{
	id theAction = nil;
	int status = 0;
	NSEnumerator *dictEnum = [commands objectEnumerator];
	while (theAction = [dictEnum nextObject]) {
		
		status = [self performAction:theAction onVolume:thePath];
	}
	
	return status;
}

- (int)stash:(NSString *)scriptFile withRoot:(NSString *)mountedPath
{
	return [nitoUtility runScript:scriptFile withInput:mountedPath];
}

- (int)fileSystemPatches:(NSString *)theVolume
{
	int status = 0;
	if ([currentBundle coreFilesInstallation] != nil)
	{
	
		NSDictionary *cfi = [currentBundle coreFilesInstallation];
		id coreFile = nil;
		NSEnumerator *dictEnum = [cfi objectEnumerator];
		while (coreFile = [dictEnum nextObject]) {
		
			status = [self performAction:coreFile onVolume:theVolume];
			if (status != 0)
			{
				NSLog(@"coreFileInstallation failed!! bail!");
				return -1;
			}
		}
	}

	
	
	
	if ([currentBundle filesystemJailbreak] != nil)
	{
		NSArray *cfi = [currentBundle filesystemJailbreak];
		id coreFile = nil;
		NSEnumerator *dictEnum = [cfi objectEnumerator];
		while (coreFile = [dictEnum nextObject]) {
			
			status = [self performAction:coreFile onVolume:theVolume];
			if (status != 0)
			{
				NSLog(@"filesystemJailbreak failed!! bail!");
				return -1;
			}
		}
	}
	return status;
}

- (int)performAction:(NSDictionary *)actionDict onVolume:(NSString *)theVolume
{
	NSString *actionType = [actionDict valueForKey:@"Action"];
	if ([actionType isEqualToString:@"Add"])
	{
		return [self addAction:actionDict toVolume:theVolume];
	} else if ([actionType isEqualToString:@"Patch"])
	{
		return [self patchAction:actionDict toVolume:theVolume];
		
	} else if ([actionType isEqualToString:@"SetPermission"])
	{
	
		return [self permissionAction:actionDict toVolume:theVolume];
		
	} else if ([actionType isEqualToString:@"SetOwner"])
	{
		return [self ownerAction:actionDict toVolume:theVolume];
	} else {
		NSLog(@"unrecognized action: %@", actionType);
		return -1;
	}
}

- (int)ownerAction:(NSDictionary *)actionDict toVolume:(NSString *)theVolume
{
	NSString *inputFile = [theVolume stringByAppendingPathComponent:[actionDict valueForKey:@"File"]];
	NSString *owner = [actionDict valueForKey:@"Owner"];
	NSLog(@"set %@ to %@", inputFile, owner);
	[nitoUtility changeOwner:owner onFile:inputFile isRecursive:FALSE];
	return 0;
}

- (int)permissionAction:(NSDictionary *)actionDict toVolume:(NSString *)theVolume
{
	NSLog(@"action: %@", actionDict);
	NSString *inputFile = [theVolume stringByAppendingPathComponent:[actionDict valueForKey:@"File"]];
	NSString *permission = [actionDict valueForKey:@"Permission"];
	NSLog(@"set %@ to %@", inputFile, permission);
	[nitoUtility changePermissions:permission onFile:inputFile isRecursive:FALSE];
	return 0;
}

- (int)patchAction:(NSDictionary *)actionDict toVolume:(NSString *)theVolume
{

		//NSLog(@"patchAction: %@ toVolume: %@", actionDict, theVolume);
	NSString *inputFile = [theVolume stringByAppendingPathComponent:[actionDict valueForKey:@"File"]];
	NSString *patch = [self.currentBundle.bundlePath stringByAppendingPathComponent:[actionDict valueForKey:@"Patch"]];
	return [nitoUtility patchFile:inputFile withPatch:patch endMD5:nil];
	
}

- (void)sendCommand:(id)theKbag
{
	
		//NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/SP_Keys.log"];
		//NSString *duplicate = [[logPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"txt"];
		//[FM removeFileAtPath:logPath handler:nil];
		//FILE* file = freopen([logPath fileSystemRepresentation], "w+", stdout);
	
	NSString *command = [NSString stringWithFormat:@"go aes dec %@", theKbag];
		//NSLog(@"command: %@", command);
	int quit = 0;
	
	irecv_error_t error = 0;
	irecv_init();
	irecv_client_t client = NULL;
	if (irecv_open(&client) != IRECV_E_SUCCESS)
	{
		NSLog(@"fail!");
		return;
		
	}
	
		//irecv_set_debug_level(20);
		//irecv_set_interface(client, 0, 0);
	irecv_set_configuration(client, 1);
	
		//irecv_event_subscribe(client, IRECV_PRECOMMAND, &precommand_cb, NULL);
		//irecv_event_subscribe(client, IRECV_POSTCOMMAND, &postcommand_cb, NULL);
	while (!quit) {
		irecv_set_interface(client, 0, 0);
		irecv_set_interface(client, 1, 1);
		error = irecv_receive(client);
		
			//irecv_set_interface(client, 1, 0);	
		error = irecv_send_command(client, [command UTF8String]);
		error = irecv_receive(client);
			//debug("%s\n", irecv_strerror(error));
		quit = 1;
	}
	irecv_close(client);
	irecv_exit();
	
	/*
		fclose(file);
	
	[FM copyItemAtPath:logPath toPath:duplicate error:nil];
	NSString *me = [NSString stringWithContentsOfFile:duplicate];
	NSLog(@"ME: %@", me);
	*/
	
	
	
	
	
}

- (int)addAction:(NSDictionary *)actionDict toVolume:(NSString *)theVolume
{

		//var/db/.launchd_use_gmalloc
	
	NSString *theFile = [actionDict valueForKey:@"File"];
	NSString *pathCompare = [[actionDict valueForKey:@"Path"] lastPathComponent];
	
	if ([theFile isEqualToString:@"libgmalloc.dylib"])
	{
		NSString *gmallocUse = [theVolume stringByAppendingPathComponent:@"var/db/.launchd_use_gmalloc"];
		[FM createFileAtPath:gmallocUse contents:nil attributes:nil];
		NSLog(@"%@ added successfully!", gmallocUse);
	}
	NSString *path = [theVolume stringByAppendingPathComponent:[actionDict valueForKey:@"Path"]];
	NSString *inputFile = [self.currentBundle.bundlePath stringByAppendingPathComponent:theFile];
	if ([FM fileExistsAtPath:path])
		{
				//may need to switcheroo?? //punchd
			NSLog(@"comparing File: %@ to Path: %@", theFile, pathCompare);
			if (![theFile isEqualToString:pathCompare])
			{
				NSString *path2 = [theVolume stringByAppendingPathComponent:[actionDict valueForKey:@"Path"]];
				path2 = [[path2 stringByDeletingLastPathComponent] stringByAppendingPathComponent:theFile];
				[FM moveItemAtPath:path toPath:path2 error:nil];
			} else { //just remove the file
				
				[FM removeItemAtPath:path error:nil];
			}
			
		}
	if([FM copyItemAtPath:inputFile toPath:path error:nil])
	{
		NSLog(@"installed %@ successfully!",[actionDict valueForKey:@"File"] );
		[nitoUtility changeOwner:@"root:wheel" onFile:path isRecursive:YES];
		[nitoUtility changePermissions:@"755" onFile:path isRecursive:YES];
		return 0;
	} else{
		NSLog(@"%@ installation failed!", [actionDict valueForKey:@"File"]);
		return -1;
	}
	
	return -1;
	
}

- (void)installDebFilesFromPath:(NSString *)debPath toRoot:(NSString *)rootPath
{
	id theDeb = nil;
	NSString *outputPath = [rootPath stringByAppendingPathComponent:@"var/root/Media/Cydia/AutoInstall"];
	
	NSDirectoryEnumerator *files = [[NSFileManager defaultManager] enumeratorAtPath:debPath];
	while (theDeb = [files nextObject]) 
	{
		NSString *extension = [theDeb pathExtension];
		if ([[extension lowercaseString] isEqualToString:@"deb"])
		{
			NSString *fullpath = [debPath stringByAppendingPathComponent:theDeb];
			NSString *finalPath = [outputPath stringByAppendingPathComponent:theDeb];
			if([FM copyItemAtPath:fullpath toPath:finalPath error:nil])
			{
				NSLog(@"installed: %@ to %@ successfully!", fullpath, finalPath);
			} else {
				NSLog(@"install: %@ to %@ failed!", fullpath, finalPath);
			}
			
		}
	}
	
}

- (int)patchDmg:(NSString *)theDMG
{
	/*
	 
	 temporary
	 
	 using this to be lazy and automate the process of preparing the pt payload for tarring
	 
	 
	 
	
	NSBundle *installerBundle = [NSBundle bundleWithPath:[[self processDict] valueForKey:@"CydiaBundle"]];
	NSArray *commands = [[installerBundle infoDictionary] valueForKey:@"Commands"];
	NSString *fileLocation = [[installerBundle bundlePath] stringByAppendingPathComponent:@"files"];
	[self runBundleCommands:commands onFiles:fileLocation];
	*/
	int status = 0;
	
		//NSLog(@"processDictionary %@", [self processDict]);
	int enableScripting = [[[self processDict] valueForKey:@"enableScripting"] intValue];
	if (enableScripting == 0)
	{
		[self enableAssistiveDevices];
	}
	//[self changeStatus:@"Converting image to read write..."];
	//NSLog(@"Converting image to read write...");
	//NSString *outputPath = [self convertImage:theDMG toMode:0]; //convert image to readwrite
	
	NSLog(@"Mounting image...");
	[self changeStatus:@"Mounting image..."];
	NSString *mountImage = [nitoUtility mountImage:theDMG]; //mount converted image
	
	if (mountImage == nil)
	{
		
		NSLog(@"FAIL!! ABORT!");
		NSString *failed = @"Filesystem mount failed!!";
		NSDictionary *failDict = [NSDictionary dictionaryWithObject:failed forKey:@"AbortReason"];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"pwnFailed" object:nil userInfo:failDict deliverImmediately:YES];
		return -1;
	}
	[self changeStatus:@"Patching filesystem..."];
	NSLog(@"Patching filesystem...");
	status = [self fileSystemPatches:mountImage];
		//NSLog(@"status %i", status);
	
	if (status != 0)
	{
		[nitoUtility unmountVolume:mountImage];
		NSLog(@"FAIL!! ABORT!");
		NSString *failed = @"Filesystem patches failed!!";
		NSDictionary *failDict = [NSDictionary dictionaryWithObject:failed forKey:@"AbortReason"];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"pwnFailed" object:nil userInfo:failDict deliverImmediately:YES];
		return -1;
	}
	 
	
	/*
	NSLog(@"Patching fstab...");
	NSDictionary *patchDict = [[self processDict] valueForKey:@"fstabPatch"];
	NSString *inputFile = [mountImage stringByAppendingPathComponent:[patchDict valueForKey:@"inputFile"]];
	NSString *thePatch = [patchDict valueForKey:@"patchFile"];
	NSString *md5 = [patchDict valueForKey:@"md5"];
	[nitoUtility patchFile:inputFile withPatch:thePatch endMD5:md5];
	*/
	

	
	
	[self changeStatus:@"Installing Software..."];
	NSLog(@"installing Software...");
	[self installCydia:[[self processDict] valueForKey:@"cydia"] withRoot:mountImage];

	[self installDebFilesFromPath:[[self processDict] valueForKey:@"debs"] toRoot:mountImage];
	
	if ([[self processDict] valueForKey:@"wifi"] != nil)
	{
		[self changeStatus:@"Installing wifi.plist..."];
		NSLog(@"installing wifi.plist...");
		[self installWifi:[[self processDict] valueForKey:@"wifi"] withRoot:mountImage];
	}
	
	if ([[self processDict] valueForKey:@"sigServer"] != nil)
	{
		[self useCydiaServer];
		NSLog(@"redirecting 74.208.10.249 gs.apple.com...");
	}
	
	if ([[self processDict] valueForKey:@"sshKey"] != nil)
	{
		[self changeStatus:@"Installing id_rsa.pub..."];
		NSLog(@"Installing id_rsa.pub...");
		[self installSSHKey:[[self processDict] valueForKey:@"sshKey"] withRoot:mountImage];
	}
	
		//[self changeStatus:@"Stash it away man!..."];
		NSLog(@"Stash it away man!...");
		[self stash:[[self processDict] valueForKey:@"stash"] withRoot:mountImage];
	
	NSDictionary *ep = [currentBundle extraPatch];
	if (ep != nil)
	{
		NSLog(@"4.3 detected, installing extra status patch");
		NSString *target = [mountImage stringByAppendingPathComponent:[ep valueForKey:@"Target"]];
		NSString *patch = [ep valueForKey:@"Patch"];
		NSString *md5 = [ep valueForKey:@"md5"];
		[nitoUtility patchFile:target withPatch:patch endMD5:md5];
		
		
	}
	
	
	
	
	NSLog(@"Unmounting Image...");
	[self changeStatus:@"Unmounting Image..."];
	

	[nitoUtility unmountVolume:mountImage];
	
	NSString *ogDMG = [processDict valueForKey:@"os"];
	
	NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys: theDMG, @"Path", ogDMG, @"os", nil];
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"pwnFinished" object:nil userInfo:userInfo deliverImmediately:YES];
	return -1;
}

- (void)changeStatus:(NSString *)theStatus
{
	 NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys: theStatus, @"Status", nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"statusChanged" object:nil userInfo:userInfo deliverImmediately:YES];
	
}

- (int)permissionedCopy:(NSString *)inputFile toPath:(NSString *)outputFile
{
	NSTask *cpTask = [[NSTask alloc] init];
	//NSFileHandle *nullOut = [NSFileHandle fileHandleWithNullDevice];
	
	[cpTask setLaunchPath:@"/bin/cp"];
	[cpTask setArguments:[NSArray arrayWithObjects:@"-rp", inputFile, outputFile, nil]];
	
	//[cpTask setStandardOutput:nullOut];
	//[cpTask setStandardError:nullOut];
    [cpTask launch];
	[cpTask waitUntilExit];
	
	int tStatus = [cpTask terminationStatus];
	return tStatus;
}

- (void)useCydiaServer
{
	NSMutableString *hosts = [[NSMutableString alloc]initWithContentsOfFile:@"/etc/hosts"];
	NSRange range = [hosts rangeOfString:@"74.208.10.249 gs.apple.com"];
	if ( range.location == NSNotFound )
	{
		[hosts appendString:@"\n74.208.10.249 gs.apple.com\n"];
		[hosts writeToFile:@"/etc/hosts" atomically:YES];
		[hosts release];
	}
}


- (void)installPackages:(NSString *)theDMG
{
	NSFileManager *man = [NSFileManager defaultManager];
	
	NSString *packageLocale = [processDict valueForKey:@"Packages"];
	NSArray *fC = [man contentsOfDirectoryAtPath:packageLocale error:nil];
		//NSArray *fC = [man directoryContentsAtPath:packageLocale];
	
	//NSLog(@"fc: %@ finalLocale: %@", fC, finalLocale);
	if ([fC count] > 0)
	{
		int i;
		for (i = 0; i < [fC count]; i++)
		{
			NSString *currentItem = [fC objectAtIndex:i];
			NSString *copyFrom = [packageLocale stringByAppendingPathComponent:currentItem];
			if ([[currentItem pathExtension] isEqualToString:@"bz2"])
			{
				
				NSLog(@"Installing: %@ to %@", copyFrom, theDMG);
				//[self nCurlSetProgressText:[NSString stringWithFormat:@"Installing %@",[copyFrom lastPathComponent]] setDeterminate:FALSE];
				
				NSString *filesRoot = [[self runPath] stringByDeletingLastPathComponent];
				NSString *excludeFile = [filesRoot stringByAppendingPathComponent:@"excludes"];
				
				//NSString *excludeFile = [[NSBundle mainBundle] pathForResource:@"excludes" ofType:@""];
				
				[nitoUtility bunZip:copyFrom toRoot:theDMG excluding:excludeFile];
				
			}
			
		}
		
	}
}

- (BOOL)enableAssistiveDevices
{
	NSLog(@"enabling assitive devices");
	NSString *assitivePath = @"/private/var/db/.AccessibilityAPIEnabled";
	if([[NSFileManager defaultManager] createFileAtPath:assitivePath contents:nil attributes:nil])
		return YES;
	
	return NO;
}



- (NSString *)runPath {
    return [[runPath retain] autorelease];
}

- (void)setRunPath:(NSString *)value {
    if (runPath != value) {
        [runPath release];
        runPath = [value copy];
    }
}

- (NSString *)appSupportFolder
{
	NSString *theFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Application Support/tetherKit"];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:theFolder])
		[FM createDirectoryAtPath:theFolder withIntermediateDirectories:YES attributes:nil error:nil];
	return theFolder;
	
}

@end
