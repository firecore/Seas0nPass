

#import <Foundation/Foundation.h>
#include <sys/types.h>
#include <unistd.h>
#import "SPHelperClass.h"


int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	setuid(0);
	int i;
	for (i = 1; i < (argc - 1); i+= 2){
		
		NSString *path = [NSString stringWithUTF8String:argv[0]];
		NSString *option = [NSString stringWithUTF8String:argv[i]];
		NSString *value = [NSString stringWithUTF8String:argv[i+1]];
		
	
		if ([option isEqualToString:@"remove"])
		{
			SPHelperClass *nhc = [[SPHelperClass alloc] init];
			int termStatus = [nhc removePackage:value];
			[nhc release];
			[pool release];
			return termStatus;
			
		} 
	}
	
	[pool release];
    return 0;
}

