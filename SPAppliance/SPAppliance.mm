
#import "SPAppliance.h"
#import "SPOptionDialog.h"

#define SP_ID @"SP_MM"
#define SP_CAT [BRApplianceCategory categoryWithName:BRLocalizedString(@"More Info", @"More Info") identifier:SP_ID preferredOrder:0]


@implementation SPAppliance


@synthesize topShelfController = _topShelfController;

- (id)init {
	if((self = [super init]) != nil) {
		_topShelfController = [[SPTopShelfController alloc] init];
		
		_applianceCategories = [[NSArray alloc] initWithObjects:SP_CAT,nil];
		
	} return self;
}

- (id)controllerForIdentifier:(id)identifier args:(id)args
{
	id menuController = nil;
	
	if ([identifier isEqualToString:SP_ID])
	{
		
		menuController = [[SPOptionDialog alloc] init];
		[menuController setTitle:BRLocalizedString(@"Jailbreak Successful", @"Jailbreak Successful")];
		[menuController addOptionText:BRLocalizedString(@"Go Back", @"Go Back")];
		[menuController addOptionText:BRLocalizedString(@"Hide Menu", @"Hide Menu")];
		[menuController setPrimaryInfo:BRLocalizedString(@"Your AppleTV has been successfully jailbroken with Seas0nPass!", @"Your AppleTV has been successfully jailbroken with Seas0nPass!")];
		[menuController setSecondaryInfo:BRLocalizedString(@"aTV Flash (black) or other 3rd party plugins can now be installed.", @"aTV Flash (black) or other 3rd party plugins can now be installed.")];
			
		
	}
	
	return menuController;
	
}
- (id)applianceCategories {
	return _applianceCategories;
}
@end



