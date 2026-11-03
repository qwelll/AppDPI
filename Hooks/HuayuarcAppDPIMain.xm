#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "HuayuarcAppDPIConfig.h"
#import "HuayuarcAppDPIResolution.h"
#import "HuayuarcAppDPIResolutionMath.h"

/*
 * Per-application logical resolution override.
 *
 * 1. UIScreen reports the shrunk bounds so every screen-relative layout gets more points.
 * 2. The main UIWindow is resized to the same bounds (UIKit does not re-read UIScreen for an
 *    already existing window), and inbound frames are converted so repeated layout passes do not
 *    shrink the window again.
 * 3. Nothing touches nativeBounds/nativeScale/scale: the physical framebuffer, the touch
 *    digitizer and screenshots stay as they were, so gestures stay correct on notched devices.
 */

static NSMapTable<UIWindow *, NSValue *> *huayuarc_appdpi_windowFrames(void) {
    static NSMapTable *table;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        table = [NSMapTable mapTableWithKeyOptions:(NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality)
                                      valueOptions:NSPointerFunctionsStrongMemory];
    });
    return table;
}

static BOOL huayuarc_appdpi_isFullScreenRect(CGRect rect, CGSize screen) {
    if (screen.width < 100 || screen.height < 100) {
        return NO;
    }
    return fabs(rect.size.width - screen.width) < 1.5 && fabs(rect.size.height - screen.height) < 1.5;
}

// Converts an inbound window frame to the scaled value. Only frames that look like the current
// logical screen are scaled; overlays and partial windows keep their own geometry.
static CGRect huayuarc_appdpi_frameForWrite(UIWindow *window, CGRect frame) {
    HuayuarcAppDPIResolution *resolution = [HuayuarcAppDPIResolution huayuarc_appdpi_shared];
    if (!resolution.huayuarc_appdpi_active || ![UIApplication sharedApplication]) {
        return frame;
    }
    NSMapTable *frames = huayuarc_appdpi_windowFrames();
    NSValue *stored = window ? [frames objectForKey:window] : nil;
    if (stored) {
        // Our own resize arriving back through setFrame: reports the scaled screen size.
        if ([resolution huayuarc_appdpi_isScaledScreenSize:frame.size]) {
            return frame;
        }
        [frames removeObjectForKey:window];
    }
    BOOL fullScreen = huayuarc_appdpi_isFullScreenRect(frame, resolution.huayuarc_appdpi_originalScreenSize);
    CGSize scaledSize = resolution.huayuarc_appdpi_scaledScreenSize;
    if (!fullScreen && !(fabs(frame.size.width - scaledSize.width) < 1.5 &&
                         fabs(frame.size.height - scaledSize.height) < 1.5)) {
        return frame;
    }
    CGRect scaled = [resolution huayuarc_appdpi_adjustRect:frame];
    if (CGRectEqualToRect(scaled, frame)) {
        return frame;
    }
    if (window) {
        [frames setObject:[NSValue valueWithCGRect:frame] forKey:window];
    }
    return scaled;
}

static void huayuarc_appdpi_resizeVisibleWindows(void) {
    HuayuarcAppDPIResolution *resolution = [HuayuarcAppDPIResolution huayuarc_appdpi_shared];
    if (!resolution.huayuarc_appdpi_active || ![UIApplication sharedApplication]) {
        return;
    }
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        CGRect frame = window.frame;
        if (!huayuarc_appdpi_isFullScreenRect(frame, resolution.huayuarc_appdpi_originalScreenSize) &&
            ![resolution huayuarc_appdpi_isScaledScreenSize:frame.size]) {
            continue;
        }
        window.frame = huayuarc_appdpi_frameForWrite(window, frame);
    }
}

%group HuayuarcAppDPIScreen
%hook UIScreen

- (CGRect)bounds {
    return [[HuayuarcAppDPIResolution huayuarc_appdpi_shared] huayuarc_appdpi_adjustRect:%orig];
}

- (CGRect)_referenceBounds {
    return [[HuayuarcAppDPIResolution huayuarc_appdpi_shared] huayuarc_appdpi_adjustRect:%orig];
}

- (CGRect)_mainScreenBounds {
    return [[HuayuarcAppDPIResolution huayuarc_appdpi_shared] huayuarc_appdpi_adjustRect:%orig];
}

// Status bar metrics follow the screen; keep them inside the new bounds.
- (CGRect)_statusBarFrameForOrientation:(long long)orientation {
    return [[HuayuarcAppDPIResolution huayuarc_appdpi_shared] huayuarc_appdpi_adjustRect:%orig(orientation)];
}

%end
%end

%group HuayuarcAppDPIWindow
%hook UIWindow

- (void)setFrame:(CGRect)frame {
    %orig(huayuarc_appdpi_frameForWrite(self, frame));
}

%end
%end

static void huayuarc_appdpi_applyConfiguration(void) {
    HuayuarcAppDPIResolution *resolution = [HuayuarcAppDPIResolution huayuarc_appdpi_shared];
    [resolution huayuarc_appdpi_refresh];
    if (!resolution.huayuarc_appdpi_active) {
        // Disabling from the panel restores the original window geometry immediately.
        static dispatch_once_t restoreToken;
        dispatch_once(&restoreToken, ^{
            %init(HuayuarcAppDPIWindow);
        });
        return;
    }
    // Hooks are installed lazily on the main thread: UIApplication exists and injecting an app that
    // is already running is safe.
    static dispatch_once_t installToken;
    dispatch_once(&installToken, ^{
        %init(HuayuarcAppDPIScreen);
        %init(HuayuarcAppDPIWindow);
    });
    huayuarc_appdpi_resizeVisibleWindows();
}

%ctor {
    @autoreleasepool {
        // Readers only load a snapshot; they never write preferences.
        [HuayuarcAppDPIConfig huayuarc_appdpi_shared];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            (CFNotificationCallback)huayuarc_appdpi_applyConfiguration,
            (__bridge CFStringRef)HuayuarcAppDPIPreferencesChanged,
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately);
        // Wait for the first main-thread turn so UIApplication/UIScreen are fully initialized.
        dispatch_async(dispatch_get_main_queue(), ^{
            huayuarc_appdpi_applyConfiguration();
        });
    }
}
