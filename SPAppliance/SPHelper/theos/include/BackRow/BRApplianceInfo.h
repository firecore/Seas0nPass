/**
 * This header is generated by class-dump-z 0.2a.
 * class-dump-z is Copyright (C) 2009 by KennyTM~, licensed under GPLv3.
 *
 * Source: /System/Library/PrivateFrameworks/BackRow.framework/BackRow
 */


@class NSMutableDictionary;

@interface BRApplianceInfo : NSObject {
@private
	NSMutableDictionary *_info;	// 4 = 0x4
}
@property(retain) id applianceCategoryDescriptors;	// G=0x315978d9; S=0x315bf019; converted property
@property(retain) id dataSourceType;	// G=0x315bf165; S=0x315bf191; converted property
@property(assign) BOOL hideIfNoCategories;	// G=0x315bef8d; S=0x315befcd; converted property
@property(assign) float iconHorizontalOffset;	// G=0x315bd5d5; S=0x315bf2f5; converted property
@property(assign) float iconKerningFactor;	// G=0x315bd59d; S=0x315bf2ad; converted property
@property(retain) id iconPath;	// G=0x315bd63d; S=0x315bf33d; converted property
@property(assign) float iconReflectionOffset;	// G=0x315bf22d; S=0x315bf265; converted property
@property(assign) BOOL isRemoteAppliance;	// G=0x315bef05; S=0x315bef41; converted property
@property(retain) id key;	// G=0x31596711; S=0x315bf395; converted property
@property(retain) id name;	// G=0x31596b79; S=0x315bf369; converted property
@property(assign) float preferredOrder;	// G=0x315967f5; S=0x315bf11d; converted property
@property(assign) BOOL primaryAppliance;	// G=0x315966d5; S=0x315bf3c1; converted property
@property(retain) id principalClassName;	// G=0x315973c9; S=0x315bf06d; converted property
@property(retain) id requiredRemoteMediaTypes;	// G=0x315bf099; S=0x315bf0c5; converted property
@property(retain) id supportedMediaTypes;	// G=0x31597c1d; S=0x315bf0f1; converted property
+ (id)infoForApplianceBundle:(id)applianceBundle;	// 0x31592905
- (id)init;	// 0x315bf40d
- (id)initWithDictionary:(id)dictionary;	// 0x31592f5d
// converted property getter: - (id)applianceCategoryDescriptors;	// 0x315978d9
- (BOOL)appliesToMediaHost:(id)mediaHost;	// 0x315bf1bd
// converted property getter: - (id)dataSourceType;	// 0x315bf165
- (void)dealloc;	// 0x31599fbd
// converted property getter: - (BOOL)hideIfNoCategories;	// 0x315bef8d
- (id)icon;	// 0x315bd60d
// converted property getter: - (float)iconHorizontalOffset;	// 0x315bd5d5
// converted property getter: - (float)iconKerningFactor;	// 0x315bd59d
// converted property getter: - (id)iconPath;	// 0x315bd63d
// converted property getter: - (float)iconReflectionOffset;	// 0x315bf22d
// converted property getter: - (BOOL)isRemoteAppliance;	// 0x315bef05
// converted property getter: - (id)key;	// 0x31596711
// converted property getter: - (id)name;	// 0x31596b79
// converted property getter: - (float)preferredOrder;	// 0x315967f5
// converted property getter: - (BOOL)primaryAppliance;	// 0x315966d5
// converted property getter: - (id)principalClassName;	// 0x315973c9
// converted property getter: - (id)requiredRemoteMediaTypes;	// 0x315bf099
// converted property setter: - (void)setApplianceCategoryDescriptors:(id)descriptors;	// 0x315bf019
// converted property setter: - (void)setDataSourceType:(id)type;	// 0x315bf191
// converted property setter: - (void)setHideIfNoCategories:(BOOL)categories;	// 0x315befcd
// converted property setter: - (void)setIconHorizontalOffset:(float)offset;	// 0x315bf2f5
// converted property setter: - (void)setIconKerningFactor:(float)factor;	// 0x315bf2ad
// converted property setter: - (void)setIconPath:(id)path;	// 0x315bf33d
// converted property setter: - (void)setIconReflectionOffset:(float)offset;	// 0x315bf265
// converted property setter: - (void)setIsRemoteAppliance:(BOOL)appliance;	// 0x315bef41
// converted property setter: - (void)setKey:(id)key;	// 0x315bf395
// converted property setter: - (void)setName:(id)name;	// 0x315bf369
// converted property setter: - (void)setPreferredOrder:(float)order;	// 0x315bf11d
// converted property setter: - (void)setPrimaryAppliance:(BOOL)appliance;	// 0x315bf3c1
// converted property setter: - (void)setPrincipalClassName:(id)name;	// 0x315bf06d
// converted property setter: - (void)setRequiredRemoteMediaTypes:(id)types;	// 0x315bf0c5
// converted property setter: - (void)setSupportedMediaTypes:(id)types;	// 0x315bf0f1
// converted property getter: - (id)supportedMediaTypes;	// 0x31597c1d
@end
