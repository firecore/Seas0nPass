//
//  TSSManager.h
//  TSSAgent
//
//  Created by Kevin Bradley on 1/16/12.
//  Copyright 2012 nito, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FWBundle.h"
#import "TSSCommon.h"

//#define BLOB_PLIST_BASE_URL @"http://nitosoft.com/ATV2/FW/"
//#define BLOB_PLIST_URL @"http://nitosoft.com/ATV2/FW/k66ap.plist"

//New URL: http://files.firecore.com/SP/firmware/k66ap.plist

#define BLOB_PLIST_BASE_URL @"http://files.firecore.com/SP/firmware"
#define BLOB_PLIST_URL @"http://files.firecore.com/SP/firmware/k66ap.plist"

enum {
	
	kTSSFetchBlobFromApple,
	kTSSFetchBlobFromCydia,
	kTSSSendBlobToCydia,
	kTSSCydiaBlobListing,
	kTSSCydiaBlobListingSolo,
};


#define TSSNullDevice DeviceIDMake(0, 0)

struct TSSDeviceID {
	int boardID;
	int chipID;
};
typedef struct TSSDeviceID TSSDeviceID;

static inline TSSDeviceID DeviceIDMake(int bid, int cid);

static inline TSSDeviceID DeviceIDMake(int bid, int cid)
{
	TSSDeviceID theDevice;
	theDevice.boardID = bid; theDevice.chipID = cid;
	return theDevice;
}

static inline bool DeviceIDEqualToDevice(TSSDeviceID device1, TSSDeviceID device2);

static inline bool DeviceIDEqualToDevice(TSSDeviceID device1, TSSDeviceID device2)
{
	return device1.boardID == device2.boardID && device1.chipID == device2.chipID;
}



@interface TSSManager : NSObject {

	NSURLConnection *           _connection;
	NSMutableData *				receivedData;
	NSString *					_returnDataAsString;
	NSString *					baseUrlString;
	id							delegate;
	NSString *					ecid;
	int							mode;
	TSSDeviceID					theDevice;
	NSString					*deviceModel;
}

@property (readwrite, assign) TSSDeviceID theDevice;
@property (readwrite, assign) int mode;
@property (nonatomic, retain) NSString *deviceModel;
@property (nonatomic, assign) NSString *_returnDataAsString;
@property (nonatomic, assign) NSString *baseUrlString;
@property (nonatomic, assign) NSString *ecid;
@property (nonatomic, retain) id delegate;

- (NSArray *)_newSimpleSynchBlobCheck;
- (NSArray *)_synchronousiFaithBlobCheck;
+ (NSArray *)ifaithBlobArrayFromString:(NSString *)inputString;
- (NSArray *)_simpleiFaithSynchronousBlobCheck;
- (int)openStitchFirmware:(FWBundle *)theBundle;
- (NSString *)_synchronousiFaithReceiveVersion:(NSString *)theVersion;
- (NSString *)_synchronousPushiFaithBlob:(NSString *)theBlob withiOSVersion:(NSString *)iosVersion;
+ (NSString *)manifestKeyFromiFaithKey:(NSString *)key;
- (int)_synchronousAPTicketCheck:(NSData *)apticket;
- (BOOL)signFileForiFaith:(NSString *)inputFile withBlob:(NSData *)blobData withCert:(NSString *)certValue;
- (NSArray *)_simpleiFaithSynchronousBlobCheck;
- (int)stitchFirmwareForiFaith:(FWBundle *)theBundle;
+ (NSArray *)signableVersionsFromModel:(NSString *)theModel;
+ (NSArray *)supportedDevices;
- (id)initWithECID:(NSString *)theEcid device:(TSSDeviceID)myDevice;
- (void)_sendBlobs:(NSArray *)blobs;
+ (NSArray *)localAppleTVBlobs;
- (NSString *)_synchronousPushBlob:(NSString *)theBlob withECID:(NSString *)theEcid;
- (NSArray *)_simpleSynchronousBlobCheck;
+ (NSData *)apTicketFromDictionary:(NSDictionary *)thePlist;
- (NSDictionary *)dictionaryFromString:(NSString *)theString;
+ (NSString *)apTicketFileFromDictionary:(NSDictionary *)thePlist;
- (NSString *)_synchronousCydiaReceiveVersion:(NSString *)theVersion;
- (NSString *)_synchronousPushBlob:(NSString *)theBlob;
- (NSString *)_synchronousReceiveVersion:(NSString *)theVersion;
- (NSArray *)_synchronousBlobCheck;
+ (NSString *)rawBlobFromResponse:(NSString *)inputString;
- (void)logDevice:(TSSDeviceID)inputDevice;
+ (TSSDeviceID)currentDevice;
+ (NSArray *)signableVersions;
+ (NSArray *)blobArrayFromString:(NSString *)theString;
+(NSString *) ipAddress;
- (NSMutableURLRequest *)requestForList;
- (NSMutableURLRequest *)requestForBlob:(NSString *)theBlob;
- (NSMutableURLRequest *)postRequestFromVersion:(NSString *)theVersion;
- (NSDictionary *)tssDictFromVersion:(NSString *)versionNumber;
- (id)initWithECID:(NSString *)theEcid;
- (int)stitchFirmware:(FWBundle *)theBundle;
- (BOOL)signFile:(NSString *)inputFile withBlob:(NSData *)blobData;
- (void)updateManifestFile:(NSString *)manifest;


@end


