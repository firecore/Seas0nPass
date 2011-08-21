/**
 * This header is generated by class-dump-z 0.2a.
 * class-dump-z is Copyright (C) 2009 by KennyTM~, licensed under GPLv3.
 *
 * Source: /System/Library/PrivateFrameworks/BackRow.framework/BackRow
 */

#import "BackRow-Structs.h"
#import "BRControl.h"

@class NSArray, BRImageControl;

__attribute__((visibility("hidden")))
@interface BRTrackInfoLayer : BRControl {
@private
	BRControl *_background;	// 40 = 0x28
	BRImageControl *_art;	// 44 = 0x2c
	NSArray *_lines;	// 48 = 0x30
	float _maxLength;	// 52 = 0x34
	long _maxLines;	// 56 = 0x38
}
- (id)init;	// 0x31604005
- (void)_updateSublayers;	// 0x31603e15
- (void)dealloc;	// 0x31603f99
- (void)layoutSubcontrols;	// 0x316042fd
- (void)setImage:(id)image;	// 0x31603ef1
- (void)setLines:(id)lines withImage:(id)image;	// 0x316040ad
- (void)setMaxLines:(long)lines;	// 0x31603ed1
@end
