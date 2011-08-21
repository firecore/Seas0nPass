/*
 ### EDITING HWAppliance.h
 add our header files (we haven’t created HWBasicMenu yet, but add it anyway) the BackRowExtras.h is used to easily grab private variables through nlist / mobilesubstrate
 */

#import "BackRowExtras.h"
/*
 we use this code to grab a _productImage variable from a BRTopShelf view, this is still a throwback from 4-5 months ago when we first delved into frappliance development for the AppleTV 2G, there /should/ be a more elegant way to do this and probably is, for now you have to live with this  , by having access to the “productImage” variable we can use our own when overriding topShelfView in our HWTopShelfController we have the interface and implementation of HWTopShelfController in our Appliance header because its such a short section of code that it would be ridiculous to make ONE more header file or header / implementation file combo for this tiny amount of code
 */
@interface BRTopShelfView (specialAdditions)
- (BRImageControl *)productImage;
@end
@implementation BRTopShelfView (specialAdditions)
- (BRImageControl *)productImage
{
	return MSHookIvar<BRImageControl *>(self, "_productImage"); //gimme that private var!!
}
@end
@interface SPTopShelfController : NSObject {
}
- (void)refresh; //4.2.1
- (void)selectCategoryWithIdentifier:(id)identifier;
- (id)topShelfView;
@end
@implementation SPTopShelfController
-(void)refresh
{
		//needed for 4.2.1 compat to keep AppleTV.app from endless reboot cycle
}
- (void)selectCategoryWithIdentifier:(id)identifier {
	
		//leave this entirely empty for controllerForIdentifier:args to work in Appliance subclass
}
- (BRTopShelfView *)topShelfView {
	
	BRTopShelfView *topShelf = [[BRTopShelfView alloc] init];
	BRImageControl *imageControl = [topShelf productImage]; //this is why we need MSHookIvar to hook the private variable
	BRImage *theImage = [BRImage imageWithPath:[[NSBundle bundleForClass:[SPTopShelfController class]] pathForResource:@"sp" ofType:@"png"]]; // roll your own
															//BRImage *theImage = [[BRThemeInfo sharedTheme] largeGeniusIconWithReflection];
	[imageControl setImage:theImage];
	
	return topShelf;
}
@end
@interface SPAppliance: BRBaseAppliance { //your interface class name may be different!!
	SPTopShelfController *_topShelfController;
	NSArray *_applianceCategories;
}
@property(nonatomic, readonly, retain) id topShelfController;
@end