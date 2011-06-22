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

	//4.3b1 md5 for iBSS 0b03c11af9bd013a6cf98be65eb0e146
    //4.3b1 patched md5 for iBSS 

#import <Security/Authorization.h>
#include <Security/AuthorizationTags.h>
#import "tetherKitAppDelegate.h"
#import "nitoUtility.h"
#import "include/libpois0n.h"

#define kIPSWName @"AppleTV2,1_4.2.1_8C154_Restore.ipsw"
#define kIPSWDownloadLocation @"http://appldnld.apple.com/AppleTV/041-0596.20110511.Zz7mC/AppleTV2,1_4.3_8F305_Restore.ipsw"
#define DL [tetherKitAppDelegate downloadLocation]
#define PTMD5 @"e8f4d590c8fe62386844d6a2248ae609"
#define IPSWMD5 @"4726cfb30f322f8cdbb5f20df7ca836f"
#define KCACHE @"kernelcache.release.k66"
#define iBSSDFU @"iBSS.k66ap.RELEASE.dfu"
#define HCIPSW [DL stringByAppendingPathComponent:@"AppleTV2,1_4.3_8F305_Restore.ipsw"]
#define CUSTOM_RESTORED @"AppleTV2,1_4.2.1_8C154_Custom_Restore.ipsw"
#define CUSTOM_RESTORE @"AppleTV_SeasonPass.ipsw"
#define BUNDLE_LOCATION [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"bundles"]
#define BUNDLES [FM contentsOfDirectoryAtPath:BUNDLE_LOCATION error:nil]
#define LAST_BUNDLE [[NSUserDefaults standardUserDefaults] valueForKey:@"lastUsedBundle"]
#define KILL_ITUNES [[NSUserDefaults standardUserDefaults] boolForKey:@"killiTunes"]

int received_cb(irecv_client_t client, const irecv_event_t* event);
int progress_cb(irecv_client_t client, const irecv_event_t* event);
int precommand_cb(irecv_client_t client, const irecv_event_t* event);
int postcommand_cb(irecv_client_t client, const irecv_event_t* event);
static unsigned int quit = 0;
static unsigned int verbose = 0;

@implementation tetherKitAppDelegate

@synthesize window, downloadIndex, processing, enableScripting, firstView, secondView, poisoning, currentBundle, bundleController, counter, otherWindow, commandTextField, tetherLabel;

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


- (void)firstTimer:(NSTimer *)timer
{
    [self setCounter:(counter -1)];
		//[countdownField setIntegerValue:counter];
   
	if (counter <= 1) { 
		[timer invalidate]; 
		[self nextCountdown];
	}
}

- (void)secondTimer:(NSTimer *)timer
{
    [self setCounter:(counter -1)];
    [countdownField setIntegerValue:counter];
    if (counter <= 1) { 
		[timer invalidate]; 
	}
}

- (IBAction)startCountdown:(id)sender
{

	counter = 5;
	[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(firstTimer:) userInfo:nil repeats:YES];

}

- (void)nextCountdown
{
	counter = 7;
	[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(secondTimer:) userInfo:nil repeats:YES];
}




	//if ([theEvent modifierFlags] == 262401){
- (BOOL) optionKeyIsDown
{
	return (GetCurrentKeyModifiers() & optionKey) != 0;
}

- (char *)iBSS
{
	NSString *iBSS = [[self currentBundle] localiBSS];
		//NSLog(@"self current bundle: %@", self.currentBundle);
		//NSLog(@"iBSS: %@", iBSS);
	return [iBSS UTF8String];
}

- (char *)oldiBSS
{
	NSString *iBSS = [DL stringByAppendingPathComponent:iBSSDFU];
	return [iBSS UTF8String];
}


- (char *)kernelcache
{
	NSString *kc = [[self currentBundle] localKernel];
	return [kc UTF8String];
}

- (char *)oldkernelcache
{
	NSString *kc = [DL stringByAppendingPathComponent:KCACHE];
	return [kc UTF8String];
}

- (NSString *)kcacheString
{
	return [[self currentBundle] localKernel];
}

- (NSString *)iBSSString
{
	return [[self currentBundle] localiBSS];
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
			break;
	
		case kSPATVUntetheredImage:
			
			theImage = [NSImage imageNamed:@"untethered"];
			break;
	}
	
	return theImage;
}

- (void)dealloc
{

	[super dealloc];
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

- (NSString *)ipswOutputPath
{
		//NSString *appSupport = [tetherKitAppDelegate applicationSupportFolder];
	return [NSHomeDirectory() stringByAppendingPathComponent:self.currentBundle.outputName];
	
}


void LogIt (NSString *format, ...)
{
    va_list args;
	
    va_start (args, format);
	
    NSString *string;
	
    string = [[NSString alloc] initWithFormat: format  arguments: args];
	
    va_end (args);
	
    printf ("%s", [string cString]);
	
    [string release];
	
} // LogIt

- (void)printEnvironment
{
	/*
	 
	 Process:         Chicken of the VNC [5926]
	 Path:            /Applications/Chicken of the VNC.app/Contents/MacOS/Chicken of the VNC
	 Identifier:      com.geekspiff.chickenofthevnc
	 Version:         2.0b4 (2.0b4)
	 Code Type:       X86 (Native)
	 Parent Process:  launchd [175]
	 
	 Date/Time:       2011-01-24 18:02:48.227 -0700
	 OS Version:      Mac OS X 10.6.5 (10H574)
	 Report Version:  6
	 
	 */
	
	/*
	 
	 CFBundleDevelopmentRegion = English;
	 CFBundleExecutable = Seas0nPass;
	 CFBundleExecutablePath = "/Users/kevinbradley/Projects/Seas0nPass/build/Release/Seas0nPass.app/Contents/MacOS/Seas0nPass";
	 CFBundleIconFile = Seas0nPass;
	 CFBundleIdentifier = "com.firecore.Seas0nPass";
	 CFBundleInfoDictionaryVersion = "6.0";
	 CFBundleInfoPlistURL = "Contents/Info.plist -- file://localhost/Users/kevinbradley/Projects/Seas0nPass/build/Release/Seas0nPass.app/";
	 CFBundleName = Seas0nPass;
	 CFBundleNumericVersion = 838893568;
	 CFBundlePackageType = APPL;
	 CFBundleShortVersionString = "0.6.9";
	 CFBundleSignature = "????";
	 CFBundleVersion = 32;
	 LSMinimumSystemVersion = "10.6";
	 NSBundleInitialPath = "/Users/kevinbradley/Projects/Seas0nPass/build/Release/Seas0nPass.app";
	 NSBundleResolvedPath = "/Users/kevinbradley/Projects/Seas0nPass/build/Release/Seas0nPass.app";
	 NSHumanReadableCopyright = "Copyright \U00a9 2011 FireCore, LLC";
	 NSMainNibFile = MainMenu;
	 NSPrincipalClass = NSApplication;
	 SUFeedURL = "http://files.firecore.com/SP/Seas0nPass.xml";
	 
	 */
	unsigned major, minor, bugFix;
    [[NSApplication sharedApplication] getSystemVersionMajor:&major minor:&minor bugFix:&bugFix];
	NSDictionary *bundle = [[NSBundle mainBundle] infoDictionary];
	
		//NSLog(@"info: %@", [[NSBundle mainBundle] infoDictionary]);
	NSString *bv = [self buildVersion];
	NSString *process = [NSString stringWithFormat:@"Process:\t\t%@\n", [bundle valueForKey:@"CFBundleExecutable"] ];
	NSString *path	  = [NSString stringWithFormat:@"Path:\t\t%@\n", [bundle valueForKey:@"CFBundleExecutablePath"] ];
	NSString *ident   = [NSString stringWithFormat:@"Identifier:\t\t%@\n", [bundle valueForKey:@"CFBundleIdentifier"] ];
	NSString *vers    = [NSString stringWithFormat:@"Version:\t\t%@ (%@)\n", [bundle valueForKey:@"CFBundleShortVersionString"], [bundle valueForKey:@"CFBundleVersion"]];
	NSString *ct	  = [NSString stringWithFormat:@"Code Type:\t\t%@\n", @"idontknow"];
	NSString *pp      = [NSString stringWithFormat:@"Parent Process:\t\t%@\n\n", [bundle valueForKey:@"CFBundleIdentifier"] ];
	NSString *date    = [NSString stringWithFormat:@"Date/Time:\t\t%@\n", [[NSDate date] description]];
	NSString *osvers  = [NSString stringWithFormat:@"OS Version:\t\t%u.%u.%u (%@)\n\n\n", major, minor, bugFix, bv];
	NSLog(@"\n");
	NSLog(@"BEGIN NEW SESSION\n");
	NSLog(@"************************\n");
	NSLog(@"%@", process);
	NSLog(@"%@", path);
	NSLog(@"%@", ident);
	NSLog(@"%@", vers);
	NSLog(@"%@", date);
	NSLog(@"%@", osvers);
		//[self gestaltFun];

	
}

- (void)gestaltFun
{
	OSType		returnType;
	long		gestaltReturnValue,
	swappedReturnValue;
	
	NSLog(@"Gestalt fun...");
	
	returnType=Gestalt(gestaltPhysicalRAMSize, &gestaltReturnValue);
	if (!returnType)
	{
		NSLog(@"RAM: %d MB",(gestaltReturnValue/1048576));
	} else {
		NSLog(@"error calling Gestalt: %d", returnType);
	}
		//gestaltSysArchitecture
	returnType=Gestalt(gestaltNativeCPUtype, &gestaltReturnValue);
	if (!returnType)
	{
		char		type[5] = { 0 };
		swappedReturnValue = EndianU32_BtoN(gestaltReturnValue);
		memmove( type, &swappedReturnValue, 4 );
		NSLog(@"NativeCPUType: '%s' (%d)",type,gestaltReturnValue);
		
		switch(gestaltReturnValue) {
			case gestaltCPU601:        NSLog(@"PowerPC 601"); break;
			case gestaltCPU603:        NSLog(@"PowerPC 603"); break;
			case gestaltCPU603e:       NSLog(@"PowerPC 603e"); break;
			case gestaltCPU603ev:      NSLog(@"PowerPC 603ev"); break;
			case gestaltCPU604:        NSLog(@"PowerPC 604"); break;
			case gestaltCPU604e:       NSLog(@"PowerPC 604e"); break;
			case gestaltCPU604ev:      NSLog(@"PowerPC 604ev"); break;
			case gestaltCPU750:        NSLog(@"G3"); break;
			case gestaltCPUG4:         NSLog(@"G4"); break;
			case gestaltCPU970:        NSLog(@"G5 (970)"); break;
			case gestaltCPU970FX:      NSLog(@"G5 (970 FX)"); break;
			case gestaltCPU486 :       NSLog(@"Intel 486"); break;
			case gestaltCPUPentium:    NSLog(@"Intel Pentium"); break;
			case gestaltCPUPentiumPro: NSLog(@"Intel Pentium Pro"); break;
			case gestaltCPUPentiumII:  NSLog(@"Intel Pentium II"); break;
			case gestaltCPUX86:        NSLog(@"Intel x86"); break;
			case gestaltCPUPentium4:   NSLog(@"Intel Pentium 4"); break;
			default: NSLog(@"error calling Gestalt: %d", returnType);
		}
	}
	
	returnType=Gestalt(gestaltProcClkSpeed, &gestaltReturnValue);
	if (!returnType)
	{
		NSLog(@"procSpeed: %d MHz",(gestaltReturnValue/1000000));
	} else {
		NSLog(@"error calling Gestalt: %d", returnType);
	}
	
	returnType=Gestalt( gestaltPowerPCProcessorFeatures, &gestaltReturnValue);
	if (!returnType)
	{
		NSLog(@"PowerPC ProcFeatures: %d",(gestaltReturnValue));
		if (gestaltPowerPCHasDCBAInstruction==gestaltReturnValue) {
		}
	} else {
		NSLog(@"error calling Gestalt: %d", returnType);
	}
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
	return [DL stringByAppendingPathComponent:@"AppleTV2,1_4.3_8F305_Restore.ipsw"];
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

- (IBAction)versionChanged:(id)sender
{
	
		//NSLog(@"version changed");
	self.currentBundle = [FWBundle bundleWithName:LAST_BUNDLE];
		//NSLog(@"self.currentBundle: %@", self.currentBundle);
	if ([[self currentBundle] untethered])
	{
		[bootButton setImage:[self imageForMode:kSPATVUntetheredImage]];
		[tetherLabel setTextColor:[NSColor lightGrayColor]];
		
	} else {
		[bootButton setImage:[self imageForMode:kSPATVTetheredImage]];
		[tetherLabel setTextColor:[NSColor blackColor]];
	}
}

- (BOOL)sufficientSpaceOnDevice:(NSString *)theDevice
{
	NSFileManager *man = [NSFileManager defaultManager];
	float available = [[[man attributesOfFileSystemForPath:theDevice error:nil] objectForKey:NSFileSystemFreeSize] floatValue];
	float totalSize = 3000.0f;
	float avail2 = available / 1024 / 1024;
	
	if (avail2 < totalSize)
	{
		NSAlert *space = [NSAlert alertWithMessageText:NSLocalizedString(@"Free Space needed", nil)
									 defaultButton:NSLocalizedString(@"OK", nil)
								   alternateButton:@""
									   otherButton:@""
						 informativeTextWithFormat:NSLocalizedString(@"Not enough free space.\n\n Space needed: %.2f MB\n Space Available: %.2f MB", nil), totalSize, avail2 ];
	
		[space runModal];
		return NO;
	}
	
	return YES;
}

- (IBAction)cancel:(id)sender
{
		
	if (downloadFile != nil)
	{
		if ([downloadFile isKindOfClass:[ripURL class]])
		{
			NSLog(@"downloadFile: %@", downloadFile);
			if ([downloadFile respondsToSelector:@selector(cancel)])
			{
					//NSLog(@"cancel?");
				[downloadFile cancel];
					//self.processing = FALSE;
				[self hideProgress];
				
			}
		}
		
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
		[self versionChanged:nil];
		[window display];
	}
	
	
}

int progress_cb(irecv_client_t client, const irecv_event_t* event) {
		//NSLog(@"progress");
	if (event->type == IRECV_PROGRESS) {
		print_progress_bar(event->progress);
	}
	return 0;
}

void print_progress_bar(double progress) {
	int i = 0;
	if(progress < 0) {
		return;
	}
	
	if(progress > 100) {
		progress = 100;
	}
	
	printf("\r[");
	for(i = 0; i < 50; i++) {
		if(i < progress / 2) {
			printf("=");
		} else {
			printf(" ");
		}
	}
	
	printf("] %3.1f%%", progress);
	fflush(stdout);
	if(progress == 100) {
		printf("\n");
	}
}

- (int)inject
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self killiTunes];
	self.poisoning = TRUE;
	[self showProgress];
	int result = 0;
	irecv_error_t ir_error = IRECV_E_SUCCESS;
	
	pois0n_init();
	pois0n_set_callback(&print_progress, self);
	[self setDownloadText:NSLocalizedString(@"Waiting for device to enter DFU mode...", @"Waiting for device to enter DFU mode...")];
	[self setInstructionText:NSLocalizedString(@"Connect USB then press and hold MENU and PLAY/PAUSE for 7 seconds.", @"Connect USB then press and hold MENU and PLAY/PAUSE for 7 seconds.")];
	[instructionImage setImage:[self imageForMode:kSPATVRestoreImage]];
	while(pois0n_is_ready()) {
		sleep(1);
	}
	irecv_event_subscribe(client, IRECV_RECEIVED, &print_progress, NULL);
	[self setDownloadText:NSLocalizedString(@"Found device in DFU mode", @"Found device in DFU mode")];
	[self setInstructionText:@""];
	
	result = pois0n_is_compatible();
	if (result < 0) {
		[self setDownloadText:NSLocalizedString(@"Your device is not compatible with this exploit!", @"Your device is not compatible with this exploit!")];
		return result;
	}
	[self setDownloadText:NSLocalizedString(@"Injecting Pois0n", @"Injecting Pois0n")];
		result = pois0n_inject();
	if (result < 0) {
		[self setDownloadText:NSLocalizedString(@"Exploit injection failed!", @"Exploit injection failed!")];
		[self hideProgress];
		pois0n_exit();
		self.poisoning = FALSE;
		[pool release];
		return result;
	}
	[self setDownloadText:@"pois0n successfully administered"];
	NSString *command = [commandTextField stringValue];
	irecv_send_command(client, [command UTF8String]);
	[self hideProgress];
	[cancelButton setTitle:@"Done"];
	[instructionImage setImage:[self imageForMode:kSPSuccessImage]];
	pois0n_exit();
	self.poisoning = FALSE;
	[pool release];
	return 0;
}

	//this code is almost identical to the tetheredboot code

- (int)enterDFU
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self killiTunes];
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

int received_cb(irecv_client_t client, const irecv_event_t* event) {
		NSLog(@"received_cb");
	if (event->type == IRECV_RECEIVED) {
		int i = 0;
		int size = event->size;
		char* data = event->data;
		for (i = 0; i < size; i++) {
			printf("%c", data[i]);
		}
	}
	return 0;
}

void parse_command(irecv_client_t client, unsigned char* command, unsigned int size) {
		NSLog(@"parse command");
	char* cmd = strdup(command);
	char* action = strtok(cmd, " ");
	debug("Executing %s\n", action);
	if (!strcmp(cmd, "/exit")) {

	} else
		
		if (!strcmp(cmd, "/help")) {

		} else
			
			if (!strcmp(cmd, "/upload")) {
				char* filename = strtok(NULL, " ");
				debug("Uploading files %s\n", filename);
				if (filename != NULL) {
					irecv_send_file(client, filename, 0);
				}
			} else
				
				if (!strcmp(cmd, "/exploit")) {
					char* filename = strtok(NULL, " ");
					debug("Sending exploit %s\n", filename);
					if (filename != NULL) {
						irecv_send_file(client, filename, 0);
					}
					irecv_send_exploit(client);
				} else
					
					if (!strcmp(cmd, "/execute")) {
						char* filename = strtok(NULL, " ");
						debug("Executing script %s\n", filename);
						if (filename != NULL) {
							irecv_execute_script(client, filename);
						}
					}
	
	
	free(action);
}

int precommand_cb(irecv_client_t client, const irecv_event_t* event) {
	NSLog(@"precommand_cb");
	if (event->type == IRECV_PRECOMMAND) {
		irecv_error_t error = 0;
		if (event->data[0] == '/') {
			parse_command(client, event->data, event->size);
			return -1;
		}
	}
	return 0;
}

int postcommand_cb(irecv_client_t client, const irecv_event_t* event) {
NSLog(@"postcommand_cb");
	char* value = NULL;
	char* action = NULL;
	char* command = NULL;
	char* argument = NULL;
	irecv_error_t error = IRECV_E_SUCCESS;

	if (event->type == IRECV_POSTCOMMAND) {
		command = strdup(event->data);
		action = strtok(command, " ");
		if (!strcmp(action, "getenv")) {
			argument = strtok(NULL, " ");
			error = irecv_getenv(client, argument, &value);
			if (error != IRECV_E_SUCCESS) {
				debug("%s\n", irecv_strerror(error));
				free(command);
				return error;
			}
			printf("%s\n", value);
			free(value);
		}
		
		
	}

	if (command) free(command);
	return 0;
}

- (IBAction)poison:(id)sender
{
	NSString *lastUsedbundle = LAST_BUNDLE;
	self.currentBundle = [FWBundle bundleWithName:lastUsedbundle];
	[window setContentView:self.secondView];
	[window display];
	[NSThread detachNewThreadSelector:@selector(inject) toTarget:self withObject:nil];
}
/*
 
 
 while (!quit) {
 
 //getVersionNumber(client);
 error = irecv_receive(client);
 if (error != IRECV_E_SUCCESS) {
 debug("%s\n", irecv_strerror(error));
 break;
 }
 
 char* cmd = readline("> ");
 if (cmd && *cmd) {
 error = irecv_send_command(client, cmd);
 if (error != IRECV_E_SUCCESS) {
 quit = 1;
 }
 
 append_command_to_history(cmd);
 free(cmd);
 }
 }
 
 */

- (IBAction)asendCommand:(id)sender
{
	NSString *command = [commandTextField stringValue];
	
	quit = 0;
	
	irecv_error_t error = 0;
	irecv_init();
	irecv_client_t client = NULL;
	if (irecv_open(&client) != IRECV_E_SUCCESS)
	{
		NSLog(@"fail!");
		return;
		
	}
	irecv_set_debug_level(1);
	
	irecv_event_subscribe(client, IRECV_PROGRESS, &progress_cb, NULL);
	irecv_event_subscribe(client, IRECV_RECEIVED, &received_cb, NULL);
		//irecv_event_subscribe(client, IRECV_PRECOMMAND, &precommand_cb, NULL);
		//irecv_event_subscribe(client, IRECV_POSTCOMMAND, &postcommand_cb, NULL);
	while (!quit) {
		error = irecv_receive(client);
		
		error = irecv_send_command(client, [command UTF8String]);
		
		
		
			//debug("%s\n", irecv_strerror(error));

	}
	
}

- (NSArray *)kbagArray 
{
	return [NSArray arrayWithObjects:@"B17EAEBA2845761183558B49905509FF671C58122438A331EB715F2FE44C70F5A00821BEC9A51AE3295D32E4E43F854B", @"8B4736C11779B6247395C79E9D23A58BB5448ED4F6F0D4B61459920E30303EBDA1DE0A5BB6FE679A9B392EE2E1775308", @"588CA181069297FBB4175C380735E3F3A50AC2DA971A1E4D0375457691A1560FBBC49B2E70E91671DC5960EA1CF8DAE7", @"76FE44A0288FB5F4974BFAF78D50ED28D471B4A247831D52CBBC18849CB500FDB7E089AA4AC814203CF752AA32E6E05B", @"DE3B1E98937F2ED65DC02036B8F0EB9ABAD83813A1FBD8F356AD0C4E492D0D8E9DF9E586F2A154243374FFCD6BE019B9", @"8870446AE8C43786A5A5F98D544C691CBBC89E8489EEA886A856A992E161DCF0503D2C9B4CEFBC2E3E826BC6D2B61D64", @"9504A98F412AD79BB8425F75F031E8BDF71D2FE3F7624E60EFBCF1957EDBB2C669F2728BE850B826363597BD392164FE", @"7A4188D676BAA4F433812F4FA5079BF5F72BE183AFECA3C530DD33B47ABC0223C22E6245153FBC7791B1E7F8597CF8ED", @"05165FD57D9FAF428AE117275C24F8CE76853B3777ADFBC5F74DEBAF10A53122528058CFDB7B6F51E8F423780AC207B0", @"C2DC6FDEE49B7B5830774980E813710A29ED484F6BA6296C3B73E8715223F327C5A32F1E7889A24647EA528465746F01", @"DD71210CFD7B14703070272732037485CB9D67B1320CB313E3AB9110838138566EBA483942D8F7FAE003FE388C919FC1", @"124E3838675F586F494365482B6DD6274B21F2EE9EE67B0C5B71CFFAC2B3A6D26547EBBF4D882E766E808169AF2C5EDA", nil];
}

- (IBAction)sendCommand:(id)sender
{

//	NSArray *ivK = [self runHelper:@"7F8651BF1E81548A719A94BFF92C9A01980A3F3EDF0BED5D3F70D5BF266C92F37A3F0D817A434B04E693D94AB619B23F"];
//	NSLog(@"ivk: %@", ivK);
//
//	NSDictionary *ivKDict = [NSDictionary dictionaryWithObjectsAndKeys:[ivK objectAtIndex:1], @"iv", [[ivK objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], @"k", nil];
//	NSLog(@"ivkDict: %@", ivKDict);
//	[ivKDict writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"kbagkeydict.plist"] atomically:YES];
//	NSString *iv = [ivKDict valueForKey:@"iv"];
//	NSLog(@"iv: -%@- other side", iv);
//		return;
	NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/SP_Keys.log"];
	[FM removeFileAtPath:logPath handler:nil];
	FILE* file = freopen([logPath fileSystemRepresentation], "a", stdout);

	NSString *command = [commandTextField stringValue];
	
	quit = 0;

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
		irecv_event_subscribe(client, IRECV_PROGRESS, &progress_cb, NULL);
		irecv_event_subscribe(client, IRECV_RECEIVED, &received_cb, NULL);
		//irecv_event_subscribe(client, IRECV_PRECOMMAND, &precommand_cb, NULL);
		//irecv_event_subscribe(client, IRECV_POSTCOMMAND, &postcommand_cb, NULL);
		//while (!quit) {
		irecv_set_interface(client, 0, 0);
		irecv_set_interface(client, 1, 1);
		error = irecv_receive(client);
		
			//irecv_set_interface(client, 1, 0);	
	
	NSEnumerator *kbagEnum = [[self kbagArray] objectEnumerator];
	id theObject = nil;
	while (theObject = [kbagEnum nextObject]) {
		
		NSString *newObject = [NSString stringWithFormat:@"go aes dec %@", theObject];
		error = irecv_send_command(client, [newObject UTF8String]);
	}
	
	
	
	
	
	error = irecv_receive(client);
			//debug("%s\n", irecv_strerror(error));
			//quit = 1;
		//}
	irecv_close(client);
	irecv_exit();
		
		fclose(file);
	
	
	NSString *me = [NSString stringWithContentsOfFile:logPath];
	me = [me stringByReplacingOccurrencesOfString:@"\0" withString:@""];
	NSLog(@"ME: %@", me);

	
	
	

	
}

- (IBAction)keydumpPrep:(id)sender //prepare for key dump
{	
		
	NSString *lastUsedbundle = LAST_BUNDLE;
	self.currentBundle = [FWBundle bundleWithName:lastUsedbundle];
	[window setContentView:self.secondView];
	[window display];
	
		 irecv_error_t error = 0;
		 irecv_init();
		 irecv_client_t client = NULL;
		 if (irecv_open(&client) != IRECV_E_SUCCESS)
		 {
			 NSLog(@"fail!");
			 return;
			 
		 }
		 
		 error = irecv_send_command(client, "setenv boot-args 2");
		 debug("%s\n", irecv_strerror(error));
	
		error = irecv_send_command(client, "saveenv");
		debug("%s\n", irecv_strerror(error));
	irecv_close(client);
	irecv_exit();
	[NSThread detachNewThreadSelector:@selector(inject) toTarget:self withObject:nil];
		 
}


	//this code is pretty much verbatim adapted and slightly modified from tetheredboot.c

- (int)tetheredBoot
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self killiTunes];
	self.poisoning = TRUE;
	[self showProgress];
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
		//irecv_send_command(client, "go kernel bootargs -v");
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

+ (NSArray *)appSupportBundles
{
	NSString *appSupport = [tetherKitAppDelegate applicationSupportFolder];
	NSArray *files = [FM contentsOfDirectoryAtPath:appSupport error:nil];
	NSMutableArray *newFiles = [[NSMutableArray alloc] init];
	NSEnumerator *fileEnum = [files objectEnumerator];
	id currentObject = nil;
	while (currentObject = [fileEnum nextObject]) {
		
		if ([[currentObject pathExtension] isEqualToString:@"bundle"])
		{
			[newFiles addObject:[currentObject stringByDeletingPathExtension]];
		}
		
	}
	return [newFiles autorelease];
}

+ (BOOL)sshKey
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"sshKey"];
}

+ (BOOL)sigServer
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"sigServer"];
}

- (void)setBundleControllerContent
{

	NSArray *appSBundles = [tetherKitAppDelegate appSupportBundles];
	NSMutableArray *outputArray = [[NSMutableArray alloc] init];
	NSEnumerator *bundleEnum = [appSBundles objectEnumerator];
	id theObject = nil;
	while(theObject = [bundleEnum nextObject])
	{
		NSDictionary *theDict = [NSDictionary dictionaryWithObject:theObject forKey:@"name"];
		[outputArray addObject:theDict];
	}
	
	[self.bundleController setContent:[outputArray autorelease]];
}

- (NSString *)buildVersion
{
	NSTask *swVers = [[NSTask alloc] init];
	NSPipe *swp = [[NSPipe alloc] init];
	NSFileHandle *swh = [swp fileHandleForReading];
	[swVers setLaunchPath:@"/usr/bin/sw_vers"];
	[swVers setArguments:[NSArray arrayWithObject:@"-buildVersion"]];
	[swVers setStandardOutput:swp];
	[swVers setStandardError:swp];
	[swVers launch];
	[swVers waitUntilExit];
	NSData *outData;
	outData = [swh readDataToEndOfFile];
	NSString *temp = [[NSString alloc] initWithData:outData encoding:NSASCIIStringEncoding];
	temp = [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	[swVers release];
	swVers = nil;
	[swp release];
	swp = nil;
	return temp;
	
}

- (NSArray *)runHelper:(NSString *)theKbag
{

	
	NSString *helpPath = [[NSBundle mainBundle] pathForResource: @"dbHelper" ofType: @""];
	
	NSTask *pwnHelper = [[NSTask alloc] init];
	
	[pwnHelper setLaunchPath:helpPath];
	NSPipe *swp = [[NSPipe alloc] init];
	NSFileHandle *swh = [swp fileHandleForReading];
	[pwnHelper setArguments:[NSArray arrayWithObjects:@"nil", theKbag, nil]];
	[pwnHelper setStandardOutput:swp];
	[pwnHelper setStandardError:swp];
	
	[pwnHelper launch];

	
	NSData *outData = nil;
    

		//Variables needed for reading output
	NSString *temp = nil;
    NSMutableArray *lineArray = [[NSMutableArray alloc] init];
	

    while((outData = [swh readDataToEndOfFile]) && [outData length])
    {
        temp = [[[NSString alloc] initWithData:outData encoding:NSASCIIStringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSLog(@"temp length: %i", [temp length]);
	
		if ([temp length] > 800)
		{
			[swh closeFile];
			[pwnHelper release];
			
			pwnHelper = nil;
			return nil;
		}
	
			//NSLog(@"temp: %@", [temp componentsSeparatedByString:@" "]);
			//[lineArray addObject:[temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		NSArray *arrayOne = [temp componentsSeparatedByString:@"\n"];
			//NSLog(@"arrayOneCount: %i", [arrayOne count]);
		NSArray *arrayTwo = [[arrayOne objectAtIndex:0] componentsSeparatedByString:@" "];
			[lineArray addObjectsFromArray:arrayTwo];
			[temp release];
    }


	
		//	NSLog(@"lineARray: %@", lineArray);
	[swh closeFile];
	[pwnHelper release];
	
	pwnHelper = nil;
	
	return [lineArray autorelease];
	
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	[self iTunesIsTenFive];
	
	if ([self homeWritable])
	{
		NSLog(@"can write to home!");
	} else{
		
		NSLog(@"cant write to home!!");
	}
	
		//killiTunes
	if ([self optionKeyIsDown])
	{
		[otherWindow makeKeyAndOrderFront:nil];
	}
	
	[self printEnvironment];
	[window setContentView:self.firstView];
	downloadIndex = 0;
	downloadFiles = [[NSMutableArray alloc] init];
	self.processing = FALSE;
	self.poisoning = FALSE;
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(pwnFinished:) name:@"pwnFinished" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(pwnFailed:) name:@"pwnFailed" object:nil];

	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(statusChanged:) name:@"statusChanged" object:nil];
		//[self startupAlert];
	BOOL theStuff = [self pwnHelperCheckOwner];
	if (theStuff == FALSE)
	{
		[[NSApplication sharedApplication] terminate:self];
	}
	[self checkScripting];
	NSString *lastUsedbundle = LAST_BUNDLE;

	if ([lastUsedbundle length] < 1)
	{
		lastUsedbundle = @"AppleTV2,1_4.3_8F305";
		[[NSUserDefaults standardUserDefaults] setObject:lastUsedbundle forKey:@"lastUsedBundle"];
	}
	self.currentBundle = [FWBundle bundleWithName:LAST_BUNDLE];

		//[self.currentBundle logDescription];
		
	
			[FM removeFileAtPath:TMP_ROOT handler:nil];
	
		//[FM removeItemAtPath:TMP_ROOT error:nil];
	[self setBundleControllerContent];
	[self versionChanged:nil];
	
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

- (void)pwnFailed:(NSNotification *)n
{

	NSString *fail = [NSString stringWithFormat:@"Process failed with reason: %@", [[n userInfo] objectForKey:@"AbortReason"]];
	[self setDownloadText:fail];
	[self hideProgress];
	[[NSWorkspace sharedWorkspace] selectFile:@"SP_Debug.log" inFileViewerRootedAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/"]];

}

- (void)pwnFinished:(NSNotification *)n
{
	
		[NSThread detachNewThreadSelector:@selector(wrapItUp:) toTarget:self withObject:[n userInfo]];
}

- (NSArray *)ipswContents
{
	NSMutableArray *ipswFiles = [[NSMutableArray alloc] init];
	[ipswFiles addObject:[TMP_ROOT stringByAppendingPathComponent:@"Firmware"]];
	[ipswFiles addObject:[TMP_ROOT stringByAppendingPathComponent:[[self currentBundle] kernelCacheName]]];
	[ipswFiles addObject:[TMP_ROOT stringByAppendingPathComponent:@"BuildManifest.plist"]];
	[ipswFiles addObject:[TMP_ROOT stringByAppendingPathComponent:@"Restore.plist"]];
	return [ipswFiles autorelease];
}

- (NSDictionary *)bundleData
{
	NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"AppleTV2,1_4.2.1_8C154" ofType:@"bundle" inDirectory:@"bundles"];
	NSDictionary *bundleD = [[NSBundle bundleWithPath:bundlePath] infoDictionary];
	NSMutableDictionary *bundleDict = [[NSMutableDictionary alloc] initWithDictionary:bundleD];
	
	[bundleDict setObject:bundlePath forKey:@"bundlePath"];
	[bundleDict setObject:TMP_ROOT forKey:@"rootPath"];
		//NSLog(@"bundleData: %@", bundleDict);
	return [bundleDict autorelease];
	
}

- (void)createSupportBundleWithCache:(NSString *)theCache iBSS:(NSString *)iBSS
{
	NSLog(@"createSupportBundleWithCache: %@ iBSS: %@", theCache, iBSS);
	NSString *bundleOut = self.currentBundle.localBundlePath;
	NSLog(@"localBundlePath: %@", bundleOut);
	if ([FM createDirectoryAtPath:bundleOut withIntermediateDirectories:YES attributes:nil error:nil] == FALSE)
	{
		NSLog(@"failed to create directory: %@", bundleOut);
	}
	NSDictionary *buildManifest = [NSDictionary dictionaryWithObjectsAndKeys:[theCache lastPathComponent], @"KernelCache", [iBSS lastPathComponent], @"iBSS", nil];
	[buildManifest writeToFile:[bundleOut stringByAppendingPathComponent:@"BuildManifest.plist"] atomically:YES];
		NSLog(@"copy: %@ to %@", theCache, [self.currentBundle localKernel]);
	 [FM copyItemAtPath:theCache toPath:self.currentBundle.localKernel error:nil];
		NSLog(@"copy: %@ to %@", iBSS, self.currentBundle.localiBSS);
	 [FM copyItemAtPath:iBSS toPath:self.currentBundle.localiBSS error:nil];
	
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
	
	NSString *kcache = [TMP_ROOT stringByAppendingPathComponent:[[self currentBundle] kernelCacheName]];
	NSString *ibss = [TMP_ROOT stringByAppendingPathComponent:[[self currentBundle] iBSSName]];
	[self createSupportBundleWithCache:kcache iBSS:ibss];

	/*
	if ([FM fileExistsAtPath:[self kcacheString]])
	{
		[FM removeItemAtPath:[self kcacheString] error:nil];
	}
	[FM copyItemAtPath:kcache toPath:[self kcacheString] error:nil];
	
	if ([FM fileExistsAtPath:[self iBSSString]])
	{
		[FM removeItemAtPath:[self iBSSString] error:nil];
	}
	[FM copyItemAtPath:ibss toPath:[self iBSSString] error:nil];
	*/
	
	
	[nitoUtility migrateFiles:[self ipswContents] toPath:IPSW_TMP];
	
		//NSString *ipswPath = [NSHomeDirectory() stringByAppendingPathComponent:CUSTOM_RESTORE];
	
	NSString *ipswPath = [self ipswOutputPath];
	
		//NSLog(@"ipsw: %@", ipswPath);
	
	
	[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:NSLocalizedString(@"Creating IPSW...", @"Creating IPSW...") waitUntilDone:NO];
	
	int ipswStatus = [nitoUtility createIPSWToFile:ipswPath];
	
	NSLog(@"ipsw creation status: %i", ipswStatus);
	
		//FIXME: COMMENT BACK IN!!
	
		[FM removeFileAtPath:TMP_ROOT handler:nil];
	
	
		// if we failed, say so
	
	if (ipswStatus == 0)
	{
		NSLog(@"ipsw created successfully!");
		
		[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:NSLocalizedString(@"Custom IPSW created successfully!" , @"Custom IPSW created successfully!" ) waitUntilDone:NO];
		
		[self hideProgress];
		[self killiTunes];
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
		[[NSUserDefaults standardUserDefaults] setObject:self.currentBundle.bundleName forKey:@"lastUsedBundle"];
		
	} else {
		
		[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:NSLocalizedString(@"Custom IPSW creation failed!" , @"Custom IPSW creation failed!" ) waitUntilDone:NO];
		[self hideProgress];
			[cancelButton setTitle:@"Failed"];
		NSLog(@"ipsw creation failed!!");
		
	}
	
	
	
	
	
	[pool release];
}

- (BOOL)homeWritable
{
	
	NSFileManager *man = [NSFileManager defaultManager];
	NSDictionary *attrs = [man attributesOfItemAtPath:NSHomeDirectory() error:nil];
		//NSLog(@"attrs: %@", attrs);
	
	return [man isWritableFileAtPath:NSHomeDirectory()];
	
}

- (void)threadedDFURestore
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self killiTunes];
	[self enterDFU];
		//NSString *ipswPath = [NSHomeDirectory() stringByAppendingPathComponent:CUSTOM_RESTORE];
	NSString *ipswPath = [self ipswOutputPath];
	if(![FM fileExistsAtPath:ipswPath])
	{
		[self setDownloadText:NSLocalizedString(@"No IPSW to restore!", @"No IPSW to restore!")];
		[self hideProgress];
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

- (void)versionMigrate
{
	NSString *documents = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Tether"];
	if ([FM fileExistsAtPath:documents])
	{
			//AppleTV2,1_4.2.1_8C154
		NSString *iBSS = [documents stringByAppendingPathComponent:iBSSDFU];
		NSString *kcache = [documents stringByAppendingPathComponent:KCACHE];
		[self createSupportBundleWithCache:kcache iBSS:iBSS];
	}
}

- (IBAction)itunesRestore:(id)sender
{
	NSString *lastUsedbundle = LAST_BUNDLE;
		//NSLog(@"lastUsedBundle: %@", lastUsedbundle);
	self.currentBundle = [FWBundle bundleWithName:lastUsedbundle];
	[window setContentView:self.secondView];
	[window display];
[	NSThread detachNewThreadSelector:@selector(threadedDFURestore) toTarget:self withObject:nil];
		//[self enterDFU];
}

- (void)killiTunes
{
	//if (KILL_ITUNES == NO)
//	return;
//	
//	NSLog(@"kill itunes");
	
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

- (void)activateiTunes
{
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource:@"activate application \"iTunes\"\n"];
	[as executeAndReturnError:nil];
	[as release];
	
}

- (BOOL)iTunesIsTenFive
{
	NSBundle *itunesBundle = [NSBundle bundleWithPath:@"/Applications/iTunes.app"];
	NSDictionary *itunesDict = [itunesBundle infoDictionary];
	if ([[itunesDict valueForKey:@"CFBundleShortVersionString"] isEqualToString:@"10.5"])
	{
		NSLog(@"10.5 iTunes here!");
		return YES;
	}
	return NO;
}

- (BOOL)loadItunesWithIPSW:(NSString *)ipsw
{
	NSDictionary *theError = nil;
	
		//AppleTV2,1_4.2.1_8C154_Custom_Restore.ipsw
	/*
	
	 activate application "iTunes"
	 tell application "System Events"
	 tell process "iTunes"
	 repeat until window 1 is not equal to null
	 end repeat
	 end tell
	 end tell
	 activate application "iTunes"
	 tell application "System Events"
	 tell process "iTunes"
	 key down option
	 click button "Restore" of scroll area 1 of tab group 1 of window "iTunes"
	 key up option
	 end tell
	 end tell
	 activate application "iTunes"
	 tell application "System Events"
	 tell process "iTunes"
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
	[asString appendString:@"end tell\n"];
	[asString appendString:@"end tell\n"];
	
	/*
	 
	 we separate these instances out in an attempt to minimize pebkac errors. that is why there is multiple activate application "iTunes"\n lines, that will bring it to the 
	 front
	 
	 */
	
	[asString appendString:@"activate application \"iTunes\"\n"];
	[asString appendString:@"tell application \"System Events\"\n"];
	[asString appendString:@"tell Process \"iTunes\"\n"];
	[asString appendString:@"key down option\n"];
	if ([self iTunesIsTenFive] == TRUE)
	{
		[asString appendString:@"click button \"Restore\"  of scroll area 3 of window 1\n"];
		
	} else {
		
		[asString appendString:@"click button \"Restore\" of scroll area 1 of tab group 1 of window 1\n"];
	}
	 //itunes beta = @"click button \"Restore\"  of scroll area 3 of window 1\n" 
	[asString appendString:@"key up option\n"];
	[asString appendString:@"end tell\n"];
	[asString appendString:@"end tell\n"];
	
	[asString appendString:@"activate application \"iTunes\"\n"];
	[asString appendString:@"tell application \"System Events\"\n"];
		[asString appendString:@"tell Process \"iTunes\"\n"];
	[asString appendString:@"key code 5 using {command down, shift down}\n"];
	[asString appendString:ipswString];
	[asString appendString:@"click button 1 of sheet 1 of window 1\n"];
	[asString appendString:@"click button 4 of window 1\n"];
	[asString appendString:@"click button 2 of window 1\n"];
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



+ (NSArray *)bundleNames
{
	
	return BUNDLES;
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

- (void)showUntetheredAlert
{
	NSAlert *errorAlert = [NSAlert alertWithMessageText:@"Untethered Jailbreak" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The %@ firmware is untethered and does not require this process!", [self.currentBundle bundleName]];
	[errorAlert runModal];
}

- (IBAction)bootTethered:(id)sender
{
	NSString *lastUsedbundle = LAST_BUNDLE;
	NSLog(@"last used bundle: %@", lastUsedbundle);
	self.currentBundle = [FWBundle bundleWithName:lastUsedbundle];
	if ([self.currentBundle untethered])
	{
		[self showUntetheredAlert];
		return;
	}
	if (![FM fileExistsAtPath:[self iBSSString]])
	{
		NSLog(@"attempting version migrate");
		[self versionMigrate];
	}
		 
	[window setContentView:self.secondView];
	[window display];
	[NSThread detachNewThreadSelector:@selector(tetheredBoot) toTarget:self withObject:nil];

}


- (IBAction)dfuMode:(id)sender
{
	[self killiTunes];
	[window setContentView:self.secondView];
	[window display];
	[NSThread detachNewThreadSelector:@selector(enterDFU) toTarget:self withObject:nil];
	
}



- (IBAction)processOne:(id)sender //download and modify ipsw
{
	
	if (![self sufficientSpaceOnDevice:NSHomeDirectory()])
	{
		NSLog(@"fail");
		return;
	}
	
		//[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/SP_Debug.log"]

	NSString *logPath2 = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/SP_Debug_new.log"];
	[FM removeFileAtPath:logPath2 handler:nil];
		//current bundle may be set by default, but we never want to assume the default processOne ipsw to be anything but the latest- which is still hardcoded to 4.2.1.
		//self.currentBundle = LAST_BUNDLE;
	self.currentBundle = [FWBundle bundleWithName:@"AppleTV2,1_4.3_8F305"];
	if ([self optionKeyIsDown])
	{
		NSOpenPanel *op = [NSOpenPanel openPanel];
		[op setTitle:@"Please select an AppleTV firmware image"];
		[op setCanChooseFiles:YES];
		[op setCanCreateDirectories:NO];
		int buttonPressed = [op runModalForTypes:[NSArray arrayWithObject:@"ipsw"]];
		if (buttonPressed != NSOKButton)
		{
			return;
		}
		NSString *ipsw = [op filename];
		FWBundle *ourBundle = [FWBundle bundleForFile:ipsw];
		
		if (ourBundle == nil)
		{
			NSAlert *errorAlert = [NSAlert alertWithMessageText:@"Unsupported Firmware!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The firmware %@ is not compatible with this version of Seas0nPass.", [ipsw lastPathComponent]];
			[errorAlert runModal];
			return;
		}
		self.currentBundle = ourBundle;
		[window setContentView:self.secondView];
		[window display];
		
		self.processing = TRUE;
		[buttonOne setEnabled:FALSE];
		[bootButton setEnabled:FALSE];
		[instructionImage setImage:[self imageForMode:kSPIPSWImage]];
			
			[NSThread detachNewThreadSelector:@selector(customFW:) toTarget:self withObject:ipsw];
		return;
	}
	
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
	
		[NSThread detachNewThreadSelector:@selector(customFW:) toTarget:self withObject:HCIPSW];
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
		//[downloadFile autorelease];
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

- (void)downloadFailed:(NSString *)adownloadFile
{
	[downloadBar stopAnimation:self];
	[downloadBar setHidden:YES];
	[downloadBar setNeedsDisplay:YES];
	[downloadFile release];
	downloadFile = nil;
	[self hideProgress];
}

- (void)downloadFinished:(NSString *)adownloadFile
{
		//NSLog(@"download complete: %@", adownloadFile);
	[downloadBar stopAnimation:self];
	[downloadBar setHidden:YES];
	[downloadBar setNeedsDisplay:YES];
	[downloadFile release];
	downloadFile = nil;
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
		[NSThread detachNewThreadSelector:@selector(customFW:) toTarget:self withObject:HCIPSW];
		
		
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

	/*
	 
	 1. perform firmware patches - generally just unpacking, patching, repacking
	 
	 
	 
	 */
	//sufficientSpaceOnDevice
- (void)customFW:(NSString *)inputIPSW
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	FWBundle *theBundle = self.currentBundle;
	NSString *fileSystemFile = [self.currentBundle rootFilesystem];
	int status = 0;
	nitoUtility *nu = [[nitoUtility alloc] init];
	[nitoUtility createTempSetup];
	if ([tetherKitAppDelegate sshKey])
	{
		NSString *sshKey = [NSHomeDirectory() stringByAppendingPathComponent:@".ssh/id_rsa.pub"];
		if ([FM fileExistsAtPath:sshKey])
			[nu setSshKey:sshKey];
	}
	
	[nu setSigServer:[tetherKitAppDelegate sigServer]];
	
	[nu setEnableScripting:self.enableScripting];
	[nu setCurrentBundle:theBundle];
	[self showProgress];
	[self setDownloadText:NSLocalizedString(@"Unzipping IPSW...",@"Unzipping IPSW..." )];
	if ([nitoUtility unzipFile:inputIPSW toPath:TMP_ROOT])
	{
		[self setDownloadText:NSLocalizedString(@"Patching ramdisk...", @"Patching ramdisk...")];
		status = [self performFirmwarePatches:theBundle withUtility:nu];
		if (status == 0)
		{
			NSLog(@"firmware patches successful!");
			[self setDownloadText:NSLocalizedString(@"Patching filesystem...", @"Patching filesystem...")];
			[nu patchFilesystem:[TMP_ROOT stringByAppendingPathComponent:fileSystemFile]];
		}
		
	}
		//[self hideProgress];
	[pool release];
}

- (int)performFirmwarePatches:(FWBundle *)theBundle withUtility:(nitoUtility *)nitoUtil
{
		//[theBundle logDescription];
	int status = 0;
	if ([theBundle iBSS] != nil)
	{
		status = [nitoUtility decryptedPatchFromData:[theBundle iBSS] atRoot:[theBundle fwRoot] fromBundle:[theBundle bundlePath]];
		if (status == 0)
		{
			NSLog(@"patched iBSS successfully!");
		} else {
			NSLog(@"iBSS patch failed!");
			return -1;
		}
	}
	if ([theBundle appleLogo] != nil)
	{
		status = [nitoUtility decryptedImageFromData:[theBundle appleLogo] atRoot:[theBundle fwRoot] fromBundle:[theBundle bundlePath]];
		if (status == 0)
		{
			NSLog(@"patched appleLogo successfully!");
		} else {
			NSLog(@"appleLogo patch failed!");
			return -1;
		}
	}
	if ([theBundle restoreRamdisk] != nil)
	{
		[nitoUtil performPatchesFromBundle:theBundle onRamdisk:[theBundle restoreRamdisk]];

		
	}
}

- (void)pwnIPSW:(NSString *)inputIPSW
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *ramdiskFile = @"038-0318-001.dmg";
	NSString *fileSystemFile = @"038-0316-001.dmg";
	int status = 0;
	nitoUtility *nu = [[nitoUtility alloc] init];
	[nu setEnableScripting:self.enableScripting];
	[nu setCurrentBundle:self.currentBundle];
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
