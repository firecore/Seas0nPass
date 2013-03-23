%hook BRMainMenuControl

@class BRImageControl, BRImage;

-(void)_reload
{
    	%orig;
	NSString *spImagePath = @"/var/mobile/Media/Photos/seas0nTV.png";
	NSFileManager *man = [NSFileManager defaultManager];
	if ([man fileExistsAtPath:spImagePath])
	{
		NSLog(@"no cure for stupid!!!");
		id img = MSHookIvar<id>(self,"_logo"); //BRImageControl
		[img setImage:[%c(BRImage) imageWithPath:spImagePath]];
	}  
}

%end

%hook ATVMainMenuController

//@class BRImage, BRMainMenuImageControl, ATVVersionInfo;
		
- (id)_imageForAppliance:(id)appliance
{
	NSString *versionNumber = [%c(ATVVersionInfo) currentOSVersion];
	NSComparisonResult theResult = [versionNumber compare:@"5.1" options:NSNumericSearch];
	float currentVersion = [[%c(ATVVersionInfo) currentOSVersion] floatValue];
//	NSString *spFile = @"/var/mobile/Media/Photos/spicon.png";
	NSString *spFile = @"/var/mobile/Library/Preferences/spicon.png";
	NSFileManager *man = [NSFileManager defaultManager];
	if ( theResult == NSOrderedAscending ){ return %orig; }

		if (![man fileExistsAtPath:spFile]){ return %orig; }

		NSString *applianceName = [[appliance applianceInfo] key];
		if ([applianceName isEqualToString:@"com.apple.frontrow.appliance.settings"])
		{
			return [%c(BRImage) imageWithPath:spFile];
		}
		
		return %orig;
	}



%end
