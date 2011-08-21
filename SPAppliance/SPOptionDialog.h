//
//  SPOptionDialog.h
//  maintenance
//
//  Created by kevin bradley on 7/11/10.
//  Copyright 2010 nito, LLC. All rights reserved.
//



@class BRHeaderControl, BRTextControl, BRController, BRControl, CALayer,BRImageControl;

@interface SPOptionDialog : BROptionDialog {
	

	BRTextControl *primaryInfoText;
	BRTextControl *secondInfoText;
	
	NSString *primaryInfo;
	NSString *secondaryInfo;


}

@property (nonatomic, retain) NSString *primaryInfo;
@property (nonatomic, retain) NSString *secondaryInfo;

- (void)removePlugin;
- (void)drawSelf;
@end
