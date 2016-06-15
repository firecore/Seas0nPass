//
//  ripURL.h
//  Seas0nPass
//
//  Created by Kevin Bradley on 3/9/07.
//  Copyright 2007 nito, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ripURLDelegate

- (void)downloadFinished:(NSString *)downloadFile;
- (void)downloadFailed:(NSString *)downloadFile;
- (void)setDownloadProgress:(double)theProgress;

@end


@interface ripURL : NSObject <NSURLDownloadDelegate>  {
	
	NSURLDownload				*urlDownload;
    NSURLResponse				*myResponse;
	id							handler;
    float						bytesReceived;
	NSString					*downloadLocation;
	long long					updateFrequency;
	long long					freq;
}

@property (nonatomic, retain) NSString *downloadLocation;
@property (nonatomic, assign) id handler;

- (void)downloadFile:(NSString *)theFile;
- (long long)updateFrequency;
- (void)setUpdateFrequency:(long long)newUpdateFrequency;
- (void)setDownloadResponse:(NSURLResponse *)response;
- (void)cancel;

@end
