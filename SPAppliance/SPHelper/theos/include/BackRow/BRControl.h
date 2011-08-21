/**
 * This header is generated by class-dump-z 0.2a.
 * class-dump-z is Copyright (C) 2009 by KennyTM~, licensed under GPLv3.
 *
 * Source: /System/Library/PrivateFrameworks/BackRow.framework/BackRow
 */

#import "BRFocusContainer.h"
#import "BackRow-Structs.h"
#import "BRResponder.h"

@class CALayer, NSMutableArray;

@interface BRControl : NSObject <BRFocusContainer, BRResponder> {
@private
	CALayer *_backing;	// 4 = 0x4
	BRControl *_defaultFocus;	// 8 = 0x8
	BRControl *_focusedControl;	// 12 = 0xc
	BRControl *_previousFocus;	// 16 = 0x10
	BRControl *_keyEventTargetControl;	// 20 = 0x14
	unsigned _autoresizing;	// 24 = 0x18
	NSMutableArray *_subControls;	// 28 = 0x1c
	BOOL _dontAutoresizeSubviews;	// 32 = 0x20
	BOOL _acceptsFocus;	// 33 = 0x21
	BOOL _focused;	// 34 = 0x22
	BOOL _controlActive;	// 35 = 0x23
	BOOL _inhibitsFocusForChildren;	// 36 = 0x24
	BOOL _inhibitsScrollFocusForChildren;	// 37 = 0x25
}
@property(assign) BOOL acceptsFocus;	// G=0x3158da45; S=0x3158d661; converted property
@property(retain) id actions;	// G=0x315d196d; S=0x315d198d; converted property
@property(assign) CGAffineTransform affineTransform;	// G=0x315d27f5; S=0x315d23b9; converted property
@property(assign) CGPoint anchorPoint;	// G=0x315d2819; S=0x315d2405; converted property
@property(assign) unsigned autoresizingMask;	// G=0x315d155d; S=0x315d154d; converted property
@property(assign) BOOL avoidsCursor;	// G=0x315a1465; S=0x3159618d; converted property
@property(assign) CGColorRef backgroundColor;	// G=0x315d1f25; S=0x315d1f45; converted property
@property(assign) CGColorRef borderColor;	// G=0x315d1bc5; S=0x315d1be5; converted property
@property(assign) float borderWidth;	// G=0x315d1b85; S=0x315d1ba5; converted property
@property(assign) CGRect bounds;	// G=0x315d283d; S=0x315d2861; converted property
@property(assign) int contentMode;	// G=0x315d1c05; S=0x315d1dc1; converted property
@property(retain) id controls;	// G=0x315d2091; S=0x315d20bd; converted property
@property(retain) BRControl *defaultFocus;	// G=0x315d1585; S=0x3159720d; converted property
@property(readonly, assign, getter=isFocused) BOOL focused;	// G=0x3158da35; converted property
@property(retain) BRControl *focusedControl;	// G=0x3158dadd; S=0x3158dbf5; converted property
@property(assign) CGRect frame;	// G=0x315d2979; S=0x315d3239; converted property
@property(assign, getter=isHidden) BOOL hidden;	// G=0x315d1e9d; S=0x315d1ec1; converted property
@property(retain) id identifier;	// G=0x3158e565; S=0x31596d19; converted property
@property(assign) BOOL inhibitsFocusForChildren;	// G=0x315d1595; S=0x315d1a8d; converted property
@property(readonly, assign) BOOL inhibitsScrollFocusForChildren;	// G=0x315d15bd; converted property
@property(retain) BRControl *keyEventTargetControl;	// G=0x315d153d; S=0x315d2445; converted property
@property(assign) BOOL masksToBounds;	// G=0x315d1f65; S=0x315d1f89; converted property
@property(retain) id name;	// G=0x315d2301; S=0x315d2321; converted property
@property(retain) id object;	// G=0x315a20b1; S=0x3159e5f9; converted property
@property(assign) float opacity;	// G=0x315d1ee5; S=0x315d1f05; converted property
@property(assign) CGPoint position;	// G=0x315d2955; S=0x315d2425; converted property
@property(retain) id selectionHandler;	// G=0x315d1a4d; S=0x315d1a6d; converted property
+ (id)control;	// 0x3158e115
+ (id)controlWithScaledFrame:(CGRect)scaledFrame;	// 0x3161ebb5
+ (Class)layerClass;	// 0x315d25e9
- (id)init;	// 0x3158d5e1
- (BOOL)_changeFocusTo:(id)to;	// 0x3158da55
- (void)_dumpControlTree;	// 0x315d2d49
- (void)_dumpFocusTree;	// 0x315d2fb1
- (BOOL)_focusControlTreeForEvent:(id)event nearPoint:(CGPoint)point;	// 0x315a105d
- (BOOL)_focusControlTreeWithDefaults;	// 0x3158d9e1
- (id)_focusedLeafControl;	// 0x315a103d
- (CGPoint)_focusedPointForEvent:(id)event;	// 0x315a0f79
- (id)_initialFocus;	// 0x315d1715
- (void)_insertSingleControl:(id)control atIndex:(long)index;	// 0x315d17b5
- (void)_layoutSublayersOfLayer:(id)layer;	// 0x315d24bd
- (id)_parentScrollControl;	// 0x31671385
- (void)_reevaluateFocusTree;	// 0x3159c9f1
- (void)_removeAllControls;	// 0x315d1759
- (void)_removeControl:(id)control;	// 0x315961cd
- (void)_resizeSubviewsWithOldSize:(CGSize)oldSize;	// 0x315d30d1
- (void)_resizeWithOldSuperviewSize:(CGSize)oldSuperviewSize;	// 0x315d2c21
- (void)_scrollPoint:(CGPoint)point fromControl:(id)control;	// 0x31671351
- (void)_scrollRect:(CGRect)rect fromControl:(id)control;	// 0x31671301
- (void)_scrollingCompleted;	// 0x3167146d
- (void)_scrollingInitiated;	// 0x3167142d
- (void)_setControlFocused:(BOOL)focused;	// 0x3158d90d
- (void)_setFocus:(id)focus;	// 0x3158daed
- (CGRect)_visibleRectOfControl:(id)control;	// 0x31671add
- (void)_visibleScrollRectChanged;	// 0x316712d5
// converted property getter: - (BOOL)acceptsFocus;	// 0x3158da45
- (id)actionForKey:(id)key;	// 0x315d19ad
- (id)actionForLayer:(id)layer forKey:(id)key;	// 0x315d24d1
// converted property getter: - (id)actions;	// 0x315d196d
- (BOOL)active;	// 0x315d156d
- (void)addAnimation:(id)animation forKey:(id)key;	// 0x315d1a2d
- (void)addControl:(id)control;	// 0x315d22c5
// converted property getter: - (CGAffineTransform)affineTransform;	// 0x315d27f5
// converted property getter: - (CGPoint)anchorPoint;	// 0x315d2819
- (id)animationForKey:(id)key;	// 0x315d1a0d
// converted property getter: - (unsigned)autoresizingMask;	// 0x315d155d
// converted property getter: - (BOOL)avoidsCursor;	// 0x315a1465
// converted property getter: - (CGColorRef)backgroundColor;	// 0x315d1f25
- (id)badge;	// 0x315e19c5
// converted property getter: - (CGColorRef)borderColor;	// 0x315d1bc5
// converted property getter: - (float)borderWidth;	// 0x315d1b85
// converted property getter: - (CGRect)bounds;	// 0x315d283d
- (CGSize)boundsForFocusCandidate:(id)focusCandidate;	// 0x315d2609
- (BOOL)brEventAction:(id)action;	// 0x315a0ad9
- (BOOL)brKeyEvent:(id)event;	// 0x315d1539
// converted property getter: - (int)contentMode;	// 0x315d1c05
- (long)controlCount;	// 0x315d2061
- (void)controlDidDisplayAsModalDialog;	// 0x315a6b8d
- (id)controlForPoint:(CGPoint)point;	// 0x315d15d5
- (void)controlWasActivated;	// 0x315d237d
- (void)controlWasDeactivated;	// 0x315d2341
- (void)controlWasFocused;	// 0x3158d941
- (void)controlWasUnfocused;	// 0x3159a58d
// converted property getter: - (id)controls;	// 0x315d2091
- (CGPoint)convertPoint:(CGPoint)point fromControl:(id)control;	// 0x315d2761
- (CGPoint)convertPoint:(CGPoint)point toControl:(id)control;	// 0x315d2701
- (CGRect)convertRect:(CGRect)rect fromControl:(id)control;	// 0x315d26a9
- (CGRect)convertRect:(CGRect)rect toControl:(id)control;	// 0x315d2651
- (void)dealloc;	// 0x3159a085
- (id)debugDescriptionForFocusCandidate:(id)focusCandidate;	// 0x315d15dd
// converted property getter: - (id)defaultFocus;	// 0x315d1585
- (void)drawInContext:(CGContextRef)context;	// 0x315d1581
- (void)drawLayer:(id)layer inContext:(CGContextRef)context;	// 0x315d24e9
- (BOOL)eligibilityForFocusCandidate:(id)focusCandidate;	// 0x315d16a1
- (id)firstControlNamed:(id)named;	// 0x315d3189
- (id)focusCandidates;	// 0x315d16f5
- (CGRect)focusCursorFrame;	// 0x31597101
- (id)focusObjectForCandidate:(id)candidate;	// 0x315d16dd
// converted property getter: - (id)focusedControl;	// 0x3158dadd
- (id)focusedControlForEvent:(id)event focusPoint:(CGPoint *)point;	// 0x315a110d
// converted property getter: - (CGRect)frame;	// 0x315d2979
// converted property getter: - (id)identifier;	// 0x3158e565
- (id)inheritedValueForKey:(id)key;	// 0x315d2501
// converted property getter: - (BOOL)inhibitsFocusForChildren;	// 0x315d1595
// converted property getter: - (BOOL)inhibitsScrollFocusForChildren;	// 0x315d15bd
- (id)initialFocus;	// 0x315d1ab9
- (void)insertControl:(id)control above:(id)above;	// 0x315d2225
- (void)insertControl:(id)control atIndex:(long)index;	// 0x315d2291
- (void)insertControl:(id)control below:(id)below;	// 0x315d21d9
// converted property getter: - (BOOL)isFocused;	// 0x3158da35
// converted property getter: - (BOOL)isHidden;	// 0x315d1e9d
// converted property getter: - (id)keyEventTargetControl;	// 0x315d153d
- (id)layer;	// 0x315d1529
- (id)layerForBacking;	// 0x315d259d
- (void)layoutSubcontrols;	// 0x315d157d
// converted property getter: - (BOOL)masksToBounds;	// 0x315d1f65
// converted property getter: - (id)name;	// 0x315d2301
// converted property getter: - (id)object;	// 0x315a20b1
// converted property getter: - (float)opacity;	// 0x315d1ee5
- (id)parent;	// 0x315d31b9
- (id)parentScrollControl;	// 0x316713a9
// converted property getter: - (CGPoint)position;	// 0x315d2955
- (CGPoint)positionForFocusCandidate:(id)focusCandidate;	// 0x315d2635
- (id)preferredActionForKey:(id)key;	// 0x315d15d9
- (float)preferredCursorRadius;	// 0x315e19c1
- (void)removeAllAnimations;	// 0x315d19cd
- (void)removeAnimationForKey:(id)key;	// 0x315d19ed
- (void)removeFromParent;	// 0x315d2039
- (id)root;	// 0x315d31e9
- (void)scrollPoint:(CGPoint)point;	// 0x31671411
- (void)scrollRectToVisible:(CGRect)visible;	// 0x316713d1
- (void)scrollingCompleted;	// 0x31671131
- (void)scrollingInitiated;	// 0x31671135
// converted property getter: - (id)selectionHandler;	// 0x315d1a4d
// converted property setter: - (void)setAcceptsFocus:(BOOL)focus;	// 0x3158d661
// converted property setter: - (void)setActions:(id)actions;	// 0x315d198d
// converted property setter: - (void)setAffineTransform:(CGAffineTransform)transform;	// 0x315d23b9
// converted property setter: - (void)setAnchorPoint:(CGPoint)point;	// 0x315d2405
// converted property setter: - (void)setAutoresizingMask:(unsigned)mask;	// 0x315d154d
// converted property setter: - (void)setAvoidsCursor:(BOOL)cursor;	// 0x3159618d
// converted property setter: - (void)setBackgroundColor:(CGColorRef)color;	// 0x315d1f45
// converted property setter: - (void)setBorderColor:(CGColorRef)color;	// 0x315d1be5
// converted property setter: - (void)setBorderWidth:(float)width;	// 0x315d1ba5
// converted property setter: - (void)setBounds:(CGRect)bounds;	// 0x315d2861
// converted property setter: - (void)setContentMode:(int)mode;	// 0x315d1dc1
// converted property setter: - (void)setControls:(id)controls;	// 0x315d20bd
// converted property setter: - (void)setDefaultFocus:(id)focus;	// 0x3159720d
- (void)setDefaultFocusWithPoint:(CGPoint)point;	// 0x315d15d1
// converted property setter: - (void)setFocusedControl:(id)control;	// 0x3158dbf5
// converted property setter: - (void)setFrame:(CGRect)frame;	// 0x315d3239
// converted property setter: - (void)setHidden:(BOOL)hidden;	// 0x315d1ec1
// converted property setter: - (void)setIdentifier:(id)identifier;	// 0x31596d19
// converted property setter: - (void)setInhibitsFocusForChildren:(BOOL)children;	// 0x315d1a8d
- (void)setInhibitsScrollFocusForChildren:(bool)children;	// 0x315d15a5
// converted property setter: - (void)setKeyEventTargetControl:(id)control;	// 0x315d2445
// converted property setter: - (void)setMasksToBounds:(BOOL)bounds;	// 0x315d1f89
// converted property setter: - (void)setName:(id)name;	// 0x315d2321
- (void)setNeedsDisplay;	// 0x315d1ff9
- (void)setNeedsDisplayInRect:(CGRect)rect;	// 0x315d1fad
- (void)setNeedsLayout;	// 0x315d2019
// converted property setter: - (void)setObject:(id)object;	// 0x3159e5f9
// converted property setter: - (void)setOpacity:(float)opacity;	// 0x315d1f05
// converted property setter: - (void)setPosition:(CGPoint)position;	// 0x315d2425
// converted property setter: - (void)setSelectionHandler:(id)handler;	// 0x315d1a6d
- (void)setValue:(id)value forKey:(id)key cascade:(BOOL)cascade;	// 0x315d299d
- (void)setValue:(id)value forUndefinedKey:(id)undefinedKey;	// 0x315d255d
- (CGSize)sizeThatFits:(CGSize)fits;	// 0x315d27c1
- (void)sizeToFit;	// 0x315d2a6d
- (int)touchSensitivity;	// 0x315d15cd
- (id)valueForUndefinedKey:(id)undefinedKey;	// 0x315d257d
- (CGRect)visibleScrollRect;	// 0x31671b25
- (void)visibleScrollRectChanged;	// 0x316713bd
@end
