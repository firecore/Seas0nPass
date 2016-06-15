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
	int queueNumber;
	int currentIndex;
}

@property (nonatomic, retain) NSString *currentBuild;
@property (nonatomic, retain) NSArray *savedBuilds;
@property (nonatomic, retain) NSArray *queuedBuilds;
@property (readwrite, assign) int queueNumber;
@property (readwrite, assign) int currentIndex;

- (void)theWholeShebang;
- (NSArray *)filteredList:(NSArray *)signedFW;
- (void)fetchSavedFirmwares; 
- (void)processorDidFinish:(id)processor withStatus:(int)status;
- (NSArray *)buildsFromList:(NSArray *)theList;
- (void)fetchAvailableFirmwares;

@end
