/*
 The MIT License (MIT)
 
 Copyright (c) 2015 Francois Hoehl

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */


#import "CDVAlloBonjour.h"
#import <Cordova/CDV.h>
#import <Foundation/Foundation.h>

@implementation CDVAlloBonjour

- (void)pluginInitialize {

    self.services = [NSMutableArray arrayWithCapacity: 0];
    self.netServiceBrowser = [[NSNetServiceBrowser alloc] init];
    self.netServiceBrowser.delegate = self;
}

- (void)startDiscovery:(CDVInvokedUrlCommand *)command {

    NSString* serviceType = [command.arguments objectAtIndex:0];
    NSString* serviceDomain = [command.arguments objectAtIndex:1];
    
    if (!self.SEARCHING && serviceType && serviceDomain) {
    
        self.command = command;
    
        [self.services removeAllObjects];
        
        [self.netServiceBrowser searchForServicesOfType:serviceType inDomain:serviceDomain];
    }
    else {
        
        CDVPluginResult* pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
    }
}

- (void)stopDiscovery:(CDVInvokedUrlCommand*)command {

    if (self.netServiceBrowser) {
        [self.netServiceBrowser stop];
        self.SEARCHING = NO;
    }
}

- (void)resolve:(CDVInvokedUrlCommand *)command {
    
    NSString* serviceName = [command.arguments objectAtIndex:0];
    NSString* serviceType = [command.arguments objectAtIndex:1];
    NSString* serviceDomain = [command.arguments objectAtIndex:2];
    
    if (!self.SEARCHING && serviceName && serviceType && serviceDomain) {
        self.command = command;

        NSNetService *service;
        service = [[NSNetService alloc] initWithDomain:serviceDomain type:serviceType name:serviceName];
        [service setDelegate:self];

        [self.services addObject:service];

        [service resolveWithTimeout:5.0];
    }
    else {

        CDVPluginResult* pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
    }
}

- (void)returnResultWithError {

    CDVPluginResult* pluginResult = nil;

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
}

- (void)returnServiceResolveData:(NSNetService *)service {

    NSMutableDictionary *pluginJSONResult = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *serviceAddressesData = [[NSMutableArray alloc] init];
    [pluginJSONResult setObject:serviceAddressesData forKey:@"addresses"];
    
    for (NSData *address in service.addresses) {
        struct sockaddr_in *socketAddress = (struct sockaddr_in *) [address bytes];
        
        NSString *serviceIP = [[NSString alloc] initWithUTF8String:inet_ntoa(socketAddress->sin_addr)];
        
        NSDictionary *addressData = @{
                                      @"hostname": service.hostName,
                                      @"ip": serviceIP,
                                      @"port": [[NSNumber alloc] initWithLong:service.port],
                                      @"serviceDomain": service.domain,
                                      @"serviceType": service.type,
                                      @"serviceName": service.name
                                      };
        
        [serviceAddressesData addObject:addressData];
    }
    
    // Return plugin data
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:pluginJSONResult];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
}

- (void)returnDiscoveryResult:(NSMutableArray*)services {
    
    NSMutableDictionary *pluginJSONResult = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *listOfServices = [[NSMutableArray alloc] init];
    
    [pluginJSONResult setObject:listOfServices forKey:@"services"];
    
    for (NSNetService *service in services) {
        
        NSMutableDictionary *serviceData = [NSMutableDictionary
                                            dictionaryWithDictionary:@{
                                                                       @"name": service.name,
                                                                       @"domain": service.domain,
                                                                       @"type": service.type
                                                                       }];
        [listOfServices addObject:serviceData];

        NSMutableArray *serviceAddressesData = [[NSMutableArray alloc] init];
        [serviceData setObject:serviceAddressesData forKey:@"addresses"];
    }
    
    //NSError *error = nil;
    //NSData *json;
    //json = [NSJSONSerialization dataWithJSONObject:pluginJSONResult options:NSJSONWritingPrettyPrinted error:&error];
    //NSLog(@"====> %@", [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]);
    
    // Return plugin data
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:pluginJSONResult];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
}

// NSNetServiceBrowserDelegate messages

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser {
    
    self.SEARCHING = YES;
    NSLog(@"Service search started");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
           didFindService:(NSNetService *)aNetService
               moreComing:(BOOL)moreComing {
    
    NSLog(@"Found service %@", aNetService.name);
    
    [self.services addObject:aNetService];
    
    if(!moreComing) {
        [browser stop];
    }
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser {
    
    NSLog(@"Stopping service search");
    
    [self returnDiscoveryResult:self.services];
    self.SEARCHING = NO;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
             didNotSearch:(NSDictionary *)errorDict {
    
    [self handleError:[errorDict objectForKey:NSNetServicesErrorCode]];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
         didRemoveService:(NSNetService *)aNetService
               moreComing:(BOOL)moreComing {
    
    [self.services removeObject:aNetService];
    
    if(!moreComing) {
        [browser stop];
    }
}

- (void)handleError:(NSNumber *)error {
    
    NSLog(@"An error occurred. Error code = %d", [error intValue]);
    
    [self returnResultWithError];
}

// NSNetServiceDelegate messages

- (void)netServiceDidResolveAddress:(NSNetService *)netService {
    
    NSLog(@"Service %@ resolved", netService.name);
    
    [self returnServiceResolveData:netService];
}

- (void)netService:(NSNetService *)netService
     didNotResolve:(NSDictionary *)errorDict {
    
    NSLog(@"Service %@ could not be resolved", netService.name);

    [self returnResultWithError];
}

@end
