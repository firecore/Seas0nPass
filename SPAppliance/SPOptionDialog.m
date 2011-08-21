//
//  SPOptionDialog.m
//  maintenance
//
//  Created by Kevin Bradley on 7/11/10.
//  Copyright 2010 nito, LLC. All rights reserved.
//


#import "SPOptionDialog.h"

@implementation SPOptionDialog

@synthesize primaryInfo, secondaryInfo;

- (id) init
{
    if ( [super init] == nil )
        return ( nil );
	
	

	
    return ( self );
}

- (int)getSelection
{
	BRListControl *list = [self list];
	int row;
	NSMethodSignature *signature = [list methodSignatureForSelector:@selector(selection)];
	NSInvocation *selInv = [NSInvocation invocationWithMethodSignature:signature];
	[selInv setSelector:@selector(selection)];
	[selInv invokeWithTarget:list];
	if([signature methodReturnLength] == 8)
	{
		double retDoub = 0;
		[selInv getReturnValue:&retDoub];
		row = retDoub;
	}
	else
		[selInv getReturnValue:&row];
	return row;
}

-(BOOL)brEventAction:(id)action
{
		//NSLog(@"%@", action);
	int select = [self getSelection];
	switch ([action remoteAction]) {
			
		case 5: //play
			
			[self itemSelected:select];
			return YES;
	}
	
	return [super brEventAction:action];
}


- (BOOL)_itemSelected:(id)selected
{
	
		//NSLog(@"_itemSelected: %@", selected);
	
	
	return NO;
	
}

- (void)itemSelected:(long)selected
{
		//NSLog(@"itemSelected: %i", selected);
	
	switch (selected) {
			
		case 0: //go back
			[BRSoundHandler playSound:1];
			[[self stack] popController];
			
			break;
			
		case 1: //remove menu
			[BRSoundHandler playSound:1];
			[self removePlugin];
			
			break;
	
		
	
	}
	
}

- (void)removePlugin
{
	NSString *command = @"/usr/bin/SPHelper remove com.firecore.seas0npass";
	int sysReturn = system([command UTF8String]);
		//NSLog(@"command: %@, return status: %i", command, sysReturn);
	[[BRApplication sharedApplication] terminate];
}

- (void)dealloc
{
	[primaryInfo release];
	[secondaryInfo release];

	[super dealloc];
}


- (NSString *)stringFromCGRect:(CGRect)inputRect
{
	return [NSString stringWithFormat:@"{{%.0f, %.0f}, {%.0f, %.0f}}", inputRect.origin.x, inputRect.origin.y, inputRect.size.width, inputRect.size.height];
	
		//{{0, 0}, {320, 480}}
}


- (void)layoutSubcontrols
{
	[super layoutSubcontrols];
	[self drawSelf];
	
	
}

- (void)drawSelf
{
	id list = [self list];
	
	
	CGRect listFrame = [list frame];
	
	listFrame.origin.y = -88;
	
	[[self list] setFrame:listFrame];

	CGRect master = [self frame];

	float maxHeight = master.size.height;
	float stfHeight = maxHeight * .15;
	
	secondInfoText = [[BRTextControl alloc] init];
	primaryInfoText = [[BRTextControl alloc] init];
	
	[self addControl:primaryInfoText];
	[self addControl:secondInfoText];
	
	[primaryInfoText setText:self.primaryInfo withAttributes:[[BRThemeInfo sharedTheme] menuItemTextAttributes]];
	[secondInfoText setText:self.secondaryInfo withAttributes:[[BRThemeInfo sharedTheme] promptTextAttributes]];
	
	[secondInfoText release];
	[primaryInfoText release];
	
	
    CGRect primaryTextFrame, secondaryTextFrame;

	primaryTextFrame.size = [primaryInfoText renderedSize];
	
	float ptfOriginX = (master.size.width - primaryTextFrame.size.width)/2;
	
    primaryTextFrame.origin.y =  master.size.height * 0.78f;
	primaryTextFrame.origin.x = ptfOriginX;
	[primaryInfoText setFrame: primaryTextFrame];
	
	
	secondaryTextFrame.size = [secondInfoText renderedSize];
	
	float stfWidth = master.size.width * .70;
	float stfOriginX = (master.size.width - stfWidth)/2;
	
	
	secondaryTextFrame.size.width = stfWidth;
	secondaryTextFrame.size.height = stfHeight;
	secondaryTextFrame.origin.y = primaryTextFrame.origin.y - (primaryTextFrame.size.height +secondaryTextFrame.size.height);
	secondaryTextFrame.origin.x = stfOriginX;
	

	[secondInfoText setFrame: secondaryTextFrame];

	
	
	
	
}




@end
