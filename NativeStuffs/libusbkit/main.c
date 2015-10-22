//
//  main.c
//  TestLibUSB
//
//  Created by Steven De Franco on 2/7/13.
//  Copyright (c) 2013 iH8sn0w. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#include <assert.h>
#include <pthread.h>
#include "libusbkit.h"

void *otherThread(void* object);
void *otherThread(void* object) {
    
    UKDevice* Device = (UKDevice*)object;
    

    while (!Device->opened && Device->pid != 0x1227) {
        
        printf("Waiting for DFU to appear\n");
        sleep(1);
    }
    
    
    int ret = shatter(Device);
    printf("SHAtter status: %i\n", ret);
  //  limerain(Device, false);
    
    //CFRunLoopStop(CFRunLoopGetCurrent());
        
     
    return NULL;
}


int main(int argc, const char * argv[])
{
    
    int a[2][2] = { {0x5AC, 0x1227}, {0x5AC, 0x1281} };
    
    UKDevice * Device = init_libusbkit();
    
    add_devices(Device, a);
    
    register_for_usb_notifications(Device);
    
    pthread_attr_t  attr;
    pthread_t       posixThreadID;
    int             returnVal;
    
    returnVal = pthread_attr_init(&attr);
    assert(!returnVal);
    returnVal = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    assert(!returnVal);
    
    int threadError = pthread_create(&posixThreadID, &attr, &otherThread, Device);
    
    returnVal = pthread_attr_destroy(&attr);
    assert(!returnVal);
    if (threadError != 0)
    {
        // Report an error.
    }
    
    
    CFRunLoopRun();
    return 0;
}

