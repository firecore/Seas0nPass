//
//  main.m
//  tetherKit
//
//  Created by Kevin Bradley on 12/27/10.
//  Copyright 2011 Fire Core, LLC. All rights reserved.
//

#ifdef DEBUG
#define LOG_PATH @"Library/Logs/SP_Debug_db.log"
#else
#define LOG_PATH @"Library/Logs/SP_Debug.log"
#endif

#import <Cocoa/Cocoa.h>
#include <stdio.h>


int main(int argc, char *argv[])
{
	
	
	 
	//FIXME: COMMENT BACK IN BEFORE RELEASE!!!!
	
	 id pool = [NSAutoreleasePool new];
	
	 NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:LOG_PATH];
	 freopen([logPath fileSystemRepresentation], "a", stderr);
	 [pool release];

	
	return NSApplicationMain(argc,  (const char **) argv);
}

