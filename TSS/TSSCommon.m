//
//  TSSCommon.m
//  TSSAgent
//
//  Created by Kevin Bradley on 1/23/12.
//  Copyright 2012 nito, LLC. All rights reserved.
//

#import "TSSCommon.h"


@implementation TSSCommon


+(NSString *)stringReturnForProcess:(NSString *)call
{
    if (call==nil) 
        return 0;
    char line[200];
    
    FILE* fp = popen([call UTF8String], "r");
    NSMutableString *lines = [[NSMutableString alloc]init];
    if (fp)
    {
        while (fgets(line, sizeof line, fp))
        {
            NSString *s = [NSString stringWithCString:line encoding:NSUTF8StringEncoding];
			[lines appendString:s];
        }
    }
    pclose(fp);
    return [lines autorelease];
}



@end
