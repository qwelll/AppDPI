#import "HuayuarcAppDPIRootListController.h"
#import "HuayuarcAppDPIApplicationPicker.h"
#import "HuayuarcAppDPIPreferences.h"
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>

/*
 * Settings panel. Single writer for com.huayuarc.appdpi.
 *
 * Besides the static plist specifiers this controller builds two specifier groups on the fly:
 * one slider per selected application (overriding the default ratio) and a reset button.
 */

static NSString * const huayuarc_appdpi_ratiosKey = @"appRatios";

@interface HuayuarcAppDPIRootListController ()
@end

@implementation HuayuarcAppDPIRootListController

- (NSMutableArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"HuayuarcAppDPIRoot" target:self] mutableCopy];
        [self huayuarc_appdpi_appendApplicationSpecifiers];
    }
    return _specifiers;
}

#pragma mark - Dynamic specifiers

- (void)huayuarc_appdpi_appendApplicationSpecifiers {
    NSDictionary *preferences = huayuarc_appdpi_readPreferences();
    NSArray *selected = [preferences[@"selectedApps"] isKindOfClass:[NSArray class]] ? preferences[@"selectedApps"] : @[];
    NSDictionary *ratios = [preferences[huayuarc_appdpi_ratiosKey] isKindOfClass:[NSDictionary class]] ? preferences[huayuarc_appdpi_ratiosKey] : @{};
    NSNumber *defaultRatio = [preferences[@"defaultRatio"] isKindOfClass:[NSNumber class]] ? preferences[@"defaultRatio"] : @0.9;
    if (selected.count == 0) {
        return;
    }

    PSSpecifier *group = [PSSpecifier groupSpecifierWithName:@"应用比例"];
    [group setProperty:@"不单独调整的 App 使用上方的默认比例。" forKey:@"footerText"];
    [_specifiers addObject:group];

    for (NSString *bundle in selected) {
        NSString *name = [self huayuarc_appdpi_displayNameForBundle:bundle];
        PSSpecifier *slider = [PSSpecifier preferenceSpecifierNamed:name
                                                             target:self
                                                                set:@selector(setPreferenceValue:specifier:)
                                                                get:@selector(huayuarc_appdpi_readPreferenceValueForSpecifier:)
                                                             detail:nil
                                                                cell:PSSliderCell
                                                                edit:nil];
        // Sliders read and write the whole appRatios dictionary; the getter/setter below unwrap one key.
        [slider setProperty:bundle forKey:@"key"];
        [slider setProperty:bundle forKey:@"huayuarcAppDPIBundle"];
        [slider setProperty:@0.6 forKey:@"min"];
        [slider setProperty:@1.0 forKey:@"max"];
        [slider setProperty:@(YES) forKey:@"showValue"];
        [slider setProperty:ratios[bundle] ?: defaultRatio forKey:@"default"];
        [slider setProperty:@YES forKey:@"isSegmented"];
        [slider setProperty:@"0.6" forKey:@"leftLabel"];
        [slider setProperty:@"1.0" forKey:@"rightLabel"];
        [_specifiers addObject:slider];
    }

    PSSpecifier *reset = [PSSpecifier preferenceSpecifierNamed:@"清除单个应用比例"
                                                        target:self
                                                           set:nil
                                                           get:nil
                                                        detail:nil
                                                          cell:PSButtonCell
                                                          edit:nil];
    reset.buttonAction = @selector(huayuarc_appdpi_resetApplicationRatios);
    [_specifiers addObject:reset];
}

- (id)huayuarc_appdpi_readPreferenceValueForSpecifier:(PSSpecifier *)specifier {
    NSString *bundle = [specifier propertyForKey:@"huayuarcAppDPIBundle"];
    NSDictionary *ratios = huayuarc_appdpi_readPreferences()[huayuarc_appdpi_ratiosKey];
    id value = [ratios isKindOfClass:[NSDictionary class]] ? ratios[bundle] : nil;
    return [value isKindOfClass:[NSNumber class]] ? value : [specifier propertyForKey:@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *bundle = [specifier propertyForKey:@"huayuarcAppDPIBundle"];
    if (bundle.length > 0) {
        NSDictionary *existing = huayuarc_appdpi_readPreferences()[huayuarc_appdpi_ratiosKey];
        NSMutableDictionary *ratios = [existing isKindOfClass:[NSDictionary class]] ? [existing mutableCopy] : [NSMutableDictionary dictionary];
        if (!value) value = @1.0;
        // A value equal to the default is redundant, so remove the override instead of storing it.
        NSNumber *defaultRatio = [specifier propertyForKey:@"default"];
        if ([value isKindOfClass:[NSNumber class]] && defaultRatio &&
            fabs([value doubleValue] - [defaultRatio doubleValue]) < 0.0005) {
            [ratios removeObjectForKey:bundle];
        } else {
            ratios[bundle] = value;
        }
        [self huayuarc_appdpi_writeValue:ratios forKey:huayuarc_appdpi_ratiosKey];
        return;
    }
    NSString *key = [specifier propertyForKey:@"key"];
    if (key.length == 0) return;
    [self huayuarc_appdpi_writeValue:value forKey:key];
}

- (void)huayuarc_appdpi_writeValue:(id)value forKey:(NSString *)key {
    NSError *error = nil;
    if (!huayuarc_appdpi_writePreference(key, value, &error)) {
        [self huayuarc_appdpi_showWriteError:error];
        [self reloadSpecifiers];
    }
}

- (void)huayuarc_appdpi_showWriteError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置未保存"
        message:error.localizedDescription ?: @"请检查配置文件路径和写入权限。"
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)huayuarc_appdpi_resetApplicationRatios {
    [self huayuarc_appdpi_writeValue:@{} forKey:huayuarc_appdpi_ratiosKey];
    [self reloadSpecifiers];
}

#pragma mark - Application picker

- (void)huayuarc_appdpi_pickApplications {
    NSArray *selected = huayuarc_appdpi_readPreferences()[@"selectedApps"];
    HuayuarcAppDPIApplicationPickerController *picker =
        [[HuayuarcAppDPIApplicationPickerController alloc] initWithSelectedBundles:
            [selected isKindOfClass:[NSArray class]] ? selected : @[]];
    picker.huayuarc_appdpi_completion = ^(NSArray<NSString *> *bundles) {
        NSError *error = nil;
        if (!huayuarc_appdpi_writePreference(@"selectedApps", bundles, &error)) {
            [self huayuarc_appdpi_showWriteError:error];
            return;
        }
        // Drop ratios for apps that are no longer selected so stale entries cannot resurrect later.
        NSDictionary *existing = huayuarc_appdpi_readPreferences()[huayuarc_appdpi_ratiosKey];
        if ([existing isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *kept = [NSMutableDictionary dictionary];
            for (NSString *bundle in bundles) {
                if (existing[bundle]) kept[bundle] = existing[bundle];
            }
            if (kept.count != existing.count) {
                huayuarc_appdpi_writePreference(huayuarc_appdpi_ratiosKey, kept, NULL);
            }
        }
        [self huayuarc_appdpi_rebuildSpecifiers];
    };
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)huayuarc_appdpi_rebuildSpecifiers {
    _specifiers = nil;
    [self reloadSpecifiers];
}

- (NSString *)huayuarc_appdpi_displayNameForBundle:(NSString *)bundle {
    for (NSDictionary *application in [HuayuarcAppDPIApplicationPickerController huayuarc_appdpi_loadApplications]) {
        if ([application[@"bundle"] isEqualToString:bundle]) {
            return application[@"name"];
        }
    }
    return bundle;
}

@end
