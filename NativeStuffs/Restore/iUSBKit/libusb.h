//
//  libusb.h
//  iFaith
//
//  Created by Steven De Franco on 10/11/2013.
//  Copyright (c) 2013 iH8sn0w. All rights reserved.
//

#ifndef iFaith_libusb_h
#define iFaith_libusb_h

#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/IOCFPlugIn.h>



#define UKDEVICE_CONNECTED 1
#define UKDEVICE_DISCONNECTED 0

typedef struct UKDevice UKDevice;
typedef void (*UKEventHandler)(UKDevice *, int, void *);
typedef void (*UKProgressHandler)(UKDevice *Device, double progress);

/*

struct UKDevice {
    
    // properties
    
   // io_service_t usbService;
    io_iterator_t interfaceIterator;
    IONotificationPortRef ioKitNotificationPort;
    CFRunLoopSourceRef notificationRunLoopSource;
    CFRunLoopSourceRef asyncRunLoopSource;
    IOUSBDeviceInterface187 **dev;
    IOUSBInterfaceInterface300 **intf;
    int mode;
    bool enabled;
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
    int eligibleDevices[2][2]; // 0 => vendorID, 1=> productID
    
    
    void *user_arg;
    UKEventHandler event_block;
    UKProgressHandler progress_callback;
    // methods
    
    
    
    void (*UKRegisterUSBNotifications) (struct UKDevice*);
    void (*UKAddDevices) (struct UKDevice*, int[2][2]);
    void (*UKOpenDevice) (struct UKDevice*);
    void (*UKOpenInterface) (struct UKDevice*, int, int);
    void (*UKReleaseDevice) (struct UKDevice*);
    void (*UKGetIDs) (struct UKDevice*);
    
    int (*UKSendControlRequest) (struct UKDevice*, UInt8, UInt8, UInt16, UInt16, UInt16, void *);
    int (*UKSendControlRequestTO) (struct UKDevice*, UInt8, UInt8, UInt16, UInt16, UInt16, void *, UInt32);
    int (*UKSendControlRequestAsync) (struct UKDevice*, UInt8, UInt8, UInt16, UInt16, UInt16, void *);
    int (*UKSendControlRequestAsyncTO) (struct UKDevice*, UInt8, UInt8, UInt16, UInt16, UInt16, void *, UInt32);
    
    int (*UKResetDevice) (struct UKDevice*);
    int (*UKAbortPipeZero) (struct UKDevice*);
    int (*UKWriteSerial) (struct UKDevice*, void*, UInt32);
    int (*UKReadSerial) (struct UKDevice*, void*, UInt32*);
    
    int (*UKSendCommand)(struct UKDevice*, const char*);
    int (*UKGetEnv)(struct UKDevice*, const char*);
    void (*UKDumpIFaith)(struct UKDevice*, const char*);
    
    int (*UKLimeRain)(struct UKDevice*, bool ifaith_mode);
    void (*UKsteaks4uce)(struct UKDevice*);
    
    int (*UKSendData)(struct UKDevice*, unsigned char*, unsigned long);
    int (*UKSendFile)(struct UKDevice*, const char*);
    
    
    
};
*/
UKDevice * init_libusbkit();

int UKDeviceRegisterForNotifications(void *userArg, UKEventHandler event_block);

//UKDevice * init_libusbkit(UKEventHandler event_block, void *userArg);
void close_libusbkit(UKDevice *Device);

void register_for_usb_notifications(UKDevice * Device);
void add_devices(UKDevice * Device, int devices_array[2][2]);
void release_device(UKDevice * Device);
void device_attached(void * refCon, io_iterator_t iterator);
void device_detached(void * refCon, io_iterator_t iterator);
void open_device(UKDevice * Device);
void open_interface(UKDevice * Device, int interface, int alt_interface);
void get_ids(UKDevice * Device);

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

void steaks4uce(UKDevice *Device);
int limerain(UKDevice *Device, bool ifaith_mode);
int send_data(UKDevice *Device, unsigned char* data, unsigned long length);
int send_file(UKDevice * Device, const char * filename);
int send_command(UKDevice * Device, const char * command);
int get_env(UKDevice* Device, const char * variable);
//void dump_ifaith(UKDevice * Device, const char* filename);

void fire_event(UKDevice *Device, int event);



int DFUGetStatus(UKDevice *Device, struct dfu_status *status);
int DFUGetState(UKDevice *Device);
int DFUClearStatus(UKDevice *Device);
int DFUAbort(UKDevice *Device);




#endif
