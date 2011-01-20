//
//  SPMenuItem.m
//  tetherKit
//
//  Created by Kevin Bradley on 1/19/11.
//  Copyright 2011 FireCore, LLC. All rights reserved.
//

#import "SPMenuItem.h"
#import "tetherKitAppDelegate.h"

@implementation SPMenuItem

- (IBAction)add:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setObject:[sender title] forKey:@"lastUsedBundle"];
	[[NSApp delegate] itunesRestore:nil];
}

- (BOOL)hasSubmenu
{
	return YES;
}



- (NSMenu *)submenu
{

	NSMenu *theMenu = [[NSMenu alloc] init];
	[theMenu setAutoenablesItems:YES];
	NSArray *appBundles = [tetherKitAppDelegate appSupportBundles];
		//NSLog(@"appBundles: %@", appBundles);
	NSEnumerator *bundleEnum = [appBundles objectEnumerator];
	id currentObject = nil;
    
	while (currentObject = [bundleEnum nextObject])
	{
		NSMenuItem *theItem = [[NSMenuItem alloc] initWithTitle:currentObject action:@selector(add:) keyEquivalent:@""];
		[theItem setTarget:self];
		[theMenu addItem:[theItem autorelease]];

		
	}
	
	return theMenu;
}

@end
