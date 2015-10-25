//
//  libusbkit.h
//  libusbkit
//
//  Created by Steven De Franco on 2/7/13.
//  Copyright (c) 2013 iH8sn0w. All rights reserved.
//

#ifndef libusbkit_libusbkit_h
#define libusbkit_libusbkit_h
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/IOCFPlugIn.h>

#ifdef __OBJC__
#include "IPhoneUSB.h"
#endif

typedef struct UKDevice_INFO {
    long long ecid;
    int bdid, cpid, status;
    unsigned int addr;
    unsigned int dwn_addr;
    unsigned int addr_final;
    unsigned char data[0x800];
    char buf[0x2C000];
} UKDevice_SHAtter;

UKDevice_SHAtter SHAtter_user;


typedef struct UKDevice {
    
    // properties

    io_service_t usbService;
    io_iterator_t interfaceIterator;
    IONotificationPortRef ioKitNotificationPort;
    CFRunLoopSourceRef notificationRunLoopSource;
    IOUSBDeviceInterface187 **dev;
    IOUSBInterfaceInterface300 **intf;
    int mode;
    bool enabled;
    bool normalDevice;
    unsigned char ctrlIn;
    unsigned char ctrlOut;
    unsigned char serialIn;
    unsigned char serialOut;
    unsigned char fileIn;
    unsigned char fileOut;
    unsigned short transaction;
    int vid;
    int pid;
    int bdid;
    int cpid;
    long long ecid;
    int locationID;
    bool opened;
    bool shattered;
    int eligibleDevices[2][2]; // 0 => vendorID, 1=> productID
    
    
} UKDevice ;


UKDevice* firstAvailableDevice();
UKDevice * init_libusbkit(int mode, const char *path, void*theClass, int status);
void close_libusbkit(UKDevice* Device);
BOOL manually_open_device(UKDevice *Device, io_object_t deviceService);
void stop_notification_monitoring(UKDevice *Device);
void register_for_usb_notifications(UKDevice * Device);
void add_devices(UKDevice * Device, int devices_array[2][2]);
void release_device(UKDevice * Device);
void device_attached(void * refCon, io_iterator_t iterator);
void device_detached(void * refCon, io_iterator_t iterator);
void open_device(UKDevice * Device);
void open_interface(UKDevice * Device, int interface, int alt_interface);
int get_ids(UKDevice * Device);
int normal_device_detected(UKDevice* Device, UInt16 vendorID, UInt16 productID);

int send_control_request(UKDevice * Device,
                         UInt8 bm_request_type,
                         UInt8 b_request,
                         UInt16 w_value,
                         UInt16 w_index,
                         UInt16 w_length,
                         void * p_data);

int send_control_request_to(UKDevice * Device,
                            UInt8 bm_request_type,
                            UInt8 b_request,
                            UInt16 w_value,
                            UInt16 w_index,
                            UInt16 w_length,
                            void * p_data,
                            UInt32 timeout);

int send_control_request_async(UKDevice * Device,
                               UInt8 bm_request_type,
                               UInt8 b_request,
                               UInt16 w_value,
                               UInt16 w_index,
                               UInt16 w_length,
                               void * p_data);

int send_control_request_async_to(UKDevice * Device,
                                  UInt8 bm_request_type,
                                  UInt8 b_request,
                                  UInt16 w_value,
                                  UInt16 w_index,
                                  UInt16 w_length,
                                  void * p_data,
                                  UInt32 timeout);

int reset_device(UKDevice * Device);
int abort_pipe_zero(UKDevice * Device);
int write_serial(UKDevice * Device, void* buffer, UInt32 size);
int read_serial(UKDevice * Device, void* buffer, UInt32 * size);
int get_status(UKDevice* Device, unsigned int * status);
int reset_counters(UKDevice * Device);
int reenumerate_device(UKDevice *Device);

int SHAtter(UKDevice *Device);
int shatter(UKDevice *Device);
int limerain(UKDevice *Device, bool ifaith_mode);
int send_data(UKDevice *Device, unsigned char* data, unsigned long length);
int send_file(UKDevice * Device, const char * filename);
int send_command(UKDevice * Device, const char * command);
int print_env(UKDevice* Device, const char * variable);
char* get_env(UKDevice* Device, const char * variable);
char* dump_ifaith(UKDevice * Device, const char* filename);

#endif
