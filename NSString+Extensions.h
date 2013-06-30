//
//  NSString+Extensions.h
//  tetherKit
//
//  Created by Kevin Bradley on 4/6/13.
//  Copyright 2013 FireCore, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (specialData)

- (NSString *)hexToString;
- (NSData *) stringToHexData;
- (NSString *)stringToPaddedHex;
@end

@interface NSXMLDocument (specialData)

- (NSDictionary *)iFaithDictionaryRepresentation;

@end

