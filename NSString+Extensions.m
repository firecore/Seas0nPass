//
//  NSString+Extensions.m
//  tetherKit
//
//  Created by Kevin Bradley on 4/6/13.
//  Copyright 2013 FireCore, LLC. All rights reserved.
//

#import "NSString+Extensions.h"

@implementation NSString (specialData)

- (NSString *)stringToPaddedHex
{
	return [NSString stringWithFormat:@"%.016lX", [self integerValue]];
}

- (NSString *)hexToString
{
	NSData *theData = [self stringToHexData];
	return [[[NSString alloc] initWithData:theData encoding: NSASCIIStringEncoding] autorelease];
}

- (NSData *) stringToHexData
{
    int len = [self length] / 2;    // Target length
    unsigned char *buf = malloc(len);
    unsigned char *whole_byte = buf;
    char byte_chars[3] = {'\0','\0','\0'};
	
    int i;
    for (i=0; i < [self length] / 2; i++) {
        byte_chars[0] = [self characterAtIndex:i*2];
        byte_chars[1] = [self characterAtIndex:i*2+1];
        *whole_byte = strtol(byte_chars, NULL, 16);
        whole_byte++;
    }
	
    NSData *data = [NSData dataWithBytes:buf length:len];
    free( buf );
    return data;
}




@end

@implementation NSXMLDocument (specialData)

- (NSDictionary *)iFaithDictionaryRepresentation
{
	
	NSArray *convertKeys = [NSArray arrayWithObjects:@"bat1", @"recm", @"glyp", @"chg0", @"ibot", @"dtre", @"bat0", @"logo", @"chg1", @"glyc", @"illb", @"batf", @"krnl", @"apticket",nil];
	
    NSMutableDictionary *dict=[[NSMutableDictionary alloc]init];
    NSArray *val=[self nodesForXPath:@"./iFaith/name" error:nil];
	NSMutableArray *convertedKeys = [[NSMutableArray alloc] init];
	if ([val count]!=0)
	{
		NSArray *children = [[val objectAtIndex:0] children];
		for (NSXMLNode *child in children)
		{
				//NSLog(@"name: %@, stringVal: %@", [child name], [child stringValue]);
			
			id object = [child stringValue];
			NSString *key = [child name];
			
			if ([convertKeys containsObject:key])
			{
				NSData *newObject = [object stringToHexData];
				NSString *newKey = [TSSManager manifestKeyFromiFaithKey:key];
					//NSLog(@"newobject; %@ forkey: %@", newObject, key);
				object = newObject;
				
				NSLog(@"key %@ to new key: %@", key, newKey);
			    
				if (newKey != nil)
				{
					key = newKey;
					[convertedKeys addObject:newKey];
				}
			}
				//			
			[dict setObject:object forKey:key];
		}
		
		[dict setObject:convertedKeys forKey:@"ifaithSigned"];
	}
    
		//	NSLog(@"dict: %@", dict);
	
	return [dict autorelease];
}

@end