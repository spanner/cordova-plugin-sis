//
//  CDVSis.h
//  LordMayorShow
//
//  Created by William Ross on 14/10/2015.
//
//

#import <Cordova/CDV.h>
#import "SISConnectionManager.h"
#import "SISManager.h"
#import "SISMessagingManager.h"
#import "SISMappingModule.h"

// Extra headers for low-level stuff we will need to gather.
#import "SISMessageChannel.h"
#import "SISZone.h"

@interface CDVSis : CDVPlugin

- (void)listenForMessages:(CDVInvokedUrlCommand *)command;
- (void)listenForMapItems:(CDVInvokedUrlCommand *)command;
- (void)getCompleteMapData:(CDVInvokedUrlCommand *)command;
- (void)deleteMessage:(CDVInvokedUrlCommand *)command;
- (void)markMessageAsRead:(CDVInvokedUrlCommand *)command;

@end
