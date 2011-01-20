//
//  SPButton.m
//  tetherKit
//
//  Created by Kevin Bradley on 1/18/11.
//  Copyright 2011 FireCore, LLC. All rights reserved.
//

#import "SPButton.h"
#import "tetherKitAppDelegate.h"

@implementation SPButton

- (void)mouseDown:(NSEvent *)theEvent
{
		//NSLog(@"mouseDown: %i", [theEvent modifierFlags]);
	if ([theEvent modifierFlags] == 262401){
		[self showMenu];

	}
	[super mouseDown:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
		//NSLog(@"rightMouseDown: %@", theEvent);
	[self showMenu];
	return [super rightMouseDown:theEvent];
}

- (IBAction)add:(id)sender
{
		//NSLog(@"add: %@", [sender title]);
	[[NSUserDefaults standardUserDefaults] setObject:[sender title] forKey:@"lastUsedBundle"];
	[[NSApp delegate] bootTethered:nil];
	
}


- (void)showMenu
{
	NSGraphicsContext *theContext = [[self window] graphicsContext];
	NSUInteger windowNumber = [[self window] windowNumber];
	NSRect frame = [(NSButton *)self frame];
    NSPoint menuOrigin = [[(NSButton *)self superview] convertPoint:NSMakePoint(frame.origin.x+10, frame.origin.y)
                                                               toView:nil];
	
    NSEvent *event =  [NSEvent mouseEventWithType:NSRightMouseDown
                                         location:menuOrigin
                                    modifierFlags:NSRightMouseDownMask // 0x100
                                        timestamp:0
                                     windowNumber:windowNumber
                                          context:theContext
                                      eventNumber:0
                                       clickCount:1
                                         pressure:1];
	
	NSArray *appBundles = [tetherKitAppDelegate appSupportBundles];
		//NSLog(@"appBundles: %@", appBundles);
	NSEnumerator *bundleEnum = [appBundles objectEnumerator];
	id currentObject = nil;
	int i = 0;
    NSMenu *menu = [[NSMenu alloc] init];
    
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
