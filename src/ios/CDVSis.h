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
#import "SISMessageChannel.h"

@interface CDVSis : CDVPlugin

- (void)listenForMessages:(CDVInvokedUrlCommand *)command;
- (void)listenForMapItems:(CDVInvokedUrlCommand *)command;
- (void)getAllMapItems:(CDVInvokedUrlCommand *)command;
- (void)deleteMessageWithId:(CDVInvokedUrlCommand *)command;

@end
