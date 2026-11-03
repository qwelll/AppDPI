#import "HuayuarcAppDPIConfig.h"
#import "HuayuarcAppDPIPreferences.h"
#import "HuayuarcAppDPIResolution.h"

@interface HuayuarcAppDPIConfig ()
@property (atomic, copy) NSDictionary *snapshot;
@property (nonatomic, strong) dispatch_queue_t reloadQueue;
@end

static void huayuarc_appdpi_preferencesDidChange(CFNotificationCenterRef center, void *observer,
                                          CFStringRef name, const void *object, CFDictionaryRef info) {
    HuayuarcAppDPIConfig *config = (__bridge HuayuarcAppDPIConfig *)observer;
    dispatch_async(config.reloadQueue, ^{
        [config huayuarc_appdpi_reload];
    });
}

@implementation HuayuarcAppDPIConfig

+ (instancetype)huayuarc_appdpi_shared {
    static HuayuarcAppDPIConfig *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _snapshot = @{};
        _reloadQueue = dispatch_queue_create("com.huayuarc.appdpi.preferences", DISPATCH_QUEUE_SERIAL);
        [self huayuarc_appdpi_reload];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)self, huayuarc_appdpi_preferencesDidChange,
            (__bridge CFStringRef)HuayuarcAppDPIPreferencesChanged, NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    return self;
}

- (void)huayuarc_appdpi_reload {
    self.snapshot = huayuarc_appdpi_readPreferences() ?: @{};
}

- (id)huayuarc_appdpi_valueForKey:(NSString *)key defaultValue:(id)defaultValue {
    id value = self.snapshot[key];
    return value ?: defaultValue;
}

- (BOOL)huayuarc_appdpi_isEnabled {
    id value = [self huayuarc_appdpi_valueForKey:@"enabled" defaultValue:@NO];
    return [value isKindOfClass:[NSNumber class]] ? [value boolValue] : NO;
}

- (NSArray<NSString *> *)huayuarc_appdpi_selectedApplications {
    id value = [self huayuarc_appdpi_valueForKey:@"selectedApps" defaultValue:nil];
    NSMutableArray *result = [NSMutableArray array];
    if ([value isKindOfClass:[NSArray class]]) {
        for (id item in (NSArray *)value) {
            if ([item isKindOfClass:[NSString class]] && [(NSString *)item length] > 0) {
                [result addObject:item];
            }
        }
    }
    return result;
}

- (CGFloat)huayuarc_appdpi_scaleForCurrentApplication {
    NSString *identifier = HuayuarcAppDPICurrentBundleIdentifier();
    if (identifier.length == 0) {
        return 1.0;
    }
    NSDictionary *ratios = [self huayuarc_appdpi_valueForKey:@"appRatios" defaultValue:nil];
    CGFloat ratio = 1.0;
    if ([ratios isKindOfClass:[NSDictionary class]] && ratios[identifier] != nil) {
        // An explicit per-app value always wins, including values that disable scaling.
        id value = ratios[identifier];
        ratio = [value isKindOfClass:[NSNumber class]] ? [value doubleValue] : 1.0;
    } else if ([[self huayuarc_appdpi_selectedApplications] containsObject:identifier]) {
        id value = [self huayuarc_appdpi_valueForKey:@"defaultRatio" defaultValue:@0.9];
        ratio = [value isKindOfClass:[NSNumber class]] ? [value doubleValue] : 0.9;
    }
    if (!(ratio > 0.5 && ratio < 1.0)) {
        return 1.0;
    }
    return (CGFloat)ratio;
}

- (void)dealloc {
    CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                            (__bridge const void *)self);
}

@end
