//
//  tetherKitAppDelegate.m
//  Seas0nPass
//
//  Created by Kevin Bradley on 12/27/10.
//  Copyright 2011 Fire Core, LLC. All rights reserved.
//  

//  Portions Copyright 2010 Joshua Hill & Chronic-Dev Team
//  Portions Copyright 2010 planetbeing & iPhone-Dev Team

// libpois0n/libsyringe by Joshua Hill & Chronic-Dev Team. ( feel free to help me update these credits )
// xpwntool by planetbeing
// limera1n exploit by George Hotz



#import <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

#import "tetherKitAppDelegate.h"
#import "nitoUtility.h"
#import "include/libpois0n.h"
#define kPTName @"PwnageTool_4.1.2.dmg"
#define kIPSWName @"AppleTV2,1_4.2.1_8C154_Restore.ipsw"
#define kPTDownloadLocation @"http://iphoneroot.com/download/PwnageTool_4.1.2.dmg"
#define kIPSWDownloadLocation @"http://appldnld.apple.com/AppleTV/061-9978.20101214.gmabr/AppleTV2,1_4.2.1_8C154_Restore.ipsw"
#define DL [tetherKitAppDelegate downloadLocation]
#define PTMD5 @"e8f4d590c8fe62386844d6a2248ae609"
#define IPSWMD5 @"3fe1a01b8f5c8425a074ffd6deea7c86"
#define KCACHE @"kernelcache.release.k66"
#define iBSSDFU @"iBSS.k66ap.RELEASE.dfu"
#define HCIPSW [DL stringByAppendingPathComponent:@"AppleTV2,1_4.2.1_8C154_Restore.ipsw"]
#define CUSTOM_RESTORE @"AppleTV2,1_4.2.1_8C154_Custom_Restore.ipsw"
@implementation tetherKitAppDelegate

@synthesize window, downloadIndex, processing, enableScripting, firstView, secondView, poisoning;

/*
 
 
 this application is a bit of an amalgam of code from libsyringe, a few random classes from hawkeye and atvPwn and then iphone wiki notes / deciphering what pwnagetool does
 by hand / creation of the bundles for PwnageTool
 
 this could be seperated into several (or at least a few) different classes, but TBH, im lazy. The only reason im even putting these comments in here are the inevitability 
 of having to open source this because i know at very least libsyringe is GPL (and i wouldn't be surprised if xpwn is as well).
 
 */

	/* probably not using this callback data variable properly, but i couldnt figure out how else to set download progress from the double values sent during uploading of iBSS and kernelcache */

void print_progress(double progress, void* data) {
	int i = 0;
	if(progress < 0) {
		return;
	}
	
	if(progress > 100) {
		progress = 100;
	}
	[data setDownloadProgress:progress];
	printf("\r[");
	for(i = 0; i < 50; i++) {
		if(i < progress / 2) {
			printf("=");
		} else {
			printf(" ");
		}
	}
	
	printf("] %3.1f%%", progress);
	if(progress == 100) {
		printf("\n");
	}
}

- (char *)iBSS
{
	NSString *iBSS = [DL stringByAppendingPathComponent:iBSSDFU];
	return [iBSS UTF8String];
}

- (char *)kernelcache
{
	NSString *kc = [DL stringByAppendingPathComponent:KCACHE];
	return [kc UTF8String];
}

- (NSString *)kcacheString
{
	return [DL stringByAppendingPathComponent:KCACHE];
}

- (NSString *)iBSSString
{
	return [DL stringByAppendingPathComponent:iBSSDFU];
}

- (NSImage *)imageForMode:(int)inputMode
{
	NSImage *theImage = nil;
	
	switch (inputMode) {
			
		case kSPATVRestoreImage:
			
			theImage = [NSImage imageNamed:@"restore"];
			
			break;
		
		case kSPATVTetheredImage:
			
			theImage = [NSImage imageNamed:@"tether"];
			
			break;
			
		case kSPSuccessImage:
			
			theImage = [NSImage imageNamed:@"success"];
			break;
			
		case kSPIPSWImage:
			
			theImage = [NSImage imageNamed:@"ipsw"];
			break;
			
		case kSPATVTetheredRemoteImage:
			
			theImage = [NSImage imageNamed:@"tetheredRemote"];
	}
	
	return theImage;
}

- (void)startupAlert
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL warningShown = [defaults boolForKey:@"SPWarningShown"];
	if (warningShown == TRUE)
		return;
	
	NSAlert *startupAlert = [NSAlert alertWithMessageText:@"Warning! Please read carefully." defaultButton:@"OK" alternateButton:@"More Info" otherButton:@"Cancel" informativeTextWithFormat:@"Currently the jailbreak for the 4.1.1 (iOS 4.2.1) software is 'tethered'. A tethered jailbreak requires the AppleTV to be connected to a computer for a brief moment during startup.\n\nSeas0nPass makes this as easy as possible, but please do not proceed unless you are comfortable with this process."];
	int button = [startupAlert runModal];

	switch (button) {
		case 0: //more info
			
			[self userGuides:nil];
			break;
			
		case 1: //okay

			break;
			
		case -1: //cancel and quit!!
				[[NSApplication sharedApplication] terminate:self];
			break;
			
	}
	
	[defaults setBool:YES forKey:@"SPWarningShown"];
	
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
	NSString *wf = [[tetherKitAppDelegate applicationSupportFolder] stringByAppendingPathComponent:@"com.apple.wifi.plist"];
	
	if ([FM fileExistsAtPath:wf]) { return wf; }
	
	return nil;
	
}

+ (NSString *)ipswFile
{
	return [DL stringByAppendingPathComponent:@"AppleTV2,1_4.2.1_8C154_Restore.ipsw"];
}
	//originally we downloaded and patched pwnagetool rather than making a custom ipsw, some deprecated code still in here commented out.

- (BOOL)filesToDownload
{
		//NSMutableArray *filesToDownload = [[NSMutableArray alloc] init];
	NSFileManager *man = [NSFileManager defaultManager];
	NSString *ipsw = [tetherKitAppDelegate ipswFile];

	if ([man fileExistsAtPath:ipsw])
	{
		if ([nitoUtility checkFile:ipsw againstMD5:IPSWMD5] == FALSE)
		{
			NSLog(@"ipsw MD5 Invalid, removing file");
			[man removeItemAtPath:ipsw error:nil];
		}
		
	}
	

	if (![man fileExistsAtPath:ipsw])
	{
		[downloadFiles addObject:kIPSWDownloadLocation];
	}
		if ([downloadFiles count] > 0)
		{
			return TRUE;
		} else {
			return FALSE;
		}
	
	return FALSE;
	
}

- (void)showProgress
{
	[buttonOne setEnabled:FALSE];
	[bootButton setEnabled:FALSE];
	self.processing = TRUE;
	[downloadBar startAnimation:self];
	[downloadBar setHidden:FALSE];
	[downloadBar setNeedsDisplay:TRUE];
	[self setDownloadProgress:0];
		[cancelButton setEnabled:FALSE];
}

- (void)hideProgress
{
	[buttonOne setEnabled:TRUE];
	[bootButton setEnabled:TRUE];
	self.processing = FALSE;
	[downloadBar stopAnimation:self];
	[downloadBar setHidden:YES];
	[downloadBar setNeedsDisplay:YES];
		[cancelButton setEnabled:TRUE];
}

- (IBAction)cancel:(id)sender
{
	if ([downloadFile respondsToSelector:@selector(cancel)])
	{
			//NSLog(@"cancel?");
		[downloadFile cancel];
			//self.processing = FALSE;
		[self hideProgress];
		
	}
	if (self.poisoning == TRUE)
	{
		pois0n_exit();
		self.poisoning = FALSE;
		self.processing = FALSE;
	}
	if (self.processing == FALSE)
	{
		[window setContentView:self.firstView];
		[window display];
	}
	
	
}

	//this code is almost identical to the tetheredboot code

- (int)enterDFU
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	self.poisoning = TRUE;
	[self showProgress];
		//[cancelButton setEnabled:TRUE];
	int result = 0;
	irecv_error_t ir_error = IRECV_E_SUCCESS;
	
		//int index;
	const char *ibssFile = [self iBSS];
	pois0n_init();
	pois0n_set_callback(&print_progress, self);
		//printf("Waiting for device to enter DFU mode\n");
	[self setDownloadText:NSLocalizedString(@"Waiting for device to enter DFU mode...", @"Waiting for device to enter DFU mode...")];
	[self setInstructionText:NSLocalizedString(@"Connect USB then press and hold MENU and PLAY/PAUSE for 7 seconds.", @"Connect USB then press and hold MENU and PLAY/PAUSE for 7 seconds.")];
		//NSImage *theImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tether" ofType:@"png"]];
		//NSImage *theImage = [NSImage imageNamed:@"tether"];
	[instructionImage setImage:[self imageForMode:kSPATVRestoreImage]];
		//[theImage release];
	while(pois0n_is_ready()) {
		sleep(1);
	}
	
	[self setDownloadText:NSLocalizedString(@"Found device in DFU mode", @"Found device in DFU mode")];
	[self setInstructionText:@""];
	
	result = pois0n_is_compatible();
	if (result < 0) {
		[self setDownloadText:NSLocalizedString(@"Your device is not compatible with this exploit!", @"Your device is not compatible with this exploit!")];
		return result;
	}
	
	result = pois0n_injectonly();
	if (result < 0) {
		[self setDownloadText:NSLocalizedString(@"Exploit injection failed!", @"Exploit injection failed!")];
		
		return result;
	}
	
	if (ibssFile != NULL) {
		[self setDownloadText:[NSString stringWithFormat:@"Uploading %@ to device...", iBSSDFU]];
		ir_error = irecv_send_file(client, ibssFile, 1);
		if(ir_error != IRECV_E_SUCCESS) {
			[self setDownloadText:NSLocalizedString(@"Unable to upload iBSS!", @"Unable to upload iBSS!")];
			debug("%s\n", irecv_strerror(ir_error));
			return -1;
		}
	} else {
		return 0;
	}
	client = irecv_reconnect(client, 10);
	[self setDownloadText:NSLocalizedString(@"DFU mode entered successfully!", @"DFU mode entered successfully!")];
	
	
	
	[self hideProgress];
	pois0n_exit();
	self.poisoning = FALSE;
	[pool release];
	return 0;
	
}

	//this code is pretty much verbatim adapted and slightly modified from tetheredboot.c

- (int)tetheredBoot
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	self.poisoning = TRUE;
	[self showProgress];
	[self killiTunes];
	int result = 0;
	irecv_error_t ir_error = IRECV_E_SUCCESS;
	
		//int index;
	const char 
	*ibssFile = [self iBSS],
	*kernelcacheFile = [self kernelcache],
	*ramdiskFile = NULL,
	*bgcolor = NULL,
	*bootlogo = NULL;
	pois0n_init();
	pois0n_set_callback(&print_progress, self);
		//printf("Waiting for device to enter DFU mode\n");
	[self setDownloadText:NSLocalizedString(@"Waiting for device to enter DFU mode...", @"Waiting for device to enter DFU mode...")];
	[self setInstructionText:NSLocalizedString(@"Connect USB, POWER then press and hold MENU and PLAY/PAUSE for 7 seconds", @"Connect USB, POWER then press and hold MENU and PLAY/PAUSE for 7 seconds")];
	[instructionImage setImage:[self imageForMode:kSPATVTetheredRemoteImage]];
	while(pois0n_is_ready()) {
		sleep(1);
	}
	
	[self setDownloadText:NSLocalizedString(@"Found device in DFU mode", @"Found device in DFU mode")];
	[self setInstructionText:@""];
	result = pois0n_is_compatible();
	if (result < 0) {
		[self setDownloadText:NSLocalizedString(@"Your device is not compatible with this exploit!", @"Your device is not compatible with this exploit!")];
		[self hideProgress];
		pois0n_exit();
		self.poisoning = FALSE;
		[pool release];
		return result;
	}
	
	result = pois0n_injectonly();
	if (result < 0) {
		[self setDownloadText:NSLocalizedString(@"Exploit injection failed!",@"Exploit injection failed!" )];
		[self hideProgress];
		pois0n_exit();
		self.poisoning = FALSE;
		[pool release];
		return result;
	}
	
	if (ibssFile != NULL) {
		[self setDownloadText:[NSString stringWithFormat:NSLocalizedString(@"Uploading %@ to device...",@"Uploading %@ to device..."), iBSSDFU]];
		ir_error = irecv_send_file(client, ibssFile, 1);
		if(ir_error != IRECV_E_SUCCESS) {
			[self setDownloadText:NSLocalizedString(@"Unable to upload iBSS!", @"Unable to upload iBSS!")];
			debug("%s\n", irecv_strerror(ir_error));
			[self hideProgress];
			pois0n_exit();
			self.poisoning = FALSE;
			[pool release];
			return -1;
		}
	} else {
		return 0;
	}
	[self setDownloadText:NSLocalizedString(@"iBSS upload successful! Reconnecting in 10 seconds...", @"iBSS upload successful! Reconnecting in 10 seconds...")];  
	client = irecv_reconnect(client, 10);
	
	if (ramdiskFile != NULL) {
		[self setDownloadText:[NSString stringWithFormat:NSLocalizedString(@"Uploading %s to device...", @"Uploading %s to device..."), ramdiskFile]];
		ir_error = irecv_send_file(client, ramdiskFile, 1);
		if(ir_error != IRECV_E_SUCCESS) {
			error("Unable to upload ramdisk\n");
			debug("%s\n", irecv_strerror(ir_error));
			
			return -1;
		}
		
		sleep(5);
		
		ir_error = irecv_send_command(client, "ramdisk");
		if(ir_error != IRECV_E_SUCCESS) {
			error("Unable send the bootx command\n");
			return -1;
		}	
	}
	
	if (bootlogo != NULL) {
		debug("Uploading %s to device...\n", bootlogo);
		ir_error = irecv_send_file(client, bootlogo, 1);
		if(ir_error != IRECV_E_SUCCESS) {
			error("Unable to upload bootlogo\n");
			debug("%s\n", irecv_strerror(ir_error));
			return -1;
		}
		
		ir_error = irecv_send_command(client, "setpicture 1");
		if(ir_error != IRECV_E_SUCCESS) {
			error("Unable to set picture\n");
			return -1;
		}
		
		ir_error = irecv_send_command(client, "bgcolor 0 0 0");
		if(ir_error != IRECV_E_SUCCESS) {
			error("Unable to set picture\n");
			return -1;
		}
	}
	
	if (bgcolor != NULL) {
		char finalbgcolor[255];
		sprintf(finalbgcolor, "bgcolor %s", bgcolor);
		ir_error = irecv_send_command(client, finalbgcolor);
		if(ir_error != IRECV_E_SUCCESS) {
			error("Unable set bgcolor\n");
			return -1;
		}
	}
	
	if (kernelcacheFile != NULL) {
		[self setDownloadText:[NSString stringWithFormat:NSLocalizedString(@"Uploading %@ to device...", @"Uploading %@ to device..."), KCACHE]];
		ir_error = irecv_send_file(client, kernelcacheFile, 1);
		if(ir_error != IRECV_E_SUCCESS) {
			error("Unable to upload kernelcache\n");
			debug("%s\n", irecv_strerror(ir_error));
			[self hideProgress];
			pois0n_exit();
			self.poisoning = FALSE;
			[pool release];
			return -1;
		}
		
		ir_error = irecv_send_command(client, "bootx");
		if(ir_error != IRECV_E_SUCCESS) {
			error("Unable send the bootx command\n");
			return -1;
		}
	}
		 [self setDownloadText:NSLocalizedString(@"Tethered boot complete! It is now safe to disconnect USB.",@"Tethered boot complete! It is now safe to disconnect USB." )];
		 [self hideProgress];
	pois0n_exit();
	self.poisoning = FALSE;
	[cancelButton setTitle:@"Done"];
	[instructionImage setImage:[self imageForMode:kSPSuccessImage]];
	[pool release];
	return 0;
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	
	[window setContentView:self.firstView];
	downloadIndex = 0;
	downloadFiles = [[NSMutableArray alloc] init];
	self.processing = FALSE;
	self.poisoning = FALSE;
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(pwnFinished:) name:@"pwnFinished" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(statusChanged:) name:@"statusChanged" object:nil];
	[self startupAlert];
	[self pwnHelperCheckOwner];
	[self checkScripting];
	[FM removeItemAtPath:TMP_ROOT error:nil];
	
		//NSLog(@"appS: %@", [tetherKitAppDelegate wifiFile]);
	
}

- (void)checkScripting
{
	if([self scriptingEnabled] == FALSE)
	{
		NSAlert *theAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"UI scripting disabled!", @"UI scripting disabled!") defaultButton:NSLocalizedString(@"Enable",@"Enable") alternateButton:NSLocalizedString(@"Don't Enable", @"Don't Enable") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"UI Scripting is not enabled, it is needed to restore the IPSW automatically in iTunes, would you like to enable it?", @"UI Scripting is not enabled, it is needed to restore the IPSW automatically in iTunes, would you like to enable it?")];
		int buttonReturn = [theAlert runModal];
			//NSLog(@"buttonReturn: %i", buttonReturn);
		switch (buttonReturn) {
			case 0:
				self.enableScripting = TRUE;
				break;
			case 1:
				self.enableScripting = FALSE;
				break;
				
				
		}
		
	}
}

- (void)pwnFinished:(NSNotification *)n
{
	
		[NSThread detachNewThreadSelector:@selector(wrapItUp:) toTarget:self withObject:[n userInfo]];
}

- (NSArray *)ipswContents
{
	NSMutableArray *ipswFiles = [[NSMutableArray alloc] init];
	[ipswFiles addObject:[TMP_ROOT stringByAppendingPathComponent:@"Firmware"]];
	[ipswFiles addObject:[TMP_ROOT stringByAppendingPathComponent:KCACHE]];
	[ipswFiles addObject:[TMP_ROOT stringByAppendingPathComponent:@"BuildManifest.plist"]];
	[ipswFiles addObject:[TMP_ROOT stringByAppendingPathComponent:@"Restore.plist"]];
	return [ipswFiles autorelease];
}

- (void)wrapItUp:(NSDictionary *)theDict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		//NSLog(@"pwnFinished!");
	[self showProgress];
	NSString *outputPath = [theDict valueForKey:@"Path"];
	NSString *theDMG = [theDict valueForKey:@"os"];
	[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:NSLocalizedString(@"Converting image to read only compressed...",@"Converting image to read only compressed...") waitUntilDone:NO];
		//[progressText setStringValue:@"Converting Image to read only compressed..."];

	
	NSString *finalPath = [nitoUtility convertImage:outputPath toFile:[IPSW_TMP stringByAppendingPathComponent:[theDMG lastPathComponent]] toMode:kDMGReadOnly]; //convert image to readonly
	
	[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:NSLocalizedString(@"Scanning image for restore...",@"Scanning image for restore..." ) waitUntilDone:NO];
	
	[nitoUtility scanForRestore:finalPath];
	
	NSString *kcache = [TMP_ROOT stringByAppendingPathComponent:KCACHE];
	NSString *ibss = [TMP_ROOT stringByAppendingPathComponent:@"Firmware/dfu/iBSS.k66ap.RELEASE.dfu"];
	[FM copyItemAtPath:kcache toPath:[self kcacheString] error:nil];
	
	
	[nitoUtility patchIBSS:ibss];
	
	[FM copyItemAtPath:ibss toPath:[self iBSSString] error:nil];
	
	[nitoUtility migrateFiles:[self ipswContents] toPath:IPSW_TMP];
	
	NSString *ipswPath = [NSHomeDirectory() stringByAppendingPathComponent:CUSTOM_RESTORE];
	
	[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:NSLocalizedString(@"Creating IPSW...", @"Creating IPSW...") waitUntilDone:NO];
	
	[nitoUtility createIPSWToFile:ipswPath];
	
		[FM removeFileAtPath:TMP_ROOT handler:nil];
	
	[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:NSLocalizedString(@"Custom IPSW created successfully!" , @"Custom IPSW created successfully!" ) waitUntilDone:NO];
	
	[self hideProgress];
	[self enterDFU];
	if ([self scriptingEnabled])
	{
		[self setDownloadText:NSLocalizedString(@"Restoring in iTunes...",@"Restoring in iTunes...") ];
		if ([self loadItunesWithIPSW:ipswPath] == FALSE)
		{
			[self setDownloadText:NSLocalizedString(@"iTunes restore script failed!, selecting IPSW in Finder...", @"iTunes restore script failed!, selecting IPSW in Finder...")];
			[[NSWorkspace sharedWorkspace] selectFile:ipswPath inFileViewerRootedAtPath:NSHomeDirectory()];
			[cancelButton setTitle:@"Done"];
		} else {
			[self setDownloadText:NSLocalizedString(@"iTunes restore script successful!", @"iTunes restore script successful!")];
			[cancelButton setTitle:@"Done"];
			[instructionImage setImage:[self imageForMode:kSPSuccessImage]];
		}
	} else {
		[[NSWorkspace sharedWorkspace] selectFile:ipswPath inFileViewerRootedAtPath:NSHomeDirectory()];
		[cancelButton setTitle:@"Done"];
	}
	[cancelButton setTitle:@"Done"];
	
	[pool release];
}

- (void)threadedDFURestore
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self killiTunes];
	[self enterDFU];
	NSString *ipswPath = [NSHomeDirectory() stringByAppendingPathComponent:CUSTOM_RESTORE];
	if(![FM fileExistsAtPath:ipswPath])
	{
		[self setDownloadText:NSLocalizedString(@"No IPSW to restore!", @"No IPSW to restore!")];
		return;
	}
	[self setDownloadText:NSLocalizedString(@"Restoring in iTunes...",@"Restoring in iTunes...") ];
	
	if ([self loadItunesWithIPSW:ipswPath] == FALSE)
	{
		[self setDownloadText:NSLocalizedString(@"Failed to run iTunes script!!",@"Failed to run iTunes script!!") ];
	} else {
		[self setDownloadText:NSLocalizedString(@"iTunes restore script successful!", @"iTunes restore script successful!")];
		[cancelButton setTitle:@"Done"];
		[instructionImage setImage:[self imageForMode:kSPSuccessImage]];
	}
	
	
	[pool release];
}

- (IBAction)itunesRestore:(id)sender
{
	[window setContentView:self.secondView];
	[window display];
[	NSThread detachNewThreadSelector:@selector(threadedDFURestore) toTarget:self withObject:nil];
		//[self enterDFU];
}

- (void)killiTunes
{
	NSTask *killTask = [[NSTask alloc] init];
	[killTask setLaunchPath:@"/usr/bin/killall"];
	[killTask setArguments:[NSArray arrayWithObject:@"iTunes"]];
	[killTask launch];
	[killTask waitUntilExit];
	[killTask release];
	killTask = nil;
}

- (BOOL)scriptingEnabled
{
	NSString *assitivePath = @"/private/var/db/.AccessibilityAPIEnabled";
	if (![FM fileExistsAtPath:assitivePath])
		return FALSE;
	
	return TRUE;
}

- (IBAction)fixScript:(id)sender
{
	NSMutableString *asString = [[NSMutableString alloc] init];
	[asString appendString:@"tell application \"System Events\"\n"];
	
	[asString appendString:@"tell Process \"Finder\"\n"];
	[asString appendString:@"key down option\n"];
	[asString appendString:@"key up option\n"];
	[asString appendString:@"end tell\n"];
	[asString appendString:@"end tell\n"];
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource:asString];
		NSLog(@"fixScript: %@", asString);
	[as executeAndReturnError:nil];
	[asString release];
	asString = nil;
	[as release];
}

- (BOOL)loadItunesWithIPSW:(NSString *)ipsw
{
	NSDictionary *theError = nil;
	
		//AppleTV2,1_4.2.1_8C154_Custom_Restore.ipsw
	/*
	
	 activate application "iTunes"
	 tell application "System Events"
	 tell process "iTunes"
	 key down option
	 click button "Restore" of scroll area 1 of tab group 1 of window "iTunes"
	 key up option
	 key code 5 using {command down, shift down} -- g key
	 set value of text field 1 of sheet 1 of window 1 to "~/AppleTV2,1_4.2.1_8C154_Custom_Restore.ipsw"
	 click button 1 of sheet 1 of window 1
	 click button 4 of window 1
	 click button 2 of window 1
	 
	 
	 end tell
	 end tell
	 
	 */
	NSString *ipswString = [NSString stringWithFormat:@"set value of text field 1 of sheet 1 of window 1 to \"%@\"\n", ipsw];
	
	NSMutableString *asString = [[NSMutableString alloc] init];
	[asString appendString:@"activate application \"iTunes\"\n"];
	[asString appendString:@"tell application \"System Events\"\n"];

	[asString appendString:@"tell Process \"iTunes\"\n"];
	[asString appendString:@"repeat until window 1 is not equal to null\n"];
	[asString appendString:@"end repeat\n"];
		[asString appendString:@"delay 2\n"];
		//[asString appendString:@"try\n"];
	[asString appendString:@"key down option\n"];
	[asString appendString:@"click button \"Restore\" of scroll area 1 of tab group 1 of window 1\n"];
	[asString appendString:@"key up option\n"];
	[asString appendString:@"key code 5 using {command down, shift down}\n"];
	[asString appendString:ipswString];
	[asString appendString:@"click button 1 of sheet 1 of window 1\n"];
	[asString appendString:@"click button 4 of window 1\n"];
	[asString appendString:@"click button 2 of window 1\n"];
		//[asString appendString:@"end try\n"];
	[asString appendString:@"end tell\n"];
	[asString appendString:@"end tell\n"];
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource:asString];
		//NSLog(@"applescript: %@", asString);
	[as executeAndReturnError:&theError];
	[asString release];
	asString = nil;
	[as release];
	if (theError != nil)
	{
		NSLog(@"iTunes Scripting failed with error: %@", theError);
		[self fixScript:self];
		return FALSE;
	}
	return TRUE;
	
}


+ (NSString *)downloadLocation
{
	NSFileManager *man = [NSFileManager defaultManager];
	NSString *loc = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Tether"];
	if (![man fileExistsAtPath:loc])
	{
		[man createDirectoryAtPath:loc withIntermediateDirectories:YES attributes:nil error:nil];
			//[man createDirectoryAtPath:loc attributes:nil];
	}
	return loc;
}

- (IBAction)bootTethered:(id)sender
{
	[window setContentView:self.secondView];
	[window display];
	[NSThread detachNewThreadSelector:@selector(tetheredBoot) toTarget:self withObject:nil];

}


- (IBAction)dfuMode:(id)sender
{
	[self killiTunes];
	[NSThread detachNewThreadSelector:@selector(enterDFU) toTarget:self withObject:nil];
	
}

- (IBAction)processOne:(id)sender //download and modify ipsw
{
	[self killiTunes];
	[window setContentView:self.secondView];
	[window display];

	self.processing = TRUE;
	[buttonOne setEnabled:FALSE];
	[bootButton setEnabled:FALSE];
	[instructionImage setImage:[self imageForMode:kSPIPSWImage]];
	BOOL download = [self filesToDownload];
	if (download == TRUE)
	{
		[self downloadFiles];
	} else {
	
		[NSThread detachNewThreadSelector:@selector(pwnIPSW:) toTarget:self withObject:HCIPSW];
	}

}

- (void)downloadFiles
{
	NSString *currentDownload = [downloadFiles objectAtIndex:downloadIndex];
	NSString *ptFile = [DL stringByAppendingPathComponent:[currentDownload lastPathComponent]];
	[self setDownloadText:[NSString stringWithFormat:@"Downloading %@...", [currentDownload lastPathComponent]]];
	downloadFile = [[ripURL alloc] init];
	[downloadFile setHandler:self];
	[downloadFile setDownloadLocation:ptFile];
	[downloadFile downloadFile:currentDownload];
	[downloadFile autorelease];
		//if ([downloadFiles count] > 1)
		//{
		downloadIndex = 1;
		//}
	
}


/*
 
 http://appldnld.apple.com/AppleTV/061-9978.20101214.gmabr/AppleTV2,1_4.2.1_8C154_Restore.ipsw
 http://iphoneroot.com/download/PwnageTool_4.1.2.dmg
 
 button 1. download tweak and open PT
 button 2. extract and tether
 
 press button 1
 
 1. curl -O http://iphoneroot.com/download/PwnageTool_4.1.2.dmg
 2. hdiutil attach PwnageTool_4.1.2.dmg
 3. cp /Volumes/PwnageTool/PwnageTool.app to whatever folder
 4. cp -r ~/Desktop/tethered/AppleTV2,1_4.2_8C150.bundle /Applications/PwnageTool.app/Contents/Resources/FirmwareBundles/
 5. cp ~/Desktop/tethered/Info.plist /Applications/PwnageTool.app/Contents/Resources/CustomPackages/CydiaInstallerATV.bundle/Info.plist
 6. open pwnagetool (maybe attempt scripting)
 
 show dialog to restore appletv prompting to press continue after restored
 
 press button 2? or continue button
 
 1. unzip -j ~/Desktop/tethered/AppleTV2,1_4.2_8C150_Custom_Restore.ipsw Firmware/dfu/iBSS.k66ap.RELEASE.dfu kernelcache.release.k66 -d ~/Desktop/tethered/
 2. make sure atv is in dfu?
 3. run tetheredboot
 4. done
 
 */



#pragma mark Download Delegates

- (void)setDownloadProgress:(double)theProgress
{

	if (theProgress == 0)
	{
		[downloadBar setIndeterminate:TRUE];
		[downloadBar setHidden:FALSE];
		[downloadBar setNeedsDisplay:YES];
		[downloadBar setUsesThreadedAnimation:YES];
		[downloadBar startAnimation:self];
		return;
	}
	[downloadBar setIndeterminate:FALSE];
	[downloadBar startAnimation:self];
	[downloadBar setHidden:FALSE];
	[downloadBar setNeedsDisplay:YES];
	[downloadBar setDoubleValue:theProgress];
}

- (void)downloadFinished:(NSString *)adownloadFile
{
		//NSLog(@"download complete: %@", adownloadFile);
	[downloadBar stopAnimation:self];
	[downloadBar setHidden:YES];
	[downloadBar setNeedsDisplay:YES];

	if (downloadIndex == 1)
	{
			//NSString *currentDownload = [downloadFiles objectAtIndex:downloadIndex];
			//NSString *ptFile = [DL stringByAppendingPathComponent:[currentDownload lastPathComponent]];
			//[self setDownloadText:[NSString stringWithFormat:@"Downloading %@...", [currentDownload lastPathComponent]]];
			//ripURL *downloadFile = [[ripURL alloc] init];
			//[downloadFile setHandler:self];
			//[downloadFile setDownloadLocation:ptFile];
			//[downloadFile downloadFile:currentDownload];
			//[downloadFile autorelease];
			//downloadIndex = 2;
			//	} else {
		
		[self setDownloadText:NSLocalizedString(@"Downloads complete", @"Downloads complete")];
		 NSLog(@"downloads complete!!");
		[self setDownloadProgress:0];
		[NSThread detachNewThreadSelector:@selector(pwnIPSW:) toTarget:self withObject:HCIPSW];
		
		
	}
	
}

- (void)setInstructionText:(NSString *)instructions
{
	[instructionField setStringValue:instructions];
	[instructionField setNeedsDisplay:YES];
}

- (void)setDownloadText:(NSString *)downloadString
{
	
		//NSLog(@"setDownlodText:%@", downloadString);
	[downloadProgressField setStringValue:downloadString];
	[downloadProgressField setNeedsDisplay:YES];
}

- (void)pwnIPSW:(NSString *)inputIPSW
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *ramdiskFile = @"038-0318-001.dmg";
	NSString *fileSystemFile = @"038-0316-001.dmg";
	int status = 0;
	nitoUtility *nu = [[nitoUtility alloc] init];
	[nu setEnableScripting:self.enableScripting];
	[nitoUtility createTempSetup];
	[self showProgress];
	[self setDownloadText:NSLocalizedString(@"Unzipping IPSW...",@"Unzipping IPSW..." )];
	if ([nitoUtility unzipFile:inputIPSW toPath:TMP_ROOT])
	{
		[self setDownloadText:NSLocalizedString(@"Patching ramdisk...", @"Patching ramdisk...")];
		status = [nu patchRamdisk:[TMP_ROOT stringByAppendingPathComponent:ramdiskFile]];
		if (status == 0)
		{
			NSLog(@"Patched ramdisk successfully!");
			[self setDownloadText:NSLocalizedString(@"Patching filesystem...", @"Patching filesystem...")];
			[nu patchFilesystem:[TMP_ROOT stringByAppendingPathComponent:fileSystemFile]];
		} else {
			[self setDownloadText:NSLocalizedString(@"IPSW creation failed!", @"IPSW creation failed!")];
			NSLog(@"failed pwnIPSW, bail!");
			[self hideProgress];
			[pool release];
			return;
		}
		
	}
		//[self hideProgress];
	[pool release];
}

- (IBAction)userGuides:(id)sender
{
	NSURL *seasonPass = [NSURL URLWithString:@"http://seas0npass.com/"];
	[[NSWorkspace sharedWorkspace] openURL:seasonPass];
}

- (void)statusChanged:(NSNotification *)n
{
	id userI = [n userInfo];
	[self setDownloadText:[userI valueForKey:@"Status"]];
	
}

- (BOOL)pwnHelperCheckOwner
{	
	
	NSString *helperPath = [[NSBundle mainBundle] pathForResource: @"dbHelper" ofType: @""];
	NSFileManager *man = [NSFileManager defaultManager];
	NSDictionary *attrs = [man fileAttributesAtPath:helperPath traverseLink:YES];
	NSNumber *curPerms = [attrs objectForKey:NSFilePosixPermissions];
		//NSLog(@"curPerms: %@", curPerms);
	if (![[attrs objectForKey:NSFileOwnerAccountName] isEqualToString:@"root"] || [curPerms intValue] < 2541)
	{
		/*
		NSAlert *alert = [NSAlert alertWithMessageText:@"helper fix"
										 defaultButton:@"OK"
									   alternateButton:@""
										   otherButton:@""
							 informativeTextWithFormat:@"the helper requires root ownership to operate properly, you will be prompted for your password to fix this issue"];
		
			[alert runModal];
		 */
		
		AuthorizationFlags myFlags = kAuthorizationFlagDefaults;// 1
		
		AuthorizationRef myAuthorizationRef;
		
		OSStatus myStatus = AuthorizationCreate (NULL, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
		
		
		NSString *helpPath = [[NSBundle mainBundle] pathForResource: @"dHelper" ofType: @""];
		
		
		char *systemCopier = ( char * ) [helpPath fileSystemRepresentation];
		
		
		AuthorizationItem rightSet[] = {{kAuthorizationRightExecute, 0, NULL, 0}};
		
		AuthorizationRights rights = {1, rightSet};
		
		
		myFlags = kAuthorizationFlagDefaults |// 8
		
		kAuthorizationFlagInteractionAllowed |// 9
		
		kAuthorizationFlagPreAuthorize |// 10
		
		kAuthorizationFlagExtendRights;// 11
		
		OSStatus result = AuthorizationCopyRights (myAuthorizationRef, &rights, NULL, myFlags, NULL );// 12
		
		
		if(result == errAuthorizationSuccess)
		{
			char *command = "chown root:wheel \"$HELP\" && chmod 4755 \"$HELP\" && chmod +s \"$HELP\"";
			setenv("HELP", [helperPath fileSystemRepresentation], 1);
			char *arguments[] = {"-c", command, NULL};
			result = AuthorizationExecuteWithPrivileges(myAuthorizationRef, "/bin/sh", kAuthorizationFlagDefaults, arguments, NULL);
			unsetenv("HELP");
		}
		if(result != errAuthorizationSuccess)
		{
			NSLog(@"dHelper permissions: %@ are not sufficient, dying", curPerms);
			/*Need to present the error dialog here telling the user to fix the permissions*/
			return NO;
		}
			//
			//return (NO);
	}
	
	return (YES);
	
}

@end
