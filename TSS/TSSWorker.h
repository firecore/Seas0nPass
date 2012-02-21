//
//  TSSWorker.h
//  TSSAgent
//
//  Created by Kevin Bradley on 1/22/12.
//  Copyright 2012 nito, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSSManager.h"

@interface TSSWorker : NSObject {
	
	NSString *currentBuild;
	NSArray *savedBuilds;
	NSArray *queuedBuilds;
	NSString *ecid;
	int queueNumber;
	int currentIndex;
}

@property (nonatomic, assign) NSString *ecid;
@property (nonatomic, retain) NSString *currentBuild;
@property (nonatomic, retain) NSArray *savedBuilds;
@property (nonatomic, retain) NSArray *queuedBuilds;
@property (readwrite, assign) int queueNumber;
@property (readwrite, assign) int currentIndex;

- (NSString *)getVersionTicket:(NSString *)theVersion;
- (void)theWholeShebang;
- (NSArray *)filteredList:(NSArray *)signedFW;
+ (NSArray *)buildsFromList:(NSArray *)theList;

@end
