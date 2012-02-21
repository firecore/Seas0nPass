//
//  NSData+Flip.m
//  tetherKit
//
//  Created by Kevin Bradley on 1/26/12.
//  Copyright 2012 FireCore, LLC. All rights reserved.
//

#import "NSData+Flip.h"

/*
 
 cydhex and cyddatahex are taken directly from cydia source, with just the names slightly changed, this was a leftover from using this code in tssagent where i did it to make sure it never found a way to interfere with cydia
 if it was ever ported for other iOS devices.
 
 
 */

static NSString *CYDHex(NSData *data, bool reverse) {
    if (data == nil)
        return nil;
	
    size_t length([data length]);
    uint8_t bytes[length];
    [data getBytes:bytes];
	
    char string[length * 2 + 1];
    for (size_t i(0); i != length; ++i)
        sprintf(string + i * 2, "%.2x", bytes[reverse ? length - i - 1 : i]);
	
    return [NSString stringWithUTF8String:string];
}

static NSData *CYDataHex(NSData *data, bool reverse) {
    if (data == nil)
        return nil;
	
    size_t length([data length]);
    uint8_t bytes[length];
    [data getBytes:bytes];
	
    char string[length * 2 + 1];
    for (size_t i(0); i != length; ++i)
        sprintf(string + i * 2, "%.2x", bytes[reverse ? length - i - 1 : i]);
	
    return [NSData dataWithBytes:string length:length];
}

static NSString *HexToDec(NSString *hexValue)
{
	if (hexValue == nil)
		return nil;
	
	unsigned long long dec;
	NSScanner *scan = [NSScanner scannerWithString:hexValue];
	if ([scan scanHexLongLong:&dec])
	{
		
		return [NSString stringWithFormat:@"%llu", dec];
			//NSLog(@"chipID binary: %@", finalValue);
	}
	
	return nil;
}


@implementation NSData (myAdditions)


+ (NSData *)dataFromStringHex:(NSString *)command
{
	
	command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSMutableData *commandToSend= [[NSMutableData alloc] init];
	unsigned char whole_byte;
	char byte_chars[3] = {'\0','\0','\0'};
	int i;
	for (i=0; i < [command length]/2; i++) {
		byte_chars[0] = [command characterAtIndex:i*2];
		byte_chars[1] = [command characterAtIndex:i*2+1];
		whole_byte = strtol(byte_chars, NULL, 16);
		[commandToSend appendBytes:&whole_byte length:1]; 
	}
		//NSLog(@"%@", commandToSend);
	
	return [commandToSend autorelease];
}

- (NSData *)reverse
{
	return [NSData dataFromStringHex:CYDHex(self, TRUE)];
}

- (NSString *)decimalString
{
	NSString *stringData = CYDHex(self, TRUE);
	return HexToDec(stringData);
}

-(NSData *) byteFlipped
{
	NSMutableData *newData = [[NSMutableData alloc] init];
	const char *_data = (char *)[self bytes];
	int stringLength = [self length];
		//NSLog(@"stringLength: %i", [self length]);
	int x;
	for( x=stringLength-1; x>=0; x-- )
	{
		char currentByte = _data[x];
			//printf("%c,", _data[x]);
		[newData appendBytes:&currentByte length:1];
	}
	
	return [newData autorelease];
}
@end
