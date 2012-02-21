//
//  SPFWButton.m
//  tetherKit
//
//  Created by Kevin Bradley on 1/18/11.
//  Copyright 2011 FireCore, LLC. All rights reserved.
//

#import "SPFWButton.h"
#import "tetherKitAppDelegate.h"

@implementation SPFWButton

- (void)mouseDown:(NSEvent *)theEvent
{
		//NSLog(@"mouseDown: %i", [theEvent modifierFlags]);
	if ([theEvent modifierFlags] == 262401){
		NSPoint locationInWindow = [theEvent locationInWindow];
		[self showMenu:locationInWindow];

	}
	[super mouseDown:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
		//NSLog(@"rightMouseDown: %@", theEvent);
	NSPoint locationInWindow = [theEvent locationInWindow];
		//NSLog(@"nsPoint: %@", NSStringFromPoint(locationInWindow));
	[self showMenu:locationInWindow];
	return [super rightMouseDown:theEvent];
}

- (IBAction)restoreLatest:(id)sender
{
	[[NSApp delegate] itunesRestore:sender];
}

- (IBAction)add:(id)sender
{
		//NSLog(@"add: %@", [sender title]);
		//[[NSUserDefaults standardUserDefaults] setObject:[sender title] forKey:@"lastUsedBundle"];
	[[NSApp delegate] downloadBundle:[sender title]];
	
}


- (void)showMenu:(NSPoint)thePoint
{
	NSGraphicsContext *theContext = [[self window] graphicsContext];
	NSUInteger windowNumber = [[self window] windowNumber];
		//NSRect frame = [(NSButton *)self frame];
		// NSPoint menuOrigin = [[(NSButton *)self superview] convertPoint:NSMakePoint(frame.origin.x+10, frame.origin.y+20) toView:nil];
	
	
    NSEvent *event =  [NSEvent mouseEventWithType:NSRightMouseDown
                                         location:thePoint
                                    modifierFlags:NSRightMouseDownMask // 0x100
                                        timestamp:0
                                     windowNumber:windowNumber
                                          context:theContext
                                      eventNumber:0
                                       clickCount:1
                                         pressure:1];
	
	NSArray *appBundles = [tetherKitAppDelegate filteredBundleNames];
		//NSLog(@"appBundles: %@", appBundles);
	NSEnumerator *bundleEnum = [appBundles objectEnumerator];
	id currentObject = nil;
	int i = 2;
    NSMenu *menu = [[NSMenu alloc] init];
    
		NSMenuItem *restoreLatest = [[NSMenuItem alloc] initWithTitle:@"Restore latest version in iTunes" action:@selector(restoreLatest:) keyEquivalent:@""];
	
	BOOL hasFirmware = [nitoUtility hasFirmware];
	if (hasFirmware == TRUE)
	{
			//	NSLog(@"has firmware!!!!!");
	} else {
		
		[restoreLatest setEnabled:FALSE];
		[restoreLatest setAction:nil];
	}
	

	
	[menu insertItem:[restoreLatest autorelease] atIndex:0];
		//[restoreLatest setEnabled:hasFirmware];
		//[menu insertItemWithTitle:@"Restore latest version in iTunes" action:@selector(restoreLatest:) keyEquivalent:@"" atIndex:0];
	
	
	NSMenuItem *dividerItem = [NSMenuItem separatorItem];
	
	[menu insertItem:dividerItem atIndex:1];
	
	
	while (currentObject = [bundleEnum nextObject])
	{
			//	NSLog(@"addObject: %@", currentObject);
		[menu insertItemWithTitle:currentObject
						   action:@selector(add:)
					keyEquivalent:@""
						  atIndex:i];
		i++;
	}
	
	
    [NSMenu popUpContextMenu:[menu autorelease] withEvent:event forView:(NSButton *)self];
}

@end
