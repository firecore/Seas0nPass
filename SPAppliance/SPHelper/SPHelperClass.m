

#import "SPHelperClass.h"



@implementation SPHelperClass



- (int)removePackage:(NSString *)packageId
{
	
	NSString *removeString = [NSString stringWithFormat:@"/usr/bin/apt-get -y --force-yes remove %@ 2>&1", packageId];
	int sysReturn = system([removeString UTF8String]);
		//NSLog(@"remove %@ returned with %i", installString, sysReturn);
	return sysReturn;
	
}




@end
