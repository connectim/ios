//
//  Language.h
//
//  Created by Aufree on 12/5/15.
//  Copyright (c) 2015 The EST Group. All rights reserved.
//

#import "Language.h"
#import "AppDelegate.h"
#import "MainTabController.h"

@implementation Language

static NSBundle *bundle = nil;

NSString *const LanguageCodeIdIndentifier = @"LanguageCodeIdIndentifier";

+ (void)initialize {
    NSString * currentLanguage = GJCFUDFGetValue(@"userCurrentLanguage");
    if (GJCFStringIsNull(currentLanguage)) {
        NSArray *languages = [NSLocale preferredLanguages];
        currentLanguage = [languages objectAtIndex:0];
        if ([currentLanguage containsString:@"en"]) {
            currentLanguage = @"en";
        } else if([currentLanguage hasPrefix:@"zh"]){
            currentLanguage = @"zh-Hans";
        }
    }
    NSString *path = [[NSBundle mainBundle] pathForResource:currentLanguage ofType:@"lproj"];
    bundle = [NSBundle bundleWithPath:path];
}

+ (void)setLanguage:(NSString *)language {
    GJCFUDFCache(@"userCurrentLanguage",language);
    NSString *path = [[NSBundle mainBundle] pathForResource:language ofType:@"lproj"];
    bundle = [NSBundle bundleWithPath:path];
    
    // Re-initialize the maintab and then interface jump
    AppDelegate *appDelegate =
    (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate changeLanguageResetMainTabController];
    MainTabController *mainTabCv = (MainTabController*)appDelegate.window.rootViewController;
    [mainTabCv changeLanguageResetController];
}

+ (NSString *)currentLanguageCode {
    NSString *userSelectedLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:LanguageCodeIdIndentifier];
    if (userSelectedLanguage) {
        // Store selected language in local
        
        return userSelectedLanguage;
    }
    
    NSString *systemLanguage = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndexCheck:0];
    if ([systemLanguage isEqualToString:@"en"] || [systemLanguage isEqualToString:@"zh-Hans"]) {
        // Update selected language in local
    } else {
        // Update selected language in local
    }
    
    return systemLanguage;
}

+ (void)userSelectedLanguage:(NSString *)selectedLanguage {
    // Store the data
    // Store selected language in local
    
    [[NSUserDefaults standardUserDefaults] setObject:selectedLanguage forKey:LanguageCodeIdIndentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Set global language
    [Language setLanguage:selectedLanguage];
}

+ (NSString *)get:(NSString *)key alter:(NSString *)alternate {
    NSString *value = [bundle localizedStringForKey:key value:alternate table:nil];
    if (!value) {
        value = key;
    }
    return value;
}

@end
