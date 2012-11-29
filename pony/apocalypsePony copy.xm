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
	NSString *spFile = @"/var/mobile/Media/Photos/spicon.png";
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

%hook SETTINGSTopShelfController

	@class BRImage, BRMainMenuImageControl, ATVVersionInfo;
	
	
	
	- (id)topShelfView
	{
		//this is deprecated
		
		return %orig;
		
		
	//	%log;
		NSString *versionNumber = [ATVVersionInfo currentOSVersion];
		NSComparisonResult theResult = [versionNumber compare:@"5.1" options:NSNumericSearch];
		float currentVersion = [[ATVVersionInfo currentOSVersion] floatValue];
		NSString *spFile = @"/var/mobile/Media/Photos/sp.png";
		NSFileManager *man = [NSFileManager defaultManager];
		if ( theResult == NSOrderedAscending )
			{ 
				return %orig;
		 }
			
		if (![man fileExistsAtPath:spFile])
			{ 
			 return %orig; 
			}

//if neither of the above are true we are replacing the icon with ours of the settings frappliance.
			
		id topShelf = %orig; //get the original and just modify that
		id mainMenuImage = [[topShelf controls] lastObject]; //BRMainMenuImageControl
		id imageControl = [[mainMenuImage controls] lastObject]; //BRImageControl
		id myImage = [BRImage imageWithPath:spFile];
		[imageControl setImage:myImage];
		return topShelf;

	}



	%end