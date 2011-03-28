//
//  ripURL.m
//  Seas0nPass
//
//  Created by Kevin Bradley on 3/9/07.
//  Copyright 2007 nito, LLC. All rights reserved.
//

/*
 
 class adapted from hawkeye's ripURL class for downloading youtube files, largely pruned to remove irrelevant sections + updated to cancel the xfer.
 
 */

#import "ripURL.h"


@implementation ripURL

@synthesize downloadLocation, handler;



#pragma mark -
#pragma mark •• URL code

- (void)dealloc
{
	downloadLocation = nil;
	[downloadLocation release];
	[super dealloc];
}

- (void)cancel
{
	
	[self download:urlDownload didFailWithError:nil];
	[urlDownload cancel];
}


- (long long)updateFrequency
{
	return updateFrequency;
}

- (void)setUpdateFrequency:(long long)newUpdateFrequency
{
	updateFrequency = newUpdateFrequency;
}

- (id)init
{
	if(self = [super init]) {
	[self setUpdateFrequency:10.0];
	}
	
	return self;
}



- (void)downloadFile:(NSString *)theFile
{

		//NSLog(@"%@ %s %@", self, _cmd, theFile);

	NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:theFile] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	urlDownload = [[NSURLDownload alloc] initWithRequest:theRequest delegate:self];
	[urlDownload setDestination:downloadLocation allowOverwrite:YES];
	[downloadLocation retain];


}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error

{
	NSLog(@"%@ %s", self, _cmd);
	[handler downloadFailed:downloadLocation];

}

- (void)downloadDidFinish:(NSURLDownload *)download

{
	
    if(download == urlDownload) {

		[handler downloadFinished:downloadLocation];
      
	}

}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response

{
		//NSLog(@"%s %@", _cmd, response);
	
    bytesReceived=0;
    
    
    // retain the response to use later
    
    [self setDownloadResponse:response];
	//[pool release];
    
}

- (void)setDownloadResponse:(NSURLResponse *)response
{
	
    [response retain];
    myResponse = response;
  
}

- (NSURLResponse *)downloadResponse
{
    return myResponse;

	
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length

{
		
    long long expectedLength = [[self downloadResponse] expectedContentLength];
    bytesReceived=bytesReceived+length;
    
    if (expectedLength != NSURLResponseUnknownLength) {
        
        double percentComplete=(bytesReceived/(float)expectedLength)*100.0;
    //    NSLog(@"Percent complete - %f",percentComplete);
		
		if((freq%updateFrequency) == 0){
		//	while(1){
				//NSLog(@"%i", freq%updateFrequency );
				[handler setDownloadProgress:percentComplete];
				
		}
		freq++;
		//	}
		
       
        
    } else {
        
       // [downloadpBar setIndeterminate:YES];
        NSLog(@"Bytes received - %d",bytesReceived);
        
    }
	

    
}




@end
