/*

type: 0 connected, 1 disconnected
state: 3 muxdevice 0 dfu 1 recovery
=================
grestorableData = calloc(1, 36) : 1 object of 36 bytes
grestorableData+0 = 0 (char?)
grestorableData+4 = device events dispatch queue (created by dispatch_queue_create("com.apple.mobiledevice.restore.events", 0))
grestorableData+8 = callbacks thread signal (created by dispatch_semaphore_create(0))
grestorableData+12 = global data lock (created by dispatch_semaphore_create(1))
grestorableData+16 = restorable listeners array (CFMutableArray)
grestorableData+20 = devices dictionary (CFMutableDictionary)
grestorableData+24 = mux mappings dictionary (CFMutableDictionary)
grestorableData+28 = current client id (int)
grestorableData+32 = usbmux listener struct



===========

AutoBootDelay = 0;
    BootImageType = UserOrInternal;
    CreateFilesystemPartitions = 1;
    DFUFileType = RELEASE;
    FlashNOR = 1;
    KernelCacheType = Release;
    NORImageType = production;
    RestoreBootArgs = "rd=md0 nand-enable-reformat=1 -progress";
    RestoreBundlePath = "/Users/djayb6/Library/Caches/Cleanup At Startup/iPhone Temporary Files.noindex";
    SystemImageType = User;
    UpdateBaseband = 1;
    
===============
DFU:
operation: 	2 = Sending DFU files
			44 = Personalizing bundle
			
Recovery:
operation:	44 = Personalizing bundle
			3 = Configuring recovery device
			4 = send apticket if applicable
			31 = Jumping to iBEC
			42 = Sending Apple logo
			5 = Sending RAMDisk
			6 = Sending DeviceTree
			7 = Sending kernelcache
			8 = Sending device map
			9 = Jumping to RAMDisk

Restore device: 

	operation : 
				44 = Personalizing bundle 
				3 = Connecting to restored service
				4 = Connected to restored service
	restored_external
				28 = Waiting for storage device
				11/12 = Creating filesystem partitions
				51 = Resizing system partition
				15 = Checking filesystem
				16 = Mounting filesystem
				29 = Unmounting filesystems
				17 = Fixing up /var directory
				49 = Creating system keybag
				27x2 = Sending then Installing kernelcache
				25 = Clearing persistent boot args
				14 = Verifying restore
				35 = Sending manifest
				18 = Flashing NOR
				46 = Updating Gas Gauge
				46 = Updating IR MCU
				19 = Updating baseband


*/

#ifndef restorable_h
#define restorable_h

typedef struct restorable_data {
    char unknown0;
    //char padding[3];
    dispatch_queue_t device_events_queue; // dispatch_queue_t
    dispatch_semaphore_t thread_lock; // dispatch_semaphore_t
    dispatch_semaphore_t global_data_lock; // dispatch_semaphore_t
    CFMutableArrayRef restorableListenersArray; // CFMutableArrayRef
    CFMutableDictionaryRef devicesDictionary; // CFMutableDictionaryRef
    CFMutableDictionaryRef muxMappingsDictionary; // CFMutableDictionaryRef
    int current_client_id;
    struct usbmux_listener * listener; // struct

} restorable_data ;

struct DeviceProxy {
	void *device; // 0 ; AMXXXModeDeviceRef
	int unknwn4; // (char in IDA) 4
	char unknwn[4]; // 8
	CFStringRef (*CopyBoardConfig)(struct DeviceProxy *prox, CFDictionaryRef deviceMap);
	unsigned int (*GetLocationID)(struct DeviceProxy *prox);
	unsigned long long (*GetECID)(struct DeviceProxy *prox);
	unsigned int (*GetState)(struct DeviceProxy *prox);
	unsigned int (*Restore)(struct DeviceProxy *prox, CFDictionaryRef bootOptions, void (
	
	
	

struct RestorableDevice {
	CFRuntimeBase base; 		// 0
							// 8
	DeviceProxyRef deviceProxy	// 12
	
	
} 
#endif