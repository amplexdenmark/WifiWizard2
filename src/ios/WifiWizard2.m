#import "WifiWizard2.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <net/if.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <NetworkExtension/NetworkExtension.h>
#import <CoreLocation/CoreLocation.h>

@implementation WifiWizard2

- (id)fetchSSIDInfo {
    // see http://stackoverflow.com/a/5198968/907720
    NSArray *ifs = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
    NSLog(@"Supported interfaces: %@", ifs);
    NSDictionary *info;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSLog(@"%@ => %@", ifnam, info);
        if (info && [info count]) { break; }
    }
    return info;
}

- (BOOL) isWiFiEnabled {
    // see http://www.enigmaticape.com/blog/determine-wifi-enabled-ios-one-weird-trick
    NSCountedSet * cset = [NSCountedSet new];

    struct ifaddrs *interfaces = NULL;
    // retrieve the current interfaces - returns 0 on success
    int success = getifaddrs(&interfaces);
    if(success == 0){
        for( struct ifaddrs *interface = interfaces; interface; interface = interface->ifa_next) {
            if ( (interface->ifa_flags & IFF_UP) == IFF_UP ) {
                [cset addObject:[NSString stringWithUTF8String:interface->ifa_name]];
            }
        }
    }

    return [cset countForObject:@"awdl0"] > 1 ? YES : NO;
}

- (void)iOSConnectNetwork:(CDVInvokedUrlCommand*)command {
    
    __block CDVPluginResult *pluginResult = nil;

    NSString * ssidString;
    NSString * passwordString;
    BOOL joinOnce;
    NSDictionary* options = [[NSDictionary alloc]init];

    options = [command argumentAtIndex:0];
    NSLog(@"connect options info -> %@", options);
    ssidString = [options objectForKey:@"Ssid"];
    passwordString = [options objectForKey:@"Password"];
    joinOnce = [options objectForKey:@"joinOnce"];
    NSLog(@"joinOnce -> %@", joinOnce);

    if (@available(iOS 11.0, *)) {
      if (ssidString && [ssidString length]) {
            NEHotspotConfiguration *configuration;


            if (@available(iOS 13.0, *)) {
               configuration = [[NEHotspotConfiguration
                                   alloc] initWithSSIDPrefix:ssidString
                                  passphrase:passwordString
                                  isWEP:(BOOL)false];
            } else {
                configuration = [[NEHotspotConfiguration
                                  alloc] initWithSSID:ssidString
                                 passphrase:passwordString
                                 isWEP:(BOOL)false];
            }
            configuration.joinOnce = joinOnce;
              
            [[NEHotspotConfigurationManager sharedManager] applyConfiguration:configuration completionHandler:^(NSError * _Nullable error) {
                
                NSDictionary *r = [self fetchSSIDInfo];
                
                NSString *ssid = [r objectForKey:(id)kCNNetworkInfoKeySSID]; //@"SSID"
                
                if ([ssid hasPrefix:ssidString]){
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:ssid];
                }else{
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
                }
                [self.commandDelegate sendPluginResult:pluginResult
                                            callbackId:command.callbackId];
            }];


        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"SSID Not provided"];
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        }
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"iOS 11+ not available"];
        [self.commandDelegate sendPluginResult:pluginResult
                                    callbackId:command.callbackId];
    }


}

- (void)iOSConnectOpenNetwork:(CDVInvokedUrlCommand*)command {

    __block CDVPluginResult *pluginResult = nil;

    NSString * ssidString;
    NSDictionary* options = [[NSDictionary alloc]init];

    options = [command argumentAtIndex:0];
    ssidString = [options objectForKey:@"Ssid"];

    if (@available(iOS 11.0, *)) {
        if (ssidString && [ssidString length]) {
          NEHotspotConfiguration *configuration;
          
          
          if (@available(iOS 13.0, *)) {
            configuration = [[NEHotspotConfiguration
                                    alloc] initWithSSIDPrefix:ssidString];
          } else {
            configuration = [[NEHotspotConfiguration
                                   alloc] initWithSSID:ssidString];
          }

            configuration.joinOnce = false;

            [[NEHotspotConfigurationManager sharedManager] applyConfiguration:configuration completionHandler:^(NSError * _Nullable error) {

                NSDictionary *r = [self fetchSSIDInfo];

                NSString *ssid = [r objectForKey:(id)kCNNetworkInfoKeySSID]; //@"SSID"

               if ([ssid hasPrefix:ssidString]){
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:ssid];
                }else{
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
                }
                [self.commandDelegate sendPluginResult:pluginResult
                                            callbackId:command.callbackId];
            }];


        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"SSID Not provided"];
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        }
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"iOS 11+ not available"];
        [self.commandDelegate sendPluginResult:pluginResult
                                    callbackId:command.callbackId];
    }


}

- (void)iOSDisconnectNetwork:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;

    NSString * ssidString;
    NSDictionary* options = [[NSDictionary alloc]init];

    options = [command argumentAtIndex:0];
    ssidString = [options objectForKey:@"Ssid"];

    if (@available(iOS 11.0, *)) {
        if (ssidString && [ssidString length]) {
            [[NEHotspotConfigurationManager sharedManager] removeConfigurationForSSID:ssidString];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:ssidString];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"SSID Not provided"];
        }
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"iOS 11+ not available"];
    }

    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)getConnectedSSID:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    NSString *ssid = [self getWifiSsid]; //@"SSID"

    if (ssid && [ssid length]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:ssid];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not available"];
    }

    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)getConnectedBSSID:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    NSDictionary *r = [self fetchSSIDInfo];
    
    NSString *bssid = [r objectForKey:(id)kCNNetworkInfoKeyBSSID]; //@"SSID"
    
    if (bssid && [bssid length]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:bssid];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not available"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)isWifiEnabled:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    NSString *isWifiOn = [self isWiFiEnabled] ? @"1" : @"0";

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:isWifiOn];

    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)setWifiEnabled:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not supported"];

    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)scan:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not supported"];

    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

// Android functions

- (void)addNetwork:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not supported"];
    
    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)removeNetwork:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not supported"];
    
    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)androidConnectNetwork:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not supported"];
    
    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)androidDisconnectNetwork:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not supported"];
    
    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)listNetworks:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not supported"];
    
    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)getScanResults:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not supported"];
    
    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)startScan:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not supported"];

    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)disconnect:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not supported"];
    
    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)isConnectedToInternet:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not supported"];
    
    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)canConnectToInternet:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not supported"];
    
    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)canPingWifiRouter:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not supported"];
    
    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (void)canConnectToRouter:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not supported"];
    
    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:command.callbackId];
}

- (NSString*) getWifiSsid {
    if (@available(iOS 13.0, *)) {
        CLLocationManager* manager = [[CLLocationManager alloc] init];
        CLAuthorizationStatus authStatus = [manager authorizationStatus];

        if (authStatus == kCLAuthorizationStatusNotDetermined) {
            [manager requestWhenInUseAuthorization];
        } else if (authStatus == kCLAuthorizationStatusDenied) {
            NSLog(@"User has explicitly denied authorization for this application, or location services are disabled in Settings.");
            return nil;
        } 
    }

    NSString *wifiName = nil;
    CFArrayRef wifiInterfaces = CNCopySupportedInterfaces();
    if (!wifiInterfaces) {
        return nil;
    }

    NSArray *interfaces = (__bridge NSArray *)wifiInterfaces;
    for (NSString *interfaceName in interfaces) {
        CFDictionaryRef dictRef = CNCopyCurrentNetworkInfo((__bridge CFStringRef)(interfaceName));

        if (dictRef) {
            NSDictionary *networkInfo = (__bridge NSDictionary *)dictRef;
            NSLog(@"network info -> %@", networkInfo);
            wifiName = [networkInfo objectForKey:(__bridge NSString *)kCNNetworkInfoKeySSID];
            CFRelease(dictRef);
        }
    }

    CFRelease(wifiInterfaces);
    return wifiName;
}

@end
