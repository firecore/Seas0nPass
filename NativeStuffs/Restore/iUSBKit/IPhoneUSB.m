//
//  IPhoneUSB.m
//  iUSBKit
//
//  Created by iH8sn0w on 9/4/12.
//  Copyright (c) 2012 iH8sn0w. All rights reserved.
//

#import "IPhoneUSB.h"
#import "ToolBox.h"
#import "NSString+Extensions.h"

static BOOL isListening = NO;

void progressCallback(UKDevice *device, double progress)
{

    IPhoneUSB *theSelf = (IPhoneUSB *)(device->user_arg);
    
    [theSelf notifyUploadInProgress:progress];
    
}

void usbEventHandler(UKDevice *device, int event, void *refCon){
    
    IPhoneUSB *theSelf = (IPhoneUSB *)refCon;
    
    if (event == UKDEVICE_CONNECTED)
    {
        theSelf.Device = device;
        device->progress_callback = progressCallback;
        
        if (device->pid == 0x1227)
        {
           [theSelf notifyDFUConnected];
            
        } else if (device->pid == 0x1281)
        {
            [theSelf notifyRecoveryConnected];
            
        }
    }
}

@implementation IPhoneUSB
@synthesize Device;

+ (IPhoneUSB *)sharedInstance
{
    static IPhoneUSB *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        sharedInstance = [[IPhoneUSB alloc] init];
        
       // [ToolBox killiTunesAndCo];
    
    });
    
    return sharedInstance;
}


- (void)start
{
    if (isListening)
        return;

    int a[2][2] = { {0x5AC, 0x1227}, {0x5AC, 0x1281} };
    
    self.Device = init_libusbkit();
    
    
    //init_libusbkit(usbEventHandler, (void *)self );
    
    self.Device->UKAddDevices(self.Device, a);
    
    self.Device->UKRegisterUSBNotifications(self.Device);
    //UKDeviceRegisterForNotifications((void *)self, usbEventHandler);

    isListening = YES;
    
}

- (void)stop
{
    close_libusbkit(self.Device);
    self.Device = NULL;
    isListening = NO;
}

- (int)exploit:(BOOL)mode
{
    return limerain(self.Device, (bool)mode);
}

- (int)uploadFile:(NSString*)file
{
    return send_file(self.Device, [file UTF8String]);
}

- (int)uploadData:(NSData *)data
{
    return send_data(self.Device, (unsigned char *)[data bytes], [data length]);
}

- (int)getEnv:(NSString*)variable
{
    return get_env(self.Device, [variable UTF8String]);
}

- (int)sendCommand:(NSString*)command
{
    return send_command(self.Device, [command UTF8String]);
}


-(NSDictionary*)dumpBlobs {

    bool end = false;
    IOReturn ret;

    NSMutableData *blobData = [NSMutableData data];
    NSMutableDictionary* dictToReturn = [NSMutableDictionary dictionary];

    [dictToReturn setValue:[NSNull null] forKey:@"response"];
    [dictToReturn setValue:[NSNull null] forKey:@"blob"];
   // dictToReturn[@"response"] = [NSNull null];
    //dictToReturn[@"blob"] = [NSNull null];

    do
    {
        IOUSBDevRequestTO request;
        char* response = (char*) malloc(0x8000);
        memset(response, '\0', 0x8000);
    
        bzero(&request, sizeof(request));
    
        request.bmRequestType = 0xC0;
        request.bRequest = 0;
        request.wValue = OSSwapLittleToHostInt16(0);
        request.wIndex = OSSwapLittleToHostInt16(0);
        request.wLength = OSSwapLittleToHostInt16(0x7FFF);
        request.pData = (unsigned char*)response;
        request.noDataTimeout = 1000;
        request.completionTimeout = 1000;
    
        ret = (*Device->dev)->DeviceRequestTO(Device->dev, &request);
    
        if (ret != 0) end = true;
    
        if (strstr(response, "pending") != NULL) continue;
    
        if (strstr(response, "ready-") != NULL)
        {
            NSString* rep = @(response);
            NSRange range = [rep rangeOfString:@"ready-"];
            NSString* md5 = [rep substringFromIndex:NSMaxRange(range)];
        
            [dictToReturn setValue:md5 forKey:@"md5"];
           // dictToReturn[@"md5"] = md5;
            continue;
        }
    
        if (strstr(response, "failed") != NULL)
        {
            NSString* rep = @(response);
            NSRange range = [rep rangeOfString:@"failed-"];
            NSString* error = [rep substringFromIndex:NSMaxRange(range)];
        
            //dictToReturn[@"error"] = error;
            [dictToReturn setValue:error forKey:@"error"];
        }
    
   
        NSString* _response = @(response);
        //NSData* data = [_response hexStringToData];
        NSData* data = [NSData dataFromStringHex:_response];
        [blobData appendData:data];
        free(response);
    
    } while (!end);

    //dictToReturn[@"blob"] = blobData;
    [dictToReturn setValue:blobData forKey:@"blob"];
    return dictToReturn;
}

-(int)rebootDevice
{
    return send_command(self.Device, "reboot");
}

-(void)notifyDFUConnected
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DFUHasConnected" object:self];
    
}

-(void)notifyRecoveryConnected
{    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RecoveryHasConnected" object:self];
    
}

- (void)notifyUploadInProgress:(double)value
{
    NSDictionary* dict;
    
    dict = @{@"progress": @(value)};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UploadInProgress" object:self userInfo:dict];
}

- (void)notifyExploitError
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ExploitError" object:self];
}

- (void)notifyFileUploadError
{    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FileUploadError" object:self];
}

-(void)notifyIFaithError:(const char*)error
{
    NSDictionary* dict = @{@"error": @(error)};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"IFaithError" object:self userInfo:dict];
}

-(void)notifyNormalConnected
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NormalHasConnected" object:self];
}

- (BOOL)isDFUMode
{
    return (self.Device->pid == 0x1227);
}

- (BOOL)isRecoveryMode
{
    return (self.Device->pid == 0x1281);
}

@end