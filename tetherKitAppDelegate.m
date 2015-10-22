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
// 4.3.x exploit by i0n1c (steffan esser)
// 4.3.3 exploit by comex
// 4.4.x exploit by pod2g

	//4.3b1 md5 for iBSS 0b03c11af9bd013a6cf98be65eb0e146
    //4.3b1 patched md5 for iBSS 

#import <Security/Authorization.h>
#include <Security/AuthorizationTags.h>
#import "tetherKitAppDelegate.h"
#import "include/libpois0n.h"
#import "include/libpartial.h"
#import <Foundation/Foundation.h>
//#import "IPhoneUSB.h"
#include <assert.h>
#include <pthread.h>
//#import "libusb.h"


//#import "IPhoneUSB.h"

#define FORCE_APPLE_STITCH

	//CURRENT_BUNDLE is the finally the only place that the bundle name needs to be replaced to change default version for future versions.

//previous @"AppleTV2,1_5.0.2_9B830"
//AppleTV2,1_5.2_10B144b
//AppleTV2,1_5.2.1_10B329a

#define CURRENT_BUNDLE @"AppleTV2,1_5.3_10B809"
#define CURRENT_IPSW [NSString stringWithFormat:@"%@_Restore.ipsw", CURRENT_BUNDLE]
#define DL [tetherKitAppDelegate downloadLocation]
#define KCACHE @"kernelcache.release.k66"
#define iBSSDFU @"iBSS.k66ap.RELEASE.dfu"
#define iBECDFU @"iBEC.k66ap.RELEASE.dfu"
#define HCIPSW [DL stringByAppendingPathComponent:CURRENT_IPSW]
#define BUNDLE_LOCATION [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"bundles"]
#define BUNDLES [FM contentsOfDirectoryAtPath:BUNDLE_LOCATION error:nil]
#define BLOB_KEY @"sentLocalBlobs"
#define BLOBS_SENT [[NSUserDefaults standardUserDefaults] boolForKey:BLOB_KEY]
#define DID_MIGRATE [[NSUserDefaults standardUserDefaults] boolForKey:@"newVersionMigrate"]
#define LAST_BUNDLE [[NSUserDefaults standardUserDefaults] valueForKey:@"lastUsedBundle"]
#define KILL_ITUNES [[NSUserDefaults standardUserDefaults] boolForKey:@"killiTunes"]
#define DEFAULTS [NSUserDefaults standardUserDefaults]

#define IFAITH_BLOB_DONE @"iFaithBlobFinished"

//int received_cb(irecv_client_t client, const irecv_event_t* event);
int progress_cb(irecv_client_t client, const irecv_event_t* event);

static NSString *ChipID_ = nil;
BOOL limera1ned = FALSE;
BOOL tetheredBoot = FALSE;
static UKDevice *staticDevice = nil;
int shatterStatus = 0;

@implementation tetherKitAppDelegate

@synthesize window, downloadIndex, processing, enableScripting, firstView, secondView, poisoning, currentBundle, bundleController, counter, otherWindow, commandTextField, tetherLabel, countdownField, runMode, theEcid;
@synthesize deviceClass;
@synthesize restoreStatus;
@synthesize currentIPSWPath;
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
	[(id)data setDownloadProgress:progress];
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

/*
 
 code for in case i ever add a fancy timer


- (void)nextCountdown
{
	counter = 7;
	[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(secondTimer:) userInfo:nil repeats:YES];
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


*/



	//if ([theEvent modifierFlags] == 262401){
- (BOOL) optionKeyIsDown
{
	return (GetCurrentKeyModifiers() & optionKey) != 0;
}

- (__strong const char *)iBECBoot
{
	NSString *iBEC = [[self currentBundle] localiBECBoot];
	if (iBEC == nil)
	{
		NSLog(@"no separate iBec for booting!");
		iBEC = [[self currentBundle] localiBEC];
	}
		//NSLog(@"self current bundle: %@", self.currentBundle);
		//NSLog(@"iBEC: %@", iBEC);
	return [iBEC UTF8String];
}

- (__strong const char *)iBEC
{
	NSString *iBEC = [[self currentBundle] localiBEC];
		//NSLog(@"self current bundle: %@", self.currentBundle);
		//NSLog(@"iBEC: %@", iBEC);
	return [iBEC UTF8String];
}

- (__strong const char *)iBSS
{
	NSString *iBSS = [[self currentBundle] localiBSS];
	return [iBSS UTF8String];
}


- (__strong const char *)kernelcache
{
	NSString *kc = [[self currentBundle] localKernel];
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
	[downloadFiles release];
	downloadFiles = nil;
	[theEcid release];
	theEcid = nil;
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}



- (void)startupAlert //deprecated till theres a tethered default version again.
{
	NSUserDefaults *defaults = DEFAULTS;
	BOOL warningShown = [defaults boolForKey:@"SPWarningShown"];

	if (warningShown == TRUE)
		return;
	
	NSAlert *startupAlert = [NSAlert alertWithMessageText:@"Warning! Please read carefully." defaultButton:@"OK" alternateButton:@"More Info" otherButton:@"Cancel" informativeTextWithFormat:@"Currently the jailbreak for the 4.1.1 (iOS 4.2.1) software is 'tethered'. A tethered jailbreak requires the Apple TV to be connected to a computer for a brief moment during startup.\n\nSeas0nPass makes this as easy as possible, but please do not proceed unless you are comfortable with this process."];
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
	return [[self currentBundle] outputFile];
	
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

- (BOOL)isMountainLion 
{
	unsigned major, minor, bugFix;
    [[NSApplication sharedApplication] getSystemVersionMajor:&major minor:&minor bugFix:&bugFix];
	NSString *comparisonVersion = @"10.8.0"; 
	NSString *osVersion = [NSString stringWithFormat:@"%u.%u.%u", major, minor, bugFix];

	NSComparisonResult theResult = [osVersion compare:comparisonVersion options:NSNumericSearch];
	//NSLog(@"theversion: %@  installed version %@", theVersion, installedVersion);
	if ( theResult == NSOrderedDescending )
	{
			//NSLog(@"%@ is greater than %@", osVersion, comparisonVersion);
		
		return YES;
		
	} else if ( theResult == NSOrderedAscending ){
		
			//NSLog(@"%@ is greater than %@", comparisonVersion, osVersion);
		return NO;
		
	} else if ( theResult == NSOrderedSame ) {
		
		//	NSLog(@"%@ is equal to %@", osVersion, comparisonVersion);
		return YES;
	}
	
	return NO;
}

- (void)printEnvironment
{

	unsigned major, minor, bugFix;
    [[NSApplication sharedApplication] getSystemVersionMajor:&major minor:&minor bugFix:&bugFix];
	NSDictionary *bundle = [[NSBundle mainBundle] infoDictionary];
	
		//NSLog(@"info: %@", [[NSBundle mainBundle] infoDictionary]);
	NSString *bv = [self buildVersion];
	NSString *process = [NSString stringWithFormat:@"Process:\t\t%@\n", [bundle valueForKey:@"CFBundleExecutable"] ];
	NSString *path	  = [NSString stringWithFormat:@"Path:\t\t%@\n", [bundle valueForKey:@"CFBundleExecutablePath"] ];
	NSString *ident   = [NSString stringWithFormat:@"Identifier:\t\t%@\n", [bundle valueForKey:@"CFBundleIdentifier"] ];
	NSString *vers    = [NSString stringWithFormat:@"Version:\t\t%@ (%@)\n", [bundle valueForKey:@"CFBundleShortVersionString"], [bundle valueForKey:@"CFBundleVersion"]];
	//NSString *ct	  = [NSString stringWithFormat:@"Code Type:\t\t%@\n", @"idontknow"];
	//NSString *pp      = [NSString stringWithFormat:@"Parent Process:\t\t%@\n\n", [bundle valueForKey:@"CFBundleIdentifier"] ];
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
	return HCIPSW;
}



+ (NSRange)customRangeFromString:(NSString *)inputFile
{
		//NSLog(@"inputFile: %@", inputFile);
	NSString *baseName = [inputFile stringByDeletingPathExtension];
	int length = [baseName length];
	int start = length - 10;
		//NSLog(@"range: (%i, %i)", start, 10);
	return NSMakeRange(start, 10);
	
}

- (void)cleanupHomeFolder
{
	/*
	 
	 search through the ~ folder for any item that ends with SP_Restore.ipsw and move it to the proper folder.
	 
	 
	 */
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSFileManager *man = [NSFileManager defaultManager];
	NSArray *homeContents = [man contentsOfDirectoryAtPath:NSHomeDirectory() error:nil];
	NSEnumerator *homeEnum = [homeContents objectEnumerator];
		//NSDirectoryEnumerator *homeEnum = [man enumeratorAtPath:NSHomeDirectory()];
	for (id currentObject in homeEnum)
	{
		if ([[currentObject pathExtension] isEqualToString:@"ipsw"])
		{
			NSString *endString = [currentObject substringWithRange:[tetherKitAppDelegate customRangeFromString:currentObject]];
				//NSLog(@"endString: %@ fromString: %@", endString, currentObject);
			if ([endString isEqualToString:@"SP_Restore"])
			{
				NSLog(@"is sp restore file, migrate: %@", currentObject);
				NSString *fullOldPath = [NSHomeDirectory() stringByAppendingPathComponent:currentObject];
				NSString *newPath = [[nitoUtility firmwareFolder] stringByAppendingPathComponent:currentObject];
				
				if([man moveItemAtPath:fullOldPath toPath:newPath error:nil])
				{
					NSLog(@"moved: %@ successfully!", currentObject);
				}
			}
		}
		
	}
	
	[DEFAULTS setBool:YES forKey:@"newVersionMigrate"];
	[pool release];
	
}



- (void)showProgress
{
		//LOG_SELF;
	[buttonOne setEnabled:FALSE];
	[bootButton setEnabled:FALSE];
	self.processing = TRUE;
	[downloadBar startAnimation:self];
	[downloadBar setHidden:FALSE];
	[downloadBar setNeedsDisplay:TRUE];
	[downloadBar display];
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
	//NSFileSize
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


int progress_cb(irecv_client_t client, const irecv_event_t* event) {
		//NSLog(@"progress");
	if (event->type == IRECV_PROGRESS) {
		print_progress_bar(event->progress);
	}
	return 0;
}



- (IBAction)showHelpLog:(id)sender;
{
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSString *logLocation = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/SP_Debug.log"];
	[workspace selectFile:logLocation inFileViewerRootedAtPath:[logLocation stringByDeletingLastPathComponent]];
}


- (int)fetch_image:(const char *) path toFile:(const char*) output {
	debug("Fetching %s...\n", path);
	if (download_file_from_zip(device->url, path, output, NULL)
		!= 0) {
		error("Unable to fetch %s\n", path);
		return -1;
	}
	
	return 0;
}

- (int)fetch_dfu_image:(const char*) type toFile:(const char*) output {
	char name[64];
	char path[255];
	
	memset(name, '\0', 64);
	memset(path, '\0', 255);
	snprintf(name, 63, "%s.%s.RELEASE.dfu", type, device->model);
	snprintf(path, 254, "Firmware/dfu/%s", name);
	
	debug("Preparing to fetch DFU image from Apple's servers\n");
	if ([self fetch_image:path toFile:output] < 0 ){
		
		//if (fetch_image(path, output) < 0) {
		error("Unable to fetch DFU image from Apple's servers\n");
		return -1;
	}
	
	return 0;
}

- (NSString *)errorDescriptionForStatus:(NSString *)stringStatus
{
    /*
     --> If the response is... "failed-1" it means the kernel failed to load from the filesystem (probably due to incomplete restore).
     --> If the response is... "failed-2" it means the kernel does not have a KBAG (only happens when someone with a 3GS old bootrom runs redsn0w and redsn0w doesn't bother to re-encrypt the kernel).
     --> If the response is... "failed-3" it means One or more of the flashed images on the device do not contain an SHSH blob (usually happens when users find funky tutorials on the web to downgrade without blobs).
     --> If the response is... "failed-4" it means an unknown iOS is detected. The payload maybe outdated or user is running a beta firmware.
     --> If the response is... "failed-5" it means no valid block devices containing flash images were found (happens when the user's NAND/NOR chip goes).
     --> If the response is... "failed-6" it means the user has 24kpwn applied (only occurs on iPhone 3GS old bootroms/iPod Touch 2G MB models). Devices with 24kpwn applied do not have any SHSH blobs applied and never need any.
     
     */
    
    if ([stringStatus isEqualToString:@"failed-1"]) return @"The kernel failed to load from the filesystem (probably due to incomplete restore).";
    if ([stringStatus isEqualToString:@"failed-2"]) return @"The kernel does not have a KBAG (only happens when someone with a 3GS old bootrom runs redsn0w and redsn0w doesn't bother to re-encrypt the kernel).";
    if ([stringStatus isEqualToString:@"failed-3"]) return @"One or more of the flashed images on the device do not contain an SHSH blob (usually happens when users find funky tutorials on the web to downgrade without blobs)";
    if ([stringStatus isEqualToString:@"failed-4"]) return @"Unknown iOS is detected. iFaith payload might be outdated or you are running a beta firmware.";
    if ([stringStatus isEqualToString:@"failed-5"]) return @"No valid block devices containing flash images were found (happens when the your NAND/NOR chip malfunctions).";
    if ([stringStatus isEqualToString:@"failed-6"]) return @"You have 24kpwn applied (only occurs on iPhone 3GS old bootroms/iPod Touch 2G MB models). Devices with 24kpwn applied do not have any SHSH blobs applied and never need any.";


return @"unknown error";
}

- (int)dumpiFaithPayload
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *ifaithDir = @"/private/tmp/ifaith";
	
	if ([FM fileExistsAtPath:ifaithDir])
	{
		[FM removeItemAtPath:ifaithDir error:nil];
		[FM createDirectoryAtPath:ifaithDir withIntermediateDirectories:YES attributes:nil error:nil];
	} else {
		[FM createDirectoryAtPath:ifaithDir withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
	int result = 0;
	char iBSSFile[255];
	char iBECFile[255];
	char* boardType = NULL;
	char* outputStatus = NULL;
	char* xmlOutput = NULL;
	irecv_error_t error = IRECV_E_SUCCESS;
	irecv_error_t ir_error = IRECV_E_SUCCESS;
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
	//	if (self.deviceClass == nil)
//		{
//			[self _fetchDeviceInfo];
//			sleep(5);
//		}
//		if ([self isAppleTV3])
//		{
//			[self hideProgress];
//				//pois0n_exit();
//			self.poisoning = FALSE;
//			[pool release];
//			return -1;
//		}
		sleep(1);
	}
	
	[self setDownloadText:NSLocalizedString(@"Found device in DFU mode", @"Found device in DFU mode")];
	[self setInstructionText:@""];
	
	result = pois0n_is_compatible();
	if (result < 0) {
		[self setDownloadText:NSLocalizedString(@"Your device is not compatible with this exploit!", @"Your device is not compatible with this exploit!")];
		return result;
	}
	
	result = ifaith_inject_only(); //iFaith specific payload
    
	if (result < 0) {
		[self setDownloadText:NSLocalizedString(@"Exploit injection failed!", @"Exploit injection failed!")];
		
		return result;
	}
	
	memset(iBSSFile, '\0', 255);
	snprintf(iBSSFile, 254, "/private/tmp/ifaith/%s.%s", "iBSS", device->model); //tmp iBSS file downloaded
	memset(iBECFile, '\0', 255); 
	snprintf(iBECFile, 254, "/private/tmp/ifaith/%s.%s", "iBEC", device->model);	//tmp iBEC file downloaded
	printf("Checking if %s already exists\n", iBSSFile);
	
	[self setDownloadText:NSLocalizedString(@"Fetching iBSS file...", @"Fetching iBSS file...")];
	
	if ([self fetch_dfu_image:"iBSS" toFile:iBSSFile] < 0){
		
		error("Unable to download DFU image\n");
		return -1;
	}
	
	printf("Checking if %s already exists\n", iBECFile);
	
	[self setDownloadText:NSLocalizedString(@"Fetching iBEC file...", @"Fetching iBSS file...")];
	
	if ([self fetch_dfu_image:"iBEC" toFile:iBECFile] < 0){
		
		error("Unable to download DFU image\n");
		return -1;
	}
	
		//got iBSS and iBEC files, now read payload.bin into a file and append iBEC
	
	NSString *payload = [[NSBundle mainBundle] pathForResource:@"payload" ofType:@"bin"];
	NSMutableData *payloadData = [[NSMutableData alloc] initWithContentsOfMappedFile:payload];
	NSData *ibecData = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:iBECFile]];
	[payloadData appendData:ibecData];
	NSString *outputFile = @"/private/tmp/ifaith/output.bin";
	[payloadData writeToFile:outputFile atomically:YES];
	
	[self setDownloadText:[NSString stringWithFormat:@"Uploading %@ to device...", [NSString stringWithUTF8String:iBSSFile]]];
	ir_error = irecv_send_file(client, iBSSFile, 1);
	if(ir_error != IRECV_E_SUCCESS) {
		[self setDownloadText:NSLocalizedString(@"Unable to upload iBSS!", @"Unable to upload iBSS!")];
		debug("%s\n", irecv_strerror(ir_error));
		return -1;
	}
	[self setDownloadText:NSLocalizedString(@"iBSS upload successful! Reconnecting in 10 seconds...", @"iBSS upload successful! Reconnecting in 10 seconds...")];
	
	
	client = irecv_reconnect(client, 10);
	
	[self setDownloadText:[NSString stringWithFormat:@"Uploading %@ to device...", outputFile]];
	ir_error = irecv_send_file(client, [outputFile UTF8String], 1);
	if(ir_error != IRECV_E_SUCCESS) {
		[self setDownloadText:NSLocalizedString(@"Unable to upload iBSS!", @"Unable to upload iBSS!")];
		debug("%s\n", irecv_strerror(ir_error));
		return -1;
	}
	[self setDownloadProgress:0];
	[self setDownloadText:NSLocalizedString(@"iFaith payload upload successful! Reconnecting in 10 seconds...", @"iFaith payload upload successful! Reconnecting in 10 seconds...")];
	client = irecv_reconnect(client, 10);
	irecv_getenv(client, "config_board", &boardType);
	
		//printf("boardType: %s\n", boardType);
	[self setDownloadText:NSLocalizedString(@"Verifying Board Type...", @"Verifying Board Type...")];
	if ([[NSString stringWithUTF8String:boardType] isEqualToString:@"k66ap"])
	{
		NSString *outputBlob = @"/private/tmp/ifaith/ifaith.blob"; //raw blob in hex
			//NSString *ifaithOutput = @"/private/tmp/ifaith/ifaith.xml";
		
		[self setDownloadText:NSLocalizedString(@"Creating iFaith SHSH blob...", @"Creating iFaith SHSH blob...")];
		FILE* file = freopen([outputBlob fileSystemRepresentation], "a", stdout);
		irecv_set_configuration(client, 1);
		
		irecv_set_interface(client, 0, 0);
		irecv_set_interface(client, 1, 1);
		error = irecv_receive(client);
		
		
		irecv_send_command(client, "go ready");
		irecv_getenv(client, "status", &outputStatus);
		
		NSString *stringStatus = [NSString stringWithUTF8String:outputStatus];
		
		NSLog(@"status: %@", stringStatus);	
		
		if (![stringStatus isEqualToString:@"ready"])
		{
            NSString *errorDescription = [self errorDescriptionForStatus:stringStatus];
			NSLog(@"failed with status: %@ and description: %@", stringStatus, errorDescription);
			fclose(file);
			[self setDownloadText:NSLocalizedString(@"Failed!", @"Failed!")];
			
			poisoning = FALSE;
			pois0n_exit();
			
			[[NSNotificationCenter defaultCenter] postNotificationName:IFAITH_BLOB_DONE object:[NSDictionary dictionaryWithObject:errorDescription forKey:@"error"]];
			[pool release];
			return -1;
		}
		
			//printf("status: %s\n", outputStatus);
		irecv_getenv_sn0w(client, "effyocouch", &xmlOutput ,1);
		fclose(file);
		
		NSString *ifaithSupport = [[tetherKitAppDelegate applicationSupportFolder] stringByAppendingPathComponent:@"iFaith"];
        
		if (![FM fileExistsAtPath:ifaithSupport])
		{
			[FM createDirectoryAtPath:ifaithSupport withIntermediateDirectories:YES attributes:nil error:nil];
		}
		
	//	NSString *decimalString = [[NSString stringWithContentsOfFile:outputBlob] hexToString];
	
        NSError *encodingError = nil;
        
        NSString *decimalString = [[NSString stringWithContentsOfFile:outputBlob encoding:NSUTF8StringEncoding error:&encodingError] hexToString];
        
        if (encodingError != nil)
        {
            NSLog(@"encoding error with UTF8, try ASCII!: %@", encodingError);
            decimalString = [[NSString stringWithContentsOfFile:outputBlob encoding:NSASCIIStringEncoding error:&encodingError] hexToString];
        }
        
        //decimal string is in XML format, I import the XML and then convert it to a plist / NSDictionary
        
		//	NSLog(@"decimalString: %@", decimalString);
		NSDictionary *ifaithDict = [[[NSXMLDocument alloc] initWithXMLString:decimalString options:NSXMLDocumentTidyXML error:nil]  iFaithDictionaryRepresentation]; 
		
		NSString *ifaithXMLOutput = [ifaithSupport stringByAppendingFormat:@"/%@_%@.xml", [ifaithDict objectForKey:@"ecid"], [ifaithDict objectForKey:@"ios"]];
		
		NSData *blob = [[NSString stringWithContentsOfFile:outputBlob encoding:NSUTF8StringEncoding error:&encodingError] stringToHexData];
        
        if (encodingError != nil)
        {
            NSLog(@"encoding error with UTF8, try ASCII!: %@", encodingError);
            
            blob = [[NSString stringWithContentsOfFile:outputBlob encoding:NSASCIIStringEncoding error:&encodingError] stringToHexData];
        }
        
        
        
        //[[NSString stringWithContentsOfFile:outputBlob] stringToHexData];
        
        
		[blob writeToFile:ifaithXMLOutput atomically:YES];
	
		
			//make sure if its greater than 4.3 to make sure there is an apticket there.
		
		BOOL shouldSendBlob = YES;
		NSString *comparisonVersion = @"4.4";
		
		NSString *iosVersion = [ifaithDict objectForKey:@"ios"];
		NSString *apticket = [ifaithDict objectForKey:@"apticket"];
		NSString *clippedPath = [[iosVersion componentsSeparatedByString:@" "] objectAtIndex:0];
		NSComparisonResult theResult = [clippedPath compare:comparisonVersion options:NSNumericSearch];
		NSString *errorString = nil;
			//NSLog(@"theversion: %@  installed version %@", theVersion, installedVersion);
		BOOL apticketCheck = NO;
		if ( theResult == NSOrderedDescending )
		{
			NSLog(@"%@ is greater than %@", clippedPath, comparisonVersion);
			if (apticket != nil) {	
				shouldSendBlob = YES;
				apticketCheck = YES;
			} else {
				NSLog(@"no apticket, invalid blob!! not submitting");
				shouldSendBlob = NO;
				errorString = @"The APTicket is missing!, invalid SHSH file!";
			}
			
		} else if ( theResult == NSOrderedAscending ){
			
			NSLog(@"%@ is greater than %@", comparisonVersion, clippedPath);
			NSLog(@"no apticket needed, below 4.4");
			shouldSendBlob = YES;
			apticketCheck = NO;
			
		} else if ( theResult == NSOrderedSame ) {
			
			NSLog(@"%@ is equal to %@", clippedPath, comparisonVersion);
			if (apticket != nil) {	
				shouldSendBlob = YES;
				apticketCheck = YES;
			} else {
				NSLog(@"no apticket, invalid blob!! not submitting");
				errorString = @"The APTicket is missing!, invalid SHSH file!";
				shouldSendBlob = NO;
				apticketCheck = NO;
			}
		}
		
		
		
		if (shouldSendBlob == YES)
		{
			TSSManager *tss = nil;
			if (!DeviceIDEqualToDevice(currentDevice, TSSNullDevice))
			{
				tss = [[TSSManager alloc] initWithECID:ChipID_ device:currentDevice];
			} else {
				
				tss = [[TSSManager alloc] initWithECID:ChipID_];
			}
			
			if (apticketCheck)
			{
				int apticketResponse = [tss _synchronousAPTicketCheck:[ifaithDict objectForKey:@"apticket"]];
				
				NSLog(@"apticket verify response: %i", apticketResponse);
				if (apticketResponse == 0) 
				{
					errorString = @"Invalid APTicket! invalid SHSH files.";
					poisoning = FALSE;
					pois0n_exit();
					
					[[NSNotificationCenter defaultCenter] postNotificationName:IFAITH_BLOB_DONE object:[NSDictionary dictionaryWithObject:errorString forKey:@"error"]];
					[pool release];
				}
			}
			
			
			
			NSString *response = [tss _synchronousPushiFaithBlob:decimalString withiOSVersion:iosVersion];
			
			NSLog(@"response: %@", response);
		} else {
			poisoning = FALSE;
			pois0n_exit();
			
			[[NSNotificationCenter defaultCenter] postNotificationName:IFAITH_BLOB_DONE object:[NSDictionary dictionaryWithObject:errorString forKey:@"error"]];
			[pool release];
			
			return -1;	
			
		}
			//printf("output: %s", xmlOutput);
			//NSLog(@"ifaithDict: %@", ifaithDict);
		[self setDownloadText:NSLocalizedString(@"Finished!", @"Finished!")];
		
		poisoning = FALSE;
		pois0n_exit();
		
		[[NSNotificationCenter defaultCenter] postNotificationName:IFAITH_BLOB_DONE object:ifaithDict];
		[pool release];
		
		return 0;	
		
	}
	
	
	pois0n_exit();
	[pool release];
	return -1;
	
}

//- (NSDictionary *)ifaithBlobToDictionary:(NSXMLDocument *)rootElt
//{
//	
//    NSMutableDictionary *dict=[[NSMutableDictionary alloc]init];
//    NSArray *val=[rootElt nodesForXPath:@"./iFaith/name" error:nil];
//	if ([val count]!=0)
//	{
//		NSArray *children = [[val objectAtIndex:0] children];
//		for (NSXMLNode *child in children)
//		{
//			NSLog(@"name: %@, stringVal: %@", [child name], [child stringValue]);
//				//	[dict setObject:[child stringValue] forKey:[child name]];
//		}
//	}
//		//NSLog(@"dict: %@",dict);
//    return [dict autorelease];
//}

+ (NSString *) stringToHex:(NSString *)str
{   
    NSUInteger len = [str length];
    unichar *chars = malloc(len * sizeof(unichar));
    [str getCharacters:chars];
	
    NSMutableString *hexString = [[NSMutableString alloc] init];
	
    for(NSUInteger i = 0; i < len; i++ )
    {
			// [hexString [NSString stringWithFormat:@"%02x", chars[i]]]; /*previous input*/
        [hexString appendFormat:@"%02x", chars[i]]; /*EDITED PER COMMENT BELOW*/
    }
    free(chars);
	
    return [hexString autorelease];
}

#pragma mark •• a note about libsyringe

/*
 
 
 in the version of syringe used there was changes to irecv_open_*_old, i assume i just changed _open_ to the old code, and then all the 
 other functions just changed to call the new version. i reference the old a few times in here. needed to update limera1n for 6.x, lost
 the source code to the version of syringe i changed that actually works in here. dont remember if i changed anything else to make it work
 initially, hope i didnt. if i compile from scratch of other copies iTunes always gets 2001 error upon trying to restore.
 
 ended up just replacing the limera1n.o file in the static library, thankfully that works, hacky, but it works.
 
 */



- (int)enterDFUNEW
{
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		//NSLog(@"iSDFUNEW");
	[self killiTunes];
	self.poisoning = TRUE;
	[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
		//[cancelButton setEnabled:TRUE];
	int result = 0;
	irecv_error_t ir_error = IRECV_E_SUCCESS;
	
		//int index;
	const char *ibssFile = [self iBSS];
	const char *ibecFile = [self iBEC];
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
		if (self.deviceClass == nil)
		{
			[self _fetchDeviceInfo];
			sleep(5);
		}
			if ([self isAppleTV3])
			{
				[self hideProgress];
					//pois0n_exit();
				self.poisoning = FALSE;
				[pool release];
				return -1;
			}
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
	
	if (ibecFile != NULL) {
		[self setDownloadText:[NSString stringWithFormat:@"Uploading %@ to device...", iBECDFU]];
		ir_error = irecv_send_file(client, ibecFile, 1);
		if(ir_error != IRECV_E_SUCCESS) {
			[self setDownloadText:NSLocalizedString(@"Unable to upload iBEC!", @"Unable to upload iBEC!")];
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

	[instructionImage setImage:[self imageForMode:kSPATVRestoreImage]];
	while(pois0n_is_ready()) {
		if (self.deviceClass == nil)
		{
			[self _fetchDeviceInfo];
			sleep(5);
		}
		
		if ([self isAppleTV3])
		{
			[self hideProgress];
			pois0n_exit();
			self.poisoning = FALSE;
			[pool release];
			return -1;
		}
		sleep(1);
	}
	
	[self setDownloadText:NSLocalizedString(@"Found device in DFU mode", @"Found device in DFU mode")];
	[self setInstructionText:@""];
	
	result = pois0n_is_compatible();
	if (result < 0) {
		[self setDownloadText:NSLocalizedString(@"Your device is not compatible with this exploit!", @"Your device is not compatible with this exploit!")];
		return result;
	}
	
	result = pois0n_injectonly_old();
	if (result < 0) {
		[self setDownloadText:NSLocalizedString(@"Exploit injection failed!", @"Exploit injection failed!")];
		
		return result;
	}
	
	if (ibssFile != NULL) {
		[self setDownloadText:[NSString stringWithFormat:NSLocalizedString(@"Uploading %@ to device...", @"Uploading %@ to device..."), iBSSDFU]];
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

/*

int received_cb(irecv_client_t client, const irecv_event_t* event) {
		//NSLog(@"received_cb");
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
		//NSLog(@"parse command");
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
*/


- (IBAction)poison:(id)sender
{
	NSString *lastUsedbundle = LAST_BUNDLE;
	self.currentBundle = [FWBundle bundleWithName:lastUsedbundle];
	[window setContentView:self.secondView];
	[window display];
	[NSThread detachNewThreadSelector:@selector(inject) toTarget:self withObject:nil];
}

- (int)sn0wyTetheredBoot
{
    LOG_SELF;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    tetheredBoot = true;
	[self killiTunes];
    [self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
	const char
	*ibssFile = [self iBSS],
	*kernelcacheFile = [self kernelcache],
	*ibecFile = [self iBEC];
   [self performSelectorOnMainThread:@selector(tetheredDFUWrapper) withObject:nil waitUntilDone:false];
    
    [self showProgressViewWithText:NSLocalizedString(@"Waiting for device to enter DFU mode...", @"Waiting for device to enter DFU mode...")];
    [self setInstructionText:NSLocalizedString(@"Connect USB then press and hold MENU and PLAY/PAUSE for 7 seconds.", @"Connect USB then press and hold MENU and PLAY/PAUSE for 7 seconds.")];
    
    [instructionImage setImage:[self imageForMode:kSPATVRestoreImage]];
    
    while (limera1ned == false)
    {
        //printf("Waiting for it to ra1n\n");
        sleep(1);
    }
    
    //once we get this far we are home free! the restore below should always work!
    
    [self setInstructionText:@""];
    
    [self showProgressViewWithText:NSLocalizedString(@"Found device in DFU mode", @"Found device in DFU mode")];
    
    sleep(5);
    
    if (ibssFile != NULL) {
		[self setDownloadText:[NSString stringWithFormat:NSLocalizedString(@"Uploading %@ to device...",@"Uploading %@ to device..."), iBSSDFU]];
		int sendError = send_file(staticDevice, ibssFile);
          NSLog(@"ibss send return: %i", sendError);
        //ir_error = irecv_send_file(client, ibssFile, 1);
		if(sendError != 0) {
			[self setDownloadText:NSLocalizedString(@"Unable to upload iBSS!", @"Unable to upload iBSS!")];
			[self hideProgress];
            stop_notification_monitoring(staticDevice);
            release_device(staticDevice);
		//	pois0n_exit();
			self.poisoning = FALSE;
			[pool release];
			return -1;
		}
	} else {
		return 0;
	}
	
	NSLog(@"iBSS upload successful! Reconnecting in 10 seconds...");
    
	[self setDownloadText:NSLocalizedString(@"iBSS upload successful! Reconnecting in 10 seconds...", @"iBSS upload successful! Reconnecting in 10 seconds...")];
	
    sleep(10);
	
	//client = irecv_reconnect(client, 10);
	
	if (ibecFile != NULL) {
		[self setDownloadText:[NSString stringWithFormat:NSLocalizedString(@"Uploading %@ to device...",@"Uploading %@ to device..."), iBECDFU]];
		int sendError = send_file(staticDevice, ibecFile);
        NSLog(@"ibec send return: %i", sendError);
		if(sendError != 0) {
			[self setDownloadText:NSLocalizedString(@"Unable to upload iBEC!", @"Unable to upload iBEC!")];
			[self hideProgress];
			//pois0n_exit();
            stop_notification_monitoring(staticDevice);
            release_device(staticDevice);
            self.poisoning = FALSE;
			[pool release];
			return -1;
		}
	} else {
		return 0;
	}
	[self setDownloadText:NSLocalizedString(@"iBEC upload successful! Reconnecting in 10 seconds...", @"iBEC upload successful! Reconnecting in 10 seconds...")];
	
	NSLog(@"iBEC upload successful! Reconnecting in 10 seconds...");
	
    sleep(10);
    
	NSLog(@"resetting device");
    reset_device(staticDevice);
    //irecv_reset(client);
    //irecv_reset_counters(client);
	sleep(10);
	//client = irecv_reconnect(client, 10);
	//NSLog(@"changing interface");
    open_interface(staticDevice, 0, 0);
    open_interface(staticDevice, 1, 1);
    //irecv_set_interface(client, 0, 0);
    //irecv_set_interface(client, 1, 1);
	
	NSLog(@"sending kernelcache");
    
	if (kernelcacheFile != NULL) {
		[self setDownloadText:[NSString stringWithFormat:NSLocalizedString(@"Uploading %@ to device...", @"Uploading %@ to device..."), KCACHE]];
		//ir_error = irecv_send_file(client, kernelcacheFile, 1);
		int sendError = send_file(staticDevice, kernelcacheFile);
        NSLog(@"send error: %i", sendError);
        if(sendError != 0) {
			error("Unable to upload kernelcache\n");
			[self hideProgress];
            stop_notification_monitoring(staticDevice);
            release_device(staticDevice);
			//pois0n_exit();
			self.poisoning = FALSE;
			[pool release];
			return -1;
		}
		
        sleep(5);
		NSLog(@"bootx");
		
        int commandError = send_command(staticDevice, "bootx");
		//ir_error = irecv_send_command(client, "bootx");
		if(commandError != 0) {
            [self setDownloadText:NSLocalizedString(@"Tethered boot failed!.",@"Tethered boot failed!." )];
			error("Unable to send the bootx command\n");
            [self hideProgress];
            stop_notification_monitoring(staticDevice);
            release_device(staticDevice);
			//pois0n_exit();
			self.poisoning = FALSE;
			[pool release];
			return -1;
		}
	}
	[self setDownloadText:NSLocalizedString(@"Tethered boot complete! It is now safe to disconnect USB.",@"Tethered boot complete! It is now safe to disconnect USB." )];
	[self hideProgress];
	//pois0n_exit();
    stop_notification_monitoring(staticDevice);
    release_device(staticDevice);
	self.poisoning = FALSE;
	[cancelButton setTitle:@"Done"];
	[instructionImage setImage:[self imageForMode:kSPSuccessImage]];
	[pool release];
	
	return 0;
    
    
}

- (int)sn0wTetheredBoot
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self killiTunes];
	self.poisoning = TRUE;
	[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
	int result = 0;
	irecv_error_t ir_error = IRECV_E_SUCCESS;
	
    //int index;
	const char
	*ibssFile = [self iBSS],
	*kernelcacheFile = [self kernelcache],
	*ibecFile = [self iBEC];
//	pois0n_init();
//	pois0n_set_callback(&print_progress, self);
//    //printf("Waiting for device to enter DFU mode\n");
	[self setDownloadText:NSLocalizedString(@"Waiting for device to enter DFU mode...", @"Waiting for device to enter DFU mode...")];
	[self setInstructionText:NSLocalizedString(@"Connect USB, POWER then press and hold MENU and PLAY/PAUSE for 7 seconds", @"Connect USB, POWER then press and hold MENU and PLAY/PAUSE for 7 seconds")];
	[instructionImage setImage:[self imageForMode:kSPATVTetheredRemoteImage]];
	while(pois0n_is_ready()) {
		sleep(1);
	}
    //irecv_set_debug_level(3);
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
	
	NSLog(@"iBSS upload successful! Reconnecting in 10 seconds...");
    
	[self setDownloadText:NSLocalizedString(@"iBSS upload successful! Reconnecting in 10 seconds...", @"iBSS upload successful! Reconnecting in 10 seconds...")];
	
    sleep(10);
	
	client = irecv_reconnect(client, 10);
	
	if (ibecFile != NULL) {
		[self setDownloadText:[NSString stringWithFormat:NSLocalizedString(@"Uploading %@ to device...",@"Uploading %@ to device..."), iBECDFU]];
		ir_error = irecv_send_file(client, ibecFile, 1);
		if(ir_error != IRECV_E_SUCCESS) {
			[self setDownloadText:NSLocalizedString(@"Unable to upload iBEC!", @"Unable to upload iBEC!")];
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
	[self setDownloadText:NSLocalizedString(@"iBEC upload successful! Reconnecting in 10 seconds...", @"iBEC upload successful! Reconnecting in 10 seconds...")];
	
	NSLog(@"iBEC upload successful! Reconnecting in 10 seconds...");
	
	NSLog(@"resetting irecovery device");
	irecv_reset(client);
    //irecv_reset_counters(client);
	sleep(10);
	client = irecv_reconnect(client, 10);
	NSLog(@"changing interface");
    irecv_set_interface(client, 0, 0);
    irecv_set_interface(client, 1, 1);
	
	NSLog(@"sending kernelcache");
    
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
		
		NSLog(@"bootx");
		
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

- (int)tetheredBootNew
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self killiTunes];
	self.poisoning = TRUE;
	[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
	int result = 0;
	irecv_error_t ir_error = IRECV_E_SUCCESS;
	
		//int index;
	const char 
	*ibssFile = [self iBSS],
	*kernelcacheFile = [self kernelcache],
	*ibecFile = [self iBEC];
	pois0n_init();
	pois0n_set_callback(&print_progress, self);
		//printf("Waiting for device to enter DFU mode\n");
	[self setDownloadText:NSLocalizedString(@"Waiting for device to enter DFU mode...", @"Waiting for device to enter DFU mode...")];
	[self setInstructionText:NSLocalizedString(@"Connect USB, POWER then press and hold MENU and PLAY/PAUSE for 7 seconds", @"Connect USB, POWER then press and hold MENU and PLAY/PAUSE for 7 seconds")];
	[instructionImage setImage:[self imageForMode:kSPATVTetheredRemoteImage]];
	while(pois0n_is_ready()) {
		sleep(1);
	}
		//irecv_set_debug_level(3);
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
	
	NSLog(@"iBSS upload successful! Reconnecting in 10 seconds...");

	[self setDownloadText:NSLocalizedString(@"iBSS upload successful! Reconnecting in 10 seconds...", @"iBSS upload successful! Reconnecting in 10 seconds...")];  
	
		sleep(10);
	
	client = irecv_reconnect(client, 10);
	
	if (ibecFile != NULL) {
		[self setDownloadText:[NSString stringWithFormat:NSLocalizedString(@"Uploading %@ to device...",@"Uploading %@ to device..."), iBECDFU]];
		ir_error = irecv_send_file(client, ibecFile, 1);
		if(ir_error != IRECV_E_SUCCESS) {
			[self setDownloadText:NSLocalizedString(@"Unable to upload iBEC!", @"Unable to upload iBEC!")];
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
	[self setDownloadText:NSLocalizedString(@"iBEC upload successful! Reconnecting in 10 seconds...", @"iBEC upload successful! Reconnecting in 10 seconds...")];  
	
	NSLog(@"iBEC upload successful! Reconnecting in 10 seconds...");
	
	NSLog(@"resetting irecovery device");
	irecv_reset(client);
		//irecv_reset_counters(client);
	sleep(10);
	client = irecv_reconnect(client, 10);
	NSLog(@"changing interface");
		irecv_set_interface(client, 0, 0);
		irecv_set_interface(client, 1, 1);
	
	NSLog(@"sending kernelcache");

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
		
		NSLog(@"bootx");
		
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

	//this code is pretty much verbatim adapted and slightly modified from tetheredboot.c



- (int)tetheredBoot
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self killiTunes];
	self.poisoning = TRUE;
	[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
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
	while(pois0n_is_ready_old()) {
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
	client = irecv_reconnect_old(client, 10);
	
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

+ (BOOL)isAvailable:(NSString *)bundleName
{
    return YES;
		//AppleTV2,1_4.1_8M89
	NSArray *componentArray = [bundleName componentsSeparatedByString:@"_"];
	NSString *versionNumber = [componentArray objectAtIndex:1];
	NSString *baseline = @"4.3";
	NSComparisonResult theResult = [versionNumber compare:baseline options:NSNumericSearch];
		//NSLog(@"properVersion: %@", versionNumber);
		//NSLog(@"theversion: %@  installed version %@", theVersion, installedVersion);
	if ( theResult == NSOrderedDescending )
	{
			//	NSLog(@"%@ is greater than %@", versionNumber, baseline);
		
		return YES;
		
	} else if ( theResult == NSOrderedAscending ){
		
			//NSLog(@"%@ is greater than %@", baseline, versionNumber);
		return NO;
		
	} else if ( theResult == NSOrderedSame ) {
		
			//		NSLog(@"%@ is equal to %@", versionNumber, baseline);
		return NO;
	}
	
	return NO;
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
			if ([tetherKitAppDelegate isAvailable:currentObject])
			{
				[newFiles addObject:[currentObject stringByDeletingPathExtension]];
			} 
			
		}
		
	}
	return [newFiles autorelease];
}

	//defaults convenience functions

+ (BOOL)sshKey
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"sshKey"];
}

+ (BOOL)sigServer
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"sigServer"];
}

+ (BOOL)debWhitelist
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"debWhitelist"];
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

- (NSString *)buildVersion //for printing out in the initial sp_debug.log
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


- (void)showHomePermissionWarning
{
	
	NSAlert *theAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Home Folder Error",@"Home Folder Error") defaultButton:NSLocalizedString(@"Quit", @"Quit") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Seas0nPass is unable to write to your home folder! Please check your ownerships and permissions (via Get Info) and re-run Seas0nPass.", @"Seas0nPass is unable to write to your home folder! Please check your ownerships and permissions (via Get Info) and re-run Seas0nPass.")];
	int buttonReturn = [theAlert runModal];
		NSLog(@"buttonReturn: %i", buttonReturn);
	switch (buttonReturn) {
		case 0:
			break;
		case 1:
			
			[[NSApplication sharedApplication] terminate:self];
			break;
			
			
	}
	
	
}




+ (NSString *)modelFromDevice:(TSSDeviceID)inputDevice
{
	if (DeviceIDEqualToDevice(inputDevice, APPLETV_31_DEVICE))
	{ return APPLETV_31_DEVICE_CLASS; } 
	else if (DeviceIDEqualToDevice(inputDevice, APPLETV_21_DEVICE))
	{ return APPLETV_21_DEVICE_CLASS; }  
	else if (DeviceIDEqualToDevice(inputDevice, IPHONE_11_DEVICE))
	{ return @"m68ap"; } 
	else if (DeviceIDEqualToDevice(inputDevice, IPOD_11_DEVICE))
	{ return @"n46ap"; } 
	else if (DeviceIDEqualToDevice(inputDevice, IPHONE_12_DEVICE)) 
	{ return @"n82ap"; }
	else if (DeviceIDEqualToDevice(inputDevice, IPOD_21_DEVICE)) 
	{ return @"n72ap"; }
	else if (DeviceIDEqualToDevice(inputDevice, IPOD_21_DEVICE)) 
	{ return @"n72ap"; }
	else if (DeviceIDEqualToDevice(inputDevice, IPHONE_21_DEVICE)) 
	{ return @"n88ap"; }
	else if (DeviceIDEqualToDevice(inputDevice, IPOD_31_DEVICE)) 
	{ return @"n18ap"; }
	else if (DeviceIDEqualToDevice(inputDevice, IPAD_11_DEVICE)) 
	{ return @"k48ap"; }
	else if (DeviceIDEqualToDevice(inputDevice, IPHONE_31_DEVICE)) 
	{ return @"n90ap"; }
	else if (DeviceIDEqualToDevice(inputDevice, IPOD_41_DEVICE)) 
	{ return @"n81ap"; }
	else if (DeviceIDEqualToDevice(inputDevice, IPHONE_33_DEVICE)) 
	{ return @"n92ap"; }
	else if (DeviceIDEqualToDevice(inputDevice, IPAD_21_DEVICE)) 
	{ return @"k93ap"; }
	else if (DeviceIDEqualToDevice(inputDevice, IPAD_22_DEVICE)) 
	{ return @"k94ap"; }
	else if (DeviceIDEqualToDevice(inputDevice, IPAD_23_DEVICE)) 
	{ return @"k95ap"; }
    else if (DeviceIDEqualToDevice(inputDevice, APPLETV_32_DEVICE))
    { return APPLETV_32_DEVICE_CLASS; }
	else { NSLog(@"unknown model! boardID: %i chipID: %i", inputDevice.boardID, inputDevice.chipID); return nil; }
	
}



static NSString *HexToDec(NSString *hexValue)
{
	if (hexValue == nil)
		return nil;
	
	unsigned long long dec;
	NSScanner *scan = [NSScanner scannerWithString:hexValue];
	if ([scan scanHexLongLong:&dec])
	{
		
		return [NSString stringWithFormat:@"%llu", dec];
		//NSLog(@"chipID binary: %@", finalValue);
	}
	
	return nil;
}


+ (TSSDeviceID)_getConnectedDevice //unused
{
	
	irecv_init();
	irecv_client_t client = NULL;
	uint32_t bdid = 0;
	uint32_t cpid = 0;
	if (irecv_open(&client) != IRECV_E_SUCCESS)
	{
		NSLog(@"fail!");
		return TSSNullDevice;
		
	}
	
	if (irecv_get_cpid(client, &cpid) < 0) {
		return TSSNullDevice;
	}
	
	if (irecv_get_bdid(client, &bdid) < 0) {
		return TSSNullDevice;
	}
	
	irecv_close(client);
	irecv_exit();
	
	NSString *cpidDecimal = HexToDec([NSString stringWithFormat:@"0x%llu", (unsigned long long)cpid]);
	NSString *bpidDecimal = HexToDec([NSString stringWithFormat:@"0x%llu", (unsigned long long)bdid]);

	return DeviceIDMake([bpidDecimal longLongValue], [cpidDecimal longLongValue]);
}

+ (NSString *)_fetchDeviceModel //unused
{
	TSSDeviceID connectedDevice = [tetherKitAppDelegate _getConnectedDevice];
	
	return [tetherKitAppDelegate modelFromDevice:connectedDevice];
	
}



- (void)_fetchDeviceInfo
{	
	irecv_init();
	irecv_client_t client = NULL;
	if (irecv_open(&client) != IRECV_E_SUCCESS)
	{
		//NSLog(@"fail!");
		return;
		
	}
	int ret;
	uint32_t bdid = 0;
	uint32_t cpid = 0;
	if (irecv_get_cpid(client, &cpid) < 0) {
		NSLog(@"failed to get cpid!");
	}
	

    
	if (irecv_get_bdid(client, &bdid) < 0) {
		NSLog(@"failed to get bdid!");
	}
	
        //NSLog(@"bdid 0x%llu cpid: 0x%llu", (unsigned long long) bdid, (unsigned long long)cpid);
    
	unsigned long long ecid;
	ret = irecv_get_ecid(client, &ecid);
	if(ret == IRECV_E_SUCCESS) {
			printf("ECID: %lld\n", ecid);
	}
	irecv_close(client);
	irecv_exit();
	
	NSString *ecidHex = [NSString stringWithFormat:@"%lld", ecid];
	
	NSLog(@"ecidHex: %@", [ecidHex stringToPaddedHex]);
	
	NSString *cpidDecimal = HexToDec([NSString stringWithFormat:@"0x%llu", (unsigned long long)cpid]);
	NSString *bpidDecimal = HexToDec([NSString stringWithFormat:@"0x%llu", (unsigned long long)bdid]);
	currentDevice = DeviceIDMake([bpidDecimal longLongValue], [cpidDecimal longLongValue]);
	self.deviceClass = [tetherKitAppDelegate modelFromDevice:currentDevice];
	self.theEcid = [NSString stringWithFormat:@"%llu", ecid];
	ChipID_ = self.theEcid;
	
}

/*
 
 get the ecid of the current device to pretty much do any install now. we check saurik's TSS/SHSH signature server for what blobs are available for either the TSS replay attack restore, or stitching blobs.
 
 also check a list we maintain (firecore) of what versions apple is still signing. we will do our best to keep this up to date and as current as possible at all times.

 
 */


- (NSString *)_getEcid
{	
	
	
		//irecv_error_t error = 0;
	irecv_init();
	irecv_client_t client = NULL;
	if (irecv_open(&client) != IRECV_E_SUCCESS)
	{
			//NSLog(@"fail!");
		return nil;
		
	}
	int ret;
	unsigned long long ecid;
	ret = irecv_get_ecid(client, &ecid);
	if(ret == IRECV_E_SUCCESS) {
			//	printf("ECID: %lld\n", ecid);
	}
	irecv_close(client);
	irecv_exit();
	
	NSString *myEcid = [NSString stringWithFormat:@"%llu", ecid];
	
	return myEcid;
	
}

/*
 
 not ever used, but this will take the ecid given, fetch the blobs from apple (that they are still signing) and send them to sauriks server.
 
 */

- (void)fetchBlobs:(NSString *)myEcid
{
	if (myEcid != nil)
	{
		TSSWorker *worker = [[TSSWorker alloc] init];
		
		[worker setEcid:myEcid];
		[worker theWholeShebang];
		[worker autorelease];
	} else {
		NSLog(@"no ecid!!!");
	}
	
}

- (NSString *)getAppleBlobVersion:(NSString *)theVersion //also not used, was probably here for initial testing on creating an apticket from a particular version.

{
	TSSWorker *worker = [[TSSWorker alloc] init];
	[worker setEcid:ChipID_];
	NSString *versionTicket = [worker getAppleVersionTicket:theVersion];
	[worker autorelease];
	return versionTicket;
}

- (NSString *)getBlobVersion:(NSString *)theVersion //also not used, was probably here for initial testing on creating an apticket from a particular version.

{
	TSSWorker *worker = [[TSSWorker alloc] init];
	[worker setEcid:ChipID_];
	NSString *versionTicket = [worker getVersionTicket:theVersion];
	[worker autorelease];
	return versionTicket;
}


- (NSData *)hexFileSize:(NSString *)inputFile //was probably just used for logging / debugging / figuring this mess out.
{
	unsigned long long theSize = [[[[NSFileManager defaultManager] attributesOfItemAtPath:inputFile error:nil] objectForKey:NSFileSize] longLongValue];
		//NSLog(@"thesize: %llu", theSize);
	NSString *newString = [NSString stringWithFormat:@"%.8x", (unsigned int)theSize];
		//NSLog(@"newString: %@", newString);
	return [[NSData dataFromStringHex:newString] reverse];
	
}



- (void)fetchBlobForVersion:(NSString *)theVersion //another custom function i wrote to conveniently dump a specific blob version to my dropbox for some reason ;-P
{
	TSSManager *theMan = [[TSSManager alloc] initWithECID:ChipID_];
	
	NSString *blob = [theMan _synchronousCydiaReceiveVersion:theVersion];
		//NSLog(@"blob: %@", blob);
	NSString *theFilez = [NSHomeDirectory() stringByAppendingPathComponent:@"Dropbox/blob.plist"];
	[blob writeToFile:theFilez atomically:TRUE encoding:NSUTF8StringEncoding error:nil];
	[theMan release];
}

- (void)threadedBlobSend //this will take your local blobs in ~/.shsh for your appletv and submit them to sauriks server.
{
		//LOG_SELF;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *theArray = [TSSManager localAppleTVBlobs];
	if (theArray == nil)
	{
		NSLog(@"no blobs to send!");
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"blobsFinished" object:nil userInfo:nil deliverImmediately:YES];
	}
	NSDictionary *theDict = [NSDictionary dictionaryWithObject:theArray forKey:@"blobs"];
	NSString *cliPath = @"/tmp/031231";
	[theDict writeToFile:cliPath atomically:YES];
	NSString *helpPath = [[NSBundle mainBundle] pathForResource: @"dbHelper" ofType: @""];
	NSTask *pwnHelper = [[NSTask alloc] init];
	
	[pwnHelper setLaunchPath:helpPath];
	
	[pwnHelper setArguments:[NSArray arrayWithObjects:@"nil", cliPath, nil]];
	[pwnHelper launch];
	[pwnHelper waitUntilExit];
	[pwnHelper release];
	pwnHelper = nil;
	[pool release];
}




- (void)blobsFinished:(NSNotification *)n //notification received when the blobs are finished
{
	[DEFAULTS setBool:TRUE forKey:BLOB_KEY];
		NSLog(@"blobsFinished: %@", n);
	[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:@"" waitUntilDone:NO];
	[self hideProgress];
	[window setContentView:self.firstView];
	[self versionChanged:nil];
	[window display];
	
}


- (int)restoreMode
{
		//we set it to -1 upon launch, if it isnt set to -1 then we know we have set it already, and the end of a restore, set back to -1.
	
	/*
	 
	 first see if apple is still signing this version.
	 first get the versions available on cydia
	 
	 */
	NSString *ecid = self.theEcid;
		//NSLog(@"chipID: %@ ecid: %@", ChipID_, self.theEcid);
	
	NSArray *signableVersions = [TSSManager signableVersionsFromModel:self.deviceClass]; //check what versions apple is still signing
	NSString *buildNumber = [[self currentBundle] buildVersion]; //ie 8C154
	NSString *osVersion = [[self currentBundle] osVersion];
	NSString *fourPointThree = @"4.3";
	
	//FIXME: REMEMBER TO COMMENT THIS BACK IN!!!!!!!!!

	
	
	

	if (ecid == nil)
	{
		[self _fetchDeviceInfo];
		ecid = self.theEcid;
		ChipID_ = ecid;
		if (ecid == nil)
		{
			
			int returnButton = [self showDeviceAlert];
			NSLog(@"returnButton: %i", returnButton);
			
			if (returnButton != NSOKButton)
			{
				return kRestoreNoDevice;
				
			} else {
				
				NSLog(@"sleeping for 5 seconds to give appletv time to detect");
				sleep(5);
				NSLog(@"trying to grab the ecid again");
				[self _fetchDeviceInfo];
				ecid = self.theEcid;
				ChipID_ = ecid;
				NSLog(@"chipID: %@ ecid: %@", ChipID_, self.theEcid);
				if (ecid == nil)
				{
					NSLog(@"still failed to get the ecid, alert to quit and re-open seas0npass");
					
					[self showDeviceFailedAlert];
					[self showInitialView];
					[self hideProgress];
					return kRestoreNoDevice;
				}
				
			}
			
			
				//"Please connect the AppleTV via USB to continue."
			
		}
		
		
	}
    
	//if ([buildNumber isEqualToString:@"11B554a"]) //FIX_ME: eventually add restore_external patches!
//	{
//		NSLog(@"6.0.2, still let apple sign for now!! %@ kRestoreDefaultMode", buildNumber);
//		return kRestoreDefaultMode;
//	}
	
    if ([signableVersions containsObject:buildNumber])
	{
		NSLog(@"apple is still signing %@ dont do anything special: kRestoreDefaultMode", buildNumber);
		return kRestoreAppleStitchMode;
	}
	
	if ([self.deviceClass isEqualToString:APPLETV_31_DEVICE_CLASS] || [self.deviceClass isEqualToString:APPLETV_32_DEVICE_CLASS])
	{
		return kRestoreUnsupportedDevice;
	}
	
	
	
	NSLog(@"apple is not signing, check what blobs cydia has for %@", ecid);
	
	TSSManager *tss = [[TSSManager alloc] initWithECID:ecid device:currentDevice];
	//TSSManager *tss = [[TSSManager alloc] initWithECID:ecid];
	NSArray *cydiaBlobs = [tss _newSimpleSynchBlobCheck];
	NSArray *ifaithBlobs = [tss _simpleiFaithSynchronousBlobCheck];
	NSLog(@"cydiaBlobs: %@", cydiaBlobs);
	NSLog(@"ifaithBlobs: %@", ifaithBlobs);
	
	[tss release];
	tss = nil;
	
	BOOL cydiaRescue = [cydiaBlobs containsObject:buildNumber];
	BOOL ifaithRescue = [ifaithBlobs containsObject:buildNumber];
	NSComparisonResult theResult = [osVersion compare:fourPointThree options:NSNumericSearch];
		//NSLog(@"theversion: %@  installed version %@", theVersion, installedVersion);
	if ( theResult == NSOrderedDescending )
	{
		NSLog(@"%@ is greater than %@", osVersion, fourPointThree);
		
			//we are greater than 4.3, we need to see if cydia has our blobs
		
		if (cydiaRescue == TRUE)
		{
			NSLog(@"snitches get stitches!! thanks saurik!");
			
			return kRestoreStitchMode;
		} else {
			
			NSLog(@"no blobs for %@! checking iFaith servers!", buildNumber);
			
			if (ifaithRescue == TRUE)
			{
				NSLog(@"found blob on iFaith servers!!");
				return kRestoreiFaithStitchMode;
			}
			
			
			NSLog(@"not on sauriks server or ih8sn0ws server... no soup for you: %@", buildNumber);
			return kRestoreFirmwareIneligible;
			
		}
		
		
	} else if ( theResult == NSOrderedAscending ){
		
		NSLog(@"%@ is greater than %@", fourPointThree, osVersion);
		
			//see if saurik has us covered with this version to do replay attack we are below 4.3
		
		if (cydiaRescue == TRUE)
		{
			NSLog(@"og replay attackin...now all stitched up.");
			return kRestoreStitchMode;
			
		} else {
			
			NSLog(@"no blobs for %@! checking iFaith servers!", buildNumber);
			
			if (ifaithRescue == TRUE)
			{
				NSLog(@"found blob on iFaith servers!!");
				return kRestoreiFaithStitchMode;
			}
			
			
			NSLog(@"not on sauriks server or ih8sn0ws server... no soup for you: %@", buildNumber);
			return kRestoreFirmwareIneligible;
			
		}
		
		
	} else if ( theResult == NSOrderedSame ) {
		
		NSLog(@"%@ is equal to %@", osVersion, fourPointThree);
		
			//see if saurik has us covered with this version to do replay attack we are below 4.3
		if (cydiaRescue == TRUE)
		{
			NSLog(@"og replay attackin...now all stitched up.");
			return kRestoreStitchMode;
		} else {
			
			NSLog(@"no blobs for %@! checking iFaith servers!", buildNumber);
			
			if (ifaithRescue == TRUE)
			{
				NSLog(@"found blob on iFaith servers!!");
				return kRestoreiFaithStitchMode;
			}
			
			
			NSLog(@"not on sauriks server or ih8sn0ws server... no soup for you: %@", buildNumber);
			return kRestoreFirmwareIneligible;
			
		}
		
		
	}
	
	
	NSLog(@"you are out in the ether!! you are somehow not bigger or smaller than 4.3, not being signed by apple, and the blobs aren't availble on cydia. howd you get here?!?! osVersion: %@ buildVersion: %@ ecid: %@", osVersion, buildNumber, ChipID_);
	
	return kRestoreUnavailableMode;
	
	
}									  



- (BOOL)interwebAvailable
{
	NSHost *theHost = [NSHost hostWithName:@"files.firecore.com"]; //should we check cydia.saurik.com also? or just assume its always working if theres internet... decisions decisions.
	if (theHost != nil)
		return (TRUE);
	
	return (FALSE);
}

- (IBAction)ifaithPayloadDump:(id)sender
{
	[window setContentView:self.secondView];
	[window display];
	
	self.processing = TRUE;
	[buttonOne setEnabled:FALSE];
	[bootButton setEnabled:FALSE];
	[instructionImage setImage:[self imageForMode:kSPIPSWImage]];
	[self showProgress];
	[NSThread detachNewThreadSelector:@selector(dumpiFaithPayload) toTarget:self withObject:nil];
}

- (void)ifaithBlobDone:(NSNotification *)n
{
	NSDictionary *ifaithBlob = [n object];

	if ([[ifaithBlob allKeys] containsObject:@"error"])
	{
		NSLog(@"epic fail :(");
		[self hideProgress];
		[self setDownloadText:@"SHSH extraction Failed"];
		[cancelButton setTitle:@"Done"];
        NSAlert *errorAlert = [NSAlert alertWithMessageText:@"SHSH extraction failed" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[ifaithBlob objectForKey:@"error"]];
        [errorAlert runModal];
		 //[instructionImage setImage:[self imageForMode:kSPSuccessImage]];
		return;
	}
	
	NSLog(@"ifaith blob dumped and submitted!");
		//NSLog(@"ifaithBlobTake2: %@", ifaithBlob);
		//NSString *outputiFaith = [NSHomeDirectory() stringByAppendingPathComponent:@"outputfile.plist"];
		//[ifaithBlob writeToFile:outputiFaith atomically:YES];
		//[[NSWorkspace sharedWorkspace] openFile:outputiFaith];
		//NSLog(@"ifaithblob: %@", ifaithBlob);
		//[self showInitialView];
	[self hideProgress];
	
	[cancelButton setTitle:@"Done"];
    [self setDownloadText:@"Success, please unplug your AppleTV from the computer now."];
	[instructionImage setImage:[self imageForMode:kSPSuccessImage]];
}


//- (NSString *)convertHex
//{
//	
//	NSString *dec = @"2932088167695";
//	;
//	NSString *hex = [NSString stringWithFormat:@"%.016lX", [dec integerValue]];
//	NSMutableString *finalString;
//	NSLog(@"%@", hex);
//}

- (void)testRecieveBlob
{
		//4.3 (8F455).xml
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//NSError *error = nil;
	NSString *testBlobVersion = @"4.3 (8F455)";
	
	
	TSSManager *tss = nil;
	
	if (!DeviceIDEqualToDevice(currentDevice, TSSNullDevice))
	{
		tss = [[TSSManager alloc] initWithECID:ChipID_ device:currentDevice];
	} else {
		
		tss = [[TSSManager alloc] initWithECID:ChipID_];
	}
	
	NSString *response = [tss _synchronousiFaithReceiveVersion:testBlobVersion];
	
	NSLog(@"response: %@", response);
	
	[tss release];
	
	tss = nil;
	[pool release];
}

- (void)testSendBlob
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSError *error = nil;
	NSString *testBlobPath = [[tetherKitAppDelegate applicationSupportFolder] stringByAppendingPathComponent:@"iFaith/000000B5AE1065CE_5.1.1 (10A831).xml"];
	NSString *blobString = [NSString stringWithContentsOfFile:testBlobPath encoding:NSUTF8StringEncoding error:&error];
	if (error!= nil)
	{
		NSLog(@"error: %@", error);
		blobString = [NSString stringWithContentsOfFile:testBlobPath encoding:NSASCIIStringEncoding error:&error];
		if (error != nil)
		{
			NSLog(@"both utf8 and ascii failed!! bail!");
			return;
		}
	}
	
	NSLog(@"blobString: %@", blobString);
	
	TSSManager *tss = nil;
	
	if (!DeviceIDEqualToDevice(currentDevice, TSSNullDevice))
	{
		tss = [[TSSManager alloc] initWithECID:ChipID_ device:currentDevice];
	} else {
		
		tss = [[TSSManager alloc] initWithECID:ChipID_];
	}
	
	NSString *response = [tss _synchronousPushiFaithBlob:blobString withiOSVersion:@"5.1.1 (10A831)"];
	
	NSLog(@"response: %@", response);
	
	[tss release];
	
	tss = nil;
	[pool release];
	
}

- (void)getiFaithBlobArrayTest
{
		//4.3 (8F455).xml
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	
	TSSManager *tss = nil;
	
	if (!DeviceIDEqualToDevice(currentDevice, TSSNullDevice))
	{
		tss = [[TSSManager alloc] initWithECID:ChipID_ device:currentDevice];
	} else {
		
		tss = [[TSSManager alloc] initWithECID:ChipID_];
	}
	
	NSArray *response = [tss _simpleiFaithSynchronousBlobCheck];
	
	NSLog(@"response: %@", response);
	
	[tss release];
	
	tss = nil;
	[pool release];
}

- (void)unsupportedAlert
{
	[window close];
	NSAlert *theAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unsupported architecture", @"Unsupported arch") defaultButton:NSLocalizedString(@"OK", @"OK") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"i386 is no longer supported, a 64 bit machine is required",@"i386 is no longer supported, a 64 bit machine is required")];
	[theAlert runModal];
	[[NSApplication sharedApplication] terminate:self];
	
}

+ (void)initialize
{
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], SPQuitiTunesPreference, nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    
}

void *tetheredThread(void *object);
void *tetheredThread(void* object) {
    
    UKDevice* Device = (UKDevice*)object;
    
    while (Device->pid != 0x1227) {
        
        printf("Waiting for DFU to appear in thread\n");
        sleep(1);
    }
    
    int lr = SHAtter(Device);
    
    printf("SHAtter status: %i\n", lr);
    
    //int lr =  limerain(Device, false);
    
    //printf("limera1n status: %i\n", lr);
    
    if (lr == 0)
    {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"tbr" object:nil];
        limera1ned = TRUE;
    }
    //CFRunLoopStop(CFRunLoopGetCurrent());
    
    
    return NULL;
}

void *otherThread(void* object);
void *otherThread(void* object) {
    
    printf("otherThread\n");
    UKDevice* Device = (UKDevice*)object;
    
    if (ChipID_ == nil)
    {
        printf("nil chip id %s\n", [ChipID_ UTF8String]);
        ChipID_ = [NSString stringWithFormat:@"%lld", Device->ecid];
        printf("updated chip id %s\n", [ChipID_ UTF8String]);
    }
    
    while (!Device->opened) {
        
        printf("waiting for teh device to be opened\n");
        sleep(1);
    }
    
//    while (Device->pid != 0x1227) {
//        
//        printf("Waiting for DFU to appear in thread\n");
//        sleep(1);
//    }
    
    //if (tetheredBoot == false)
      //  stop_notification_monitoring(Device);
    
    //int lr =  limerain(Device, false);
    int lr = SHAtter(Device);
    //printf("limerain status: %i\n", lr);
    
    if (lr == 0)
    {
        
      //  [[NSNotificationCenter defaultCenter] postNotificationName:@"limera1ned" object:ChipID_];
        //limera1ned = TRUE;
    }
    //CFRunLoopStop(CFRunLoopGetCurrent());
    
    
    return NULL;
}

/*
 
 AppleTV restore order
 
 28
 11
 12
 12
 15
 16
 15
 16
 51
 29
 29
 13 (determinate)
 14 (determinate)
 15
 16
 15
 16
 27
 27
 17
 25
 35
 18 (determintate)
 46
 46
 50 (determinate)
 49
 51
 29
 29
 
 */

- (NSString *)restoreStatusForOperation:(int)opValue
{
    NSString *theRestoreStatus = nil;
    
    switch (opValue) {
        
        case -1:
            theRestoreStatus = @"Restore completed";
            break;
        case 0:
        case 1:
        case 2:
            theRestoreStatus = @"Sending DFU File";
            break;
        
        case 3:
            theRestoreStatus = @"Connecting to device";
            break;
            
        case 4:
            theRestoreStatus = @"sending APTicket";
            break;
            
        case 5:
            theRestoreStatus = @"Sending Ramdisk";
            break;
            
        case 6:
            theRestoreStatus = @"Sending DeviceTree";
            break;
            
        case 7:
            theRestoreStatus = @"Sending Kernelcache";
            break;
        
        case 8:
            theRestoreStatus = @"Setting Restore boot-args";
            break;
            
        case 9:
            theRestoreStatus = @"Booting Ramdisk";
            break;
            
        case 10:
            theRestoreStatus = @"Flashing SYSCFG";
            break;
            
        case 11:
            theRestoreStatus = @"Creating RootFS partition";
            break;
            
        case 12:
            theRestoreStatus = @"Creating User Partition";
            break;
            
        case 13:
            theRestoreStatus = @"Restoring AppleTV";
            break;
            
        case 14:
            theRestoreStatus = @"Verifying Restore";
            break;
            
        case 15:
            theRestoreStatus = @"Checking Filesystem";
            break;
            
        case 16:
            theRestoreStatus = @"Mounting Filesystem";
            break;
            
        case 17:
            theRestoreStatus = @"Fixing up /var";
            //theRestoreStatus = NSLocalizedString(@"Restoring Apple TV firmware...", @"Restoring Apple TV firmware...");
            break;
            
        case 18:
            theRestoreStatus = @"Flashing NOR";
            //theRestoreStatus = NSLocalizedString(@"Restoring Apple TV firmware...", @"Restoring Apple TV firmware...");
            break;
            
        case 19:
            theRestoreStatus = @"Flashing baseband";
            break;
            
        case 20:
            theRestoreStatus = @"Setting boot stage";
            break;
            
        case 21:
            theRestoreStatus = @"Rebooting iDevice";
            break;
            
        case 22:
            theRestoreStatus = @"Shutting down AppleTV";
            break;
            
        case 23:
            theRestoreStatus = @"Turning on Acessory Power";
            break;
            
        case 24:
            theRestoreStatus = @"Clearing Persistent boot-args";
            break;
            
        case 25:
            theRestoreStatus = @"Modifying Persistent boot-args";
             //theRestoreStatus = NSLocalizedString(@"Restoring Apple TV firmware...", @"Restoring Apple TV firmware...");
            //break;
            
        case 26:
            theRestoreStatus = @"Installing root";
            break;
            
        case 27:
            theRestoreStatus = @"Installing Kernelcache";
           //theRestoreStatus = NSLocalizedString(@"Restoring Apple TV firmware...", @"Restoring Apple TV firmware...");
            break;
            
        case 28:
            theRestoreStatus = @"Waiting for NAND";
            break;
            
        case 29:
            theRestoreStatus = @"Unmounting Filesystems";
            break;
            
        case 30:
            theRestoreStatus = @"Setting Date and Time";
            break;
            
        case 31:
            theRestoreStatus = @"Executing iBEC to bootstrap update";
            break;
            
        case 32:
            theRestoreStatus = @"Finalizing NAND epoch update";
            break;
            
        case 33:
            theRestoreStatus = @"Checking for inappropriate bootable partitions";
            break;
            
        case 34:
            theRestoreStatus = @"Creating factory restore marker";
            break;
            
        case 35:
            theRestoreStatus = @"Loading firmware data to flash";
             //theRestoreStatus = NSLocalizedString(@"Restoring Apple TV firmware...", @"Restoring Apple TV firmware...");
            break;
            
        case 36:
            theRestoreStatus = @"i dont know";
            break;
            
        case 37:
            theRestoreStatus = @"Checking battery voltage";
            break;
        
        case 38:
            theRestoreStatus = @"Waiting for battery to charge";
            break;
            
        case 39:
            theRestoreStatus = @"Closing modem tickets";
            break;
            
        case 40:
            theRestoreStatus = @"Migrating data";
            break;
            
        case 41:
            theRestoreStatus = @"Wiping storage device";
            break;
            
        case 42:
            theRestoreStatus = @"Sending Apple logo";
            break;
            
        case 43:
            theRestoreStatus = @"Checking for uncollected logs";
            break;
            
        case 44:
            theRestoreStatus = @"Personalizing restore bundle";
            break;
            
        case 45:
            theRestoreStatus = @"Clearing NVRAM";
            break;
            
        case 46:
         //   theRestoreStatus = @"Updating gas gauge software";
            theRestoreStatus = @"Restoring AppleTV firmware...";
            break;
            
        case 47:
            theRestoreStatus = @"Preparing for baseband update";
            break;
            
        case 48:
            theRestoreStatus = @"Booting the baseband";
            break;
            
        case 49:
            theRestoreStatus = @"Creating system key bag";
            break;
            
        case 50:
            theRestoreStatus = @"Updating IR MCU firmware";
           //theRestoreStatus = NSLocalizedString(@"Restoring Apple TV firmware...", @"Restoring Apple TV firmware...");
            break;
            
        case 51:
            theRestoreStatus = @"Resizing system partition";
             //theRestoreStatus = NSLocalizedString(@"Restoring Apple TV firmware...", @"Restoring Apple TV firmware...");
            break;
            
    }
    
    return theRestoreStatus;
    
}

- (int)shatteredTB
{
    //NSLog(@"copyDocuments:%@ toPhone:%@ withVersion:%i", theFile, hostAddress, sshVersion);
    NSPipe *pipe = [[NSPipe alloc] init];
    
    NSTask *usbTask = [[NSTask alloc] init];
    
    [usbTask setStandardError:pipe];
    [usbTask setStandardOutput:pipe];
    
    [usbTask setLaunchPath:[[NSBundle mainBundle] pathForResource:@"usbkit" ofType:@"" inDirectory:@"bin"]];
    [usbTask setArguments:@[@"1", [self.currentBundle localBundlePath]]];
    
    [NSThread detachNewThreadSelector:@selector(processUSBData:) toTarget:self withObject:[pipe fileHandleForReading]];
    [usbTask launch];
    [usbTask waitUntilExit];
    int termStatus = [usbTask terminationStatus];
    //NSLog(@"ringtone copy ended with %i", termStatus);
    if (termStatus == 1)
        
    {
        NSLog(@"tethered booted successfully!?");
        //[[NSFileManager defaultManager] removeFileAtPath:theFile handler:nil];
    } else {
        
        NSLog(@"tethered boot failed: %i",termStatus);
        
    }
    [usbTask release];
    usbTask = nil;
    return termStatus;
    
}

- (int)anotherNewTetheredBoot
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    LOG_SELF;
    tetheredBoot = true;
   
    [self showProgressViewWithText:NSLocalizedString(@"Waiting for device to enter DFU mode...", @"Waiting for device to enter DFU mode...")];
    [self setInstructionText:NSLocalizedString(@"Connect USB then press and hold MENU and PLAY/PAUSE for 7 seconds.", @"Connect USB then press and hold MENU and PLAY/PAUSE for 7 seconds.")];
    
    [instructionImage setImage:[self imageForMode:kSPATVRestoreImage]];
    /*
    NSTask *usbTask = [NSTask launchedTaskWithLaunchPath:[[NSBundle mainBundle] pathForResource:@"usbkit" ofType:@"" inDirectory:@"bin"] arguments:@[@"1", [self.currentBundle localBundlePath]]];
    [usbTask waitUntilExit];
     */
    [self setInstructionText:@""];
    
    [self shatteredTB];
   // [self showProgressViewWithText:NSLocalizedString(@"Found device in DFU mode", @"Found device in DFU mode")];
    [self hideProgress];

    [self setDownloadText:NSLocalizedString(@"Tethered boot complete! It is now safe to disconnect USB.",@"Tethered boot complete! It is now safe to disconnect USB." )];
    [self hideProgress];
    [self performSelectorOnMainThread:@selector(hideProgress) withObject:nil waitUntilDone:true];
    self.poisoning = FALSE;

    [cancelButton setTitle:@"Done"];
    [cancelButton setEnabled:true];
    [instructionImage setImage:[self imageForMode:kSPSuccessImage]];
    
    [pool release];
    pool = nil;
    return 0;
    
}

- (void)processUSBData:(NSFileHandle *)theFile
{
    LOG_SELF;
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
    while(1)
    {
        NSAutoreleasePool *wp = [[NSAutoreleasePool alloc] init];
        NSData *data = [theFile availableData];
        if([data length]) {
            //NSLog(@"data length: %i", [data length]);
            NSString *tempa = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            
            NSString *temp = [tempa  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            if ([temp rangeOfString:@"Waiting for DFU mode..."].location == NSNotFound)
            {
                [self setInstructionText:@""];
            }
            NSArray *lineArray = [temp componentsSeparatedByString:@"\n"];
            
            NSArray *progressArray = [temp componentsSeparatedByString:@"/"];
            
            NSLog(temp);
            if ([[lineArray lastObject] floatValue] > 0)
            {
                [self setDownloadProgress:[[lineArray lastObject] floatValue]];
            } else {
                [self showProgressViewWithText:[lineArray lastObject]];
                
            }

            //[self showProgressViewWithText:temp];
            

            
            
            [tempa release];
            tempa = nil;
            
        } else {
            [wp release];
            [thePool release];
            return;
        }
        [wp release];
    }
    NSLog(@"ending processUSBData");
    [thePool release];
}

- (int)aprocessUSBData:(NSFileHandle *)theFile
{
    NSPipe *pipe = [[NSPipe alloc] init];
    NSFileHandle *handle = [pipe fileHandleForReading];
    
    NSTask *usbTask = [[NSTask alloc] init];
    NSData *outData;
    
    [usbTask setStandardOutput:pipe];
    [usbTask setStandardError:pipe];
    [usbTask setLaunchPath:[[NSBundle mainBundle] pathForResource:@"usbkit" ofType:@"" inDirectory:@"bin"]];
    [usbTask setArguments:@[@"1", [self.currentBundle localBundlePath]]];
    NSString *temp = @"";
    NSMutableArray *lineArray = [[NSMutableArray alloc] init];
    
    [usbTask launch];
    while((outData = [handle readDataToEndOfFile]) && [outData length])
    {
        temp = [[NSString alloc] initWithData:outData encoding:NSASCIIStringEncoding];
        [lineArray addObjectsFromArray:[temp componentsSeparatedByString:@"\n"]];
        [temp release];
    }
    
    int a;
    for(a = 0 ; a < [lineArray count] ; a++) {
        temp = [[lineArray objectAtIndex:a] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSLog(temp);
        if ([temp componentsSeparatedByString:@"/"].count == 2)
        {
            NSArray *comps = [temp componentsSeparatedByString:@"/"];
            NSInteger currentValue = [[comps[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] integerValue];
            NSInteger totalValue = [[comps[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] integerValue];
           if (currentValue && totalValue != 0)
           {
               CGFloat percentComplete = currentValue / totalValue;
               if (percentComplete >= 100) {
                   [self setDownloadProgress:0];
               } else {
                   [self setDownloadProgress:percentComplete];
               }
           }
           
            //  [self setDownloadProgress:0];
            //[self setDownloadProgress:[[progressArray lastObject] floatValue]];
        } else {
            [self showProgressViewWithText:temp];
            
        }
        
    }
    [lineArray release];
    
    int returnStatus = [usbTask terminationStatus];
    
    [usbTask release];
    usbTask = nil;
    [pipe release];
    pipe = nil;
    return returnStatus;
    // return finalInt;
}

- (int)shatterDFU
{
    NSPipe *pipe = [[NSPipe alloc] init];
    NSFileHandle *handle = [pipe fileHandleForReading];
    
    NSTask *usbTask = [[NSTask alloc] init];
    //NSData *outData;
    
    [usbTask setStandardOutput:pipe];
    [usbTask setStandardError:pipe];
    [usbTask setLaunchPath:[[NSBundle mainBundle] pathForResource:@"usbkit" ofType:@"" inDirectory:@"bin"]];
    [usbTask setArguments:@[@"0", [self.currentBundle localBundlePath]]];
   // NSString *temp = @"";
    //NSMutableArray *lineArray = [[NSMutableArray alloc] init];
    
    [NSThread detachNewThreadSelector:@selector(processUSBData:) toTarget:self withObject:handle];
    [usbTask launch];
    
    [usbTask waitUntilExit];
    //    while((outData = [handle readDataToEndOfFile]) && [outData length])
//    {
//        temp = [[NSString alloc] initWithData:outData encoding:NSASCIIStringEncoding];
//        [lineArray addObjectsFromArray:[temp componentsSeparatedByString:@"\n"]];
//        [temp release];
//    }
//    
//    int a;
//    for(a = 0 ; a < [lineArray count] ; a++) {
//        temp = [[lineArray objectAtIndex:a] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//        NSLog(temp);
//        [self showProgressViewWithText:temp];
//        
//    }
//    [lineArray release];
//    
    int returnStatus = [usbTask terminationStatus];
    
    [usbTask release];
    usbTask = nil;
    [pipe release];
    pipe = nil;
    return returnStatus;
   // return finalInt;
}

- (void)anotherNewRestoreIPSW:(NSString *)ipswPath
{
    LOG_SELF;
    NSLog(@"ipswPath: %@", ipswPath);
    tetheredBoot = false;
    [self showProgressViewWithText:NSLocalizedString(@"Waiting for device to enter DFU mode...", @"Waiting for device to enter DFU mode...")];
    [self setInstructionText:NSLocalizedString(@"Connect USB then press and hold MENU and PLAY/PAUSE for 7 seconds.", @"Connect USB then press and hold MENU and PLAY/PAUSE for 7 seconds.")];
    
    [instructionImage setImage:[self imageForMode:kSPATVRestoreImage]];

    [self shatterDFU];
    
    //NSTask *usbTask = [NSTask launchedTaskWithLaunchPath:[[NSBundle mainBundle] pathForResource:@"usbkit" ofType:@"" inDirectory:@"bin"] arguments:@[@"0", [self.currentBundle localBundlePath]]];
    //[usbTask waitUntilExit];
    [self showProgressViewWithText:NSLocalizedString(@"Found device in DFU mode", @"Found device in DFU mode")];
    [self setInstructionText:@""];
    
    
    if (self.theEcid != nil)
    {
        
        IPSW *theFw = [[IPSW alloc] initWithPath:ipswPath];
        
        NSError *theError = nil;
        
        BOOL processIPSW =  [theFw processIPSWwithError:&theError];
        
        if (processIPSW == FALSE)
        {
            NSLog(@"processing IPSW failed!");
        }
        
        if (theError != nil)
        {
            NSLog(@"theerror: %@", theError);
            return;
        }
        
        
        restoreInstance = [[IPSWRestore alloc] initWithIPSW:theFw andECID:self.theEcid];
        [restoreInstance startListening];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreProgress:) name:@"RestoreProgress" object:nil];
        
    } else {
        
        NSLog(@"missing device ecid!!! how'd this happen??");
        [self failedWithReason:@"Device ECID is missing, please try again!"];
        
    }
    
    
}

/**
 
 this is the new restore code added from ih8sn0ws awesome wrapper for apple native classes.
 there is no need to use idevicerestore external binaries anymore, and this gives 
 the heave-ho to the unreliable dreck that is libusb :)
 
 */

- (void)newRestoreIPSW:(NSString *)ipswPath
{
    LOG_SELF;
    NSLog(@"ipswPath: %@", ipswPath);
    currentIPSWPath = ipswPath;
    tetheredBoot = false;
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
    int a[2][2] = { {0x5AC, 0x1227}, {0x5AC, 0x1281} };
    
    /* 
     
     hopefully we're already in DFU mode, under those cirumstance
     this instantiation of Device will be used below, if not there are some tricky
     threading issues for when the notifications are monitored for the device
     detaching and reattaching back in DFU mode. (explained more below)
     
     */
    Device = init_libusbkit(0, [[self.currentBundle localBundlePath] UTF8String], self, shatterStatus);
    
    add_devices(Device, a);
    
    register_for_usb_notifications(Device);
   
   // sleep(5);
    
    NSLog(@"device pid: %i", Device->pid);
    
    if (Device->pid != 0x1227)
    {
        //we're not in DFU mode, so we are tearing down the device declared above
        //in favor of creating it in the main thread so we can properly monitor
        //notifications for when it is attached / detached.
        
        stop_notification_monitoring(Device);
        release_device(Device);
        
        sleep(1);
        
        //not only does it need to be called in the main thread, it has to be called from C code
        //and not obj-c code. so DFUWrapper literally just calls C code in this class
        //that adds the device and spawns a pthread to monitor when DFU is entered.
        [self performSelectorOnMainThread:@selector(DFUWrapper) withObject:nil waitUntilDone:false];
        
    } else {
        
        //if the device was not attached the minute the app launched we don't have the ecid assigned.
        
         NSLog(@"ecid: %@ length: %lu", self.theEcid, (unsigned long)self.theEcid.length);
         if (self.theEcid.length == 0);
         {
             NSLog(@"ecid length supposedly zero??: %lu", (unsigned long)self.theEcid.length);
             self.theEcid = [NSString stringWithFormat:@"%lld", Device->ecid];
             NSLog(@"new ecid: %@",  self.theEcid);
         }
        
        //if we don't stop monitoring notifications after limera1n is run
        //when the device detaches and re-attaches libusbkit will grab exclusive access
        //thats no bueno and will saddle us with a 2001 error from AMRestore.
        //stop_notification_monitoring(Device);
        //limerain(Device, false);
        //printf("newREstoreIpws\n");
        SHAtter(Device);
       // stop_notification_monitoring(Device);
        
       // limera1ned = true;
        
        //release_device(Device);
    }
    
    [self showProgressViewWithText:NSLocalizedString(@"Waiting for device to enter DFU mode...", @"Waiting for device to enter DFU mode...")];
    [self setInstructionText:NSLocalizedString(@"Connect USB then press and hold MENU and PLAY/PAUSE for 7 seconds.", @"Connect USB then press and hold MENU and PLAY/PAUSE for 7 seconds.")];
    
    [instructionImage setImage:[self imageForMode:kSPATVRestoreImage]];

    while (limera1ned == false)
    {
       // fprintf(stderr, "Waiting for it to ra1n\n");
        sleep(1);
    }
    
    NSLog(@"outside of limera1ned finished");
    //once we get this far we are home free! the restore below should always work!
    
    [self setInstructionText:@""];
    
    //if we get this far and theEcid is still nil, theres a chance we fetched it before applying
    //limera1n in otherThread.
    
    if(self.theEcid == nil)
    {
        if(ChipID_ != nil)
        {
            self.theEcid = ChipID_;
            NSLog(@"updated ecid to: %@", self.theEcid);
        }
   
    }
    
    [self showProgressViewWithText:NSLocalizedString(@"Found device in DFU mode", @"Found device in DFU mode")];
    

    if (self.theEcid != nil)
    {
     
        IPSW *theFw = [[IPSW alloc] initWithPath:ipswPath];
        
        NSError *theError = nil;
        
        BOOL processIPSW =  [theFw processIPSWwithError:&theError];
        
        if (processIPSW == FALSE)
        {
            NSLog(@"processing IPSW failed!");
        }
        
        if (theError != nil)
        {
            NSLog(@"theerror: %@", theError);
            return;
        }
        
        
        restoreInstance = [[IPSWRestore alloc] initWithIPSW:theFw andECID:self.theEcid];
        [restoreInstance startListening];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreProgress:) name:@"RestoreProgress" object:nil];
        
    } else {
        
        NSLog(@"missing device ecid!!! how'd this happen??");
        [self failedWithReason:@"Device ECID is missing, please try again!"];
        
    }
}

- (void)newTetheredBoot
{
    LOG_SELF;
    tetheredBoot = true;
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    int a[2][2] = { {0x5AC, 0x1227}, {0x5AC, 0x1281} };
    
    /*
     
     hopefully we're already in DFU mode, under those cirumstance
     this instantiation of Device will be used below, if not there are some tricky
     threading issues for when the notifications are monitored for the device
     detaching and reattaching back in DFU mode. (explained more below)
     
     */
    Device = init_libusbkit(1, [[self.currentBundle localBundlePath] UTF8String], self, shatterStatus);
    
    add_devices(Device, a);
    
    register_for_usb_notifications(Device);
    
    // sleep(5);
    
    NSLog(@"device pid: %i", Device->pid);
    
    if (Device->pid != 0x1227)
    {
        //we're not in DFU mode, so we are tearing down the device declared above
        //in favor of creating it in the main thread so we can properly monitor
        //notifications for when it is attached / detached.
        
        stop_notification_monitoring(Device);
        release_device(Device);
        
        sleep(1);
        
        //not only does it need to be called in the main thread, it has to be called from C code
        //and not obj-c code. so DFUWrapper literally just calls C code in this class
        //that adds the device and spawns a pthread to monitor when DFU is entered.
        [self performSelectorOnMainThread:@selector(tetheredDFUWrapper) withObject:nil waitUntilDone:false];
        
    } else {
        
        //if the device was not attached the minute the app launched we don't have the ecid assigned.
        
        NSLog(@"ecid: %@ length: %lu", self.theEcid, (unsigned long)self.theEcid.length);
        if (self.theEcid.length == 0);
        {
            NSLog(@"ecid length supposedly zero??: %lu", (unsigned long)self.theEcid.length);
            self.theEcid = [NSString stringWithFormat:@"%lld", Device->ecid];
            NSLog(@"new ecid: %@",  self.theEcid);
        }
        
        printf("new tetheredboot\n");
        SHAtter(Device);
    }
    
    [self showProgressViewWithText:NSLocalizedString(@"Waiting for device to enter DFU mode...", @"Waiting for device to enter DFU mode...")];
    [self setInstructionText:NSLocalizedString(@"Connect USB then press and hold MENU and PLAY/PAUSE for 7 seconds.", @"Connect USB then press and hold MENU and PLAY/PAUSE for 7 seconds.")];
    
    [instructionImage setImage:[self imageForMode:kSPATVTetheredRemoteImage]];
    
   
}

//for some reason if the code is called straight from this method rather
//than a C method, the thread doesn't detach properly or somethin?

- (void)DFUWrapper
{
    LOG_SELF;
    monitorForDeviceAndDetachThread([[self.currentBundle localBundlePath] UTF8String], self);
}

- (void)tetheredDFUWrapper
{
    monitorForDeviceAndDetachThreadForTether([[self.currentBundle localBundlePath] UTF8String], self);
}

int monitorForDeviceAndDetachThreadForTether(const char* path, void* class)
{
    int a[2][2] = { {0x5AC, 0x1227}, {0x5AC, 0x1281} };
    
    staticDevice = init_libusbkit(1, path, class, shatterStatus);
    
    add_devices(staticDevice, a);
    
    register_for_usb_notifications(staticDevice);
    
    pthread_attr_t  attr;
    pthread_t       posixThreadID;
    int             returnVal;
    
    returnVal = pthread_attr_init(&attr);
    assert(!returnVal);
    returnVal = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    assert(!returnVal);
    
    int threadError = pthread_create(&posixThreadID, &attr, &tetheredThread, staticDevice);
    
    returnVal = pthread_attr_destroy(&attr);
    assert(!returnVal);
    if (threadError != 0)
    {
        // Report an error.
    }
    
    
    CFRunLoopRun();
    return 0;
}


int monitorForDeviceAndDetachThread(const char* path, void* class)
{
    printf("monitorForDeviceAndDetach\n");
    int a[2][2] = { {0x5AC, 0x1227}, {0x5AC, 0x1281} };
    
    UKDevice *Device = init_libusbkit(0, path, class, shatterStatus);
    
    add_devices(Device, a);
    
    register_for_usb_notifications(Device);
    
    pthread_attr_t  attr;
    pthread_t       posixThreadID;
    int             returnVal;
    
    returnVal = pthread_attr_init(&attr);
    assert(!returnVal);
    returnVal = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    assert(!returnVal);
    
    int threadError = pthread_create(&posixThreadID, &attr, &otherThread, Device);
    
    returnVal = pthread_attr_destroy(&attr);
    assert(!returnVal);
    if (threadError != 0)
    {
        // Report an error.
    }
    
    
    CFRunLoopRun();
    return 0;
}

- (void)shatterFinished:(int)mode {
    
    LOG_SELF;
    
    stop_notification_monitoring(Device);
    //release_device(Device);
    //NSLog(@"chipID: %@", ChipID_);
  //  [[NSNotificationCenter defaultCenter] postNotificationName:@"limera1ned" object:ChipID_];
    limera1ned = true;
    
    if (mode == 0) //restore
    {
        [self finishRestore];
    }
}

- (void)finishRestore
{
    [self setInstructionText:@""];
    
    //if we get this far and theEcid is still nil, theres a chance we fetched it before applying
    //limera1n in otherThread.
    
    if(self.theEcid == nil)
    {
        if(ChipID_ != nil)
        {
            self.theEcid = ChipID_;
            NSLog(@"updated ecid to: %@", self.theEcid);
        }
        
    }
    
    [self showProgressViewWithText:NSLocalizedString(@"Found device in DFU mode", @"Found device in DFU mode")];
    
    
    if (self.theEcid != nil)
    {
        
        IPSW *theFw = [[IPSW alloc] initWithPath:currentIPSWPath];
        
        NSError *theError = nil;
        
        BOOL processIPSW =  [theFw processIPSWwithError:&theError];
        
        if (processIPSW == FALSE)
        {
            NSLog(@"processing IPSW failed!");
        }
        
        if (theError != nil)
        {
            NSLog(@"theerror: %@", theError);
            return;
        }
        
        
        restoreInstance = [[IPSWRestore alloc] initWithIPSW:theFw andECID:self.theEcid];
        [restoreInstance startListening];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreProgress:) name:@"RestoreProgress" object:nil];
        
    } else {
        
        NSLog(@"missing device ecid!!! how'd this happen??");
        [self failedWithReason:@"Device ECID is missing, please try again!"];
        
    }
}

- (void)updateStatus:(int)status
{
    printf("\nupdateStatus: %i\n", status);
    //NSLog(@"status updated: %i", status);
    shatterStatus = status;
    //return;
    stop_notification_monitoring(Device);
    //release_device(Device);
   // close_libusbkit(Device);
    sleep(5);
    
    //not only does it need to be called in the main thread, it has to be called from C code
    //and not obj-c code. so DFUWrapper literally just calls C code in this class
    //that adds the device and spawns a pthread to monitor when DFU is entered.
    if (tetheredBoot == true)
    {
        [self tetheredDFUWrapper];
    } else {
        [self DFUWrapper];
       //[self performSelectorOnMainThread:@selector(DFUWrapper) withObject:nil waitUntilDone:false];
    }
    //[self performSelectorOnMainThread:@selector(DFUWrapper) withObject:nil waitUntilDone:false];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	
	restoreStatus = FALSE;
		//quitItunes
	[self rollLogFile];
	if ([nitoUtility is64Bit])
	{
		
		NSLog(@"we're 64bit, we're okay");
	} else {
		
		NSLog(@"i386 bail");
		[self unsupportedAlert];
			//[[NSApplication sharedApplication] terminate:self];
	}

		//	NSArray *testArray = [TSSManager ifaithBlobArrayFromString:[TSSManager testString]];
		//NSLog(@"testArray: %@", testArray);
		//unsigned long long ecid = 
	
	[self printEnvironment];
	
	[self _fetchDeviceInfo];
	
		//[self getAppleBlobVersion:@"11A502"];
	
	NSLog(@"ecid: %@ deviceClass: %@", self.theEcid, self.deviceClass);
	
	if ([self interwebAvailable] == FALSE)
	{
		
		NSAlert *theAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Internet Unavailable", @"Internet Unavailable") defaultButton:nil alternateButton:NSLocalizedString(@"OK", @"OK") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Seas0nPass is unable to retrieve firmware details. Please check your internet connection and firewall settings.", @"Seas0nPass is unable to retrieve firmware details. Please check your internet connection and firewall settings.")];
		
		[theAlert runModal];
		[[NSApplication sharedApplication] terminate:self];
		
		
	}
	_downloadRetries = 0;
	//[self iTunesScriptReady];
	ChipID_ = self.theEcid;
	_restoreMode = kRestoreUnavailableMode;
	
	//NSLog(@"ecid: %@", ChipID_);
	

	if ([self homeWritable])
	{
		
		//NSLog(@"can write to home!");
	} else{
		
		[self showHomePermissionWarning];
		
		NSLog(@"cant write to home!!");
	}
	
		//killiTunes
	if ([self optionKeyIsDown])
	{
		//[otherWindow makeKeyAndOrderFront:nil];
	}
	
	
	[window setContentView:self.firstView];
	downloadIndex = 0;
	downloadFiles = [[NSMutableArray alloc] init];
	self.processing = FALSE;
	self.poisoning = FALSE;
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(pwnFinished:) name:@"pwnFinished" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(pwnFailed:) name:@"pwnFailed" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(blobsFinished:) name:@"blobsFinished" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(statusChanged:) name:@"statusChanged" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(checksumFinished:) name:@"checksumFinished" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldDownloadFinished:) name:@"shouldDownloadFinish" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ifaithBlobDone:) name:IFAITH_BLOB_DONE object:nil];
		//[self startupAlert];
	
	//check the ownership to make sure we can continue on our merry way
	
	BOOL theStuff = [self pwnHelperCheckOwner];
	if (theStuff == FALSE)
	{
		[[NSApplication sharedApplication] terminate:self];
	}
//	[self checkScripting]; //make sure UI scripting is enabled for the iTunes chicanery
    
	NSString *lastUsedbundle = LAST_BUNDLE;

	if ([lastUsedbundle length] < 1)
	{
			//NSLog(@"lastUsedBundle is nil, set it!");
		lastUsedbundle = CURRENT_BUNDLE;
		[[NSUserDefaults standardUserDefaults] setObject:lastUsedbundle forKey:@"lastUsedBundle"];
	}
	
	
	self.currentBundle = [FWBundle bundleWithName:LAST_BUNDLE];

		//[self.currentBundle logDescription];
	
	[FM removeItemAtPath:TMP_ROOT error:nil]; //clean up from last run
		
	
	[self setBundleControllerContent];
	
	[self versionChanged:nil];
	
	if (DID_MIGRATE == TRUE)
	{
		NSLog(@"already migrated");
	} else {
		[NSThread detachNewThreadSelector:@selector(cleanupHomeFolder) toTarget:self withObject:nil];
	}
			
	if (BLOBS_SENT == TRUE)
	{
		NSLog(@"local blobs already sent");
		
	} else {

		NSLog(@"sending local blobs!!!");
		[window setContentView:self.secondView];
		[window display];
		
		self.processing = TRUE;
		[buttonOne setEnabled:FALSE];
		[bootButton setEnabled:FALSE];
		[instructionImage setImage:[self imageForMode:kSPIPSWImage]];
		[self showProgress];
		[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
		[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:NSLocalizedString(@"Saving firmware signatures...",@"Saving firmware signatures...") waitUntilDone:NO];
		[NSThread detachNewThreadSelector:@selector(threadedBlobSend) toTarget:self withObject:nil];

	}

		//	[NSThread detachNewThreadSelector:@selector(getiFaithBlobArrayTest) toTarget:self withObject:nil];
		//[self ifaithPayloadDump];
    
    //return;


    
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(limerainApplied:) name:@"limera1ned" object:nil];
}

/*
 
 this gets called if the appletv isn't in DFU mode and ready for limera1n from the initial restore.
 newRestoreIPSW waits on limera1ned to be true before it will proceed with restoring.
 
 */

- (void)tetheredBootReady:(NSNotification *)n
{
    LOG_SELF;
    limera1ned = true;
//    NSLog(@"object: %@", [n object]);
    //Device = (UKDevice *)[n object];
}

- (void)limerainApplied:(NSNotification *)n
{
    LOG_SELF;
    limera1ned = true;
    NSLog(@"object: %@", [n object]);
    //theres a chance we already have self.theEcid set, a nil check fails here
    //so just always set it.. don't really like this but it appears to work..
    self.theEcid = [n object];
   if (tetheredBoot == false)
       release_device(Device);
}

/*
 
 2014-12-14 15:51:45.911 Seas0nPass[966:303] restoreProgress: {
 Operation = "-1";
 Progress = "-1";
 Status = Successful;
 }
 
 */

- (void)restoreProgress:(NSNotification *)n
{
  //  LOG_SELF;
    NSDictionary *progressDict = [n userInfo];
    //NSLog(@"ProgressDict: %@", progressDict);
    int operation = [[progressDict valueForKey:@"Operation"] intValue];
    int progress = [[progressDict valueForKey:@"Progress"] intValue];
    NSString *status = [progressDict valueForKey:@"Status"];
    
    
    
    if (progress == -1)
    {
        [self setDownloadProgress:0];
    } else {
        [self setDownloadProgress:progress];
    }
    
    if (operation == -1) //we're finished, check the status!
    {
        NSLog(@"finished with status: %@", status);
        if ([status isEqualToString:@"Successful"])
        {
            
            [self performSelectorOnMainThread:@selector(setDownloadText:) withObject:NSLocalizedString(@"Firmware restore successful!", @"Firmware restore successful!") waitUntilDone:NO];
            NSLog(@"Firmware restore successful!");
           // [self setDownloadText:];
            [instructionImage setImage:[self imageForMode:kSPSuccessImage]];
			[self hideProgress];
            self.restoreStatus = TRUE;
            [cancelButton setTitle:NSLocalizedString(@"Done", @"Done")];
            [[NSUserDefaults standardUserDefaults] setObject:self.currentBundle.bundleName forKey:@"lastUsedBundle"];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RestoreProgress" object:nil];
            [restoreInstance stopListening];
            [restoreInstance release];
             restoreInstance = nil;
          //  close_libusbkit(Device);
        } else {
            
            [self performSelectorOnMainThread:@selector(setDownloadText:) withObject:NSLocalizedString(@"Firmware restore failed", @"Firmware restore failed") waitUntilDone:NO];
             NSLog(@"Firmware restore failed");
           // [instructionImage setImage:[self imageForMode:kSPSuccessImage]];
			[self hideProgress];
            
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RestoreProgress" object:nil];
            self.restoreStatus = FALSE;
            [restoreInstance stopListening];
            [restoreInstance release];
            restoreInstance = nil;
           //  close_libusbkit(Device);
        }
    } else {
        
        [self performSelectorOnMainThread:@selector(setDownloadText:) withObject:[self restoreStatusForOperation:operation] waitUntilDone:NO];
        NSLog(@"%@", [self restoreStatusForOperation:operation]);
      //  [self setDownloadText:[self restoreStatusForOperation:operation]];
        
    }
    
    
    //NSLog(@"restoreProgress: %@", [n userInfo]);
    
}

- (void)failedWithReason:(NSString *)theReason
{
	
	NSDictionary *failDict = [NSDictionary dictionaryWithObject:theReason forKey:@"AbortReason"];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"pwnFailed" object:nil userInfo:failDict deliverImmediately:YES];
}

- (void)showInitialView
{
	[window setContentView:self.firstView];
	
	[window display];
	self.processing = FALSE;
	[buttonOne setEnabled:TRUE];
	[bootButton setEnabled:TRUE];
}

- (void)showProgressViewWithText:(NSString *)theString
{
	[window setContentView:self.secondView];
	[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:theString waitUntilDone:YES];

	self.processing = TRUE;
	[buttonOne setEnabled:FALSE];
	[bootButton setEnabled:FALSE];
	
	[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
	[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
	
	[instructionImage setImage:[self imageForMode:kSPIPSWImage]];
		[window display];
}

- (void)validateFileThreaded:(NSString *)ipsw
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	FWBundle *ourBundle = [FWBundle bundleForFile:ipsw];
    NSLog(@"ourBundle: %@", ourBundle);
	NSString *sha = [ourBundle SHA];
    NSLog(@"sha: %@", sha);
    if (sha == nil)
    {
        [pool release];
        return;
        
    }
    
	[nitoUtility altValidateFile:ipsw withChecksum:sha];
	[pool release];
}

#pragma mark we start here

- (IBAction)processOne:(id)sender //download and modify ipsw
{
		//LOG_SELF;
	
	//int theRestoreMode = kRestoreUnavailableMode;
	
	if (![self sufficientSpaceOnDevice:NSHomeDirectory()])
	{
		NSLog(@"insufficient space on device!!!!!");
		return;
	}
	
	
		//current bundle may be set by default, but we never want to assume the default processOne ipsw to be anything but the latest- which is still hardcoded to 4.2.1.

	self.currentBundle = [FWBundle bundleWithName:CURRENT_BUNDLE];
	

	
	if ([self optionKeyIsDown]) //choose custom firmware version
	{
		NSOpenPanel *op = [NSOpenPanel openPanel];
        [op setAllowedFileTypes:[NSArray arrayWithObject:@"ipsw"]];
		[op setTitle:NSLocalizedString(@"Please select an Apple TV firmware image",@"Please select an Apple TV firmware image" )];
		[op setCanChooseFiles:YES];
		[op setCanCreateDirectories:NO];
		int buttonPressed = [op runModal];
		if (buttonPressed != NSOKButton)
		{
			return;
		}
      
        NSString *ipsw = [[op URL] path]; //so stupid
		FWBundle *ourBundle = [FWBundle bundleForFile:ipsw];
		
		if (ourBundle == nil)
		{
			NSAlert *errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unsupported Firmware!", @"Unsupported Firmware!") defaultButton:NSLocalizedString(@"OK", @"OK") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The firmware %@ is not compatible with this version of Seas0nPass.", @"The firmware %@ is not compatible with this version of Seas0nPass."), [ipsw lastPathComponent]];
			[errorAlert runModal];
			return;
		}
		self.currentBundle = ourBundle;
	
		/*
		 
		 no more lock ups when option clicking to choose a bundle, also happens to validate much quicker now too, only 3 more places to thread!
		 
		 
		 */
		
		[self showProgressViewWithText:NSLocalizedString(@"Validating IPSW...", @"Validating IPSW...")];
		
		[NSThread detachNewThreadSelector:@selector(validateFileThreaded:) toTarget:self withObject:ipsw];
		
		return;
	} //end option key down if / custom payload selection
	
    _restoreMode = [self restoreMode];
    
    if (_restoreMode == kRestoreNoDevice)
    {
        return;
    }
    
    [self.currentBundle setRestoreMode:_restoreMode];
    
	if ([self isAppleTV3])
	{
		[self showIncompatDeviceAlert];
		return;
	}
	[window setContentView:self.secondView];
	[window display];
	
	self.processing = TRUE;
	[buttonOne setEnabled:FALSE];
	[bootButton setEnabled:FALSE];
	[instructionImage setImage:[self imageForMode:kSPIPSWImage]];

	/*
	 
	 one more instance of validating the file with 'proper' threading
	 
	 */
	
	[NSThread detachNewThreadSelector:@selector(checkFileDownload:) toTarget:self withObject:self.currentBundle];
	/*
	BOOL download = [self filesToDownload];
	
	theRestoreMode = 0;
	
	if (download == TRUE)
	{
		[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
		[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
		NSLog(@"downloading IPSW...");
		
		[self downloadTheFiles];
		
	} else {
		
		NSLog(@"Seas0nPass: Software payload: %@", [self.currentBundle bundleName]);
		[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
		
		NSDictionary *customFwDict = [NSDictionary dictionaryWithObjectsAndKeys:HCIPSW, @"file", [NSString stringWithFormat:@"%i", theRestoreMode], @"restoreMode", nil];
		[NSThread detachNewThreadSelector:@selector(customFW:) toTarget:self withObject:customFwDict];
	}
	 
	 */
	
} //end process one

- (void)checkFileDownload:(FWBundle *)theBundle
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSFileManager *man = [NSFileManager defaultManager];
	NSString *ipsw = [tetherKitAppDelegate ipswFile];
	NSString *sha = [theBundle SHA];
	NSString *downloadLink = [theBundle downloadURL];
	NSLog(@"ipsw: %@", ipsw);
	if ([man fileExistsAtPath:ipsw])
	{
		NSLog(@"validating file: %@", ipsw);
		[self showProgressViewWithText:NSLocalizedString(@"Validating IPSW...", @"Validating IPSW...")];
		if ([nitoUtility validateFile:ipsw withChecksum:sha] == FALSE) 
		{
			NSLog(@"ipsw SHA Invalid, not removing file (for now, need to make sure its not a beta)");
			if (downloadLink != nil)
			{
				NSLog(@"there is a download url!, we can safely delete and then re-download");
				[ man removeItemAtPath:ipsw error:nil];
			}
			
		} else {
			
			NSLog(@"Seas0nPass: Software payload: %@", [theBundle bundleName]);
			[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
		
			NSDictionary *customFwDict = [NSDictionary dictionaryWithObjectsAndKeys:HCIPSW, @"file", [NSString stringWithFormat:@"%i", 4], @"restoreMode", nil];
			[self customFW:customFwDict];
			[pool release];
			return;
		}
		
	}
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:ipsw forKey:@"file"];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"shouldDownloadFinish" object:nil userInfo:userInfo deliverImmediately:YES];
	
	
	
	[pool release];
}

/*

 //thoughts of disabling keyboard / mouse when running applescript
 
bool dontForwardTap = false;

CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
	
	
		//NSLog(@"Event Tap: %d", (int) CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode));
	
    if (dontForwardTap)
        return nil;
    else
        return event;
}

void tap_keyboard(void) {
    CFRunLoopSourceRef runLoopSource;
	
    CGEventMask mask = kCGEventMaskForAllEvents;
		//CGEventMask mask = CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventKeyDown);
	
    CFMachPortRef eventTap = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, mask, myCGEventCallback, NULL);
	
    if (!eventTap) { 
        NSLog(@"Couldn't create event tap!");
        exit(1);
    }
	
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
	
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
	
    CGEventTapEnable(eventTap, true);
	
    CFRelease(eventTap);
    CFRelease(runLoopSource);
	
}
 
 */

- (void)customFW:(NSDictionary *)theDict //called inside process one
{
	
		//LOG_SELF;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *inputIPSW = [theDict valueForKey:@"file"];
	int restoreMode = [[theDict valueForKey:@"restoreMode"] intValue];
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
	
	[nu setRestoreMode:restoreMode];
	[nu setSigServer:[tetherKitAppDelegate sigServer]];
	[nu setDebWhitelist:[tetherKitAppDelegate debWhitelist]];
	[nu setEnableScripting:self.enableScripting];
	[nu setCurrentBundle:theBundle];
	[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
	[self setDownloadText:NSLocalizedString(@"Unzipping IPSW...",@"Unzipping IPSW..." )];
	if ([nitoUtility unzipFile:inputIPSW toPath:TMP_ROOT])
	{
        NSLog(@"unzip finished successfully!");
		
		/*
		 if ([[self currentBundle] shouldUpdatePartitionSize])
		 {
		 NSLog(@"updating partition size!!");
		 {
		 [[self currentBundle] setMinimumSystemPartition:1024];
		 }
		 }
		 */
		
		[self setDownloadText:NSLocalizedString(@"Patching ramdisk...", @"Patching ramdisk...")];
		status = [self performFirmwarePatches:theBundle withUtility:nu];
		if (status == 0)
		{
			NSLog(@"firmware patches successful!");
			[self setDownloadText:NSLocalizedString(@"Patching filesystem...", @"Patching filesystem...")];
			[nu patchFilesystem:[TMP_ROOT stringByAppendingPathComponent:fileSystemFile]];
		} else {
			
			NSLog(@"firmware patches failed!!");
			
			[self failedWithReason:@"Firmware patches failed!"];
			
		}
		
	}
	
	[nu autorelease]; //FIXME: not sure if this is going to cause anything to bail, trying to work on memory management here!
	
		//[self hideProgress];
	[pool release];
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

	NSString *fail = [NSString stringWithFormat:NSLocalizedString(@"Process failed with reason: %@",@"Process failed with reason: %@" ), [[n userInfo] objectForKey:@"AbortReason"]];
	[self setDownloadText:fail];
	[self hideProgress];
	[[NSWorkspace sharedWorkspace] selectFile:@"SP_Debug.log" inFileViewerRootedAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/"]];

}

- (void)pwnFinished:(NSNotification *)n
{
	
		[NSThread detachNewThreadSelector:@selector(wrapItUp:) toTarget:self withObject:[n userInfo]];
}

- (NSArray *)ipswContentsNoManifest //for when we stitch firmware, im sure it could be more elegant but it wasnt cooperating any other way.
{
	
	NSMutableArray *ipswFiles = [[NSMutableArray alloc] init];
	[ipswFiles addObject:[TMP_ROOT stringByAppendingPathComponent:@"Firmware"]];
	[ipswFiles addObject:[TMP_ROOT stringByAppendingPathComponent:[[self currentBundle] kernelCacheName]]];

	[ipswFiles addObject:[TMP_ROOT stringByAppendingPathComponent:@"Restore.plist"]];
	return [ipswFiles autorelease];
}

- (NSArray *)ipswContents
{
	NSString *buildM = [TMP_ROOT stringByAppendingPathComponent:@"BuildManifest.plist"];
	
	NSMutableArray *ipswFiles = [[NSMutableArray alloc] init];
	[ipswFiles addObject:[TMP_ROOT stringByAppendingPathComponent:@"Firmware"]];
	[ipswFiles addObject:[TMP_ROOT stringByAppendingPathComponent:[[self currentBundle] kernelCacheName]]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:buildM])
		[ipswFiles addObject:buildM];
	[ipswFiles addObject:[TMP_ROOT stringByAppendingPathComponent:@"Restore.plist"]];
	return [ipswFiles autorelease];
}

- (void)createSupportBundleWithCache:(NSString *)theCache iBSS:(NSString *)iBSS
{
	//NSLog(@"createSupportBundleWithCache: %@ iBSS: %@", theCache, iBSS);
	NSString *bundleOut = self.currentBundle.localBundlePath;
	//NSLog(@"localBundlePath: %@", bundleOut);
	if ([FM createDirectoryAtPath:bundleOut withIntermediateDirectories:YES attributes:nil error:nil] == FALSE)
	{
		NSLog(@"failed to create directory: %@", bundleOut);
	}
	NSDictionary *buildManifest = [NSDictionary dictionaryWithObjectsAndKeys:[theCache lastPathComponent], @"KernelCache", [iBSS lastPathComponent], @"iBSS", nil];
	[buildManifest writeToFile:[bundleOut stringByAppendingPathComponent:@"BuildManifest.plist"] atomically:YES];
	//	NSLog(@"copy: %@ to %@", theCache, [self.currentBundle localKernel]);
    if ([FM fileExistsAtPath:self.currentBundle.localKernel])
        [FM removeItemAtPath:self.currentBundle.localKernel error:nil];
	 [FM copyItemAtPath:theCache toPath:self.currentBundle.localKernel error:nil];
	//	NSLog(@"copy: %@ to %@", iBSS, self.currentBundle.localiBSS);
    if ([FM fileExistsAtPath:self.currentBundle.localiBSS])
        [FM removeItemAtPath:self.currentBundle.localiBSS error:nil];
	 [FM copyItemAtPath:iBSS toPath:self.currentBundle.localiBSS error:nil];
	
}

- (void)createSupportBundleWithCache:(NSString *)theCache iBSS:(NSString *)iBSS iBEC:(NSString *)iBEC
{
 
	//NSLog(@"createSupportBundleWithCache: %@ iBSS: %@ iBEC: %@", theCache, iBSS, iBEC);
	NSString *bundleOut = self.currentBundle.localBundlePath;
	//NSLog(@"localBundlePath: %@", bundleOut);
	if ([FM fileExistsAtPath:bundleOut])
	{
        [FM removeItemAtPath:bundleOut error:nil];
	
    }
	if ([FM createDirectoryAtPath:bundleOut withIntermediateDirectories:YES attributes:nil error:nil] == FALSE)
	{
		NSLog(@"failed to create directory: %@", bundleOut);
	}
	NSDictionary *buildManifest = [NSDictionary dictionaryWithObjectsAndKeys:[theCache lastPathComponent], @"KernelCache", [iBSS lastPathComponent], @"iBSS", [iBEC lastPathComponent], @"iBEC", nil];
	[buildManifest writeToFile:[bundleOut stringByAppendingPathComponent:@"BuildManifest.plist"] atomically:YES];
	//NSLog(@"copy: %@ to %@", theCache, [self.currentBundle localKernel]);
	[FM copyItemAtPath:theCache toPath:self.currentBundle.localKernel error:nil];
	//NSLog(@"copy: %@ to %@", iBSS, self.currentBundle.localiBSS);
	[FM copyItemAtPath:iBSS toPath:self.currentBundle.localiBSS error:nil];
	
	//NSLog(@"copy: %@ to %@", iBEC, self.currentBundle.localiBEC);
	[FM copyItemAtPath:iBEC toPath:self.currentBundle.localiBEC error:nil];
	
}


- (void)wrapItUp:(NSDictionary *)theDict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		//NSLog(@"pwnFinished!");
	[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
	NSString *outputPath = [theDict valueForKey:@"Path"];
	NSString *theDMG = [theDict valueForKey:@"os"];
	int myRestoreMode = [[theDict valueForKey:@"restoreMode"] intValue];
	[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:NSLocalizedString(@"Converting image to read only compressed...",@"Converting image to read only compressed...") waitUntilDone:NO];
		//[progressText setStringValue:@"Converting Image to read only compressed..."];

	
	NSString *finalPath = [nitoUtility convertImage:outputPath toFile:[IPSW_TMP stringByAppendingPathComponent:[theDMG lastPathComponent]] toMode:kDMGReadOnly]; //convert image to readonly
	
	[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:NSLocalizedString(@"Scanning image for restore...",@"Scanning image for restore..." ) waitUntilDone:NO];
	
	NSLog(@"rw path?: %@", outputPath);
	[FM removeFileAtPath:outputPath handler:nil];
	
	[nitoUtility scanForRestore:finalPath];
	
	BOOL is44 = [[self currentBundle] is4point4];
	
	NSString *kcache = [TMP_ROOT stringByAppendingPathComponent:[[self currentBundle] kernelCacheName]];
	NSString *ibss = [TMP_ROOT stringByAppendingPathComponent:[[self currentBundle] iBSSName]];
	NSString *ibec = [TMP_ROOT stringByAppendingPathComponent:[[self currentBundle] iBECName]];
	
	if (is44 == TRUE)
	{
		
		NSLog(@"4.4+!!!!");
		
		[self createSupportBundleWithCache:kcache iBSS:ibss iBEC:ibec];
		
		
	} else {
		NSLog(@"under 4.4/5.0");
        
		[self createSupportBundleWithCache:kcache iBSS:ibss];

	}
	
    int status = [self performSupportBundlePatches:[self currentBundle]];
    
    NSLog(@"support bundle patches ended with status: %i", status);
    
	
	if (myRestoreMode == kRestoreStitchMode)
	{
		NSLog(@"stitch it up!");
    
		TSSManager *tss = nil;
		
		if (!DeviceIDEqualToDevice(currentDevice, TSSNullDevice))
		{
			tss = [[TSSManager alloc] initWithECID:ChipID_ device:currentDevice];
		} else {
		
			tss = [[TSSManager alloc] initWithECID:ChipID_];
		}
		
		
		[tss stitchFirmware:[self currentBundle]];
		
		[tss release];
		
		tss	= nil;
		
		[nitoUtility migrateFiles:[self ipswContentsNoManifest] toPath:IPSW_TMP];
        
	} else if (myRestoreMode == kRestoreiFaithStitchMode){
		
		NSLog(@"stitch it up! ifaith style");
		
		
		TSSManager *tss = nil;
		
		if (!DeviceIDEqualToDevice(currentDevice, TSSNullDevice))
		{
			tss = [[TSSManager alloc] initWithECID:ChipID_ device:currentDevice];
		} else {
			
			tss = [[TSSManager alloc] initWithECID:ChipID_];
		}
		
		
		[tss stitchFirmwareForiFaith:[self currentBundle]];
		
		[tss release];
		
		tss	= nil;
		
		[nitoUtility migrateFiles:[self ipswContentsNoManifest] toPath:IPSW_TMP];
	
		
	} else if (myRestoreMode == kRestoreAppleStitchMode) {
    
        NSLog(@"stitch it up with apples blobs!");
        
		TSSManager *tss = nil;
		
		if (!DeviceIDEqualToDevice(currentDevice, TSSNullDevice))
		{
			tss = [[TSSManager alloc] initWithECID:ChipID_ device:currentDevice];
		} else {
            
			tss = [[TSSManager alloc] initWithECID:ChipID_];
		}
		
		
		[tss openStitchFirmware:[self currentBundle]];
		
		[tss release];
		
		tss	= nil;
		
		[nitoUtility migrateFiles:[self ipswContentsNoManifest] toPath:IPSW_TMP];
    
    
    } else {
	
        [nitoUtility migrateFiles:[self ipswContents] toPath:IPSW_TMP];
		
	}
	
	NSString *ipswPath = [self ipswOutputPath];
	
    int ipswStatus = 0;
    
    //dont need to zip the folder anymore, just migrate it to proper location
    
    //what if the folders already there?? BUGGGGG.
    
    NSString *newPath = [ipswPath stringByDeletingPathExtension];
    
    //append ECID
    
    newPath = [newPath stringByAppendingFormat:@"_%@", ChipID_];
    
    if ([FM fileExistsAtPath:newPath])
    {
        [FM removeItemAtPath:newPath error:nil];
    }
    
    NSLog(@"moving: %@ to %@", IPSW_TMP, newPath);
    
    [FM moveItemAtPath:IPSW_TMP toPath:newPath error:nil];
    
    
    
    /*
    
	[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:NSLocalizedString(@"Creating IPSW...", @"Creating IPSW...") waitUntilDone:NO];
	
	int ipswStatus = [nitoUtility createIPSWToFile:ipswPath];
	
	NSLog(@"ipsw creation status: %i", ipswStatus);

*/
    
    [FM removeItemAtPath:TMP_ROOT error:nil];
	
	
		// if we failed, say so
	
	if (ipswStatus == 0)
	{
		NSLog(@"ipsw created successfully!");
		
		[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:NSLocalizedString(@"Custom IPSW created successfully!" , @"Custom IPSW created successfully!" ) waitUntilDone:NO];
		
		[self hideProgress];
		[self killiTunes];
		
		[self _fetchDeviceInfo];
		
		if ([self isAppleTV3])
		{
			[self showInitialView];
			[self hideProgress];
			[self showIncompatDeviceAlert];
			
			return;
		}
		
        //old DFU code
        
        /*
        
        int dfuStatus = 0;
		
		if (is44 == TRUE)
		{
			
			dfuStatus = [self enterDFUNEW];
			NSLog(@"dfu entered with status: %i", dfuStatus);
			
			
		} else {
			
			dfuStatus = [self enterDFU];
			
			NSLog(@"dfu entered with status: %i", dfuStatus);
		}
		
		if (dfuStatus != 0)
		{
			NSLog(@"failed to enter dfu, bail!");
			
		}
		

		if ([self isAppleTV3])
		{
			[self showInitialView];
			[self hideProgress];
			[self showIncompatDeviceAlert];
			
			return;
		}
		*/
        
		[cancelButton setEnabled:FALSE];
		[cancelButton setTitle:NSLocalizedString(@"Cancel", @"Cancel")];
		NSString *progressString = [NSString stringWithFormat:NSLocalizedString(@"Restoring %@...", @"Restoring IPSW"), [ipswPath lastPathComponent]];
		
		[self setDownloadText:progressString];
			//[self setDownloadText:NSLocalizedString(@"Restoring in iTunes, Please wait while script is running...",@"Restoring in iTunes, Please wait while script is running...") ];
		[self setDownloadProgress:0];
		
		int restoreStatus = 0;
		
		NSString *buildNumber = [[self currentBundle] buildVersion]; //ie 8C154

        //old restore code below, not needed
        
        [self newRestoreIPSW:newPath];
        
        [pool release];
        return;
        
		//if ([buildNumber isEqualToString:@"11B554a"])
//		{
//			NSLog(@"********* W00T: special restore consideration for 6.0.2! use the FORCE");
//			restoreStatus = [nitoUtility restoreIPSW:ipswPath force:TRUE];
//			
//		} else {
//			
			restoreStatus = [nitoUtility restoreIPSW:ipswPath];
				//}
		
		if(self.restoreStatus == TRUE)
		{
			NSLog(@"restore status true!");
		} else {
			NSLog(@"restore status false (could be false positive)!");
		}
		
		if (restoreStatus == 0)
		{
			[self setDownloadText:NSLocalizedString(@"Firmware restore successful!", @"Firmware restore successful!")];
			[instructionImage setImage:[self imageForMode:kSPSuccessImage]];
			[self hideProgress];
			[cancelButton setTitle:NSLocalizedString(@"Done", @"Done")];
		} else { //always showing success because of false positives.
			
			[self setDownloadText:NSLocalizedString(@"Firmware restore successful!", @"Firmware restore successful!")];
			[instructionImage setImage:[self imageForMode:kSPSuccessImage]];
			[self hideProgress];
			[cancelButton setTitle:NSLocalizedString(@"Done", @"Done")];
			
		}
			
		
		/*
		if ([self scriptingEnabled])
		{
			[self setDownloadText:NSLocalizedString(@"Restoring in iTunes. Please wait while script is running...",@"Restoring in iTunes. Please wait while script is running...") ];
			if ([self loadItunesWithIPSW:ipswPath] == FALSE)
			{
				[self setDownloadText:NSLocalizedString(@"iTunes restore script failed!, selecting IPSW in Finder...", @"iTunes restore script failed!, selecting IPSW in Finder...")];
				[[NSWorkspace sharedWorkspace] selectFile:ipswPath inFileViewerRootedAtPath:NSHomeDirectory()];
				[cancelButton setTitle:NSLocalizedString(@"Done", @"Done")];
			} else {
				[self setDownloadText:NSLocalizedString(@"iTunes restore script successful!", @"iTunes restore script successful!")];
				[cancelButton setTitle:NSLocalizedString(@"Done", @"Done")];
				[instructionImage setImage:[self imageForMode:kSPSuccessImage]];
			}
			
		} else { //scripting is not enabled.
			
			[[NSWorkspace sharedWorkspace] selectFile:ipswPath inFileViewerRootedAtPath:NSHomeDirectory()];
			[cancelButton setTitle:NSLocalizedString(@"Done", @"Done")];
		}
		 */
		
		
		[cancelButton setTitle:NSLocalizedString(@"Done", @"Done")];
		[[NSUserDefaults standardUserDefaults] setObject:self.currentBundle.bundleName forKey:@"lastUsedBundle"];

        
	} else { //creating ipsw failed
		
		[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:NSLocalizedString(@"Custom IPSW creation failed!" , @"Custom IPSW creation failed!" ) waitUntilDone:NO];
		[self hideProgress];
			[cancelButton setTitle:NSLocalizedString(@"Failed", @"Failed")];
		NSLog(@"ipsw creation failed!!");
		
	}
	
	
	
	
	
	[pool release];
}

- (BOOL)homeWritable
{
	
	NSFileManager *man = [NSFileManager defaultManager];
	//NSDictionary *attrs = [man attributesOfItemAtPath:NSHomeDirectory() error:nil];
		//NSLog(@"attrs: %@", attrs);
	NSString *homeDir = [nitoUtility applicationSupportFolder];
	return [man isWritableFileAtPath:homeDir];
	
}

	//log out and update progress for idevicerestore

- (void)dataReadyFormat:(NSFileHandle *)theFile
{
	NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	while(1)
    {
		NSAutoreleasePool *wp = [[NSAutoreleasePool alloc] init];
		NSData *data = [theFile availableData];
		if([data length]) {
				//NSLog(@"data length: %i", [data length]);
			NSString *tempa = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
			
			NSString *temp = [tempa  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			NSArray *lineArray = [temp componentsSeparatedByString:@"\n"];
		
			NSArray *progressArray = [temp componentsSeparatedByString:@"]"];
		
			if ([[lineArray objectAtIndex:0] rangeOfString:@"%"].location == NSNotFound)
				NSLog(@"%@", temp);
			
			if ([lineArray count] > 1)
			{
				
				for (NSString *progressString in lineArray)
				{
					if ([progressString rangeOfString:@"%"].location == NSNotFound)
					{
							LogIt(progressString);
							//NSLog(@"%@", progressString);
						
						[self setDownloadText:[self replacementProgressForString:progressString]];
						//if ([progressString isEqualToString:@"Unknown operation (18)"])
//						{
//							[self setDownloadText:NSLocalizedString(@"Restoring device firmware (18)", @"Resotring device firmware")];
//						} else {
//							[self setDownloadText:progressString];
//						}
						
							//[self performSelectorOnMainThread:@selector(setDownloadText:) withObject:progressString waitUntilDone:YES];
						
					}
					
					if ([progressString rangeOfString:@"Status:"].length > 0)
					{
							//found the status string, should only happen at the end!
						NSString *statusSubstring = [progressString substringWithRange:NSMakeRange(8, [progressString length]-8)];
						NSLog(@"statusSubstring: -%@-", statusSubstring);
						if ([statusSubstring isEqualToString:@"Restore Finished"])
						{
							NSLog(@"restore was successful??");
			
								self.restoreStatus = TRUE;
							
							
						} else {
							
								//NSLog(@"restore failed???");
								
								self.restoreStatus = FALSE;
						}
					}
					
				
				}
				
			}
			
			if ([progressArray count] == 2 && [lineArray count] == 1)
			{
				float progress = [[progressArray lastObject] floatValue];
				if (progress == 100)
				{
						//NSLog(@"at 100");
						//[self setDownloadText:NSLocalizedString(@"Verifying...", @"verifying")];
					[self setDownloadProgress:0];
					
				} else {
				
					[self setDownloadProgress:[[progressArray lastObject] floatValue]];
				}
				
					//NSLog(@"percantage: %.2f", [[progressArray lastObject] floatValue]);
			}
			
			
			[tempa release];
			tempa = nil;
			
		} else {
			[wp release];
			[thePool release];
			return;
		}
		[wp release];
	}
	[thePool release];
}

- (NSString *)replacementProgressForString:(NSString *)inputString
{
	if ([inputString isEqualToString:@"Extracting filesystem from IPSW"]) return NSLocalizedString(@"Extracting software...", @"Extracting software...");
	if ([inputString isEqualToString:@"Sending filesystem now..."]) return NSLocalizedString(@"Restoring Apple TV software...", @"Restoring Apple TV software...");
	if ([inputString isEqualToString:@"Restoring image (14)"]) return NSLocalizedString(@"Verifying Apple TV software...", @"Verifying Apple TV software...");
	if ([inputString isEqualToString:@"Checking filesystems (16)"]) return NSLocalizedString(@"Verifying Apple TV software...", @"Verifying Apple TV software...");
	if ([inputString isEqualToString:@"Unknown operation (18)"]) return NSLocalizedString(@"Restoring Apple TV firmware...", @"Restoring Apple TV firmware...");
	if ([inputString isEqualToString:@"Unknown operation (46)"]) return NSLocalizedString(@"Restoring Apple TV firmware...", @"Restoring Apple TV firmware...");
	if ([inputString isEqualToString:@"Unknown operation (50)"]) return NSLocalizedString(@"Restoring Apple TV firmware...", @"Restoring Apple TV firmware...");
	return (inputString);
}

- (void)threadedDFURestore
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self killiTunes];
	
    /*
    
	BOOL is44 = [[self currentBundle] is4point4];
	if (is44 == TRUE)
	{
		NSLog(@"DFU NEW!");
		[self enterDFUNEW];
		
	} else {
		
		NSLog(@"DFU OLD!");
		
		[self enterDFU];
	}
	
	*/
		//NSString *ipswPath = [NSHomeDirectory() stringByAppendingPathComponent:CUSTOM_RESTORE];
	NSString *ipswPath = [self ipswOutputPath];
    
    NSString *extractedPath = [ipswPath stringByDeletingPathExtension];
    NSString *newExtractedPath = [extractedPath stringByAppendingFormat:@"_%@", ChipID_];
    
	if(![FM fileExistsAtPath:extractedPath])
	{
		//[self setDownloadText:NSLocalizedString(@"No IPSW to restore!", @"No IPSW to restore!")];
		//[self hideProgress];
		//return;
	
        if (![FM fileExistsAtPath:ipswPath] && ![FM fileExistsAtPath:newExtractedPath])
        {
            [self setDownloadText:NSLocalizedString(@"No IPSW to restore!", @"No IPSW to restore!")];
            [self hideProgress];
            return;
        } else {
            
            NSString *extractedPath = [ipswPath stringByDeletingPathExtension];
            
            [self setDownloadText:NSLocalizedString(@"Unzipping IPSW...",@"Unzipping IPSW..." )];
            if ([nitoUtility unzipFile:ipswPath toPath:extractedPath])
            {
                ipswPath = extractedPath;
            }
            
        }
    
    } else {
        
        
        //file DOES exist at extracted path for new restore code!
        
      
        
        ipswPath = extractedPath;
        
        NSLog(@"extracted path exists: %@", ipswPath);
        
        
        if ([FM fileExistsAtPath:newExtractedPath])
        {
            ipswPath = newExtractedPath;
            NSLog(@"chip id specific ipsw exists, use that instead: %@", ipswPath);
        }
        
        
        
        
    }
	NSString *progressString = [NSString stringWithFormat:NSLocalizedString(@"Restoring %@...", @"Restoring IPSW"), [ipswPath lastPathComponent]];
	
	[self setDownloadText:progressString];
		//[self setDownloadText:NSLocalizedString(@"Restoring in iTunes, Please wait while script is running...",@"Restoring in iTunes, Please wait while script is running...") ];
	[self setDownloadProgress:0];
	
		//[pool release];
		//return;
	
    
    [self newRestoreIPSW:ipswPath];
    //[self anotherNewRestoreIPSW:ipswPath];
    
    [pool release];
    
    return;
    
		int restoreStatus = 0;
	
	NSString *buildNumber = [[self currentBundle] buildVersion]; //ie 8C154
	//if ([buildNumber isEqualToString:@"11B554a"])
//	{	
//			//restoreStatus = [nitoUtility restoreIPSW:ipswPath force:TRUE];
//			restoreStatus = 0;
//	}
//	else
//	{
		restoreStatus = [nitoUtility restoreIPSW:ipswPath];
	
		//}
	
	
	if (restoreStatus == 0)
	{
		[self setDownloadText:NSLocalizedString(@"Firmware restore successful!", @"Firmware restore successful!")];
		[instructionImage setImage:[self imageForMode:kSPSuccessImage]];
		
	} else {
		
		[self setDownloadText:NSLocalizedString(@"Firmware restore failed?", @"Firmware restore successful!")];
		
	}
	[self hideProgress];
	[cancelButton setTitle:NSLocalizedString(@"Done", @"Done")];
	
    /*
	if ([self loadItunesWithIPSW:ipswPath] == FALSE)
	{
		[self setDownloadText:NSLocalizedString(@"Failed to run iTunes script!!",@"Failed to run iTunes script!!") ];
	} else {
		[self setDownloadText:NSLocalizedString(@"iTunes restore script successful!", @"iTunes restore script successful!")];
		[cancelButton setTitle:NSLocalizedString(@"Done", @"Done")];
		[instructionImage setImage:[self imageForMode:kSPSuccessImage]];
	}
	*/
	
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

    [self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
[	NSThread detachNewThreadSelector:@selector(threadedDFURestore) toTarget:self withObject:nil];
		//[self enterDFU];
}

- (void)killiTunes
{
	if ([UD boolForKey:SPQuitiTunesPreference] == TRUE) {
		NSString *killItunesString = @"tell application \"iTunes\" to quit";
		NSAppleScript *theScript = [[NSAppleScript alloc] initWithSource:killItunesString];
		[theScript executeAndReturnError:nil];
		[theScript release];
		theScript = nil;
	}
	
}

- (void)rollLogFile
{
	NSString *logFile = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/SP_Debug.log"];
	float fileSize = [[[FM attributesOfItemAtPath:logFile error:nil] objectForKey:NSFileSize] floatValue];
	float bytes = fileSize/1024;
	float mb = bytes/1024;
	NSLog(@"log file size: %.02f MB", mb);
		//	NSLog(@"attrs: %@",[FM attributesOfItemAtPath:theFile error:nil]);
	if (mb > 10)
	{
		NSLog(@"log file is over 10 megs, clearing and creating a new one");
		system("/bin/echo \"restarting log\" > ~/Library/Logs/SP_Debug.log");
			//[FM removeItemAtPath:logFile error:nil];
			//[FM createFileAtPath:logFile contents:[NSData data] attributes:nil];
	}
	
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
		//NSLog(@"fixScript: %@", asString);
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

	//click button 1 of scroll area 1 of splitter group 1 of window 1


- (BOOL)iTunesIsElevenPlus
{
	NSBundle *itunesBundle = [NSBundle bundleWithPath:@"/Applications/iTunes.app"];
	NSDictionary *itunesDict = [itunesBundle infoDictionary];
	NSString *versionNumber = [itunesDict valueForKey:@"CFBundleShortVersionString"];
	NSComparisonResult theResult = [versionNumber compare:@"11" options:NSNumericSearch];
	NSLog(@"iTunes version: %@", versionNumber);
		//NSLog(@"theversion: %@  installed version %@", theVersion, installedVersion);
	if ( theResult == NSOrderedDescending )
	{
			//NSLog(@"%@ is greater than %@", versionNumber, @"10.4");
		
		return YES;
		
	} else if ( theResult == NSOrderedAscending ){
		
			//NSLog(@"%@ is greater than %@", @"10.4", versionNumber);
		return NO;
		
	} else if ( theResult == NSOrderedSame ) {
		
			//NSLog(@"%@ is equal to %@", versionNumber, @"10.4");
		return YES;
	}
	
	return NO;
}

- (BOOL)iTunesIsTenFourPlus
{
	NSBundle *itunesBundle = [NSBundle bundleWithPath:@"/Applications/iTunes.app"];
	NSDictionary *itunesDict = [itunesBundle infoDictionary];
	NSString *versionNumber = [itunesDict valueForKey:@"CFBundleShortVersionString"];
	NSComparisonResult theResult = [versionNumber compare:@"10.4" options:NSNumericSearch];
	NSLog(@"iTunes version: %@", versionNumber);
    //NSLog(@"theversion: %@  installed version %@", theVersion, installedVersion);
	if ( theResult == NSOrderedDescending )
	{
		//NSLog(@"%@ is greater than %@", versionNumber, @"10.4");
		
		return YES;
		
	} else if ( theResult == NSOrderedAscending ){
		
		//NSLog(@"%@ is greater than %@", @"10.4", versionNumber);
		return NO;
		
	} else if ( theResult == NSOrderedSame ) {
		
		//NSLog(@"%@ is equal to %@", versionNumber, @"10.4");
		return YES;
	}
	
	return NO;
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

- (BOOL)iTunesScriptReady
{
	
	NSDictionary *theError = nil;
	NSMutableString *asString = [[NSMutableString alloc] init];
	
	[asString appendString:@"activate application \"iTunes\"\n"];
		//[asString appendString:@"tell application \"System Events\"\n"];
		//[asString appendString:@"tell Process \"iTunes\"\n"];
		//[asString appendString:@"delay 5\n"];
		//[asString appendString:@"end tell\n"];
		//[asString appendString:@"end tell\n"];
	
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource:asString];
	[as executeAndReturnError:&theError];
	[asString release];
	asString = nil;
	[as release];
	
		//use AXUI shit to get the bounds, much more elegant than doing it with applescript, should be more reliable / less error prone.
	
	AXUIElementRef _systemWideElement;
    AXUIElementRef _focusedApp;
    CFTypeRef _focusedWindow;
		// CFTypeRef _position;
  //  CFTypeRef _size;
	//CFStringRef _name;
	CFNumberRef _fullScreen;
	
    _systemWideElement = AXUIElementCreateSystemWide();
	
		//Get the app that has the focus
    AXUIElementCopyAttributeValue(_systemWideElement,
								  (CFStringRef)kAXFocusedApplicationAttribute,
								  (CFTypeRef*)&_focusedApp);
	
		//Get the window that has the focus
    if(AXUIElementCopyAttributeValue((AXUIElementRef)_focusedApp,
									 (CFStringRef)NSAccessibilityFocusedWindowAttribute,
									 (CFTypeRef*)&_focusedWindow) == kAXErrorSuccess) {
		
		if(CFGetTypeID(_focusedWindow) == AXUIElementGetTypeID()) {
			
			AXUIElementCopyAttributeValue((AXUIElementRef)_focusedWindow, (CFStringRef)CFSTR("AXFullScreen"), (CFTypeRef *)&_fullScreen);
			
			NSLog(@"is full screen: %@", (NSNumber *)_fullScreen);
				//return (![_fullScreen boolValue]); //if its full screen we want to return false
		if ([(NSNumber *)_fullScreen intValue] == 1)
		{
			NSLog(@"full screen, return false");
			return (FALSE);
		}
			
		}
    } else {
		NSLog(@"Cant determine iTunes bounds");
		return TRUE;
    }
	
	return TRUE; //default to it not being full screen, may not be idiot proof enough if something goes awry
}

- (BOOL)iTunesScriptReadyold
{
	//if ([self isMountainLion])
	//{
	//	return (TRUE);//mountain lion scripting actually works in full screen.
	//}
	//use applescript to launch the app and give it ample time to do full screen animation just in case it is full screen
	
	NSDictionary *theError = nil;
	NSMutableString *asString = [[NSMutableString alloc] init];
	
	[asString appendString:@"activate application \"iTunes\"\n"];
	[asString appendString:@"tell application \"System Events\"\n"];
	[asString appendString:@"tell Process \"iTunes\"\n"];
	[asString appendString:@"delay 5\n"];
	[asString appendString:@"end tell\n"];
	[asString appendString:@"end tell\n"];
	
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource:asString];
	[as executeAndReturnError:&theError];
	[asString release];
	asString = nil;
	[as release];
	
	//use AXUI shit to get the bounds, much more elegant than doing it with applescript, should be more reliable / less error prone.
	
	AXUIElementRef _systemWideElement;
    AXUIElementRef _focusedApp;
    CFTypeRef _focusedWindow;
   // CFTypeRef _position;
    CFTypeRef _size;
	//CFStringRef _name;
	
    _systemWideElement = AXUIElementCreateSystemWide();
	
	//Get the app that has the focus
    AXUIElementCopyAttributeValue(_systemWideElement,
								  (CFStringRef)kAXFocusedApplicationAttribute,
								  (CFTypeRef*)&_focusedApp);
	
    //Get the window that has the focus
    if(AXUIElementCopyAttributeValue((AXUIElementRef)_focusedApp,
									 (CFStringRef)NSAccessibilityFocusedWindowAttribute,
									 (CFTypeRef*)&_focusedWindow) == kAXErrorSuccess) {
		
		if(CFGetTypeID(_focusedWindow) == AXUIElementGetTypeID()) {
	
			if(AXUIElementCopyAttributeValue((AXUIElementRef)_focusedWindow,
											 (CFStringRef)NSAccessibilitySizeAttribute,
											 (CFTypeRef*)&_size) != kAXErrorSuccess) {
				NSLog(@"Can't Retrieve Window Size");
		
			} else {
				NSSize size;
				
				
				if(AXValueGetType(_size) == kAXValueCGSizeType) {
					AXValueGetValue(_size, kAXValueCGSizeType, (void*)&size);
						NSLog(@"itunes window size: %@", NSStringFromSize(size));
					
					
					
					if ([self isFullScreen:size])
					{
						NSLog(@"is full screen!");
						return FALSE;
					} else {
						
						NSLog(@"is NOT full screen");
						
					}
					
				} //kAXValueCGSizeType true
				
			} //kAXErrorSuccess else
		}
    } else {
		NSLog(@"Cant determine iTunes bounds");
		return TRUE;
    }
	
	return TRUE; //default to it not being full screen, may not be idiot proof enough if something goes awry
}

- (BOOL)isFullScreen:(NSSize)theSize
{
	NSRect fsRect = [[NSScreen mainScreen] frame];
	NSSize fsSize = fsRect.size;
	
	return NSEqualSizes(fsSize, theSize);

	
}

/*
 
 this method first gets iTunes up and running, then uses AXUIElement interaction from ApplicationServices/HIServices to anaylze itunes for full screen / sidebar visibility
 
 fortunately the splitter is always item 13, we check the count of the children of the AXSplitGroup, if its 1, then we know we dont have a sidebar, if its greater than 1 we do!
 
 
 
 
 */


- (void)analyzeiTunes
{
	
	NSDictionary *theError = nil;
	NSMutableString *asString = [[NSMutableString alloc] init];
	[asString appendString:@"activate application \"iTunes\"\n"];
	[asString appendString:@"activate application \"iTunes\"\n"];
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource:asString];
	[as executeAndReturnError:&theError];
	[asString release];
	asString = nil;
	[as release];
	
	AXUIElementRef _systemWideElement;
    AXUIElementRef _focusedApp;
    CFTypeRef _focusedWindow;
	
	CFNumberRef _fullScreen;
	CFArrayRef _children;
	CFArrayRef _splitterChildren;

	
    _systemWideElement = AXUIElementCreateSystemWide();
	
		//Get the app that has the focus
    AXUIElementCopyAttributeValue(_systemWideElement,
								  (CFStringRef)kAXFocusedApplicationAttribute,
								  (CFTypeRef*)&_focusedApp);
	
		//Get the window that has the focus
    if(AXUIElementCopyAttributeValue((AXUIElementRef)_focusedApp,
									 (CFStringRef)NSAccessibilityFocusedWindowAttribute,
									 (CFTypeRef*)&_focusedWindow) == kAXErrorSuccess) {
		
		if(CFGetTypeID(_focusedWindow) == AXUIElementGetTypeID()) {
			
		
			AXUIElementCopyAttributeValue((AXUIElementRef)_focusedWindow, (CFStringRef)CFSTR("AXFullScreen"), (CFTypeRef *)&_fullScreen);
			
			NSLog(@"is full screen: %i", [(NSNumber *)_fullScreen intValue]);
			
			itunesFullScreen = [(NSNumber *)_fullScreen boolValue];
			
			AXUIElementCopyAttributeValue((AXUIElementRef)_focusedWindow, (CFStringRef)kAXChildrenAttribute, (CFTypeRef *)&_children);
			
			while ([(NSArray *)_children count] < 14)
			{
				NSLog(@"iTunes window children count was less than 14, looping until 14 is reached."); //item count is 14 WITH sidebar and 17 without
				AXUIElementCopyAttributeValue((AXUIElementRef)_focusedWindow, (CFStringRef)kAXChildrenAttribute, (CFTypeRef *)&_children);
			}
			
				/* 
				 
				another thought here because while investigating this issue... again.. the child item count WITH sidebar APPEARS to always be 14. so if the count is greater than 14 
				we should be able to assume that the sidebar is showing, without an appletv connected the code below creates a false positive. hence the concern.

				 
				*/
			
			AXUIElementRef splitter = (AXUIElementRef)[(NSArray *)_children objectAtIndex:13]; //if our children count is more than 1 (probably 6) we are showing sidebar
			
			AXUIElementCopyAttributeValue((AXUIElementRef)splitter, (CFStringRef)kAXChildrenAttribute, (CFTypeRef *)&_splitterChildren);
			
			if ([(NSArray *)_splitterChildren count] > 1)
			{
				NSLog(@"showing sidebar!");
			
				itunesShowingSideBar = TRUE;
			
				/*
				CFArrayRef _splitterChildren2;
				CFArrayRef _scrollViewChildren;
				CFTypeRef _role;
				AXUIElementRef splitter2 = [_splitterChildren objectAtIndex:4]; //splitter group 1 again
				AXUIElementCopyAttributeValue((AXUIElementRef)splitter2, (CFStringRef)CFSTR("AXChildren"), (CFTypeRef *)&_splitterChildren2);
				AXUIElementRef scrollView = [_splitterChildren2 objectAtIndex:0]; //scroll view 1
				AXUIElementCopyAttributeValue((AXUIElementRef)scrollView, (CFStringRef)CFSTR("AXChildren"), (CFTypeRef *)&_scrollViewChildren);
				AXUIElementRef buttonView = [_scrollViewChildren lastObject]; //AXButton?
				AXUIElementCopyAttributeValue((AXUIElementRef)buttonView,
											  (CFStringRef)CFSTR("AXRole"),
											  (CFTypeRef*)&_role);
				
				NSLog(@"know your role! %@", _role);
				 
				 */
				
					//found restore button, side bar is showing as expected
				
			} else { //not showing sidebar
				
				NSLog(@"not showing sidebar!");
				
				itunesShowingSideBar = FALSE;
				
				
				/*
				AXUIElementRef scrollView = [_splitterChildren objectAtIndex:0]; //scroll view 1
				
				
				AXUIElementCopyAttributeValue((AXUIElementRef)scrollView, (CFStringRef)CFSTR("AXChildren"), (CFTypeRef *)&_scrollViewChildren);
				
				AXUIElementRef buttonView = [_scrollViewChildren lastObject]; //AXButton?
				
				AXUIElementCopyAttributeValue((AXUIElementRef)buttonView,
											  (CFStringRef)CFSTR("AXRole"),
											  (CFTypeRef*)&_role);
				
				NSLog(@"know your role! %@", _role);
				
				 //want to figure out how to press the button here but dont know how to modify with option key
				 
				*/
			}
			
			
		}
		
	
	}	
}

- (BOOL)loadiTunes11WithIPSW:(NSString *)ipsw
{
	[self analyzeiTunes];
		//[self analyzeiTunes];
	
	
	NSDictionary *theError = nil;
	
	NSString *ipswString = [NSString stringWithFormat:@"set value of text field 1 of sheet 1 of window 1 to \"%@\"\n", ipsw];
	
	NSMutableString *asString = [[NSMutableString alloc] init];
	
	[asString appendString:@"activate application \"iTunes\"\n"];
	[asString appendString:@"tell application \"System Events\"\n"];
	[asString appendString:@"tell Process \"iTunes\"\n"];
	
		//if (![self iTunesScriptReady])
	if(itunesFullScreen == TRUE)
	{
		NSLog(@"iTunes fullscreen?");
		[asString appendString:@"delay 5\n"];
		[asString appendString:@"key code 3 using {command down, control down}\n"];
		[asString appendString:@"delay 5\n"];
		
	}
	
	[asString appendString:@"repeat until window 1 is not equal to null\n"];
	[asString appendString:@"end repeat\n"];
	[asString appendString:@"end tell\n"];
	[asString appendString:@"end tell\n"];
	
	
	[asString appendString:@"activate application \"iTunes\"\n"];
	[asString appendString:@"tell application \"System Events\"\n"];
	[asString appendString:@"tell Process \"iTunes\"\n"];
	[asString appendString:@"key down option\n"]; //holding down option for option mouse down on restore button
	
	if (itunesShowingSideBar == TRUE)
	{
		
		[asString appendString:@"click button 1 of scroll area 1 of splitter group 1 of splitter group 1 of window 1\n"];
		
	} else {
		
		[asString appendString:@"click button 1 of scroll area 1 of splitter group 1 of window 1\n"];
	}
	
	
	
		//button 1 of scroll area 1 of splitter group 1 of splitter group 1 of window 1
	[asString appendString:@"key up option\n"];
	[asString appendString:@"end tell\n"];
	[asString appendString:@"end tell\n"];
	
	[asString appendString:@"activate application \"iTunes\"\n"];
	[asString appendString:@"tell application \"System Events\"\n"];
	[asString appendString:@"tell Process \"iTunes\"\n"];
	[asString appendString:@"key code 5 using {command down, shift down}\n"];
	[asString appendString:ipswString];
		//[asString appendString:@"click button 1 of sheet 1 of window 1\n"];
	[asString appendString:@"key code 36\n"];
	
	[asString appendString:@"delay 3\n"];
	[asString appendString:@"key code 36\n"];
	[asString appendString:@"delay 5\n"];
	[asString appendString:@"key code 36\n"];
	[asString appendString:@"delay 3\n"];
		//[asString appendString:@"click button 4 of window 1\n"];
		//[asString appendString:@"click button 2 of window 1\n"];
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

	//restore button for other devices: click button 2 of scroll area 3 of window 1

- (BOOL)loadItunesWithIPSW:(NSString *)ipsw
{
	
	if ([self iTunesIsElevenPlus])
	{
		return [self loadiTunes11WithIPSW:ipsw];
	}
	
	
	
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
	
	if (![self iTunesScriptReady])
	{
		NSLog(@"iTunes fullscreen?");
		[asString appendString:@"delay 5\n"];
		[asString appendString:@"key code 3 using {command down, control down}\n"];
		[asString appendString:@"delay 5\n"];
		
	}
	
	[asString appendString:@"repeat until window 1 is not equal to null\n"];
	[asString appendString:@"end repeat\n"];
	[asString appendString:@"end tell\n"];
	[asString appendString:@"end tell\n"];
	
	/*
	 
	 we separate these instances out in an attempt to minimize pebkac errors. that is why there is multiple activate application "iTunes"\n lines, that will bring it to the 
	 front
	 
	 */
	
	/*
	 
	 there have been some reports of script failures, this is an attempt to do a repeat cycle until the AppleTV device playlist 
	 actually shows up in iTunes, it /should/ always be named "Apple TV" regardless of the users name for it
	 
	 */
	
	/*
	

	 //old version that doesn't have a timeout, susceptible to infinite loop
	 
	 [asString appendString:@"activate application \"iTunes\"\n"];
	[asString appendString:@"tell application \"iTunes\"\n"];
	[asString appendString:@"copy name of view of window 1 to the_name\n"]; //frontmost playlist of the first window
	[asString appendString:@"repeat until the_name is equal to \"Apple TV\"\n"];
	[asString appendString:@"copy name of view of window 1 to the_name\n"];
	[asString appendString:@"end repeat\n"];
	[asString appendString:@"end tell\n"];
	
	 */
	
	[asString appendString:@"tell application \"iTunes\"\n"];
	[asString appendString:@"copy name of view of window 1 to the_name\n"]; //Should be AppleTV device playlist
	[asString appendString:@"set thisTime to current date\n"]; //get the current time so we can timeout after 25 seconds of waiting
	[asString appendString:@"set dropDeadTime to thisTime + 25\n"]; //set the var for the time to die
	[asString appendString:@"try\n"];
	[asString appendString:@"repeat until the_name is equal to \"Apple TV\"\n"]; //should properly wait until the AppleTV actually pops up in iTunes
	[asString appendString:@"if (current date) > dropDeadTime then error \"Apple TV Not Found.\"\n"]; //we done waiting!!
	[asString appendString:@"copy name of view of window 1 to the_name\n"]; //copy the name to check it
	[asString appendString:@"--if (current date) > dropDeadTime then exit repeat\n"]; //alternate way that wont give error
	[asString appendString:@"end repeat\n"];
	//on error errText
	//		display dialog errText as string
	[asString appendString:@"end try\n"];
	
	[asString appendString:@"end tell\n"];
	
	
	
	/*
	 
	 okay we SHOULD have a window 1 now, AND we should have the frontmost playlist item being the Apple TV, SHOULD be okay
	 to proceed.
	 
	 */
	
	
	[asString appendString:@"activate application \"iTunes\"\n"];
	[asString appendString:@"tell application \"System Events\"\n"];
	[asString appendString:@"tell Process \"iTunes\"\n"];
	[asString appendString:@"key down option\n"];
	if ([self iTunesIsTenFourPlus] == TRUE)
	{
			//[asString appendString:@"click button \"Restore\"  of scroll area 3 of window 1\n"];
		[asString appendString:@"click button 1 of scroll area 3 of window 1\n"];
	} else {
		
			//[asString appendString:@"click button \"Restore\" of scroll area 1 of tab group 1 of window 1\n"];
		[asString appendString:@"click button 1 of scroll area 1 of tab group 1 of window 1\n"];
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

+ (NSString *)bundleNameFromLabel:(NSString *)theBundle
{
		//5.0 9B5127c
	
	NSArray *objects = [theBundle componentsSeparatedByString:@" "];
	return [NSString stringWithFormat:@"AppleTV2,1_%@_%@.bundle", [objects objectAtIndex:0], [objects objectAtIndex:1]];
}

+ (NSString *)formattedStringFromBundle:(NSString *)theBundle
{
		//AppleTV2,1_5.0_9B5127c.bundle
	
	NSArray *objects = [[theBundle stringByDeletingPathExtension] componentsSeparatedByString:@"_"];

	return [NSString stringWithFormat:@"%@ %@", [objects objectAtIndex:1], [objects objectAtIndex:2]];

	
	
}

+ (NSArray *)filteredBundleNames
{
	NSArray *betaBundles = [NSArray arrayWithObjects:@"AppleTV2,1_5.0_9B5127c.bundle", @"AppleTV2,1_5.0_9B5141a.bundle", @"AppleTV2,1_5.2_10B5105c.bundle", @"AppleTV2,1_5.2_10B5126b.bundle",  nil];
	NSMutableArray *finalArray = [[NSMutableArray alloc] init];
	
	for (id object in BUNDLES)
	{
		if (![betaBundles containsObject:object])
		{
			if ([tetherKitAppDelegate isAvailable:object])
			{
				[finalArray addObject:[tetherKitAppDelegate formattedStringFromBundle:object]];
			}
			
		}
	}
	
	NSArray *sortedBundles = [finalArray sortedArrayUsingSelector:@selector(compare:)];
	[finalArray release];
	
	return sortedBundles;
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

- (int)showDeviceAlert
{
	NSAlert *errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"No Device Detected.", @"No Device Detected.") defaultButton:NSLocalizedString(@"OK", @"OK") alternateButton:NSLocalizedString(@"Cancel", @"Cancel") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Please connect the Apple TV via USB to continue.", @"Please connect the Apple TV via USB to continue.")];
	return [errorAlert runModal];
}

- (int)showDeviceFailedAlert
{
	NSAlert *errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"No Device Detected.", @"No Device Detected.") defaultButton:NSLocalizedString(@"OK", @"OK") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Failed to detect Apple TV, please quit and re-open Seas0nPass and try again.", @"Failed to detect Apple TV, please quit and re-open Seas0nPass and try again.")];
	return [errorAlert runModal];
}

- (void)showUntetheredAlert
{
	NSAlert *errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Untethered Jailbreak", @"Untethered Jailbreak") defaultButton:NSLocalizedString(@"OK", @"OK") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The %@ firmware is untethered and does not require this process!", @"The %@ firmware is untethered and does not require this process!"), [self.currentBundle bundleName]];
	[errorAlert runModal];
}

- (BOOL)isAppleTV3
{ 
	if ([self.deviceClass isEqualToString:APPLETV_31_DEVICE_CLASS] || [self.deviceClass isEqualToString:APPLETV_32_DEVICE_CLASS])
	{
		return (TRUE);
	}
	
	return (FALSE);
}

- (IBAction)bootTethered:(id)sender
{
	if ([self isAppleTV3])
	{
		[self showIncompatDeviceAlert];
		return;
	}
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
	
	BOOL is44 = [[self currentBundle] is4point4];
	[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
	if (is44 == TRUE)
	{
		NSLog(@"new tethered boot!");
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(tetheredBootReady:) name:@"tbr" object:nil];
		[NSThread detachNewThreadSelector:@selector(newTetheredBoot) toTarget:self withObject:nil];
       // [NSThread detachNewThreadSelector:@selector(sn0wyTetheredBoot) toTarget:self withObject:nil];
    } else {
	
		NSLog(@"old tethered boot!");
		[NSThread detachNewThreadSelector:@selector(tetheredBoot) toTarget:self withObject:nil];
	}
	

}


- (IBAction)dfuMode:(id)sender
{
	[self killiTunes];
	[window setContentView:self.secondView];
	[window display];
	[NSThread detachNewThreadSelector:@selector(enterDFU) toTarget:self withObject:nil];
	
}

- (void)showIncompatDeviceAlert
{
	//This AppleTV is not eligible for this version
	
	NSAlert *errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Sorry. :-(", @"Sorry. :-(") defaultButton:NSLocalizedString(@"OK", @"OK") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"This device is not supported by Seas0nPass.", @"This device is not supported by Seas0nPass.")];
	[errorAlert runModal];
	[self showInitialView];
	return;
}

- (void)showDeviceIneligibleAlert
{
		//This AppleTV is not eligible for this version
	
	NSAlert *errorAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Sorry. :-(", @"Sorry. :-(") defaultButton:NSLocalizedString(@"OK", @"OK") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"This Apple TV is not eligible for this version.", @"This Apple TV is not eligible for this version.")];
	[errorAlert runModal];
	[self showInitialView];
	return;
}


- (NSString *)threadedBundleFirmware:(FWBundle *)theBundle
{
	NSString *theFirmwareDownload = [DL stringByAppendingPathComponent:[theBundle filename]];
	NSLog(@"theFirmwareDownload: %@", theFirmwareDownload);
	NSString *sha = [theBundle SHA];
	if ([FM fileExistsAtPath:theFirmwareDownload])
	{
		[self showProgressViewWithText:NSLocalizedString(@"Validating IPSW...", @"Validating IPSW...")];
		if([nitoUtility validateFile:theFirmwareDownload withChecksum:sha] == FALSE)
		{
			NSLog(@"failed to validate file, delete file and continue to new download");
			[FM removeItemAtPath:theFirmwareDownload error:nil];
			return nil;
		} else {
			
			NSLog(@"firmware exists, no need to download!");
			
			return theFirmwareDownload;
			
		}
	}
	
	return nil; //default to nil right?
	
}

- (NSString *)currentBundleFirmware //deprecated
{
	NSString *theFirmwareDownload = [DL stringByAppendingPathComponent:[[self currentBundle] filename]];
	NSLog(@"theFirmwareDownload: %@", theFirmwareDownload);
	NSString *sha = [[self currentBundle] SHA];
	if ([FM fileExistsAtPath:theFirmwareDownload])
	{
		[self showProgressViewWithText:NSLocalizedString(@"Validating IPSW...", @"Validating IPSW...")];
		if([nitoUtility validateFile:theFirmwareDownload withChecksum:sha] == FALSE)
		{
			NSLog(@"failed to validate file, delete file and continue to new download");
			[FM removeItemAtPath:theFirmwareDownload error:nil];
			return nil;
		} else {
			
			NSLog(@"firmware exists, no need to download!");
			
			return theFirmwareDownload;
			
		}
	}
	
	return nil; //default to nil right?
	
}

- (void)shouldDownloadFinished:(NSNotification *)n
{
	id userInfo = [n userInfo];
	NSString *theFile = [userInfo valueForKey:@"file"];
	FWBundle *ourBundle = [FWBundle bundleForFile:theFile];
	
	NSString *downloadLink = [ourBundle downloadURL];
	
	if([downloadLink length] > 2)
	{
		[downloadFiles addObject:downloadLink];
		[window setContentView:self.secondView];
		[window display];
		
		self.processing = TRUE;
		[buttonOne setEnabled:FALSE];
		[bootButton setEnabled:FALSE];
		[instructionImage setImage:[self imageForMode:kSPIPSWImage]];
		[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
		[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
		[self downloadTheFiles];
	}
	
}

- (void)shouldDownloadThreaded:(NSString *)theFile
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	FWBundle *ourBundle = [FWBundle bundleForFile:theFile];
	if (ourBundle == nil)
	{
		NSLog(@"nil bundle??: %@", theFile);
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:theFile forKey:@"file"];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"shouldDownloadFinish" object:nil userInfo:userInfo deliverImmediately:YES];
		return;
		
	}
	
	
	NSString *cbf = [self threadedBundleFirmware:ourBundle];
	if (cbf != nil)
	{
		NSLog(@"we already have the firmware, no need to download!");
		[FM removeItemAtPath:TMP_ROOT error:nil];
		[window setContentView:self.secondView];
		[window display];
		
		self.processing = TRUE;
		[buttonOne setEnabled:FALSE];
		[bootButton setEnabled:FALSE];
		[instructionImage setImage:[self imageForMode:kSPIPSWImage]];
		
		NSDictionary *customFwDict = [NSDictionary dictionaryWithObjectsAndKeys:cbf, @"file", [NSString stringWithFormat:@"%i", _restoreMode], @"restoreMode", nil];
			//[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
			//[NSThread detachNewThreadSelector:@selector(customFW:) toTarget:self withObject:customFwDict];
		[self customFW:customFwDict];
		return;
	} else {

		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:theFile forKey:@"file"];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"shouldDownloadFinish" object:nil userInfo:userInfo deliverImmediately:YES];
		
		
	}
	
	[pool release];
}

- (void)downloadBundle:(NSString *)theFile
{	
	
	NSString *bundleName = [tetherKitAppDelegate bundleNameFromLabel:theFile];
		//NSLog(@"bundleName: %@", bundleName);
	self.currentBundle = [FWBundle bundleForFile:bundleName];
		//NSLog(@"currentBundle: %@", self.currentBundle);
	
	if (self.currentBundle == nil)
	{
		NSLog(@"nil bundle, bail!!");
		return;
	}
	[[NSUserDefaults standardUserDefaults] setObject:[bundleName stringByDeletingPathExtension] forKey:@"lastUsedBundle"];
		[self showProgressViewWithText:NSLocalizedString(@"Checking firmware compatibility...",@"Checking firmware compatibility..." )];
	int theRestoreMode = [self restoreMode];
	
	[self.currentBundle setRestoreMode:theRestoreMode];
		//if (![self.deviceClass isEqualToString:APPLETV_21_DEVICE_CLASS])
	if ([self isAppleTV3])
	{
		[self hideProgress];
		[self showInitialView];
		[self showIncompatDeviceAlert];
		NSLog(@"download mode only works with AppleTV2,1 / k66ap");
		return;
		
	}
	_restoreMode = theRestoreMode;
	
	NSLog(@"restoreMode: %i", theRestoreMode);

	switch (theRestoreMode) {
			
			
		case kRestoreNoDevice: //already showed alert, just bail
			[self showInitialView];
			[self hideProgress];
			return;
			
		case kRestoreFirmwareIneligible:
			
			[self showInitialView];
			[self hideProgress];
			[self showDeviceIneligibleAlert];
			
			return;
			
			
		case kRestoreUnsupportedDevice:
			[self showInitialView];
			[self hideProgress];
			[self showIncompatDeviceAlert];
			return;
			
		default:
			
				//NSLog(@"restore mode: %i", theRestoreMode);
			break;
	}
	
	[NSThread detachNewThreadSelector:@selector(shouldDownloadThreaded:) toTarget:self withObject:bundleName];
	
	/*
	
	 fixed the lockup in two places now when validating files.
	 
	 */
	
	
	/*
	NSString *cbf = [self currentBundleFirmware];
	
		//NSLog(@"cbf: %@", cbf);
	
	if (cbf != nil)
	{
		NSLog(@"we already have the firmware, no need to download!");
		[FM removeItemAtPath:TMP_ROOT error:nil];
		[window setContentView:self.secondView];
		[window display];
		
		self.processing = TRUE;
		[buttonOne setEnabled:FALSE];
		[bootButton setEnabled:FALSE];
		[instructionImage setImage:[self imageForMode:kSPIPSWImage]];
		
		NSDictionary *customFwDict = [NSDictionary dictionaryWithObjectsAndKeys:cbf, @"file", [NSString stringWithFormat:@"%i", theRestoreMode], @"restoreMode", nil];
		[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
        [NSThread detachNewThreadSelector:@selector(customFW:) toTarget:self withObject:customFwDict];
		return;
	}
	
	NSString *downloadLink = [[self currentBundle] downloadURL];
	
		if([downloadLink length] > 2)
		{
			[downloadFiles addObject:downloadLink];
			[window setContentView:self.secondView];
			[window display];
			
			self.processing = TRUE;
			[buttonOne setEnabled:FALSE];
			[bootButton setEnabled:FALSE];
			[instructionImage setImage:[self imageForMode:kSPIPSWImage]];
			[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
			[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
			[self downloadTheFiles];
		}
	 */
}

- (void)downloadTheFiles
{
	//LOG_SELF;
	NSString *currentDownload = [downloadFiles objectAtIndex:downloadIndex];
	NSString *ptFile = [DL stringByAppendingPathComponent:[currentDownload lastPathComponent]];
	[self setDownloadText:[NSString stringWithFormat:NSLocalizedString(@"Downloading %@...",@"Downloading %@..."), [currentDownload lastPathComponent]]];
	downloadFile = [[ripURL alloc] init];
	[downloadFile setHandler:self];
	[downloadFile setDownloadLocation:ptFile];
	[downloadFile downloadFile:currentDownload];
	downloadIndex = 1;
	
}



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

	//FIXME: the last place i need to make sure we properly thread when validating the file to prevent UI lockup

- (void)threadedDownloadFinished:(NSString *)adownloadFile
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *sha = [[self currentBundle] SHA];
	[self showProgressViewWithText:NSLocalizedString(@"Validating IPSW...", @"Validating IPSW...")];
	if ([nitoUtility validateFile:adownloadFile withChecksum:sha] == FALSE)
	{
		if (_downloadRetries > 0)
		{
			NSLog(@"already tried to redownload, still corrupt, bail!");
			[self setDownloadText:NSLocalizedString(@"Firmware download corrupt upon two tries, failed!",@"Firmware download corrupt upon two tries, failed!") ];
			[self hideProgress];
			_downloadRetries = 0;
			[pool release];
			return;
			
		} else { //we downloaded once, and it was corrupt, trying again.
			
			self.downloadIndex = 0;
			NSLog(@"download corrupt on first try, trying once more!");
			[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
			[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:adownloadFile forKey:@"file"];
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"shouldDownloadFinish" object:nil userInfo:userInfo deliverImmediately:YES];
				//[self downloadTheFiles];
			_downloadRetries++;
			return;
		}
		
	}
	_downloadRetries = 0;
	
	[FM removeItemAtPath:TMP_ROOT error:nil];
	NSLog(@"download complete: %@", adownloadFile);
	[downloadBar stopAnimation:self];
	[downloadBar setHidden:YES];
	[downloadBar setNeedsDisplay:YES];
	[downloadFile release];
	downloadFile = nil;
	if (downloadIndex == 1)
	{
		
		
		[self setDownloadText:NSLocalizedString(@"Downloads complete", @"Downloads complete")];
		NSLog(@"downloads complete!!");
		[self setDownloadProgress:0];
		NSLog(@"_restoreMode: %i", _restoreMode);
		NSDictionary *customFwDict = [NSDictionary dictionaryWithObjectsAndKeys:adownloadFile, @"file", [NSString stringWithFormat:@"%i", _restoreMode], @"restoreMode", nil];
			//	[NSThread detachNewThreadSelector:@selector(customFW:) toTarget:self withObject:customFwDict];
		[self customFW:customFwDict];
		
	}
	
	[pool release];
}

- (void)downloadFinished:(NSString *)adownloadFile
{
	[NSThread detachNewThreadSelector:@selector(threadedDownloadFinished:) toTarget:self withObject:adownloadFile];
	return;
	
	NSString *sha = [[self currentBundle] SHA];
	[self showProgressViewWithText:NSLocalizedString(@"Validating IPSW...", @"Validating IPSW...")];
	if ([nitoUtility validateFile:adownloadFile withChecksum:sha] == FALSE)
	{
		if (_downloadRetries > 0)
		{
			NSLog(@"already tried to redownload, still corrupt, bail!");
			[self setDownloadText:NSLocalizedString(@"Firmware download corrupt upon two tries, failed!",@"Firmware download corrupt upon two tries, failed!") ];
			[self hideProgress];
			_downloadRetries = 0;
			return;
			
		} else { //we downloaded once, and it was corrupt, trying again.
			
			self.downloadIndex = 0;
			NSLog(@"download corrupt on first try, trying once more!");
			[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
			[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
			[self downloadTheFiles];
			_downloadRetries++;
			return;
		}

	}
	_downloadRetries = 0;
	
	[FM removeItemAtPath:TMP_ROOT error:nil];
		NSLog(@"download complete: %@", adownloadFile);
	[downloadBar stopAnimation:self];
	[downloadBar setHidden:YES];
	[downloadBar setNeedsDisplay:YES];
	[downloadFile release];
	downloadFile = nil;
	if (downloadIndex == 1)
	{
		
		
		[self setDownloadText:NSLocalizedString(@"Downloads complete", @"Downloads complete")];
		 NSLog(@"downloads complete!!");
		[self setDownloadProgress:0];
		NSLog(@"_restoreMode: %i", _restoreMode);
		NSDictionary *customFwDict = [NSDictionary dictionaryWithObjectsAndKeys:adownloadFile, @"file", [NSString stringWithFormat:@"%i", _restoreMode], @"restoreMode", nil];
		[NSThread detachNewThreadSelector:@selector(customFW:) toTarget:self withObject:customFwDict];
		
		
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



- (int)performSupportBundlePatches:(FWBundle *)theBundle //pretty much never used.
{
    int status = 0;
	if ([theBundle sbkernel] != nil)
	{
        NSLog(@"decryptedPatchFromData: %@ atRoot: %@ fromBundle: %@", [theBundle sbkernel], [theBundle localBundlePath], [theBundle bundlePath]);
		status = [nitoUtility decryptedPatchFromData:[theBundle sbkernel] atRoot:[theBundle localBundlePath] fromBundle:[theBundle bundlePath]];
        

    }
    
    return status;
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
	
	if ([theBundle iBEC] != nil)
	{
		status = [nitoUtility decryptedPatchFromData:[theBundle iBEC] atRoot:[theBundle fwRoot] fromBundle:[theBundle bundlePath]];
		if (status == 0)
		{
			NSLog(@"patched iBEC successfully!");
		} else {
			NSLog(@"iBEC patch failed!");
			return -1;
		}
	}
	
	if ([theBundle kernelcache] != nil)
	{
		status = [nitoUtility decryptedPatchFromData:[theBundle kernelcache] atRoot:[theBundle fwRoot] fromBundle:[theBundle bundlePath]];
		if (status == 0)
		{
			NSLog(@"patched kernelcache successfully!");
		} else {
			NSLog(@"kernelcache patch failed!");
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
		status = [nitoUtil performPatchesFromBundle:theBundle onRamdisk:[theBundle restoreRamdisk]];

		
	}
	
	return status;
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

- (void)checksumFinished:(NSNotification *)n
{
	NSLog(@"checksumFinished: %@", n);
	
	int status = [[[n userInfo] objectForKey:@"status"] intValue];
	
	NSString *ipsw = [[n userInfo] objectForKey:@"file"];
	
	NSLog(@"ipsw: %@ status: %i", ipsw, status);
	
	FWBundle *ourBundle = [FWBundle bundleForFile:ipsw];
	NSString *downloadLink = [ourBundle downloadURL];
	
	if (status == 0)
	{
		NSLog(@"checksum failed!, do somethin!");
		NSLog(@"invalid file: %@, redownloading...", ipsw);
		if([downloadLink length] > 2)
		{
			[downloadFiles addObject:downloadLink];
			[window setContentView:self.secondView];
			[window display];
			
			self.processing = TRUE;
			[buttonOne setEnabled:FALSE];
			[bootButton setEnabled:FALSE];
			[instructionImage setImage:[self imageForMode:kSPIPSWImage]];
			[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
			[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
			[self downloadTheFiles];
		}
		return;
		
	} else {
		
		[self showProgressViewWithText:NSLocalizedString(@"Checking firmware compatibility...",@"Checking firmware compatibility..." )];
		int theRestoreMode = [self restoreMode];
		_restoreMode = theRestoreMode;
		[self.currentBundle setRestoreMode:theRestoreMode];
		NSLog(@"restoreMode: %i", theRestoreMode);
		id object = nil;
		switch (theRestoreMode) {
				
			case -1:
			case kRestoreUnavailableMode: //shouldn't get this anymore. deprecated
				NSLog(@"bailing!!!!");
				object = [NSAlert alertWithMessageText:NSLocalizedString(@"Unspecified Error", @"Unspecified Error") defaultButton:NSLocalizedString(@"OK", @"OK") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The firmware %@ is either not being signed by Apple anymore, not backed up to cydia, or the device cannot be detected: kRestoreUnavailableMode.", @"The firmware %@ is either not being signed by Apple anymore, not backed up to cydia, or the device cannot be detected: kRestoreUnavailableMode."), [ipsw lastPathComponent]];
				[object runModal];
				return;
				
			case kRestoreNoDevice: //already showed alert, just bail
				[self showInitialView];
				[self hideProgress];
				return;
				
				
			case kRestoreFirmwareIneligible:
				[self showInitialView];
				[self hideProgress];
				[self showDeviceIneligibleAlert];
				return;
				
				
			case kRestoreUnsupportedDevice:
				[self showInitialView];
				[self hideProgress];
				[self showIncompatDeviceAlert];
				
				return;
				
			default:
				break;
		}
		
		
		
		NSLog(@"Seas0nPass: Software payload: %@ (option key)", [self.currentBundle bundleName]);
		
		[window setContentView:self.secondView];
		[window display];
		
		self.processing = TRUE;
		[buttonOne setEnabled:FALSE];
		[bootButton setEnabled:FALSE];
		[instructionImage setImage:[self imageForMode:kSPIPSWImage]];
		
		NSDictionary *customFwDict = [NSDictionary dictionaryWithObjectsAndKeys:ipsw, @"file", [NSString stringWithFormat:@"%i", theRestoreMode], @"restoreMode", nil];
		[self performSelectorOnMainThread:@selector(showProgress) withObject:nil waitUntilDone:YES];
        [NSThread detachNewThreadSelector:@selector(customFW:) toTarget:self withObject:customFwDict];
		return;
		
	}

		//	[self setDownloadText:[userI valueForKey:@"Status"]];
	
}

- (BOOL)pwnHelperCheckOwner
{	
	
	NSString *helperPath = [[NSBundle mainBundle] pathForResource: @"dbHelper" ofType: @""];
	NSFileManager *man = [NSFileManager defaultManager];
    NSDictionary *attrs = [man attributesOfItemAtPath:helperPath error:nil];
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
		
			//OSStatus myStatus = AuthorizationCreate (NULL, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
		AuthorizationCreate (NULL, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
		
	//	NSString *helpPath = [[NSBundle mainBundle] pathForResource: @"dHelper" ofType: @""];
		
		
		//char *systemCopier = ( char * ) [helpPath fileSystemRepresentation];
		
		
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
