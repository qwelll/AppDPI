#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HuayuarcAppDPIConfig : NSObject
+ (instancetype)huayuarc_appdpi_shared;
- (BOOL)huayuarc_appdpi_isEnabled;
- (id)huayuarc_appdpi_valueForKey:(NSString *)key defaultValue:(id)defaultValue;
/// Scale factor for the current process bundle identifier, 1.0 when the app is not configured.
- (CGFloat)huayuarc_appdpi_scaleForCurrentApplication;
/// Explicit application identifiers from the preferences panel.
- (NSArray<NSString *> *)huayuarc_appdpi_selectedApplications;
- (void)huayuarc_appdpi_reload;
@end
