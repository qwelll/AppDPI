#pragma once

#import <UIKit/UIKit.h>

// Application bundle identifier of the process being hooked (falls back to the main bundle).
FOUNDATION_EXPORT NSString *huayuarc_appdpi_currentBundleIdentifier(void);

/*
 * Per-process resolution state. Views are scaled exactly once: the first time a size is requested
 * the original is recorded and the scaled value is cached, so repeated queries are cheap and the
 * window hooks can tell scaled frames from originals.
 */
@interface HuayuarcAppDPIResolution : NSObject
+ (instancetype)huayuarc_appdpi_shared;

@property (nonatomic, readonly) BOOL huayuarc_appdpi_active;
@property (nonatomic, readonly) CGFloat huayuarc_appdpi_ratio;
/// The screen bounds before scaling (UIKit logical points).
@property (nonatomic, readonly) CGSize huayuarc_appdpi_originalScreenSize;
@property (nonatomic, readonly) CGSize huayuarc_appdpi_scaledScreenSize;

/// Reads the current bundle ratio and resets cached geometry when it changes.
- (void)huayuarc_appdpi_refresh;

/// Converts a size reported by UIKit; returns the original when scaling is not active.
- (CGSize)huayuarc_appdpi_adjustSize:(CGSize)size;
- (CGRect)huayuarc_appdpi_adjustRect:(CGRect)rect;
/// True when a size is (approximately) an already scaled screen size, used to avoid double scaling.
- (BOOL)huayuarc_appdpi_isScaledScreenSize:(CGSize)size;
@end
