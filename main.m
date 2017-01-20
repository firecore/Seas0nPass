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

#include <dlfcn.h>

/*
 
 Added some special code to undo App Translocation so we can setuid the helper.
 
 all praise and credit to these websites and their authors for the solution below.
 
 
 
 http://lapcatsoftware.com/articles/detect-app-translocation.html
 https://objective-see.com/blog/blog_0x15.html
 
 */



Boolean (*mySecTranslocateIsTranslocatedURL)(CFURLRef path, bool *isTranslocated, CFErrorRef * __nullable error);
CFURLRef __nullable (*mySecTranslocateCreateOriginalPathForURL)(CFURLRef translocatedPath, CFErrorRef * __nullable error);

bool IsTranslocatedURL(CFURLRef currentURL, CFURLRef *originalURL)
{
    if (currentURL == NULL)
    {
        return false;
    }
    
    // #define NSAppKitVersionNumber10_11 1404
    if (floor(NSAppKitVersionNumber) <= 1404)
    {
        return false;
    }
    
    void *handle = dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_LAZY);
    if (handle == NULL)
    {
        return false;
    }
    
    bool isTranslocated = false;
    
    Boolean (*mySecTranslocateIsTranslocatedURL)(CFURLRef path, bool *isTranslocated, CFErrorRef * __nullable error);
    mySecTranslocateIsTranslocatedURL = dlsym(handle, "SecTranslocateIsTranslocatedURL");
    if (mySecTranslocateIsTranslocatedURL != NULL)
    {
        if (mySecTranslocateIsTranslocatedURL(currentURL, &isTranslocated, NULL))
        {
            if (isTranslocated)
            {
                if (originalURL != NULL)
                {
                    CFURLRef __nullable (*mySecTranslocateCreateOriginalPathForURL)(CFURLRef translocatedPath, CFErrorRef * __nullable error);
                    mySecTranslocateCreateOriginalPathForURL = dlsym(handle, "SecTranslocateCreateOriginalPathForURL");
                    if (mySecTranslocateCreateOriginalPathForURL != NULL)
                    {
                        *originalURL = mySecTranslocateCreateOriginalPathForURL((CFURLRef)currentURL, NULL);
                    }
                    else
                    {
                        *originalURL = NULL;
                    }
                }
            }
        }
    }
    
    dlclose(handle);
    
    return isTranslocated;
}




int main(int argc, char *argv[])
{
	id pool = [NSAutoreleasePool new];
    NSURL *appPath = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    
    //get original URL
    NSURL *newPath = nil;
    
    if (IsTranslocatedURL((CFURLRef) appPath, &newPath) == true)
    {
        
        //remove quarantine attributes of original
       
        [NSTask launchedTaskWithLaunchPath:@"/usr/bin/xattr" arguments:@[@"-cr", (NSURL*)newPath.path]];
 
        //relaunch original
        
        // ->use 'open' as allows two instances of app (this instance is exiting)
        [NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:@[@"-n", @"-a", newPath.path]];
        //this instance is done
        return 0;
    }
 
	
	 NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:LOG_PATH];
	 freopen([logPath fileSystemRepresentation], "a", stderr);

	 [pool release];

	
	return NSApplicationMain(argc,  (const char **) argv);
}

