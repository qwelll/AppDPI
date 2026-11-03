#import "HuayuarcAppDPIResolution.h"
#import "HuayuarcAppDPIResolutionMath.h"
#import "HuayuarcAppDPIConfig.h"

static NSString *huayuarc_appdpi_currentBundleID = nil;

NSString *huayuarc_appdpi_currentBundleIdentifier(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *identifier = bundle.bundleIdentifier;
        // Extension hosts may report the extension bundle; prefer the executable bundle id.
        if (identifier.length == 0) {
            NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
            identifier = [[bundlePath stringByDeletingPathExtension] lastPathComponent];
        }
        huayuarc_appdpi_currentBundleID = [identifier copy] ?: @"";
    });
    return huayuarc_appdpi_currentBundleID;
}

@interface HuayuarcAppDPIResolution ()
@property (nonatomic, assign) BOOL huayuarc_appdpi_active;
@property (nonatomic, assign) CGFloat huayuarc_appdpi_ratio;
@property (nonatomic, assign) CGSize huayuarc_appdpi_originalScreenSize;
@property (nonatomic, assign) CGSize huayuarc_appdpi_scaledScreenSize;
@end

@implementation HuayuarcAppDPIResolution

+ (instancetype)huayuarc_appdpi_shared {
    static HuayuarcAppDPIResolution *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self huayuarc_appdpi_refresh];
    }
    return self;
}

- (void)huayuarc_appdpi_refresh {
    HuayuarcAppDPIConfig *config = [HuayuarcAppDPIConfig huayuarc_appdpi_shared];
    CGFloat ratio = config.huayuarc_appdpi_isEnabled ? [config huayuarc_appdpi_scaleForCurrentApplication] : 1.0;
    if (!huayuarc_appdpi_ratioIsValid(ratio)) {
        ratio = 1.0;
    }

    BOOL active = (ratio != 1.0);
    CGSize original = CGSizeZero;
    CGSize scaled = CGSizeZero;
    if (active) {
        if (self.huayuarc_appdpi_active && fabs(self.huayuarc_appdpi_ratio - ratio) < 0.0001) {
            return; // Same configuration, keep the cached geometry.
        }
        // Read the main screen directly so a previous (scaled) value can never feed back in.
        CGFloat width = [[UIScreen mainScreen] nativeBounds].size.width /
                        (([[UIScreen mainScreen] nativeScale] > 0) ? [[UIScreen mainScreen] nativeScale] : 1);
        CGFloat height = [[UIScreen mainScreen] nativeBounds].size.height /
                         (([[UIScreen mainScreen] nativeScale] > 0) ? [[UIScreen mainScreen] nativeScale] : 1);
        original = CGSizeMake(width, height);
        if (original.width < 100 || original.height < 100) {
            active = NO;
        } else {
            scaled = huayuarc_appdpi_scaledSize(original, ratio);
        }
    }
    if (ratio == 1.0 && !self.huayuarc_appdpi_active) {
        return;
    }
    self.huayuarc_appdpi_ratio = ratio;
    self.huayuarc_appdpi_active = active;
    self.huayuarc_appdpi_originalScreenSize = original;
    self.huayuarc_appdpi_scaledScreenSize = scaled;
}

- (NSString *)huayuarc_appdpi_debugDescription {
    return [NSString stringWithFormat:@"<%@ %p bundle=%@ ratio=%.3f active=%d>",
            NSStringFromClass([self class]), self, huayuarc_appdpi_currentBundleIdentifier(),
            (double)self.huayuarc_appdpi_ratio, self.huayuarc_appdpi_active];
}

- (CGSize)huayuarc_appdpi_adjustSize:(CGSize)size {
    if (!self.huayuarc_appdpi_active) {
        return size;
    }
    if (self.huayuarc_appdpi_isScaledScreenSize:size) {
        return self.huayuarc_appdpi_scaledScreenSize;
    }
    return huayuarc_appdpi_scaledSize(size, self.huayuarc_appdpi_ratio);
}

- (CGRect)huayuarc_appdpi_adjustRect:(CGRect)rect {
    if (!self.huayuarc_appdpi_active) {
        return rect;
    }
    return huayuarc_appdpi_scaledRect(rect, self.huayuarc_appdpi_ratio);
}

- (BOOL)huayuarc_appdpi_isScaledScreenSize:(CGSize)size {
    if (!self.huayuarc_appdpi_active) {
        return NO;
    }
    CGSize scaled = self.huayuarc_appdpi_scaledScreenSize;
    return fabs(size.width - scaled.width) < 1.0 && fabs(size.height - scaled.height) < 1.0;
}

@end
