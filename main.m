//
//  main.m
//  tetherKit
//
//  Created by Kevin Bradley on 12/27/10.
//  Copyright 2011 Fire Core, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
	/*
	char *val_buf, path_buf[155];
	
	val_buf = getenv("HOME");
	sprintf(path_buf,"%s/Library/Logs/Test.log",val_buf);
	freopen(path_buf,"a",stderr);
	 */
    id pool = [NSAutoreleasePool new];
	
	NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/SP_Debug.log"];
	freopen([logPath fileSystemRepresentation], "a", stderr);
	
	[pool release];
	return NSApplicationMain(argc,  (const char **) argv);
}

