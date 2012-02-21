//
//  tetherKitAppDelegate.h
//  Seas0nPass
//
//  Created by Kevin Bradley on 12/27/10.
//  Copyright 2011 Fire Core, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ripURL.h"
#import "FWBundle.h"
#import <Carbon/Carbon.h>
#import "SPButton.h"
#import "SPMenuItem.h"
#import "nitoUtility.h"

enum  {
	kSPATVRestoreImage,
	kSPATVTetheredImage,
	kSPATVTetheredRemoteImage,
	kSPSuccessImage,
	kSPIPSWImage,
	kSPATVUntetheredImage,
};

enum {
	
	kSPStandardMode,
	kSPCydiaSigningMode,
	kSPStitchSigningMode,
};



@interface tetherKitAppDelegate : NSObject <ripURLDelegate> {
    NSWindow *window;
	IBOutlet NSProgressIndicator *downloadBar;
	IBOutlet NSTextField *downloadProgressField;
	IBOutlet NSTextField *instructionField;
	IBOutlet NSImageView *instructionImage;
	IBOutlet NSButton *buttonOne;
	IBOutlet NSButton *cancelButton;
	IBOutlet SPButton *bootButton;
	IBOutlet NSWindow *otherWindow;
	NSMutableArray *downloadFiles;
	int downloadIndex;
	BOOL processing;
	BOOL enableScripting;
	IBOutlet NSView *firstView;
	IBOutlet NSView *secondView;
	ripURL *downloadFile;
	BOOL poisoning;
	FWBundle *currentBundle;
	IBOutlet NSArrayController *bundleController;
	IBOutlet NSTextField *commandTextField;
	IBOutlet NSTextField *countdownField;
	int counter;
	IBOutlet NSTextField *tetherLabel;
	NSString *theEcid;
	int runMode;
	int _restoreMode;
	int _downloadRetries;
	
}
@property (nonatomic, retain) NSString *theEcid;
@property (assign) IBOutlet NSTextField *commandTextField;
@property (assign) IBOutlet NSTextField *countdownField;
@property (assign) IBOutlet NSTextField *tetherLabel;
@property (assign) IBOutlet NSArrayController *bundleController;
@property (assign) FWBundle *currentBundle;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *otherWindow;
@property (assign) IBOutlet NSView	*firstView;
@property (assign) IBOutlet NSView	*secondView;
@property (readwrite, assign) int runMode;
@property (readwrite, assign) BOOL processing;
@property (readwrite, assign) BOOL poisoning;
@property (readwrite, assign) BOOL enableScripting;
@property (readwrite, assign) int downloadIndex;
@property (readwrite, assign) int counter;

+ (NSArray *)filteredBundleNames;
- (void)downloadBundle:(NSString *)theFile;
- (BOOL)isFullScreen:(NSSize)theSize;
- (void)updateManifestFile:(NSString *)manifest;
+ (NSString *)bundleNameFromLabel:(NSString *)theBundle;
+ (NSString *)formattedStringFromBundle:(NSString *)theBundle;
- (NSData *)hexFileSize:(NSString *)inputFile;
- (BOOL)signFile:(NSString *)inputFile withBlob:(NSData *)blobData;
- (void)fetchBlobs:(NSString *)myEcid;
- (int)showDeviceAlert;
- (int)showDeviceFailedAlert;
- (void)showDeviceIneligibleAlert;
- (void)downloadTheFiles;
- (int)performFirmwarePatches:(FWBundle *)theBundle withUtility:(nitoUtility *)nitoUtil;
- (NSString *)buildVersion;
- (IBAction)showHelpLog:(id)sender;
- (IBAction)versionChanged:(id)sender;
- (IBAction)poison:(id)sender;
	//- (IBAction)startCountdown:(id)sender;
	//- (void)firstTimer:(NSTimer *)timer;
- (BOOL) optionKeyIsDown;
+ (NSString *)applicationSupportFolder;
+ (NSString *)wifiFile;
- (IBAction)fixScript:(id)sender;
- (void)killiTunes;
- (void)checkScripting;
- (BOOL)scriptingEnabled;
- (BOOL)loadItunesWithIPSW:(NSString *)ipsw;
- (BOOL)pwnHelperCheckOwner;
- (void)setDownloadProgress:(double)theProgress;
- (void)setDownloadText:(NSString *)downloadString;
- (IBAction)processOne:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)userGuides:(id)sender;
+ (NSString *)downloadLocation;
- (int)tetheredBoot;
- (IBAction)bootTethered:(id)sender;
- (IBAction)dfuMode:(id)sender;
- (BOOL)loadItunesWithIPSW:(NSString *)ipswString;
- (IBAction)itunesRestore:(id)sender;
- (void)setInstructionText:(NSString *)instructions;
- (NSImage *)imageForMode:(int)inputMode;
- (NSString *)ipswOutputPath;
- (void)createSupportBundleWithCache:(NSString *)theCache iBSS:(NSString *)iBSS iBEC:(NSString *)iBEC;
- (int)performSupportBundlePatches:(FWBundle *)theBundle;
- (BOOL)homeWritable;
+ (NSArray *)appSupportBundles;
@end
