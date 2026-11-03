#import <UIKit/UIKit.h>

/// Called with the final selection when the user taps Done.
typedef void (^HuayuarcAppDPIApplicationPickerCompletion)(NSArray<NSString *> *selectedBundles);

@interface HuayuarcAppDPIApplicationPickerController : UIViewController
@property (nonatomic, copy) HuayuarcAppDPIApplicationPickerCompletion huayuarc_appdpi_completion;
- (instancetype)huayuarc_appdpi_initWithSelectedBundles:(NSArray<NSString *> *)selectedBundles;
/// User applications as dictionaries with keys name and bundle, sorted by display name.
+ (NSArray<NSDictionary<NSString *, NSString *> *> *)huayuarc_appdpi_loadApplications;
@end
