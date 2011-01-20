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

enum  {
	kSPATVRestoreImage,
	kSPATVTetheredImage,
	kSPATVTetheredRemoteImage,
	kSPSuccessImage,
	kSPIPSWImage,
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
	
	
}
@property (assign) IBOutlet NSArrayController *bundleController;
@property (assign) FWBundle *currentBundle;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView	*firstView;
@property (assign) IBOutlet NSView	*secondView;
@property (readwrite, assign) BOOL processing;
@property (readwrite, assign) BOOL poisoning;
@property (readwrite, assign) BOOL enableScripting;
@property (readwrite, assign) int downloadIndex;

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
- (void)downloadFiles;
- (int)tetheredBoot;
- (IBAction)bootTethered:(id)sender;
- (IBAction)dfuMode:(id)sender;
- (BOOL)loadItunesWithIPSW:(NSString *)ipswString;
- (IBAction)itunesRestore:(id)sender;
- (void)setInstructionText:(NSString *)instructions;
- (NSImage *)imageForMode:(int)inputMode;
- (NSString *)ipswOutputPath;
@end
