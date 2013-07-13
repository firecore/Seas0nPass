//
//  TSSCategories.m
//  TSSAgent
//
//  Created by Kevin Bradley on 6/22/13.
//  Copyright 2013 nito. All rights reserved.
//

#import "TSSCategories.h"

@implementation NSDictionary (strings) 

- (NSString *)stringFromDictionary
{
	NSString *error = nil;
	NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:self format:kCFPropertyListXMLFormat_v1_0 errorDescription:&error];
	NSString *s=[[NSString alloc] initWithData:xmlData encoding: NSUTF8StringEncoding];
	return [s autorelease];
}

@end

@implementation NSArray (strings)

- (NSString *)stringFromArray
{
	NSString *error = nil;
	NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:self format:kCFPropertyListXMLFormat_v1_0 errorDescription:&error];
	NSString *s=[[NSString alloc] initWithData:xmlData encoding: NSUTF8StringEncoding];
	return [s autorelease];
}

@end


@implementation NSString (TSSAdditions)

/*
 
 we use this to convert a raw dictionary plist string into a proper NSDictionary
 
 */

- (id)dictionaryFromString
{
	NSString *error = nil;
	NSPropertyListFormat format;
	NSData *theData = [self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	id theDict = [NSPropertyListSerialization propertyListFromData:theData
												  mutabilityOption:NSPropertyListImmutable
															format:&format
												  errorDescription:&error];
	return theDict;
}


@end

